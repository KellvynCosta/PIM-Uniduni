-- Executar depois das migrações 001 e 002. Preserva as tabelas legadas do PIM III.
USE [uniduni];
GO
SET XACT_ABORT ON;
BEGIN TRANSACTION;
IF OBJECT_ID('dbo.CarrinhoItensLoja','U') IS NULL
CREATE TABLE dbo.CarrinhoItensLoja(
 UsuarioId INT NOT NULL REFERENCES dbo.Usuarios(Id),
 VariacaoId INT NOT NULL REFERENCES dbo.ProdutoVariacoes(Id),
 Quantidade INT NOT NULL CHECK(Quantidade BETWEEN 1 AND 99),
 CONSTRAINT PK_CarrinhoItensLoja PRIMARY KEY(UsuarioId,VariacaoId)
);
IF OBJECT_ID('dbo.PedidosLoja','U') IS NULL
BEGIN
 CREATE TABLE dbo.PedidosLoja(
 Id INT IDENTITY PRIMARY KEY, UsuarioId INT NOT NULL REFERENCES dbo.Usuarios(Id),
 OperacaoId UNIQUEIDENTIFIER NOT NULL, Status NVARCHAR(30) NOT NULL,
 Total DECIMAL(12,2) NOT NULL CHECK(Total>0), CriadoEm DATETIME2 NOT NULL,
 ReservaAte DATETIME2 NULL, PagoEm DATETIME2 NULL, CanceladoEm DATETIME2 NULL,
 CodigoRetirada VARCHAR(12) NOT NULL, RetiradoEm DATETIME2 NULL,
 RetiradoPor INT NULL REFERENCES dbo.Usuarios(Id),
 CONSTRAINT UQ_PedidosLoja_Operacao UNIQUE(UsuarioId,OperacaoId),
 CONSTRAINT CK_PedidosLoja_Status CHECK(Status IN(N'Pendente',N'Recusado',N'Pago',N'EmPreparacao',N'Pronto',N'Retirado',N'Cancelado',N'Expirado'))
 );
 CREATE INDEX IX_PedidosLoja_Reserva ON dbo.PedidosLoja(Status,ReservaAte);
 CREATE INDEX IX_PedidosLoja_Usuario ON dbo.PedidosLoja(UsuarioId,Id DESC);
END;
IF OBJECT_ID('dbo.ItensPedidoLoja','U') IS NULL
CREATE TABLE dbo.ItensPedidoLoja(
 Id INT IDENTITY PRIMARY KEY, PedidoId INT NOT NULL REFERENCES dbo.PedidosLoja(Id),
 VariacaoId INT NOT NULL REFERENCES dbo.ProdutoVariacoes(Id),
 Nome NVARCHAR(100) NOT NULL, Cor NVARCHAR(40) NOT NULL, Tamanho NVARCHAR(20) NOT NULL,
 Imagem NVARCHAR(255) NOT NULL, Quantidade INT NOT NULL CHECK(Quantidade BETWEEN 1 AND 99),
 PrecoUnitario DECIMAL(10,2) NOT NULL CHECK(PrecoUnitario>0),
 CONSTRAINT UQ_ItensPedidoLoja UNIQUE(PedidoId,VariacaoId)
);
IF OBJECT_ID('dbo.PagamentosSimulados','U') IS NULL
CREATE TABLE dbo.PagamentosSimulados(
 Id INT IDENTITY PRIMARY KEY, PedidoId INT NOT NULL REFERENCES dbo.PedidosLoja(Id),
 OperacaoId UNIQUEIDENTIFIER NOT NULL, Metodo NVARCHAR(10) NOT NULL CHECK(Metodo IN(N'Pix',N'Cartao')),
 ResultadoSolicitado NVARCHAR(15) NOT NULL CHECK(ResultadoSolicitado IN(N'Aprovado',N'Recusado',N'Pendente')),
 Status NVARCHAR(15) NOT NULL CHECK(Status IN(N'Aprovado',N'Recusado',N'Pendente',N'Cancelado',N'Expirado',N'Estornado')),
 Valor DECIMAL(12,2) NOT NULL CHECK(Valor>0), CriadoEm DATETIME2 NOT NULL, AtualizadoEm DATETIME2 NOT NULL,
 CONSTRAINT UQ_PagamentoSimulado_Operacao UNIQUE(PedidoId,OperacaoId)
);
IF OBJECT_ID('dbo.EventosPedidoLoja','U') IS NULL
CREATE TABLE dbo.EventosPedidoLoja(
 Id INT IDENTITY PRIMARY KEY, PedidoId INT NOT NULL REFERENCES dbo.PedidosLoja(Id),
 UsuarioId INT NULL REFERENCES dbo.Usuarios(Id), Descricao NVARCHAR(250) NOT NULL,
 CriadoEm DATETIME2 NOT NULL
);
IF COL_LENGTH('dbo.MovimentacoesEstoque','ReservadoAnterior') IS NULL
 ALTER TABLE dbo.MovimentacoesEstoque ADD ReservadoAnterior INT NOT NULL CONSTRAINT DF_Mov_ReservadoAnterior DEFAULT(0);
IF COL_LENGTH('dbo.MovimentacoesEstoque','ReservadoAtual') IS NULL
 ALTER TABLE dbo.MovimentacoesEstoque ADD ReservadoAtual INT NOT NULL CONSTRAINT DF_Mov_ReservadoAtual DEFAULT(0);
ALTER TABLE dbo.MovimentacoesEstoque DROP CONSTRAINT CK_Movimentacao_Tipo;
ALTER TABLE dbo.MovimentacoesEstoque ADD CONSTRAINT CK_Movimentacao_Tipo CHECK(Tipo IN(N'Inicial',N'Entrada',N'Ajuste',N'Reserva',N'Liberacao',N'Venda',N'Estorno'));
COMMIT;
GO

-- Movimentação manual preserva também os valores da reserva no histórico.
CREATE OR ALTER PROCEDURE dbo.usp_MovimentarEstoque
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
        IF @Responsavel IS NULL THROW 51003,'Acesso ao estoque não permitido.',1;
        IF @Tipo IS NULL OR @Tipo NOT IN(N'Entrada',N'Ajuste') OR @Quantidade IS NULL OR @Quantidade<0 OR @Quantidade>1000000
            OR @Justificativa IS NULL OR LEN(LTRIM(RTRIM(@Justificativa)))<5 OR @OperacaoId IS NULL
            THROW 51000,'Informe operação, quantidade e justificativa válidas.',1;

        IF EXISTS(SELECT 1 FROM dbo.MovimentacoesEstoque WITH(UPDLOCK,HOLDLOCK) WHERE OperacaoId=@OperacaoId)
        BEGIN
            IF NOT EXISTS(SELECT 1 FROM dbo.MovimentacoesEstoque WHERE OperacaoId=@OperacaoId AND VariacaoId=@VariacaoId AND UsuarioId=@UsuarioId
                AND Tipo=@Tipo AND (CASE WHEN @Tipo=N'Entrada' THEN Quantidade ELSE SaldoAtual END)=@Quantidade AND Justificativa=@Justificativa)
                THROW 51009,'O identificador da operação já foi utilizado com outros dados.',1;
            COMMIT;
            SELECT Id FROM dbo.MovimentacoesEstoque WHERE OperacaoId=@OperacaoId;
            RETURN;
        END;
        SELECT @Atual=v.Estoque,@Reservado=v.Reservado,@Versao=v.Versao
        FROM dbo.ProdutoVariacoes v WITH(UPDLOCK,HOLDLOCK) JOIN dbo.Produtos p ON p.Id=v.ProdutoId
        WHERE v.Id=@VariacaoId AND v.Ativo=1 AND p.Ativo=1;
        IF @Atual IS NULL THROW 51004,'Variação ativa não encontrada.',1;
        IF @VersaoEsperada IS NULL OR @Versao<>@VersaoEsperada THROW 51009,'O estoque foi atualizado por outra operação. Atualize os dados e tente novamente.',1;
        SET @Novo=CASE WHEN @Tipo=N'Entrada' THEN CAST(@Atual AS BIGINT)+@Quantidade ELSE @Quantidade END;
        IF @Novo<@Reservado OR @Novo>2147483647 THROW 51009,'O saldo informado é inválido ou menor que a quantidade reservada.',1;
        IF @Novo=@Atual THROW 51000,'A operação não altera o estoque.',1;
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
