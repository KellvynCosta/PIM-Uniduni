# Uniduni — plano de implementação do PIM IV

Planejamento inicial de 19/10/2026, baseado no escopo aceito pelo usuário em `escopo-pim-iv.md`. As datas são metas de organização, não registros de trabalho já realizado. Conclusão pretendida: 05/11/2026.

## Resultado a demonstrar

Um cliente encontra um produto no site ou no Android, escolhe cor e tamanho, finaliza o pedido e realiza um pagamento simulado. A equipe acompanha o mesmo pedido em qualquer plataforma, prepara os itens e confirma a retirada por código. O Administrador acompanha os valores e as movimentações de estoque. As permissões e regras são aplicadas na API e no banco, além das interfaces.

## Organização técnica proposta

- Manter o frontend HTML/CSS/JavaScript e evoluir sua identidade visual atual.
- Manter .NET e SQL Server; separar apresentação HTTP, regras de negócio e persistência por responsabilidade, evitando reescrita sem necessidade.
- Priorizar a plataforma web por solicitação do usuário: concluir e validar seus fluxos antes de iniciar instalação, configuração ou desenvolvimento Flutter.
- O usuário administra o SQL Server pelo SSMS. Preparar scripts de evolução compatíveis com esse fluxo, com instruções de execução e preservação dos dados existentes.
- Centralizar regras de pedidos, pagamentos e estoque na API, compartilhadas pelo site e pelo Flutter.
- Usar DTOs para separar entradas e respostas das entidades persistidas. O cadastro público nunca aceita elevação de perfil.
- Proteger senhas com hash, autenticar sessões e verificar perfil e propriedade de recursos no servidor.
- Modelar separadamente produto e variação de cor/tamanho, pedido e itens, tentativa de pagamento, reserva e movimentação de estoque.
- Preservar preço e descrição dos itens no momento da compra para que alterações de catálogo não modifiquem o histórico.
- Executar reserva, confirmação, cancelamento e estorno com transações e proteção contra repetição da mesma operação.
- Procedures e triggers devem ter responsabilidades explícitas e úteis; não duplicar baixas de estoque entre API e banco.
- Manter mudanças de banco separadas do script antigo que remove o banco. Não executar esse script contra os dados existentes durante a evolução.
- Preparar dados fictícios e um procedimento de demonstração que possam ser usados novamente sem apagar dados por padrão.

## Verificação inicial realizada

- Em 19/10/2026, a API existente compilou com .NET SDK 10.0.401, sem restauração de pacotes: zero erros e 14 avisos CS8618 de propriedades não inicializadas nos modelos de entrada e entidades.
- Essa verificação não executou o fluxo web nem validou a conexão com SQL Server. Nenhum script de banco foi executado.
- Flutter e ferramentas Android ainda não foram preparados. A implementação das novas funcionalidades não foi iniciada nesta etapa de planejamento.

## Entregas e metas

| Etapa | Meta | Entrega verificável |
| --- | --- | --- |
| 1 — Base web e banco | 19–21/10 | Diagnóstico da execução, conexão com SQL Server, scripts para SSMS, modelo de dados, autenticação e permissões. |
| 2 — Operação comercial | 22–25/10 | Catálogo por variação, carrinho, pedidos, reserva, expiração, simulação de pagamento e cancelamento na API e no banco. |
| 3 — Web completo e validado | 26–28/10 | Jornada de compra e retirada, administração, estoque, indicadores, acessibilidade e testes dos fluxos web, mantendo a identidade visual. |
| 4 — Flutter, após a entrega web | 29/10–02/11 | Instalação e configuração Flutter/Android, aplicativo com as funções dos três perfis, consumindo a API validada no site e testado no celular. |
| 5 — Integração final e evidências | 03–04/11 | Testes entre web e mobile, acessibilidade Android, correções, evidências e materiais técnicos para a documentação. |
| 6 — Entrega | 05/11 | Revisão do escopo, roteiro de apresentação e instruções para executar o projeto. |

A instalação e o desenvolvimento Flutter ficam para a última fase de implementação, após a validação da plataforma web. A API continua compartilhável para que o aplicativo aproveite as mesmas regras e dados. As metas de datas serão revistas conforme o avanço real; a ordem de prioridades prevalece sobre as datas propostas.

## Backlog inicial

Todos os itens estão inicialmente a fazer, exceto o levantamento de requisitos já concluído.

Atualização de 19/10/2026: primeira implementação de BASE-01, AUTH-01 e AUTH-02 concluída e integrada às telas existentes. A API compilou sem erros ou avisos; 45 verificações de integração com SQL Server e 5 testes da comunicação web passaram. Inclui hash das senhas existentes, sessões revogáveis, restrição do cadastro público a Cliente, autorização por perfil e desativação preservando histórico. O banco manteve as duas contas e os três produtos originais. A revisão visual e os demais módulos comerciais permanecem pendentes. As instruções estão no README.

Atualização de 20/10/2026: CAT-01 e EST-01 implementados na API, no SQL Server e na interface web. Inclui variações de cor/tamanho, filtro pela mesma combinação, guia de medidas editável, saldos iniciais, entradas, ajustes justificados, alertas, histórico e desativação sem exclusão. A migração 002 preservou os saldos 10/8/6 dos produtos existentes. A procedure executa movimentação e histórico na mesma transação; o trigger mantém o agregado legado, sem outra baixa. Foram aprovadas 92 verificações de integração, 5 testes de comunicação web e a conferência dos fluxos no navegador. Reservas estão apenas previstas na estrutura; PED-01, PAG-01 e PED-02 seguem pendentes.

| ID | Entrega | Dependência | Validação principal |
| --- | --- | --- | --- |
| BASE-01 | Preparar execução local e registrar configurações | Nenhuma | API compila; conexão com banco verificada sem apagar dados. |
| AUTH-01 | Autenticação e senhas protegidas | BASE-01 | Login válido e inválido; respostas sem senha; encerramento da sessão. |
| AUTH-02 | Perfis e contas internas | AUTH-01 | Cliente não cria perfil interno nem acessa dados de terceiros. |
| CAT-01 | Catálogo, categorias e variações | BASE-01 | Quantidade disponível por cor/tamanho; roupas RN/P/M/G e numeração própria para calçados. |
| EST-01 | Entradas, ajustes, histórico e alertas | AUTH-02, CAT-01 | Alterações justificadas e rastreáveis; estoque não fica negativo. |
| PED-01 | Carrinho e pedido com reserva | AUTH-01, CAT-01 | Preço calculado no servidor; proteção da última unidade. |
| PAG-01 | Cartão e Pix simulados | PED-01 | Aprovação, recusa e pendência com registros de tentativas. |
| PED-02 | Expiração, cancelamento e estorno | PAG-01 | Reserva expira em 30 minutos; liberações e estornos ocorrem uma única vez. |
| RET-01 | Preparação e retirada por código | PED-02, AUTH-02 | Conferência do código, responsável e data/hora; funcionamento fora do horário informado. |
| ADM-01 | Indicadores e gestão de usuários | PAG-01, PED-02, AUTH-02 | Valores conciliados e restritos ao Administrador. |
| WEB-01 | Jornada e áreas web | APIs correspondentes | Fluxo completo nos três perfis e preservação da identidade visual. |
| MOB-01 | Preparar Flutter e Android | WEB-01 e A11Y-WEB-01 validados | Ferramentas verificadas e aplicativo de teste executado no Samsung. |
| MOB-02 | Aplicativo integrado | MOB-01, APIs correspondentes | Dados alterados no app aparecem no site e vice-versa após atualização. |
| A11Y-WEB-01 | Acessibilidade e inclusão web | WEB-01 | Teclado, foco, contraste, VLibras, formulários e imagens adequadas. |
| A11Y-MOB-01 | Acessibilidade Android | MOB-02 | Leitor de tela, texto ampliado e imagens adequadas. |
| DOC-01 | Evidências e material técnico | Evolui com as entregas | Modelos de banco, arquitetura, contratos, plano de nuvem/DevOps e backlog coerentes com o realizado. |

## Regras que orientam os testes

### Contas e permissões

- Visitante consulta catálogo; precisa autenticar para fechar pedido.
- Cadastro público cria Cliente mesmo se uma requisição tentar enviar outro perfil.
- Cliente consulta e cancela apenas seus próprios pedidos, nos estados permitidos.
- Funcionário gerencia operação e consulta valores dos pedidos, sem acessar indicadores gerais ou gestão de contas internas.
- Administrador acessa as funções gerenciais e cadastra contas internas.

### Estoque e pagamentos

- Duas compras concorrentes da última unidade resultam em apenas uma reserva válida.
- Alterar valores no navegador não altera o preço calculado pela API.
- Reserva reduz disponibilidade, sem gerar uma segunda baixa quando o pagamento é confirmado.
- Expiração considera o horário registrado no servidor e funciona sem depender de o cliente manter uma tela aberta.
- Recusa, expiração ou cancelamento liberam somente os itens ainda reservados.
- Nova tentativa após recusa revalida disponibilidade e cria a reserva necessária.
- Repetir aprovação, cancelamento, expiração ou estorno não duplica valores nem movimentações.
- Pagamento pendente, recusado ou expirado não integra o total vendido; estorno aprovado reduz o total.
- Um pedido cancelado ou expirado não pode ser aprovado posteriormente por uma tentativa antiga.

### Retirada

- Fluxo principal: pendente → pago → em preparação → pronto para retirada → retirado.
- Cliente cancela somente antes da preparação; equipe cancela antes da retirada.
- Confirmação exige pedido pronto e código correto, com registro do operador e instante.
- Pedido retirado não pode ser cancelado ou estornado no escopo inicial.
- Horário de atendimento é informativo: testar confirmação à noite e no domingo, sem bloqueio por calendário.

### Integração e interface

- Demonstrar compra no Android e atendimento no site; repetir no sentido inverso.
- A interface oferece atualização dos dados; não pressupor sincronização offline ou atualizações instantâneas por conexão persistente.
- Não armazenar credenciais de banco no site ou aplicativo; acesso aos dados ocorre pela API.
- Exibir claramente a simulação de pagamentos e o caráter fictício da loja e do horário.
- Testar formulários por teclado no site, TalkBack no Android e texto ampliado sem ocultar ações essenciais.

## Roteiro previsto para a apresentação

1. Abrir catálogo sem login, filtrar um produto e escolher uma variação.
2. Entrar como Cliente, finalizar o pedido e aprovar pagamento simulado.
3. No outro dispositivo, entrar como Funcionário, preparar o pedido e confirmar a retirada por código.
4. Entrar como Administrador e conferir total vendido e histórico de estoque.
5. Demonstrar pagamento recusado e um cancelamento com estorno, conferindo os efeitos.
6. Mostrar uma reserva vencida preparada para teste com controle de tempo interno aos testes, sem precisar esperar 30 minutos durante a apresentação e sem permitir ao cliente alterar o relógio do servidor.
7. Apresentar uma ação de acessibilidade e a restrição de acesso de cada perfil.

## Critério de conclusão de uma entrega

Atualização de 20/10/2026 — etapa de compras: PED-01, PAG-01, PED-02 e RET-01 implementados e integrados ao site. Inclui carrinho autenticado, snapshots, reserva por 30 minutos, expiração em segundo plano, tentativas Pix/cartão, recusa e revalidação, cancelamento, estorno, preparação e retirada por código. A parte de total vendido de ADM-01 também foi entregue, com filtro por período e acesso exclusivo do Administrador. Os 203 testes de integração e cinco testes de comunicação web passaram; a compilação teve zero erros e avisos. A jornada de compra, atendimento e estorno foi conferida no navegador. O comportamento em viewport estreito foi inspecionado, mas validação em aparelho físico e TalkBack continua pendente. Ver `compras-pedidos-pagamentos.md`. O web segue em revisão final; Flutter, documentação acadêmica completa e implantação não foram declarados concluídos.

Funcionalidade implementada, testada nos casos relevantes, integrada às plataformas previstas e com instruções/evidências atualizadas. Compilar isoladamente não comprova integração com SQL Server, execução no Android ou conclusão do fluxo comercial.
