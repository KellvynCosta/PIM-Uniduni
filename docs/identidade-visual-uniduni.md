# Uniduni — reinvenção visual

20/10/2026. O redesenho atende famílias que procuram peças para bebês e a equipe que mantém o catálogo, sem alterar as regras comerciais existentes.

## Direção aprovada pelo contexto do projeto

- Preservar rosa `#f78ac7`, azul `#8ecae6` e turquesa `#00cbd0`; acrescentar lilás `#d5c2eb`, fundo `#f9f8fc` e texto ameixa `#42364e`.
- Fonte Nunito variável hospedada no próprio projeto, com licença OFL. Usar a mesma família em títulos e leitura, variando peso e escala.
- Logo original em SVG: símbolo de acolhimento com a letra “u”, rosto de bebê e pequeno brilho; assinatura desenhada por traços vetoriais arredondados. O desenho não depende de fontes para abrir corretamente.
- Organizar a página inicial em navegação, apresentação com fotografia, atalhos de categorias, filtros e catálogo. Sem depoimentos, descontos ou números de vendas inventados.
- Usar molduras de fotografia e linhas pontilhadas como referência ao vestuário; evitar transformar toda informação em decoração.
- Integrar o mesmo sistema às páginas de produto, sobre, login, cadastro, usuários e estoque.
- Aplicar interações funcionais: menu móvel, dropdown de conta, visibilidade de senha, seletores, checkbox, filtros rápidos, ordenação, notificações e confirmação de desativação.
- Movimento: entrada da apresentação, transição das fotografias, resposta dos botões e expansão dos menus; respeitar movimento reduzido, pausa e navegação por teclado.

## Revisão antes da implementação

A referência anterior exige cores suaves e cantos arredondados. A diferenciação virá do logo, da fotografia em moldura e dos detalhes de vestuário, sem substituir a identidade por outra estética. A administração terá a mesma linguagem, mas com controles e tabelas objetivos. O botão de acessibilidade permanecerá o nativo do VLibras; a imagem customizada do CSS será removida.

```text
Loja:       logo + navegação + busca + conta
            apresentação / fotografia
            categorias / filtros / peças
            identidade / retirada / links
Gestão:     navegação de operação / área de trabalho
Conta:      identidade e fotografia / formulário
```

## Arquivos da marca

Os SVGs ficam em `frontend (VS Code)/images/brand`. O símbolo também é usado como favicon. Variantes claras e monocromáticas permitem aplicação sem fundos obrigatórios. A pasta `output/brand` reúne as cópias para uso fora do site.
