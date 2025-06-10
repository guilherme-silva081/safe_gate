// Importa o framework Express para criação do servidor e rotas
import express from 'express';

// Importa o middleware CORS para permitir requisições entre diferentes origens
import cors from 'cors';

// Importa dotenv para carregar variáveis de ambiente do arquivo .env
import dotenv from 'dotenv';

// Importa os módulos de rotas para autenticação, controle do portão e administração
import authRoutes from './routes/authRoutes.js';
import gateRoutes from './routes/gateRoutes.js';
import adminRoutes from './routes/adminRoutes.js';

// Carrega as variáveis do arquivo .env para process.env
dotenv.config();

// Cria uma instância da aplicação Express
const app = express();

// Define a porta para o servidor (usa a variável de ambiente PORT ou padrão 3000)
const PORT = process.env.PORT || 3000;

// Aplica o middleware CORS para permitir requisições externas
app.use(cors());

// Habilita o middleware para interpretar requisições com JSON no corpo
app.use(express.json());

// Define as rotas para cada funcionalidade, prefixadas por seus caminhos
app.use('/auth', authRoutes);   // Rotas de autenticação
app.use('/gate', gateRoutes);   // Rotas para controle do portão
app.use('/admin', adminRoutes); // Rotas administrativas (usuários, logs, etc)

// Rota raiz para teste simples da API
app.get('/', (req, res) => res.send('API SafeGate Online!'));

// Inicia o servidor na porta definida e exibe mensagem no console
app.listen(PORT, () => console.log(`Server rodando na porta ${PORT}`));
