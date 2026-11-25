namespace Uniduni.API.Models;

public class Sessao
{
    public int Id { get; set; }
    public int UsuarioId { get; set; }
    public string TokenHash { get; set; } = string.Empty;
    public DateTime CriadaEm { get; set; }
    public DateTime ExpiraEm { get; set; }
    public Usuario Usuario { get; set; } = null!;
}
