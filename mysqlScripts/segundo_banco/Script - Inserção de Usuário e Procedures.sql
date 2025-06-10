-- =====================================================
-- CRIAÇÃO DO BANCO DE DADOS SERVO_INFO
-- Banco destinado a armazenar informações de usuários,
-- registros de movimento do servo motor e logs para auditoria
-- =====================================================

CREATE DATABASE IF NOT EXISTS SERVO_INFO;  -- Cria banco apenas se não existir
USE SERVO_INFO;                           -- Seleciona o banco para uso


-- =====================================================
-- TABELA Usuarios
-- Guarda dados dos usuários do sistema, com chave primária,
-- campos únicos para evitar duplicidade e tipos de usuário restritos.
-- =====================================================

CREATE TABLE IF NOT EXISTS Usuarios (
    id_user INT AUTO_INCREMENT PRIMARY KEY,           -- Identificador único gerado automaticamente
    nome_user VARCHAR(100) NOT NULL,                   -- Nome completo do usuário (não pode ser nulo)
    cpf_user VARCHAR(11) UNIQUE NOT NULL,              -- CPF único (apenas números, 11 dígitos)
    contato_user VARCHAR(15),                           -- Telefone ou contato (opcional)
    email_user VARCHAR(100) UNIQUE NOT NULL,           -- Email único e obrigatório
    tipo_user ENUM('cliente', 'admin') NOT NULL,       -- Define tipo de usuário: cliente ou admin
    senha_user VARCHAR(255) NOT NULL,                   -- Senha armazenada com hash seguro (não guardar texto puro!)
    data_cadastro DATETIME DEFAULT CURRENT_TIMESTAMP   -- Data/hora do cadastro, preenchido automaticamente
);

-- Comentário:
-- Usamos ENUM para limitar tipo_user apenas aos valores 'cliente' ou 'admin',
-- garantindo integridade dos dados. CPF e email são únicos para evitar duplicidade.


-- =====================================================
-- TABELA Registros
-- Armazena movimentações do servo motor feitas pelos usuários,
-- relacionando cada registro ao usuário que executou.
-- =====================================================

CREATE TABLE IF NOT EXISTS Registros (
    id_registro INT AUTO_INCREMENT PRIMARY KEY,        -- Identificador único do registro
    ds_registro VARCHAR(100) NOT NULL,                  -- Descrição curta do registro/movimento
    dt_acao DATETIME DEFAULT CURRENT_TIMESTAMP,         -- Data/hora da ação no sistema (default agora)
    tipo_acao VARCHAR(100),                             -- Tipo de ação realizada (exemplo: 'movimentar', 'parar')
    hora_registro DATETIME,                             -- Hora específica da movimentação (pode ser diferente do dt_acao)
    id_usuario INT NOT NULL,                            -- FK para o usuário que realizou a ação
    FOREIGN KEY (id_usuario) REFERENCES Usuarios(id_user) ON DELETE CASCADE
    -- ON DELETE CASCADE significa que se o usuário for excluído, seus registros também serão
);

-- Comentário:
-- A coluna dt_acao é a data e hora em que o registro foi inserido no banco,
-- já a hora_registro é o momento que a ação do servo motor ocorreu, pode ser diferente.


-- =====================================================
-- TABELA Log_Main
-- Registra logs de todas as ações importantes para auditoria,
-- possibilitando rastreamento e histórico de operações no sistema.
-- =====================================================

CREATE TABLE IF NOT EXISTS Log_Main (
    id_log INT AUTO_INCREMENT PRIMARY KEY,              -- Identificador único do log
    tipo_acao VARCHAR(10) NOT NULL,                      -- Tipo da ação: INSERT, UPDATE, DELETE, etc.
    tipo_user ENUM('cliente', 'admin') NOT NULL,         -- Tipo do usuário que fez a ação
    dt_acao DATETIME DEFAULT CURRENT_TIMESTAMP,          -- Data e hora do registro no log
    ds_registro_old VARCHAR(100),                         -- Valor antigo da descrição do registro (antes da ação)
    ds_registro_now VARCHAR(100),                         -- Valor novo da descrição do registro (depois da ação)
    tipo_acao_old VARCHAR(100),                           -- Tipo da ação antiga (antes da alteração)
    tipo_acao_now VARCHAR(100),                           -- Tipo da ação nova (depois da alteração)
    nome_usuario_old VARCHAR(80),                         -- Nome do usuário antes da alteração
    nome_usuario_now VARCHAR(80),                         -- Nome do usuário depois da alteração
    id_usuario_excluido INT NULL,                         -- ID do usuário excluído, quando aplicável
    excluido_por INT NULL,                                -- ID do usuário que realizou a exclusão
    dados_usuario JSON NULL                               -- JSON com dados completos do usuário excluído para auditoria
);

-- Comentário:
-- Esta tabela é fundamental para rastrear alterações e exclusões no sistema,
-- especialmente para cumprir políticas de auditoria e segurança.


-- =====================================================
-- PROCEDURE: InserirUsuario
-- Insere um novo usuário após validar tipo_user.
-- =====================================================

DELIMITER //

CREATE PROCEDURE InserirUsuario (
    IN p_nome_user VARCHAR(100),
    IN p_cpf_user VARCHAR(11),
    IN p_contato_user VARCHAR(15),
    IN p_email_user VARCHAR(100),
    IN p_tipo_user ENUM('cliente', 'admin'),
    IN p_senha_user VARCHAR(255)
)
BEGIN
    -- Verifica se o tipo de usuário está entre os valores válidos
    IF p_tipo_user NOT IN ('cliente', 'admin') THEN
        SIGNAL SQLSTATE '45000' -- Código de erro customizado
        SET MESSAGE_TEXT = 'Tipo de usuário inválido. Use "cliente" ou "admin".';
    ELSE
        -- Insere usuário na tabela Usuarios com a data atual
        INSERT INTO Usuarios (
            nome_user,
            cpf_user,
            contato_user,
            email_user,
            tipo_user,
            senha_user,
            data_cadastro
        ) VALUES (
            p_nome_user,
            p_cpf_user,
            p_contato_user,
            p_email_user,
            p_tipo_user,
            p_senha_user,
            NOW() -- Timestamp atual
        );
    END IF;
END;
//

DELIMITER ;

-- Comentário:
-- Não é necessário usar SHA2 dentro da procedure se a senha já vier hashada pela API.


-- =====================================================
-- PROCEDURE: AtualizarUsuario
-- Atualiza nome, contato e senha do usuário com base no email.
-- =====================================================

DELIMITER //

CREATE PROCEDURE AtualizarUsuario (
    IN p_email_user VARCHAR(100),
    IN p_nome_user VARCHAR(100),
    IN p_contato_user VARCHAR(15),
    IN p_senha_user VARCHAR(255)
)
BEGIN
    -- Atualiza os campos de acordo com o email fornecido
    UPDATE Usuarios
    SET
        nome_user = p_nome_user,
        contato_user = p_contato_user,
        senha_user = p_senha_user
    WHERE email_user = p_email_user;
END;
//

DELIMITER ;


-- =====================================================
-- PROCEDURE: RegistrarLogExclusao
-- Insere registro na tabela Log_Main para registrar exclusões.
-- =====================================================

DELIMITER //

CREATE PROCEDURE RegistrarLogExclusao (
    IN p_tipo_acao VARCHAR(100),
    IN p_tipo_user ENUM('cliente', 'admin'),
    IN p_id_usuario_excluido INT,
    IN p_excluido_por INT,
    IN p_dados_antigos JSON
)
BEGIN
    -- Insere dados do log na tabela Log_Main
    INSERT INTO Log_Main (
        tipo_acao,
        tipo_user,
        dt_acao,
        id_usuario_excluido,
        excluido_por,
        dados_usuario
    ) VALUES (
        p_tipo_acao,
        p_tipo_user,
        NOW(),
        p_id_usuario_excluido,
        p_excluido_por,
        p_dados_antigos
    );
END;
//

DELIMITER ;


-- =====================================================
-- PROCEDURE: ExcluirUsuario
-- Registra o log da exclusão e depois exclui o usuário da tabela Usuarios.
-- Recebe o ID do usuário a ser excluído e o ID do usuário que executou a exclusão.
-- =====================================================

DELIMITER //

CREATE PROCEDURE ExcluirUsuario (
    IN p_id_user INT,       -- ID do usuário que será excluído
    IN p_excluido_por INT   -- ID do usuário que está realizando a exclusão
)
BEGIN
    DECLARE v_tipo_user ENUM('cliente', 'admin');    -- Variável para armazenar tipo_user do usuário excluído
    DECLARE v_dados_usuario JSON;                     -- Variável para armazenar dados do usuário excluído em JSON

    -- Seleciona dados do usuário a ser excluído e monta JSON com suas informações
    SELECT tipo_user,
           JSON_OBJECT(
               'nome_user', nome_user,
               'cpf_user', cpf_user,
               'contato_user', contato_user,
               'email_user', email_user,
               'tipo_user', tipo_user,
               'data_cadastro', DATE_FORMAT(data_cadastro, '%Y-%m-%d %H:%i:%s')
           )
    INTO v_tipo_user, v_dados_usuario
    FROM Usuarios
    WHERE id_user = p_id_user;

    -- Registra log de exclusão chamando procedure responsável
    CALL RegistrarLogExclusao('DELETE', v_tipo_user, p_id_user, p_excluido_por, v_dados_usuario);

    -- Exclui o usuário da tabela Usuarios
    DELETE FROM Usuarios WHERE id_user = p_id_user;
END;
//

DELIMITER ;


-- =====================================================
-- PROCEDURE: InserirRegistro
-- Insere um novo registro de movimentação e grava log na Log_Main.
-- =====================================================

DELIMITER //

CREATE PROCEDURE InserirRegistro (
    IN p_ds_registro VARCHAR(100),    -- Descrição do registro (ex: "Servo ligado")
    IN p_tipo_acao VARCHAR(100),      -- Tipo de ação (ex: "ligar", "parar")
    IN p_hora_registro DATETIME,      -- Horário da movimentação
    IN p_id_usuario INT,              -- ID do usuário que realizou a ação
    IN p_ip_origem VARCHAR(45)        -- IP de origem da ação para auditoria
)
BEGIN
    DECLARE v_tipo_user ENUM('cliente', 'admin');    -- Tipo do usuário para log
    DECLARE v_nome_user VARCHAR(100);                 -- Nome do usuário para log

    -- Recupera tipo_user e nome do usuário que realizou a ação
    SELECT tipo_user, nome_user INTO v_tipo_user, v_nome_user
    FROM Usuarios
    WHERE id_user = p_id_usuario;

    -- Insere o registro de movimentação do servo motor
    INSERT INTO Registros (
        ds_registro,
        tipo
