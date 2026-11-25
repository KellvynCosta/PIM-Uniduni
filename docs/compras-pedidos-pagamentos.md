# Compras, pagamentos simulados e retirada

Entrega de 20/10/2026. Site e API compartilham as mesmas regras, preparadas para consumo posterior pelo Flutter. Todas as cobranças, códigos Pix e estornos desta entrega são fictícios.

## Como demonstrar no site

1. Entre com uma conta existente ou cadastre um Cliente. Na página de produto, escolha cor, tamanho e quantidade e use **Adicionar ao carrinho**. Se ainda não estiver autenticado, o login retorna à peça escolhida; adicione-a após entrar.
2. Abra o ícone do carrinho para visualizar o painel lateral: itens em lista, cor, tamanho, quantidade, subtotais e total. O botão **Ir para o carrinho detalhado** abre a página de edição, onde é possível alterar quantidades ou remover itens. Adicionar ao carrinho ou abrir a prévia não reserva estoque.
3. **Finalizar pedido** confere preços e disponibilidade no servidor, preserva os dados dos itens e reserva as unidades por 30 minutos. O carrinho é esvaziado somente se todos os itens forem reservados.
4. Escolha **Pix simulado** ou **Cartão de teste**, e o resultado **Aprovar**, **Recusar** ou **Deixar pendente**. O cartão usa uma identificação fictícia somente na tela; não recebe nem armazena número, validade ou código de segurança reais. O Pix pendente exibe um identificador textual que não é um Pix bancário.
5. Uma tentativa pendente pode ser aprovada ou recusada pelos controles de simulação do próprio comprador. Ela mantém o prazo original da reserva. Uma recusa libera as unidades; uma nova tentativa precisa reservá-las novamente, sujeita ao estoque disponível.
6. A aprovação transforma a reserva em venda: diminui saldo físico e reservado uma vez. O cliente consulta o código em **Meus pedidos**.
7. Funcionário ou Administrador abre **Pedidos e retirada** no painel, ou **Pedidos da loja** na área de compras. Pode filtrar as situações, iniciar preparação e marcar pronto. A retirada exige o código apresentado pelo cliente e registra operador e instante. Não existe bloqueio por horário de atendimento.
8. O Cliente pode cancelar antes da preparação. A equipe pode cancelar antes da retirada. O cancelamento exige motivo; quando já pago, registra estorno fictício e devolve as unidades ao estoque. Pedido retirado não pode ser cancelado.
9. O Administrador abre **Total vendido** e consulta o período desejado. Funcionário e Cliente não acessam essa rota. A consulta soma pagamentos atualmente aprovados e exclui os estornados; o período usa a data de confirmação, não a data de uma tentativa inicialmente pendente. Um estorno posterior remove a venda da consulta desse período também. Não é relatório de fluxo de caixa por data de estorno.

Os pedidos listados são os últimos 100 da conta, ou da loja na visão da equipe. A atualização é explícita pelo botão da tela; não há promessa de atualização instantânea entre dispositivos.

## Modelo e migração

Executar `banco (SSMS)/migracoes/003_compras.sql` após 001 e 002. A migração é reaplicável e já foi executada nesta máquina. Não utilizar o script antigo que remove o banco.

- `CarrinhoItensLoja`: quantidade por usuário e variação, sem reserva.
- `PedidosLoja`: comprador, identificador da finalização, estado, total, prazo e informações de retirada.
- `ItensPedidoLoja`: snapshots de nome, imagem, cor, tamanho, quantidade e preço.
- `PagamentosSimulados`: tentativas e seus resultados, com valor e datas, sem dados de cartão reais.
- `EventosPedidoLoja`: histórico de alterações com responsável e instante.
- `MovimentacoesEstoque`: ampliada com saldo reservado anterior e posterior, além de tipos Reserva, Liberacao, Venda e Estorno. A procedure de movimentação manual também registra o valor reservado preservado.

As tabelas antigas `Carrinho`, `Pedidos`, `Pagamentos` e seus relacionamentos do PIM III foram preservados. O módulo novo utiliza as tabelas com os nomes acima; não importa automaticamente compras antigas para o novo modelo por variação. Nenhum registro legado foi apagado pela migração.

## Consistência e autorização

As ações comerciais usam uma transação SQL e um lock de aplicação transacional compartilhado, apropriado ao volume de uma única loja fictícia. Alterações do cadastro e desativação do produto usam o mesmo lock para não concorrer incorretamente com novas reservas. Atualizações condicionais com a versão do saldo protegem contra concorrência com entradas e ajustes manuais, que têm sua própria procedure. Falhar em qualquer item desfaz toda a reserva do pedido. O trigger existente atualiza apenas o total físico agregado do produto, sem duplicar baixas.

A finalização é identificada por usuário e GUID de operação; repeti-la retorna o mesmo pedido. A tentativa é identificada por pedido e GUID, e não aceita o mesmo identificador com método ou resultado solicitado diferentes. Repetir confirmação, cancelamento ou avanço já concluído não duplica movimentações. Uma tentativa antiga não aprova um pedido cancelado ou expirado. Somente o comprador simula seus pagamentos; a equipe acessa o atendimento, sem poder pagar pedidos de outras pessoas.

O processo em segundo plano verifica reservas a cada 30 segundos enquanto a API está em execução. As rotas de compras também liberam reservas vencidas antes das operações. Se a aplicação estiver desligada, as reservas vencidas serão tratadas quando voltar a funcionar. Horários são registrados em UTC e apresentados no fuso do navegador. Não há rota pública para alterar o relógio ou antecipar artificialmente uma expiração.

## Contratos principais

Todas as rotas abaixo exigem uma sessão. Os contratos completos estão no Swagger local.

| Rota | Finalidade |
| --- | --- |
| GET /api/compras/carrinho | Carrinho do usuário autenticado, preços e disponibilidade atuais. |
| PUT /api/compras/carrinho | Define quantidade de uma variação; zero remove. |
| POST /api/compras/pedidos | Finaliza o carrinho com `operacaoId`. |
| GET /api/compras/pedidos | Últimos pedidos próprios; `equipe=true` exige perfil interno. |
| GET /api/compras/pedidos/{id} | Detalhe próprio ou atendimento pela equipe; código somente ao comprador. |
| POST /api/compras/pedidos/{id}/pagamentos | Cria tentativa: `operacaoId`, `metodo`, `resultado`. |
| POST /api/compras/pedidos/{id}/pagamentos/{pagamentoId}/resolver | Define resultado de tentativa pendente do comprador. |
| POST /api/compras/pedidos/{id}/cancelar | Cancelamento com motivo, respeitando perfil e etapa. |
| POST /api/compras/pedidos/{id}/andamento | Equipe avança a etapa; retirada exige código. |
| GET /api/compras/resumo | Administrador; `inicio` inclusivo e `fim` exclusivo em UTC. |

## Verificação realizada

Compilação sem erros ou avisos. A suíte completa passou em **203 verificações de integração**; os cinco testes de comunicação web também passaram. A cobertura inclui última unidade concorrente, rollback de reserva parcial, preço adulterado, histórico de preços preservado, confirmação repetida, cancelamento repetido, recusa e nova tentativa sem disponibilidade, expiração sem navegador aberto, tentativa antiga após vencimento, cancelamento concorrente com aprovação, retirada por código, permissões, desativação concorrente com compra e total vendido com estorno.

No navegador foram conferidos login com retorno à peça, inclusão no carrinho, finalização, Pix pendente, aprovação, código, lista da equipe, preparação, pedido pronto, cancelamento com estorno e total voltando a zero. A tela de pedido foi inspecionada em viewport de 390 pixels, sem transbordamento horizontal; isso não substitui teste em celular físico. As capturas `output/qa/compras-*.png` usam dados temporários, já removidos.

Após os testes, permaneceram os saldos existentes de 10/8/6 e a variação RN de 15 unidades, sem unidades reservadas. A variação RN já existia antes desta etapa. Não ficaram contas ou pedidos temporários no banco. Sequências de identidade podem apresentar intervalos devido a rollback e limpeza dos testes; isso não representa perda de pedidos.

## Painel lateral do carrinho

Atualização de interface em 20/10/2026: o painel do carrinho desliza da direita para a esquerda, ocupa aproximadamente 35% da tela no computador e adapta a largura no celular. Cabeçalho e total/botão permanecem visíveis enquanto a lista rola. Pode ser fechado pelo botão, por Escape e pelo fundo externo; o foco volta à origem e a navegação por Tab permanece no painel. A interface respeita a preferência por movimento reduzido e possui estados para visitante, vazio, carregamento e falha com nova tentativa. Foram conferidos no navegador os estados de visitante, vazio e preenchido, fechamento, teclado e acesso ao detalhe; a adaptação foi inspecionada em viewport de 390 pixels. Evidências em `output/qa/carrinho-lateral.png` e `output/qa/carrinho-lateral-mobile.png`, com itens de conta temporária removidos após a conferência. Nenhuma compra foi finalizada para testar esta alteração.

## Próximas entregas

Revisão final da plataforma web e da acessibilidade em aparelho real; documentação acadêmica de arquitetura, MER e roteiro de apresentação; depois, instalação e desenvolvimento Flutter. Nuvem e DevOps permanecem conforme o planejamento acadêmico. Este módulo não executa pagamentos reais, envio de mensagens, entrega de produtos, frete, nem devoluções após retirada.
