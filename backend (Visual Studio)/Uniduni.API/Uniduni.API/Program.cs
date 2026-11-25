using System.Threading.RateLimiting;
using Microsoft.AspNetCore.Authentication;
using Microsoft.AspNetCore.Identity;
using Microsoft.AspNetCore.RateLimiting;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.FileProviders;
using Uniduni.API.Data;
using Uniduni.API.Models;
using Uniduni.API.Security;

var builder = WebApplication.CreateBuilder(args);
builder.Services.AddControllers();
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen();
builder.Services.AddDbContext<AppDbContext>(options => options.UseSqlServer(
    builder.Configuration.GetConnectionString("DefaultConnection")));
builder.Services.AddScoped<IPasswordHasher<Usuario>, PasswordHasher<Usuario>>();
builder.Services.AddScoped<SenhasService>();
builder.Services.AddScoped<Uniduni.API.Services.CatalogoService>();
builder.Services.AddScoped<Uniduni.API.Services.ComprasService>();
builder.Services.AddHostedService<Uniduni.API.Services.ExpiracaoReservasService>();
builder.Services.AddAuthentication(SessaoAuthenticationHandler.Esquema)
    .AddScheme<AuthenticationSchemeOptions, SessaoAuthenticationHandler>(SessaoAuthenticationHandler.Esquema, null);
builder.Services.AddAuthorization();
builder.Services.AddCors(options => options.AddDefaultPolicy(policy => policy
    .WithOrigins("http://localhost:5500", "http://127.0.0.1:5500")
    .AllowAnyMethod().AllowAnyHeader()));
builder.Services.AddRateLimiter(options => {
    options.RejectionStatusCode = StatusCodes.Status429TooManyRequests;
    options.AddPolicy("autenticacao", context => RateLimitPartition.GetFixedWindowLimiter(
        context.Connection.RemoteIpAddress?.ToString() ?? "local",
        _ => new FixedWindowRateLimiterOptions { PermitLimit = 15, Window = TimeSpan.FromMinutes(1), QueueLimit = 0 }));
});
var app = builder.Build();
if (args.Contains("--migrar-senhas"))
{
    using var scope = app.Services.CreateScope();
    var count = await scope.ServiceProvider.GetRequiredService<SenhasService>()
        .MigrarLegadasAsync(scope.ServiceProvider.GetRequiredService<AppDbContext>());
    Console.WriteLine("Migração de senhas concluída. Contas atualizadas: " + count);
    return;
}
app.UseExceptionHandler(handler => handler.Run(async context => {
    context.Response.StatusCode = 500;
    await context.Response.WriteAsJsonAsync(new { mensagem = "Não foi possível concluir a operação. Verifique a conexão e a configuração do banco." });
}));
app.Use(async (context, next) => {
    context.Response.Headers.XContentTypeOptions = "nosniff";
    context.Response.Headers["Referrer-Policy"] = "same-origin";
    if (context.Request.Path.StartsWithSegments("/api/Usuarios") || context.Request.Path.StartsWithSegments("/api/compras")) context.Response.Headers.CacheControl = "no-store";
    await next();
});
// Desenvolvimento local: o mesmo endereço da API serve o frontend existente.
var frontend = Path.GetFullPath(Path.Combine(builder.Environment.ContentRootPath, "..", "..", "..", "frontend (VS Code)"));
if (Directory.Exists(frontend))
{
    var provider = new PhysicalFileProvider(frontend);
    app.UseDefaultFiles(new DefaultFilesOptions { FileProvider = provider });
    app.UseStaticFiles(new StaticFileOptions { FileProvider = provider });
}
if (app.Environment.IsDevelopment()) { app.UseSwagger(); app.UseSwaggerUI(); }
app.UseRouting();
app.UseCors();
app.UseRateLimiter();
app.UseAuthentication();
app.UseAuthorization();
app.MapControllers();
app.Run();
