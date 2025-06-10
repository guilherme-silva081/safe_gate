// Importa a conexão com o banco de dados a partir do arquivo connection.js
import pool from "../database/connection.js";

// Função para obter a lista de usuários
export const getUsuarios = async (req, res) => {
    try {
        // Executa uma consulta no banco de dados para selecionar os usuários
        const [rows] = await pool.query('SELECT id_usuario, nome, email, tipo_usuario FROM usuarios');
        
        // Retorna os resultados da consulta em formato JSON
        res.json(rows);
    } catch (error) {
        // Em caso de erro, exibe no console
        console.log('Erro ao buscar usuários:', error);
        
        // Retorna um erro 500 (erro interno do servidor) com mensagem
        res.status(500).json({error: 'Erro no servidor'});
    }
};

// Função para excluir um usuário com base no email
export const deleteUsuario = async (req, res) => {
    try {
        // Extrai o email dos parâmetros da requisição
        const {email} = req.params;
        
        // Chama a procedure armazenada 'excluir_usuario' no banco de dados
        await pool.query('CALL excluir_usuario(?)', [email]);
        
        // Retorna uma mensagem de sucesso
        res.json({message: 'Usuário excluído com sucesso!'});
    } catch (error) {
        // Em caso de erro, exibe no console
        console.log('Erro ao excluir usuário:', error);
        
        // Retorna um erro 500 (erro interno do servidor) com mensagem
        res.status(500).json({error: 'Erro no servidor'});
    }
};
