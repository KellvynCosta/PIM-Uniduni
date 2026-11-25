using System.Diagnostics;
using System.Net.Http.Headers;
using System.Net.Http.Json;
using System.Text.Json;
using Microsoft.AspNetCore.Identity;
using Microsoft.EntityFrameworkCore;
using Uniduni.API.Data;
using Uniduni.API.Models;
using Uniduni.API.Security;

var root = Path.GetFullPath(Path.Combine(AppContext.BaseDirectory, "..", "..", "..", "..", ".."));
var api = Path.Combine(root, "backend (Visual Studio)", "Uniduni.API", "Uniduni.API");
using var settings = JsonDocument.Parse(File.ReadAllText(Path.Combine(api, "appsettings.json")));
var connection = Environment.GetEnvironmentVariable("ConnectionStrings__DefaultConnection")
    ?? settings.RootElement.GetProperty("ConnectionStrings").GetProperty("DefaultConnection").GetString();
await using var db = new AppDbContext(new DbContextOptionsBuilder<AppDbContext>().UseSqlServer(connection).Options);
var prefix = (args.Contains("--preparar-interface") ? "pim-ui-" : "pim-teste-") + Guid.NewGuid().ToString("N");
var password = Guid.NewGuid().ToString("N") + "!aA1";
var senhas = new SenhasService(new PasswordHasher<Usuario>());
var admin = new Usuario { Nome = "Teste de integração", Email = prefix + "-admin@example.invalid", TipoUsuario = Perfis.Administrador };
admin.Senha = senhas.Gerar(admin, password);
var fixturePath=Path.Combine(root,"tmp","qa-ui.json");
if(args.Contains("--limpar-interface"))
{
    using var fixture=JsonDocument.Parse(File.ReadAllText(fixturePath));
    var email=fixture.RootElement.GetProperty("email").GetString()!;
    var tag=fixture.RootElement.GetProperty("prefix").GetString()!;
    if(!tag.StartsWith("pim-ui-") || email!=tag+"-admin@example.invalid") throw new Exception("Fixture inválido.");
    var emails = new[] { email, tag + "-cliente@example.invalid", tag + "-funcionario@example.invalid", tag + "-mobile@example.invalid" };
    var usuarios=await db.Usuarios.Where(u=>emails.Contains(u.Email)).Select(u=>u.Id).ToListAsync();
    var permitirRetirada=args.Contains("--permitir-retirada-temporaria");
    if(await db.PedidosLoja.AnyAsync(p=>usuarios.Contains(p.UsuarioId)&&p.Status!="Cancelado"&&p.Status!="Expirado"&&(!permitirRetirada||p.Status!="Retirado")))
        throw new Exception("Cancele os pedidos temporários pela interface antes de limpar, para restaurar os saldos.");
    // Retirada só pode ser limpa quando TODOS os seus itens usam produtos exclusivos deste fixture.
    // Vendas com qualquer produto preexistente continuam protegidas, mesmo com a opção de teste.
    var retirados=await db.PedidosLoja.Where(p=>usuarios.Contains(p.UsuarioId)&&p.Status=="Retirado").Select(p=>p.Id).ToListAsync();
    if(await db.ItensPedidoLoja.AnyAsync(i=>retirados.Contains(i.PedidoId)&&!db.ProdutoVariacoes.Any(v=>v.Id==i.VariacaoId&&v.Produto.Nome.StartsWith(tag))))
        throw new Exception("Retirada contém produto não temporário; limpeza bloqueada para preservar os saldos.");
    var pedidos=await db.PedidosLoja.Where(p=>usuarios.Contains(p.UsuarioId)).Select(p=>p.Id).ToListAsync();
    await db.EventosPedidoLoja.Where(ev=>pedidos.Contains(ev.PedidoId)).ExecuteDeleteAsync();
    await db.PagamentosSimulados.Where(pg=>pedidos.Contains(pg.PedidoId)).ExecuteDeleteAsync();
    await db.ItensPedidoLoja.Where(i=>pedidos.Contains(i.PedidoId)).ExecuteDeleteAsync();
    await db.PedidosLoja.Where(p=>pedidos.Contains(p.Id)).ExecuteDeleteAsync();
    await db.CarrinhoItensLoja.Where(i=>usuarios.Contains(i.UsuarioId)).ExecuteDeleteAsync();
    await db.MovimentacoesEstoque.Where(m=>m.UsuarioId!=null&&usuarios.Contains(m.UsuarioId.Value)).ExecuteDeleteAsync();
    var produtos=await db.Produtos.Where(p=>p.Nome.StartsWith(tag)).Select(p=>p.Id).ToListAsync();
    var variacoes=await db.ProdutoVariacoes.Where(v=>produtos.Contains(v.ProdutoId)).Select(v=>v.Id).ToListAsync();
    await db.MovimentacoesEstoque.Where(m=>variacoes.Contains(m.VariacaoId)).ExecuteDeleteAsync();
    await db.ProdutoVariacoes.Where(v=>variacoes.Contains(v.Id)).ExecuteDeleteAsync();
    await db.Produtos.Where(p=>produtos.Contains(p.Id)).ExecuteDeleteAsync();
    await db.Sessoes.Where(s=>usuarios.Contains(s.UsuarioId)).ExecuteDeleteAsync();
    await db.Usuarios.Where(u=>usuarios.Contains(u.Id)).ExecuteDeleteAsync();
    File.Delete(fixturePath);
    Console.WriteLine("Registros temporários da interface removidos.");
    return;
}
if(args.Contains("--preparar-interface"))
{
    if(File.Exists(fixturePath)) throw new Exception("Limpe primeiro o fixture de interface existente.");
    var clienteUi = new Usuario { Nome = "Cliente da revisão", Email = prefix + "-cliente@example.invalid", TipoUsuario = Perfis.Cliente };
    var funcionarioUi = new Usuario { Nome = "Funcionário da revisão", Email = prefix + "-funcionario@example.invalid", TipoUsuario = Perfis.Funcionario };
    clienteUi.Senha = senhas.Gerar(clienteUi, password);
    funcionarioUi.Senha = senhas.Gerar(funcionarioUi, password);
    db.Usuarios.AddRange(admin, clienteUi, funcionarioUi); await db.SaveChangesAsync();
    Directory.CreateDirectory(Path.GetDirectoryName(fixturePath)!);
    await File.WriteAllTextAsync(fixturePath,JsonSerializer.Serialize(new { prefix,email=admin.Email,clienteEmail=clienteUi.Email,funcionarioEmail=funcionarioUi.Email,senha=password }));
    Console.WriteLine("Três contas temporárias de interface preparadas; credenciais apenas em tmp/qa-ui.json.");
    return;
}
Process? processo = null;
var checks = 0;
using var client = new HttpClient { BaseAddress = new Uri("http://127.0.0.1:5291"), Timeout = TimeSpan.FromSeconds(15) };

async Task<(int Status, string Text)> Send(HttpMethod method, string path, object? data = null, string? token = null)
{
    using var request = new HttpRequestMessage(method, path);
    if (data is not null) request.Content = JsonContent.Create(data);
    if (token is not null) request.Headers.Authorization = new AuthenticationHeaderValue("Bearer", token);
    using var response = await client.SendAsync(request);
    return ((int)response.StatusCode, await response.Content.ReadAsStringAsync());
}
void Check(bool condition, string description)
{
    if (!condition) throw new Exception("FALHOU: " + description);
    checks++;
    Console.WriteLine("OK: " + description);
}
async Task<JsonElement> Expect(HttpMethod method, string path, int expected, object? data = null, string? token = null)
{
    var response = await Send(method, path, data, token);
    if(response.Status!=expected)Console.WriteLine($"Resposta inesperada: {response.Status} — {response.Text[..Math.Min(response.Text.Length,600)]}");
    Check(response.Status == expected, method + " " + path + " retorna " + expected);
    if (string.IsNullOrEmpty(response.Text)) return default;
    try { return JsonDocument.Parse(response.Text).RootElement.Clone(); }
    catch (JsonException) { return default; }
}
async Task<string> Login(string email, string senha)
{
    var body = await Expect(HttpMethod.Post, "/api/Usuarios/login", 200, new { email, senha });
    Check(!body.GetProperty("usuario").TryGetProperty("senha", out _), "Login não expõe senha");
    return body.GetProperty("token").GetString()!;
}

try
{
    db.Usuarios.Add(admin);
    await db.SaveChangesAsync();
    var start = new ProcessStartInfo("dotnet") {
        WorkingDirectory = api, RedirectStandardOutput = true, RedirectStandardError = true, UseShellExecute = false,
        CreateNoWindow = true
    };
    start.ArgumentList.Add(Path.Combine(api, "bin", "Debug", "net10.0", "Uniduni.API.dll"));
    start.ArgumentList.Add("--urls"); start.ArgumentList.Add(client.BaseAddress.ToString());
    start.Environment["ASPNETCORE_ENVIRONMENT"] = "Development";
    start.Environment["Logging__LogLevel__Default"] = "Warning";
    start.Environment["Logging__LogLevel__Microsoft.EntityFrameworkCore.Database.Command"] = "Warning";
    processo = Process.Start(start)!;
    processo.OutputDataReceived += (_, _) => { };
    processo.ErrorDataReceived += (_, _) => { };
    processo.BeginOutputReadLine(); processo.BeginErrorReadLine();
    var ready = false;
    for (var attempt = 0; attempt < 40; attempt++)
    {
        if (processo.HasExited) throw new Exception("A API de teste encerrou antes de iniciar.");
        try { if ((await Send(HttpMethod.Get, "/api/Produtos")).Status == 200) { ready = true; break; } }
        catch (HttpRequestException) { }
        await Task.Delay(250);
    }
    Check(ready, "API conectada ao SQL Server");
    await Expect(HttpMethod.Get, "/", 200);
    await Expect(HttpMethod.Get, "/js/api.js", 200);
    await Expect(HttpMethod.Get, "/html/cadastro.html", 200);
    await Expect(HttpMethod.Get, "/api/Usuarios", 401);
    await Expect(HttpMethod.Post, "/api/Produtos", 401, new { });
    await Expect(HttpMethod.Post, "/api/Usuarios/login", 401, new { email = admin.Email, senha = "incorreta" });
    var adminToken = await Login(admin.Email, password);
    await Expect(HttpMethod.Get, "/api/Usuarios", 200, token: adminToken);
    await Expect(HttpMethod.Delete, "/api/Usuarios/" + admin.Id, 400, token: adminToken);

    var clienteEmail = prefix + "-cliente@example.invalid";
    var cliente = await Expect(HttpMethod.Post, "/api/Usuarios/cadastro", 201,
        new { nome = "Cliente teste", email = clienteEmail, senha = password, tipoUsuario = "Administrador" });
    Check(cliente.GetProperty("tipoUsuario").GetString() == "Cliente", "Cadastro público ignora tentativa de elevação de perfil");
    Check(!cliente.TryGetProperty("senha", out _), "Cadastro não expõe senha");
    var clienteId = cliente.GetProperty("id").GetInt32();
    var clienteToken = await Login(clienteEmail.ToUpperInvariant(), password);
    await Expect(HttpMethod.Get, "/api/Usuarios", 403, token: clienteToken);
    await Expect(HttpMethod.Post, "/api/Usuarios", 403, new { }, clienteToken);
    await Expect(HttpMethod.Post, "/api/Produtos", 403, new { }, clienteToken);
    await Expect(HttpMethod.Post, "/api/Usuarios/cadastro", 409,
        new { nome = "Duplicado", email = clienteEmail.ToUpperInvariant(), senha = password });
    await Expect(HttpMethod.Post, "/api/Usuarios/cadastro", 400,
        new { nome = "Senha curta", email = prefix + "-invalido@example.invalid", senha = "123" });

    var equipeEmail = prefix + "-funcionario@example.invalid";
    var funcionario = await Expect(HttpMethod.Post, "/api/Usuarios", 201,
        new { nome = "Funcionário teste", email = equipeEmail, senha = password, tipoUsuario = "Funcionario" }, adminToken);
    var funcionarioId = funcionario.GetProperty("id").GetInt32();
    var equipeToken = await Login(equipeEmail, password);
    await Expect(HttpMethod.Get, "/api/Usuarios", 403, token: equipeToken);
    await Expect(HttpMethod.Post, "/api/Produtos", 400, new { }, equipeToken);
    var catalogoChecks = await CatalogoChecks.Run(Expect,Send,db,prefix,adminToken,clienteToken,equipeToken);
    checks += catalogoChecks;
    var comprasChecks = await ComprasChecks.Run(Expect,Send,db,prefix,password,adminToken,clienteToken,equipeToken);
    checks += comprasChecks;
    await Expect(HttpMethod.Put, "/api/Usuarios/" + funcionarioId, 200,
        new { nome = "Funcionário teste", email = equipeEmail, telefone = "", tipoUsuario = "Cliente" }, adminToken);
    await Expect(HttpMethod.Post, "/api/Produtos", 403, new { }, equipeToken);
    await Expect(HttpMethod.Put, "/api/Usuarios/" + funcionarioId, 200,
        new { nome = "Funcionário teste", email = equipeEmail, telefone = "", tipoUsuario = "Funcionario" }, adminToken);
    await Expect(HttpMethod.Put, "/api/Usuarios/alterar-senha/" + admin.Id, 403,
        new { senhaAtual = password, novaSenha = password + "nova" }, clienteToken);
    await Expect(HttpMethod.Put, "/api/Usuarios/alterar-senha/" + clienteId, 400,
        new { senhaAtual = "incorreta", novaSenha = password + "nova" }, clienteToken);
    await Expect(HttpMethod.Put, "/api/Usuarios/alterar-senha/" + clienteId, 200,
        new { senhaAtual = password, novaSenha = password + "nova" }, clienteToken);
    await Expect(HttpMethod.Get, "/api/Usuarios/me", 401, token: clienteToken);
    await Expect(HttpMethod.Post, "/api/Usuarios/login", 401, new { email = clienteEmail, senha = password });
    clienteToken = await Login(clienteEmail, password + "nova");

    // Simula sessão expirada no armazenamento sem alterar o relógio do servidor.
    var tokenHash = SessaoAuthenticationHandler.HashToken(clienteToken);
    await db.Sessoes.Where(s => s.TokenHash == tokenHash).ExecuteUpdateAsync(setters => setters.SetProperty(s => s.ExpiraEm, DateTime.UtcNow.AddMinutes(-1)));
    await Expect(HttpMethod.Get, "/api/Usuarios/me", 401, token: clienteToken);
    await Expect(HttpMethod.Post, "/api/Usuarios/logout", 204, token: equipeToken);
    await Expect(HttpMethod.Get, "/api/Usuarios/me", 401, token: equipeToken);
    await Expect(HttpMethod.Delete, "/api/Usuarios/" + funcionarioId, 200, token: adminToken);
    await Expect(HttpMethod.Post, "/api/Usuarios/login", 401, new { email = equipeEmail, senha = password });
    Check(await db.Usuarios.AsNoTracking().AnyAsync(u => u.Id == funcionarioId && !u.Ativo), "Desativação preserva o registro");
    Check(await db.Usuarios.AsNoTracking().Where(u => u.Email.StartsWith(prefix)).AllAsync(u => u.Senha.StartsWith("PBKDF2:")), "Senhas persistidas somente como hash");
    await Expect(HttpMethod.Post, "/api/Usuarios/redefinir-senha", 410, new { email = admin.Email, novaSenha = "fraude" });
    var limited = false;
    for (var i = 0; i < 16; i++)
        if ((await Send(HttpMethod.Post, "/api/Usuarios/login", new { email = "invalido", senha = "" })).Status == 429)
        { limited = true; break; }
    Check(limited, "Limitação de tentativas de autenticação aplicada");
    Console.WriteLine("Concluído: " + checks + " verificações passaram.");
}
finally
{
    if (processo is { HasExited: false }) { processo.Kill(entireProcessTree: true); await processo.WaitForExitAsync(); }
    processo?.Dispose();
    var ids = await db.Usuarios.AsNoTracking().Where(u => u.Email.StartsWith(prefix)).Select(u => u.Id).ToListAsync();
    await db.Sessoes.Where(s => ids.Contains(s.UsuarioId)).ExecuteDeleteAsync();
    await db.Usuarios.Where(u => ids.Contains(u.Id)).ExecuteDeleteAsync();
    Console.WriteLine("Contas temporárias deste teste removidas.");
}
