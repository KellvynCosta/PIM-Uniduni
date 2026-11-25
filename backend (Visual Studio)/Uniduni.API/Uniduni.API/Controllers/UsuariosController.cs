using System.Security.Claims;
using System.Security.Cryptography;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Identity;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.RateLimiting;
using Microsoft.AspNetCore.WebUtilities;
using Microsoft.Data.SqlClient;
using Microsoft.EntityFrameworkCore;
using Uniduni.API.Contracts;
using Uniduni.API.Data;
using Uniduni.API.Models;
using Uniduni.API.Security;

namespace Uniduni.API.Controllers;

[ApiController]
[Route("api/[controller]")]
public class UsuariosController(AppDbContext db, SenhasService senhas) : ControllerBase
{
    private int UsuarioId => int.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!);
    private static object Resposta(Usuario u) => new { u.Id, u.Nome, u.Email, u.Telefone, u.TipoUsuario };
    private static string NormalizarEmail(string email) => email.Trim().ToLowerInvariant();

    [HttpGet, Authorize(Roles = Perfis.Administrador)]
    public async Task<IActionResult> Get() => Ok(await db.Usuarios.AsNoTracking().Where(u => u.Ativo)
        .Select(u => new { u.Id, u.Nome, u.Email, u.Telefone, u.TipoUsuario }).ToListAsync());

    [HttpGet("me"), Authorize]
    public async Task<IActionResult> Me() => Ok(Resposta(await db.Usuarios.SingleAsync(u => u.Id == UsuarioId)));

    [HttpGet("{id:int}"), Authorize(Roles = Perfis.Administrador)]
    public async Task<IActionResult> GetById(int id)
    {
        var u = await db.Usuarios.SingleOrDefaultAsync(u => u.Id == id && u.Ativo);
        return u is null ? NotFound("Usuário não encontrado.") : Ok(Resposta(u));
    }

    [HttpPost("cadastro"), EnableRateLimiting("autenticacao")]
    public Task<IActionResult> Cadastro(CadastroRequest request) => Criar(request, Perfis.Cliente);

    [HttpPost, Authorize(Roles = Perfis.Administrador)]
    public Task<IActionResult> CriarInterno(CriarUsuarioRequest request) => Criar(request, request.TipoUsuario);

    private async Task<IActionResult> Criar(CadastroRequest request, string perfil)
    {
        var email = NormalizarEmail(request.Email);
        if (await db.Usuarios.AnyAsync(u => u.Email == email)) return Conflict("Email já cadastrado.");
        var u = new Usuario { Nome = request.Nome.Trim(), Email = email,
            Telefone = request.Telefone.Trim(), TipoUsuario = perfil };
        if (u.Nome.Length < 2) return BadRequest("Informe um nome com pelo menos dois caracteres.");
        u.Senha = senhas.Gerar(u, request.Senha);
        db.Usuarios.Add(u);
        try { await db.SaveChangesAsync(); }
        catch (DbUpdateException ex) when (ex.InnerException is SqlException { Number: 2601 or 2627 })
        { return Conflict("Email já cadastrado."); }
        return StatusCode(StatusCodes.Status201Created, Resposta(u));
    }

    [HttpPost("login"), EnableRateLimiting("autenticacao")]
    public async Task<IActionResult> Login(LoginRequest request)
    {
        var email = NormalizarEmail(request.Email);
        var u = await db.Usuarios.SingleOrDefaultAsync(u => u.Email == email && u.Ativo);
        var resultado = u is null ? PasswordVerificationResult.Failed : senhas.Verificar(u, request.Senha);
        if (u is null || resultado == PasswordVerificationResult.Failed)
            return Unauthorized("Email ou senha inválidos.");
        if (resultado == PasswordVerificationResult.SuccessRehashNeeded) u.Senha = senhas.Gerar(u, request.Senha);
        var token = WebEncoders.Base64UrlEncode(RandomNumberGenerator.GetBytes(32));
        var agora = DateTime.UtcNow;
        var sessao = new Sessao { UsuarioId = u.Id, TokenHash = SessaoAuthenticationHandler.HashToken(token),
            CriadaEm = agora, ExpiraEm = agora.AddHours(8) };
        db.Sessoes.Add(sessao);
        await db.Sessoes.Where(s => s.ExpiraEm <= agora).ExecuteDeleteAsync();
        await db.SaveChangesAsync();
        Response.Headers.CacheControl = "no-store";
        return Ok(new { token, sessao.ExpiraEm, usuario = Resposta(u) });
    }

    [HttpPost("logout"), Authorize]
    public async Task<IActionResult> Logout()
    {
        var id = int.Parse(User.FindFirstValue("sessaoId")!);
        await db.Sessoes.Where(s => s.Id == id).ExecuteDeleteAsync();
        return NoContent();
    }

    [HttpPut("{id:int}"), Authorize(Roles = Perfis.Administrador)]
    public async Task<IActionResult> Put(int id, AtualizarUsuarioRequest request)
    {
        var u = await db.Usuarios.SingleOrDefaultAsync(u => u.Id == id && u.Ativo);
        if (u is null) return NotFound("Usuário não encontrado.");
        var email = NormalizarEmail(request.Email);
        if (await db.Usuarios.AnyAsync(u => u.Email == email && u.Id != id)) return Conflict("Email já cadastrado.");
        if (id == UsuarioId && request.TipoUsuario is not null && request.TipoUsuario != Perfis.Administrador)
            return BadRequest("Você não pode remover o próprio acesso de administrador.");
        if (request.Nome.Trim().Length < 2) return BadRequest("Informe um nome válido.");
        u.Nome = request.Nome.Trim(); u.Email = email; u.Telefone = request.Telefone.Trim();
        if (request.TipoUsuario is not null) u.TipoUsuario = request.TipoUsuario;
        if (!string.IsNullOrEmpty(request.Senha))
        {
            u.Senha = senhas.Gerar(u, request.Senha);
            await db.Sessoes.Where(s => s.UsuarioId == id).ExecuteDeleteAsync();
        }
        try { await db.SaveChangesAsync(); }
        catch (DbUpdateException ex) when (ex.InnerException is SqlException { Number: 2601 or 2627 })
        { return Conflict("Email já cadastrado."); }
        return Ok(Resposta(u));
    }

    [HttpPut("alterar-senha/{id:int}"), Authorize]
    public async Task<IActionResult> AlterarSenha(int id, AlterarSenhaRequest request)
    {
        if (id != UsuarioId) return Forbid();
        var u = await db.Usuarios.SingleAsync(u => u.Id == id);
        if (senhas.Verificar(u, request.SenhaAtual) == PasswordVerificationResult.Failed)
            return BadRequest("Senha atual incorreta.");
        u.Senha = senhas.Gerar(u, request.NovaSenha);
        await db.Sessoes.Where(s => s.UsuarioId == id).ExecuteDeleteAsync();
        await db.SaveChangesAsync();
        return Ok("Senha alterada. Entre novamente.");
    }

    [HttpPost("redefinir-senha")]
    public IActionResult RedefinirSenha() => StatusCode(StatusCodes.Status410Gone,
        "Para recuperar o acesso, solicite a redefinição ao administrador da loja. Não é possível trocar a senha apenas informando o email.");

    [HttpDelete("{id:int}"), Authorize(Roles = Perfis.Administrador)]
    public async Task<IActionResult> Delete(int id)
    {
        if (id == UsuarioId) return BadRequest("Você não pode desativar a própria conta.");
        var u = await db.Usuarios.SingleOrDefaultAsync(u => u.Id == id && u.Ativo);
        if (u is null) return NotFound("Usuário não encontrado.");
        u.Ativo = false;
        await db.Sessoes.Where(s => s.UsuarioId == id).ExecuteDeleteAsync();
        await db.SaveChangesAsync();
        return Ok("Usuário desativado. Seu histórico foi preservado.");
    }
}
