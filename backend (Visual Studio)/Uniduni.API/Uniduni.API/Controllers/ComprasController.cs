using System.Security.Claims;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Microsoft.Data.SqlClient;
using Uniduni.API.Contracts;
using Uniduni.API.Data;
using Uniduni.API.Security;
using Uniduni.API.Services;

namespace Uniduni.API.Controllers;
[ApiController,Route("api/compras"),Authorize]
public class ComprasController(ComprasService compras,AppDbContext db) : ControllerBase
{
    private int UsuarioId=>int.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!);
    private bool Equipe=>User.IsInRole(Perfis.Administrador)||User.IsInRole(Perfis.Funcionario);
    private async Task<IActionResult> Acao(Func<Task<object>> executar)
    {
        try {return Ok(await executar());}
        catch(CompraException ex){return StatusCode(ex.Status,new{mensagem=ex.Message});}
        catch(DbUpdateConcurrencyException){return Conflict(new{mensagem="Os dados mudaram. Atualize e tente novamente."});}
        catch(SqlException ex) when(ex.Number is 51009 or 1205){return Conflict(new{mensagem="Outra operação está atualizando estes dados. Tente novamente."});}
    }
    [HttpGet("carrinho")]
    public Task<IActionResult> Carrinho()=>Acao(async ()=>{await compras.ExpirarAsync();return await compras.Carrinho(UsuarioId);});
    [HttpPut("carrinho")]
    public Task<IActionResult> Carrinho(CarrinhoRequest r)=>Acao(()=>compras.Executar(()=>compras.AlterarCarrinho(UsuarioId,r)));
    [HttpPost("pedidos")]
    public Task<IActionResult> Criar(CriarPedidoRequest r)=>Acao(async ()=>{
        var p=await compras.Executar(()=>compras.CriarPedido(UsuarioId,r.OperacaoId));return ComprasService.Resposta(p,UsuarioId);
    });
    [HttpGet("pedidos")]
    public Task<IActionResult> Lista([FromQuery] bool equipe=false)=>Acao(async ()=>{
        if(equipe && !Equipe)throw new CompraException("Acesso restrito à equipe.",403);
        await compras.ExpirarAsync();
        var lista=await compras.Consulta.AsNoTracking().Where(p=>equipe || p.UsuarioId==UsuarioId).OrderByDescending(p=>p.Id).Take(100).ToListAsync();
        return lista.Select(p=>ComprasService.Resposta(p,UsuarioId)).ToList();
    });
    [HttpGet("pedidos/{id:int}")]
    public Task<IActionResult> Detalhe(int id)=>Acao(async ()=>{await compras.ExpirarAsync();return ComprasService.Resposta(await compras.Pedido(id,UsuarioId,Equipe),UsuarioId);});
    [HttpPost("pedidos/{id:int}/pagamentos")]
    public Task<IActionResult> Pagar(int id,PagamentoRequest r)=>Acao(async ()=>ComprasService.Resposta(await compras.Executar(()=>compras.Pagar(id,UsuarioId,r)),UsuarioId));
    [HttpPost("pedidos/{id:int}/pagamentos/{pagamentoId:int}/resolver")]
    public Task<IActionResult> Resolver(int id,int pagamentoId,ResolverPagamentoRequest r)=>Acao(async ()=>ComprasService.Resposta(await compras.Executar(()=>compras.Resolver(id,pagamentoId,UsuarioId,r.Resultado)),UsuarioId));
    [HttpPost("pedidos/{id:int}/cancelar")]
    public Task<IActionResult> Cancelar(int id,CancelarPedidoRequest r)=>Acao(async ()=>ComprasService.Resposta(await compras.Executar(()=>compras.Cancelar(id,UsuarioId,Equipe,r.Motivo)),UsuarioId));
    [HttpPost("pedidos/{id:int}/andamento"),Authorize(Roles=Perfis.Equipe)]
    public Task<IActionResult> Andamento(int id,AndamentoPedidoRequest r)=>Acao(async ()=>ComprasService.Resposta(await compras.Executar(()=>compras.Andamento(id,UsuarioId,r)),UsuarioId));
    [HttpGet("resumo"),Authorize(Roles=Perfis.Administrador)]
    public Task<IActionResult> Resumo([FromQuery] DateTime? inicio,[FromQuery] DateTime? fim)=>Acao(async ()=>{
        if(inicio>fim)throw new CompraException("O início deve ser anterior ao fim.",400);
        var q=db.PagamentosSimulados.AsNoTracking().Where(pg=>pg.Status=="Aprovado");
        if(inicio is not null)q=q.Where(pg=>pg.AtualizadoEm>=inicio);
        if(fim is not null)q=q.Where(pg=>pg.AtualizadoEm<fim);
        return new {totalVendido=await q.SumAsync(pg=>(decimal?)pg.Valor)??0m,quantidadeVendas=await q.CountAsync(),simulado=true};
    });
}
