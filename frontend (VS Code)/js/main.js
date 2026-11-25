const formCadastro = document.getElementById("formCadastro");

if (formCadastro) {
    formCadastro.addEventListener("submit", async (event) => {
        event.preventDefault();
        const botao = event.currentTarget.querySelector('[type="submit"]'); botao.disabled = true; botao.classList.add("is-loading");

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
            const resposta = await apiFetch("http://localhost:5288/api/Usuarios/cadastro", {
                method: "POST",
                headers: {
                    "Content-Type": "application/json"
                },
                body: JSON.stringify(usuario)
            });

            if (resposta.ok) {
                mensagem.dataset.tipo = "sucesso";
                mensagem.textContent = "Cadastro realizado com sucesso!";

                formCadastro.reset();
            } else {
                const erro = await erroDaApi(resposta);

                mensagem.dataset.tipo = "erro";
                mensagem.textContent = erro;
            }

        } catch (error) {
            mensagem.dataset.tipo = "erro";
            mensagem.textContent = "Não foi possível conectar. Confira a conexão e tente novamente.";
        } finally { botao.disabled = false; botao.classList.remove("is-loading"); }
    });
}

const formLogin = document.getElementById("formLogin");

if (formLogin) {
    formLogin.addEventListener("submit", async (event) => {
        event.preventDefault();
        const botao = event.currentTarget.querySelector('[type="submit"]'); botao.disabled = true; botao.classList.add("is-loading");

        const email = document.getElementById("emailLogin").value;
        const senha = document.getElementById("senhaLogin").value;

        const mensagem = document.getElementById("mensagemLogin");

        const login = {
            email,
            senha
        };

        try {
            const resposta = await apiFetch("http://localhost:5288/api/Usuarios/login", {
                method: "POST",
                headers: {
                    "Content-Type": "application/json"
                },
                body: JSON.stringify(login)
            });

            if (resposta.ok) {
                const sessao = await resposta.json();
                const usuario = sessao.usuario;
                sessionStorage.setItem("uniduniToken", sessao.token);
                sessionStorage.setItem("usuarioLogado", JSON.stringify(usuario));

                mensagem.dataset.tipo = "sucesso";
                mensagem.textContent = "Login realizado com sucesso!";

                setTimeout(() => {
                    const retorno = sessionStorage.getItem("retornoCompra");
                    sessionStorage.removeItem("retornoCompra");
                    window.location.href = retorno && /^\/html\/(produto|compras)\.html(?:\?|$)/.test(retorno) ? retorno : "../index.html";
                }, 1500);
            } else {
                const erro = await erroDaApi(resposta);

                mensagem.dataset.tipo = "erro";
                mensagem.textContent = erro;
            }

        } catch (error) {
            mensagem.dataset.tipo = "erro";
            mensagem.textContent = "Não foi possível conectar. Confira a conexão e tente novamente.";
        } finally { botao.disabled = false; botao.classList.remove("is-loading"); }
    });
}

const areaUsuario = document.getElementById("areaUsuario");

if (areaUsuario) {
    const usuarioLogado = JSON.parse(sessionStorage.getItem("usuarioLogado"));

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

        const usuarioAdmin = ["Administrador", "Funcionario"].includes(usuarioLogado.tipoUsuario);

        areaUsuario.innerHTML = `
            <div class="user-menu">
                <button id="avatarUsuario" class="avatar-usuario" aria-label="Abrir minha conta" aria-expanded="false" aria-controls="dropdownUsuario">
                    ${escaparHtml(inicial)}
                </button>

                <div id="dropdownUsuario" class="dropdown-usuario">
                    <strong>${escaparHtml(usuarioLogado.nome)}</strong>
                    <span>${escaparHtml(usuarioLogado.email)}</span>

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
            const aberto = dropdownUsuario.classList.toggle("ativo");
            avatarUsuario.setAttribute("aria-expanded", String(aberto));
        });

        btnSair.addEventListener("click", async () => {
            try { await apiFetch("/api/Usuarios/logout", { method: "POST" }); }
            finally {
                sessionStorage.removeItem("uniduniToken");
                sessionStorage.removeItem("usuarioLogado");
                window.location.href = estaEmPastaHtml ? "../index.html" : "index.html";
            }
        });

    } else {
        areaUsuario.innerHTML = `
            <a href="${caminhoLogin}">Entrar</a>
        `;
    }
}

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
            const resposta = await apiFetch("http://localhost:5288/api/Usuarios/redefinir-senha", {
                method: "POST",
                headers: {
                    "Content-Type": "application/json"
                },
                body: JSON.stringify(dados)
            });

            if (resposta.ok) {
                const texto = await resposta.text();

                mensagem.dataset.tipo = "sucesso";
                mensagem.textContent = texto;

                formRedefinirSenha.reset();
            } else {
                const erro = await erroDaApi(resposta);

                mensagem.dataset.tipo = "erro";
                mensagem.textContent = erro;
            }

        } catch (error) {
            mensagem.dataset.tipo = "erro";
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

    const usuarioLogado = JSON.parse(sessionStorage.getItem("usuarioLogado"));

    if (!usuarioLogado || !["Administrador", "Funcionario"].includes(usuarioLogado.tipoUsuario)) {
        adminContainer.classList.add("sem-acesso");
        adminContainer.innerHTML = `
            <section class="admin-header">
                <h1>Acesso negado</h1>
                <p>Entre com uma conta de funcionário ou administrador para acessar o espaço da equipe.</p><a class="catalogo-botao" href="login.html">Entrar na minha conta</a><p></p>
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
        const usuario = JSON.parse(sessionStorage.getItem("usuarioLogado"));
        if (usuario?.tipoUsuario === "Administrador") {
            btnGerenciarUsuarios.addEventListener("click", carregarUsuariosAdmin);
        } else { btnGerenciarUsuarios.closest(".admin-card").hidden = true; }
    }
}

async function carregarUsuariosAdmin() {
    const areaAdminConteudo = document.getElementById("areaAdminConteudo");

    if (!areaAdminConteudo) {
        return;
    }

    try {
        const response = await apiFetch("http://localhost:5288/api/Usuarios");
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
            <div class="catalogo-tabela"><table class="admin-table">
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
                            <td>${escaparHtml(usuario.nome)}</td>
                            <td>${escaparHtml(usuario.email)}</td>
                            <td>${escaparHtml(usuario.telefone || "-")}</td>
                            <td>${escaparHtml(usuario.tipoUsuario)}</td>
                            <td>
                                <div class="admin-actions">
                                    <button class="btn-editar" onclick="abrirFormularioEditarUsuario(${usuario.id})">
                                        Editar
                                    </button>

                                    <button class="btn-excluir" onclick="excluirUsuarioAdmin(${usuario.id})">
                                        Desativar
                                    </button>
                                </div>
                            </td>
                        </tr>
                    `).join("")}
                </tbody>
            </table></div>
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
                <input type="password" id="cadastroAdminSenha" minlength="8" maxlength="128" required>
            </div>

            <div class="form-group">
                <label for="cadastroAdminTelefone">Telefone</label>
                <input type="text" id="cadastroAdminTelefone">
            </div>

            <div class="form-group">
                <label for="cadastroAdminTipo">Tipo de usuário</label>
                <select id="cadastroAdminTipo" required>
                    <option value="Cliente">Cliente</option>
                    <option value="Funcionario">Funcionário</option>
                    <option value="Administrador">Administrador</option>
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
        const resposta = await apiFetch("http://localhost:5288/api/Usuarios", {
            method: "POST",
            headers: {
                "Content-Type": "application/json"
            },
            body: JSON.stringify(usuario)
        });

        if (resposta.ok) {
            notificar("Usuário cadastrado com sucesso.");
            carregarUsuariosAdmin();
        } else {
            const erro = await erroDaApi(resposta);
            notificar(erro, "erro");
        }

    } catch (error) {
        console.error("Erro ao cadastrar usuário:", error);
        notificar("Erro ao conectar com o servidor.");
    }
}

async function abrirFormularioEditarUsuario(id) {
    const areaAdminConteudo = document.getElementById("areaAdminConteudo");

    if (!areaAdminConteudo) {
        return;
    }

    try {
        const response = await apiFetch(`http://localhost:5288/api/Usuarios/${id}`);

        if (!response.ok) {
            notificar("Usuário não encontrado.");
            return;
        }

        const usuario = await response.json();

        areaAdminConteudo.innerHTML = `
            <h2 class="admin-section-title">Editar Usuário</h2>

            <form id="formEditarUsuario" class="admin-form">
                <input type="hidden" id="editarUsuarioId" value="${usuario.id}">

                <div class="form-group">
                    <label for="editarUsuarioNome">Nome</label>
                    <input type="text" id="editarUsuarioNome" value="${escaparHtml(usuario.nome)}" required>
                </div>

                <div class="form-group">
                    <label for="editarUsuarioEmail">Email</label>
                    <input type="email" id="editarUsuarioEmail" value="${escaparHtml(usuario.email)}" required>
                </div>

                <div class="form-group">
                    <label for="editarUsuarioTelefone">Telefone</label>
                    <input type="text" id="editarUsuarioTelefone" value="${escaparHtml(usuario.telefone || "")}">
                </div>

                <div class="form-group">
                    <label for="editarUsuarioTipo">Tipo de usuário</label>
                    <select id="editarUsuarioTipo" required>
                        <option value="Cliente" ${usuario.tipoUsuario === "Cliente" ? "selected" : ""}>Cliente</option>
                        <option value="Funcionario" ${usuario.tipoUsuario === "Funcionario" ? "selected" : ""}>Funcionário</option>
                        <option value="Administrador" ${usuario.tipoUsuario === "Administrador" ? "selected" : ""}>Administrador</option>
                    </select>
                </div>

                <div class="form-group">
                    <label for="editarUsuarioSenha">Nova senha</label>
                    <input type="password" id="editarUsuarioSenha" minlength="8" maxlength="128" placeholder="Deixe em branco para manter a senha atual">
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
        notificar("Erro ao carregar usuário.");
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
        senha: document.getElementById("editarUsuarioSenha").value || null
    };

    try {
        const resposta = await apiFetch(`http://localhost:5288/api/Usuarios/${id}`, {
            method: "PUT",
            headers: {
                "Content-Type": "application/json"
            },
            body: JSON.stringify(usuarioAtualizado)
        });

        if (resposta.ok) {
            notificar("Usuário atualizado com sucesso.");

            const usuarioLogado = JSON.parse(sessionStorage.getItem("usuarioLogado"));

            if (usuarioLogado && usuarioLogado.id === Number(id)) {
                const usuarioAtualizadoResposta = await resposta.json();

                sessionStorage.setItem("usuarioLogado", JSON.stringify(usuarioAtualizadoResposta));
            }

            carregarUsuariosAdmin();
        } else {
            const erro = await erroDaApi(resposta);
            notificar(erro, "erro");
        }

    } catch (error) {
        console.error("Erro ao salvar usuário:", error);
        notificar("Erro ao conectar com o servidor.");
    }
}

async function excluirUsuarioAdmin(id) {
    const usuarioLogado = JSON.parse(sessionStorage.getItem("usuarioLogado"));

    if (usuarioLogado && usuarioLogado.id === id) {
        notificar("Você não pode desativar o próprio usuário logado.");
        return;
    }

    const confirmou = await confirmarAcao("Tem certeza que deseja desativar este usuário? Seu histórico será preservado.");

    if (!confirmou) {
        return;
    }

    try {
        const resposta = await apiFetch(`http://localhost:5288/api/Usuarios/${id}`, {
            method: "DELETE"
        });

        if (resposta.ok) {
            notificar("Usuário desativado com sucesso.");
            carregarUsuariosAdmin();
        } else {
            const erro = await erroDaApi(resposta);
            notificar(erro, "erro");
        }

    } catch (error) {
        console.error("Erro ao excluir usuário:", error);
        notificar("Erro ao conectar com o servidor.");
    }
}

configurarPainelAdmin();
