// Importa o módulo mysql2/promise para usar conexões com o MySQL usando Promises
import mysql from 'mysql2/promise';

// Importa o módulo dotenv para carregar variáveis de ambiente do arquivo .env
import dotenv from 'dotenv';

// Carrega as variáveis de ambiente do arquivo .env para process.env
dotenv.config();

// Lista das variáveis de ambiente obrigatórias
const requiredEnvVars = ['DB_HOST', 'DB_USER', 'DB_PASSWORD', 'DB_NAME', 'DB_PORT'];

// Verifica se todas as variáveis de ambiente necessárias estão definidas
for (const envVar of requiredEnvVars) {
  if (!process.env[envVar]) {
    // Lança um erro se alguma variável obrigatória estiver ausente
    throw new Error(`Variável de ambiente ${envVar} não definida`);
  }
}

// Cria um pool de conexões com o banco de dados MySQL
const pool = mysql.createPool({
  host: process.env.DB_HOST,           // Endereço do host do banco
  user: process.env.DB_USER,           // Nome de usuário do banco
  password: process.env.DB_PASSWORD,   // Senha do banco
  database: process.env.DB_NAME,       // Nome do banco de dados
  port: Number(process.env.DB_PORT),   // Porta convertida para número
  waitForConnections: true,            // Espera por conexões disponíveis
  connectionLimit: 10,                 // Número máximo de conexões simultâneas
  queueLimit: 0,                       // Tamanho máximo da fila de conexões pendentes (0 = ilimitado)
  connectTimeout: 10000                // Tempo limite para tentar conectar (em ms)
});

// Testa se a conexão está pegando o banco de dados correto
pool.query('SELECT DATABASE() AS db')
  .then(([rows]) => console.log('Conectado ao banco:', rows[0].db))
  .catch(err => console.error('Erro ao verificar database:', err));

// Teste assíncrono imediato da conexão ao iniciar a aplicação
(async () => {
  try {
    // Obtém uma conexão do pool
    const connection = await pool.getConnection();
    // Loga no console se a conexão foi bem-sucedida
    console.log('✅ Conexão com o MySQL estabelecida com sucesso!');
    // Libera a conexão de volta ao pool
    connection.release();
  } catch (error) {
    // Mostra o erro de conexão no console
    console.error('❌ Erro ao conectar ao MySQL:', error.message);
    // Encerra a aplicação com erro
    process.exit(1);
  }
})();

// Exporta o pool para ser usado em outras partes do projeto (ex: nas queries)
export default pool;
