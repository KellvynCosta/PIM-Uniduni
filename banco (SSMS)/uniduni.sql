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

INSERT INTO Categorias (Nome, Descricao)
VALUES
('Roupas', 'Roupas infantis para bebês'),
('Calçados', 'Calçados infantis para bebês'),
('Acessórios', 'Acessórios infantis para bebês'),
('Kits', 'Conjuntos e kits infantis para bebês');


INSERT INTO Usuarios (Nome, Email, Senha, Telefone, TipoUsuario)
VALUES
('Admin', 'admin@email.com', 'admin', '11999999999', 'Admin');


INSERT INTO Produtos (Nome, Descricao, Preco, Estoque, Tamanho, Genero, Imagem, CategoriaId)
VALUES
('Body Bebê Azul', 'Body confortável e macio', 44.90, 10, 'P', 'Masculino', 'body-azul.jpg', 1),
('Camiseta Preta', 'Camiseta preta confortável para bebê', 79.90, 8, 'P', 'Unissex', 'camiseta-preta.jpg', 1),
('Sapatinho Bebê Feminino', 'Sapatinho confortável para bebê', 59.90, 6, '18', 'Feminino', 'sapatilha-feminina-uniduni.png', 2);


SELECT * FROM Categorias;
SELECT * FROM Produtos;
SELECT * FROM Usuarios;
