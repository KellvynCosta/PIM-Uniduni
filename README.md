# PIM-Uniduni

# Realização do Projeto Universitário

## PIM IV — execução web

O projeto usa ASP.NET Core (.NET 10), SQL Server e frontend HTML/CSS/JavaScript. O banco é administrado pelo SSMS. Flutter será desenvolvido depois da plataforma web.

### Primeira configuração

1. No SSMS, conecte à instância usada pela API e abra o banco `uniduni`.
2. Execute `banco (SSMS)/migracoes/001_autenticacao.sql`. O script acrescenta sessões e desativação de usuários e normaliza os perfis, preservando os registros. Não execute o script antigo `uniduni.sql` sobre o banco em uso: ele remove o banco.
   Em seguida, execute `banco (SSMS)/migracoes/002_catalogo_estoque.sql` para acrescentar variações, histórico, a procedure de movimentação e o trigger do saldo agregado.
   Depois, execute `banco (SSMS)/migracoes/003_compras.sql` para carrinho, pedidos, reservas, pagamentos simulados e retirada. As três migrações já foram aplicadas nesta máquina.
3. Confira a conexão `DefaultConnection` no `appsettings.json` da API. Na máquina atual ela usa `localhost`, banco `uniduni` e autenticação integrada do Windows.
4. Na raiz do repositório, execute uma vez para converter as senhas existentes em hashes, mantendo as mesmas senhas de acesso:

```powershell
dotnet run --project "backend (Visual Studio)/Uniduni.API/Uniduni.API/Uniduni.API.csproj" -- --migrar-senhas
```

A migração SQL e a conversão de senhas já foram aplicadas nesta máquina em 19/10/2026. Em outra cópia do banco, repita a configuração. A conversão pode ser executada novamente sem reprocessar hashes existentes.

A migração `002_catalogo_estoque.sql` foi aplicada em 20/10/2026 e reaplicada para conferir que não duplica registros. Os três produtos existentes foram mantidos, com saldos de 10, 8 e 6 unidades. As cores explícitas nos nomes foram aproveitadas; a cor do sapatinho ficou como “Não informada” para a equipe revisar. Não foram inventadas medidas para os produtos antigos.

### Abrir a plataforma

No Visual Studio, abra `backend (Visual Studio)/Uniduni.API/Uniduni.API.slnx` e execute o perfil `http`. Alternativamente, na raiz do repositório:

```powershell
dotnet run --project "backend (Visual Studio)/Uniduni.API/Uniduni.API/Uniduni.API.csproj" --launch-profile http
```

Acesse [Uniduni local](http://localhost:5288). A própria API serve o site, sem necessidade de Live Server. O Swagger fica em [documentação local da API](http://localhost:5288/swagger) durante o desenvolvimento. Se usar Live Server, os endereços permitidos são `http://localhost:5500` e `http://127.0.0.1:5500`.

As contas existentes continuam com as mesmas senhas. O perfil antigo `Admin` foi padronizado como `Administrador`. Novos cadastros públicos sempre criam clientes; contas internas são criadas pelo Administrador. As novas senhas exigem pelo menos oito caracteres.

### Autenticação implementada

- Sessão aleatória com validade de oito horas; apenas o hash do token fica no banco.
- Site mantém a sessão na aba do navegador e envia o token à API.
- Sair da conta revoga a sessão no servidor.
- Alterar senha revoga as sessões da conta. A alteração pelo próprio usuário exige a senha atual; o Administrador também pode redefinir pelo gerenciamento de usuários.
- Recuperação apenas por email foi desativada. Nesta etapa, a recuperação é feita pelo Administrador.
- Desativar uma conta preserva o registro e seu histórico.
- Esta execução HTTP destina-se ao desenvolvimento local. Uma implantação deverá configurar HTTPS e a publicação dos arquivos estáticos.

### Verificações automatizadas

Com o banco configurado, execute na raiz:

```powershell
dotnet run --project "tests/Uniduni.Integration/Uniduni.Integration.csproj"
node --test tests/web-auth.test.cjs
```

Os testes de integração iniciam uma API temporária em `127.0.0.1:5291`, usam o banco configurado e criam contas com identificadores exclusivos para os testes. Ao terminar, encerram essa API e removem somente as contas, sessões, produtos, pedidos e pagamentos criados pelos próprios testes. Não devem ser executados contra um banco de produção.

Na validação de 19/10/2026 passaram 45 verificações de integração e 5 testes da comunicação web. A compilação terminou sem erros ou avisos. Permaneceram as 2 contas e os 3 produtos existentes, com zero senhas legadas sem hash.

Em 20/10/2026, a suíte ampliada passou em 92 verificações de integração e nos 5 testes da comunicação web. Também foram testados no navegador: login, cadastro de produto, inclusão de variação, entrada, ajuste, alerta, histórico e filtros combinados por cor e tamanho. Os registros temporários foram removidos. A compilação terminou sem erros ou avisos.

### Catálogo e estoque

- O catálogo público filtra por busca, categoria, cor, tamanho e disponibilidade. Cor e tamanho precisam existir na mesma variação.
- O detalhe mostra seletores de cor/tamanho, disponibilidade da combinação e o guia de medidas cadastrado pela equipe.
- No painel, abra **Gerenciar produtos e estoque**. Cadastre um produto com sua primeira variação ou abra **Gerenciar** em um produto existente.
- **Adicionar variação** cria uma combinação de cor e tamanho com saldo inicial e limite para alerta. Não é permitido duplicar a combinação no mesmo produto, mesmo quando a anterior está inativa.
- **Movimentar → Entrada de mercadorias** soma a quantidade informada ao saldo atual.
- **Movimentar → Ajustar saldo físico** substitui o saldo pela quantidade contada. Exige justificativa e não permite saldo negativo ou menor que as unidades reservadas.
- **Editar** na variação permite revisar cor, tamanho, limite e situação. As quantidades devem ser alteradas pela movimentação, mantendo a rastreabilidade.
- O histórico registra responsável, justificativa, quantidade alterada e saldos anterior e posterior. A tela mostra as últimas 50 movimentações do produto.
- A visibilidade do produto e a situação das variações podem ser desativadas, preservando os dados. Produtos/variações com reserva não podem ser desativados.
- O nome da imagem corresponde a um arquivo existente em `frontend (VS Code)/images`. Upload de arquivos não faz parte desta entrega; imagens ausentes usam uma ilustração de fallback.

No SQL Server, `ProdutoVariacoes.Estoque` representa o saldo físico e `Reservado` as unidades comprometidas. A disponibilidade é a diferença entre esses valores. O trigger `trg_Variacoes_TotalProduto` mantém `Produtos.Estoque` como soma física das variações ativas, para compatibilidade com o cadastro anterior. Não altere a coluna legada para tentar movimentar estoque: use a interface ou a procedure `usp_MovimentarEstoque`.

A procedure registra a alteração e seu histórico na mesma transação. Cada operação tem um identificador para impedir duplicação em novas tentativas. Uma versão do saldo também impede que uma tela desatualizada sobrescreva outra movimentação.

O fluxo comercial agora utiliza as reservas: finalizar pedido reserva as unidades; aprovação baixa saldo físico e reservado; recusa, cancelamento pendente e expiração liberam a reserva. O cancelamento de uma venda aprovada registra estorno e devolve o saldo físico uma única vez. O histórico mostra os saldos físico e reservado, antes e depois.

Evidências visuais dos testes locais estão em `output/qa/catalogo-web.png` e `output/qa/estoque-web.png`. A imagem de estoque utiliza dados temporários de validação, já removidos do banco.

### Identidade e interface — 20/10/2026

As seis páginas receberam o mesmo sistema visual: rosa, lilás, azul e turquesa, fonte Nunito local, logo original vetorial, navegação e formulários redesenhados. A página inicial inclui carrossel com pausa, atalhos de categorias, filtros recolhíveis, checkbox personalizado e ordenação por nome/preço. Conta, administração, tabelas, notificações e confirmações acompanham essa linguagem. O movimento respeita a preferência por animações reduzidas. O VLibras usa apenas seu botão nativo, sem a imagem adicional que duplicava o acesso.

Os arquivos da marca estão em `output/brand`: SVG e PNG transparente, símbolo isolado e versões clara e monocromática. O conceito e a paleta estão em `docs/identidade-visual-uniduni.md`.

Verificação desta entrega: seis páginas inspecionadas no navegador de desktop; filtros rápidos, ordenação, disponibilidade, guia de medidas, mostrar senha, login, menu da conta, painel, formulário de produto e cancelamento da confirmação de desativação conferidos. As 92 verificações integradas e os cinco testes da comunicação web passaram novamente. Os arquivos locais e IDs das seis páginas e os SVGs foram validados. Evidências em `output/qa/redesign-*.png`. A folha de estilos inclui adaptações para telas estreitas; a conferência em aparelho Android permanece pendente. Os registros temporários foram removidos após o teste.

### Andamento

Entregas concluídas: autenticação e permissões; catálogo com variações e filtros; gestão de entradas, ajustes, histórico e alertas de estoque; reinvenção visual e logo; carrinho, pedidos, reserva e expiração, pagamentos Pix/cartão simulados, cancelamento com estorno, preparação e retirada por código e total vendido exclusivo do Administrador.

Em 20/10/2026, a suíte ampliada passou em **203 verificações de integração** e cinco testes de comunicação web. A compilação terminou sem erros ou avisos. A jornada foi conferida no navegador, incluindo estorno e restauração dos saldos. Os dados temporários foram removidos. A API atualizada permanece disponível no endereço local habitual.

Para experimentar: entre, escolha cor/tamanho/quantidade no produto, adicione ao carrinho e finalize. No pedido, selecione Pix ou cartão de teste e o resultado desejado. Na conta, abra **Meus pedidos**. No painel interno, use **Pedidos e retirada**; o Administrador também encontra **Total vendido**. Todos os pagamentos são fictícios. Instruções, regras, contratos e limites desta entrega estão em `docs/compras-pedidos-pagamentos.md`.

Revisão web de 20/10/2026: os três perfis foram conferidos no navegador; passaram novamente 203 verificações de integração e cinco testes de comunicação web. A leitura do catálogo no celular e a adaptação do carrinho ao tablet foram ajustadas. Resultados, evidências e limites estão em [docs/revisao-final-web.md](docs/revisao-final-web.md); o ensaio da apresentação está em [docs/roteiro-demonstracao-web.md](docs/roteiro-demonstracao-web.md).

Próximas etapas: ensaio e acessibilidade em aparelho físico, documentação técnica e acadêmica, e desenvolvimento Flutter após a validação web. Planos de nuvem e DevOps ainda não representam uma implantação concluída.

Consulte `docs/escopo-pim-iv.md` e `docs/plano-implementacao-pim-iv.md` para as decisões e próximas entregas.
