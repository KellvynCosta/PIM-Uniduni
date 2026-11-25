using System.Security.Claims;
using System.Security.Cryptography;
using System.Text;
using System.Text.Encodings.Web;
using Microsoft.AspNetCore.Authentication;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Options;
using Uniduni.API.Data;

namespace Uniduni.API.Security;

public class SessaoAuthenticationHandler(
    IOptionsMonitor<AuthenticationSchemeOptions> options,
    ILoggerFactory logger, UrlEncoder encoder, AppDbContext db)
    : AuthenticationHandler<AuthenticationSchemeOptions>(options, logger, encoder)
{
    public const string Esquema = "Sessao";
    public static string HashToken(string token) => Convert.ToHexString(SHA256.HashData(Encoding.UTF8.GetBytes(token)));

    protected override async Task<AuthenticateResult> HandleAuthenticateAsync()
    {
        var header = Request.Headers.Authorization.ToString();
        if (!header.StartsWith("Bearer ", StringComparison.OrdinalIgnoreCase))
            return AuthenticateResult.NoResult();
        var token = header[7..].Trim();
        if (token.Length != 43) return AuthenticateResult.Fail("Sessão inválida.");
        var hash = HashToken(token);
        var sessao = await db.Sessoes.AsNoTracking().Include(s => s.Usuario)
            .SingleOrDefaultAsync(s => s.TokenHash == hash && s.ExpiraEm > DateTime.UtcNow && s.Usuario.Ativo,
                Context.RequestAborted);
        if (sessao is null) return AuthenticateResult.Fail("Sessão inválida ou expirada.");
        var claims = new[] {
            new Claim(ClaimTypes.NameIdentifier, sessao.UsuarioId.ToString()),
            new Claim(ClaimTypes.Name, sessao.Usuario.Nome),
            new Claim(ClaimTypes.Role, sessao.Usuario.TipoUsuario),
            new Claim("sessaoId", sessao.Id.ToString())
        };
        return AuthenticateResult.Success(new AuthenticationTicket(
            new ClaimsPrincipal(new ClaimsIdentity(claims, Esquema)), Esquema));
    }
}
