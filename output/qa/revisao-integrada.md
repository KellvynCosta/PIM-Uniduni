# Revisão integrada — web, serviços Flutter e SQL Server

Esta é uma evidência operacional de testes locais, não a documentação acadêmica final.

## Resultado

- API e SQL Server: 203 verificações passaram, incluindo perfis, concorrência, idempotência, expiração, reservas, pagamento simulado, estorno e retirada.
- Flutter: análise estática sem problemas e 22 testes passaram. Incluem cadastro, senha, CRUD, estoque e atendimento, com cenários de texto ampliado.
- Comunicação web: 5 testes passaram; sintaxe de compras.js validada após a alteração.
- Duas rodadas de compra usando os serviços Dart consumidos pelo aplicativo, atendimento no navegador e nova consulta por Dart: pedido retirado com operador/data, lista do comprador atualizada, físico 6/reservado 0/disponível 6 no produto exclusivo e acréscimo de R$ 59,80 no resumo. Cada rodada usou seu próprio fixture, posteriormente removido.

## Percursos no navegador

- Funcionário: produtos/estoque e atendimento disponíveis; Pessoas e Total vendido ausentes. Compra originada pelos serviços Flutter encontrada; preparação e pronto registrados; código incorreto rejeitado.
- Administrador: Pessoas e Total vendido disponíveis. Segunda compra preparada, marcada pronta e retirada. Resumo exibiu R$ 59,80 para a venda temporária.
- Cliente: menu sem painel interno; pedido próprio consultável com retirada concluída. Não há pagamento ou cancelamento disponível após a retirada.
- Confirmação de retirada: Voltar mantém o pedido pronto e preserva o código; foco retorna ao botão de origem; Confirmar conclui a entrega.
- Em viewport de 390 px, resumo e detalhe do pedido revisados. Título do produto temporário com trecho longo sem espaços provocava transbordamento; overflow-wrap:anywhere corrigiu a página de 430 px para 380 px de largura de conteúdo (viewport 390 px com espaço de barra de rolagem).
- Carrinho lateral aberto em tela estreita; Escape fecha e devolve o foco a Meu carrinho.
- Nenhum erro no console da aba na consulta final.

## Alterações

- Site exige confirmação antes de registrar a retirada, acompanhando o fluxo mobile.
- Nome longo no item do pedido quebra sem provocar rolagem horizontal na página.
- Versões dos arquivos JS/CSS atualizadas nas sete páginas para renovação do cache.
- README mobile corrigido sobre a disponibilidade das movimentações de estoque.
- tool/review_cross_platform.dart permite preparar a compra e conferir o resultado após o atendimento no navegador. Usa somente credenciais do fixture em tmp/qa-ui.json e produto exclusivo com o prefixo do fixture.

## Evidências e alcance

- revisao-integrada-confirmacao.png: confirmação no site com conta e pedido temporários.
- revisao-integrada-pedido-390.png: pedido temporário em tela estreita após a correção.

O usuário preferiu testar depois no Samsung. Esta rodada NÃO comprova uso manual no aparelho, TalkBack, toque/teclado físico nem funcionamento do VLibras por um usuário. O aparelho foi identificado como conectado e autorizado, mas não foi operado nesta revisão. Os testes Flutter são automatizados; a compra cruzada usou seus serviços Dart pela linha de comando, não toques no Samsung. Hospedagem, HTTPS público e APK para internet continuam para a próxima etapa. Os dados de teste foram removidos com proteção para preservar produtos e pedidos preexistentes.
