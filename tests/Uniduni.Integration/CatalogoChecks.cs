using System.Text.Json;
using Microsoft.EntityFrameworkCore;
using Uniduni.API.Data;

public static class CatalogoChecks
{
    public static async Task<int> Run(
        Func<HttpMethod,string,int,object?,string?,Task<JsonElement>> expect,
        Func<HttpMethod,string,object?,string?,Task<(int Status,string Text)>> send,
        AppDbContext db,string prefix,string adminToken,string clienteToken,string equipeToken)
    {
        var count=0;
        void Check(bool ok,string mensagem) {
            if(!ok) throw new Exception("FALHOU: "+mensagem);
            Console.WriteLine("OK: "+mensagem); count++;
        }
        Task<JsonElement> E(HttpMethod m,string path,int status,object? data=null,string? token=null)
            => expect(m,path,status,data,token);
        object Produto(string nome,int categoriaId,object variacao) => new { nome,descricao="Peça de teste para validação de estoque",preco=44.90m,
            genero="Unissex",imagem="body-azul.jpg",categoriaId,guiaMedidas="Medida fictícia de teste: comprimento 32 cm.",variacaoInicial=variacao };
        object Mov(string tipo,int quantidade,string versao,Guid? operacao=null) => new {
            tipo,quantidade,versao,operacaoId=operacao??Guid.NewGuid(),justificativa="Conferência de integração do estoque"
        };
        var nome=prefix+"-produto";
        var nomeCalcado=prefix+"-calcado";
        try
        {
            var categorias=await E(HttpMethod.Get,"/api/Categorias",200);
            var roupas=categorias.EnumerateArray().Single(c=>c.GetProperty("nome").GetString()=="Roupas").GetProperty("id").GetInt32();
            var calcados=categorias.EnumerateArray().Single(c=>c.GetProperty("nome").GetString()=="Calçados").GetProperty("id").GetInt32();
            await E(HttpMethod.Get,"/api/Estoque/alertas",401);
            await E(HttpMethod.Get,"/api/Estoque/historico",403,token:clienteToken);
            await E(HttpMethod.Get,"/api/Produtos/administracao",403,token:clienteToken);
            var p=await E(HttpMethod.Post,"/api/Produtos",201,Produto(nome,roupas,new { cor="Azul",tamanho="P",estoqueInicial=5,estoqueMinimo=2 }),equipeToken);
            var id=p.GetProperty("id").GetInt32();
            var path="/api/Produtos/"+id;
            var v=p.GetProperty("variacoes")[0]; var vid=v.GetProperty("id").GetInt32();
            var versao=v.GetProperty("versao").GetString()!;
            Check(p.GetProperty("estoque").GetInt32()==5,"Produto criado com saldo inicial da variação");
            await E(HttpMethod.Post,path+"/variacoes",403,new { cor="Azul",tamanho="M" },clienteToken);
            await E(HttpMethod.Post,path+"/variacoes",400,new { cor="Azul",tamanho="18" },equipeToken);
            p=await E(HttpMethod.Post,path+"/variacoes",201,new { cor="Azul",tamanho="M",estoqueInicial=3,estoqueMinimo=1 },equipeToken);
            Check(p.GetProperty("estoque").GetInt32()==8,"Saldo do produto soma variações sem duplicar unidades");
            await E(HttpMethod.Post,path+"/variacoes",409,new { cor="azul",tamanho="m",estoqueInicial=3 },equipeToken);
            await E(HttpMethod.Post,"/api/Produtos",400,Produto(nome,999999,new { cor="Azul",tamanho="P" }),adminToken);
            var shoe=await E(HttpMethod.Post,"/api/Produtos",201,Produto(nomeCalcado,calcados,new { cor="Rosa",tamanho="18",estoqueInicial=0 }),adminToken);
            await E(HttpMethod.Post,"/api/Produtos/"+shoe.GetProperty("id").GetInt32()+"/variacoes",400,new { cor="Rosa",tamanho="P" },adminToken);
            var movPath="/api/Estoque/variacoes/"+vid+"/movimentacoes";
            var operacao=Guid.NewGuid(); var entrada=Mov("Entrada",2,versao,operacao);
            await E(HttpMethod.Post,movPath,403,entrada,clienteToken);
            var first=await E(HttpMethod.Post,movPath,200,entrada,equipeToken);
            var replay=await E(HttpMethod.Post,movPath,200,entrada,equipeToken);
            Check(first.GetProperty("movimentoId").GetInt64()==replay.GetProperty("movimentoId").GetInt64(),"Repetição da operação retorna o mesmo registro");
            await E(HttpMethod.Post,movPath,409,Mov("Entrada",3,versao,operacao),equipeToken);
            await E(HttpMethod.Post,movPath,409,Mov("Entrada",1,versao),equipeToken);
            p=await E(HttpMethod.Get,path,200);
            v=p.GetProperty("variacoes").EnumerateArray().Single(v=>v.GetProperty("id").GetInt32()==vid);
            Check(v.GetProperty("estoque").GetInt32()==7 && p.GetProperty("estoque").GetInt32()==10,"Entrada repetida não duplica estoque físico nem agregado");
            versao=v.GetProperty("versao").GetString()!;
            await E(HttpMethod.Post,movPath,400,Mov("Ajuste",-1,versao),equipeToken);
            await E(HttpMethod.Post,movPath,400,Mov("Entrada",0,versao),equipeToken);
            await E(HttpMethod.Post,movPath,400,Mov("Entrada",1,versao,Guid.Empty),equipeToken);
            await E(HttpMethod.Post,movPath,200,Mov("Ajuste",1,versao),equipeToken);
            p=await E(HttpMethod.Get,path,200);
            v=p.GetProperty("variacoes").EnumerateArray().Single(v=>v.GetProperty("id").GetInt32()==vid);
            Check(v.GetProperty("disponivel").GetInt32()==1 && v.GetProperty("estoqueBaixo").GetBoolean(),"Ajuste substitui o saldo e aciona o alerta configurado");
            var alertas=await E(HttpMethod.Get,"/api/Estoque/alertas",200,token:equipeToken);
            Check(alertas.EnumerateArray().Any(a=>a.GetProperty("id").GetInt32()==vid),"Variação aparece no alerta da equipe");

            versao=v.GetProperty("versao").GetString()!;
            var concorrentes=await Task.WhenAll(send(HttpMethod.Post,movPath,Mov("Entrada",1,versao),equipeToken),
                send(HttpMethod.Post,movPath,Mov("Entrada",1,versao),equipeToken));
            Check(concorrentes.Count(r=>r.Status==200)==1 && concorrentes.Count(r=>r.Status==409)==1,"Operações concorrentes não sobrescrevem o mesmo saldo");
            await db.ProdutoVariacoes.Where(v=>v.Id==vid).ExecuteUpdateAsync(u=>u.SetProperty(v=>v.Reservado,1));
            p=await E(HttpMethod.Get,path,200);
            v=p.GetProperty("variacoes").EnumerateArray().Single(v=>v.GetProperty("id").GetInt32()==vid);
            versao=v.GetProperty("versao").GetString()!;
            await E(HttpMethod.Post,movPath,409,Mov("Ajuste",0,versao),equipeToken);
            await E(HttpMethod.Delete,path,409,token:adminToken);
            await E(HttpMethod.Put,path+"/variacoes/"+vid,409,new { cor="Azul",tamanho="P",estoqueMinimo=2,versao,ativo=false },equipeToken);
            await db.ProdutoVariacoes.Where(v=>v.Id==vid).ExecuteUpdateAsync(u=>u.SetProperty(v=>v.Reservado,0));
            p=await E(HttpMethod.Get,path,200);
            v=p.GetProperty("variacoes").EnumerateArray().Single(v=>v.GetProperty("id").GetInt32()==vid);
            await E(HttpMethod.Put,path+"/variacoes/"+vid,409,new { cor="Azul",tamanho="P",estoqueMinimo=2,versao },equipeToken);
            versao=v.GetProperty("versao").GetString()!;
            await E(HttpMethod.Put,path+"/variacoes/"+vid,200,new { cor="Azul",tamanho="P",estoqueMinimo=4,versao,ativo=false },equipeToken);
            var publico=await E(HttpMethod.Get,path,200);
            Check(publico.GetProperty("variacoes").EnumerateArray().All(v=>v.GetProperty("id").GetInt32()!=vid),"Variação inativa não aparece para o cliente");
            var historico=await E(HttpMethod.Get,"/api/Estoque/historico?produtoId="+id,200,token:equipeToken);
            Check(historico.GetArrayLength()==5,"Histórico registra dois saldos iniciais, entrada, ajuste e entrada concorrente única");
            Check(historico.EnumerateArray().All(m=>!string.IsNullOrEmpty(m.GetProperty("responsavel").GetString())),"Movimentações identificam seus responsáveis");
            Check(await db.Produtos.AsNoTracking().Where(p=>p.Id==id).Select(p=>p.Estoque).SingleAsync()==3,"Trigger mantém o agregado somente das variações ativas");
            await E(HttpMethod.Delete,path,200,token:equipeToken);
            await E(HttpMethod.Get,path,404);
            Check(await db.Produtos.AsNoTracking().AnyAsync(p=>p.Id==id && !p.Ativo),"Desativar produto preserva suas variações e seu histórico");
        }
        finally
        {
            var ids=await db.Produtos.AsNoTracking().Where(p=>p.Nome==nome || p.Nome==nomeCalcado).Select(p=>p.Id).ToListAsync();
            var variacoes=await db.ProdutoVariacoes.AsNoTracking().Where(v=>ids.Contains(v.ProdutoId)).Select(v=>v.Id).ToListAsync();
            await db.MovimentacoesEstoque.Where(m=>variacoes.Contains(m.VariacaoId)).ExecuteDeleteAsync();
            await db.ProdutoVariacoes.Where(v=>variacoes.Contains(v.Id)).ExecuteDeleteAsync();
            await db.Produtos.Where(p=>ids.Contains(p.Id)).ExecuteDeleteAsync();
            Console.WriteLine("Produtos e movimentações temporários removidos.");
        }
        return count;
    }
}
