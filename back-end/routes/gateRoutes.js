// Importa o framework Express para criar o roteador
import express from 'express';

// Importa as funções controladoras responsáveis pelo controle do portão, histórico, logs e exclusão de registros
import { controlGate, history, getLogs, deleteRegistro } from '../controllers/gateController.js';

// Importa o middleware que verifica o token JWT para proteger as rotas
import { verifyToken } from '../middlewares/authMiddleware.js';

// Cria uma instância do roteador Express para definir rotas específicas
const router = express.Router();

// Rota POST para realizar ações no portão (abrir, fechar, parar), protegida por verificação de token JWT
router.post('/action', verifyToken, controlGate);

// Rota GET para buscar o histórico das ações realizadas no portão, protegida por verificação de token JWT
router.get('/history', verifyToken, history);

// Rota GET para obter os logs do sistema, protegida por verificação de token JWT
router.get('/logs', verifyToken, getLogs);

// Rota DELETE para excluir um registro do histórico pelo ID, protegida por verificação de token JWT
router.delete('/history/:id', verifyToken, deleteRegistro);

// Exporta o roteador para ser usado em outras partes da aplicação
export default router;
