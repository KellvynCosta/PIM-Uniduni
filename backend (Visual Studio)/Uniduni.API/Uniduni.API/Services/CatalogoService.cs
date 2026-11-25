using System.Security.Claims;
using Microsoft.EntityFrameworkCore;
using Uniduni.API.Contracts;
using Uniduni.API.Data;
using Uniduni.API.Models;

namespace Uniduni.API.Services;

public class CatalogoService(AppDbContext db)
{
    public IQueryable<Produto> Consulta => db.Produtos.AsNoTracking().Include(p => p.Categoria).Include(p => p.Variacoes);

    public async Task<string?> ValidarProdutoAsync(ProdutoRequest r, int? produtoId = null)
    {
        if (r.Nome.Trim().Length < 2 || r.Descricao.Trim().Length < 5) return "Preencha nome e descrição válidos.";
        var categoria = await db.Categorias.FindAsync(r.CategoriaId);
        if (categoria is null) return "Categoria não encontrada.";
        if (produtoId is not null)
        {
            var tamanhos = await db.ProdutoVariacoes.Where(v => v.ProdutoId == produtoId).Select(v => v.Tamanho).ToListAsync();
            if (tamanhos.Any(t => ValidarTamanho(categoria.Nome,t) is not null))
                return "A categoria escolhida não aceita os tamanhos já cadastrados neste produto.";
            if (!r.Ativo && await db.ProdutoVariacoes.AnyAsync(v => v.ProdutoId == produtoId && v.Reservado > 0))
                return "O produto possui unidades reservadas e não pode ser desativado.";
        }
        return null;
    }
    public async Task<string?> ValidarVariacaoAsync(int categoriaId, VariacaoRequest r)
    {
        if (string.IsNullOrWhiteSpace(r.Cor) || string.IsNullOrWhiteSpace(r.Tamanho)) return "Preencha cor e tamanho.";
        var c = await db.Categorias.FindAsync(categoriaId);
        return c is null ? "Categoria não encontrada." : ValidarTamanho(c.Nome,r.Tamanho.Trim());
    }
    private static string? ValidarTamanho(string categoria, string tamanho) => categoria switch
    {
        "Roupas" when !new[] { "RN","P","M","G" }.Contains(tamanho.ToUpperInvariant()) => "Para roupas, escolha RN, P, M ou G.",
        "Calçados" when !int.TryParse(tamanho,out var n) || n < 1 || n > 99 => "Para calçados, informe a numeração como um inteiro de 1 a 99.",
        _ => null
    };
    public static void Aplicar(Produto p, ProdutoRequest r)
    {
        p.Nome=r.Nome.Trim(); p.Descricao=r.Descricao.Trim(); p.Preco=r.Preco; p.Genero=r.Genero;
        p.Imagem=r.Imagem.Trim(); p.CategoriaId=r.CategoriaId; p.GuiaMedidas=r.GuiaMedidas.Trim(); p.Ativo=r.Ativo;
    }
    public async Task<ProdutoVariacao> AdicionarVariacaoAsync(Produto p, CriarVariacaoRequest r, ClaimsPrincipal user)
    {
        var v=new ProdutoVariacao { ProdutoId=p.Id, Cor=r.Cor.Trim(), Tamanho=r.Tamanho.Trim().ToUpperInvariant(),
            Estoque=r.EstoqueInicial,EstoqueMinimo=r.EstoqueMinimo };
        db.ProdutoVariacoes.Add(v);
        await db.SaveChangesAsync();
        db.MovimentacoesEstoque.Add(new MovimentacaoEstoque {
            VariacaoId=v.Id,UsuarioId=int.Parse(user.FindFirstValue(ClaimTypes.NameIdentifier)!),
            Responsavel=user.Identity!.Name!,Tipo="Inicial",Quantidade=r.EstoqueInicial,SaldoAnterior=0,SaldoAtual=r.EstoqueInicial,
            Justificativa="Cadastro da variação com saldo inicial.",OperacaoId=Guid.NewGuid(),CriadaEm=DateTime.UtcNow
        });
        await db.SaveChangesAsync();
        return v;
    }
    public static bool LerVersao(string entrada, out byte[] versao)
    {
        try { versao=Convert.FromBase64String(entrada); return versao.Length == 8; }
        catch(FormatException) { versao=[]; return false; }
    }
}
