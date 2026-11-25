-- UNIDUNI PIM IV - SCRIPT COMPLETO DO BANCO DE DADOS
-- Estrutura exportada da base uniduni e documentada como evolucao do PIM III.
-- 17 tabelas: 11 do nucleo atual e 6 legadas preservadas.
-- Inclui chaves, restricoes, indices, procedure e trigger. Nao inclui dados pessoais.
-- Executar no SSMS com Modo SQLCMD ativado, ou pelo utilitario sqlcmd.
-- O script NAO apaga bancos: interrompe se o destino ja existir.
:On Error exit
:setvar BancoDestino "uniduni"
USE [master];
GO
IF DB_ID(N'$(BancoDestino)') IS NOT NULL THROW 51000, 'O banco de destino ja existe. Escolha um banco novo e vazio.', 1;
GO
CREATE DATABASE [$(BancoDestino)] COLLATE Latin1_General_CI_AS;
GO
USE [$(BancoDestino)];
GO
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
SET XACT_ABORT ON;
GO
CREATE TABLE [dbo].[Carrinho] (
    [Id] INT IDENTITY(1,1) NOT NULL,
    [UsuarioId] INT NULL,
    [Ativo] BIT NULL CONSTRAINT [DF__Carrinho__Ativo__5535A963] DEFAULT ((1)),
    CONSTRAINT [PK__Carrinho__3214EC0766EF4C7D] PRIMARY KEY CLUSTERED ([Id] ASC)
);
GO
CREATE TABLE [dbo].[CarrinhoItens] (
    [Id] INT IDENTITY(1,1) NOT NULL,
    [CarrinhoId] INT NULL,
    [ProdutoId] INT NULL,
    [Quantidade] INT NULL,
    CONSTRAINT [PK__Carrinho__3214EC077C6320F4] PRIMARY KEY CLUSTERED ([Id] ASC)
);
GO
CREATE TABLE [dbo].[CarrinhoItensLoja] (
    [UsuarioId] INT NOT NULL,
    [VariacaoId] INT NOT NULL,
    [Quantidade] INT NOT NULL,
    CONSTRAINT [PK_CarrinhoItensLoja] PRIMARY KEY CLUSTERED ([UsuarioId] ASC, [VariacaoId] ASC)
);
GO
CREATE TABLE [dbo].[Categorias] (
    [Id] INT IDENTITY(1,1) NOT NULL,
    [Nome] NVARCHAR(50) COLLATE Latin1_General_CI_AS NULL,
    [Descricao] NVARCHAR(100) COLLATE Latin1_General_CI_AS NULL,
    CONSTRAINT [PK__Categori__3214EC07C2CFF941] PRIMARY KEY CLUSTERED ([Id] ASC)
);
GO
CREATE TABLE [dbo].[Enderecos] (
    [Id] INT IDENTITY(1,1) NOT NULL,
    [UsuarioId] INT NULL,
    [Rua] NVARCHAR(100) COLLATE Latin1_General_CI_AS NULL,
    [Numero] NVARCHAR(10) COLLATE Latin1_General_CI_AS NULL,
    [Bairro] NVARCHAR(50) COLLATE Latin1_General_CI_AS NULL,
    [Cidade] NVARCHAR(50) COLLATE Latin1_General_CI_AS NULL,
    [Estado] NVARCHAR(50) COLLATE Latin1_General_CI_AS NULL,
    [CEP] NVARCHAR(10) COLLATE Latin1_General_CI_AS NULL,
    CONSTRAINT [PK__Endereco__3214EC07678581F4] PRIMARY KEY CLUSTERED ([Id] ASC)
);
GO
CREATE TABLE [dbo].[EventosPedidoLoja] (
    [Id] INT IDENTITY(1,1) NOT NULL,
    [PedidoId] INT NOT NULL,
    [UsuarioId] INT NULL,
    [Descricao] NVARCHAR(250) COLLATE Latin1_General_CI_AS NOT NULL,
    [CriadoEm] DATETIME2(7) NOT NULL,
    CONSTRAINT [PK__EventosP__3214EC07BC3A6B6F] PRIMARY KEY CLUSTERED ([Id] ASC)
);
GO
CREATE TABLE [dbo].[ItensPedidoLoja] (
    [Id] INT IDENTITY(1,1) NOT NULL,
    [PedidoId] INT NOT NULL,
    [VariacaoId] INT NOT NULL,
    [Nome] NVARCHAR(100) COLLATE Latin1_General_CI_AS NOT NULL,
    [Cor] NVARCHAR(40) COLLATE Latin1_General_CI_AS NOT NULL,
    [Tamanho] NVARCHAR(20) COLLATE Latin1_General_CI_AS NOT NULL,
    [Imagem] NVARCHAR(255) COLLATE Latin1_General_CI_AS NOT NULL,
    [Quantidade] INT NOT NULL,
    [PrecoUnitario] DECIMAL(10,2) NOT NULL,
    CONSTRAINT [PK__ItensPed__3214EC07BEA39B20] PRIMARY KEY CLUSTERED ([Id] ASC),
    CONSTRAINT [UQ_ItensPedidoLoja] UNIQUE NONCLUSTERED ([PedidoId] ASC, [VariacaoId] ASC)
);
GO
CREATE TABLE [dbo].[MovimentacoesEstoque] (
    [Id] BIGINT IDENTITY(1,1) NOT NULL,
    [VariacaoId] INT NOT NULL,
    [UsuarioId] INT NULL,
    [Responsavel] NVARCHAR(100) COLLATE Latin1_General_CI_AS NOT NULL,
    [Tipo] NVARCHAR(20) COLLATE Latin1_General_CI_AS NOT NULL,
    [Quantidade] INT NOT NULL,
    [SaldoAnterior] INT NOT NULL,
    [SaldoAtual] INT NOT NULL,
    [Justificativa] NVARCHAR(250) COLLATE Latin1_General_CI_AS NOT NULL,
    [OperacaoId] UNIQUEIDENTIFIER NOT NULL,
    [CriadaEm] DATETIME2(7) NOT NULL CONSTRAINT [DF_Movimentacao_Data] DEFAULT (sysutcdatetime()),
    [ReservadoAnterior] INT NOT NULL CONSTRAINT [DF_Mov_ReservadoAnterior] DEFAULT ((0)),
    [ReservadoAtual] INT NOT NULL CONSTRAINT [DF_Mov_ReservadoAtual] DEFAULT ((0)),
    CONSTRAINT [PK__Moviment__3214EC0793A42290] PRIMARY KEY CLUSTERED ([Id] ASC),
    CONSTRAINT [UQ_Movimentacao_Operacao] UNIQUE NONCLUSTERED ([OperacaoId] ASC)
);
GO
CREATE TABLE [dbo].[Pagamentos] (
    [Id] INT IDENTITY(1,1) NOT NULL,
    [PedidoId] INT NULL,
    [Metodo] NVARCHAR(50) COLLATE Latin1_General_CI_AS NULL,
    [Status] NVARCHAR(50) COLLATE Latin1_General_CI_AS NULL,
    [Valor] DECIMAL(10,2) NULL,
    [DataPagamento] DATETIME NULL CONSTRAINT [DF__Pagamento__DataP__6477ECF3] DEFAULT (getdate()),
    CONSTRAINT [PK__Pagament__3214EC07932C70F5] PRIMARY KEY CLUSTERED ([Id] ASC)
);
GO
CREATE TABLE [dbo].[PagamentosSimulados] (
    [Id] INT IDENTITY(1,1) NOT NULL,
    [PedidoId] INT NOT NULL,
    [OperacaoId] UNIQUEIDENTIFIER NOT NULL,
    [Metodo] NVARCHAR(10) COLLATE Latin1_General_CI_AS NOT NULL,
    [ResultadoSolicitado] NVARCHAR(15) COLLATE Latin1_General_CI_AS NOT NULL,
    [Status] NVARCHAR(15) COLLATE Latin1_General_CI_AS NOT NULL,
    [Valor] DECIMAL(12,2) NOT NULL,
    [CriadoEm] DATETIME2(7) NOT NULL,
    [AtualizadoEm] DATETIME2(7) NOT NULL,
    CONSTRAINT [PK__Pagament__3214EC07106AC07A] PRIMARY KEY CLUSTERED ([Id] ASC),
    CONSTRAINT [UQ_PagamentoSimulado_Operacao] UNIQUE NONCLUSTERED ([PedidoId] ASC, [OperacaoId] ASC)
);
GO
CREATE TABLE [dbo].[PedidoItens] (
    [Id] INT IDENTITY(1,1) NOT NULL,
    [PedidoId] INT NULL,
    [ProdutoId] INT NULL,
    [Quantidade] INT NULL,
    [PrecoUnitario] DECIMAL(10,2) NULL,
    CONSTRAINT [PK__PedidoIt__3214EC07E8DE821D] PRIMARY KEY CLUSTERED ([Id] ASC)
);
GO
CREATE TABLE [dbo].[Pedidos] (
    [Id] INT IDENTITY(1,1) NOT NULL,
    [UsuarioId] INT NULL,
    [DataPedido] DATETIME NULL CONSTRAINT [DF__Pedidos__DataPed__5CD6CB2B] DEFAULT (getdate()),
    [Status] NVARCHAR(50) COLLATE Latin1_General_CI_AS NULL,
    [Total] DECIMAL(10,2) NULL,
    CONSTRAINT [PK__Pedidos__3214EC07C611D8C6] PRIMARY KEY CLUSTERED ([Id] ASC)
);
GO
CREATE TABLE [dbo].[PedidosLoja] (
    [Id] INT IDENTITY(1,1) NOT NULL,
    [UsuarioId] INT NOT NULL,
    [OperacaoId] UNIQUEIDENTIFIER NOT NULL,
    [Status] NVARCHAR(30) COLLATE Latin1_General_CI_AS NOT NULL,
    [Total] DECIMAL(12,2) NOT NULL,
    [CriadoEm] DATETIME2(7) NOT NULL,
    [ReservaAte] DATETIME2(7) NULL,
    [PagoEm] DATETIME2(7) NULL,
    [CanceladoEm] DATETIME2(7) NULL,
    [CodigoRetirada] VARCHAR(12) COLLATE Latin1_General_CI_AS NOT NULL,
    [RetiradoEm] DATETIME2(7) NULL,
    [RetiradoPor] INT NULL,
    CONSTRAINT [PK__PedidosL__3214EC07718C5D7D] PRIMARY KEY CLUSTERED ([Id] ASC),
    CONSTRAINT [UQ_PedidosLoja_Operacao] UNIQUE NONCLUSTERED ([UsuarioId] ASC, [OperacaoId] ASC)
);
GO
CREATE TABLE [dbo].[Produtos] (
    [Id] INT IDENTITY(1,1) NOT NULL,
    [Nome] NVARCHAR(100) COLLATE Latin1_General_CI_AS NULL,
    [Descricao] NVARCHAR(500) COLLATE Latin1_General_CI_AS NULL,
    [Preco] DECIMAL(10,2) NULL,
    [Estoque] INT NULL,
    [Tamanho] NVARCHAR(5) COLLATE Latin1_General_CI_AS NULL,
    [Genero] NVARCHAR(10) COLLATE Latin1_General_CI_AS NULL,
    [Imagem] NVARCHAR(255) COLLATE Latin1_General_CI_AS NULL,
    [CategoriaId] INT NULL,
    [Ativo] BIT NOT NULL CONSTRAINT [DF_Produtos_Ativo] DEFAULT ((1)),
    [GuiaMedidas] NVARCHAR(500) COLLATE Latin1_General_CI_AS NOT NULL CONSTRAINT [DF_Produtos_Guia] DEFAULT (N''),
    CONSTRAINT [PK__Produtos__3214EC073A67475A] PRIMARY KEY CLUSTERED ([Id] ASC)
);
GO
CREATE TABLE [dbo].[ProdutoVariacoes] (
    [Id] INT IDENTITY(1,1) NOT NULL,
    [ProdutoId] INT NOT NULL,
    [Cor] NVARCHAR(40) COLLATE Latin1_General_CI_AS NOT NULL,
    [Tamanho] NVARCHAR(20) COLLATE Latin1_General_CI_AS NOT NULL,
    [Estoque] INT NOT NULL CONSTRAINT [DF_Variacoes_Estoque] DEFAULT ((0)),
    [Reservado] INT NOT NULL CONSTRAINT [DF_Variacoes_Reservado] DEFAULT ((0)),
    [EstoqueMinimo] INT NOT NULL CONSTRAINT [DF_Variacoes_Minimo] DEFAULT ((3)),
    [Ativo] BIT NOT NULL CONSTRAINT [DF_Variacoes_Ativo] DEFAULT ((1)),
    [Versao] ROWVERSION NOT NULL,
    CONSTRAINT [PK__ProdutoV__3214EC07EEC20BD4] PRIMARY KEY CLUSTERED ([Id] ASC),
    CONSTRAINT [UQ_Variacoes_ProdutoCorTamanho] UNIQUE NONCLUSTERED ([ProdutoId] ASC, [Cor] ASC, [Tamanho] ASC)
);
GO
CREATE TABLE [dbo].[Sessoes] (
    [Id] INT IDENTITY(1,1) NOT NULL,
    [UsuarioId] INT NOT NULL,
    [TokenHash] CHAR(64) COLLATE Latin1_General_CI_AS NOT NULL,
    [CriadaEm] DATETIME2(7) NOT NULL,
    [ExpiraEm] DATETIME2(7) NOT NULL,
    CONSTRAINT [PK__Sessoes__3214EC0717900086] PRIMARY KEY CLUSTERED ([Id] ASC),
    CONSTRAINT [UQ_Sessoes_TokenHash] UNIQUE NONCLUSTERED ([TokenHash] ASC)
);
GO
CREATE TABLE [dbo].[Usuarios] (
    [Id] INT IDENTITY(1,1) NOT NULL,
    [Nome] NVARCHAR(100) COLLATE Latin1_General_CI_AS NULL,
    [Email] NVARCHAR(100) COLLATE Latin1_General_CI_AS NULL,
    [Senha] NVARCHAR(255) COLLATE Latin1_General_CI_AS NULL,
    [Telefone] NVARCHAR(20) COLLATE Latin1_General_CI_AS NULL,
    [TipoUsuario] NVARCHAR(20) COLLATE Latin1_General_CI_AS NULL,
    [Ativo] BIT NOT NULL CONSTRAINT [DF_Usuarios_Ativo] DEFAULT ((1)),
    CONSTRAINT [PK__Usuarios__3214EC075C676586] PRIMARY KEY CLUSTERED ([Id] ASC),
    CONSTRAINT [UQ__Usuarios__A9D105348E3A373C] UNIQUE NONCLUSTERED ([Email] ASC)
);
GO
ALTER TABLE [dbo].[Carrinho] WITH CHECK ADD CONSTRAINT [FK__Carrinho__Usuari__5629CD9C] FOREIGN KEY ([UsuarioId]) REFERENCES [dbo].[Usuarios] ([Id]);
GO
ALTER TABLE [dbo].[CarrinhoItens] WITH CHECK ADD CONSTRAINT [FK__CarrinhoI__Carri__59063A47] FOREIGN KEY ([CarrinhoId]) REFERENCES [dbo].[Carrinho] ([Id]);
GO
ALTER TABLE [dbo].[CarrinhoItens] WITH CHECK ADD CONSTRAINT [FK__CarrinhoI__Produ__59FA5E80] FOREIGN KEY ([ProdutoId]) REFERENCES [dbo].[Produtos] ([Id]);
GO
ALTER TABLE [dbo].[CarrinhoItensLoja] WITH CHECK ADD CONSTRAINT [CK__CarrinhoI__Quant__0B91BA14] CHECK ([Quantidade]>=(1) AND [Quantidade]<=(99));
GO
ALTER TABLE [dbo].[CarrinhoItensLoja] WITH CHECK ADD CONSTRAINT [FK__CarrinhoI__Usuar__09A971A2] FOREIGN KEY ([UsuarioId]) REFERENCES [dbo].[Usuarios] ([Id]);
GO
ALTER TABLE [dbo].[CarrinhoItensLoja] WITH CHECK ADD CONSTRAINT [FK__CarrinhoI__Varia__0A9D95DB] FOREIGN KEY ([VariacaoId]) REFERENCES [dbo].[ProdutoVariacoes] ([Id]);
GO
ALTER TABLE [dbo].[Enderecos] WITH CHECK ADD CONSTRAINT [FK__Enderecos__Usuar__4D94879B] FOREIGN KEY ([UsuarioId]) REFERENCES [dbo].[Usuarios] ([Id]);
GO
ALTER TABLE [dbo].[EventosPedidoLoja] WITH CHECK ADD CONSTRAINT [FK__EventosPe__Pedid__236943A5] FOREIGN KEY ([PedidoId]) REFERENCES [dbo].[PedidosLoja] ([Id]);
GO
ALTER TABLE [dbo].[EventosPedidoLoja] WITH CHECK ADD CONSTRAINT [FK__EventosPe__Usuar__245D67DE] FOREIGN KEY ([UsuarioId]) REFERENCES [dbo].[Usuarios] ([Id]);
GO
ALTER TABLE [dbo].[ItensPedidoLoja] WITH CHECK ADD CONSTRAINT [CK__ItensPedi__Quant__17F790F9] CHECK ([Quantidade]>=(1) AND [Quantidade]<=(99));
GO
ALTER TABLE [dbo].[ItensPedidoLoja] WITH CHECK ADD CONSTRAINT [CK__ItensPedi__Preco__18EBB532] CHECK ([PrecoUnitario]>(0));
GO
ALTER TABLE [dbo].[ItensPedidoLoja] WITH CHECK ADD CONSTRAINT [FK__ItensPedi__Pedid__160F4887] FOREIGN KEY ([PedidoId]) REFERENCES [dbo].[PedidosLoja] ([Id]);
GO
ALTER TABLE [dbo].[ItensPedidoLoja] WITH CHECK ADD CONSTRAINT [FK__ItensPedi__Varia__17036CC0] FOREIGN KEY ([VariacaoId]) REFERENCES [dbo].[ProdutoVariacoes] ([Id]);
GO
ALTER TABLE [dbo].[MovimentacoesEstoque] WITH CHECK ADD CONSTRAINT [CK_Movimentacao_Saldos] CHECK ([SaldoAnterior]>=(0) AND [SaldoAtual]>=(0));
GO
ALTER TABLE [dbo].[MovimentacoesEstoque] WITH CHECK ADD CONSTRAINT [CK_Movimentacao_Tipo] CHECK ([Tipo]=N'Estorno' OR [Tipo]=N'Venda' OR [Tipo]=N'Liberacao' OR [Tipo]=N'Reserva' OR [Tipo]=N'Ajuste' OR [Tipo]=N'Entrada' OR [Tipo]=N'Inicial');
GO
ALTER TABLE [dbo].[MovimentacoesEstoque] WITH CHECK ADD CONSTRAINT [FK__Movimenta__Varia__01142BA1] FOREIGN KEY ([VariacaoId]) REFERENCES [dbo].[ProdutoVariacoes] ([Id]);
GO
ALTER TABLE [dbo].[MovimentacoesEstoque] WITH CHECK ADD CONSTRAINT [FK__Movimenta__Usuar__02084FDA] FOREIGN KEY ([UsuarioId]) REFERENCES [dbo].[Usuarios] ([Id]);
GO
CREATE NONCLUSTERED INDEX [IX_Movimentacoes_VariacaoData] ON [dbo].[MovimentacoesEstoque] ([VariacaoId] ASC, [CriadaEm] DESC);
GO
ALTER TABLE [dbo].[Pagamentos] WITH CHECK ADD CONSTRAINT [FK__Pagamento__Pedid__656C112C] FOREIGN KEY ([PedidoId]) REFERENCES [dbo].[Pedidos] ([Id]);
GO
ALTER TABLE [dbo].[PagamentosSimulados] WITH CHECK ADD CONSTRAINT [CK__Pagamento__Metod__1DB06A4F] CHECK ([Metodo]=N'Cartao' OR [Metodo]=N'Pix');
GO
ALTER TABLE [dbo].[PagamentosSimulados] WITH CHECK ADD CONSTRAINT [CK__Pagamento__Resul__1EA48E88] CHECK ([ResultadoSolicitado]=N'Pendente' OR [ResultadoSolicitado]=N'Recusado' OR [ResultadoSolicitado]=N'Aprovado');
GO
ALTER TABLE [dbo].[PagamentosSimulados] WITH CHECK ADD CONSTRAINT [CK__Pagamento__Statu__1F98B2C1] CHECK ([Status]=N'Estornado' OR [Status]=N'Expirado' OR [Status]=N'Cancelado' OR [Status]=N'Pendente' OR [Status]=N'Recusado' OR [Status]=N'Aprovado');
GO
ALTER TABLE [dbo].[PagamentosSimulados] WITH CHECK ADD CONSTRAINT [CK__Pagamento__Valor__208CD6FA] CHECK ([Valor]>(0));
GO
ALTER TABLE [dbo].[PagamentosSimulados] WITH CHECK ADD CONSTRAINT [FK__Pagamento__Pedid__1CBC4616] FOREIGN KEY ([PedidoId]) REFERENCES [dbo].[PedidosLoja] ([Id]);
GO
ALTER TABLE [dbo].[PedidoItens] WITH CHECK ADD CONSTRAINT [FK__PedidoIte__Pedid__60A75C0F] FOREIGN KEY ([PedidoId]) REFERENCES [dbo].[Pedidos] ([Id]);
GO
ALTER TABLE [dbo].[PedidoItens] WITH CHECK ADD CONSTRAINT [FK__PedidoIte__Produ__619B8048] FOREIGN KEY ([ProdutoId]) REFERENCES [dbo].[Produtos] ([Id]);
GO
ALTER TABLE [dbo].[Pedidos] WITH CHECK ADD CONSTRAINT [FK__Pedidos__Usuario__5DCAEF64] FOREIGN KEY ([UsuarioId]) REFERENCES [dbo].[Usuarios] ([Id]);
GO
ALTER TABLE [dbo].[PedidosLoja] WITH CHECK ADD CONSTRAINT [CK__PedidosLo__Total__10566F31] CHECK ([Total]>(0));
GO
ALTER TABLE [dbo].[PedidosLoja] WITH CHECK ADD CONSTRAINT [CK_PedidosLoja_Status] CHECK ([Status]=N'Expirado' OR [Status]=N'Cancelado' OR [Status]=N'Retirado' OR [Status]=N'Pronto' OR [Status]=N'EmPreparacao' OR [Status]=N'Pago' OR [Status]=N'Recusado' OR [Status]=N'Pendente');
GO
ALTER TABLE [dbo].[PedidosLoja] WITH CHECK ADD CONSTRAINT [FK__PedidosLo__Usuar__0F624AF8] FOREIGN KEY ([UsuarioId]) REFERENCES [dbo].[Usuarios] ([Id]);
GO
ALTER TABLE [dbo].[PedidosLoja] WITH CHECK ADD CONSTRAINT [FK__PedidosLo__Retir__114A936A] FOREIGN KEY ([RetiradoPor]) REFERENCES [dbo].[Usuarios] ([Id]);
GO
CREATE NONCLUSTERED INDEX [IX_PedidosLoja_Reserva] ON [dbo].[PedidosLoja] ([Status] ASC, [ReservaAte] ASC);
GO
CREATE NONCLUSTERED INDEX [IX_PedidosLoja_Usuario] ON [dbo].[PedidosLoja] ([UsuarioId] ASC, [Id] DESC);
GO
ALTER TABLE [dbo].[Produtos] WITH CHECK ADD CONSTRAINT [FK__Produtos__Catego__52593CB8] FOREIGN KEY ([CategoriaId]) REFERENCES [dbo].[Categorias] ([Id]);
GO
ALTER TABLE [dbo].[ProdutoVariacoes] WITH CHECK ADD CONSTRAINT [CK_Variacoes_Saldos] CHECK ([Estoque]>=(0) AND [Reservado]>=(0) AND [Reservado]<=[Estoque] AND [EstoqueMinimo]>=(0));
GO
ALTER TABLE [dbo].[ProdutoVariacoes] WITH CHECK ADD CONSTRAINT [FK__ProdutoVa__Produ__787EE5A0] FOREIGN KEY ([ProdutoId]) REFERENCES [dbo].[Produtos] ([Id]);
GO
ALTER TABLE [dbo].[Sessoes] WITH CHECK ADD CONSTRAINT [FK__Sessoes__Usuario__72C60C4A] FOREIGN KEY ([UsuarioId]) REFERENCES [dbo].[Usuarios] ([Id]);
GO
CREATE NONCLUSTERED INDEX [IX_Sessoes_UsuarioId] ON [dbo].[Sessoes] ([UsuarioId] ASC);
GO
CREATE NONCLUSTERED INDEX [IX_Sessoes_ExpiraEm] ON [dbo].[Sessoes] ([ExpiraEm] ASC);
GO
ALTER TABLE [dbo].[Usuarios] WITH CHECK ADD CONSTRAINT [CK_Usuarios_Perfil] CHECK ([TipoUsuario]=N'Administrador' OR [TipoUsuario]=N'Funcionario' OR [TipoUsuario]=N'Cliente');
GO
SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO
-- MovimentaÃ§Ã£o manual preserva tambÃ©m os valores da reserva no histÃ³rico.
CREATE   PROCEDURE dbo.usp_MovimentarEstoque
    @VariacaoId INT, @UsuarioId INT, @Tipo NVARCHAR(20), @Quantidade INT,
    @Justificativa NVARCHAR(250), @OperacaoId UNIQUEIDENTIFIER, @VersaoEsperada VARBINARY(8)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    BEGIN TRY
        BEGIN TRANSACTION;
        DECLARE @Responsavel NVARCHAR(100),@Atual INT,@Reservado INT,@Novo BIGINT,@Versao BINARY(8);
        SELECT @Responsavel=Nome FROM dbo.Usuarios WHERE Id=@UsuarioId AND Ativo=1 AND TipoUsuario IN(N'Funcionario',N'Administrador');
        IF @Responsavel IS NULL THROW 51003,'Acesso ao estoque nÃ£o permitido.',1;
        IF @Tipo IS NULL OR @Tipo NOT IN(N'Entrada',N'Ajuste') OR @Quantidade IS NULL OR @Quantidade<0 OR @Quantidade>1000000
            OR @Justificativa IS NULL OR LEN(LTRIM(RTRIM(@Justificativa)))<5 OR @OperacaoId IS NULL
            THROW 51000,'Informe operaÃ§Ã£o, quantidade e justificativa vÃ¡lidas.',1;

        IF EXISTS(SELECT 1 FROM dbo.MovimentacoesEstoque WITH(UPDLOCK,HOLDLOCK) WHERE OperacaoId=@OperacaoId)
        BEGIN
            IF NOT EXISTS(SELECT 1 FROM dbo.MovimentacoesEstoque WHERE OperacaoId=@OperacaoId AND VariacaoId=@VariacaoId AND UsuarioId=@UsuarioId
                AND Tipo=@Tipo AND (CASE WHEN @Tipo=N'Entrada' THEN Quantidade ELSE SaldoAtual END)=@Quantidade AND Justificativa=@Justificativa)
                THROW 51009,'O identificador da operaÃ§Ã£o jÃ¡ foi utilizado com outros dados.',1;
            COMMIT;
            SELECT Id FROM dbo.MovimentacoesEstoque WHERE OperacaoId=@OperacaoId;
            RETURN;
        END;
        SELECT @Atual=v.Estoque,@Reservado=v.Reservado,@Versao=v.Versao
        FROM dbo.ProdutoVariacoes v WITH(UPDLOCK,HOLDLOCK) JOIN dbo.Produtos p ON p.Id=v.ProdutoId
        WHERE v.Id=@VariacaoId AND v.Ativo=1 AND p.Ativo=1;
        IF @Atual IS NULL THROW 51004,'VariaÃ§Ã£o ativa nÃ£o encontrada.',1;
        IF @VersaoEsperada IS NULL OR @Versao<>@VersaoEsperada THROW 51009,'O estoque foi atualizado por outra operaÃ§Ã£o. Atualize os dados e tente novamente.',1;
        SET @Novo=CASE WHEN @Tipo=N'Entrada' THEN CAST(@Atual AS BIGINT)+@Quantidade ELSE @Quantidade END;
        IF @Novo<@Reservado OR @Novo>2147483647 THROW 51009,'O saldo informado Ã© invÃ¡lido ou menor que a quantidade reservada.',1;
        IF @Novo=@Atual THROW 51000,'A operaÃ§Ã£o nÃ£o altera o estoque.',1;
        UPDATE dbo.ProdutoVariacoes SET Estoque=CAST(@Novo AS INT) WHERE Id=@VariacaoId;
        INSERT INTO dbo.MovimentacoesEstoque(VariacaoId,UsuarioId,Responsavel,Tipo,Quantidade,SaldoAnterior,SaldoAtual,ReservadoAnterior,ReservadoAtual,Justificativa,OperacaoId)
        VALUES(@VariacaoId,@UsuarioId,@Responsavel,@Tipo,CAST(@Novo AS INT)-@Atual,@Atual,CAST(@Novo AS INT),@Reservado,@Reservado,LTRIM(RTRIM(@Justificativa)),@OperacaoId);
        DECLARE @Id BIGINT=CAST(SCOPE_IDENTITY() AS BIGINT);
        COMMIT;
        SELECT @Id AS Id;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT>0 ROLLBACK;
        THROW;
    END CATCH;
END;
GO
SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO
-- O trigger mantém somente o saldo legado agregado. Não registra outra baixa.
CREATE   TRIGGER dbo.trg_Variacoes_TotalProduto
ON dbo.ProdutoVariacoes AFTER INSERT,UPDATE,DELETE
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE p SET Estoque = COALESCE((SELECT SUM(v.Estoque) FROM dbo.ProdutoVariacoes v WHERE v.ProdutoId=p.Id AND v.Ativo=1),0)
    FROM dbo.Produtos p WHERE p.Id IN (SELECT ProdutoId FROM inserted UNION SELECT ProdutoId FROM deleted);
END;
GO
-- Categorias ficticias necessarias ao catalogo; nenhum usuario ou venda e exportado.
INSERT INTO [dbo].[Categorias] ([Nome],[Descricao]) VALUES
(N'Roupas',N'Roupas para bebes'),
(N'Calçados',N'Calçados para bebes'),
(N'Acessórios',N'Acessórios para bebes'),
(N'Kits',N'Conjuntos para bebes');
GO
-- Cadastros de usuarios, produtos e pedidos devem ser realizados pela aplicacao.
-- Senhas sao geradas pela API com hash PBKDF2; nao inserir senhas em texto puro.
