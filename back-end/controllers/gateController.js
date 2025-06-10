// Importa a biblioteca JWT para verificar tokens
import jwt from 'jsonwebtoken';
// Importa a conexão com o banco de dados
import pool from '../database/connection.js';

// Função que controla a abertura/fechamento do portão
export const controlGate = async (req, res) => {
    try {
        // Extrai a ação e descrição do corpo da requisição
        const { acao, descricao } = req.body;

        // Extrai o token JWT do header Authorization (formato: "Bearer <token>")
        const token = req.headers.authorization.split(' ')[1];

        // Decodifica e verifica o token usando a chave secreta
        const decoded = jwt.verify(token, process.env.JWT_SECRET);

        // Lista de ações válidas que o sistema permite
        const acoesPermitidas = ['abrir', 'fechar', 'parar'];

        // Se a ação não for válida, retorna erro 400
        if (!acoesPermitidas.includes(acao)) {
            return res.status(400).json({ error: 'Ação inválida' });
        }

        // Insere um novo registro de ação no banco de dados, usando uma procedure
        await pool.query(
            'CALL inserir_registro(?, ?)',
            [descricao || `Portão ${acao}`, decoded.id] // Usa descrição fornecida ou uma padrão
        );

        // Retorna mensagem de sucesso
        res.json({ message: `Portão ${acao} com sucesso!` });
    } catch (error) {
        // Em caso de erro, exibe no console
        console.log('Erro no controle do portão:', error);

        // Retorna erro genérico de servidor
        res.status(500).json({ error: 'Erro no servidor' });
    }
};

// Função para retornar o histórico de ações do portão
export const history = async (req, res) => {
    try {
        // Executa uma consulta SQL para retornar os 50 registros mais recentes
        const [rows] = await pool.query(
            `SELECT r.*, u.nome, u.tipo_usuario
            FROM registros r
            JOIN usuarios u ON r.id_usuario = u.id_usuario
            ORDER BY r.dt_acao DESC
            LIMIT 50`
        );

        // Retorna os dados em formato JSON
        res.json(rows);
    } catch (error) {
        // Exibe erro no console
        console.log('Erro ao buscar histórico:', error);

        // Retorna erro genérico
        res.status(500).json({ error: 'Erro no servidor' });
    }
};

// Função para deletar um registro de ação
export const deleteRegistro = async (req, res) => {
    try {
        // Extrai o id do registro a ser deletado dos parâmetros da URL
        const { id } = req.params;

        // Extrai e verifica o token JWT
        const token = req.headers.authorization.split(' ')[1];
        const decoded = jwt.verify(token, process.env.JWT_SECRET);

        // Verifica se o registro existe no banco
        const [registro] = await pool.query('SELECT * FROM registros WHERE id_registro = ?', [id]);

        // Se o registro não for encontrado, retorna erro 404
        if (!registro.length) {
            return res.status(404).json({ error: 'Registro não encontrado' });
        }

        // Chama a procedure para excluir o registro
        await pool.query('CALL excluir_registro(?)', [id]);

        // Retorna mensagem de sucesso
        res.json({ message: 'Registro excluído com sucesso!' });
    } catch (error) {
        // Mostra erro no console
        console.log('Erro ao excluir registro:', error);

        // Retorna erro genérico
        res.status(500).json({ error: 'Erro no servidor' });
    }
};

// Função para buscar os logs de ações no sistema
export const getLogs = async (req, res) => {
    try {
        // Consulta os últimos 100 logs registrados no banco
        const [rows] = await pool.query(
            `SELECT * FROM log
            ORDER BY dt_trigger DESC
            LIMIT 100`
        );

        // Retorna os logs em formato JSON
        res.json(rows);
    } catch (error) {
        // Mostra erro no console
        console.log('Erro ao buscar logs:', error);

        // Retorna erro genérico
        res.status(500).json({ error: 'Erro no servidor' });
    }
};
