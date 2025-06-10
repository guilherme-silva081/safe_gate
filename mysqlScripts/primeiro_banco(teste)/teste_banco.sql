-- Criação do banco de dados chamado safegate
create database safegate;

-- Seleciona o banco de dados safegate para uso nas próximas operações
use safegate;

-- Criação da tabela usuarios para armazenar informações dos usuários
create table usuarios (
    id int auto_increment primary key,          -- Identificador único do usuário, auto incrementado
    nome varchar(100) not null,                  -- Nome completo do usuário, obrigatório
    email varchar(100) not null unique,          -- Email do usuário, obrigatório e único
    senha varchar(255) not null,                  -- Senha do usuário, armazenada com hash (por isso tamanho maior)
    cpf varchar(14) not null unique,              -- CPF do usuário, obrigatório e único (formato com pontos e traço)
    telefone varchar(20) not null,                 -- Telefone do usuário, obrigatório
    criado_em timestamp default current_timestamp -- Data e hora do cadastro, padrão: momento da inserção
);

-- Criação da tabela acoes_portao para registrar as ações feitas no portão
create table acoes_portao (
    id int auto_increment primary key,              -- Identificador único da ação, auto incrementado
    usuario_id int not null,                         -- ID do usuário que realizou a ação (chave estrangeira)
    acao enum('abrir', 'fechar', 'parar') not null, -- Tipo da ação realizada no portão: abrir, fechar ou parar
    data timestamp default current_timestamp,       -- Data e hora da ação, padrão: momento da inserção
    foreign key (usuario_id) references usuarios(id) -- Chave estrangeira que referencia o usuário responsável pela ação
);
