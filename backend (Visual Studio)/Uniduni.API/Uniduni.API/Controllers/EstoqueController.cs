using System.Data;
using System.Security.Claims;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Data.SqlClient;
using Microsoft.EntityFrameworkCore;
using Uniduni.API.Contracts;
using Uniduni.API.Data;
using Uniduni.API.Security;
using Uniduni.API.Services;

namespace Uniduni.API.Controllers;

[ApiController,Route("api/[controller]"),Authorize(Roles=Perfis.Equipe)]
public class EstoqueController(AppDbContext db) : ControllerBase
{
    [HttpGet("alertas")]
    public async Task<IActionResult> Alertas() => Ok(await db.ProdutoVariacoes.AsNoTracking()
        .Where(v=>v.Ativo && v.Produto.Ativo && v.Estoque-v.Reservado<=v.EstoqueMinimo)
        .OrderBy(v=>v.Estoque-v.Reservado).ThenBy(v=>v.Produto.Nome)
        .Select(v=>new { v.Id,v.ProdutoId,Produto=v.Produto.Nome,v.Cor,v.Tamanho,
            Disponivel=v.Estoque-v.Reservado,v.EstoqueMinimo }).ToListAsync());

    [HttpGet("historico")]
    public async Task<IActionResult> Historico([FromQuery] int? produtoId,[FromQuery] int? variacaoId,[FromQuery] int limite=50)
    {
        var q=db.MovimentacoesEstoque.AsNoTracking().AsQueryable();
        if(produtoId is not null) q=q.Where(m=>m.Variacao.ProdutoId==produtoId);
        if(variacaoId is not null) q=q.Where(m=>m.VariacaoId==variacaoId);
        var movimentos=await q.OrderByDescending(m=>m.Id).Take(Math.Clamp(limite,1,200))
            .Select(m=>new { m.Id,m.VariacaoId,Produto=m.Variacao.Produto.Nome,m.Variacao.Cor,m.Variacao.Tamanho,
                m.Tipo,m.Quantidade,m.SaldoAnterior,m.SaldoAtual,m.ReservadoAnterior,m.ReservadoAtual,m.Responsavel,m.Justificativa,m.CriadaEm }).ToListAsync();
        return Ok(movimentos.Select(m=>new { m.Id,m.VariacaoId,m.Produto,m.Cor,m.Tamanho,m.Tipo,m.Quantidade,
            m.SaldoAnterior,m.SaldoAtual,m.ReservadoAnterior,m.ReservadoAtual,m.Responsavel,m.Justificativa,CriadaEm=DateTime.SpecifyKind(m.CriadaEm,DateTimeKind.Utc) }));
    }

    [HttpPost("variacoes/{id:int}/movimentacoes")]
    public async Task<IActionResult> Movimentar(int id,MovimentarEstoqueRequest r,CancellationToken ct)
    {
        if(r.OperacaoId==Guid.Empty) return BadRequest("Informe um identificador para a operação.");
        if(!CatalogoService.LerVersao(r.Versao,out var versao)) return BadRequest("Versão de estoque inválida.");
        await db.Database.OpenConnectionAsync(ct);
        await using var command=db.Database.GetDbConnection().CreateCommand();
        command.CommandText="dbo.usp_MovimentarEstoque"; command.CommandType=CommandType.StoredProcedure;
        command.Parameters.Add(new SqlParameter("@VariacaoId",id));
        command.Parameters.Add(new SqlParameter("@UsuarioId",int.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!)));
        command.Parameters.Add(new SqlParameter("@Tipo",SqlDbType.NVarChar,20) { Value=r.Tipo });
        command.Parameters.Add(new SqlParameter("@Quantidade",r.Quantidade));
        command.Parameters.Add(new SqlParameter("@Justificativa",SqlDbType.NVarChar,250) { Value=r.Justificativa.Trim() });
        command.Parameters.Add(new SqlParameter("@OperacaoId",r.OperacaoId));
        command.Parameters.Add(new SqlParameter("@VersaoEsperada",SqlDbType.VarBinary,8) { Value=versao });
        try {
            var movimentoId=Convert.ToInt64(await command.ExecuteScalarAsync(ct));
            return Ok(new { movimentoId,mensagem="Estoque atualizado e movimentação registrada." });
        }
        catch(SqlException ex) when(ex.Number==51009) { return Conflict(ex.Message); }
        catch(SqlException ex) when(ex.Number==51004) { return NotFound(ex.Message); }
        catch(SqlException ex) when(ex.Number==51003) { return Forbid(); }
        catch(SqlException ex) when(ex.Number==51000) { return BadRequest(ex.Message); }
        finally { await db.Database.CloseConnectionAsync(); }
    }
}
