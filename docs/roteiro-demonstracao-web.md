# Roteiro de demonstração web — Uniduni

Roteiro sugerido de 10 a 15 minutos, preparado em 20/10/2026. Ajuste a duração ao tempo disponibilizado pelos professores. Esta demonstração cobre a plataforma web; Flutter e implantação em nuvem são entregas separadas.

## Preparação antes da apresentação

- Inicie o SQL Server e a API conforme o README. Abra `http://localhost:5288` e confira se os produtos aparecem. Use esse endereço para servir site e API juntos.
- Tenha três contas próprias de demonstração: Cliente, Funcionário e Administrador. O cadastro público cria apenas Cliente; uma conta Administrador existente cadastra os perfis internos em **Pessoas**. Não projete senhas nem arquivos de configuração.
- Use perfis ou navegadores separados para as contas. Abas comuns do mesmo site podem começar com uma cópia da sessão da aba que as abriu; confira o nome no menu da conta antes de cada ação.
- Cadastre um produto identificado como **Body de demonstração**, categoria Roupas, preço **R$ 49,90**, cor Azul, tamanhos P e M. Use uma imagem local já disponível no projeto. Prepare a variação P com **10 unidades físicas**, **0 reservadas** e estoque mínimo **3**. Verifique o saldo atual antes de usar a operação de ajuste.
- Este cenário é uma sugestão para o ensaio: o produto e as contas não são criados automaticamente por este documento. Os testes da revisão usaram registros temporários que já foram removidos.
- Anote o total vendido inicial como **T**. Se houver outras vendas no banco, compare as diferenças; não espere que o total comece em zero.
- Os pagamentos são fictícios. Não digite dados bancários ou de cartão reais. O horário da loja é informativo e não impede a apresentação.

## Sequência principal

| Tempo sugerido | Quem apresenta / tela | Ação e resultado que deve aparecer |
| --- | --- | --- |
| 1 min | Página inicial | Apresente a Uniduni como loja fictícia de produtos para bebês. Mostre a identidade visual, as duas fotografias de bebês, o catálogo, a busca e os filtros de categoria, cor e tamanho. |
| 1 min | Cliente / produto | Escolha Azul, P e **2 unidades**. Abra o guia de medidas e adicione ao carrinho. Clique no ícone: o painel desliza da direita, mostra quantidade, subtotais e total de **R$ 99,80**. Feche por Escape e abra novamente. |
| 1 min | Cliente / carrinho detalhado | Clique em **Ir para o carrinho detalhado**. Mostre os controles de quantidade e remoção. Explique que o carrinho ainda não reserva as peças. Finalize com duas unidades. |
| 1 min | Cliente / pedido | Anote o número do pedido **A**. Mostre o prazo de 30 minutos. Na equipe, atualize o estoque: o físico continua **10**, o reservado passa a **2** e o disponível a **8**. |
| 1 min | Cliente / pagamento | Escolha **Pix simulado** e **Deixar pendente**. Mostre a tentativa registrada e o identificador sem validade bancária. Use o controle da tentativa para aprovar. |
| 1 min | Equipe / estoque e Administrador / total | Após atualizar as telas, o físico deve ser **8**, o reservado **0** e o disponível **8**. O total vendido deve passar de **T** para **T + R$ 99,80**. O cliente vê seu código de retirada; a equipe não recebe esse código na consulta do pedido. |
| 2 min | Funcionário / Pedidos e retirada | Abra o pedido A, use **Iniciar preparação** e **Marcar pronto para retirada**. Tente um código incorreto e mostre a mensagem de erro sem concluir a retirada. Depois digite o código fornecido pela conta Cliente e confirme. Mostre o estado Retirado, o responsável e a data. Não há nova baixa de estoque ao retirar. |
| 1 min | Cliente / Meus pedidos | Atualize a consulta e mostre o pedido retirado. Explique que um pedido retirado não permite cancelamento neste escopo. |

## Segundo pedido: recusa e estorno

1. Com o mesmo Cliente, adicione **1 unidade** da mesma variação e finalize o pedido **B**, no valor de **R$ 49,90**.
2. Escolha **Cartão de teste** e **Recusar pagamento**. O cartão mostrado é fictício. A tentativa fica registrada; o saldo físico continua em **8** e a reserva volta a **0**. O total vendido não aumenta.
3. Faça uma nova tentativa aprovada. Se houver estoque disponível, o físico passa a **7**, a reserva fica **0** e o total passa a **T + R$ 149,70**.
4. Antes de iniciar a preparação do B, o Cliente abre **Cancelar pedido**, informa o motivo e confirma. Mostre o pedido Cancelado, a tentativa Estornado e o histórico. O físico volta a **8**; o total retorna a **T + R$ 99,80**.
5. Se quiser demonstrar cancelamento durante a preparação, use a equipe: o Cliente só cancela antes dessa etapa; Funcionário e Administrador podem cancelar até antes da retirada.

Esses valores pressupõem que ninguém mais movimente a variação ou registre vendas durante o ensaio. O pedido A permanece como venda demonstrativa: após sua retirada, as duas unidades continuam vendidas. Não altere o banco para forçar o resultado de um pedido já retirado.

## Gestão e permissões

- **Funcionário:** abra Produtos e estoque, entre no produto e mostre as variações, saldo físico/reservado/disponível e o histórico. Uma entrada registra quantidade e justificativa; um ajuste define um saldo físico alvo e não pode deixar o físico menor que o reservado. Para demonstrar alerta, use outra variação de demonstração com saldo igual ou inferior ao mínimo.
- **Administrador:** mostre Pessoas e Total vendido. Consulte um período que inclua a confirmação dos pagamentos. O indicador representa o total dos pagamentos simulados atualmente aprovados, excluindo os estornados; não representa lucro.
- **Cliente:** mostre Meus pedidos e o bloqueio ao abrir o painel interno. Um cliente não consulta pedidos de outra pessoa.
- **Funcionário:** mostre que Pessoas e Total vendido não aparecem em seu menu. A API também bloqueia o acesso, mesmo que alguém tente abrir diretamente essas áreas.
- **Acessibilidade:** navegue por Tab, mostre o foco dos botões, a pausa do carrossel, o fechamento do carrinho por Escape e o único botão do VLibras. Uma demonstração pontual não constitui certificação de acessibilidade.

## Expiração e consistência, se os professores perguntarem

A reserva vence em 30 minutos. O processo verifica vencimentos a cada 30 segundos enquanto a API está ligada; as rotas comerciais também verificam vencimentos. Se a API estiver desligada, as reservas vencidas são tratadas quando ela voltar. Para uma demonstração ao vivo, prepare um pedido pendente com antecedência e acompanhe o saldo, ou apresente o resultado da suíte de integração. Não existe botão público para adiantar o relógio.

Os testes locais exercitam concorrência na última unidade, repetição de confirmações, cancelamento simultâneo à aprovação, liberação por vencimento e reserva de múltiplos itens com rollback. A API confere os preços e as permissões; esconder um botão no navegador não é a proteção principal.

## Apoio técnico para perguntas

| Tema | Como explicar |
| --- | --- |
| Integração | O navegador chama a API ASP.NET Core, que aplica regras e acessa o SQL Server. O Flutter consumirá os mesmos serviços posteriormente. |
| Variação | Cor e tamanho identificam o saldo que será reservado e vendido. Duas variações do mesmo produto podem ter disponibilidades diferentes. |
| Histórico | O pedido preserva nome, preço, cor e tamanho da compra. Alterar o catálogo depois não reescreve o item já comprado. |
| Segurança | Senhas usam hash, sessões são verificadas pela API e cada ação exige perfil adequado. Pagamentos são somente simulações. |
| Banco | As migrações acrescentam tabelas e regras. A procedure registra movimentações de estoque; o trigger mantém o agregado físico do produto. |
| Limites | Retirada na loja, sem frete, cobrança real ou devolução após retirada. A lista exibe os últimos 100 pedidos e requer atualização explícita. |

## Conferência no dia

Teste o percurso inteiro antes de apresentar, confira disponibilidade, login das três contas e acesso às imagens locais. A fonte é local; o VLibras depende de um serviço externo. Mantenha as capturas em `output/qa` como apoio, sem apresentá-las como substitutas de uma execução ao vivo. Nunca execute o script legado `banco (SSMS)/uniduni.sql`: ele remove o banco.

Detalhes das regras e dos contratos: [compras-pedidos-pagamentos.md](compras-pedidos-pagamentos.md). Evidências e pendências: [revisao-final-web.md](revisao-final-web.md).
