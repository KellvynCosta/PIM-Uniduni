"use strict";

function notificar(mensagem, tipo) {
    const regiao = document.getElementById("notificacoes");
    if (!regiao) return;
    const aviso = document.createElement("div");
    const erro = tipo === "erro" || /erro|não foi|não pode|inválid|não encontrado|falhou/i.test(String(mensagem));
    aviso.className = `notificacao${erro ? " erro" : ""}`;
    aviso.setAttribute("role", erro ? "alert" : "status");
    const texto = document.createElement("span"); texto.textContent = mensagem;
    const fechar = document.createElement("button"); fechar.type = "button"; fechar.setAttribute("aria-label", "Fechar aviso"); fechar.textContent = "×";
    fechar.addEventListener("click", () => aviso.remove()); aviso.append(texto, fechar); regiao.append(aviso);
    if (!erro) setTimeout(() => aviso.remove(), 7000);
}

async function confirmarAcao(mensagem, titulo = "Desativar esta conta?") {
    const dialogo = document.getElementById("dialogoConfirmacao");
    if (!dialogo || dialogo.open) return false;
    document.getElementById("dialogoTitulo").textContent = titulo;
    document.getElementById("dialogoMensagem").textContent = mensagem;
    dialogo.setAttribute("aria-labelledby", "dialogoTitulo");
    dialogo.setAttribute("aria-describedby", "dialogoMensagem");
    dialogo.returnValue = "cancelar"; dialogo.showModal();
    return new Promise(resolve => dialogo.addEventListener("close", () => resolve(dialogo.returnValue === "confirmar"), { once: true }));
}

(() => {
    const reduzMovimento = window.matchMedia("(prefers-reduced-motion: reduce)");
    const cabecalho = document.getElementById("siteHeader");
    const menuBotao = document.querySelector(".menu-toggle");
    const menu = document.getElementById("menuPrincipal");
    const topo = document.querySelector(".voltar-topo");
    const larguraMenu = window.matchMedia("(max-width: 900px)");
    function fecharMenu() {
        menu?.classList.remove("aberto"); menuBotao?.setAttribute("aria-expanded", "false"); menuBotao?.setAttribute("aria-label", "Abrir menu");
    }
    menuBotao?.addEventListener("click", () => {
        const aberto = menu.classList.toggle("aberto");
        menuBotao.setAttribute("aria-expanded", String(aberto)); menuBotao.setAttribute("aria-label", aberto ? "Fechar menu" : "Abrir menu");
        if (aberto) menu.querySelector("a")?.focus();
    });
    menu?.addEventListener("click", event => { if (event.target.closest("a")) fecharMenu(); });
    larguraMenu.addEventListener("change", fecharMenu);
    document.addEventListener("click", event => {
        if (!event.target.closest(".site-header")) fecharMenu();
        const dropdown = document.getElementById("dropdownUsuario");
        if (dropdown && !event.target.closest(".user-menu")) {
            dropdown.classList.remove("ativo"); document.getElementById("avatarUsuario")?.setAttribute("aria-expanded", "false");
        }
        const botaoAdmin = event.target.closest("[data-admin-nav]");
        if (botaoAdmin) document.querySelectorAll("[data-admin-nav]").forEach(botao => {
            botao.classList.toggle("ativo", botao === botaoAdmin);
            if (botao === botaoAdmin) botao.setAttribute("aria-current", "page"); else botao.removeAttribute("aria-current");
        });
        const mostrar = event.target.closest(".senha-toggle");
        if (mostrar) {
            const campo = document.getElementById(mostrar.getAttribute("aria-controls"));
            const visivel = campo.type === "password"; campo.type = visivel ? "text" : "password";
            mostrar.setAttribute("aria-pressed", String(visivel)); mostrar.setAttribute("aria-label", visivel ? "Ocultar senha" : "Mostrar senha");
            mostrar.classList.toggle("visivel", visivel);
        }
    });
    document.addEventListener("keydown", event => {
        if (event.key === "Escape") {
            if (menu?.classList.contains("aberto")) { fecharMenu(); menuBotao.focus(); }
            const conta = document.getElementById("dropdownUsuario");
            if (conta?.classList.contains("ativo")) { conta.classList.remove("ativo"); const botao = document.getElementById("avatarUsuario"); botao.setAttribute("aria-expanded", "false"); botao.focus(); }
        }
        if (event.key === "/" && !event.ctrlKey && !event.metaKey && !event.altKey && !event.target.closest("input,textarea,select,[contenteditable]")) {
            const busca = document.getElementById("barraPesquisa"); if (busca) { event.preventDefault(); busca.focus(); }
        }
    });
    let frame = false;
    function atualizarRolagem() {
        cabecalho?.classList.toggle("is-scrolled", window.scrollY > 20);
        if (topo) topo.hidden = window.scrollY < 500;
        frame = false;
    }
    window.addEventListener("scroll", () => { if (!frame) { frame = true; requestAnimationFrame(atualizarRolagem); } }, { passive: true });
    atualizarRolagem(); topo?.addEventListener("click", () => window.scrollTo({ top: 0, behavior: reduzMovimento.matches ? "auto" : "smooth" }));

    function prepararCampos(raiz = document) {
        raiz.querySelectorAll('input[type="password"]:not([data-senha-pronta])').forEach(campo => {
            if (!campo.id) return;
            campo.dataset.senhaPronta = "1";
            const grupo = document.createElement("span"); grupo.className = "senha-campo";
            campo.before(grupo); grupo.append(campo);
            const botao = document.createElement("button"); botao.type = "button"; botao.className = "senha-toggle";
            botao.setAttribute("aria-label", "Mostrar senha"); botao.setAttribute("aria-pressed", "false"); botao.setAttribute("aria-controls", campo.id);
            botao.innerHTML = '<svg class="icone" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.5" aria-hidden="true"><path d="M2 12s4-7 10-7 10 7 10 7-4 7-10 7S2 12 2 12Z"/><circle cx="12" cy="12" r="3"/></svg>';
            grupo.append(botao);
        });
        raiz.querySelectorAll(".admin-table thead th:not([scope])").forEach(th => th.setAttribute("scope", "col"));
    }
    prepararCampos();
    const conteudoAdmin = document.getElementById("areaAdminConteudo");
    if (conteudoAdmin) new MutationObserver(() => prepararCampos(conteudoAdmin)).observe(conteudoAdmin, { childList: true, subtree: true });

    const slides = [...document.querySelectorAll(".carrossel-slide")];
    if (slides.length) {
        const pontos = [...document.querySelectorAll(".indicador")];
        const pausa = document.querySelector(".carrossel-pausa");
        const contador = document.querySelector(".carrossel-contador");
        let atual = 0, temporizador, pausado = reduzMovimento.matches, sobPonteiro = false, comFoco = false;
        function mostrar(indice) {
            atual = (indice + slides.length) % slides.length;
            slides.forEach((slide, i) => { slide.classList.toggle("ativo", i === atual); slide.setAttribute("aria-hidden", String(i !== atual)); slide.inert = i !== atual; });
            pontos.forEach((ponto, i) => { ponto.classList.toggle("ativo", i === atual); ponto.setAttribute("aria-pressed", String(i === atual)); });
            contador.textContent = `${atual + 1} / ${slides.length}`;
        }
        function ritmo() {
            clearInterval(temporizador);
            if (!pausado && !sobPonteiro && !comFoco && !document.hidden && !reduzMovimento.matches) temporizador = setInterval(() => mostrar(atual + 1), 6500);
            pausa.setAttribute("aria-label", pausado ? "Retomar apresentação" : "Pausar apresentação");
            pausa.setAttribute("aria-pressed", String(pausado)); pausa.textContent = pausado ? "▷" : "Ⅱ";
        }
        document.querySelectorAll("[data-slide]").forEach(botao => botao.addEventListener("click", () => { mostrar(atual + (botao.dataset.slide === "proximo" ? 1 : -1)); ritmo(); }));
        pontos.forEach((ponto, i) => ponto.addEventListener("click", () => { mostrar(i); ritmo(); }));
        pausa.addEventListener("click", () => { pausado = !pausado; ritmo(); });
        const visual = document.querySelector(".hero-visual");
        visual.addEventListener("pointerenter", () => { sobPonteiro = true; ritmo(); });
        visual.addEventListener("pointerleave", () => { sobPonteiro = false; ritmo(); });
        visual.addEventListener("focusin", () => { comFoco = true; ritmo(); });
        visual.addEventListener("focusout", event => { if (!visual.contains(event.relatedTarget)) { comFoco = false; ritmo(); } });
        document.addEventListener("visibilitychange", ritmo);
        reduzMovimento.addEventListener("change", () => { pausado = reduzMovimento.matches; ritmo(); });
        mostrar(0); ritmo();
    }
    document.addEventListener("DOMContentLoaded", () => {
        if (document.body.dataset.pagina === "admin") document.getElementById("btnGerenciarProdutos")?.click();
    });
})();
