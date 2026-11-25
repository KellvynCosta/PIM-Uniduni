-- UNIDUNI: copia de estrutura destinada exclusivamente a modelagem no Workbench 8.0.
-- Origem: metadados atuais do SQL Server. Nenhuma linha de dados foi exportada.
-- Nao executar na API ou no SQL Server. Importar com Reverse Engineer MySQL Create Script.
-- Adaptacoes: NVARCHAR -> VARCHAR utf8mb4; BIT -> TINYINT(1); GUID -> CHAR(36);
-- DATETIME2(7) -> DATETIME(6); ROWVERSION -> BINARY(8) apenas para representacao.
-- ROWVERSION nao possui aqui o comportamento automatico do SQL Server.
-- Defaults, CHECKs, procedures e triggers nao sao convertidos por este arquivo.
-- Para a implementacao original, consultar o script SQL Server integral.
CREATE SCHEMA IF NOT EXISTS `uniduni_modelo` DEFAULT CHARACTER SET utf8mb4;
USE `uniduni_modelo`;

CREATE TABLE `Carrinho` (
  `Id` INT NOT NULL AUTO_INCREMENT,
  `UsuarioId` INT NULL,
  `Ativo` TINYINT(1) NULL,
  PRIMARY KEY (`Id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE `CarrinhoItens` (
  `Id` INT NOT NULL AUTO_INCREMENT,
  `CarrinhoId` INT NULL,
  `ProdutoId` INT NULL,
  `Quantidade` INT NULL,
  PRIMARY KEY (`Id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE `CarrinhoItensLoja` (
  `UsuarioId` INT NOT NULL,
  `VariacaoId` INT NOT NULL,
  `Quantidade` INT NOT NULL,
  PRIMARY KEY (`UsuarioId`, `VariacaoId`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE `Categorias` (
  `Id` INT NOT NULL AUTO_INCREMENT,
  `Nome` VARCHAR(50) NULL,
  `Descricao` VARCHAR(100) NULL,
  PRIMARY KEY (`Id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE `Enderecos` (
  `Id` INT NOT NULL AUTO_INCREMENT,
  `UsuarioId` INT NULL,
  `Rua` VARCHAR(100) NULL,
  `Numero` VARCHAR(10) NULL,
  `Bairro` VARCHAR(50) NULL,
  `Cidade` VARCHAR(50) NULL,
  `Estado` VARCHAR(50) NULL,
  `CEP` VARCHAR(10) NULL,
  PRIMARY KEY (`Id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE `EventosPedidoLoja` (
  `Id` INT NOT NULL AUTO_INCREMENT,
  `PedidoId` INT NOT NULL,
  `UsuarioId` INT NULL,
  `Descricao` VARCHAR(250) NOT NULL,
  `CriadoEm` DATETIME(6) NOT NULL,
  PRIMARY KEY (`Id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE `ItensPedidoLoja` (
  `Id` INT NOT NULL AUTO_INCREMENT,
  `PedidoId` INT NOT NULL,
  `VariacaoId` INT NOT NULL,
  `Nome` VARCHAR(100) NOT NULL,
  `Cor` VARCHAR(40) NOT NULL,
  `Tamanho` VARCHAR(20) NOT NULL,
  `Imagem` VARCHAR(255) NOT NULL,
  `Quantidade` INT NOT NULL,
  `PrecoUnitario` DECIMAL(10,2) NOT NULL,
  PRIMARY KEY (`Id`),
  CONSTRAINT `UQ_ItensPedidoLoja` UNIQUE (`PedidoId`, `VariacaoId`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE `MovimentacoesEstoque` (
  `Id` BIGINT NOT NULL AUTO_INCREMENT,
  `VariacaoId` INT NOT NULL,
  `UsuarioId` INT NULL,
  `Responsavel` VARCHAR(100) NOT NULL,
  `Tipo` VARCHAR(20) NOT NULL,
  `Quantidade` INT NOT NULL,
  `SaldoAnterior` INT NOT NULL,
  `SaldoAtual` INT NOT NULL,
  `Justificativa` VARCHAR(250) NOT NULL,
  `OperacaoId` CHAR(36) NOT NULL,
  `CriadaEm` DATETIME(6) NOT NULL,
  `ReservadoAnterior` INT NOT NULL,
  `ReservadoAtual` INT NOT NULL,
  PRIMARY KEY (`Id`),
  CONSTRAINT `UQ_Movimentacao_Operacao` UNIQUE (`OperacaoId`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE `Pagamentos` (
  `Id` INT NOT NULL AUTO_INCREMENT,
  `PedidoId` INT NULL,
  `Metodo` VARCHAR(50) NULL,
  `Status` VARCHAR(50) NULL,
  `Valor` DECIMAL(10,2) NULL,
  `DataPagamento` DATETIME NULL,
  PRIMARY KEY (`Id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE `PagamentosSimulados` (
  `Id` INT NOT NULL AUTO_INCREMENT,
  `PedidoId` INT NOT NULL,
  `OperacaoId` CHAR(36) NOT NULL,
  `Metodo` VARCHAR(10) NOT NULL,
  `ResultadoSolicitado` VARCHAR(15) NOT NULL,
  `Status` VARCHAR(15) NOT NULL,
  `Valor` DECIMAL(12,2) NOT NULL,
  `CriadoEm` DATETIME(6) NOT NULL,
  `AtualizadoEm` DATETIME(6) NOT NULL,
  PRIMARY KEY (`Id`),
  CONSTRAINT `UQ_PagamentoSimulado_Operacao` UNIQUE (`PedidoId`, `OperacaoId`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE `PedidoItens` (
  `Id` INT NOT NULL AUTO_INCREMENT,
  `PedidoId` INT NULL,
  `ProdutoId` INT NULL,
  `Quantidade` INT NULL,
  `PrecoUnitario` DECIMAL(10,2) NULL,
  PRIMARY KEY (`Id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE `Pedidos` (
  `Id` INT NOT NULL AUTO_INCREMENT,
  `UsuarioId` INT NULL,
  `DataPedido` DATETIME NULL,
  `Status` VARCHAR(50) NULL,
  `Total` DECIMAL(10,2) NULL,
  PRIMARY KEY (`Id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE `PedidosLoja` (
  `Id` INT NOT NULL AUTO_INCREMENT,
  `UsuarioId` INT NOT NULL,
  `OperacaoId` CHAR(36) NOT NULL,
  `Status` VARCHAR(30) NOT NULL,
  `Total` DECIMAL(12,2) NOT NULL,
  `CriadoEm` DATETIME(6) NOT NULL,
  `ReservaAte` DATETIME(6) NULL,
  `PagoEm` DATETIME(6) NULL,
  `CanceladoEm` DATETIME(6) NULL,
  `CodigoRetirada` VARCHAR(12) NOT NULL,
  `RetiradoEm` DATETIME(6) NULL,
  `RetiradoPor` INT NULL,
  PRIMARY KEY (`Id`),
  CONSTRAINT `UQ_PedidosLoja_Operacao` UNIQUE (`UsuarioId`, `OperacaoId`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE `Produtos` (
  `Id` INT NOT NULL AUTO_INCREMENT,
  `Nome` VARCHAR(100) NULL,
  `Descricao` VARCHAR(500) NULL,
  `Preco` DECIMAL(10,2) NULL,
  `Estoque` INT NULL,
  `Tamanho` VARCHAR(5) NULL,
  `Genero` VARCHAR(10) NULL,
  `Imagem` VARCHAR(255) NULL,
  `CategoriaId` INT NULL,
  `Ativo` TINYINT(1) NOT NULL,
  `GuiaMedidas` VARCHAR(500) NOT NULL,
  PRIMARY KEY (`Id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE `ProdutoVariacoes` (
  `Id` INT NOT NULL AUTO_INCREMENT,
  `ProdutoId` INT NOT NULL,
  `Cor` VARCHAR(40) NOT NULL,
  `Tamanho` VARCHAR(20) NOT NULL,
  `Estoque` INT NOT NULL,
  `Reservado` INT NOT NULL,
  `EstoqueMinimo` INT NOT NULL,
  `Ativo` TINYINT(1) NOT NULL,
  `Versao` BINARY(8) NOT NULL COMMENT 'Origem SQL Server ROWVERSION: representacao sem incremento automatico',
  PRIMARY KEY (`Id`),
  CONSTRAINT `UQ_Variacoes_ProdutoCorTamanho` UNIQUE (`ProdutoId`, `Cor`, `Tamanho`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE `Sessoes` (
  `Id` INT NOT NULL AUTO_INCREMENT,
  `UsuarioId` INT NOT NULL,
  `TokenHash` CHAR(64) NOT NULL,
  `CriadaEm` DATETIME(6) NOT NULL,
  `ExpiraEm` DATETIME(6) NOT NULL,
  PRIMARY KEY (`Id`),
  CONSTRAINT `UQ_Sessoes_TokenHash` UNIQUE (`TokenHash`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE `Usuarios` (
  `Id` INT NOT NULL AUTO_INCREMENT,
  `Nome` VARCHAR(100) NULL,
  `Email` VARCHAR(100) NULL,
  `Senha` VARCHAR(255) NULL,
  `Telefone` VARCHAR(20) NULL,
  `TipoUsuario` VARCHAR(20) NULL,
  `Ativo` TINYINT(1) NOT NULL,
  PRIMARY KEY (`Id`),
  CONSTRAINT `UQ__Usuarios__A9D105348E3A373C` UNIQUE (`Email`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

ALTER TABLE `Carrinho` ADD CONSTRAINT `FK__Carrinho__Usuari__5629CD9C` FOREIGN KEY (`UsuarioId`) REFERENCES `Usuarios` (`Id`) ON DELETE NO ACTION ON UPDATE NO ACTION;
ALTER TABLE `CarrinhoItens` ADD CONSTRAINT `FK__CarrinhoI__Carri__59063A47` FOREIGN KEY (`CarrinhoId`) REFERENCES `Carrinho` (`Id`) ON DELETE NO ACTION ON UPDATE NO ACTION;
ALTER TABLE `CarrinhoItens` ADD CONSTRAINT `FK__CarrinhoI__Produ__59FA5E80` FOREIGN KEY (`ProdutoId`) REFERENCES `Produtos` (`Id`) ON DELETE NO ACTION ON UPDATE NO ACTION;
ALTER TABLE `CarrinhoItensLoja` ADD CONSTRAINT `FK__CarrinhoI__Usuar__09A971A2` FOREIGN KEY (`UsuarioId`) REFERENCES `Usuarios` (`Id`) ON DELETE NO ACTION ON UPDATE NO ACTION;
ALTER TABLE `CarrinhoItensLoja` ADD CONSTRAINT `FK__CarrinhoI__Varia__0A9D95DB` FOREIGN KEY (`VariacaoId`) REFERENCES `ProdutoVariacoes` (`Id`) ON DELETE NO ACTION ON UPDATE NO ACTION;
ALTER TABLE `Enderecos` ADD CONSTRAINT `FK__Enderecos__Usuar__4D94879B` FOREIGN KEY (`UsuarioId`) REFERENCES `Usuarios` (`Id`) ON DELETE NO ACTION ON UPDATE NO ACTION;
ALTER TABLE `EventosPedidoLoja` ADD CONSTRAINT `FK__EventosPe__Pedid__236943A5` FOREIGN KEY (`PedidoId`) REFERENCES `PedidosLoja` (`Id`) ON DELETE NO ACTION ON UPDATE NO ACTION;
ALTER TABLE `EventosPedidoLoja` ADD CONSTRAINT `FK__EventosPe__Usuar__245D67DE` FOREIGN KEY (`UsuarioId`) REFERENCES `Usuarios` (`Id`) ON DELETE NO ACTION ON UPDATE NO ACTION;
ALTER TABLE `ItensPedidoLoja` ADD CONSTRAINT `FK__ItensPedi__Pedid__160F4887` FOREIGN KEY (`PedidoId`) REFERENCES `PedidosLoja` (`Id`) ON DELETE NO ACTION ON UPDATE NO ACTION;
ALTER TABLE `ItensPedidoLoja` ADD CONSTRAINT `FK__ItensPedi__Varia__17036CC0` FOREIGN KEY (`VariacaoId`) REFERENCES `ProdutoVariacoes` (`Id`) ON DELETE NO ACTION ON UPDATE NO ACTION;
ALTER TABLE `MovimentacoesEstoque` ADD CONSTRAINT `FK__Movimenta__Varia__01142BA1` FOREIGN KEY (`VariacaoId`) REFERENCES `ProdutoVariacoes` (`Id`) ON DELETE NO ACTION ON UPDATE NO ACTION;
ALTER TABLE `MovimentacoesEstoque` ADD CONSTRAINT `FK__Movimenta__Usuar__02084FDA` FOREIGN KEY (`UsuarioId`) REFERENCES `Usuarios` (`Id`) ON DELETE NO ACTION ON UPDATE NO ACTION;
ALTER TABLE `Pagamentos` ADD CONSTRAINT `FK__Pagamento__Pedid__656C112C` FOREIGN KEY (`PedidoId`) REFERENCES `Pedidos` (`Id`) ON DELETE NO ACTION ON UPDATE NO ACTION;
ALTER TABLE `PagamentosSimulados` ADD CONSTRAINT `FK__Pagamento__Pedid__1CBC4616` FOREIGN KEY (`PedidoId`) REFERENCES `PedidosLoja` (`Id`) ON DELETE NO ACTION ON UPDATE NO ACTION;
ALTER TABLE `PedidoItens` ADD CONSTRAINT `FK__PedidoIte__Pedid__60A75C0F` FOREIGN KEY (`PedidoId`) REFERENCES `Pedidos` (`Id`) ON DELETE NO ACTION ON UPDATE NO ACTION;
ALTER TABLE `PedidoItens` ADD CONSTRAINT `FK__PedidoIte__Produ__619B8048` FOREIGN KEY (`ProdutoId`) REFERENCES `Produtos` (`Id`) ON DELETE NO ACTION ON UPDATE NO ACTION;
ALTER TABLE `Pedidos` ADD CONSTRAINT `FK__Pedidos__Usuario__5DCAEF64` FOREIGN KEY (`UsuarioId`) REFERENCES `Usuarios` (`Id`) ON DELETE NO ACTION ON UPDATE NO ACTION;
ALTER TABLE `PedidosLoja` ADD CONSTRAINT `FK__PedidosLo__Usuar__0F624AF8` FOREIGN KEY (`UsuarioId`) REFERENCES `Usuarios` (`Id`) ON DELETE NO ACTION ON UPDATE NO ACTION;
ALTER TABLE `PedidosLoja` ADD CONSTRAINT `FK__PedidosLo__Retir__114A936A` FOREIGN KEY (`RetiradoPor`) REFERENCES `Usuarios` (`Id`) ON DELETE NO ACTION ON UPDATE NO ACTION;
ALTER TABLE `Produtos` ADD CONSTRAINT `FK__Produtos__Catego__52593CB8` FOREIGN KEY (`CategoriaId`) REFERENCES `Categorias` (`Id`) ON DELETE NO ACTION ON UPDATE NO ACTION;
ALTER TABLE `ProdutoVariacoes` ADD CONSTRAINT `FK__ProdutoVa__Produ__787EE5A0` FOREIGN KEY (`ProdutoId`) REFERENCES `Produtos` (`Id`) ON DELETE NO ACTION ON UPDATE NO ACTION;
ALTER TABLE `Sessoes` ADD CONSTRAINT `FK__Sessoes__Usuario__72C60C4A` FOREIGN KEY (`UsuarioId`) REFERENCES `Usuarios` (`Id`) ON DELETE NO ACTION ON UPDATE NO ACTION;
