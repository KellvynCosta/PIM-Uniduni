"use strict";

const API_ORIGIN = ["5500", "5501"].includes(location.port) || location.protocol === "file:"
    ? "http://localhost:5288" : location.origin;

// Remove a identificação antiga: ela não comprova uma sessão autenticada.
localStorage.removeItem("usuarioLogado");
try { JSON.parse(sessionStorage.getItem("usuarioLogado")); }
catch { sessionStorage.removeItem("usuarioLogado"); }
if (!sessionStorage.getItem("uniduniToken")) sessionStorage.removeItem("usuarioLogado");

function escaparHtml(valor) {
    return String(valor ?? "").replace(/[&<>"']/g, char => ({
        "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;", "'": "&#39;"
    })[char]);
}

function imagemSegura(nome) {
    return encodeURIComponent(String(nome || "produto-padrao.svg"));
}

async function apiFetch(url, options = {}) {
    const destino = new URL(String(url).replace("http://localhost:5288", API_ORIGIN), API_ORIGIN);
    if (destino.origin !== API_ORIGIN) throw new Error("Endereço de API inválido.");
    const headers = new Headers(options.headers);
    const token = sessionStorage.getItem("uniduniToken");
    if (token) headers.set("Authorization", `Bearer ${token}`);
    const resposta = await fetch(destino, { ...options, headers });
    if (resposta.status === 401 && token) {
        sessionStorage.removeItem("uniduniToken");
        sessionStorage.removeItem("usuarioLogado");
        location.href = location.pathname.includes("/html/") ? "login.html" : "html/login.html";
    }
    return resposta;
}

async function erroDaApi(resposta) {
    const texto = await resposta.text();
    if (resposta.status === 429) return "Muitas tentativas. Aguarde um minuto e tente novamente.";
    try {
        const dados = JSON.parse(texto);
        if (dados.errors) return Object.values(dados.errors).flat().join(" ");
        return dados.mensagem || dados.title || texto;
    } catch { return texto || "Não foi possível concluir a operação."; }
}
