using System.Text.Json;
using Microsoft.EntityFrameworkCore;
using Uniduni.API.Data;

public static class ComprasChecks
{
    public static async Task<int> Run(
        Func<HttpMethod,string,int,object?,string?,Task<JsonElement>> expect,
        Func<HttpMethod,string,object?,string?,Task<(int Status,string Text)>> send,
        AppDbContext db,string prefix,string password,string admin,string cliente,string equipe)
    {
        int n=0;
        void Check(bool ok,string descricao){if(!ok)throw new Exception("FALHOU: "+descricao);n++;Console.WriteLine("OK: "+descricao);}
        Task<JsonElement> E(HttpMethod m,string path,int status,object? dados=null,string? token=null)=>expect(m,path,status,dados,token);
        const string api="/api/compras";
        var idsProdutos=new List<int>();
        try{
            await E(HttpMethod.Get,api+"/carrinho",401);
            await E(HttpMethod.Put,api+"/carrinho",400,new{variacaoId=1,quantidade=100},cliente);
            await E(HttpMethod.Get,api+"/resumo",403,token:cliente);
            await E(HttpMethod.Get,api+"/resumo",403,token:equipe);
            await E(HttpMethod.Get,api+"/pedidos?equipe=true",403,token:cliente);
            var email=prefix+"-segundo@example.invalid";
            await E(HttpMethod.Post,"/api/Usuarios/cadastro",201,new{nome="Segundo cliente",email,senha=password});
            var login=await E(HttpMethod.Post,"/api/Usuarios/login",200,new{email,senha=password});
            var segundo=login.GetProperty("token").GetString()!;
            var categorias=await E(HttpMethod.Get,"/api/Categorias",200);
            var cat=categorias.EnumerateArray().First(c=>c.GetProperty("nome").GetString()=="Roupas").GetProperty("id").GetInt32();
            async Task<(int Produto,int Variacao)> Produto(string sufixo,int saldo){
                var p=await E(HttpMethod.Post,"/api/Produtos",201,new{nome=prefix+"-compra-"+sufixo,descricao="Peça fictícia para testes de compras",preco=25.50m,categoriaId=cat,genero="Unissex",imagem="body-azul.jpg",variacaoInicial=new{cor="Azul",tamanho="P",estoqueInicial=saldo,estoqueMinimo=1}},admin);
                var id=p.GetProperty("id").GetInt32();idsProdutos.Add(id);return(id,p.GetProperty("variacoes")[0].GetProperty("id").GetInt32());
            }
            async Task<(int Estoque,int Reserva)> Saldo(int id){var v=await db.ProdutoVariacoes.AsNoTracking().SingleAsync(v=>v.Id==id);return(v.Estoque,v.Reservado);}
            async Task<int> Checkout(int variacao,string token,int qtd=1){
                await E(HttpMethod.Put,api+"/carrinho",200,new{variacaoId=variacao,quantidade=qtd},token);
                var p=await E(HttpMethod.Post,api+"/pedidos",200,new{operacaoId=Guid.NewGuid(),total=0.01m},token);
                Check(p.GetProperty("total").GetDecimal()==25.50m*qtd,"Preço calculado pelo servidor, ignorando valor adulterado");
                return p.GetProperty("id").GetInt32();
            }
            async Task<JsonElement> Pagar(int id,string token,string resultado,string metodo="Pix",Guid? chave=null)=>
                await E(HttpMethod.Post,$"{api}/pedidos/{id}/pagamentos",200,new{operacaoId=chave??Guid.NewGuid(),metodo,resultado},token);
            var ultimo=await Produto("ultima-unidade",1);
            await E(HttpMethod.Put,api+"/carrinho",200,new{variacaoId=ultimo.Variacao,quantidade=1},cliente);
            await E(HttpMethod.Put,api+"/carrinho",200,new{variacaoId=ultimo.Variacao,quantidade=1},segundo);
            var op1=Guid.NewGuid();var op2=Guid.NewGuid();
            var concorrentes=await Task.WhenAll(send(HttpMethod.Post,api+"/pedidos",new{operacaoId=op1},cliente),send(HttpMethod.Post,api+"/pedidos",new{operacaoId=op2},segundo));
            Check(concorrentes.Count(r=>r.Status==200)==1&&concorrentes.Count(r=>r.Status==409)==1,"Somente um cliente reserva a última unidade");
            var vencedor=concorrentes[0].Status==200?cliente:segundo;var perdedor=vencedor==cliente?segundo:cliente;
            var op=vencedor==cliente?op1:op2;
            var pedido=JsonDocument.Parse(concorrentes.Single(r=>r.Status==200).Text).RootElement;var id=pedido.GetProperty("id").GetInt32();
            var repetido=await E(HttpMethod.Post,api+"/pedidos",200,new{operacaoId=op},vencedor);
            Check(repetido.GetProperty("id").GetInt32()==id,"Repetir finalização devolve o mesmo pedido");
            Check(await Saldo(ultimo.Variacao)==(1,1),"Reserva reduz disponibilidade sem baixar saldo físico");
            await E(HttpMethod.Get,$"{api}/pedidos/{id}",404,token:perdedor);
            await E(HttpMethod.Post,$"{api}/pedidos/{id}/pagamentos",404,new{operacaoId=Guid.NewGuid(),metodo="Pix",resultado="Aprovado"},perdedor);
            var key=Guid.NewGuid();var pago=await Pagar(id,vencedor,"Aprovado","Cartao",key);
            var codigo=pago.GetProperty("codigoRetirada").GetString();
            Check(await Saldo(ultimo.Variacao)==(0,0),"Aprovação baixa uma única unidade e encerra reserva");
            await Pagar(id,vencedor,"Aprovado","Cartao",key);
            Check(await Saldo(ultimo.Variacao)==(0,0),"Pagamento repetido não duplica baixa");
            await E(HttpMethod.Post,$"{api}/pedidos/{id}/pagamentos",409,new{operacaoId=key,metodo="Pix",resultado="Aprovado"},vencedor);
            await E(HttpMethod.Post,$"{api}/pedidos/{id}/andamento",403,new{status="EmPreparacao"},vencedor);
            await E(HttpMethod.Post,$"{api}/pedidos/{id}/andamento",409,new{status="Pronto"},equipe);
            var atendimento=await E(HttpMethod.Get,$"{api}/pedidos/{id}",200,token:equipe);
            Check(atendimento.GetProperty("codigoRetirada").ValueKind==JsonValueKind.Null,"Equipe confere o código apresentado; não recebe o segredo do cliente");
            await E(HttpMethod.Post,$"{api}/pedidos/{id}/andamento",200,new{status="EmPreparacao"},equipe);
            await E(HttpMethod.Post,$"{api}/pedidos/{id}/cancelar",403,new{motivo="Cliente desistiu"},vencedor);
            await E(HttpMethod.Post,$"{api}/pedidos/{id}/andamento",200,new{status="Pronto"},equipe);
            await E(HttpMethod.Post,$"{api}/pedidos/{id}/andamento",400,new{status="Retirado",codigo="errado"},equipe);
            var retirado=await E(HttpMethod.Post,$"{api}/pedidos/{id}/andamento",200,new{status="Retirado",codigo},equipe);
            Check(retirado.GetProperty("retiradoPor").GetInt32()>0&&retirado.GetProperty("retiradoEm").ValueKind==JsonValueKind.String,"Retirada registra operador e instante, sem bloqueio por horário");
            await E(HttpMethod.Post,$"{api}/pedidos/{id}/cancelar",409,new{motivo="Não deve permitir"},equipe);
            await E(HttpMethod.Put,api+"/carrinho",200,new{variacaoId=ultimo.Variacao,quantidade=0},perdedor);

            var estoque=await Produto("fluxos",12);
            id=await Checkout(estoque.Variacao,cliente,2);
            var antes=await db.Produtos.AsNoTracking().Where(p=>p.Id==estoque.Produto).Select(p=>p.Preco).SingleAsync();
            await db.Produtos.Where(p=>p.Id==estoque.Produto).ExecuteUpdateAsync(s=>s.SetProperty(p=>p.Preco,99m));
            var congelado=await E(HttpMethod.Get,$"{api}/pedidos/{id}",200,token:cliente);
            Check(congelado.GetProperty("total").GetDecimal()==51m,"Preço do pedido preservado após alteração do catálogo");
            await db.Produtos.Where(p=>p.Id==estoque.Produto).ExecuteUpdateAsync(s=>s.SetProperty(p=>p.Preco,antes));
            await Pagar(id,cliente,"Recusado");Check(await Saldo(estoque.Variacao)==(12,0),"Recusa libera reserva sem alterar saldo físico");
            var retry=await Pagar(id,cliente,"Pendente");
            Check(await Saldo(estoque.Variacao)==(12,2),"Nova tentativa após recusa reserva novamente as unidades");
            var pg=retry.GetProperty("pagamentos")[0].GetProperty("id").GetInt32();
            Check(retry.GetProperty("pagamentos")[0].GetProperty("codigoPix").GetString()!.StartsWith("SIMULACAO"),"Pix pendente emite somente código fictício");
            await E(HttpMethod.Post,$"{api}/pedidos/{id}/pagamentos/{pg}/resolver",200,new{resultado="Aprovado"},cliente);
            await E(HttpMethod.Post,$"{api}/pedidos/{id}/pagamentos/{pg}/resolver",200,new{resultado="Aprovado"},cliente);
            Check(await Saldo(estoque.Variacao)==(10,0),"Confirmação pendente repetida baixa apenas uma vez");
            var resumoAntes=await E(HttpMethod.Get,api+"/resumo",200,token:admin);
            await E(HttpMethod.Post,$"{api}/pedidos/{id}/cancelar",200,new{motivo="Teste de estorno"},cliente);
            await E(HttpMethod.Post,$"{api}/pedidos/{id}/cancelar",200,new{motivo="Teste de estorno"},cliente);
            Check(await Saldo(estoque.Variacao)==(12,0),"Cancelamento pago e repetição estornam estoque uma única vez");
            var resumoDepois=await E(HttpMethod.Get,api+"/resumo",200,token:admin);
            Check(resumoAntes.GetProperty("totalVendido").GetDecimal()-resumoDepois.GetProperty("totalVendido").GetDecimal()==51m,"Estorno reduz o total vendido");
            id=await Checkout(estoque.Variacao,cliente);
            await E(HttpMethod.Post,$"{api}/pedidos/{id}/cancelar",200,new{motivo="Cancelamento antes de pagar"},cliente);
            Check(await Saldo(estoque.Variacao)==(12,0),"Cancelamento pendente libera a reserva");
            id=await Checkout(estoque.Variacao,cliente);
            var pendente=await Pagar(id,cliente,"Pendente");pg=pendente.GetProperty("pagamentos")[0].GetProperty("id").GetInt32();
            await db.PedidosLoja.Where(p=>p.Id==id).ExecuteUpdateAsync(s=>s.SetProperty(p=>p.ReservaAte,DateTime.UtcNow.AddMinutes(-1)));
            var expirado=await E(HttpMethod.Get,$"{api}/pedidos/{id}",200,token:cliente);
            Check(expirado.GetProperty("status").GetString()=="Expirado"&&await Saldo(estoque.Variacao)==(12,0),"Reserva vencida libera estoque e expira o pedido");
            await E(HttpMethod.Post,$"{api}/pedidos/{id}/pagamentos/{pg}/resolver",409,new{resultado="Aprovado"},cliente);
            await E(HttpMethod.Get,$"{api}/pedidos/{id}",200,token:cliente);
            Check(await Saldo(estoque.Variacao)==(12,0),"Pagamento antigo não reaprova pedido expirado nem duplica liberação");
            id=await Checkout(estoque.Variacao,cliente);await Pagar(id,cliente,"Aprovado");
            await E(HttpMethod.Post,$"{api}/pedidos/{id}/andamento",200,new{status="EmPreparacao"},equipe);
            await E(HttpMethod.Post,$"{api}/pedidos/{id}/cancelar",200,new{motivo="Equipe cancelou durante preparação"},equipe);
            Check(await Saldo(estoque.Variacao)==(12,0),"Equipe pode cancelar em preparação com estorno simulado");
            var movimentos=await db.MovimentacoesEstoque.AsNoTracking().Where(m=>m.VariacaoId==estoque.Variacao).ToListAsync();
            Check(movimentos.Any(m=>m.Tipo=="Reserva"&&m.ReservadoAtual>m.ReservadoAnterior)&&movimentos.Any(m=>m.Tipo=="Estorno"),"Histórico registra reservas, liberações, vendas e estornos");
            var indisponivel=await Produto("rollback",1);
            await E(HttpMethod.Put,api+"/carrinho",200,new{variacaoId=estoque.Variacao,quantidade=1},cliente);
            await E(HttpMethod.Put,api+"/carrinho",200,new{variacaoId=indisponivel.Variacao,quantidade=1},cliente);
            await db.ProdutoVariacoes.Where(v=>v.Id==indisponivel.Variacao).ExecuteUpdateAsync(s=>s.SetProperty(v=>v.Estoque,0));
            await E(HttpMethod.Post,api+"/pedidos",409,new{operacaoId=Guid.NewGuid()},cliente);
            Check(await Saldo(estoque.Variacao)==(12,0),"Falha em outro item desfaz a reserva parcial da transação");
            var carrinhoPreservado=await E(HttpMethod.Get,api+"/carrinho",200,token:cliente);
            Check(carrinhoPreservado.GetProperty("itens").GetArrayLength()==2,"Falha ao finalizar preserva o carrinho para correção");
            await E(HttpMethod.Put,api+"/carrinho",200,new{variacaoId=estoque.Variacao,quantidade=0},cliente);
            await E(HttpMethod.Put,api+"/carrinho",200,new{variacaoId=indisponivel.Variacao,quantidade=0},cliente);
            var recusado=await Checkout(estoque.Variacao,cliente,12);await Pagar(recusado,cliente,"Recusado");
            var concorrente=await Checkout(estoque.Variacao,segundo,12);
            await E(HttpMethod.Post,$"{api}/pedidos/{recusado}/pagamentos",409,new{operacaoId=Guid.NewGuid(),metodo="Cartao",resultado="Aprovado"},cliente);
            Check(await Saldo(estoque.Variacao)==(12,12),"Nova tentativa recusada não toma reserva feita por outro cliente");
            await E(HttpMethod.Post,$"{api}/pedidos/{concorrente}/cancelar",200,new{motivo="Liberar compra de teste"},segundo);
            await E(HttpMethod.Post,$"{api}/pedidos/{recusado}/cancelar",200,new{motivo="Encerrar teste de recusa"},cliente);
            var corrida=await Checkout(estoque.Variacao,cliente);var tentativa=await Pagar(corrida,cliente,"Pendente");
            pg=tentativa.GetProperty("pagamentos")[0].GetProperty("id").GetInt32();
            var acoes=await Task.WhenAll(send(HttpMethod.Post,$"{api}/pedidos/{corrida}/pagamentos/{pg}/resolver",new{resultado="Aprovado"},cliente),send(HttpMethod.Post,$"{api}/pedidos/{corrida}/cancelar",new{motivo="Cancelar durante confirmação"},cliente));
            Check(acoes.All(a=>a.Status is 200 or 409),"Aprovação e cancelamento concorrentes retornam resultados controlados");
            var finalCorrida=await E(HttpMethod.Get,$"{api}/pedidos/{corrida}",200,token:cliente);
            Check(finalCorrida.GetProperty("status").GetString()=="Cancelado"&&await Saldo(estoque.Variacao)==(12,0),"Concorrência entre aprovação e cancelamento conserva o saldo");
            var desativacao=await Produto("desativacao-concorrente",1);
            await E(HttpMethod.Put,api+"/carrinho",200,new{variacaoId=desativacao.Variacao,quantidade=1},cliente);
            var conflitoCatalogo=await Task.WhenAll(send(HttpMethod.Post,api+"/pedidos",new{operacaoId=Guid.NewGuid()},cliente),send(HttpMethod.Delete,"/api/Produtos/"+desativacao.Produto,null,equipe));
            Check((conflitoCatalogo[0].Status==200&&conflitoCatalogo[1].Status==409)||(conflitoCatalogo[0].Status==409&&conflitoCatalogo[1].Status==200),"Desativação e reserva concorrentes respeitam a mesma proteção transacional");
            if(conflitoCatalogo[0].Status==200){
                var d=JsonDocument.Parse(conflitoCatalogo[0].Text).RootElement.GetProperty("id").GetInt32();
                await E(HttpMethod.Post,$"{api}/pedidos/{d}/cancelar",200,new{motivo="Encerrar teste de desativação"},cliente);
            }
            await E(HttpMethod.Put,api+"/carrinho",200,new{variacaoId=desativacao.Variacao,quantidade=0},cliente);
            var reservaSemTela=await Checkout(estoque.Variacao,cliente);
            await db.PedidosLoja.Where(p=>p.Id==reservaSemTela).ExecuteUpdateAsync(s=>s.SetProperty(p=>p.ReservaAte,DateTime.UtcNow.AddMinutes(-1)));
            // Verifica o trabalhador em segundo plano sem chamar uma rota de compras.
            var prazo=DateTime.UtcNow.AddSeconds(38);bool liberado=false;
            while(DateTime.UtcNow<prazo){
                if(await db.PedidosLoja.AsNoTracking().AnyAsync(p=>p.Id==reservaSemTela&&p.Status=="Expirado")){liberado=true;break;}
                await Task.Delay(1000);
            }
            Check(liberado&&await Saldo(estoque.Variacao)==(12,0),"Reserva expira em segundo plano sem manter o navegador aberto");
            return n;
        }finally{
            var users=await db.Usuarios.AsNoTracking().Where(u=>u.Email.StartsWith(prefix)).Select(u=>u.Id).ToListAsync();
            var pedidos=await db.PedidosLoja.Where(p=>users.Contains(p.UsuarioId)).Select(p=>p.Id).ToListAsync();
            await db.EventosPedidoLoja.Where(ev=>pedidos.Contains(ev.PedidoId)).ExecuteDeleteAsync();
            await db.PagamentosSimulados.Where(pg=>pedidos.Contains(pg.PedidoId)).ExecuteDeleteAsync();
            await db.ItensPedidoLoja.Where(i=>pedidos.Contains(i.PedidoId)).ExecuteDeleteAsync();
            await db.PedidosLoja.Where(p=>pedidos.Contains(p.Id)).ExecuteDeleteAsync();
            await db.CarrinhoItensLoja.Where(i=>users.Contains(i.UsuarioId)).ExecuteDeleteAsync();
            var vs=await db.ProdutoVariacoes.Where(v=>idsProdutos.Contains(v.ProdutoId)).Select(v=>v.Id).ToListAsync();
            await db.MovimentacoesEstoque.Where(m=>vs.Contains(m.VariacaoId)).ExecuteDeleteAsync();
            await db.ProdutoVariacoes.Where(v=>vs.Contains(v.Id)).ExecuteDeleteAsync();
            await db.Produtos.Where(p=>idsProdutos.Contains(p.Id)).ExecuteDeleteAsync();
            Console.WriteLine("Pedidos, pagamentos e produtos temporários de compras removidos.");
        }
    }
}
