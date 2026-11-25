# Uniduni — decisões para o PIM IV

Registro atualizado em 19/10/2026 a partir das respostas do responsável pelo desenvolvimento. Este documento distingue decisões aceitas de pontos ainda em discussão e não afirma que as funcionalidades já foram implementadas.

## Contexto

- Empresa fictícia de produtos exclusivamente para bebês.
- Continuação do PIM III, aproveitando o site HTML/CSS/JavaScript, a API .NET e o SQL Server existentes.
- Aplicativo Flutter novo, integrado à mesma API e ao mesmo banco do site.
- Objetivo: divulgação, compras simuladas, administração, controle de estoque e acompanhamento do total vendido.
- Prazo de conclusão informado pelo grupo: 05/11/2026. O manual informa postagem até 14/11/2026; prevalece o prazo de trabalho informado pelo grupo.
- Responsável pelo desenvolvimento com experiência básica em Flutter.
- Prioridade confirmada: desenvolver e validar primeiro banco, API e plataforma web. Instalação, configuração e desenvolvimento Flutter ficam para a última fase de implementação.
- Banco SQL Server administrado pelo usuário via SSMS; manter esse ambiente e preparar scripts de evolução sem apagar os dados existentes.

## Decisões confirmadas

### Perfis e plataformas

As funções de cada perfil estarão disponíveis tanto no site quanto no aplicativo, adaptadas a cada interface.

| Perfil | Acesso previsto |
| --- | --- |
| Cliente | Catálogo, compra simulada e acompanhamento dos próprios pedidos. |
| Funcionário | Gestão de produtos, estoque e pedidos; consulta aos valores dos pedidos atendidos. |
| Administrador | Funções operacionais, indicadores, total vendido e gestão de usuários e funcionários. |

O relatório geral de faturamento é exclusivo do Administrador. As permissões devem ser verificadas na API, além da apresentação das interfaces.

- Catálogo disponível sem login; autenticação obrigatória para finalizar compras e consultar dados pessoais.
- Cadastro público cria somente clientes. Apenas o Administrador gerencia contas de funcionários e administradores.

### Catálogo e identidade

- Categorias: roupas, calçados, acessórios e kits.
- Roupas nos tamanhos RN, P, M e G, com indicação de medidas por produto; calçados com numeração própria.
- Produtos com variações de tamanho e cor; estoque individual para cada combinação.
- Preservar a identidade visual apresentada: degradê rosa, lilás, azul e turquesa, fundo claro, cartões brancos e cantos arredondados.
- Melhorar organização, legibilidade e destaque dos produtos mantendo a identidade da marca.
- Atualizar o conteúdo institucional para refletir o atendimento exclusivo a bebês.

### Compras, pagamentos e estoque

- Carrinho e finalização de pedidos.
- Cartão e Pix exclusivamente simulados, com dados fictícios e indicação de simulação.
- Demonstrar aprovação, recusa e pendência de pagamento.
- Reservar estoque ao finalizar o pedido; confirmar a venda após aprovação do pagamento.
- Liberar a reserva em caso de pagamento recusado ou pedido cancelado.
- Impedir que pedidos concorrentes comprometam a mesma última unidade disponível.
- Reservas de pagamento pendente expiram em 30 minutos e liberam o estoque.
- Permitir nova tentativa após pagamento recusado, sujeita à disponibilidade de estoque; a reserva anterior já terá sido liberada.
- Incluir entrada de mercadorias, ajustes com justificativa, histórico de movimentações e alertas de estoque baixo.
- Exibir total vendido; não incluir cálculo de lucro ou cadastro de custo como requisito financeiro confirmado.
- Indicadores exclusivos do Administrador: total vendido por período, quantidade de vendas, valor médio dos pedidos e produtos mais vendidos. O total considera pagamentos aprovados, descontando os estornos simulados.

### Retirada e cancelamento

- Uma única loja fictícia. Endereço de referência fornecido pelo usuário (faculdade): Av. Yojiro Takaoka, 3500 - Alphaville, Santana de Parnaíba - SP, 06500-000. Identificar o uso fictício nas telas; não apresentar como uma loja real ou serviço oferecido pela faculdade.
- Horário informativo da loja fictícia: segunda a sexta, das 9h às 18h; sábado, das 9h às 13h. Não bloquear compras, preparação, confirmação de retirada ou outras ações pelo dia ou horário. A apresentação deve funcionar a qualquer momento.
- Somente retirada; não há entrega ou cálculo de frete no escopo confirmado.
- Fluxo principal: pagamento pendente → pago → em preparação → pronto para retirada → retirado.
- Cancelamento como caminho alternativo, com registro de estorno simulado quando houver pagamento aprovado.
- Cliente pode cancelar pedido pendente ou pago, antes do início da preparação.
- Depois do início da preparação e antes da retirada, o cancelamento fica sob responsabilidade de funcionário ou administrador.
- Pedido retirado encerra o fluxo: não permitir cancelamento ou estorno nesse estado. Trocas e devoluções posteriores ficam como evolução futura.
- Cliente acompanha o andamento em sua conta.
- Gerar código de retirada por pedido, apresentado pelo cliente e conferido pelo funcionário; registrar o responsável pela confirmação e a data e hora.

### Acessibilidade, inclusão e diversidade

- Manter o VLibras no site.
- Web com navegação por teclado, foco visível, contraste adequado, descrição de imagens e formulários com mensagens claras.
- Flutter com suporte ao leitor de tela Android e ao tamanho de texto configurado no dispositivo.
- Utilizar imagens que representem a diversidade de bebês e famílias.
- Validar os recursos na prática; a presença do VLibras não substitui os demais cuidados de acessibilidade.

### Ambiente mobile

- Celular disponível para testes: Samsung S26 Ultra, Android.
- Flutter ainda não instalado, conforme informação do usuário.
- Em 19/10/2026, a inspeção local encontrou SDK .NET 10.0.401; flutter, dart e adb não foram encontrados no PATH. Android Studio e SDK Android não foram encontrados nos caminhos padrão consultados. Isso não exclui instalações em outros locais.

## Requisitos acadêmicos identificados no manual

Estes itens descrevem entregas do manual e precisam ser relacionados à implementação e à documentação do grupo:

- Caracterização da organização e planejamento da solução e do negócio.
- Responsabilidade social, diversidade, inclusão e acessibilidade.
- Aplicação web com APIs REST, autenticação, segurança, administração e integração de módulos.
- Aplicativo mobile com telas, navegação, autenticação, sincronização de dados e integração por APIs.
- Orientação a objetos, organização em camadas e modularização.
- Banco com modelo lógico, físico, MER, procedures, triggers e script completo utilizado pelos sistemas.
- Plano de infraestrutura em nuvem e DevOps, incluindo containers, CI/CD, monitoramento, escalabilidade e segurança; implantação efetiva aparece como diferencial nos objetivos.
- Product Backlog, Sprint Backlog, cronograma, Kanban e definição de entregas.

Fontes: manual do PIM IV, especialmente páginas 21–28, e documentação do PIM III fornecidos pelo usuário. As funcionalidades dos wireframes anteriores não devem ser consideradas implementadas sem verificação do código e da execução.

## Preparação e detalhamento da implementação

- Escopo funcional inicial confirmado nas cinco rodadas de perguntas e respostas.
- Detalhes operacionais poderão ser definidos durante o desenvolvimento e registrados, sem reabrir decisões já aceitas.
- Após a entrega web: instalação e configuração do Flutter e das ferramentas Android, conexão do celular e execução integrada.
- Sequência de entregas e critérios de validação em `plano-implementacao-pim-iv.md`.

## Situação

Levantamento inicial de requisitos concluído. Primeira entrega web implementada em 19/10/2026: autenticação, sessões e permissões. Segunda entrega em 20/10/2026: catálogo por cor/tamanho, filtros, guia de medidas, entradas e ajustes de estoque, histórico e alertas. Na mesma data, foram entregues a reinvenção visual e o módulo de compras: carrinho, pedidos, reserva e expiração, Pix/cartão simulados, cancelamento e estorno, atendimento e retirada por código, e consulta administrativa do total vendido por período. As migrações preservaram os cadastros existentes. Foram validadas 203 verificações de integração e cinco testes de comunicação web. Revisão final web, teste em aparelho físico, Flutter e documentação acadêmica completa permanecem previstos. Ver `compras-pedidos-pagamentos.md` para o que foi implementado e suas limitações.
