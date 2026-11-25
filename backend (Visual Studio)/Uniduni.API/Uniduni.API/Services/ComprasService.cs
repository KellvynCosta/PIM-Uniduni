using System.Data;
using System.Security.Cryptography;
using Microsoft.EntityFrameworkCore;
using Uniduni.API.Contracts;
using Uniduni.API.Data;
using Uniduni.API.Models;

namespace Uniduni.API.Services;

public sealed class CompraException(string message,int status=409) : Exception(message)
{ public int Status { get; } = status; }

// Um lock transacional coordena os fluxos comerciais deste projeto de loja única.
// As atualizações condicionais também protegem contra ajustes concorrentes da equipe.
public class ComprasService(AppDbContext db)
{
    public IQueryable<PedidoLoja> Consulta => db.PedidosLoja.Include(p=>p.Usuario)
        .Include(p=>p.Itens).Include(p=>p.Pagamentos).Include(p=>p.Eventos).AsSplitQuery();
    private static DateTime Agora => DateTime.UtcNow;
    private Task Lock() => db.Database.ExecuteSqlRawAsync("DECLARE @r int; EXEC @r=sys.sp_getapplock @Resource=N'UniduniCompras',@LockMode='Exclusive',@LockOwner='Transaction',@LockTimeout=15000; IF @r<0 THROW 51009,'Operação ocupada. Tente novamente.',1;");
    public Task BloquearCatalogoAsync() => Lock();
    private async Task<T> Transacao<T>(Func<Task<T>> action)
    {
        await using var tx=await db.Database.BeginTransactionAsync(IsolationLevel.ReadCommitted);
        await Lock();
        var result=await action();
        await db.SaveChangesAsync(); await tx.CommitAsync(); return result;
    }
    public async Task<T> Executar<T>(Func<Task<T>> action)
    {
        await ExpirarAsync();
        return await Transacao(action);
    }
    private static void Evento(PedidoLoja p,int? user,string texto) => p.Eventos.Add(new(){UsuarioId=user,Descricao=texto,CriadoEm=Agora});
    private async Task Movimento(PedidoLoja p,ItemPedidoLoja item,string tipo,int? user)
    {
        var v=await db.ProdutoVariacoes.AsNoTracking().SingleAsync(v=>v.Id==item.VariacaoId);
        int qtd=item.Quantidade, fisico=v.Estoque, reservado=v.Reservado;
        var (df,dr)=tipo switch { "Reserva"=>(0,qtd),"Liberacao"=>(0,-qtd),"Venda"=>(-qtd,-qtd),"Estorno"=>(qtd,0),_=>throw new InvalidOperationException() };
        int alteradas;
        if(tipo=="Reserva")
            alteradas=await db.Database.ExecuteSqlInterpolatedAsync($"UPDATE v SET Reservado=Reservado+{qtd} FROM dbo.ProdutoVariacoes v JOIN dbo.Produtos p ON p.Id=v.ProdutoId WHERE v.Id={v.Id} AND v.Ativo=1 AND p.Ativo=1 AND v.Estoque-v.Reservado>={qtd} AND v.Versao={v.Versao}");
        else
            alteradas=await db.Database.ExecuteSqlInterpolatedAsync($"UPDATE dbo.ProdutoVariacoes SET Estoque=Estoque+{df}, Reservado=Reservado+{dr} WHERE Id={v.Id} AND Versao={v.Versao} AND Reservado+{dr}>=0 AND Estoque+{df}>=Reservado+{dr} AND CAST(Estoque AS BIGINT)+{df}<=2147483647");
        if(alteradas!=1) throw new CompraException($"O estoque de {item.Nome} ({item.Cor}, {item.Tamanho}) mudou ou é insuficiente. Atualize e tente novamente.");
        var responsavel=user is null ? "Sistema — reserva vencida" : await db.Usuarios.Where(u=>u.Id==user).Select(u=>u.Nome).SingleAsync();
        db.MovimentacoesEstoque.Add(new(){VariacaoId=v.Id,UsuarioId=user,Responsavel=responsavel,Tipo=tipo,Quantidade=df,
            SaldoAnterior=fisico,SaldoAtual=fisico+df,ReservadoAnterior=reservado,ReservadoAtual=reservado+dr,
            Justificativa=$"{tipo} do pedido #{p.Id}.",OperacaoId=Guid.NewGuid(),CriadaEm=Agora});
    }
    public Task<int> ExpirarAsync() => Transacao(async ()=>{
        var vencidos=await Consulta.Where(p=>p.Status=="Pendente" && p.ReservaAte<=Agora).ToListAsync();
        foreach(var p in vencidos){
            foreach(var i in p.Itens.OrderBy(i=>i.VariacaoId)) await Movimento(p,i,"Liberacao",null);
            p.Status="Expirado";p.ReservaAte=null;
            foreach(var pg in p.Pagamentos.Where(pg=>pg.Status=="Pendente")){pg.Status="Expirado";pg.AtualizadoEm=Agora;}
            Evento(p,null,"Reserva de 30 minutos vencida; estoque liberado.");
        }
        return vencidos.Count;
    });
    public async Task<object> Carrinho(int user)
    {
        var itens=await db.CarrinhoItensLoja.AsNoTracking().Where(i=>i.UsuarioId==user)
            .Include(i=>i.Variacao).ThenInclude(v=>v.Produto).OrderBy(i=>i.VariacaoId).ToListAsync();
        return new { itens=itens.Select(i=>new {i.VariacaoId,i.Quantidade,i.Variacao.Produto.Nome,i.Variacao.Cor,i.Variacao.Tamanho,i.Variacao.Produto.Imagem,
            Preco=i.Variacao.Produto.Preco,Subtotal=i.Quantidade*i.Variacao.Produto.Preco,Disponivel=i.Variacao.Estoque-i.Variacao.Reservado,
            Ativo=i.Variacao.Ativo && i.Variacao.Produto.Ativo}),total=itens.Sum(i=>i.Quantidade*i.Variacao.Produto.Preco)};
    }
    public async Task<object> AlterarCarrinho(int user,CarrinhoRequest r)
    {
        var item=await db.CarrinhoItensLoja.FindAsync(user,r.VariacaoId);
        if(r.Quantidade==0){if(item is not null)db.Remove(item);}
        else {
            var v=await db.ProdutoVariacoes.AsNoTracking().Include(v=>v.Produto).SingleOrDefaultAsync(v=>v.Id==r.VariacaoId);
            if(v is null || !v.Ativo || !v.Produto.Ativo)throw new CompraException("Esta variação não está mais disponível.");
            if(v.Estoque-v.Reservado<r.Quantidade)throw new CompraException("Quantidade maior que o estoque disponível.");
            if(item is null){
                if(await db.CarrinhoItensLoja.CountAsync(i=>i.UsuarioId==user)>=50)throw new CompraException("O carrinho aceita até 50 combinações diferentes.");
                db.Add(new CarrinhoItemLoja{UsuarioId=user,VariacaoId=r.VariacaoId,Quantidade=r.Quantidade});
            }else item.Quantidade=r.Quantidade;
        }
        await db.SaveChangesAsync();return await Carrinho(user);
    }
    public async Task<PedidoLoja> CriarPedido(int user,Guid operacao)
    {
        if(operacao==Guid.Empty)throw new CompraException("Informe o identificador da operação.",400);
        var anterior=await Consulta.SingleOrDefaultAsync(p=>p.UsuarioId==user && p.OperacaoId==operacao);
        if(anterior is not null)return anterior;
        var carrinho=await db.CarrinhoItensLoja.Where(i=>i.UsuarioId==user).Include(i=>i.Variacao).ThenInclude(v=>v.Produto).OrderBy(i=>i.VariacaoId).ToListAsync();
        if(carrinho.Count==0)throw new CompraException("Seu carrinho está vazio.",400);
        var p=new PedidoLoja{UsuarioId=user,OperacaoId=operacao,CriadoEm=Agora,ReservaAte=Agora.AddMinutes(30),CodigoRetirada=Convert.ToHexString(RandomNumberGenerator.GetBytes(4))};
        foreach(var c in carrinho)p.Itens.Add(new(){VariacaoId=c.VariacaoId,Quantidade=c.Quantidade,Nome=c.Variacao.Produto.Nome,Cor=c.Variacao.Cor,
            Tamanho=c.Variacao.Tamanho,Imagem=c.Variacao.Produto.Imagem,PrecoUnitario=c.Variacao.Produto.Preco});
        p.Total=p.Itens.Sum(i=>i.PrecoUnitario*i.Quantidade);
        if(p.Total>9_999_999_999.99m)throw new CompraException("O total excede o limite do pedido. Reduza as quantidades.",400);
        db.PedidosLoja.Add(p);await db.SaveChangesAsync();
        foreach(var i in p.Itens)await Movimento(p,i,"Reserva",user);
        db.RemoveRange(carrinho);Evento(p,user,"Pedido criado; itens reservados por 30 minutos.");return p;
    }
    public async Task<PedidoLoja> Pedido(int id,int user,bool equipe=false)
    {
        var p=await Consulta.SingleOrDefaultAsync(p=>p.Id==id && (p.UsuarioId==user || equipe));
        return p ?? throw new CompraException("Pedido não encontrado.",404);
    }
    public async Task<PedidoLoja> Pagar(int id,int user,PagamentoRequest r)
    {
        if(r.OperacaoId==Guid.Empty)throw new CompraException("Informe o identificador da operação.",400);
        var p=await Pedido(id,user);
        var anterior=p.Pagamentos.SingleOrDefault(pg=>pg.OperacaoId==r.OperacaoId);
        if(anterior is not null){
            if(anterior.Metodo!=r.Metodo || anterior.ResultadoSolicitado!=r.Resultado)throw new CompraException("Identificador já usado em outro pagamento.");
            return p;
        }
        if(p.Status is not ("Pendente" or "Recusado"))throw new CompraException("Este pedido não aceita outra tentativa de pagamento.");
        if(p.Status=="Pendente" && p.ReservaAte<=Agora)throw new CompraException("A reserva venceu. Atualize o pedido.");
        if(p.Pagamentos.Any(pg=>pg.Status=="Pendente"))throw new CompraException("Resolva a tentativa pendente antes de iniciar outra.");
        if(p.Pagamentos.Count>=30)throw new CompraException("Limite de tentativas atingido. Cancele e crie outro pedido.");
        if(p.Status=="Recusado"){
            foreach(var i in p.Itens.OrderBy(i=>i.VariacaoId))await Movimento(p,i,"Reserva",user);
            p.Status="Pendente";p.ReservaAte=Agora.AddMinutes(30);
        }
        var pg=new PagamentoSimulado{OperacaoId=r.OperacaoId,Metodo=r.Metodo,ResultadoSolicitado=r.Resultado,Status="Pendente",Valor=p.Total,CriadoEm=Agora,AtualizadoEm=Agora};
        p.Pagamentos.Add(pg);
        if(r.Resultado!="Pendente")await FinalizarPagamento(p,pg,r.Resultado,user);
        else Evento(p,user,$"Pagamento {r.Metodo} simulado aguardando resultado.");
        return p;
    }
    public async Task<PedidoLoja> Resolver(int id,int pagamentoId,int user,string resultado)
    {
        var p=await Pedido(id,user);var pg=p.Pagamentos.SingleOrDefault(pg=>pg.Id==pagamentoId) ?? throw new CompraException("Tentativa não encontrada.",404);
        if(pg.Status==resultado && p.Status is "Pago" or "Recusado")return p;
        if(pg.Status!="Pendente" || p.Status!="Pendente" || p.ReservaAte<=Agora)throw new CompraException("Esta tentativa não pode mais ser confirmada.");
        await FinalizarPagamento(p,pg,resultado,user);return p;
    }
    private async Task FinalizarPagamento(PedidoLoja p,PagamentoSimulado pg,string resultado,int user)
    {
        foreach(var i in p.Itens.OrderBy(i=>i.VariacaoId))await Movimento(p,i,resultado=="Aprovado" ? "Venda" : "Liberacao",user);
        pg.Status=resultado;pg.AtualizadoEm=Agora;p.ReservaAte=null;p.Status=resultado=="Aprovado"?"Pago":"Recusado";
        if(resultado=="Aprovado")p.PagoEm=Agora;
        Evento(p,user,$"Pagamento {pg.Metodo} simulado {resultado.ToLowerInvariant()}.");
    }
    public async Task<PedidoLoja> Cancelar(int id,int user,bool equipe,string motivo)
    {
        if(motivo.Trim().Length<5)throw new CompraException("Informe o motivo do cancelamento.",400);
        var p=await Pedido(id,user,equipe);
        if(p.Status=="Cancelado")return p;
        if(p.Status is "Retirado" or "Expirado")throw new CompraException("Este pedido não pode ser cancelado.");
        if(!equipe && p.Status is "EmPreparacao" or "Pronto")throw new CompraException("A preparação já começou. Solicite o cancelamento à equipe.",403);
        if(p.Status=="Pendente")foreach(var i in p.Itens.OrderBy(i=>i.VariacaoId))await Movimento(p,i,"Liberacao",user);
        var aprovado=p.Pagamentos.SingleOrDefault(pg=>pg.Status=="Aprovado");
        if(aprovado is not null){
            foreach(var i in p.Itens.OrderBy(i=>i.VariacaoId))await Movimento(p,i,"Estorno",user);
            aprovado.Status="Estornado";aprovado.AtualizadoEm=Agora;
        }
        foreach(var pg in p.Pagamentos.Where(pg=>pg.Status=="Pendente")){pg.Status="Cancelado";pg.AtualizadoEm=Agora;}
        p.Status="Cancelado";p.CanceladoEm=Agora;p.ReservaAte=null;
        Evento(p,user,$"Cancelado: {motivo.Trim()}."+(aprovado is null ? "" : " Estorno simulado concluído."));return p;
    }
    public async Task<PedidoLoja> Andamento(int id,int user,AndamentoPedidoRequest r)
    {
        var p=await Pedido(id,user,true);
        if(r.Status=="Retirado" && !string.Equals(p.CodigoRetirada,r.Codigo?.Trim(),StringComparison.OrdinalIgnoreCase))throw new CompraException("Código de retirada incorreto.",400);
        if(p.Status==r.Status)return p;
        var esperado=r.Status switch {"EmPreparacao"=>"Pago","Pronto"=>"EmPreparacao","Retirado"=>"Pronto",_=>""};
        if(p.Status!=esperado)throw new CompraException("O pedido não está na etapa anterior necessária.");
        p.Status=r.Status;
        if(r.Status=="Retirado"){p.RetiradoEm=Agora;p.RetiradoPor=user;}
        Evento(p,user,$"Etapa alterada para {r.Status}.");return p;
    }
    public static object Resposta(PedidoLoja p,int user) => new {p.Id,p.UsuarioId,Cliente=p.Usuario?.Nome,p.Status,p.Total,
        CriadoEm=Utc(p.CriadoEm),ReservaAte=Utc(p.ReservaAte),PagoEm=Utc(p.PagoEm),CanceladoEm=Utc(p.CanceladoEm),
        CodigoRetirada=p.UsuarioId==user ? p.CodigoRetirada : null,RetiradoEm=Utc(p.RetiradoEm),p.RetiradoPor,
        Itens=p.Itens.Select(i=>new{i.Id,i.VariacaoId,i.Nome,i.Cor,i.Tamanho,i.Imagem,i.Quantidade,i.PrecoUnitario,Subtotal=i.Quantidade*i.PrecoUnitario}),
        Pagamentos=p.Pagamentos.OrderByDescending(pg=>pg.Id).Select(pg=>new{pg.Id,pg.Metodo,pg.Status,pg.Valor,CriadoEm=Utc(pg.CriadoEm),AtualizadoEm=Utc(pg.AtualizadoEm),
            CodigoPix=pg.Metodo=="Pix" && pg.Status=="Pendente" ? $"SIMULACAO-UNIDUNI-PEDIDO-{p.Id}-TENTATIVA-{pg.Id}-SEM-VALOR-FINANCEIRO" : null}),
        Eventos=p.Eventos.OrderBy(ev=>ev.Id).Select(ev=>new{ev.Descricao,CriadoEm=Utc(ev.CriadoEm),ev.UsuarioId})};
    private static DateTime? Utc(DateTime? d)=>d is null?null:DateTime.SpecifyKind(d.Value,DateTimeKind.Utc);
}

public sealed class ExpiracaoReservasService(IServiceScopeFactory scopes,ILogger<ExpiracaoReservasService> log) : BackgroundService
{
    protected override async Task ExecuteAsync(CancellationToken stoppingToken)
    {
        using var timer=new PeriodicTimer(TimeSpan.FromSeconds(30));
        do {
            try { using var scope=scopes.CreateScope();await scope.ServiceProvider.GetRequiredService<ComprasService>().ExpirarAsync(); }
            catch(Exception ex){log.LogError(ex,"Falha ao liberar reservas vencidas; nova tentativa em 30 segundos.");}
        } while(await timer.WaitForNextTickAsync(stoppingToken));
    }
}
