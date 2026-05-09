let listaProdutos = [];
let slideAtual = 0;
let intervaloCarrossel = null;
let animandoCarrossel = false;

async function carregarProdutos() {
    const container = document.getElementById("produtos");

    if (!container) {
        return;
    }

    try {
        const response = await fetch("http://localhost:5288/api/Produtos");
        const produtos = await response.json();

        listaProdutos = produtos;

        renderizarProdutos(listaProdutos);

    } catch (error) {
        console.error("Erro ao carregar produtos:", error);
    }
}

function renderizarProdutos(produtos) {
    const container = document.getElementById("produtos");

    if (!container) {
        return;
    }

    container.innerHTML = "";

    produtos.forEach(produto => {
        const card = document.createElement("div");
        card.className = "card";

        const imagemProduto = produto.imagem
            ? `images/${produto.imagem}`
            : "images/produto-padrao.jpg";

        card.innerHTML = `
            <img src="${imagemProduto}" alt="${produto.nome}">
            <h3>${produto.nome}</h3>
            <p>${produto.descricao}</p>
            <p class="preco">R$ ${produto.preco}</p>
            <button onclick="verDetalhes(${produto.id})">
                Ver detalhes
            </button>
        `;

        container.appendChild(card);
    });
}

function verDetalhes(id) {
    window.location.href = `html/produto.html?id=${id}`;
}

carregarProdutos();

/* CARROSSEL */

function configurarCarrosselInicial() {
    const slides = document.querySelectorAll(".carrossel-slide");
    const indicadores = document.querySelectorAll(".indicador");

    if (slides.length === 0) {
        return;
    }

    slides.forEach(slide => {
        slide.classList.remove(
            "ativo",
            "entrando-direita",
            "entrando-esquerda",
            "saindo-esquerda",
            "saindo-direita"
        );
    });

    indicadores.forEach(indicador => {
        indicador.classList.remove("ativo");
    });

    slides[slideAtual].classList.add("ativo");

    if (indicadores[slideAtual]) {
        indicadores[slideAtual].classList.add("ativo");
    }
}

function trocarSlide(novoIndice, direcao) {
    const slides = document.querySelectorAll(".carrossel-slide");
    const indicadores = document.querySelectorAll(".indicador");

    if (slides.length === 0 || animandoCarrossel) {
        return;
    }

    if (novoIndice >= slides.length) {
        novoIndice = 0;
    }

    if (novoIndice < 0) {
        novoIndice = slides.length - 1;
    }

    if (novoIndice === slideAtual) {
        return;
    }

    animandoCarrossel = true;

    const slideSaindo = slides[slideAtual];
    const slideEntrando = slides[novoIndice];

    slides.forEach(slide => {
        slide.classList.remove(
            "entrando-direita",
            "entrando-esquerda",
            "saindo-esquerda",
            "saindo-direita"
        );
    });

    if (direcao === "proximo") {
        slideSaindo.classList.add("saindo-esquerda");
        slideEntrando.classList.add("entrando-direita");
    } else {
        slideSaindo.classList.add("saindo-direita");
        slideEntrando.classList.add("entrando-esquerda");
    }

    slideEntrando.classList.add("ativo");

    indicadores.forEach(indicador => {
        indicador.classList.remove("ativo");
    });

    if (indicadores[novoIndice]) {
        indicadores[novoIndice].classList.add("ativo");
    }

    setTimeout(() => {
        slideSaindo.classList.remove(
            "ativo",
            "saindo-esquerda",
            "saindo-direita"
        );

        slideEntrando.classList.remove(
            "entrando-direita",
            "entrando-esquerda"
        );

        slideAtual = novoIndice;
        animandoCarrossel = false;
    }, 650);
}

function mudarSlide(direcao) {
    const novoIndice = slideAtual + direcao;

    if (direcao > 0) {
        trocarSlide(novoIndice, "proximo");
    } else {
        trocarSlide(novoIndice, "anterior");
    }

    reiniciarIntervaloCarrossel();
}

function irParaSlide(indice) {
    if (indice === slideAtual) {
        return;
    }

    const direcao = indice > slideAtual ? "proximo" : "anterior";

    trocarSlide(indice, direcao);
    reiniciarIntervaloCarrossel();
}

function iniciarCarrosselAutomatico() {
    const slides = document.querySelectorAll(".carrossel-slide");

    if (slides.length === 0) {
        return;
    }

    intervaloCarrossel = setInterval(() => {
        trocarSlide(slideAtual + 1, "proximo");
    }, 5000);
}

function reiniciarIntervaloCarrossel() {
    if (intervaloCarrossel) {
        clearInterval(intervaloCarrossel);
    }

    iniciarCarrosselAutomatico();
}

function rolarParaProdutos() {
    const produtos = document.getElementById("produtos");

    if (!produtos) {
        return;
    }

    produtos.scrollIntoView({
        behavior: "smooth",
        block: "start"
    });
}

configurarCarrosselInicial();
iniciarCarrosselAutomatico();

const barraPesquisa = document.getElementById("barraPesquisa");

if (barraPesquisa) {
    barraPesquisa.addEventListener("input", () => {
        const termo = barraPesquisa.value.toLowerCase();

        const produtosFiltrados = listaProdutos.filter(produto =>
            produto.nome.toLowerCase().includes(termo) ||
            produto.descricao.toLowerCase().includes(termo)
        );

        renderizarProdutos(produtosFiltrados);
    });
}

const formCadastro = document.getElementById("formCadastro");

if (formCadastro) {
    formCadastro.addEventListener("submit", async (event) => {
        event.preventDefault();

        const nome = document.getElementById("nome").value;
        const email = document.getElementById("email").value;
        const senha = document.getElementById("senha").value;
        const telefone = document.getElementById("telefone").value;

        const mensagem = document.getElementById("mensagemCadastro");

        const usuario = {
            nome,
            email,
            senha,
            telefone,
            tipoUsuario: "Cliente"
        };

        try {
            const resposta = await fetch("http://localhost:5288/api/Usuarios/cadastro", {
                method: "POST",
                headers: {
                    "Content-Type": "application/json"
                },
                body: JSON.stringify(usuario)
            });

            if (resposta.ok) {
                mensagem.style.color = "green";
                mensagem.textContent = "Cadastro realizado com sucesso!";

                formCadastro.reset();
            } else {
                const erro = await resposta.text();

                mensagem.style.color = "red";
                mensagem.textContent = erro;
            }

        } catch (error) {
            mensagem.style.color = "red";
            mensagem.textContent = "Erro ao conectar com o servidor.";
        }
    });
}

const formLogin = document.getElementById("formLogin");

if (formLogin) {
    formLogin.addEventListener("submit", async (event) => {
        event.preventDefault();

        const email = document.getElementById("emailLogin").value;
        const senha = document.getElementById("senhaLogin").value;

        const mensagem = document.getElementById("mensagemLogin");

        const login = {
            email,
            senha
        };

        try {
            const resposta = await fetch("http://localhost:5288/api/Usuarios/login", {
                method: "POST",
                headers: {
                    "Content-Type": "application/json"
                },
                body: JSON.stringify(login)
            });

            if (resposta.ok) {
                const usuario = await resposta.json();

                localStorage.setItem("usuarioLogado", JSON.stringify(usuario));

                mensagem.style.color = "green";
                mensagem.textContent = "Login realizado com sucesso!";

                setTimeout(() => {
                    window.location.href = "../index.html";
                }, 1500);
            } else {
                const erro = await resposta.text();

                mensagem.style.color = "red";
                mensagem.textContent = erro;
            }

        } catch (error) {
            mensagem.style.color = "red";
            mensagem.textContent = "Erro ao conectar com o servidor.";
        }
    });
}

const areaUsuario = document.getElementById("areaUsuario");

if (areaUsuario) {
    const usuarioLogado = JSON.parse(localStorage.getItem("usuarioLogado"));

    const estaEmPastaHtml = window.location.pathname.includes("/html/");
    const estaNaPaginaAdmin = window.location.pathname.includes("admin.html");

    const caminhoLogin = estaEmPastaHtml
        ? "login.html"
        : "html/login.html";

    const caminhoAdmin = estaEmPastaHtml
        ? "admin.html"
        : "html/admin.html";

    const textoBotaoAdmin = estaNaPaginaAdmin
        ? "Página Inicial"
        : "Painel Admin";

    const caminhoBotaoAdmin = estaNaPaginaAdmin
        ? "../index.html"
        : caminhoAdmin;

    if (usuarioLogado) {
        const inicial = usuarioLogado.nome.charAt(0).toUpperCase();

        const usuarioAdmin = usuarioLogado.tipoUsuario === "Admin";

        areaUsuario.innerHTML = `
            <div class="user-menu">
                <button id="avatarUsuario" class="avatar-usuario">
                    ${inicial}
                </button>

                <div id="dropdownUsuario" class="dropdown-usuario">
                    <strong>${usuarioLogado.nome}</strong>
                    <span>${usuarioLogado.email}</span>

                    ${usuarioAdmin ? `
                        <a href="${caminhoBotaoAdmin}" class="btn-admin">
                            ${textoBotaoAdmin}
                        </a>
                    ` : ""}

                    <button id="btnSair" class="btn-sair">
                        Sair
                    </button>
                </div>
            </div>
        `;

        const avatarUsuario = document.getElementById("avatarUsuario");
        const dropdownUsuario = document.getElementById("dropdownUsuario");
        const btnSair = document.getElementById("btnSair");

        avatarUsuario.addEventListener("click", () => {
            dropdownUsuario.classList.toggle("ativo");
        });

        btnSair.addEventListener("click", () => {
            localStorage.removeItem("usuarioLogado");
            window.location.reload();
        });

    } else {
        areaUsuario.innerHTML = `
            <a href="${caminhoLogin}">Login</a>
        `;
    }
}

async function carregarProdutoDetalhe() {
    const nomeProduto = document.getElementById("nomeProduto");

    if (!nomeProduto) {
        return;
    }

    const params = new URLSearchParams(window.location.search);
    const id = params.get("id");

    if (!id) {
        return;
    }

    try {
        const response = await fetch(`http://localhost:5288/api/Produtos/${id}`);
        const produto = await response.json();

        document.getElementById("nomeProduto").textContent = produto.nome;
        document.getElementById("descricaoProduto").textContent = produto.descricao;
        document.getElementById("precoProduto").textContent = `R$ ${produto.preco}`;
        document.getElementById("tamanhoProduto").textContent = produto.tamanho;
        document.getElementById("generoProduto").textContent = produto.genero;

        const imagemProduto = produto.imagem
            ? `../images/${produto.imagem}`
            : "../images/produto-padrao.jpg";

        document.getElementById("imagemProduto").src = imagemProduto;

    } catch (error) {
        console.error("Erro ao carregar produto:", error);
    }
}

carregarProdutoDetalhe();

const btnMostrarRedefinir = document.getElementById("btnMostrarRedefinir");
const formRedefinirSenha = document.getElementById("formRedefinirSenha");

if (btnMostrarRedefinir && formRedefinirSenha) {
    btnMostrarRedefinir.addEventListener("click", () => {
        formRedefinirSenha.classList.toggle("hidden");
    });
}

if (formRedefinirSenha) {
    formRedefinirSenha.addEventListener("submit", async (event) => {
        event.preventDefault();

        const email = document.getElementById("emailRedefinir").value;
        const novaSenha = document.getElementById("novaSenha").value;

        const mensagem = document.getElementById("mensagemRedefinir");

        const dados = {
            email,
            novaSenha
        };

        try {
            const resposta = await fetch("http://localhost:5288/api/Usuarios/redefinir-senha", {
                method: "POST",
                headers: {
                    "Content-Type": "application/json"
                },
                body: JSON.stringify(dados)
            });

            if (resposta.ok) {
                const texto = await resposta.text();

                mensagem.style.color = "green";
                mensagem.textContent = texto;

                formRedefinirSenha.reset();
            } else {
                const erro = await resposta.text();

                mensagem.style.color = "red";
                mensagem.textContent = erro;
            }

        } catch (error) {
            mensagem.style.color = "red";
            mensagem.textContent = "Erro ao conectar com o servidor.";
        }
    });
}

/* ADMIN */

function verificarAcessoAdmin() {
    const adminContainer = document.querySelector(".admin-container");

    if (!adminContainer) {
        return true;
    }

    const usuarioLogado = JSON.parse(localStorage.getItem("usuarioLogado"));

    if (!usuarioLogado || usuarioLogado.tipoUsuario !== "Admin") {
        adminContainer.innerHTML = `
            <section class="admin-header">
                <h1>Acesso negado</h1>
                <p>Você precisa estar logado como administrador para acessar esta página.</p>
            </section>
        `;

        return false;
    }

    return true;
}

function configurarPainelAdmin() {
    const btnGerenciarProdutos = document.getElementById("btnGerenciarProdutos");
    const btnGerenciarUsuarios = document.getElementById("btnGerenciarUsuarios");

    if (!btnGerenciarProdutos && !btnGerenciarUsuarios) {
        return;
    }

    const acessoPermitido = verificarAcessoAdmin();

    if (!acessoPermitido) {
        return;
    }

    if (btnGerenciarProdutos) {
        btnGerenciarProdutos.addEventListener("click", carregarProdutosAdmin);
    }

    if (btnGerenciarUsuarios) {
        btnGerenciarUsuarios.addEventListener("click", carregarUsuariosAdmin);
    }
}

async function carregarProdutosAdmin() {
    const areaAdminConteudo = document.getElementById("areaAdminConteudo");

    if (!areaAdminConteudo) {
        return;
    }

    try {
        const response = await fetch("http://localhost:5288/api/Produtos");
        const produtos = await response.json();

        areaAdminConteudo.innerHTML = `
            <div class="admin-section-header">
                <h2 class="admin-section-title">Produtos</h2>

                <button class="btn-novo-admin" onclick="abrirFormularioCadastrarProduto()">
                    Novo Produto
                </button>
            </div>
        `;

        if (produtos.length === 0) {
            areaAdminConteudo.innerHTML += `
                <p>Nenhum produto cadastrado.</p>
            `;

            return;
        }

        areaAdminConteudo.innerHTML += `
            <table class="admin-table">
                <thead>
                    <tr>
                        <th>ID</th>
                        <th>Nome</th>
                        <th>Preço</th>
                        <th>Estoque</th>
                        <th>Tamanho</th>
                        <th>Gênero</th>
                        <th>Ações</th>
                    </tr>
                </thead>

                <tbody>
                    ${produtos.map(produto => `
                        <tr>
                            <td>${produto.id}</td>
                            <td>${produto.nome}</td>
                            <td>R$ ${produto.preco}</td>
                            <td>${produto.estoque}</td>
                            <td>${produto.tamanho}</td>
                            <td>${produto.genero}</td>
                            <td>
                                <div class="admin-actions">
                                    <button class="btn-editar" onclick="abrirFormularioEditarProduto(${produto.id})">
                                        Editar
                                    </button>

                                    <button class="btn-excluir" onclick="excluirProdutoAdmin(${produto.id})">
                                        Excluir
                                    </button>
                                </div>
                            </td>
                        </tr>
                    `).join("")}
                </tbody>
            </table>
        `;

    } catch (error) {
        areaAdminConteudo.innerHTML = `
            <p>Erro ao carregar produtos.</p>
        `;

        console.error("Erro ao carregar produtos no admin:", error);
    }
}

function abrirFormularioCadastrarProduto() {
    const areaAdminConteudo = document.getElementById("areaAdminConteudo");

    if (!areaAdminConteudo) {
        return;
    }

    areaAdminConteudo.innerHTML = `
        <h2 class="admin-section-title">Cadastrar Produto</h2>

        <form id="formCadastrarProdutoAdmin" class="admin-form">
            <div class="form-group">
                <label for="cadastroProdutoNome">Nome</label>
                <input type="text" id="cadastroProdutoNome" required>
            </div>

            <div class="form-group">
                <label for="cadastroProdutoDescricao">Descrição</label>
                <input type="text" id="cadastroProdutoDescricao" required>
            </div>

            <div class="form-group">
                <label for="cadastroProdutoPreco">Preço</label>
                <input type="number" id="cadastroProdutoPreco" step="0.01" required>
            </div>

            <div class="form-group">
                <label for="cadastroProdutoEstoque">Estoque</label>
                <input type="number" id="cadastroProdutoEstoque" required>
            </div>

            <div class="form-group">
                <label for="cadastroProdutoTamanho">Tamanho</label>
                <input type="text" id="cadastroProdutoTamanho" placeholder="Ex: P, M, G">
            </div>

            <div class="form-group">
                <label for="cadastroProdutoGenero">Gênero</label>
                <select id="cadastroProdutoGenero" required>
                    <option value="Unissex">Unissex</option>
                    <option value="Masculino">Masculino</option>
                    <option value="Feminino">Feminino</option>
                </select>
            </div>

            <div class="form-group">
                <label for="cadastroProdutoImagem">Imagem</label>
                <input type="text" id="cadastroProdutoImagem" placeholder="Ex: body-azul.jpg">
            </div>

            <div class="form-group">
                <label for="cadastroProdutoCategoriaId">Categoria ID</label>
                <input type="number" id="cadastroProdutoCategoriaId" value="1" required>
            </div>

            <button type="submit" class="btn-salvar-admin">
                Cadastrar Produto
            </button>

            <button type="button" class="btn-cancelar-admin" onclick="carregarProdutosAdmin()">
                Cancelar
            </button>
        </form>
    `;

    const formCadastrarProdutoAdmin = document.getElementById("formCadastrarProdutoAdmin");

    formCadastrarProdutoAdmin.addEventListener("submit", cadastrarProdutoAdmin);
}

async function cadastrarProdutoAdmin(event) {
    event.preventDefault();

    const produto = {
        nome: document.getElementById("cadastroProdutoNome").value,
        descricao: document.getElementById("cadastroProdutoDescricao").value,
        preco: Number(document.getElementById("cadastroProdutoPreco").value),
        estoque: Number(document.getElementById("cadastroProdutoEstoque").value),
        tamanho: document.getElementById("cadastroProdutoTamanho").value,
        genero: document.getElementById("cadastroProdutoGenero").value,
        imagem: document.getElementById("cadastroProdutoImagem").value || "produto-padrao.jpg",
        categoriaId: Number(document.getElementById("cadastroProdutoCategoriaId").value)
    };

    try {
        const resposta = await fetch("http://localhost:5288/api/Produtos", {
            method: "POST",
            headers: {
                "Content-Type": "application/json"
            },
            body: JSON.stringify(produto)
        });

        if (resposta.ok) {
            alert("Produto cadastrado com sucesso.");
            carregarProdutosAdmin();
        } else {
            const erro = await resposta.text();
            alert(erro);
        }

    } catch (error) {
        console.error("Erro ao cadastrar produto:", error);
        alert("Erro ao conectar com o servidor.");
    }
}

async function abrirFormularioEditarProduto(id) {
    const areaAdminConteudo = document.getElementById("areaAdminConteudo");

    if (!areaAdminConteudo) {
        return;
    }

    try {
        const response = await fetch(`http://localhost:5288/api/Produtos/${id}`);

        if (!response.ok) {
            alert("Produto não encontrado.");
            return;
        }

        const produto = await response.json();

        areaAdminConteudo.innerHTML = `
            <h2 class="admin-section-title">Editar Produto</h2>

            <form id="formEditarProduto" class="admin-form">
                <input type="hidden" id="editarProdutoId" value="${produto.id}">

                <div class="form-group">
                    <label for="editarProdutoNome">Nome</label>
                    <input type="text" id="editarProdutoNome" value="${produto.nome}" required>
                </div>

                <div class="form-group">
                    <label for="editarProdutoDescricao">Descrição</label>
                    <input type="text" id="editarProdutoDescricao" value="${produto.descricao}" required>
                </div>

                <div class="form-group">
                    <label for="editarProdutoPreco">Preço</label>
                    <input type="number" id="editarProdutoPreco" value="${produto.preco}" step="0.01" required>
                </div>

                <div class="form-group">
                    <label for="editarProdutoEstoque">Estoque</label>
                    <input type="number" id="editarProdutoEstoque" value="${produto.estoque}" required>
                </div>

                <div class="form-group">
                    <label for="editarProdutoTamanho">Tamanho</label>
                    <input type="text" id="editarProdutoTamanho" value="${produto.tamanho || ""}">
                </div>

                <div class="form-group">
                    <label for="editarProdutoGenero">Gênero</label>
                    <select id="editarProdutoGenero" required>
                        <option value="Unissex" ${produto.genero === "Unissex" ? "selected" : ""}>Unissex</option>
                        <option value="Masculino" ${produto.genero === "Masculino" ? "selected" : ""}>Masculino</option>
                        <option value="Feminino" ${produto.genero === "Feminino" ? "selected" : ""}>Feminino</option>
                    </select>
                </div>

                <div class="form-group">
                    <label for="editarProdutoImagem">Imagem</label>
                    <input type="text" id="editarProdutoImagem" value="${produto.imagem || ""}">
                </div>

                <div class="form-group">
                    <label for="editarProdutoCategoriaId">Categoria ID</label>
                    <input type="number" id="editarProdutoCategoriaId" value="${produto.categoriaId}" required>
                </div>

                <button type="submit" class="btn-salvar-admin">
                    Salvar Alterações
                </button>

                <button type="button" class="btn-cancelar-admin" onclick="carregarProdutosAdmin()">
                    Cancelar
                </button>
            </form>
        `;

        const formEditarProduto = document.getElementById("formEditarProduto");

        formEditarProduto.addEventListener("submit", salvarEdicaoProduto);

    } catch (error) {
        console.error("Erro ao abrir edição do produto:", error);
        alert("Erro ao carregar produto.");
    }
}

async function salvarEdicaoProduto(event) {
    event.preventDefault();

    const id = document.getElementById("editarProdutoId").value;

    const produtoAtualizado = {
        id: Number(id),
        nome: document.getElementById("editarProdutoNome").value,
        descricao: document.getElementById("editarProdutoDescricao").value,
        preco: Number(document.getElementById("editarProdutoPreco").value),
        estoque: Number(document.getElementById("editarProdutoEstoque").value),
        tamanho: document.getElementById("editarProdutoTamanho").value,
        genero: document.getElementById("editarProdutoGenero").value,
        imagem: document.getElementById("editarProdutoImagem").value,
        categoriaId: Number(document.getElementById("editarProdutoCategoriaId").value)
    };

    try {
        const resposta = await fetch(`http://localhost:5288/api/Produtos/${id}`, {
            method: "PUT",
            headers: {
                "Content-Type": "application/json"
            },
            body: JSON.stringify(produtoAtualizado)
        });

        if (resposta.ok) {
            alert("Produto atualizado com sucesso.");
            carregarProdutosAdmin();
        } else {
            const erro = await resposta.text();
            alert(erro);
        }

    } catch (error) {
        console.error("Erro ao salvar produto:", error);
        alert("Erro ao conectar com o servidor.");
    }
}

async function excluirProdutoAdmin(id) {
    const confirmou = confirm("Tem certeza que deseja excluir este produto?");

    if (!confirmou) {
        return;
    }

    try {
        const resposta = await fetch(`http://localhost:5288/api/Produtos/${id}`, {
            method: "DELETE"
        });

        if (resposta.ok) {
            alert("Produto excluído com sucesso.");
            carregarProdutosAdmin();
        } else {
            const erro = await resposta.text();
            alert(erro);
        }

    } catch (error) {
        console.error("Erro ao excluir produto:", error);
        alert("Erro ao conectar com o servidor.");
    }
}

async function carregarUsuariosAdmin() {
    const areaAdminConteudo = document.getElementById("areaAdminConteudo");

    if (!areaAdminConteudo) {
        return;
    }

    try {
        const response = await fetch("http://localhost:5288/api/Usuarios");
        const usuarios = await response.json();

        areaAdminConteudo.innerHTML = `
            <div class="admin-section-header">
                <h2 class="admin-section-title">Usuários</h2>

                <button class="btn-novo-admin" onclick="abrirFormularioCadastrarUsuario()">
                    Novo Usuário
                </button>
            </div>
        `;

        if (usuarios.length === 0) {
            areaAdminConteudo.innerHTML += `
                <p>Nenhum usuário cadastrado.</p>
            `;

            return;
        }

        areaAdminConteudo.innerHTML += `
            <table class="admin-table">
                <thead>
                    <tr>
                        <th>ID</th>
                        <th>Nome</th>
                        <th>Email</th>
                        <th>Telefone</th>
                        <th>Tipo</th>
                        <th>Ações</th>
                    </tr>
                </thead>

                <tbody>
                    ${usuarios.map(usuario => `
                        <tr>
                            <td>${usuario.id}</td>
                            <td>${usuario.nome}</td>
                            <td>${usuario.email}</td>
                            <td>${usuario.telefone || "-"}</td>
                            <td>${usuario.tipoUsuario}</td>
                            <td>
                                <div class="admin-actions">
                                    <button class="btn-editar" onclick="abrirFormularioEditarUsuario(${usuario.id})">
                                        Editar
                                    </button>

                                    <button class="btn-excluir" onclick="excluirUsuarioAdmin(${usuario.id})">
                                        Excluir
                                    </button>
                                </div>
                            </td>
                        </tr>
                    `).join("")}
                </tbody>
            </table>
        `;

    } catch (error) {
        areaAdminConteudo.innerHTML = `
            <p>Erro ao carregar usuários.</p>
        `;

        console.error("Erro ao carregar usuários no admin:", error);
    }
}

function abrirFormularioCadastrarUsuario() {
    const areaAdminConteudo = document.getElementById("areaAdminConteudo");

    if (!areaAdminConteudo) {
        return;
    }

    areaAdminConteudo.innerHTML = `
        <h2 class="admin-section-title">Cadastrar Usuário</h2>

        <form id="formCadastrarUsuarioAdmin" class="admin-form">
            <div class="form-group">
                <label for="cadastroAdminNome">Nome</label>
                <input type="text" id="cadastroAdminNome" required>
            </div>

            <div class="form-group">
                <label for="cadastroAdminEmail">Email</label>
                <input type="email" id="cadastroAdminEmail" required>
            </div>

            <div class="form-group">
                <label for="cadastroAdminSenha">Senha</label>
                <input type="password" id="cadastroAdminSenha" required>
            </div>

            <div class="form-group">
                <label for="cadastroAdminTelefone">Telefone</label>
                <input type="text" id="cadastroAdminTelefone">
            </div>

            <div class="form-group">
                <label for="cadastroAdminTipo">Tipo de usuário</label>
                <select id="cadastroAdminTipo" required>
                    <option value="Cliente">Cliente</option>
                    <option value="Admin">Admin</option>
                </select>
            </div>

            <button type="submit" class="btn-salvar-admin">
                Cadastrar Usuário
            </button>

            <button type="button" class="btn-cancelar-admin" onclick="carregarUsuariosAdmin()">
                Cancelar
            </button>
        </form>
    `;

    const formCadastrarUsuarioAdmin = document.getElementById("formCadastrarUsuarioAdmin");

    formCadastrarUsuarioAdmin.addEventListener("submit", cadastrarUsuarioAdmin);
}

async function cadastrarUsuarioAdmin(event) {
    event.preventDefault();

    const usuario = {
        nome: document.getElementById("cadastroAdminNome").value,
        email: document.getElementById("cadastroAdminEmail").value,
        senha: document.getElementById("cadastroAdminSenha").value,
        telefone: document.getElementById("cadastroAdminTelefone").value,
        tipoUsuario: document.getElementById("cadastroAdminTipo").value
    };

    try {
        const resposta = await fetch("http://localhost:5288/api/Usuarios/cadastro", {
            method: "POST",
            headers: {
                "Content-Type": "application/json"
            },
            body: JSON.stringify(usuario)
        });

        if (resposta.ok) {
            alert("Usuário cadastrado com sucesso.");
            carregarUsuariosAdmin();
        } else {
            const erro = await resposta.text();
            alert(erro);
        }

    } catch (error) {
        console.error("Erro ao cadastrar usuário:", error);
        alert("Erro ao conectar com o servidor.");
    }
}

async function abrirFormularioEditarUsuario(id) {
    const areaAdminConteudo = document.getElementById("areaAdminConteudo");

    if (!areaAdminConteudo) {
        return;
    }

    try {
        const response = await fetch(`http://localhost:5288/api/Usuarios/${id}`);

        if (!response.ok) {
            alert("Usuário não encontrado.");
            return;
        }

        const usuario = await response.json();

        areaAdminConteudo.innerHTML = `
            <h2 class="admin-section-title">Editar Usuário</h2>

            <form id="formEditarUsuario" class="admin-form">
                <input type="hidden" id="editarUsuarioId" value="${usuario.id}">

                <div class="form-group">
                    <label for="editarUsuarioNome">Nome</label>
                    <input type="text" id="editarUsuarioNome" value="${usuario.nome}" required>
                </div>

                <div class="form-group">
                    <label for="editarUsuarioEmail">Email</label>
                    <input type="email" id="editarUsuarioEmail" value="${usuario.email}" required>
                </div>

                <div class="form-group">
                    <label for="editarUsuarioTelefone">Telefone</label>
                    <input type="text" id="editarUsuarioTelefone" value="${usuario.telefone || ""}">
                </div>

                <div class="form-group">
                    <label for="editarUsuarioTipo">Tipo de usuário</label>
                    <select id="editarUsuarioTipo" required>
                        <option value="Cliente" ${usuario.tipoUsuario === "Cliente" ? "selected" : ""}>Cliente</option>
                        <option value="Admin" ${usuario.tipoUsuario === "Admin" ? "selected" : ""}>Admin</option>
                    </select>
                </div>

                <div class="form-group">
                    <label for="editarUsuarioSenha">Nova senha</label>
                    <input type="password" id="editarUsuarioSenha" placeholder="Deixe em branco para manter a senha atual">
                </div>

                <button type="submit" class="btn-salvar-admin">
                    Salvar Alterações
                </button>

                <button type="button" class="btn-cancelar-admin" onclick="carregarUsuariosAdmin()">
                    Cancelar
                </button>
            </form>
        `;

        const formEditarUsuario = document.getElementById("formEditarUsuario");

        formEditarUsuario.addEventListener("submit", salvarEdicaoUsuario);

    } catch (error) {
        console.error("Erro ao abrir edição do usuário:", error);
        alert("Erro ao carregar usuário.");
    }
}

async function salvarEdicaoUsuario(event) {
    event.preventDefault();

    const id = document.getElementById("editarUsuarioId").value;

    const usuarioAtualizado = {
        id: Number(id),
        nome: document.getElementById("editarUsuarioNome").value,
        email: document.getElementById("editarUsuarioEmail").value,
        telefone: document.getElementById("editarUsuarioTelefone").value,
        tipoUsuario: document.getElementById("editarUsuarioTipo").value,
        senha: document.getElementById("editarUsuarioSenha").value
    };

    try {
        const resposta = await fetch(`http://localhost:5288/api/Usuarios/${id}`, {
            method: "PUT",
            headers: {
                "Content-Type": "application/json"
            },
            body: JSON.stringify(usuarioAtualizado)
        });

        if (resposta.ok) {
            alert("Usuário atualizado com sucesso.");

            const usuarioLogado = JSON.parse(localStorage.getItem("usuarioLogado"));

            if (usuarioLogado && usuarioLogado.id === Number(id)) {
                const usuarioAtualizadoResposta = await resposta.json();

                localStorage.setItem("usuarioLogado", JSON.stringify(usuarioAtualizadoResposta));
            }

            carregarUsuariosAdmin();
        } else {
            const erro = await resposta.text();
            alert(erro);
        }

    } catch (error) {
        console.error("Erro ao salvar usuário:", error);
        alert("Erro ao conectar com o servidor.");
    }
}

async function excluirUsuarioAdmin(id) {
    const usuarioLogado = JSON.parse(localStorage.getItem("usuarioLogado"));

    if (usuarioLogado && usuarioLogado.id === id) {
        alert("Você não pode excluir o próprio usuário logado.");
        return;
    }

    const confirmou = confirm("Tem certeza que deseja excluir este usuário?");

    if (!confirmou) {
        return;
    }

    try {
        const resposta = await fetch(`http://localhost:5288/api/Usuarios/${id}`, {
            method: "DELETE"
        });

        if (resposta.ok) {
            alert("Usuário excluído com sucesso.");
            carregarUsuariosAdmin();
        } else {
            const erro = await resposta.text();
            alert(erro);
        }

    } catch (error) {
        console.error("Erro ao excluir usuário:", error);
        alert("Erro ao conectar com o servidor.");
    }
}

configurarPainelAdmin();