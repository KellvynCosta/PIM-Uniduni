# Material técnico do PIM IV da Uniduni

O arquivo Uniduni_PIM_IV_capitulos_revisados.docx reúne os textos acadêmicos das quatro disciplinas solicitadas, com figuras incorporadas, legendas, fontes e referências. Sua redação e apresentação seguem a documentação do PIM III fornecida pelo grupo, atualizadas para a implementação atual.

O Word tem 23 páginas. Trata-se do conjunto técnico dessas quatro disciplinas, e não do trabalho acadêmico completo com capa, outras disciplinas e elementos pré e pós-textuais. A numeração de capítulos, figuras e páginas é interna a este material e pode ser ajustada pelo líder à sequência do documento final. O manual prevê de 20 a 30 páginas de desenvolvimento para o PIM como um todo; a seleção e a distribuição das figuras no trabalho consolidado devem considerar esse limite global.

## Correspondência entre o manual e os capítulos entregues

| Disciplina | Conteúdo solicitado no manual | Local no Word |
| --- | --- | --- |
| Desenvolvimento Web com Net | Arquitetura da aplicação, APIs REST, autenticação, segurança, estrutura administrativa e integração entre módulos | Capítulo 1, seções 1.1 a 1.6 |
| Desenvolvimento Mobile | Telas principais, fluxo de navegação, autenticação, sincronização de dados e integração com APIs | Capítulo 2, seções 2.1 a 2.7 |
| Programação Aplicada em .NET | Orientação a objetos, organização em camadas e modularização da solução integrada | Capítulo 3, seções 3.1 a 3.4, incluindo encapsulamento, abstração, herança, polimorfismo e injeção de dependência |
| Programação de banco de dados | Modelo de entidades e relacionamentos, modelos lógico e físico, procedures, triggers e script SQL completo | Capítulo 4, seções 4.1 a 4.6; arquivos SQL, CSV e draw.io complementares |

Referência dos requisitos: Manual do PIM IV, etapas 4 a 7, páginas 24 a 26 do PDF fornecido. A documentação do PIM III orientou o estilo e a continuidade do projeto; as descrições de funcionamento do PIM IV foram confrontadas com o código atual.

## Arquivos entregues

- Uniduni_PIM_IV_capitulos_revisados.docx: textos prontos e figuras das quatro disciplinas.
- Uniduni_PIM_IV_banco_completo.sql: estrutura física integral do banco atual, com as 17 tabelas, chaves, restrições, índices, procedure e trigger.
- Dicionario_de_dados_completo.csv: todas as colunas, tipos SQL Server, nulabilidade, chaves e valores padrão. Formato UTF-8 com BOM e separador ponto e vírgula, apropriado para abertura no Excel.
- Modelos_Uniduni_PIM_IV.drawio: diagramas conceituais e lógicos editáveis no diagrams.net. Os recortes são páginas do mesmo arquivo e compartilham as mesmas entidades; tabelas marcadas como “ref.” não são duplicatas no banco.
- figuras: imagens utilizadas no Word e figuras complementares das telas e modelos. As imagens de código físico são exemplos para leitura; a definição completa, incluindo restrições adicionadas após CREATE TABLE, está no arquivo SQL.
- Validacao_tecnica.txt: registro da conferência do SQL e dos testes do aplicativo.

## Esclarecimento sobre as observações anteriores

Banco de dados: a observação anterior referia-se à consolidação da estrutura em um arquivo integral de entrega. Esse arquivo foi produzido e validado recriando a base em um ambiente descartável separado. Não falta um script a ser escrito para este material. A base existente do grupo foi preservada.

Mobile: o aplicativo já implementa o CRUD de produtos solicitado pelo professor, além de cadastro e autenticação, catálogo, carrinho, pedidos, pagamentos simulados, estoque, atendimento, usuários por Administrador e total vendido. A observação anterior sobre validação manual dizia respeito à conferência final de usabilidade no aparelho, que o grupo havia preferido fazer depois. Isso não representa ausência desses módulos.

As figuras mobile deste material foram produzidas com as telas reais do código Flutter, renderizadas em testes com dados fictícios. Elas estão identificadas dessa forma no Word. Não foram apresentadas como novas capturas do Samsung, que não estava conectado durante esta revisão. A instalação e a execução no Samsung haviam sido realizadas e confirmadas pelo integrante em etapas anteriores. Não se declara uma nova validação manual completa nem certificação de acessibilidade com TalkBack.

A publicação em hospedagem pública não foi realizada. O funcionamento documentado usa API e SQL Server locais; a integração no Samsung utilizou encaminhamento de porta USB. Uma mudança feita por uma plataforma é consultada pela outra na mesma API ao atualizar os dados. Não há banco offline ou sincronização por WebSocket implementados.

## Estrutura preservada e evolução do PIM III

As entidades Usuarios, Categorias e Produtos continuam na solução. O núcleo atual da API utiliza 11 tabelas: Usuarios, Sessoes, Categorias, Produtos, ProdutoVariacoes, MovimentacoesEstoque, CarrinhoItensLoja, PedidosLoja, ItensPedidoLoja, PagamentosSimulados e EventosPedidoLoja.

As seis tabelas legadas Carrinho, CarrinhoItens, Enderecos, Pedidos, PedidoItens e Pagamentos permanecem na base e no script para representar a estrutura existente. Elas não são o fluxo comercial atual. O diagrama de legado é complementar; as definições físicas e referências de todas as tabelas constam no SQL e no dicionário.

O MER conceitual emprega entidades, atributos e relacionamentos em losangos, como o PIM III. O modelo lógico apresenta atributos e marcações PK/FK. O físico reproduz definições SQL Server. Os recortes evitam concentrar todas as relações em uma figura ilegível e são explicados no texto.

## Execução do SQL no SSMS

O script é uma entrega de estrutura para criação de uma base nova. Não é um script de atualização da base já utilizada pelo grupo.

1. Abra o arquivo SQL no SSMS conectado ao SQL Server.
2. Ative Consulta > Modo SQLCMD.
3. Na linha `:setvar BancoDestino "uniduni"`, informe o nome de uma base nova, por exemplo `uniduni_apresentacao`.
4. Execute o arquivo completo. O login do SQL Server precisa ter permissão de criação de banco.

Se o nome já existir, o script interrompe a execução. Não contém DROP DATABASE e não substitui a base do grupo. São incluídas somente quatro categorias fictícias. Contas, hashes de senhas, sessões e vendas da base atual não são exportados. O arquivo não contém credenciais de acesso à aplicação e não constitui cópia dos dados operacionais.

## Uso no documento final

Os textos descrevem a implementação existente e não contêm campos “inserir depois”, figuras ausentes ou funcionalidades futuras tratadas como prontas. O líder pode incorporar os capítulos às disciplinas correspondentes, mantendo as legendas e referências e ajustando a numeração ao conjunto do trabalho. As imagens PNG e o arquivo draw.io permitem adequar tamanho e organização sem redesenhar os modelos.
