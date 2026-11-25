"use strict";

const moedaUniduni = new Intl.NumberFormat("pt-BR", { style: "currency", currency: "BRL" });
let produtosCatalogo = [];
let categoriasUniduni = [];
let produtoEmEdicao = null;
let filtroEstoqueBaixo = false;
const e = escaparHtml;

async function dadosCatalogo(url, options) {
    const resposta = await apiFetch(url, options);
    if (!resposta.ok) throw new Error(await erroDaApi(resposta));
    return resposta.json();
}
function enviarCatalogo(url, method, dados) {
    return dadosCatalogo(url, { method, headers: { "Content-Type": "application/json" }, body: JSON.stringify(dados) });
}
function avisoCatalogo(texto, erro = false) {
    const alvo = document.getElementById("catalogoMensagem") || document.getElementById("catalogoStatus");
    if (!alvo) return;
    alvo.textContent = texto;
    alvo.className = erro ? "catalogo-aviso erro" : "catalogo-aviso";
    if (erro) alvo.focus();
}
function telaCatalogo(html) {
    document.getElementById("areaAdminConteudo").innerHTML = `<p id="catalogoMensagem" role="status" aria-live="polite" tabindex="-1"></p>${html}`;
}
function opcoesCategorias(id) {
    return categoriasUniduni.map(c => `<option value="${c.id}" ${Number(id) === c.id ? "selected" : ""}>${e(c.nome)}</option>`).join("");
}
async function categoriasCatalogo() {
    if (!categoriasUniduni.length) categoriasUniduni = await dadosCatalogo("/api/Categorias");
    return categoriasUniduni;
}
function tamanhosProduto(produto) {
    return [...new Set(produto.variacoes.filter(v => v.ativo).map(v => v.tamanho))].join(", ");
}

async function iniciarCatalogoPublico() {
    if (!document.getElementById("produtos")) return;
    try {
        const [produtos] = await Promise.all([dadosCatalogo("/api/Produtos"), categoriasCatalogo()]);
        produtosCatalogo = produtos;
        document.getElementById("filtroCategoria").innerHTML = `<option value="">Todas as categorias</option>${opcoesCategorias()}`;
        const cores = [...new Set(produtos.flatMap(p => p.variacoes.map(v => v.cor)))].sort();
        const tamanhos = [...new Set(produtos.flatMap(p => p.variacoes.map(v => v.tamanho)))];
        document.getElementById("filtroCor").innerHTML = `<option value="">Todas as cores</option>${cores.map(c => `<option>${e(c)}</option>`).join("")}`;
        document.getElementById("filtroTamanho").innerHTML = `<option value="">Todos os tamanhos</option>${tamanhos.map(t => `<option>${e(t)}</option>`).join("")}`;
        for (const id of ["barraPesquisa", "filtroCategoria", "filtroCor", "filtroTamanho", "filtroDisponivel"])
            document.getElementById(id)?.addEventListener(id === "barraPesquisa" ? "input" : "change", filtrarCatalogo);
        const atalhos = document.getElementById("atalhosCategorias");
        if (atalhos) {
            const desenhos = [
                '<path d="m8 4-6 4 3 5 3-2v10h8V11l3 2 3-5-6-4c0 4-8 4-8 0Z"/>',
                '<path d="M7 4v9c0 2 4 2 5 0l5 3 4 1v4H3V4Z"/>',
                '<path d="M12 12C2-2-4 25 12 12Zm0 0c10-14 16 13 0 0Z"/><circle cx="12" cy="12" r="2"/>',
                '<path d="m3 7 9-4 9 4v10l-9 4-9-4V7Zm0 0 9 4 9-4M12 11v10M7 5l9 4"/>'
            ];
            atalhos.innerHTML = categoriasUniduni.map((c, i) => {
                const n = produtos.filter(p => p.categoriaId === c.id).length;
                return `<button type="button" class="categoria-atalho" data-categoria="${c.id}" aria-pressed="false"><svg class="icone" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.5" stroke-linejoin="round" stroke-linecap="round" aria-hidden="true">${desenhos[i % desenhos.length]}</svg><span><strong>${e(c.nome)}</strong><small>${n ? `${n} ${n === 1 ? "peça no catálogo" : "peças no catálogo"}` : "Explore a categoria"}</small></span></button>`;
            }).join("");
            atalhos.addEventListener("click", event => {
                const botao = event.target.closest("[data-categoria]"); if (!botao) return;
                document.getElementById("filtroCategoria").value = botao.dataset.categoria;
                document.getElementById("filtroCor").value = ""; document.getElementById("filtroTamanho").value = "";
                filtrarCatalogo(); document.getElementById("catalogoTitulo").scrollIntoView({ behavior: matchMedia("(prefers-reduced-motion: reduce)").matches ? "auto" : "smooth", block: "start" });
            });
        }
        document.getElementById("ordenarProdutos")?.addEventListener("change", filtrarCatalogo);
        document.getElementById("limparFiltros")?.addEventListener("click", () => {
            for (const id of ["barraPesquisa", "filtroCategoria", "filtroCor", "filtroTamanho"]) document.getElementById(id).value = "";
            document.getElementById("filtroDisponivel").checked = false; filtrarCatalogo();
        });
        filtrarCatalogo();
    } catch (erro) { avisoCatalogo(`Não foi possível carregar o catálogo. ${erro.message}`, true); }
}
function filtrarCatalogo() {
    const termo = document.getElementById("barraPesquisa").value.trim().toLocaleLowerCase("pt-BR");
    const categoria = document.getElementById("filtroCategoria").value;
    const cor = document.getElementById("filtroCor").value;
    const tamanho = document.getElementById("filtroTamanho").value;
    const disponivel = document.getElementById("filtroDisponivel").checked;
    const produtos = produtosCatalogo.filter(p => (!termo || `${p.nome} ${p.descricao}`.toLocaleLowerCase("pt-BR").includes(termo))
        && (!categoria || p.categoriaId === Number(categoria))
        && p.variacoes.some(v => v.ativo && (!cor || v.cor === cor) && (!tamanho || v.tamanho === tamanho) && (!disponivel || v.disponivel > 0)));
    const ordem = document.getElementById("ordenarProdutos")?.value || "nome";
    produtos.sort((a, b) => ordem === "menor" ? a.preco - b.preco : ordem === "maior" ? b.preco - a.preco : a.nome.localeCompare(b.nome, "pt-BR"));
    document.querySelectorAll("[data-categoria]").forEach(botao => botao.setAttribute("aria-pressed", String(botao.dataset.categoria === categoria)));
    document.getElementById("produtos").innerHTML = produtos.map(p => `<article class="card">
        <a href="html/produto.html?id=${p.id}" class="catalogo-foto"><img src="images/${imagemSegura(p.imagem)}" alt="${e(p.nome)}" loading="lazy"></a>
        <p class="catalogo-categoria">${e(p.categoriaNome)}</p><h3>${e(p.nome)}</h3>
        <p>${e(p.descricao)}</p><p class="preco">${moedaUniduni.format(p.preco)}</p>
        <p class="catalogo-meta">Tamanhos: ${e(tamanhosProduto(p)) || "A confirmar"}</p>
        <p class="catalogo-meta">${p.estoque > 0 ? "Disponível para retirada" : "Sem estoque no momento"}</p>
        <a class="catalogo-botao" href="html/produto.html?id=${p.id}">Ver essa fofura</a></article>`).join("");
    avisoCatalogo(produtos.length ? `${produtos.length} ${produtos.length === 1 ? "produto encontrado" : "produtos encontrados"}.`
        : "Nenhum produto corresponde à busca. Experimente outra cor, tamanho ou categoria.");
}

async function iniciarDetalheCatalogo() {
    if (!document.getElementById("variacoesProduto")) return;
    try {
        const id = Number(new URLSearchParams(location.search).get("id"));
        if (!Number.isInteger(id) || id < 1) throw new Error("Volte ao catálogo e escolha um produto.");
        const p = await dadosCatalogo(`/api/Produtos/${id}`);
        document.title = `${p.nome} — Uniduni`;
        for (const [alvo, valor] of [["nomeProduto", p.nome], ["descricaoProduto", p.descricao], ["precoProduto", moedaUniduni.format(p.preco)],
            ["generoProduto", p.genero], ["medidasProduto", p.guiaMedidas || "As medidas desta peça ainda não foram informadas pela loja."]])
            document.getElementById(alvo).textContent = valor;
        const imagem = document.getElementById("imagemProduto");
        imagem.src = `../images/${imagemSegura(p.imagem)}`; imagem.alt = p.nome;
        const cores = [...new Set(p.variacoes.map(v => v.cor))];
        document.getElementById("corProduto").innerHTML = cores.map(c => `<option>${e(c)}</option>`).join("");
        function atualizarTamanhos() {
            const cor = document.getElementById("corProduto").value;
            document.getElementById("tamanhoProduto").innerHTML = p.variacoes.filter(v => v.cor === cor)
                .map(v => `<option value="${v.id}">${e(v.tamanho)}${v.disponivel === 0 ? " — esgotado" : ""}</option>`).join("");
            atualizarSaldo();
        }
        function atualizarSaldo() {
            const v = p.variacoes.find(v => v.id === Number(document.getElementById("tamanhoProduto").value));
            const adicionar = document.getElementById("adicionarCarrinho");
            if (adicionar) adicionar.disabled = !v || v.disponivel < 1;
            const quantidade = document.getElementById("quantidadeProduto");
            if (quantidade) { quantidade.max = Math.min(99, v?.disponivel || 1); quantidade.value = 1; }
            document.getElementById("saldoProduto").textContent = !v ? "Nenhuma variação disponível."
                : v.disponivel ? `${v.disponivel} ${v.disponivel === 1 ? "unidade disponível" : "unidades disponíveis"} nesta combinação.` : "Esta combinação está sem estoque.";
        }
        document.getElementById("corProduto").addEventListener("change", atualizarTamanhos);
        document.getElementById("tamanhoProduto").addEventListener("change", atualizarSaldo);
        atualizarTamanhos();
    } catch (erro) {
        document.getElementById("nomeProduto").textContent = "Produto indisponível";
        document.getElementById("saldoProduto").textContent = erro.message;
        document.getElementById("variacoesProduto").hidden = true;
    }
}

async function carregarProdutosAdmin(somenteBaixo = false) {
    filtroEstoqueBaixo = somenteBaixo === true;
    try {
        await categoriasCatalogo();
        const [produtos, alertas] = await Promise.all([dadosCatalogo("/api/Produtos/administracao"), dadosCatalogo("/api/Estoque/alertas")]);
        const selecionados = filtroEstoqueBaixo ? produtos.filter(p => alertas.some(a => a.produtoId === p.id)) : produtos;
        telaCatalogo(`<div class="admin-section-header"><div><h2>Produtos e estoque</h2><p class="catalogo-ajuda">Controle cada cor e tamanho separadamente.</p></div>
            <button class="catalogo-botao" data-catalogo="novo">Cadastrar produto</button></div>
            <div class="estoque-filtros"><button class="catalogo-secundario" data-catalogo="todos" ${!filtroEstoqueBaixo ? 'aria-pressed="true"' : 'aria-pressed="false"'}>Todos os produtos</button>
            <button class="catalogo-secundario" data-catalogo="alertas" ${filtroEstoqueBaixo ? 'aria-pressed="true"' : 'aria-pressed="false"'}>Estoque baixo (${alertas.length} variações)</button></div>
            ${selecionados.length ? `<div class="catalogo-tabela"><table class="admin-table"><caption class="somente-leitor">Produtos cadastrados e disponibilidade por variação</caption>
            <thead><tr><th scope="col">Produto</th><th scope="col">Categoria</th><th scope="col">Preço</th><th scope="col">Disponível</th><th scope="col">Situação</th><th scope="col">Ação</th></tr></thead>
            <tbody>${selecionados.map(p => `<tr><th scope="row">${e(p.nome)}<span class="catalogo-detalhe-linha">${e(tamanhosProduto(p))}</span></th><td>${e(p.categoriaNome)}</td>
            <td>${moedaUniduni.format(p.preco)}</td><td>${p.estoque}</td><td>${!p.ativo ? "Inativo" : alertas.some(a => a.produtoId === p.id) ? '<span class="estoque-baixo">Estoque baixo</span>' : "Ativo"}</td>
            <td><button class="catalogo-secundario" data-catalogo="editar" data-id="${p.id}">Gerenciar<span class="somente-leitor"> ${e(p.nome)}</span></button></td></tr>`).join("")}</tbody></table></div>`
            : `<div class="catalogo-vazio"><h3>${filtroEstoqueBaixo ? "Nenhuma variação com estoque baixo" : "Nenhum produto cadastrado"}</h3><p>${filtroEstoqueBaixo ? "Os saldos ativos estão acima dos limites configurados." : "Cadastre o primeiro produto e sua combinação inicial de cor e tamanho."}</p></div>`}`);
        instalarAcoesCatalogo();
    } catch (erro) { telaCatalogo(""); avisoCatalogo(erro.message, true); }
}
function camposVariacao(v = {}, inicial = false) {
    return `<div class="catalogo-campos"><div class="form-group"><label for="variacaoCor">Cor</label><input id="variacaoCor" maxlength="40" required value="${e(v.cor || "")}" placeholder="Ex.: Azul"></div>
        <div class="form-group"><label for="variacaoTamanho">Tamanho ou numeração</label><input id="variacaoTamanho" list="tamanhosSugeridos" maxlength="20" required value="${e(v.tamanho || "")}" placeholder="Ex.: RN, P ou 18">
        <datalist id="tamanhosSugeridos"><option value="RN"><option value="P"><option value="M"><option value="G"><option value="Único"></datalist></div>
        <div class="form-group"><label for="variacaoMinimo">Avisar quando disponível for até</label><input type="number" id="variacaoMinimo" min="0" max="1000000" value="${v.estoqueMinimo ?? 3}" required></div>
        ${inicial ? '<div class="form-group"><label for="variacaoInicial">Quantidade inicial</label><input type="number" id="variacaoInicial" min="0" max="1000000" value="0" required></div>' : ""}</div>
        <p class="catalogo-ajuda">Roupas: RN, P, M ou G. Calçados: numeração própria. Acessórios e kits: tamanho informado pela loja.</p>`;
}
async function abrirFormularioCadastrarProduto() {
    try { await categoriasCatalogo(); produtoEmEdicao = null; renderizarFormularioProduto(); }
    catch (erro) { avisoCatalogo(erro.message, true); }
}
async function abrirFormularioEditarProduto(id, mensagem = "") {
    try {
        await categoriasCatalogo();
        produtoEmEdicao = await dadosCatalogo(`/api/Produtos/administracao/${id}`);
        renderizarFormularioProduto();
        if (mensagem) avisoCatalogo(mensagem);
        await carregarHistoricoProduto(id);
    } catch (erro) { avisoCatalogo(erro.message, true); }
}
function renderizarFormularioProduto() {
    const p = produtoEmEdicao;
    telaCatalogo(`<button class="catalogo-voltar" data-catalogo="todos">Voltar aos produtos</button><h2>${p ? e(p.nome) : "Cadastrar produto"}</h2>
        <p class="catalogo-ajuda">Os dados da peça aparecem no catálogo. As quantidades são controladas nas variações.</p>
        <form id="formProdutoCatalogo" class="admin-form catalogo-painel">
        <h3>Dados do produto</h3><div class="catalogo-campos">
        <div class="form-group"><label for="produtoNome">Nome</label><input id="produtoNome" required minlength="2" maxlength="100" value="${e(p?.nome || "")}"></div>
        <div class="form-group"><label for="produtoCategoria">Categoria</label><select id="produtoCategoria" required>${opcoesCategorias(p?.categoriaId || categoriasUniduni[0]?.id)}</select></div>
        <div class="form-group"><label for="produtoPreco">Preço (R$)</label><input id="produtoPreco" type="number" min="0.01" max="99999999.99" step="0.01" required value="${p?.preco ?? ""}"></div>
        <div class="form-group"><label for="produtoGenero">Gênero</label><select id="produtoGenero">${["Unissex", "Masculino", "Feminino"].map(g => `<option ${p?.genero === g ? "selected" : ""}>${g}</option>`).join("")}</select></div>
        <div class="form-group catalogo-largura"><label for="produtoDescricao">Descrição</label><textarea id="produtoDescricao" required minlength="5" maxlength="500" rows="3">${e(p?.descricao || "")}</textarea></div>
        <div class="form-group"><label for="produtoImagem">Arquivo da imagem</label><input id="produtoImagem" maxlength="255" value="${e(p?.imagem || "")}" placeholder="Ex.: body-azul.jpg"><p class="catalogo-ajuda">Use um arquivo já disponível na pasta de imagens do site.</p></div>
        <div class="form-group"><label for="produtoMedidas">Guia de medidas</label><textarea id="produtoMedidas" maxlength="500" rows="3" placeholder="Informe medidas reais da peça em centímetros.">${e(p?.guiaMedidas || "")}</textarea></div>
        </div>${p ? `<label class="catalogo-checkbox"><input type="checkbox" id="produtoAtivo" ${p.ativo ? "checked" : ""}> Produto visível no catálogo</label>`
            : `<h3>Primeira variação</h3>${camposVariacao({}, true)}`}
        <div class="catalogo-acoes"><button type="submit" class="catalogo-botao">${p ? "Salvar dados do produto" : "Cadastrar produto"}</button></div></form>
        ${p ? `<section class="catalogo-painel" aria-labelledby="variacoesTitulo"><div class="admin-section-header"><div><h3 id="variacoesTitulo">Cores, tamanhos e quantidades</h3>
        <p class="catalogo-ajuda">Disponível = estoque físico menos unidades reservadas.</p></div><button class="catalogo-secundario" data-catalogo="nova-variacao" ${!p.ativo ? "disabled" : ""}>Adicionar variação</button></div>
        <div class="catalogo-tabela"><table class="admin-table"><thead><tr><th>Cor / tamanho</th><th>Físico</th><th>Reservado</th><th>Disponível</th><th>Limite</th><th>Situação</th><th>Ações</th></tr></thead>
        <tbody>${p.variacoes.map(v => `<tr><th scope="row">${e(v.cor)} / ${e(v.tamanho)}</th><td>${v.estoque}</td><td>${v.reservado}</td><td>${v.disponivel}</td><td>${v.estoqueMinimo}</td>
        <td>${!v.ativo ? "Inativa" : v.estoqueBaixo ? '<span class="estoque-baixo">Estoque baixo</span>' : "Regular"}</td><td><div class="catalogo-acoes">
        <button class="catalogo-secundario" data-catalogo="movimentar" data-id="${v.id}" ${!v.ativo || !p.ativo ? "disabled" : ""}>Movimentar</button>
        <button class="catalogo-secundario" data-catalogo="editar-variacao" data-id="${v.id}">Editar</button></div></td></tr>`).join("")}</tbody></table></div>
        <div id="variacaoEditor"></div></section><section class="catalogo-painel" aria-labelledby="historicoTitulo"><h3 id="historicoTitulo">Histórico de estoque</h3>
        <p class="catalogo-ajuda">Últimas 50 movimentações deste produto, incluindo saldos iniciais e responsáveis.</p><div id="historicoProduto" aria-live="polite">Carregando histórico…</div></section>` : ""}`);
    document.getElementById("formProdutoCatalogo").addEventListener("submit", salvarProdutoCatalogo);
    instalarAcoesCatalogo();
}
function lerVariacao(inicial = false) {
    const r = { cor: document.getElementById("variacaoCor").value.trim(), tamanho: document.getElementById("variacaoTamanho").value.trim(),
        estoqueMinimo: Number(document.getElementById("variacaoMinimo").value) };
    if (inicial) r.estoqueInicial = Number(document.getElementById("variacaoInicial").value);
    return r;
}
async function salvarProdutoCatalogo(event) {
    event.preventDefault();
    const botao = event.currentTarget.querySelector('[type="submit"]'); botao.disabled = true;
    const p = produtoEmEdicao;
    const r = { nome: document.getElementById("produtoNome").value, descricao: document.getElementById("produtoDescricao").value,
        preco: Number(document.getElementById("produtoPreco").value), categoriaId: Number(document.getElementById("produtoCategoria").value),
        genero: document.getElementById("produtoGenero").value, imagem: document.getElementById("produtoImagem").value.trim(),
        guiaMedidas: document.getElementById("produtoMedidas").value, ativo: p ? document.getElementById("produtoAtivo").checked : true };
    if (!p) r.variacaoInicial = lerVariacao(true);
    try {
        const salvo = await enviarCatalogo(p ? `/api/Produtos/${p.id}` : "/api/Produtos", p ? "PUT" : "POST", r);
        await abrirFormularioEditarProduto(salvo.id, p ? "Dados do produto atualizados." : "Produto e variação inicial cadastrados.");
    } catch (erro) { avisoCatalogo(erro.message, true); }
    finally { botao.disabled = false; }
}
function instalarAcoesCatalogo() {
    document.getElementById("areaAdminConteudo").onclick = async event => {
        const botao = event.target.closest("[data-catalogo]");
        if (!botao || botao.disabled) return;
        const id = Number(botao.dataset.id);
        switch (botao.dataset.catalogo) {
            case "novo": await abrirFormularioCadastrarProduto(); break;
            case "todos": await carregarProdutosAdmin(); break;
            case "alertas": await carregarProdutosAdmin(true); break;
            case "editar": await abrirFormularioEditarProduto(id); break;
            case "nova-variacao": editarVariacaoCatalogo(); break;
            case "editar-variacao": editarVariacaoCatalogo(id); break;
            case "movimentar": movimentarVariacaoCatalogo(id); break;
            case "fechar-editor": document.getElementById("variacaoEditor").innerHTML = ""; break;
        }
    };
}
function editarVariacaoCatalogo(id) {
    const p = produtoEmEdicao, v = p.variacoes.find(v => v.id === id);
    const editor = document.getElementById("variacaoEditor");
    editor.innerHTML = `<form id="formVariacaoCatalogo" class="catalogo-editor"><h4>${v ? "Editar variação" : "Adicionar variação"}</h4>
        ${camposVariacao(v, !v)}${v ? `<label class="catalogo-checkbox"><input id="variacaoAtiva" type="checkbox" ${v.ativo ? "checked" : ""}> Variação ativa</label>` : ""}
        <div class="catalogo-acoes"><button class="catalogo-botao" type="submit">Salvar variação</button><button class="catalogo-secundario" type="button" data-catalogo="fechar-editor">Cancelar</button></div></form>`;
    document.getElementById("variacaoCor").focus();
    document.getElementById("formVariacaoCatalogo").addEventListener("submit", async event => {
        event.preventDefault(); const botao = event.currentTarget.querySelector('[type="submit"]'); botao.disabled = true;
        const r = lerVariacao(!v);
        if (v) { r.versao = v.versao; r.ativo = document.getElementById("variacaoAtiva").checked; }
        try {
            await enviarCatalogo(`/api/Produtos/${p.id}/variacoes${v ? `/${v.id}` : ""}`, v ? "PUT" : "POST", r);
            await abrirFormularioEditarProduto(p.id, "Variação salva. O histórico do saldo foi preservado.");
        } catch (erro) { avisoCatalogo(`${erro.message} Se os dados mudaram, reabra o produto antes de tentar novamente.`, true); }
        finally { botao.disabled = false; }
    });
}
function movimentarVariacaoCatalogo(id) {
    const p = produtoEmEdicao, v = p.variacoes.find(v => v.id === id);
    const operacaoId = crypto.randomUUID();
    document.getElementById("variacaoEditor").innerHTML = `<form id="formMovimentacaoCatalogo" class="catalogo-editor"><h4>Movimentar ${e(v.cor)} / ${e(v.tamanho)}</h4>
        <p>Saldo físico atual: <strong>${v.estoque}</strong>. Reservado: <strong>${v.reservado}</strong>.</p>
        <div class="catalogo-campos"><div class="form-group"><label for="movimentoTipo">Operação</label><select id="movimentoTipo"><option value="Entrada">Entrada de mercadorias</option><option value="Ajuste">Ajustar saldo físico</option></select></div>
        <div class="form-group"><label id="movimentoQuantidadeLabel" for="movimentoQuantidade">Quantidade a acrescentar</label><input type="number" id="movimentoQuantidade" min="1" max="1000000" required></div>
        <div class="form-group catalogo-largura"><label for="movimentoJustificativa">Justificativa</label><textarea id="movimentoJustificativa" required minlength="5" maxlength="250" rows="2" placeholder="Ex.: Recebimento de reposição da peça."></textarea></div></div>
        <p id="movimentoExplicacao" class="catalogo-ajuda">A entrada soma unidades ao saldo atual.</p>
        <div class="catalogo-acoes"><button class="catalogo-botao" type="submit">Registrar movimentação</button><button class="catalogo-secundario" type="button" data-catalogo="fechar-editor">Cancelar</button></div></form>`;
    document.getElementById("movimentoTipo").addEventListener("change", event => {
        const ajuste = event.target.value === "Ajuste";
        document.getElementById("movimentoQuantidadeLabel").textContent = ajuste ? "Novo saldo físico total" : "Quantidade a acrescentar";
        document.getElementById("movimentoQuantidade").min = ajuste ? "0" : "1";
        document.getElementById("movimentoExplicacao").textContent = ajuste ? "Informe a quantidade total contada. O ajuste não pode ficar abaixo das unidades reservadas." : "A entrada soma unidades ao saldo atual.";
    });
    document.getElementById("movimentoQuantidade").focus();
    document.getElementById("formMovimentacaoCatalogo").addEventListener("submit", async event => {
        event.preventDefault(); const botao = event.currentTarget.querySelector('[type="submit"]'); botao.disabled = true;
        const r = { tipo: document.getElementById("movimentoTipo").value, quantidade: Number(document.getElementById("movimentoQuantidade").value),
            justificativa: document.getElementById("movimentoJustificativa").value.trim(), operacaoId, versao: v.versao };
        try {
            await enviarCatalogo(`/api/Estoque/variacoes/${v.id}/movimentacoes`, "POST", r);
            await abrirFormularioEditarProduto(p.id, "Movimentação registrada. Confira o saldo e o histórico abaixo.");
        } catch (erro) { avisoCatalogo(`${erro.message} Em caso de conflito, reabra o produto para atualizar o saldo.`, true); }
        finally { botao.disabled = false; }
    });
}
async function carregarHistoricoProduto(id) {
    try {
        const movimentos = await dadosCatalogo(`/api/Estoque/historico?produtoId=${id}`);
        const alvo = document.getElementById("historicoProduto");
        if (!alvo || produtoEmEdicao?.id !== id) return;
        alvo.innerHTML = movimentos.length ? `<div class="catalogo-tabela"><table class="admin-table"><thead><tr><th>Data</th><th>Cor / tamanho</th><th>Operação</th><th>Variação do saldo</th><th>Físico: antes / depois</th><th>Reserva: antes / depois</th><th>Responsável e justificativa</th></tr></thead>
            <tbody>${movimentos.map(m => `<tr><td>${e(new Date(m.criadaEm).toLocaleString("pt-BR"))}</td><td>${e(m.cor)} / ${e(m.tamanho)}</td><td>${e(m.tipo)}</td><td>${m.quantidade > 0 ? "+" : ""}${m.quantidade}</td><td>${m.saldoAnterior} / ${m.saldoAtual}</td><td>${m.reservadoAnterior} / ${m.reservadoAtual}</td>
            <td>${e(m.responsavel)}<span class="catalogo-detalhe-linha">${e(m.justificativa)}</span></td></tr>`).join("")}</tbody></table></div>`
            : "Nenhuma movimentação registrada para este produto.";
    } catch (erro) { avisoCatalogo(`Não foi possível carregar o histórico. ${erro.message}`, true); }
}

document.addEventListener("error", event => {
    const imagem = event.target;
    if (imagem.tagName === "IMG" && !imagem.dataset.fallback) {
        imagem.dataset.fallback = "1";
        imagem.src = `${location.pathname.includes("/html/") ? "../" : ""}images/produto-padrao.svg`;
    }
}, true);
document.addEventListener("DOMContentLoaded", () => { iniciarCatalogoPublico(); iniciarDetalheCatalogo(); });
