const { test } = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const vm = require('node:vm');
const path = require('node:path');

function iniciar(fetchImpl, port = '5288') {
    const dados = new Map([['uniduniToken', 'token-teste'], ['usuarioLogado', '{"nome":"Cliente"}']]);
    const sessao = { getItem: k => dados.get(k) ?? null, removeItem: k => dados.delete(k) };
    const contexto = vm.createContext({ location: { port, protocol: 'http:', origin: `http://localhost:${port}`, pathname: '/html/admin.html' },
        localStorage: { removeItem() {} }, sessionStorage: sessao, Headers, URL, fetch: fetchImpl });
    vm.runInContext(fs.readFileSync(path.join(__dirname, '..', 'frontend (VS Code)', 'js', 'api.js'), 'utf8'), contexto);
    return { contexto, dados };
}

test('texto e atributos vindos do banco não são interpretados como marcação', () => {
    const { contexto } = iniciar();
    assert.equal(vm.runInContext('escaparHtml(\'<img src=x onerror="alert(1)">\')', contexto), '&lt;img src=x onerror=&quot;alert(1)&quot;&gt;');
});
test('requisição envia a sessão para a API e mantém as opções', async () => {
    let recebido;
    const { contexto } = iniciar(async (url, options) => { recebido = { url, options }; return { status: 200 }; });
    await vm.runInContext('apiFetch("/api/Usuarios", { method: "POST", headers: { "Content-Type": "application/json" }, body: "{}" })', contexto);
    assert.equal(recebido.options.headers.get('Authorization'), 'Bearer token-teste');
    assert.equal(recebido.options.headers.get('Content-Type'), 'application/json');
    assert.equal(recebido.options.method, 'POST');
});
test('token não é enviado a um endereço externo', async () => {
    let chamou = false;
    const { contexto } = iniciar(async () => { chamou = true; });
    await assert.rejects(vm.runInContext('apiFetch("https://exemplo.invalid/api")', contexto), /inválido/);
    assert.equal(chamou, false);
});
test('sessão expirada limpa os dados locais e retorna ao login', async () => {
    const { contexto, dados } = iniciar(async () => ({ status: 401 }));
    await vm.runInContext('apiFetch("/api/Usuarios")', contexto);
    assert.equal(dados.size, 0);
    assert.equal(contexto.location.href, 'login.html');
});
test('Live Server usa a API local configurada', async () => {
    let origem;
    const { contexto } = iniciar(async url => { origem = url.origin; return { status: 200 }; }, '5500');
    await vm.runInContext('apiFetch("http://localhost:5288/api/Produtos")', contexto);
    assert.equal(origem, 'http://localhost:5288');
});
