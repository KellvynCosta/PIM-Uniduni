using System.ComponentModel.DataAnnotations;

namespace Uniduni.API.Contracts;

public class CadastroRequest
{
    [Required, StringLength(100, MinimumLength = 2)]
    public string Nome { get; set; } = string.Empty;
    [Required, EmailAddress, StringLength(100)]
    public string Email { get; set; } = string.Empty;
    [Required, StringLength(128, MinimumLength = 8)]
    public string Senha { get; set; } = string.Empty;
    [StringLength(20)]
    public string Telefone { get; set; } = string.Empty;
}

public class CriarUsuarioRequest : CadastroRequest
{
    [Required, RegularExpression("^(Cliente|Funcionario|Administrador)$")]
    public string TipoUsuario { get; set; } = "Cliente";
}

public class AtualizarUsuarioRequest
{
    [Required, StringLength(100, MinimumLength = 2)]
    public string Nome { get; set; } = string.Empty;
    [Required, EmailAddress, StringLength(100)]
    public string Email { get; set; } = string.Empty;
    [StringLength(20)]
    public string Telefone { get; set; } = string.Empty;
    [RegularExpression("^(Cliente|Funcionario|Administrador)$")]
    public string? TipoUsuario { get; set; }
    [StringLength(128, MinimumLength = 8)]
    public string? Senha { get; set; }
}

public class AlterarSenhaRequest
{
    [Required, StringLength(128)]
    public string SenhaAtual { get; set; } = string.Empty;
    [Required, StringLength(128, MinimumLength = 8)]
    public string NovaSenha { get; set; } = string.Empty;
}
