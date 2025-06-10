// Importa o módulo express para criação das rotas
import express from 'express';

// Importa as funções controller responsáveis pelas operações de autenticação e atualização de usuário
import { register, login, atualizarUsuario } from '../controllers/authController.js';

// Cria uma instância do roteador do Express para definir as rotas
const router = express.Router();

// Rota POST para registrar um novo usuário, chama a função register do controller
router.post('/register', register);

// Rota POST para fazer login, chama a função login do controller
router.post('/login', login);

// Rota PUT para atualizar dados do usuário, chama a função atualizarUsuario do controller
router.put('/update', atualizarUsuario);

// Exporta o roteador para ser usado na aplicação principal (ex: app.js ou server.js)
export default router;
