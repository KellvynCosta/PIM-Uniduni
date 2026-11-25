using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Data.SqlClient;
using Microsoft.EntityFrameworkCore;
using Uniduni.API.Contracts;
using Uniduni.API.Data;
using Uniduni.API.Models;
using Uniduni.API.Security;
using Uniduni.API.Services;

namespace Uniduni.API.Controllers;

[ApiController, Route("api/[controller]")]
public class ProdutosController(AppDbContext db, CatalogoService catalogo, ComprasService compras) : ControllerBase
{
    [HttpGet]
    public async Task<IActionResult> Get()
        => Ok((await catalogo.Consulta.Where(p=>p.Ativo).OrderBy(p=>p.Nome).ToListAsync()).Select(p=>ProdutoResponse.De(p)));

    [HttpGet("administracao"), Authorize(Roles=Perfis.Equipe)]
    public async Task<IActionResult> Administracao()
        => Ok((await catalogo.Consulta.OrderByDescending(p=>p.Ativo).ThenBy(p=>p.Nome).ToListAsync()).Select(p=>ProdutoResponse.De(p,true)));

    [HttpGet("{id:int}")]
    public async Task<IActionResult> GetById(int id)
    {
        var p=await catalogo.Consulta.SingleOrDefaultAsync(p=>p.Id==id && p.Ativo);
        return p is null ? NotFound("Produto não encontrado.") : Ok(ProdutoResponse.De(p));
    }
    [HttpGet("administracao/{id:int}"), Authorize(Roles=Perfis.Equipe)]
    public async Task<IActionResult> AdministracaoById(int id)
    {
        var p=await catalogo.Consulta.SingleOrDefaultAsync(p=>p.Id==id);
        return p is null ? NotFound("Produto não encontrado.") : Ok(ProdutoResponse.De(p,true));
    }

    [HttpPost, Authorize(Roles=Perfis.Equipe)]
    public async Task<IActionResult> Post(CriarProdutoRequest r)
    {
        var erro=await catalogo.ValidarProdutoAsync(r) ?? await catalogo.ValidarVariacaoAsync(r.CategoriaId,r.VariacaoInicial);
        if(erro is not null) return BadRequest(erro);
        using var tx=await db.Database.BeginTransactionAsync();
        var p=new Produto { Tamanho=r.VariacaoInicial.Tamanho.Trim().ToUpperInvariant() };
        CatalogoService.Aplicar(p,r);
        db.Produtos.Add(p); await db.SaveChangesAsync();
        await catalogo.AdicionarVariacaoAsync(p,r.VariacaoInicial,User);
        await tx.CommitAsync();
        var criado=await catalogo.Consulta.SingleAsync(produto=>produto.Id==p.Id);
        return StatusCode(201,ProdutoResponse.De(criado,true));
    }

    [HttpPut("{id:int}"), Authorize(Roles=Perfis.Equipe)]
    public async Task<IActionResult> Put(int id,ProdutoRequest r)
    {
        using var tx=await db.Database.BeginTransactionAsync();
        await compras.BloquearCatalogoAsync();
        var p=await db.Produtos.FindAsync(id);
        if(p is null) return NotFound("Produto não encontrado.");
        var erro=await catalogo.ValidarProdutoAsync(r,id);
        if(erro is not null) return BadRequest(erro);
        CatalogoService.Aplicar(p,r); await db.SaveChangesAsync();
        await tx.CommitAsync();
        return Ok(ProdutoResponse.De(await catalogo.Consulta.SingleAsync(produto=>produto.Id==id),true));
    }
    [HttpDelete("{id:int}"), Authorize(Roles=Perfis.Equipe)]
    public async Task<IActionResult> Delete(int id)
    {
        using var tx=await db.Database.BeginTransactionAsync();
        await compras.BloquearCatalogoAsync();
        var p=await db.Produtos.FindAsync(id);
        if(p is null) return NotFound("Produto não encontrado.");
        if(await db.ProdutoVariacoes.AnyAsync(v=>v.ProdutoId==id && v.Reservado>0))
            return Conflict("O produto possui unidades reservadas e não pode ser desativado.");
        p.Ativo=false; await db.SaveChangesAsync();
        await tx.CommitAsync();
        return Ok("Produto desativado. O histórico e as quantidades foram preservados.");
    }

    [HttpPost("{id:int}/variacoes"), Authorize(Roles=Perfis.Equipe)]
    public async Task<IActionResult> AdicionarVariacao(int id,CriarVariacaoRequest r)
    {
        var p=await db.Produtos.FindAsync(id);
        if(p is null || !p.Ativo) return NotFound("Produto ativo não encontrado.");
        var erro=await catalogo.ValidarVariacaoAsync(p.CategoriaId,r);
        if(erro is not null) return BadRequest(erro);
        using var tx=await db.Database.BeginTransactionAsync();
        try {
            await catalogo.AdicionarVariacaoAsync(p,r,User);
            await tx.CommitAsync();
            return StatusCode(201,ProdutoResponse.De(await catalogo.Consulta.SingleAsync(produto=>produto.Id==id),true));
        }
        catch(DbUpdateException ex) when(ex.InnerException is SqlException { Number:2601 or 2627 })
        { return Conflict("Essa combinação de cor e tamanho já existe. Edite a variação existente, inclusive se estiver inativa."); }
    }

    [HttpPut("{id:int}/variacoes/{variacaoId:int}"), Authorize(Roles=Perfis.Equipe)]
    public async Task<IActionResult> AtualizarVariacao(int id,int variacaoId,AtualizarVariacaoRequest r)
    {
        var v=await db.ProdutoVariacoes.Include(v=>v.Produto).SingleOrDefaultAsync(v=>v.Id==variacaoId && v.ProdutoId==id);
        if(v is null) return NotFound("Variação não encontrada.");
        var erro=await catalogo.ValidarVariacaoAsync(v.Produto.CategoriaId,r);
        if(erro is not null) return BadRequest(erro);
        if(!CatalogoService.LerVersao(r.Versao,out var versao)) return BadRequest("Versão de estoque inválida.");
        if(!v.Versao.SequenceEqual(versao)) return Conflict("A variação mudou. Atualize os dados antes de salvar.");
        if(!r.Ativo && v.Reservado>0) return Conflict("Existem unidades reservadas para esta variação.");
        v.Cor=r.Cor.Trim(); v.Tamanho=r.Tamanho.Trim().ToUpperInvariant(); v.EstoqueMinimo=r.EstoqueMinimo; v.Ativo=r.Ativo;
        try { await db.SaveChangesAsync(); }
        catch(DbUpdateConcurrencyException) { return Conflict("A variação mudou. Atualize os dados antes de salvar."); }
        catch(DbUpdateException ex) when(ex.InnerException is SqlException { Number:2601 or 2627 })
        { return Conflict("Essa combinação de cor e tamanho já existe."); }
        return Ok(ProdutoResponse.De(await catalogo.Consulta.SingleAsync(produto=>produto.Id==id),true));
    }
}
