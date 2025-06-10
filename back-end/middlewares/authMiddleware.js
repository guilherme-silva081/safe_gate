// Importa a biblioteca jsonwebtoken para trabalhar com JWT (tokens de autenticação)
import jwt from 'jsonwebtoken';

// Importa o pool de conexões com o banco de dados
import pool from '../database/connection.js';

// Middleware para verificar se o token JWT é válido
export const verifyToken = (req, res, next) => {
    // Obtém o token do header "Authorization" (formato: "Bearer <token>")
    const token = req.headers.authorization?.split(' ')[1];

    // Se não houver token, retorna erro 401 (não autorizado)
    if (!token) return res.status(401).json({ error: 'Acesso negado' });

    try {
        // Verifica e decodifica o token, e salva os dados do usuário na requisição
        req.user = jwt.verify(token, process.env.JWT_SECRET);

        // Chama o próximo middleware ou rota
        next();
    } catch (error) {
        // Se o token for inválido, retorna erro 400 (requisição inválida)
        res.status(400).json({ error: 'Token inválido' });
    }
};

// Middleware para restringir acesso apenas a administradores
export const adminOnly = async (req, res, next) => {
    // Mostra no console os dados do usuário extraídos do token
    console.log('req.user', req.user);
    console.log('Email usado na query:', req.user.email);

    // Se o tipo do usuário for "admin", permite o acesso imediatamente
    if (req.user.tipo === 'admin') {
        return next();
    }

    try {
        // Consulta o tipo de usuário no banco de dados com base no e-mail
        const [users] = await pool.query(
            'SELECT tipo_usuario FROM usuarios WHERE email = ?',
            [req.user.email]
        );

        // Se não encontrou o usuário ou ele não for admin, bloqueia o acesso
        if (!users.length || users[0].tipo_usuario !== 'admin') {
            return res.status(403).json({ error: 'Acesso restrito a administradores' });
        }

        // Se for admin, continua para o próximo middleware ou rota
        next();
    } catch (error) {
        // Em caso de erro na consulta ao banco, retorna erro 500
        res.status(500).json({ error: 'Erro ao verificar permissões' });
    }
};
