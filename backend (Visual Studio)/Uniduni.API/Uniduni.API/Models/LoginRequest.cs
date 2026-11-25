using System.ComponentModel.DataAnnotations;
namespace Uniduni.API.Models;
public class LoginRequest
{
    [Required, EmailAddress, StringLength(100)]
    public string Email { get; set; } = string.Empty;
    [Required, StringLength(128)]
    public string Senha { get; set; } = string.Empty;
}
