-- ================================================================
-- TABELAS
-- ================================================================

-- Tabela que armazena dados dos usuários do sistema
create table usuarios(
	id_usuario int auto_increment primary key,  -- Identificador único do usuário
    nome varchar(100) not null,                  -- Nome completo do usuário
    cpf varchar(11) unique not null,             -- CPF único do usuário
    telefone varchar(15) not null,               -- Telefone do usuário
    email varchar(100) unique not null,          -- Email único do usuário
	senha varchar(100) not null,                  -- Senha do usuário (armazenar hash em produção)
    tipo_usuario enum('cliente', 'admin') not null, -- Tipo do usuário (cliente ou admin)
    data_cadastro datetime default current_timestamp -- Data e hora do cadastro (padrão atual)
);

-- Tabela para registrar ações realizadas no sistema (log de ações)
create table registros (
	id_registro int auto_increment primary key,  -- Identificador único do registro
    ds_registro varchar(100) not null,           -- Descrição da ação realizada
    tipo_acao enum('INSERT', 'UPDATE', 'DELETE') not null, -- Tipo da ação realizada
    id_usuario int not null,                      -- Usuário responsável pela ação
    dt_acao datetime default current_timestamp,  -- Data e hora da ação
    foreign key (id_usuario) references usuarios(id_usuario) -- Chave estrangeira para usuário
);

-- Tabela para armazenar logs detalhados de todas as alterações no sistema
create table log (
	id_log int auto_increment primary key,       -- Identificador único do log
    tipo_usuario enum('cliente', 'admin') not null, -- Tipo do usuário envolvido
    tipo_acao_old enum('INSERT', 'UPDATE', 'DELETE') default null, -- Tipo de ação anterior no log
    tipo_acao_now enum('INSERT', 'UPDATE', 'DELETE') not null, -- Tipo de ação atual
    nome_usuario_old varchar(100) default null,  -- Nome antigo do usuário (em update)
    nome_usuario_now varchar(100) not null,      -- Nome atual do usuário
    ds_registro_old varchar(100) default null,   -- Descrição antiga do registro (em update)
    ds_registro_now varchar(100) default null,   -- Descrição atual do registro
    email_usuario_excluido varchar(100) default null, -- Email do usuário excluído
    dt_trigger timestamp default current_timestamp -- Timestamp do evento no log
);

-- Adicionando colunas extras na tabela log para maior detalhamento
alter table log add column id_usuario int after id_log;               -- ID do usuário relacionado ao log
alter table log add column id_registro int after id_usuario;           -- ID do registro relacionado ao log
alter table log add column telefone_usuario_old varchar(100) default null after nome_usuario_now; -- Telefone antigo do usuário
alter table log add column telefone_usuario_now varchar(100) not null after telefone_usuario_old; -- Telefone atual do usuário


-- ================================================================
-- PROCEDURES
-- ================================================================

-- PROCEDURE PARA INSERIR NOVO USUÁRIO NA TABELA usuarios
delimiter //
create procedure inserir_usuario(
	in p_nome varchar(100),                  -- Nome do usuário
    in p_cpf varchar(11),                    -- CPF do usuário
    in p_telefone varchar(15),               -- Telefone do usuário
    in p_email varchar(100),                 -- Email do usuário
    in p_senha varchar(100),                 -- Senha do usuário
    in p_tipo_usuario enum('cliente', 'admin') -- Tipo do usuário
)
begin
	insert into usuarios (
		nome,
        cpf,
        telefone,
        email,
        senha,
        tipo_usuario
    ) values (
		p_nome,
        p_cpf,
        p_telefone,
        p_email,
        p_senha,
        p_tipo_usuario
    );
end
//
delimiter ;

-- Inserção manual para criar o usuário sistema (admin fixo)
call inserir_usuario('sistema', '00000000000', '0000000000000', 'sistema@admin', 'sistema123', 'admin');

-- PROCEDURE PARA ATUALIZAR DADOS DO USUÁRIO (exceto email)
delimiter //
create procedure atualizar_usuario (
	in p_nome varchar(100),      -- Novo nome do usuário
    in p_telefone varchar(15),   -- Novo telefone
    in p_email varchar(100),     -- Email do usuário para identificar qual atualizar
    in p_senha varchar(100)      -- Nova senha
)
begin
	update usuarios
    set nome = p_nome,
		telefone = p_telefone,
        senha = p_senha
	where email = p_email; -- Atualiza o usuário pelo email
end;
//
delimiter ;

-- PROCEDURE PARA EXCLUIR USUÁRIO PELO EMAIL
delimiter //
create procedure excluir_usuario(
	in p_email varchar(100) -- Email do usuário a ser excluído
)
begin
	delete from usuarios where email = p_email;
end;
//
delimiter ;

-- PROCEDURE PARA INSERIR REGISTRO DE AÇÃO NA TABELA registros
delimiter //
create procedure inserir_registro (
	in p_ds_registro varchar(100), -- Descrição da ação
    in p_id_usuario int            -- Usuário responsável
)
begin
	insert into registros (
		ds_registro,
        tipo_acao,
        id_usuario
    ) values (
		p_ds_registro,
        'INSERT',     -- Tipo da ação fixado como INSERT nesta procedure
        p_id_usuario
    );
end;
//
delimiter ;

-- PROCEDURE PARA EXCLUIR REGISTRO PELO ID
delimiter //
create procedure excluir_registro (
	in p_id_registro int -- ID do registro a excluir
)
begin
	delete from registros where id_registro = p_id_registro;
end;
//
delimiter ;


-- ================================================================
-- TRIGGERS
-- ================================================================

-- TRIGGER PARA INSERÇÃO DE USUÁRIO: registra a inserção na tabela log
delimiter //
create trigger t_log_inserir_usuario
after insert on usuarios
for each row
begin
	declare v_tipo_acao_old enum('INSERT', 'UPDATE', 'DELETE');
    
    -- Obtém o último tipo de ação registrado para manter histórico
    select tipo_acao_now into v_tipo_acao_old
    from log
    order by dt_trigger desc
    limit 1;

	-- Insere novo registro na tabela de logs com os dados da inserção
	insert into log (
		id_usuario,
		tipo_usuario,
		tipo_acao_old,
		tipo_acao_now,
        nome_usuario_now,
        telefone_usuario_now
    ) values (
		new.id_usuario,
		new.tipo_usuario,
        v_tipo_acao_old,
		'INSERT',
        new.nome,
        new.telefone
    );
end;
//
delimiter ;

-- TRIGGER PARA ATUALIZAÇÃO DE USUÁRIO: registra as mudanças no log
delimiter //
create trigger t_log_atualizar_usuario
after update on usuarios
for each row
begin
	declare v_tipo_acao_old enum('INSERT', 'UPDATE', 'DELETE');
    declare v_nome_usuario_old varchar(100);
    declare v_telefone_usuario_old varchar(100);
    
    -- Obtém última ação, nome e telefone antigo para registro histórico
    select tipo_acao_now, nome_usuario_now, telefone_usuario_now
    into v_tipo_acao_old, v_nome_usuario_old, v_telefone_usuario_old
    from log
    where id_usuario = new.id_usuario
    order by dt_trigger desc
    limit 1;

	-- Insere novo registro no log com dados antigos e novos para comparação
	insert into log (
		id_usuario,
		tipo_usuario,
        tipo_acao_old,
        tipo_acao_now,
        nome_usuario_old,
        nome_usuario_now,
        telefone_usuario_old,
        telefone_usuario_now
    ) values (
		new.id_usuario,
		new.tipo_usuario,
		v_tipo_acao_old,
        'UPDATE',
        v_nome_usuario_old,
        new.nome,
        v_telefone_usuario_old,
        new.telefone
    );
end;
//
delimiter ;

-- TRIGGER PARA EXCLUSÃO DE USUÁRIO: registra exclusão no log
delimiter //
create trigger t_log_excluir_usuario
after delete on usuarios
for each row
begin
	declare v_tipo_acao_old enum('INSERT', 'UPDATE', 'DELETE');
    
    -- Obtém o último tipo de ação para histórico
    select tipo_acao_now into v_tipo_acao_old
    from log
    where id_usuario = old.id_usuario
    order by dt_trigger desc
    limit 1;
    
	-- Insere log de exclusão com dados do usuário excluído
	insert into log (
		id_usuario,
        tipo_usuario,
        tipo_acao_old,
        tipo_acao_now,
        nome_usuario_now,
        telefone_usuario_now,
        email_usuario_excluido
    ) values (
		old.id_usuario,
        old.tipo_usuario,
        v_tipo_acao_old,
        'DELETE',
        old.nome,
        old.telefone,
        old.email
    );
end;
//
delimiter ;

-- TRIGGER PARA INSERIR REGISTRO NA TABELA registros: registra no log toda inserção
delimiter //
 create trigger t_log_inserir_registro
 after insert on registros
 for each row
 begin
	declare v_tipo_acao_old enum('INSERT', 'UPDATE', 'DELETE');
    declare v_ds_registro_old varchar(100);
    declare v_tipo_usuario enum('cliente', 'admin');
    declare v_nome varchar(100);
    declare v_telefone varchar(15);
    
    -- Obtém último tipo de ação e descrição antiga para histórico
    select tipo_acao_now, ds_registro_now
    into v_tipo_acao_old, v_ds_registro_old
    from log
    order by dt_trigger desc
    limit 1;
    
    -- Obtém dados do usuário relacionado ao registro
    select tipo_usuario, nome, telefone
    into v_tipo_usuario, v_nome, v_telefone
    from usuarios
    where id_usuario = new.id_usuario;
    
    -- Insere o registro no log
    insert into log (
		id_usuario,
        id_registro,
        tipo_usuario,
        tipo_acao_old,
		tipo_acao_now,
        nome_usuario_now,
        telefone_usuario_now,
        ds_registro_old,
		ds_registro_now
    ) values (
		new.id_usuario,
        new.id_registro,
        v_tipo_usuario,
        v_tipo_acao_old,
        'INSERT',
        v_nome,
        v_telefone,
        v_ds_registro_old,
        new.ds_registro
    );
end;
//
delimiter ;

-- TRIGGER PARA EXCLUIR REGISTRO NA TABELA registros: registra exclusão no log
delimiter //
create trigger t_log_excluir_registro
after delete on registros
for each row
begin
	declare v_tipo_acao_old enum('INSERT', 'UPDATE', 'DELETE');
    declare v_tipo_usuario enum ('cliente', 'admin');
    declare v_nome varchar(100);
    declare v_telefone varchar(15);
    
    -- Obtém último tipo de ação do log relacionado ao registro excluído
    select tipo_acao_now into v_tipo_acao_old
    from log
    where id_registro = old.id_registro
    order by dt_trigger desc
    limit 1;
    
    -- Obtém dados do usuário relacionado ao registro excluído
    select tipo_usuario, nome, telefone
    into v_tipo_usuario, v_nome, v_telefone
    from usuarios
    where id_usuario = old.id_usuario;
    
    -- Insere log da exclusão do registro
    insert into log (
		id_usuario,
        id_registro,
        tipo_usuario,
        tipo_acao_old,
        tipo_acao_now,
        nome_usuario_now,
        telefone_usuario_now,
        ds_registro_now
    ) values (
		old.id_usuario,
        old.id_registro,
        v_tipo_usuario,
        v_tipo_acao_old,
        'DELETE',
        v_nome,
        v_telefone,
        old.ds_registro
    );
end;
//
delimiter ;


-- ================================================================
-- LIMPEZA AUTOMÁTICA DO LOG
-- ================================================================

-- Desativa o event scheduler global (pode ligar com ON se desejar usar)
set global event_scheduler = off;

-- PROCEDURE PARA LIMPAR LOGS ANTIGOS (mais de 2 minutos)
delimiter //
create procedure p_limpar_log_antigo()
begin
	-- Deleta o log mais antigo com timestamp menor que 2 minutos atrás
	delete from log
    where dt_trigger < date_sub(now(), interval 2 minute)
    order by dt_trigger asc
    limit 1;
    
    -- Insere um registro de limpeza automática na tabela registros
    insert into registros (ds_registro, tipo_acao, id_usuario)
    values ('Limpeza automática', 'DELETE', 1);
end;
//
delimiter ;

-- CRIAÇÃO DO EVENTO PARA CHAMAR LIMPEZA A CADA 2 MINUTOS
delimiter //
create event j_limpar_log
on schedule every 2 minute
do
begin
	call p_limpar_log_antigo();
end;
//
delimiter ;
