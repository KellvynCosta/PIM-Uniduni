namespace Uniduni.API.Models;

public class Categoria
{
    public int Id { get; set; }
    public string Nome { get; set; } = string.Empty;
    public string Descricao { get; set; } = string.Empty;
}

public class ProdutoVariacao
{
    public int Id { get; set; }
    public int ProdutoId { get; set; }
    public Produto Produto { get; set; } = null!;
    public string Cor { get; set; } = string.Empty;
    public string Tamanho { get; set; } = string.Empty;
    public int Estoque { get; set; }
    public int Reservado { get; set; }
    public int EstoqueMinimo { get; set; } = 3;
    public bool Ativo { get; set; } = true;
    public byte[] Versao { get; set; } = [];
}

public class MovimentacaoEstoque
{
    public long Id { get; set; }
    public int VariacaoId { get; set; }
    public ProdutoVariacao Variacao { get; set; } = null!;
    public int? UsuarioId { get; set; }
    public string Responsavel { get; set; } = string.Empty;
    public string Tipo { get; set; } = string.Empty;
    public int Quantidade { get; set; }
    public int SaldoAnterior { get; set; }
    public int SaldoAtual { get; set; }
    public int ReservadoAnterior { get; set; }
    public int ReservadoAtual { get; set; }
    public string Justificativa { get; set; } = string.Empty;
    public Guid OperacaoId { get; set; }
    public DateTime CriadaEm { get; set; }
}
