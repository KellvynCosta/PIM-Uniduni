using Microsoft.AspNetCore.Identity;
using Microsoft.EntityFrameworkCore;
using Uniduni.API.Data;
using Uniduni.API.Models;

namespace Uniduni.API.Security;

public class SenhasService(IPasswordHasher<Usuario> hasher)
{
    private const string Prefixo = "PBKDF2:";

    public string Gerar(Usuario usuario, string senha) => Prefixo + hasher.HashPassword(usuario, senha);

    public PasswordVerificationResult Verificar(Usuario usuario, string senha)
    {
        if (!usuario.Senha.StartsWith(Prefixo, StringComparison.Ordinal))
            return PasswordVerificationResult.Failed;
        try { return hasher.VerifyHashedPassword(usuario, usuario.Senha[Prefixo.Length..], senha); }
        catch (FormatException) { return PasswordVerificationResult.Failed; }
    }

    public async Task<int> MigrarLegadasAsync(AppDbContext db)
    {
        var usuarios = await db.Usuarios.Where(u => !u.Senha.StartsWith(Prefixo)).ToListAsync();
        if (usuarios.Any(u => string.IsNullOrEmpty(u.Senha)))
            throw new InvalidOperationException("Existem usuários sem senha; revise os dados antes de migrar.");
        foreach (var usuario in usuarios)
            usuario.Senha = Gerar(usuario, usuario.Senha);
        await db.SaveChangesAsync();
        return usuarios.Count;
    }
}
