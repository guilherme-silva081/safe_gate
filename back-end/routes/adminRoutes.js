// Importa o Express para criar rotas
import express from 'express';

// Importa os controladores responsáveis pelas funcionalidades de admin
import { getUsuarios, deleteUsuario } from '../controllers/adminController.js';

// Importa os middlewares de autenticação e autorização
import { verifyToken, adminOnly } from '../middlewares/authMiddleware.js';

// Importa a função que retorna os logs do sistema
import { getLogs } from '../controllers/gateController.js';

// Cria uma instância do roteador do Express
const router = express.Router();

// Rota GET para listar todos os usuários (restrita a administradores autenticados)
router.get('/users', verifyToken, adminOnly, getUsuarios);

// Rota DELETE para excluir um usuário pelo email (restrita a administradores autenticados)
router.delete('/users/:email', verifyToken, adminOnly, deleteUsuario);

// Rota GET para listar os logs do sistema (restrita a administradores autenticados)
router.get('/logs', verifyToken, adminOnly, getLogs);

// Exporta o roteador para ser usado no arquivo principal (ex: app.js ou server.js)
export default router;
