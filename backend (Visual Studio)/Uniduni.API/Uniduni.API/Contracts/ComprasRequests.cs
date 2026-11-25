using System.ComponentModel.DataAnnotations;
namespace Uniduni.API.Contracts;
public record CarrinhoRequest([Range(1,int.MaxValue)] int VariacaoId,[Range(0,99)] int Quantidade);
public record CriarPedidoRequest(Guid OperacaoId);
public record PagamentoRequest(Guid OperacaoId,[Required,RegularExpression("^(Pix|Cartao)$")] string Metodo,
    [Required,RegularExpression("^(Aprovado|Recusado|Pendente)$")] string Resultado);
public record ResolverPagamentoRequest([Required,RegularExpression("^(Aprovado|Recusado)$")] string Resultado);
public record CancelarPedidoRequest([Required,StringLength(200,MinimumLength=5)] string Motivo);
public record AndamentoPedidoRequest([Required,RegularExpression("^(EmPreparacao|Pronto|Retirado)$")] string Status,
    [StringLength(12)] string? Codigo);
