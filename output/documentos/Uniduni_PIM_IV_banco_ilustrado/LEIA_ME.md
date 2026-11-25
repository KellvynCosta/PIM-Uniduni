# Uniduni PIM IV — documentação revisada com banco ilustrado

O Word mantém os capítulos de Desenvolvimento Web, Desenvolvimento Mobile e Arquitetura e revisa o capítulo de Banco de Dados conforme os seis itens da professora. O conteúdo foi organizado no estilo do PIM III, com modelos divididos em recortes e explicações em texto corrido.

## Onde encontrar cada item

- MER: seção 4.1 e seus recortes complementares.
- Modelo lógico: seção 4.2, dividido por catálogo, contas, carrinho, pedidos e estoque.
- Modelo físico: seção 4.3, com trechos SQL e explicação dos tipos e restrições. A definição física integral está no Apêndice A.
- Procedure: seção 4.4, com fragmento real de código, explicação simples e exemplo de entrada e ajuste de estoque. A rotina completa aparece no Apêndice A.
- Trigger: seção 4.5, com código e explicação.
- Script completo: seção 4.6 e Apêndice A, com 15 imagens sequenciais que cobrem todas as 411 linhas do arquivo SQL, incluindo tabelas, chaves, restrições, índices, procedure, trigger e categorias iniciais.
- Tabelas preservadas do PIM III: Apêndice B, com MER e modelo lógico fragmentados das seis tabelas legadas. O núcleo atual tem 11 tabelas; o script reúne as 17 existentes.

## Arquivos

- Uniduni_PIM_IV_documentacao_banco_ilustrado.docx: documento editável com 46 páginas. São 25 páginas dos quatro capítulos, uma de referências, 15 do Apêndice A e cinco do Apêndice B.
- Uniduni_PIM_IV_banco_completo.sql: script executável da estrutura completa, preservado byte a byte em relação à versão anterior.
- Modelos_fragmentados_completos.drawio: conjunto reunido dos modelos fragmentados editáveis. Abrir no diagrams.net.
- Dicionario_de_dados_completo.csv: descrição dos campos das 17 tabelas.
- figuras/: imagens em PNG para reutilizar no documento final.
- Indice_dos_prints_SQL.json: sequência das imagens, intervalos de linhas e hash do SQL.
- Conferencia_da_entrega.txt: verificações desta entrega.

## Como usar no trabalho final

Os capítulos, as figuras, as legendas e os apêndices já estão inseridos no Word. O líder pode incorporar esse conteúdo e ajustar a numeração e as referências ao reunir as demais disciplinas. Os apêndices concentram o material extenso; a conferência do limite de páginas do PIM completo deve considerar também os capítulos das outras matérias.

Os recortes de um modelo são complementares. Uma entidade repetida representa a mesma tabela; caixas com “ref.” apontam para cadastros detalhados em outro recorte. As tabelas legadas são apresentadas separadamente para distinguir a estrutura antiga do fluxo atual de compras e retirada.

As imagens SQL são reproduções diagramadas do código, e não capturas de execução do SSMS. Linhas longas recebem quebra visual; por isso, um intervalo pode terminar e o seguinte começar no mesmo número de linha. A acentuação de mensagens foi normalizada somente nas imagens. O arquivo SQL de execução foi mantido sem alterações. Não houve omissão de instruções na sequência.

O SQL destina-se à criação da estrutura em um banco novo no SQL Server, usando modo SQLCMD no SSMS. Ele interrompe a execução se o banco de destino já existir. Não é necessário executá-lo no banco atual para usar esta documentação. Não contém usuários, senhas ou vendas exportadas; contém apenas a estrutura e as categorias iniciais. O banco e as aplicações não foram alterados nesta revisão documental.
