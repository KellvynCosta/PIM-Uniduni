using Microsoft.AspNetCore.Mvc;
using Uniduni.API.Data;
using Uniduni.API.Models;

namespace Uniduni.API.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class UsuariosController : ControllerBase
    {
        private readonly AppDbContext _context;

        public UsuariosController(AppDbContext context)
        {
            _context = context;
        }

        [HttpGet]
        public IActionResult Get()
        {
            var usuarios = _context.Usuarios
                .Select(u => new
                {
                    u.Id,
                    u.Nome,
                    u.Email,
                    u.Telefone,
                    u.TipoUsuario
                })
                .ToList();

            return Ok(usuarios);
        }

        [HttpGet("{id}")]
        public IActionResult GetById(int id)
        {
            var usuario = _context.Usuarios
                .Where(u => u.Id == id)
                .Select(u => new
                {
                    u.Id,
                    u.Nome,
                    u.Email,
                    u.Telefone,
                    u.TipoUsuario
                })
                .FirstOrDefault();

            if (usuario == null)
            {
                return NotFound("Usuário não encontrado.");
            }

            return Ok(usuario);
        }

        [HttpPost("cadastro")]
        public IActionResult Cadastro([FromBody] Usuario usuario)
        {
            if (usuario == null)
            {
                return BadRequest("Dados inválidos.");
            }

            if (string.IsNullOrWhiteSpace(usuario.Nome) ||
                string.IsNullOrWhiteSpace(usuario.Email) ||
                string.IsNullOrWhiteSpace(usuario.Senha))
            {
                return BadRequest("Nome, email e senha são obrigatórios.");
            }

            var emailJaExiste = _context.Usuarios.Any(u => u.Email == usuario.Email);

            if (emailJaExiste)
            {
                return BadRequest("Email já cadastrado.");
            }

            if (string.IsNullOrWhiteSpace(usuario.TipoUsuario))
            {
                usuario.TipoUsuario = "Cliente";
            }

            _context.Usuarios.Add(usuario);
            _context.SaveChanges();

            return Ok(new
            {
                usuario.Id,
                usuario.Nome,
                usuario.Email,
                usuario.Telefone,
                usuario.TipoUsuario
            });
        }

        [HttpPost("login")]
        public IActionResult Login([FromBody] LoginRequest login)
        {
            if (login == null)
            {
                return BadRequest("Dados inválidos.");
            }

            if (string.IsNullOrWhiteSpace(login.Email) ||
                string.IsNullOrWhiteSpace(login.Senha))
            {
                return BadRequest("Email e senha são obrigatórios.");
            }

            var usuario = _context.Usuarios
                .FirstOrDefault(u => u.Email == login.Email && u.Senha == login.Senha);

            if (usuario == null)
            {
                return Unauthorized("Email ou senha inválidos.");
            }

            return Ok(new
            {
                usuario.Id,
                usuario.Nome,
                usuario.Email,
                usuario.Telefone,
                usuario.TipoUsuario
            });
        }

        [HttpPut("{id}")]
        public IActionResult Put(int id, [FromBody] Usuario usuarioAtualizado)
        {
            if (usuarioAtualizado == null)
            {
                return BadRequest("Dados inválidos.");
            }

            var usuario = _context.Usuarios.FirstOrDefault(u => u.Id == id);

            if (usuario == null)
            {
                return NotFound("Usuário não encontrado.");
            }

            if (string.IsNullOrWhiteSpace(usuarioAtualizado.Nome) ||
                string.IsNullOrWhiteSpace(usuarioAtualizado.Email))
            {
                return BadRequest("Nome e email são obrigatórios.");
            }

            var emailJaExiste = _context.Usuarios
                .Any(u => u.Email == usuarioAtualizado.Email && u.Id != id);

            if (emailJaExiste)
            {
                return BadRequest("Este email já está sendo usado por outro usuário.");
            }

            usuario.Nome = usuarioAtualizado.Nome;
            usuario.Email = usuarioAtualizado.Email;
            usuario.Telefone = usuarioAtualizado.Telefone;
            usuario.TipoUsuario = string.IsNullOrWhiteSpace(usuarioAtualizado.TipoUsuario)
                ? usuario.TipoUsuario
                : usuarioAtualizado.TipoUsuario;

            if (!string.IsNullOrWhiteSpace(usuarioAtualizado.Senha))
            {
                usuario.Senha = usuarioAtualizado.Senha;
            }

            _context.Usuarios.Update(usuario);
            _context.SaveChanges();

            return Ok(new
            {
                usuario.Id,
                usuario.Nome,
                usuario.Email,
                usuario.Telefone,
                usuario.TipoUsuario
            });
        }

        [HttpPut("alterar-senha/{id}")]
        public IActionResult AlterarSenha(int id, [FromBody] LoginRequest dados)
        {
            if (dados == null || string.IsNullOrWhiteSpace(dados.Senha))
            {
                return BadRequest("Nova senha inválida.");
            }

            var usuario = _context.Usuarios.FirstOrDefault(u => u.Id == id);

            if (usuario == null)
            {
                return NotFound("Usuário não encontrado.");
            }

            usuario.Senha = dados.Senha;

            _context.Usuarios.Update(usuario);
            _context.SaveChanges();

            return Ok("Senha atualizada com sucesso.");
        }

        [HttpPost("redefinir-senha")]
        public IActionResult RedefinirSenha([FromBody] RedefinirSenhaRequest request)
        {
            if (request == null)
            {
                return BadRequest("Dados inválidos.");
            }

            if (string.IsNullOrWhiteSpace(request.Email) ||
                string.IsNullOrWhiteSpace(request.NovaSenha))
            {
                return BadRequest("Email e nova senha são obrigatórios.");
            }

            var usuario = _context.Usuarios.FirstOrDefault(u => u.Email == request.Email);

            if (usuario == null)
            {
                return NotFound("Usuário não encontrado.");
            }

            usuario.Senha = request.NovaSenha;

            _context.Usuarios.Update(usuario);
            _context.SaveChanges();

            return Ok("Senha redefinida com sucesso.");
        }

        [HttpDelete("{id}")]
        public IActionResult Delete(int id)
        {
            var usuario = _context.Usuarios.FirstOrDefault(u => u.Id == id);

            if (usuario == null)
            {
                return NotFound("Usuário não encontrado.");
            }

            _context.Usuarios.Remove(usuario);
            _context.SaveChanges();

            return Ok("Usuário excluído com sucesso.");
        }
    }
}