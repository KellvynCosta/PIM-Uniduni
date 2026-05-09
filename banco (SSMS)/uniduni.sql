USE MASTER IF EXISTS(SELECT * FROM SYS.databases WHERE NAME = 'uniduni')
DROP DATABASE uniduni;

CREATE DATABASE uniduni;
GO

USE uniduni;
GO

CREATE TABLE Usuarios (
    Id INT IDENTITY(1,1) PRIMARY KEY,
    Nome NVARCHAR(100),
    Email NVARCHAR(100) UNIQUE,
    Senha NVARCHAR(255),
    Telefone NVARCHAR(20),
    TipoUsuario NVARCHAR(20)
);

CREATE TABLE Enderecos (
    Id INT IDENTITY(1,1) PRIMARY KEY,
    UsuarioId INT,
    Rua NVARCHAR(100),
    Numero NVARCHAR(10),
    Bairro NVARCHAR(50),
    Cidade NVARCHAR(50),
    Estado NVARCHAR(50),
    CEP NVARCHAR(10),
    FOREIGN KEY (UsuarioId) REFERENCES Usuarios(Id)
);

CREATE TABLE Categorias (
    Id INT IDENTITY(1,1) PRIMARY KEY,
    Nome NVARCHAR(50),
    Descricao NVARCHAR(100)
);

CREATE TABLE Produtos (
    Id INT IDENTITY(1,1) PRIMARY KEY,
    Nome NVARCHAR(100),
    Descricao NVARCHAR(500),
    Preco DECIMAL(10,2),
    Estoque INT,
    Tamanho NVARCHAR(5),
    Genero NVARCHAR(10),
    Imagem NVARCHAR(255),
    CategoriaId INT,
    FOREIGN KEY (CategoriaId) REFERENCES Categorias(Id)
);

CREATE TABLE Carrinho (
    Id INT IDENTITY(1,1) PRIMARY KEY,
    UsuarioId INT,
    Ativo BIT DEFAULT 1,
    FOREIGN KEY (UsuarioId) REFERENCES Usuarios(Id)
);

CREATE TABLE CarrinhoItens (
    Id INT IDENTITY(1,1) PRIMARY KEY,
    CarrinhoId INT,
    ProdutoId INT,
    Quantidade INT,
    FOREIGN KEY (CarrinhoId) REFERENCES Carrinho(Id),
    FOREIGN KEY (ProdutoId) REFERENCES Produtos(Id)
);

CREATE TABLE Pedidos (
    Id INT IDENTITY(1,1) PRIMARY KEY,
    UsuarioId INT,
    DataPedido DATETIME DEFAULT GETDATE(),
    Status NVARCHAR(50),
    Total DECIMAL(10,2),
    FOREIGN KEY (UsuarioId) REFERENCES Usuarios(Id)
);

CREATE TABLE PedidoItens (
    Id INT IDENTITY(1,1) PRIMARY KEY,
    PedidoId INT,
    ProdutoId INT,
    Quantidade INT,
    PrecoUnitario DECIMAL(10,2),
    FOREIGN KEY (PedidoId) REFERENCES Pedidos(Id),
    FOREIGN KEY (ProdutoId) REFERENCES Produtos(Id)
);

CREATE TABLE Pagamentos (
    Id INT IDENTITY(1,1) PRIMARY KEY,
    PedidoId INT,
    Metodo NVARCHAR(50),
    Status NVARCHAR(50),
    Valor DECIMAL(10,2),
    DataPagamento DATETIME DEFAULT GETDATE(),
    FOREIGN KEY (PedidoId) REFERENCES Pedidos(Id)
);

INSERT INTO Categorias (Nome, Descricao)
VALUES
('Roupas', 'Roupas infantis para bebês')
('Calçados', 'Calçados infantis para bebês'),
('Acessórios', 'Acessórios infantis para bebês'),
('Kits', 'Conjuntos e kits infantis para bebês');


SELECT * FROM Categorias;
SELECT * FROM Produtos;
SELECT * FROM Usuarios;
