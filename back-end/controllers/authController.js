// Importa a biblioteca bcrypt para criptografar senhas
import bcrypt from 'bcrypt';
// Importa a biblioteca jsonwebtoken para gerar tokens JWT
import jwt from 'jsonwebtoken';
// Importa a conexão com o banco de dados
import pool from '../database/connection.js';

// Função para registrar um novo usuário
export const register = async (req, res) => {
  try {
    // Extrai os dados do corpo da requisição
    const { nome, email, senha, cpf, telefone, tipo_usuario } = req.body;

    // Verifica se o tipo de usuário é válido (apenas 'cliente' ou 'admin')
    if (!['cliente', 'admin'].includes(tipo_usuario)) {
      return res.status(400).json({ error: 'Tipo de usuário inválido' });
    }

    // Criptografa a senha com bcrypt
    const hashedPassword = await bcrypt.hash(senha, 10);

    // Chama a procedure no banco para inserir o novo usuário
    await pool.query('CALL inserir_usuario(?, ?, ?, ?, ?, ?)', [
      nome, cpf, telefone, email, hashedPassword, tipo_usuario
    ]);

    // Retorna resposta de sucesso
    res.status(201).json({ message: 'Usuário criado com sucesso!' });
  } catch (error) {
    // Mostra o erro no console
    console.error("Erro no registro:", error);

    // Verifica se o erro foi por duplicidade (email ou CPF já cadastrados)
    if (error.code === 'ER_DUP_ENTRY') {
      return res.status(400).json({ error: 'Email ou CPF já cadastrado' });
    }

    // Resposta genérica de erro
    res.status(500).json({ error: 'Erro no servidor' });
  }
};

// Função para login do usuário
export const login = async (req, res) => {
  try {
    // Extrai o email e senha do corpo da requisição
    const { email, senha } = req.body;

    // Consulta o usuário no banco pelo email
    const [users] = await pool.query('SELECT * FROM usuarios WHERE email = ?', [email]);

    // Se não encontrar usuário, retorna erro
    if (!users.length) return res.status(401).json({ error: 'Credenciais inválidas' });

    // Pega o primeiro usuário encontrado
    const user = users[0];

    // Compara a senha informada com a senha criptografada no banco
    const validPassword = await bcrypt.compare(senha, user.senha);

    // Se a senha for inválida, retorna erro
    if (!validPassword) return res.status(401).json({ error: 'Credenciais inválidas' });

    // Gera um token JWT com dados do usuário e validade de 1 hora
    const token = jwt.sign(
      {
        id: user.id_usuario,
        email: user.email,
        tipo_usuario: user.tipo_usuario
      },
      process.env.JWT_SECRET, // Chave secreta do .env
      { expiresIn: '1h' } // Tempo de expiração
    );

    // Retorna o token e os dados do usuário
    res.json({
      token,
      user: {
        id: user.id_usuario,
        nome: user.nome,
        email: user.email,
        cpf: user.cpf,
        telefone: user.telefone,
        tipo: user.tipo_usuario
      }
    });
  } catch (error) {
    // Mostra erro no console
    console.error("Erro no login:", error);

    // Retorna erro genérico
    res.status(500).json({ error: 'Erro no servidor' });
  }
};

// Função para atualizar dados do usuário
export const atualizarUsuario = async (req, res) => {
  try {
    // Pega o email do corpo da requisição ou do token JWT (se autenticado)
    const userEmail = req.body.email || req.user?.email;

    // Se não houver email, retorna erro
    if (!userEmail) {
      return res.status(400).json({ error: 'Email é obrigatório' });
    }

    // Verifica se o usuário existe no banco
    const [usuarios] = await pool.query('SELECT * FROM usuarios WHERE email = ?', [userEmail]);

    // Se não encontrar o usuário, retorna erro
    if (!usuarios.length) {
      return res.status(404).json({ error: 'Email não encontrado' });
    }

    // Extrai os dados a serem atualizados do corpo da requisição
    const { nome, telefone, senha } = req.body;

    // Se a senha foi enviada, criptografa
    const senhaHash = senha ? await bcrypt.hash(senha, 10) : null;

    // Atualiza os dados do usuário no banco de dados
    await pool.query(
      `UPDATE usuarios SET
        nome = COALESCE(?, nome),         -- Atualiza se novo nome foi enviado
        telefone = COALESCE(?, telefone), -- Atualiza se novo telefone foi enviado
        senha = COALESCE(?, senha)        -- Atualiza se nova senha foi enviada
      WHERE email = ?`,                   // Localiza o usuário pelo email
      [nome, telefone, senhaHash, userEmail]
    );

    // Retorna mensagem de sucesso
    res.json({ message: 'Dados atualizados com sucesso!' });
  } catch (error) {
    // Mostra erro no console
    console.log('Erro ao atualizar usuário:', error);

    // Retorna erro genérico
    res.status(500).json({ error: 'Erro no servidor' });
  }
};
