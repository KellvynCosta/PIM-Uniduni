using Microsoft.AspNetCore.Mvc;
using Uniduni.API.Data;
using Uniduni.API.Models;

namespace Uniduni.API.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class ProdutosController : ControllerBase
    {
        private readonly AppDbContext _context;

        public ProdutosController(AppDbContext context)
        {
            _context = context;
        }

        [HttpGet]
        public IActionResult Get()
        {
            var produtos = _context.Produtos.ToList();

            return Ok(produtos);
        }

        [HttpGet("{id}")]
        public IActionResult GetById(int id)
        {
            var produto = _context.Produtos.FirstOrDefault(p => p.Id == id);

            if (produto == null)
            {
                return NotFound("Produto não encontrado.");
            }

            return Ok(produto);
        }

        [HttpPost]
        public IActionResult Post([FromBody] Produto produto)
        {
            if (produto == null)
            {
                return BadRequest("Dados inválidos.");
            }

            if (string.IsNullOrWhiteSpace(produto.Nome) ||
                string.IsNullOrWhiteSpace(produto.Descricao) ||
                produto.Preco <= 0 ||
                produto.Estoque < 0)
            {
                return BadRequest("Nome, descrição, preço e estoque são obrigatórios.");
            }

            _context.Produtos.Add(produto);
            _context.SaveChanges();

            return Ok(produto);
        }

        [HttpPut("{id}")]
        public IActionResult Put(int id, [FromBody] Produto produtoAtualizado)
        {
            if (produtoAtualizado == null)
            {
                return BadRequest("Dados inválidos.");
            }

            var produto = _context.Produtos.FirstOrDefault(p => p.Id == id);

            if (produto == null)
            {
                return NotFound("Produto não encontrado.");
            }

            if (string.IsNullOrWhiteSpace(produtoAtualizado.Nome) ||
                string.IsNullOrWhiteSpace(produtoAtualizado.Descricao) ||
                produtoAtualizado.Preco <= 0 ||
                produtoAtualizado.Estoque < 0)
            {
                return BadRequest("Nome, descrição, preço e estoque são obrigatórios.");
            }

            produto.Nome = produtoAtualizado.Nome;
            produto.Descricao = produtoAtualizado.Descricao;
            produto.Preco = produtoAtualizado.Preco;
            produto.Estoque = produtoAtualizado.Estoque;
            produto.Tamanho = produtoAtualizado.Tamanho;
            produto.Genero = produtoAtualizado.Genero;
            produto.Imagem = produtoAtualizado.Imagem;
            produto.CategoriaId = produtoAtualizado.CategoriaId;

            _context.Produtos.Update(produto);
            _context.SaveChanges();

            return Ok(produto);
        }

        [HttpDelete("{id}")]
        public IActionResult Delete(int id)
        {
            var produto = _context.Produtos.FirstOrDefault(p => p.Id == id);

            if (produto == null)
            {
                return NotFound("Produto não encontrado.");
            }

            _context.Produtos.Remove(produto);
            _context.SaveChanges();

            return Ok("Produto excluído com sucesso.");
        }
    }
}