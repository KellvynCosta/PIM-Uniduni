# Uniduni Mobile

Aplicativo Android em Flutter: catálogo, busca por texto/categoria, detalhes de variações, login/logout e CRUD de produtos para Funcionário e Administrador na API existente. Em Minha conta → Gerenciar produtos, a equipe cadastra produto com uma variação inicial, consulta saldos, edita os dados, desativa e reativa. A exclusão é lógica e preserva o histórico. A edição não altera os saldos existentes; entradas e ajustes ficam em Estoque e movimentações, também disponíveis no site. Sessão mantida somente em memória.

Compras: seleção de cor/tamanho e quantidade, carrinho persistido por usuário, finalização com reserva, Pix/cartão simulados, resolução de tentativa pendente, consulta dos próprios pedidos, código de retirada e cancelamento antes da preparação com estorno simulado. Os identificadores das operações são preservados em memória após falha para permitir nova tentativa sem duplicação.

Equipe: Minha conta → Pedidos e retirada abre a lista compartilhada com o site, com busca por número/cliente e filtro de situação. Permite iniciar preparação, marcar pronto, conferir o código apresentado pelo comprador e registrar a retirada, ou cancelar até antes da retirada. O Administrador também acessa Total vendido, com datas locais inclusivas convertidas para o intervalo UTC da API, excluindo os pagamentos estornados. Calendários e componentes nativos estão em português.

Usuários: Minha conta → Gerenciar usuários é exclusivo do Administrador. Lista contas ativas, busca nome/e-mail e filtra perfil; permite cadastrar, editar dados/perfil e desativar com confirmação, preservando histórico. Nova senha na edição é opcional, exige confirmação e revoga as sessões da conta. Na própria conta, mantém o perfil de Administrador, impede desativação e pede novo login após redefinir a senha. Senhas não são retornadas nem exibidas na lista.

Conta: sem login, Minha conta → Criar minha conta cadastra Cliente, valida confirmação da senha e retorna ao login com o e-mail preenchido. Para qualquer perfil autenticado, Alterar minha senha exige a senha atual e a confirmação da nova senha. A troca revoga todas as sessões dessa conta no servidor e retorna ao login; falhas de validação mantêm o formulário e a sessão.

Estoque: Minha conta → Estoque e movimentações permite consultar saldos físicos, reservados, disponíveis e mínimos por cor/tamanho, filtrar estoque baixo e consultar até 100 movimentos recentes gerais ou por combinação. Entrada soma unidades; ajuste define o novo saldo físico. Exige justificativa e confirmação, preserva reservas, identifica conflitos de versão e reutiliza o identificador da operação em novas tentativas após falha de rede. Alterações usam a mesma API e banco do site; consulte novamente ou atualize a página para visualizar mudanças feitas em outra plataforma.

Na raiz do repositório, `./iniciar-mobile.ps1` conecta um Android autorizado por USB à API local, sem abrir o servidor para a rede. Exige Android SDK/Platform-Tools e API em execução na porta 5288. HTTP está habilitado somente no manifesto de debug; publicação deverá utilizar HTTPS.

Validação: `flutter analyze`, `flutter test` e `dart run tool/check_api.dart` (API ligada). A documentação acadêmica será preparada na etapa final.
