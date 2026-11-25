namespace Uniduni.API.Models
{
    public class Produto
    {
        public int Id { get; set; }

        public string Nome { get; set; } = string.Empty;

        public string Descricao { get; set; } = string.Empty;

        public decimal Preco { get; set; }

        public int Estoque { get; set; }

        public string Tamanho { get; set; } = string.Empty; // RN, P, M, G

        public string Genero { get; set; } = string.Empty; // Masculino, Feminino, Unissex

        public string Imagem { get; set; } = string.Empty;

        public int CategoriaId { get; set; }
        public Categoria Categoria { get; set; } = null!;
        public bool Ativo { get; set; } = true;
        public string GuiaMedidas { get; set; } = string.Empty;
        public List<ProdutoVariacao> Variacoes { get; set; } = [];
    }
}
