# Revisão web — 20/10/2026

Revisão local da aplicação existente, antes da etapa Flutter. Não equivale à conclusão de todo o PIM, à implantação em nuvem ou à validação em aparelho físico.

## Ajustes realizados

- O painel lateral mantém **35% da largura no desktop**. Até 1000 pixels de viewport, usa no máximo 560 pixels, respeitando a largura disponível. Isso evita comprimir a lista em tablets. Animações, fechamento e acesso ao carrinho detalhado foram preservados.
- Os textos menores do catálogo em telas de até 480 pixels passaram a ter pelo menos **12 pixels**, mantendo a grade de duas colunas e os espaçamentos existentes. Os títulos e preços conservam sua hierarquia.
- A descrição dos produtos passou de `#85718f` para `#806b8b`: contraste calculado com fundo branco de aproximadamente **4,42:1 para 4,78:1**. É uma verificação dessa combinação específica, não uma auditoria completa de todos os estados ou de conformidade WCAG.
- O preparador de revisão cria contas temporárias dos três perfis; a limpeza usa os e-mails exatos do fixture e só aceita remover pedidos cancelados ou expirados. O pedido desta revisão foi cancelado pelo fluxo normal antes da limpeza.

## Resultado da validação

| Verificação | Resultado / alcance |
| --- | --- |
| Compilação | Sucesso, zero erros e avisos. |
| Integração com SQL Server | **203 verificações passaram novamente**. Log em `output/qa/revisao-integracao.log`. |
| Comunicação web | **5 testes passaram novamente**: escape de conteúdo, envio da sessão, bloqueio de token para destino externo, expiração da sessão e configuração de API local. |
| Cliente no navegador | Login, bloqueio ao painel interno, produto, inclusão no carrinho, painel lateral, carrinho detalhado e finalização. |
| Pagamentos no navegador | Cartão recusado seguido de nova tentativa Pix aprovada; tentativas preservadas no histórico. |
| Funcionário no navegador | Produtos/estoque e pedidos disponíveis; Pessoas e Total vendido ausentes do menu. Abertura direta do resumo bloqueada. Preparação e pedido pronto conferidos. Código incorreto recusado. |
| Administrador no navegador | Total de R$ 44,90 após aprovação; cancelamento pela equipe com motivo, estorno e total voltando a R$ 0,00. |
| Retirada correta | Exercitada pela suíte de integração. Nesta rodada de navegador, a retirada foi testada com código incorreto e o pedido foi cancelado antes da entrega, permitindo restaurar o saldo. |
| Teclado do painel | Shift+Tab a partir de Fechar carrinho levou ao último link do painel; acesso ao detalhe funcionou. Fechamento por Escape e retorno de foco já haviam sido conferidos na entrega do painel. |
| Responsividade | Catálogo em viewport de 390 pixels sem transbordamento horizontal; textos conferidos por estilos calculados. Painel preenchido em 820 pixels com área de lista de 560 pixels, sem transbordamento interno. Resumo administrativo conferido em desktop de 1280 pixels. |
| Console | Nenhum erro registrado no console da aba na consulta realizada ao final do percurso. |
| Limpeza | Três contas e pedido temporários removidos. Consulta SQL confirmou zero contas `pim-ui-*`/`pim-teste-*` e zero reservas nas variações existentes. |

A suíte integra autenticação, autorização, catálogo e estoque, reserva atômica, disputa pela última unidade, idempotência, expiração em segundo plano, preço definido pelo servidor, estados de atendimento, código de retirada e total vendido com estorno. Ela utiliza registros com identificadores próprios e os remove ao finalizar.

## Saldos após a revisão

Consulta SQL final, sem redefinir saldos por fora das regras comerciais:

| Produto / variação | Físico | Reservado |
| --- | ---: | ---: |
| Body Bebê Azul / Azul / P | 10 | 0 |
| Body Bebê Azul / Azul / RN | 15 | 0 |
| Camiseta Preta / Preto / P | 8 | 0 |
| Sapatinho / cor não informada / 18 | 6 | 0 |

Os produtos e os pedidos preexistentes foram preservados. As sequências numéricas podem ter intervalos em razão dos testes e da limpeza de seus registros.

## Evidências

- `output/qa/revisao-catalogo-mobile.png`: catálogo com textos maiores em viewport de 390 pixels.
- `output/qa/revisao-carrinho-tablet.png`: painel preenchido em viewport de 820 pixels.
- `output/qa/revisao-total-vendido.png`: total durante a venda de teste, antes do estorno. O pedido e as contas mostrados são temporários e já foram removidos.
- `output/qa/revisao-integracao.log`: resultado desta execução de integração.

## Pendências antes de considerar a entrega acadêmica encerrada

- Ensaiar o [roteiro de demonstração](roteiro-demonstracao-web.md) com as contas do grupo e o tempo de apresentação.
- Conferir o site no Android físico, teclado/leitor de tela e uso efetivo do VLibras. Viewports simuladas e presença do botão não comprovam essas experiências.
- Completar documentação acadêmica de arquitetura, MER e modelos lógico/físico, explicação das procedures/triggers, processo ágil e planejamento de nuvem/DevOps conforme o manual.
- Instalar o ambiente Flutter e desenvolver/testar o aplicativo consumindo a API. A API local em HTTP é adequada a esta demonstração; publicação exige configuração própria de hospedagem, HTTPS e segredos.

Nenhum defeito funcional impeditivo apareceu nos percursos executados. Essa conclusão se limita aos cenários descritos e não substitui os itens pendentes.
