namespace Uniduni.API.Models
{
    public class RedefinirSenhaRequest
    {
        public string Email { get; set; } = string.Empty;
        public string NovaSenha { get; set; } = string.Empty;
    }
}