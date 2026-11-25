"use strict";

const estadoPedido = { Pendente:"Aguardando pagamento",Recusado:"Pagamento recusado",Pago:"Pagamento aprovado",EmPreparacao:"Em preparação",Pronto:"Pronto para retirada",Retirado:"Retirado",Cancelado:"Cancelado",Expirado:"Reserva expirada" };
const comprasParams = new URLSearchParams(location.search);
const paginaCompras = document.getElementById("areaCompras");
const usuarioCompras = JSON.parse(sessionStorage.getItem("usuarioLogado") || "null");
const equipeCompras = ["Funcionario","Administrador"].includes(usuarioCompras?.tipoUsuario);
const caminhoCompras = location.pathname.includes("/html/") ? "compras.html" : "html/compras.html";
const dataCompra = valor => valor ? new Date(valor).toLocaleString("pt-BR") : "—";
const valorCompra = valor => moedaUniduni.format(valor);

let painelCarrinho;
let origemPainelCarrinho;
let painelCarrinhoFechando = false;

function criarPainelCarrinho() {
    if (painelCarrinho) return;
    painelCarrinho = document.createElement("dialog");
    painelCarrinho.id = "painelCarrinho";
    painelCarrinho.className = "painel-carrinho";
    painelCarrinho.setAttribute("aria-labelledby", "tituloPainelCarrinho");
    painelCarrinho.setAttribute("aria-describedby", "resumoPainelCarrinho");
    painelCarrinho.innerHTML = `<header class="painel-carrinho-cabecalho"><div><h2 id="tituloPainelCarrinho">Meu carrinho</h2><p id="resumoPainelCarrinho" aria-live="polite">Confira suas escolhas.</p></div><button type="button" class="painel-carrinho-fechar" aria-label="Fechar carrinho" autofocus><svg class="icone" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.7" stroke-linecap="round" aria-hidden="true"><path d="m6 6 12 12M18 6 6 18"/></svg></button></header>
        <div id="itensPainelCarrinho" class="painel-carrinho-conteudo"></div>
        <footer class="painel-carrinho-rodape"><div id="totalPainelCarrinho" class="painel-carrinho-total" hidden><span>Total dos itens</span><strong></strong></div><p>Retirada na loja · pagamento simulado.</p><a class="botao-principal" href="${caminhoCompras}">Ir para o carrinho detalhado<svg class="icone" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.7" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="M4 12h15m-6-6 6 6-6 6"/></svg></a></footer>`;
    document.body.append(painelCarrinho);
    painelCarrinho.querySelector(".painel-carrinho-fechar").addEventListener("click", fecharPainelCarrinho);
    painelCarrinho.addEventListener("cancel", event => { event.preventDefault(); fecharPainelCarrinho(); });
    painelCarrinho.addEventListener("keydown", event => {
        if (event.key !== "Tab") return;
        const alvos = [...painelCarrinho.querySelectorAll('button:not(:disabled),a[href],input:not(:disabled),select:not(:disabled),textarea:not(:disabled),[tabindex="0"]')]
            .filter(el => el.getClientRects().length > 0);
        const primeiro = alvos[0], ultimo = alvos[alvos.length - 1];
        if (event.shiftKey && document.activeElement === primeiro) { event.preventDefault(); ultimo?.focus(); }
        else if (!event.shiftKey && document.activeElement === ultimo) { event.preventDefault(); primeiro?.focus(); }
    });
    painelCarrinho.addEventListener("click", event => {
        const r = painelCarrinho.getBoundingClientRect();
        if (event.target === painelCarrinho && (event.clientX < r.left || event.clientX > r.right || event.clientY < r.top || event.clientY > r.bottom)) fecharPainelCarrinho();
        if (event.target.closest("[data-recarregar-painel]")) carregarPainelCarrinho();
        if (event.target.closest("[data-entrar-painel]")) sessionStorage.setItem("retornoCompra", new URL(caminhoCompras, location.href).pathname);
    });
    painelCarrinho.addEventListener("close", () => {
        document.documentElement.classList.remove("painel-carrinho-aberto");
        painelCarrinho.classList.remove("fechando"); painelCarrinhoFechando = false;
        document.querySelectorAll('[aria-controls="painelCarrinho"]').forEach(el => el.setAttribute("aria-expanded", "false"));
        if (origemPainelCarrinho?.isConnected) origemPainelCarrinho.focus({ preventScroll: true });
    });
}
function fecharPainelCarrinho() {
    if (!painelCarrinho?.open || painelCarrinhoFechando) return;
    painelCarrinhoFechando = true;
    if (matchMedia("(prefers-reduced-motion: reduce)").matches) { painelCarrinho.close(); return; }
    painelCarrinho.classList.add("fechando");
    // O temporizador também garante fechamento se uma preferência de animação mudar.
    setTimeout(() => { if (painelCarrinho.open) painelCarrinho.close(); }, 240);
}
async function carregarPainelCarrinho() {
    const conteudo = painelCarrinho.querySelector("#itensPainelCarrinho");
    const resumo = painelCarrinho.querySelector("#resumoPainelCarrinho");
    const total = painelCarrinho.querySelector("#totalPainelCarrinho");
    total.hidden = true;
    if (!sessionStorage.getItem("uniduniToken")) {
        const login = location.pathname.includes("/html/") ? "login.html" : "html/login.html";
        resumo.textContent = "Suas escolhas ficam salvas na sua conta.";
        conteudo.innerHTML = `<div class="painel-carrinho-vazio"><h3>Entre para ver seu carrinho</h3><p>Acesse sua conta para conferir as peças que você adicionou.</p><a href="${login}" class="catalogo-secundario" data-entrar-painel>Entrar na minha conta</a></div>`;
        return;
    }
    conteudo.setAttribute("aria-busy", "true");
    conteudo.innerHTML = '<p class="painel-carrinho-carregando" role="status">Buscando suas peças…</p>';
    try {
        const c = await dadosCatalogo("/api/compras/carrinho");
        const quantidade = c.itens.reduce((s, i) => s + i.quantidade, 0);
        resumo.textContent = `${quantidade} ${quantidade === 1 ? "item adicionado" : "itens adicionados"}`;
        document.querySelectorAll("[data-contador-carrinho]").forEach(el => { el.textContent = quantidade; el.setAttribute("aria-label", `${quantidade} itens`); });
        total.querySelector("strong").textContent = valorCompra(c.total); total.hidden = false;
        const prefixo = location.pathname.includes("/html/") ? "../" : "";
        conteudo.innerHTML = c.itens.length ? `<ul class="painel-carrinho-lista">${c.itens.map(i => `<li><img src="${prefixo}images/${imagemSegura(i.imagem)}" alt="${e(i.nome)}"><div class="painel-carrinho-item"><h3>${e(i.nome)}</h3><p>${e(i.cor)} · Tamanho ${e(i.tamanho)}</p><p>${i.quantidade} ${i.quantidade === 1 ? "unidade" : "unidades"} × ${valorCompra(i.preco)}</p>${!i.ativo || i.quantidade > i.disponivel ? '<p class="painel-carrinho-alerta">Revise a disponibilidade no carrinho detalhado.</p>' : ""}<strong>${valorCompra(i.subtotal)}</strong></div></li>`).join("")}</ul>`
            : '<div class="painel-carrinho-vazio"><h3>Seu carrinho ainda está vazio</h3><p>Explore o catálogo e escolha a cor e o tamanho da sua próxima peça.</p></div>';
    } catch (erro) {
        resumo.textContent = "Não foi possível atualizar seu carrinho.";
        conteudo.innerHTML = `<div class="painel-carrinho-vazio"><p role="alert">${e(erro.message)}</p><button type="button" class="catalogo-secundario" data-recarregar-painel>Tentar novamente</button></div>`;
    } finally { conteudo.setAttribute("aria-busy", "false"); }
}
function abrirPainelCarrinho(origem) {
    criarPainelCarrinho();
    if (painelCarrinho.open) return;
    origemPainelCarrinho = origem;
    origem?.setAttribute("aria-expanded", "true");
    document.documentElement.classList.add("painel-carrinho-aberto");
    painelCarrinho.showModal();
    carregarPainelCarrinho();
}

function exigirContaCompra() {
    if (sessionStorage.getItem("uniduniToken")) return true;
    sessionStorage.setItem("retornoCompra", location.pathname + location.search);
    location.href = location.pathname.includes("/html/") ? "login.html" : "html/login.html";
    return false;
}
function operacaoCompra(chave) {
    const nome = `uniduni-operacao-${usuarioCompras?.id}-${chave}`;
    let id = sessionStorage.getItem(nome);
    if (!id) { id = crypto.randomUUID(); sessionStorage.setItem(nome,id); }
    return id;
}
function limparOperacaoCompra(chave) { sessionStorage.removeItem(`uniduni-operacao-${usuarioCompras?.id}-${chave}`); }
function avisoCompra(mensagem,erro=false) {
    const alvo=document.getElementById("comprasMensagem");
    if(alvo){alvo.textContent=mensagem;alvo.className=`catalogo-aviso${erro?" erro":""}`;if(erro)alvo.focus();}
    else notificar(mensagem,erro?"erro":"sucesso");
}
function telaCompra(html) {
    paginaCompras.innerHTML=`<p id="comprasMensagem" class="catalogo-aviso" role="status" tabindex="-1"></p>${html}`;
    const titulo=paginaCompras.querySelector("h1");
    if(titulo){document.title=`${titulo.textContent} — Uniduni`;titulo.tabIndex=-1;titulo.focus({preventScroll:true});}
}
async function atualizarContadorCarrinho() {
    if(!usuarioCompras)return;
    try {const c=await dadosCatalogo("/api/compras/carrinho");const n=c.itens.reduce((s,i)=>s+i.quantidade,0);
        document.querySelectorAll("[data-contador-carrinho]").forEach(el=>{el.textContent=n;el.setAttribute("aria-label",`${n} itens`);});
    }catch{ /* O fluxo principal mostra falhas ao abrir o carrinho. */ }
}
function linhaCompra(i,carrinho=false) {
    return `<article class="compra-item"><img src="../images/${imagemSegura(i.imagem)}" alt="${e(i.nome)}" loading="lazy"><div><h2>${e(i.nome)}</h2><p>${e(i.cor)} · ${e(i.tamanho)}</p><p>${valorCompra(carrinho?i.preco:i.precoUnitario)} por unidade</p>${carrinho&&!i.ativo?'<p class="erro">Produto indisponível. Remova-o do carrinho.</p>':""}</div><div class="compra-item-acoes">${carrinho?`<label for="qtd-${i.variacaoId}">Quantidade</label><input id="qtd-${i.variacaoId}" type="number" min="1" max="99" value="${i.quantidade}" data-quantidade-compra="${i.variacaoId}"><button class="link-remover" data-remover-compra="${i.variacaoId}">Remover<span class="somente-leitor"> ${e(i.nome)}</span></button><small>Disponíveis: ${i.disponivel}</small>`:`<span>${i.quantidade} ${i.quantidade===1?"unidade":"unidades"}</span>`}<strong>${valorCompra(i.subtotal)}</strong></div></article>`;
}
async function verCarrinho() {
    const c=await dadosCatalogo("/api/compras/carrinho");
    telaCompra(`<div class="compra-titulo"><div><p class="produto-marca">Seus pequenos achados</p><h1>Meu carrinho</h1></div><a class="catalogo-secundario" href="../index.html#catalogoTitulo">Continuar comprando</a></div>
        ${c.itens.length?`<div class="compra-layout"><div>${c.itens.map(i=>linhaCompra(i,true)).join("")}</div><aside class="compra-resumo"><h2>Resumo do pedido</h2><p>Retirada na loja <strong>Sem frete</strong></p><p class="compra-total">Total <strong>${valorCompra(c.total)}</strong></p><p>O estoque será reservado por 30 minutos ao finalizar. Preços e disponibilidade são conferidos novamente pelo servidor.</p><button class="botao-principal" id="finalizarCompra">Finalizar pedido</button><p class="nota-projeto">Loja fictícia · pagamento somente simulado.</p></aside></div>`:`<div class="catalogo-vazio"><h2>Seu carrinho está esperando uma escolha.</h2><p>Escolha uma peça, uma cor e um tamanho para começar.</p><a class="botao-principal" href="../index.html#catalogoTitulo">Explorar o catálogo</a></div>`}`);
    document.getElementById("finalizarCompra")?.addEventListener("click",event=>acaoCompra(event.currentTarget,async()=>{
        const p=await enviarCatalogo("/api/compras/pedidos","POST",{operacaoId:operacaoCompra("pedido")});
        limparOperacaoCompra("pedido");location.href=`compras.html?pedido=${p.id}`;
    }));
    paginaCompras.querySelectorAll("[data-quantidade-compra]").forEach(input=>input.addEventListener("change",()=>acaoCompra(input,async()=>{
        if(!input.checkValidity()){input.reportValidity();return;}
        await enviarCatalogo("/api/compras/carrinho","PUT",{variacaoId:Number(input.dataset.quantidadeCompra),quantidade:Number(input.value)});await verCarrinho();await atualizarContadorCarrinho();
    })));
    paginaCompras.querySelectorAll("[data-remover-compra]").forEach(btn=>btn.addEventListener("click",()=>acaoCompra(btn,async()=>{
        await enviarCatalogo("/api/compras/carrinho","PUT",{variacaoId:Number(btn.dataset.removerCompra),quantidade:0});await verCarrinho();await atualizarContadorCarrinho();
    })));
}
async function acaoCompra(botao,acao) {
    botao.disabled=true;botao.classList.add("is-loading");
    try {await acao();}catch(erro){avisoCompra(erro.message,true);}finally{botao.disabled=false;botao.classList.remove("is-loading");}
}
async function listarPedidos(equipe=false) {
    const pedidos=await dadosCatalogo(`/api/compras/pedidos${equipe?"?equipe=true":""}`);
    telaCompra(`<div class="compra-titulo"><div><p class="produto-marca">${equipe?"Espaço da equipe":"Minha conta"}</p><h1>${equipe?"Pedidos da loja":"Meus pedidos"}</h1><p>Últimos 100 pedidos · atualize para acompanhar as mudanças.</p></div><button class="catalogo-secundario" id="atualizarPedidos">Atualizar pedidos</button></div>
        <div class="pedidos-filtro"><label for="filtrarPedido">Filtrar por situação</label><select id="filtrarPedido"><option value="">Todas as situações</option>${Object.entries(estadoPedido).map(([k,v])=>`<option value="${k}">${v}</option>`).join("")}</select></div>
        <div id="listaPedidosCompra">${pedidos.length?pedidos.map(p=>`<article class="pedido-linha" data-status-pedido="${p.status}"><div><h2>Pedido #${p.id}</h2><p>${dataCompra(p.criadoEm)}${equipe?` · ${e(p.cliente)}`:""}</p></div><span class="pedido-status status-${p.status}">${estadoPedido[p.status]||e(p.status)}</span><strong>${valorCompra(p.total)}</strong><a class="catalogo-secundario" href="compras.html?pedido=${p.id}${equipe?"&visao=equipe":""}">Ver pedido #${p.id}</a></article>`).join(""):'<div class="catalogo-vazio"><h2>Nenhum pedido por aqui ainda.</h2><p>As compras finalizadas aparecerão nesta área.</p></div>'}</div><p id="filtroPedidoVazio" hidden>Nenhum pedido nesta situação.</p>`);
    document.getElementById("atualizarPedidos").onclick=event=>acaoCompra(event.currentTarget,()=>listarPedidos(equipe));
    document.getElementById("filtrarPedido").onchange=event=>{
        let n=0;paginaCompras.querySelectorAll("[data-status-pedido]").forEach(el=>{el.hidden=!!event.target.value&&el.dataset.statusPedido!==event.target.value;if(!el.hidden)n++;});document.getElementById("filtroPedidoVazio").hidden=n>0||!pedidos.length;
    };
}
function formularioPagamento(p) {
    return `<section class="compra-pagamento"><h2>Pagamento simulado</h2><p>Ambiente acadêmico. Nenhuma cobrança será feita. Não informe dados reais.</p><form id="formPagamentoCompra"><div class="catalogo-campos"><div class="form-group"><label for="metodoCompra">Forma de pagamento</label><select id="metodoCompra"><option value="Pix">Pix simulado</option><option value="Cartao">Cartão de teste</option></select></div><div class="form-group"><label for="resultadoCompra">Resultado da simulação</label><select id="resultadoCompra"><option value="Aprovado">Aprovar pagamento</option><option value="Recusado">Recusar pagamento</option><option value="Pendente">Deixar pendente</option></select></div></div><div id="cartaoCompra" hidden><label for="numeroCartaoTeste">Cartão fictício de demonstração</label><input id="numeroCartaoTeste" value="TESTE ···· 4242" readonly><p>Cartão de teste · validade 12/2099 · código fictício 123. Estes dados não são enviados nem armazenados como dados de cartão.</p></div><p id="pixCompra">O código de demonstração, sem validade bancária, aparece ao escolher um resultado pendente.</p><button class="botao-principal" type="submit">Simular pagamento de ${valorCompra(p.total)}</button></form></section>`;
}
async function verPedido(id) {
    const p=await dadosCatalogo(`/api/compras/pedidos/${id}`);
    const proprio=p.usuarioId===usuarioCompras?.id;
    const pendente=p.pagamentos.find(pg=>pg.status==="Pendente");
    const cancelavel=equipeCompras?!["Cancelado","Expirado","Retirado"].includes(p.status):["Pendente","Pago","Recusado"].includes(p.status);
    const etapas=["Pago","EmPreparacao","Pronto","Retirado"];
    const seguinte={Pago:"EmPreparacao",EmPreparacao:"Pronto",Pronto:"Retirado"}[p.status];
    telaCompra(`<div class="compra-titulo"><div><p class="produto-marca">${e(p.cliente||"Minha compra")}</p><h1>Pedido #${p.id}</h1><p>${dataCompra(p.criadoEm)}</p></div><span class="pedido-status status-${p.status}">${estadoPedido[p.status]}</span></div><div class="compra-acoes"><a class="catalogo-secundario" href="compras.html?visao=${comprasParams.get("visao")==="equipe"?"equipe":"pedidos"}">Voltar aos pedidos</a><button class="catalogo-secundario" id="atualizarPedidoCompra">Atualizar pedido</button></div>
        ${p.reservaAte?`<p class="reserva-aviso">Reserva até ${dataCompra(p.reservaAte)}. Após esse horário, as peças voltam ao estoque. Atualize para conferir a situação.</p>`:""}
        <ol class="pedido-etapas" aria-label="Andamento da retirada">${etapas.map((s,i)=>`<li class="${etapas.indexOf(p.status)>=i?"concluida":""}" ${p.status===s?'aria-current="step"':""}>${estadoPedido[s]}</li>`).join("")}</ol>
        <div class="compra-layout"><div>${p.itens.map(i=>linhaCompra(i)).join("")}</div><aside class="compra-resumo"><h2>Retirada na loja</h2><p>Av. Yojiro Takaoka, 3500 – Alphaville, Santana de Parnaíba – SP.</p><p>Seg. a sex.: 9h às 18h · sábado: 9h às 13h. Horário informativo; a demonstração funciona a qualquer momento.</p><p class="compra-total">Total <strong>${valorCompra(p.total)}</strong></p>${proprio&&["Pago","EmPreparacao","Pronto","Retirado"].includes(p.status)?`<p>Código de retirada</p><strong class="codigo-retirada">${e(p.codigoRetirada)}</strong><p>Apresente este código à equipe quando o pedido estiver pronto.</p>`:""}<p class="nota-projeto">Loja fictícia. Endereço da faculdade usado como referência acadêmica.</p></aside></div>
        ${proprio&&["Pendente","Recusado"].includes(p.status)&&!pendente?formularioPagamento(p):""}
        ${pendente&&proprio?`<section class="compra-pagamento"><h2>${pendente.metodo==="Pix"?"Pix":"Cartão"} simulado pendente</h2><p>Sem cobrança real. A reserva mantém seu prazo original.</p>${pendente.codigoPix?`<label for="codigoPixTeste">Código de demonstração — não é um Pix válido</label><textarea id="codigoPixTeste" readonly>${e(pendente.codigoPix)}</textarea>`:""}<div class="compra-acoes"><button class="botao-principal" data-resolver-compra="Aprovado" data-pagamento="${pendente.id}">Simular aprovação</button><button class="catalogo-secundario" data-resolver-compra="Recusado" data-pagamento="${pendente.id}">Simular recusa</button></div></section>`:""}
        ${equipeCompras&&seguinte?`<form id="formAndamentoCompra" class="compra-pagamento"><h2>Atendimento pela equipe</h2>${seguinte==="Retirado"?'<div class="form-group"><label for="codigoRetiradaCompra">Código apresentado pelo cliente</label><input id="codigoRetiradaCompra" maxlength="12" required autocomplete="off"></div>':""}<button class="botao-principal" type="submit">${{EmPreparacao:"Iniciar preparação",Pronto:"Marcar pronto para retirada",Retirado:"Confirmar retirada"}[seguinte]}</button></form>`:""}
        ${cancelavel?`<details class="compra-cancelamento"><summary>Cancelar pedido</summary><p>${p.pagoEm?"O pagamento será estornado na simulação e as peças retornarão ao estoque.":"Os itens ainda reservados serão liberados."}</p><form id="formCancelarCompra"><div class="form-group"><label for="motivoCancelarCompra">Motivo do cancelamento</label><input id="motivoCancelarCompra" minlength="5" maxlength="200" required></div><button class="catalogo-secundario" type="submit">Confirmar cancelamento</button></form></details>`:""}
        <section class="compra-historico"><h2>Tentativas de pagamento</h2>${p.pagamentos.length?`<div class="catalogo-tabela"><table class="admin-table"><thead><tr><th scope="col">Tentativa</th><th scope="col">Método</th><th scope="col">Resultado</th><th scope="col">Valor simulado</th><th scope="col">Atualização</th></tr></thead><tbody>${p.pagamentos.map(pg=>`<tr><td>#${pg.id}</td><td>${pg.metodo==="Cartao"?"Cartão":e(pg.metodo)}</td><td>${e(pg.status)}</td><td>${valorCompra(pg.valor)}</td><td>${dataCompra(pg.atualizadoEm)}</td></tr>`).join("")}</tbody></table></div>`:'<p>Nenhuma tentativa registrada.</p>'}<h2>Histórico do pedido</h2><ol class="eventos-compra">${p.eventos.map(ev=>`<li><time>${dataCompra(ev.criadoEm)}</time><p>${e(ev.descricao)}</p></li>`).join("")}</ol></section>`);
    document.getElementById("atualizarPedidoCompra").onclick=event=>acaoCompra(event.currentTarget,()=>verPedido(id));
    document.getElementById("metodoCompra")?.addEventListener("change",event=>{const cartao=event.target.value==="Cartao";document.getElementById("cartaoCompra").hidden=!cartao;document.getElementById("pixCompra").hidden=cartao;});
    document.getElementById("formPagamentoCompra")?.addEventListener("submit",event=>{
        event.preventDefault();const metodo=document.getElementById("metodoCompra").value,resultado=document.getElementById("resultadoCompra").value;
        const chave=`pagamento-${id}-${metodo}-${resultado}`;
        acaoCompra(event.submitter,async()=>{await enviarCatalogo(`/api/compras/pedidos/${id}/pagamentos`,"POST",{metodo,resultado,operacaoId:operacaoCompra(chave)});limparOperacaoCompra(chave);await verPedido(id);});
    });
    paginaCompras.querySelectorAll("[data-resolver-compra]").forEach(btn=>btn.onclick=()=>acaoCompra(btn,async()=>{await enviarCatalogo(`/api/compras/pedidos/${id}/pagamentos/${btn.dataset.pagamento}/resolver`,"POST",{resultado:btn.dataset.resolverCompra});await verPedido(id);}));
    document.getElementById("formCancelarCompra")?.addEventListener("submit",event=>{event.preventDefault();const motivo=document.getElementById("motivoCancelarCompra").value;acaoCompra(event.submitter,async()=>{
        if(!await confirmarAcao("O pedido será encerrado e os efeitos no estoque e no pagamento simulado serão registrados.","Cancelar este pedido?"))return;
        await enviarCatalogo(`/api/compras/pedidos/${id}/cancelar`,"POST",{motivo});await verPedido(id);
    });});
    document.getElementById("formAndamentoCompra")?.addEventListener("submit",async event=>{
        event.preventDefault();
        const botao=event.submitter;
        const codigo=document.getElementById("codigoRetiradaCompra")?.value.trim();
        if(seguinte==="Retirado" && !await confirmarAcao(
            `Pedido #${id}. Confirme que as peças estão sendo entregues à pessoa que apresentou o código.`,
            "Confirmar retirada?"
        )) return;
        acaoCompra(botao,async()=>{
            await enviarCatalogo(`/api/compras/pedidos/${id}/andamento`,"POST",{status:seguinte,codigo});
            await verPedido(id);
        });
    });
}
async function verResumoVendas(inicio="",fim="") {
    const params=new URLSearchParams();
    if(inicio)params.set("inicio",new Date(inicio+"T00:00:00").toISOString());
    if(fim){const final=new Date(fim+"T00:00:00");final.setDate(final.getDate()+1);params.set("fim",final.toISOString());}
    const resumo=await dadosCatalogo(`/api/compras/resumo?${params}`);
    telaCompra(`<div class="compra-titulo"><div><p class="produto-marca">Administrador</p><h1>Total vendido</h1><p>Somente pagamentos simulados aprovados, descontados os estornos. Datas no horário local.</p></div></div><form id="formResumoVendas" class="catalogo-campos"><div class="form-group"><label for="vendasInicio">De</label><input id="vendasInicio" type="date" value="${e(inicio)}"></div><div class="form-group"><label for="vendasFim">Até (inclusive)</label><input id="vendasFim" type="date" value="${e(fim)}"></div><button class="catalogo-botao" type="submit">Consultar período</button></form><section class="total-vendas"><h2>Total vendido na simulação</h2><strong>${valorCompra(resumo.totalVendido)}</strong><p>${resumo.quantidadeVendas} ${resumo.quantidadeVendas===1?"venda aprovada":"vendas aprovadas"} no período.</p></section>`);
    document.getElementById("formResumoVendas").onsubmit=event=>{event.preventDefault();acaoCompra(event.submitter,()=>verResumoVendas(document.getElementById("vendasInicio").value,document.getElementById("vendasFim").value));};
}
document.addEventListener("DOMContentLoaded",async()=>{
    const navegacao=document.querySelector(".compras-nav");
    if(navegacao&&equipeCompras){
        navegacao.insertAdjacentHTML("beforeend",`<a href="compras.html?visao=equipe">Pedidos da loja</a>${usuarioCompras.tipoUsuario==="Administrador"?'<a href="compras.html?visao=resumo">Total vendido</a>':""}`);
    }
    navegacao?.querySelectorAll("a").forEach(a=>{if(new URL(a.href).search===location.search)a.setAttribute("aria-current","page");});
    const area=document.getElementById("areaUsuario");
    if(area){
        criarPainelCarrinho();
        const botao=document.createElement("button");botao.type="button";botao.className="atalho-carrinho";botao.setAttribute("aria-label","Meu carrinho");botao.setAttribute("aria-haspopup","dialog");botao.setAttribute("aria-controls","painelCarrinho");botao.setAttribute("aria-expanded","false");
        botao.innerHTML='<svg class="icone" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.7" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="M3 3h2l3 12h11l2-9H6M9 20h.01M18 20h.01"/></svg><span data-contador-carrinho>0</span>';
        botao.addEventListener("click",()=>abrirPainelCarrinho(botao));area.before(botao);
    }
    const verCarrinhoProduto=document.getElementById("irCarrinhoProduto");
    if(verCarrinhoProduto){
        verCarrinhoProduto.setAttribute("aria-haspopup","dialog");verCarrinhoProduto.setAttribute("aria-controls","painelCarrinho");verCarrinhoProduto.setAttribute("aria-expanded","false");
        verCarrinhoProduto.addEventListener("click",event=>{if(event.ctrlKey||event.metaKey||event.shiftKey||event.altKey)return;event.preventDefault();abrirPainelCarrinho(verCarrinhoProduto);});
    }
    const dropdown=document.getElementById("dropdownUsuario");
    if(dropdown){const a=document.createElement("a");a.href=caminhoCompras+"?visao=pedidos";a.textContent="Meus pedidos";dropdown.insertBefore(a,document.getElementById("btnSair"));}
    const adminNav=document.querySelector(".admin-sidebar .admin-cards");
    if(adminNav&&equipeCompras){const links=document.createElement("div");links.className="admin-card";links.innerHTML=`<a class="admin-nav-botao" href="compras.html?visao=equipe">Pedidos e retirada</a>${usuarioCompras.tipoUsuario==="Administrador"?'<a class="admin-nav-botao" href="compras.html?visao=resumo">Total vendido</a>':""}`;adminNav.append(links);}
    const adicionar=document.getElementById("adicionarCarrinho");
    adicionar?.addEventListener("click",()=>{if(!exigirContaCompra())return;acaoCompra(adicionar,async()=>{
        const variacaoId=Number(document.getElementById("tamanhoProduto").value),quantidade=Number(document.getElementById("quantidadeProduto").value);
        const input=document.getElementById("quantidadeProduto");if(!input.checkValidity()){input.reportValidity();return;}
        const c=await dadosCatalogo("/api/compras/carrinho"),atual=c.itens.find(i=>i.variacaoId===variacaoId)?.quantidade||0;
        await enviarCatalogo("/api/compras/carrinho","PUT",{variacaoId,quantidade:atual+quantidade});await atualizarContadorCarrinho();notificar("Peça adicionada ao carrinho.");document.getElementById("irCarrinhoProduto").hidden=false;
    });});
    await atualizarContadorCarrinho();
    if(!paginaCompras||!exigirContaCompra())return;
    try {
        const visao=comprasParams.get("visao");
        if((visao==="equipe"&&!equipeCompras)||(visao==="resumo"&&usuarioCompras.tipoUsuario!=="Administrador"))throw new Error("Você não tem permissão para acessar esta área.");
        if(comprasParams.has("pedido"))await verPedido(Number(comprasParams.get("pedido")));
        else if(visao==="resumo")await verResumoVendas();
        else if(visao==="pedidos"||visao==="equipe")await listarPedidos(visao==="equipe");
        else await verCarrinho();
    }catch(erro){telaCompra('<h1>Não foi possível abrir esta área</h1><a class="catalogo-secundario" href="../index.html">Voltar para a loja</a>');avisoCompra(erro.message,true);}
});
