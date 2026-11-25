-- Execute no SSMS conectado à instância que contém o banco uniduni.
-- Evolução preservando tabelas e registros existentes; pode ser executada novamente.
USE [uniduni];
GO
SET XACT_ABORT ON;
BEGIN TRANSACTION;

IF EXISTS (SELECT 1 FROM dbo.Usuarios WHERE Email IS NULL OR LEN(LTRIM(RTRIM(Email))) = 0)
    THROW 50001, 'Existem usuários sem email. Corrija esses registros antes da atualização.', 1;
IF EXISTS (SELECT LOWER(LTRIM(RTRIM(Email))) FROM dbo.Usuarios GROUP BY LOWER(LTRIM(RTRIM(Email))) HAVING COUNT(*) > 1)
    THROW 50002, 'Existem emails repetidos após normalização. Revise os registros antes da atualização.', 1;
IF EXISTS (SELECT 1 FROM dbo.Usuarios WHERE TipoUsuario IS NOT NULL AND TipoUsuario NOT IN (N'Admin', N'Administrador', N'Funcionario', N'Funcionário', N'Cliente'))
    THROW 50003, 'Existe um perfil desconhecido. Revise os perfis antes da atualização.', 1;

IF COL_LENGTH('dbo.Usuarios', 'Ativo') IS NULL
    ALTER TABLE dbo.Usuarios ADD Ativo BIT NOT NULL CONSTRAINT DF_Usuarios_Ativo DEFAULT (1) WITH VALUES;

UPDATE dbo.Usuarios SET Email = LOWER(LTRIM(RTRIM(Email)));
UPDATE dbo.Usuarios SET TipoUsuario = N'Administrador' WHERE TipoUsuario = N'Admin';
UPDATE dbo.Usuarios SET TipoUsuario = N'Funcionario' WHERE TipoUsuario = N'Funcionário';
UPDATE dbo.Usuarios SET TipoUsuario = N'Cliente' WHERE TipoUsuario IS NULL;

IF NOT EXISTS (SELECT 1 FROM sys.check_constraints WHERE name = 'CK_Usuarios_Perfil')
    ALTER TABLE dbo.Usuarios ADD CONSTRAINT CK_Usuarios_Perfil CHECK (TipoUsuario IN (N'Cliente', N'Funcionario', N'Administrador'));

IF OBJECT_ID('dbo.Sessoes', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.Sessoes (
        Id INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
        UsuarioId INT NOT NULL REFERENCES dbo.Usuarios(Id),
        TokenHash CHAR(64) NOT NULL,
        CriadaEm DATETIME2 NOT NULL,
        ExpiraEm DATETIME2 NOT NULL,
        CONSTRAINT UQ_Sessoes_TokenHash UNIQUE (TokenHash)
    );
    CREATE INDEX IX_Sessoes_UsuarioId ON dbo.Sessoes(UsuarioId);
    CREATE INDEX IX_Sessoes_ExpiraEm ON dbo.Sessoes(ExpiraEm);
END;

COMMIT TRANSACTION;
GO
