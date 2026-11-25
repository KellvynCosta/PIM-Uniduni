namespace Uniduni.API.Models;

public class CarrinhoItemLoja
{
    public int UsuarioId { get; set; }
    public int VariacaoId { get; set; }
    public int Quantidade { get; set; }
    public ProdutoVariacao Variacao { get; set; } = null!;
}
public class PedidoLoja
{
    public int Id { get; set; }
    public int UsuarioId { get; set; }
    public Usuario Usuario { get; set; } = null!;
    public Guid OperacaoId { get; set; }
    public string Status { get; set; } = "Pendente";
    public decimal Total { get; set; }
    public DateTime CriadoEm { get; set; }
    public DateTime? ReservaAte { get; set; }
    public DateTime? PagoEm { get; set; }
    public DateTime? CanceladoEm { get; set; }
    public string CodigoRetirada { get; set; } = "";
    public DateTime? RetiradoEm { get; set; }
    public int? RetiradoPor { get; set; }
    public List<ItemPedidoLoja> Itens { get; set; } = [];
    public List<PagamentoSimulado> Pagamentos { get; set; } = [];
    public List<EventoPedidoLoja> Eventos { get; set; } = [];
}
public class ItemPedidoLoja
{
    public int Id { get; set; }
    public int PedidoId { get; set; }
    public int VariacaoId { get; set; }
    public string Nome { get; set; } = "";
    public string Cor { get; set; } = "";
    public string Tamanho { get; set; } = "";
    public string Imagem { get; set; } = "";
    public int Quantidade { get; set; }
    public decimal PrecoUnitario { get; set; }
}
public class PagamentoSimulado
{
    public int Id { get; set; }
    public int PedidoId { get; set; }
    public Guid OperacaoId { get; set; }
    public string Metodo { get; set; } = "";
    public string ResultadoSolicitado { get; set; } = "";
    public string Status { get; set; } = "";
    public decimal Valor { get; set; }
    public DateTime CriadoEm { get; set; }
    public DateTime AtualizadoEm { get; set; }
}
public class EventoPedidoLoja
{
    public int Id { get; set; }
    public int PedidoId { get; set; }
    public int? UsuarioId { get; set; }
    public string Descricao { get; set; } = "";
    public DateTime CriadoEm { get; set; }
}
