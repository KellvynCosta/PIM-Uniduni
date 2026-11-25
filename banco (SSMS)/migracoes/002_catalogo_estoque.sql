-- Requer 001_autenticacao.sql. Executar no SSMS com a base uniduni.
-- Preserva produtos e quantidades; pode ser executado novamente.
USE [uniduni];
GO
SET XACT_ABORT ON;
BEGIN TRANSACTION;
IF EXISTS (SELECT 1 FROM dbo.Produtos WHERE Estoque < 0 OR Preco <= 0)
    THROW 51000, 'Revise preços e saldos inválidos antes da migração.', 1;
IF COL_LENGTH('dbo.Produtos','Ativo') IS NULL
    ALTER TABLE dbo.Produtos ADD Ativo BIT NOT NULL CONSTRAINT DF_Produtos_Ativo DEFAULT(1) WITH VALUES;
IF COL_LENGTH('dbo.Produtos','GuiaMedidas') IS NULL
    ALTER TABLE dbo.Produtos ADD GuiaMedidas NVARCHAR(500) NOT NULL CONSTRAINT DF_Produtos_Guia DEFAULT(N'') WITH VALUES;

IF OBJECT_ID('dbo.ProdutoVariacoes','U') IS NULL
BEGIN
    CREATE TABLE dbo.ProdutoVariacoes (
        Id INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
        ProdutoId INT NOT NULL REFERENCES dbo.Produtos(Id),
        Cor NVARCHAR(40) NOT NULL,
        Tamanho NVARCHAR(20) NOT NULL,
        Estoque INT NOT NULL CONSTRAINT DF_Variacoes_Estoque DEFAULT(0),
        Reservado INT NOT NULL CONSTRAINT DF_Variacoes_Reservado DEFAULT(0),
        EstoqueMinimo INT NOT NULL CONSTRAINT DF_Variacoes_Minimo DEFAULT(3),
        Ativo BIT NOT NULL CONSTRAINT DF_Variacoes_Ativo DEFAULT(1),
        Versao ROWVERSION NOT NULL,
        CONSTRAINT UQ_Variacoes_ProdutoCorTamanho UNIQUE(ProdutoId,Cor,Tamanho),
        CONSTRAINT CK_Variacoes_Saldos CHECK(Estoque >= 0 AND Reservado >= 0 AND Reservado <= Estoque AND EstoqueMinimo >= 0)
    );
END;
IF OBJECT_ID('dbo.MovimentacoesEstoque','U') IS NULL
BEGIN
    CREATE TABLE dbo.MovimentacoesEstoque (
        Id BIGINT IDENTITY(1,1) NOT NULL PRIMARY KEY,
        VariacaoId INT NOT NULL REFERENCES dbo.ProdutoVariacoes(Id),
        UsuarioId INT NULL REFERENCES dbo.Usuarios(Id),
        Responsavel NVARCHAR(100) NOT NULL,
        Tipo NVARCHAR(20) NOT NULL,
        Quantidade INT NOT NULL,
        SaldoAnterior INT NOT NULL,
        SaldoAtual INT NOT NULL,
        Justificativa NVARCHAR(250) NOT NULL,
        OperacaoId UNIQUEIDENTIFIER NOT NULL CONSTRAINT UQ_Movimentacao_Operacao UNIQUE,
        CriadaEm DATETIME2 NOT NULL CONSTRAINT DF_Movimentacao_Data DEFAULT SYSUTCDATETIME(),
        CONSTRAINT CK_Movimentacao_Saldos CHECK(SaldoAnterior >= 0 AND SaldoAtual >= 0),
        CONSTRAINT CK_Movimentacao_Tipo CHECK(Tipo IN (N'Inicial',N'Entrada',N'Ajuste'))
    );
    CREATE INDEX IX_Movimentacoes_VariacaoData ON dbo.MovimentacoesEstoque(VariacaoId,CriadaEm DESC);
END;
COMMIT;
GO

-- O trigger mantém somente o saldo legado agregado. Não registra outra baixa.
CREATE OR ALTER TRIGGER dbo.trg_Variacoes_TotalProduto
ON dbo.ProdutoVariacoes AFTER INSERT,UPDATE,DELETE
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE p SET Estoque = COALESCE((SELECT SUM(v.Estoque) FROM dbo.ProdutoVariacoes v WHERE v.ProdutoId=p.Id AND v.Ativo=1),0)
    FROM dbo.Produtos p WHERE p.Id IN (SELECT ProdutoId FROM inserted UNION SELECT ProdutoId FROM deleted);
END;
GO

SET XACT_ABORT ON;
BEGIN TRANSACTION;
INSERT INTO dbo.ProdutoVariacoes(ProdutoId,Cor,Tamanho,Estoque)
SELECT p.Id,
    CASE WHEN p.Nome LIKE N'%Azul%' THEN N'Azul' WHEN p.Nome LIKE N'%Preta%' OR p.Nome LIKE N'%Preto%' THEN N'Preto' ELSE N'Não informada' END,
    COALESCE(NULLIF(LTRIM(RTRIM(p.Tamanho)),N''),N'Único'),COALESCE(p.Estoque,0)
FROM dbo.Produtos p WHERE NOT EXISTS (SELECT 1 FROM dbo.ProdutoVariacoes v WHERE v.ProdutoId=p.Id);

INSERT INTO dbo.MovimentacoesEstoque(VariacaoId,Responsavel,Tipo,Quantidade,SaldoAnterior,SaldoAtual,Justificativa,OperacaoId)
SELECT v.Id,N'Migração PIM IV',N'Inicial',v.Estoque,0,v.Estoque,N'Saldo preservado do cadastro anterior; revisar cor quando não informada.',NEWID()
FROM dbo.ProdutoVariacoes v WHERE NOT EXISTS (SELECT 1 FROM dbo.MovimentacoesEstoque m WHERE m.VariacaoId=v.Id);
COMMIT;
GO

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
        INSERT INTO dbo.MovimentacoesEstoque(VariacaoId,UsuarioId,Responsavel,Tipo,Quantidade,SaldoAnterior,SaldoAtual,Justificativa,OperacaoId)
        VALUES(@VariacaoId,@UsuarioId,@Responsavel,@Tipo,CAST(@Novo AS INT)-@Atual,@Atual,CAST(@Novo AS INT),LTRIM(RTRIM(@Justificativa)),@OperacaoId);
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
