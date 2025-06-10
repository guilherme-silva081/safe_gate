-- ATIVAR O AGENDADOR DE EVENTOS (PRECISA SER EXECUTADO UMA VEZ POR SESSÃO/INSTÂNCIA)
SET GLOBAL event_scheduler = ON;

-- CRIAÇÃO DE EVENTO (JOB) PARA INSERIR UM REGISTRO DIÁRIO NA TABELA Log_Main
CREATE EVENT IF NOT EXISTS job_log_diario
ON SCHEDULE EVERY 1 DAY                    -- Executa uma vez a cada dia
STARTS CURRENT_DATE + INTERVAL 3 HOUR     -- Começa hoje às 03:00 da manhã
DO
INSERT INTO Log_Main (
    tipo_acao,          -- Tipo da ação (ex: SYSTEM para ações automáticas do sistema)
    login_user,         -- Usuário responsável pela ação
    dt_acao,            -- Data e hora da ação
    ds_registro_now,    -- Descrição do registro atual
    tipo_acao_now,      -- Descrição da ação atual
    nome_usuario_now,   -- Nome do usuário relacionado à ação (aqui é o sistema)
    ip_origem           -- IP de origem da ação (localhost para sistema)
)
VALUES (
    'SYSTEM',
    'sistema',
    NOW(),
    CONCAT('Relatório diário às 03:00 - Status OK'),
    'Relatório Diário',
    'Sistema Noturno',
    '127.0.0.1'
);

-- PARA LISTAR OS EVENTOS (JOBS) CRIADOS ATIVOS NO BANCO:
SHOW EVENTS;


-- ===========================================================
-- TRIGGER PARA INSERÇÃO (INSERT) NA TABELA Usuarios
-- A cada novo usuário inserido, registra o evento no Log_Main
DELIMITER //
CREATE TRIGGER trg_insert_usuario
AFTER INSERT ON Usuarios
FOR EACH ROW
BEGIN
    INSERT INTO Log_Main (
        tipo_acao,
        login_user,
        dt_acao,
        ds_registro_now,
        tipo_acao_now,
        nome_usuario_now,
        ip_origem
    )
    VALUES (
        'INSERT',
        NEW.login_user,                              -- LOGIN do usuário inserido
        NOW(),
        CONCAT('Usuário inserido: ', NEW.nome_user), -- Descrição do que aconteceu
        'Criação',
        NEW.nome_user,
        '127.0.0.1'
    );
END;
//
DELIMITER ;


-- ===========================================================
-- TRIGGER PARA ATUALIZAÇÃO (UPDATE) NA TABELA Usuarios
-- Registra no log as alterações feitas no usuário
DELIMITER //
CREATE TRIGGER trg_update_usuario
AFTER UPDATE ON Usuarios
FOR EACH ROW
BEGIN
    INSERT INTO Log_Main (
        tipo_acao,
        login_user,
        dt_acao,
        ds_registro_old,
        ds_registro_now,
        tipo_acao_old,
        tipo_acao_now,
        nome_usuario_old,
        nome_usuario_now,
        ip_origem
    )
    VALUES (
        'UPDATE',
        NEW.login_user,
        NOW(),
        OLD.nome_user,        -- Nome antigo
        NEW.nome_user,        -- Nome novo
        'Antes',
        'Depois',
        OLD.nome_user,
        NEW.nome_user,
        '127.0.0.1'
    );
END;
//
DELIMITER ;


-- ===========================================================
-- TRIGGER PARA EXCLUSÃO (DELETE) NA TABELA Usuarios
-- Registra no log a exclusão de um usuário
DELIMITER //
CREATE TRIGGER trg_delete_usuario
BEFORE DELETE ON Usuarios
FOR EACH ROW
BEGIN
    INSERT INTO Log_Main (
        tipo_acao,
        login_user,
        dt_acao,
        ds_registro_old,
        tipo_acao_old,
        nome_usuario_old,
        ip_origem
    )
    VALUES (
        'DELETE',
        OLD.login_user,
        NOW(),
        CONCAT('Usuário removido: ', OLD.nome_user),
        'Excluído',
        OLD.nome_user,
        '127.0.0.1'
    );
END;
//
DELIMITER ;


-- ===========================================================
-- TRIGGER PARA INSERÇÃO (INSERT) NA TABELA Registros
-- Registra inserção de ações em registros associadas a usuários
DELIMITER //
CREATE TRIGGER trg_insert_registro
AFTER INSERT ON Registros
FOR EACH ROW
BEGIN
    INSERT INTO Log_Main (
        tipo_acao,
        login_user,
        dt_acao,
        ds_registro_now,
        tipo_acao_now,
        nome_usuario_now,
        ip_origem
    )
    SELECT
        'INSERT',
        u.login_user,
        NOW(),
        NEW.DS_REGISTRO,
        NEW.TIPO_ACAO,
        u.nome_user,
        '127.0.0.1'
    FROM Usuarios u
    WHERE u.id_user = NEW.id_usuario;
END;
//
DELIMITER ;


-- ===========================================================
-- TRIGGER PARA ATUALIZAÇÃO (UPDATE) NA TABELA Registros
-- Registra alteração de registros vinculados a usuários
DELIMITER //
CREATE TRIGGER trg_update_registro
AFTER UPDATE ON Registros
FOR EACH ROW
BEGIN
    INSERT INTO Log_Main (
        tipo_acao,
        login_user,
        dt_acao,
        ds_registro_old,
        ds_registro_now,
        tipo_acao_old,
        tipo_acao_now,
        nome_usuario_now,
        ip_origem
    )
    SELECT
        'UPDATE',
        u.login_user,
        NOW(),
        OLD.DS_REGISTRO,
        NEW.DS_REGISTRO,
        OLD.TIPO_ACAO,
        NEW.TIPO_ACAO,
        u.nome_user,
        '127.0.0.1'
    FROM Usuarios u
    WHERE u.id_user = NEW.id_usuario;
END;
//
DELIMITER ;


-- ===========================================================
-- TRIGGER PARA EXCLUSÃO (DELETE) NA TABELA Registros
-- Registra remoção de registros vinculados a usuários
DELIMITER //
CREATE TRIGGER trg_delete_registro
BEFORE DELETE ON Registros
FOR EACH ROW
BEGIN
    INSERT INTO Log_Main (
        tipo_acao,
        login_user,
        dt_acao,
        ds_registro_old,
        tipo_acao_old,
        nome_usuario_old,
        ip_origem
    )
    SELECT
        'DELETE',
        u.login_user,
        NOW(),
        OLD.DS_REGISTRO,
        OLD.TIPO_ACAO,
        u.nome_user,
        '127.0.0.1'
    FROM Usuarios u
    WHERE u.id_user = OLD.id_usuario;
END;
//
DELIMITER ;
