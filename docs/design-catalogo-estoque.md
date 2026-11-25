# Direção das telas de catálogo e estoque

20/10/2026. Problema: permitir que famílias identifiquem a variação disponível e que a equipe mantenha o estoque por cor e tamanho sem perder o histórico.

- Paleta: fundo `#f8f9fb`, superfície `#ffffff`, rosa `#f78ac7`, azul `#8ecae6`, turquesa `#00d4d8`, texto/ações `#174e57`. O degradê da marca permanece em cabeçalho e detalhes; mensagens e botões usam contraste próprio.
- Tipografia: manter Arial para leitura e usar Trebuchet MS nos novos títulos de seção, com fallback sem serifa. Não depender de downloads de fontes.
- Catálogo: fotografia e nome do produto primeiro; categoria, tamanhos e disponibilidade como informações úteis. Filtros com rótulos visíveis e mensagem quando não houver resultados.
- Detalhe: imagem ao lado da descrição, preço, seletores de cor/tamanho e disponibilidade da combinação escolhida. Guia de medidas informado pela equipe, sem inventar medidas para o acervo atual.
- Administração: lista de produtos seguida de um espaço de trabalho para cada produto. Variações em tabela com saldo disponível e alerta textual; entrada/ajuste em formulário e histórico cronológico.
- Responsividade: formulários em uma coluna no celular e tabelas em contêiner com rolagem própria, sem gerar rolagem horizontal da página.
- Interação: foco visível, mensagens em região de status, botões desabilitados durante gravação e preservação do contexto após a atualização.

Revisão do plano: manter o estilo aceito pelo usuário, usando as cores da marca para identidade e um tom escuro para ações legíveis. Não acrescentar gráficos ou indicadores decorativos. O centro dessas telas são as variações reais e a rastreabilidade das quantidades.

Estrutura prevista:

```text
Catálogo:    filtros → produtos → combinação disponível
Gestão:     produtos → dados do produto → variações
                                         → entrada/ajuste → histórico
```
