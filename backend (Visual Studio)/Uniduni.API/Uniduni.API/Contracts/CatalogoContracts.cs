using System.ComponentModel.DataAnnotations;
using Uniduni.API.Models;

namespace Uniduni.API.Contracts;

public class ProdutoRequest
{
    [Required, StringLength(100, MinimumLength = 2)] public string Nome { get; set; } = string.Empty;
    [Required, StringLength(500, MinimumLength = 5)] public string Descricao { get; set; } = string.Empty;
    [Range(typeof(decimal), "0.01", "99999999.99")] public decimal Preco { get; set; }
    [Required, RegularExpression("^(Unissex|Masculino|Feminino)$")] public string Genero { get; set; } = "Unissex";
    [StringLength(255), RegularExpression(@"^$|^[\p{L}\p{N}_ .-]+\.(jpg|jpeg|png|webp)$", ErrorMessage = "Informe apenas o nome de um arquivo JPG, PNG ou WebP da pasta de imagens.")]
    public string Imagem { get; set; } = string.Empty;
    [Range(1,int.MaxValue)] public int CategoriaId { get; set; }
    [StringLength(500)] public string GuiaMedidas { get; set; } = string.Empty;
    public bool Ativo { get; set; } = true;
}
public class CriarProdutoRequest : ProdutoRequest
{
    [Required] public CriarVariacaoRequest VariacaoInicial { get; set; } = null!;
}
public class VariacaoRequest
{
    [Required, StringLength(40)] public string Cor { get; set; } = string.Empty;
    [Required, StringLength(20)] public string Tamanho { get; set; } = string.Empty;
    [Range(0,1000000)] public int EstoqueMinimo { get; set; } = 3;
}
public class CriarVariacaoRequest : VariacaoRequest
{
    [Range(0,1000000)] public int EstoqueInicial { get; set; }
}
public class AtualizarVariacaoRequest : VariacaoRequest
{
    [Required] public string Versao { get; set; } = string.Empty;
    public bool Ativo { get; set; } = true;
}
public class MovimentarEstoqueRequest
{
    [Required, RegularExpression("^(Entrada|Ajuste)$")] public string Tipo { get; set; } = string.Empty;
    [Range(0,1000000)] public int Quantidade { get; set; }
    [Required, StringLength(250,MinimumLength = 5)] public string Justificativa { get; set; } = string.Empty;
    public Guid OperacaoId { get; set; }
    [Required] public string Versao { get; set; } = string.Empty;
}

public record VariacaoResponse(int Id, string Cor, string Tamanho, int Estoque, int Reservado, int Disponivel,
    int EstoqueMinimo, bool EstoqueBaixo, bool Ativo, string Versao);
public record ProdutoResponse(int Id, string Nome, string Descricao, decimal Preco, string Genero, string Imagem,
    int CategoriaId, string CategoriaNome, string GuiaMedidas, bool Ativo, int Estoque, string Tamanho,
    IReadOnlyList<VariacaoResponse> Variacoes)
{
    public static ProdutoResponse De(Produto p, bool equipe = false)
    {
        var variacoes = p.Variacoes.Where(v => equipe || v.Ativo).OrderBy(v => v.Cor).ThenBy(v => v.Tamanho)
            .Select(v => new VariacaoResponse(v.Id,v.Cor,v.Tamanho,v.Estoque,v.Reservado,v.Estoque-v.Reservado,
                v.EstoqueMinimo,v.Estoque-v.Reservado <= v.EstoqueMinimo,v.Ativo,Convert.ToBase64String(v.Versao))).ToList();
        return new(p.Id,p.Nome,p.Descricao,p.Preco,p.Genero,p.Imagem,p.CategoriaId,p.Categoria.Nome,p.GuiaMedidas,p.Ativo,
            variacoes.Where(v => v.Ativo).Sum(v => v.Disponivel),string.Join(", ",variacoes.Where(v => v.Ativo).Select(v => v.Tamanho).Distinct()),variacoes);
    }
}
