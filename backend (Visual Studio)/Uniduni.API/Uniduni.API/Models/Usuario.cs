namespace Uniduni.API.Models
{
    public class Usuario
    {
        public int Id { get; set; }

        public string Nome { get; set; } = string.Empty;

        public string Email { get; set; } = string.Empty;

        public string Senha { get; set; } = string.Empty;

        public string Telefone { get; set; } = string.Empty;

        public string TipoUsuario { get; set; } = "Cliente";
        public bool Ativo { get; set; } = true;
    }
}
