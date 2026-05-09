namespace Uniduni.API.Models
{
    public class Produto
    {
        public int Id { get; set; }

        public string Nome { get; set; }

        public string Descricao { get; set; }

        public decimal Preco { get; set; }

        public int Estoque { get; set; }

        public string Tamanho { get; set; } // RN, P, M, G

        public string Genero { get; set; } // Masculino, Feminino, Unissex

        public string Imagem { get; set; }

        public int CategoriaId { get; set; }
    }
}
