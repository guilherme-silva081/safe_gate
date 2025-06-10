import 'package:flutter/material.dart'; // Importa o framework Flutter para UI
import 'package:provider/provider.dart'; // Importa Provider para gerenciar estado
import 'package:google_fonts/google_fonts.dart'; // Importa fonte Google Fonts
import 'package:marquee/marquee.dart'; // Importa widget para texto rolando (marquee)
import 'package:http/http.dart' as http; // Importa pacote http para requisições
import 'dart:convert'; // Importa para manipular JSON
import 'tela_login.dart'; // Importa tela de login (arquivo local)
import 'tela_alt_senha.dart'; // Importa tela para alterar senha (arquivo local)
import 'tela_historico.dart'; // Importa tela de histórico (arquivo local)
import 'tela_gestao_users.dart'; // Importa tela de gestão de usuários (arquivo local)
import 'tela_perfil.dart'; // Importa tela de perfil do usuário (arquivo local)

void main() => runApp(const MyApp()); // Função principal que inicia o app Flutter

// Classe para gerenciar o histórico de ações, estende ChangeNotifier para atualizar UI
class HistoricoManager extends ChangeNotifier {
  final AuthManager authManager; // Recebe o gerenciador de autenticação
  HistoricoManager(this.authManager); // Construtor recebe o authManager

  // Método para buscar histórico via API
  Future<List<ItemHistorico>> fetchHistory() async {
    try {
      // Faz requisição GET para endpoint do histórico com token de autorização
      final response = await http.get(
        Uri.parse(
            'https://projeto-safe-gate-production.up.railway.app/gate/history'),
        headers: {
          'Authorization': 'Bearer ${authManager._token}', // Token JWT no header
        },
      );

      // Se resposta OK (200)
      if (response.statusCode == 200) {
        // Decodifica o JSON retornado para lista dinâmica
        final List<dynamic> data = jsonDecode(response.body);
        // Mapeia cada item JSON para um objeto ItemHistorico
        return data
            .map((item) => ItemHistorico(
                  item['id_registro'], // ID do registro
                  item['ds_registro'] ?? 'Ação no portão', // Descrição (fallback)
                  _formatTime(item['dt_acao']), // Formata horário
                  _getDiaSemana(DateTime.parse(item['dt_acao']).weekday), // Dia da semana
                  _formatDate(item['dt_acao']), // Formata data
                ))
            .toList(); // Retorna lista convertida
      } else {
        // Se código diferente de 200 lança exceção
        throw Exception('Falha ao carregar histórico');
      }
    } catch (error) {
      // Em caso de erro de conexão ou outro lança exceção
      throw Exception('Erro de conexão: $error');
    }
  }

  // Método privado para formatar horário da data em string "HH:mm"
  String _formatTime(String dateTime) {
    final dt = DateTime.parse(dateTime).toLocal(); // Converte para hora local
    return '${dt.hour}:${dt.minute.toString().padLeft(2, '0')}'; // Formato "hora:minuto"
  }

  // Método privado para formatar data em string "dd/MM/yyyy"
  String _formatDate(String dateTime) {
    final dt = DateTime.parse(dateTime).toLocal(); // Converte para hora local
    return "${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}";
  }

  final List<ItemHistorico> _historico = []; // Lista interna do histórico
  int _aberturas = 0; // Contador de ações de abrir portão
  int _fechamentos = 0; // Contador de fechar portão
  int _paradas = 0; // Contador de paradas do portão
  String? _ultimaAcao; // Guarda última ação realizada para evitar repetição

  // Getter para obter histórico invertido (mais recentes primeiro)
  List<ItemHistorico> get historico => List.from(_historico.reversed);
  int get totalAcoes => _aberturas + _fechamentos + _paradas; // Total de ações
  int get aberturas => _aberturas; // Getter para aberturas
  int get fechamentos => _fechamentos; // Getter para fechamentos
  int get paradas => _paradas; // Getter para paradas

  // Método que checa se uma nova ação pode ser realizada (não repetir consecutivamente)
  bool podeRealizarAcao(String novaAcao) {
    return _ultimaAcao == null || _ultimaAcao != novaAcao;
  }

  // Método para obter o contador de um tipo específico de ação
  int getContador(String tipoAcao) {
    switch (tipoAcao.toLowerCase()) {
      case 'abrir':
        return _aberturas;
      case 'fechar':
        return _fechamentos;
      case 'parar':
        return _paradas;
      default:
        return 0;
    }
  }

  // Método para adicionar uma ação (abrir/fechar/parar)
  Future<void> adicionarAcao(String acao) async {
    // Bloqueia se a ação for igual à última feita
    if (!podeRealizarAcao(acao)) {
      throw Exception('Ação bloqueada: Portão já $acao');
    }

    // Verifica se o usuário está autenticado
    if (authManager._token == null) {
      throw Exception('Usuário não autenticado');
    }

    try {
      // Faz requisição POST para a API com ação e descrição
      final response = await http.post(
        Uri.parse(
            'https://projeto-safe-gate-production.up.railway.app/gate/action'),
        headers: {
          'Content-type': 'application/json', // Tipo do conteúdo
          'Authorization': 'Bearer ${authManager._token}', // Token JWT
        },
        body: jsonEncode({'acao': acao, 'descricao': 'Portão $acao'}),
      );

      // Se a resposta for sucesso (200)
      if (response.statusCode == 200) {
        final now = DateTime.now(); // Data e hora atuais

        // Cria um novo item de histórico com dados atuais
        final item = ItemHistorico(
          0,
          'Portão $acao',
          '${now.hour}:${now.minute.toString().padLeft(2, '0')}',
          _getDiaSemana(now.weekday),
          '${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year}',
        );

        _historico.add(item); // Adiciona o novo item ao histórico local
        _ultimaAcao = acao; // Atualiza última ação realizada

        // Atualiza os contadores conforme o tipo de ação
        switch (acao) {
          case 'abrir':
            _aberturas++;
            break;
          case 'fechar':
            _fechamentos++;
            break;
          case 'parar':
            _paradas++;
            break;
        }
        notifyListeners(); // Notifica UI que houve atualização
      } else {
        // Se a resposta não foi 200, lança exceção com mensagem da API ou padrão
        throw Exception(
            jsonDecode(response.body)['error'] ?? 'Falha ao executar ação');
      }
    } catch (error) {
      // Lança exceção em caso de erro de conexão ou outro
      throw Exception('Erro de conexão: $error');
    }
  }

  // Método para remover um item do histórico via API
  Future<void> removerItem(ItemHistorico item) async {
    try {
      // Faz requisição DELETE para o endpoint com o id do item
      final response = await http.delete(
        Uri.parse(
            'https://projeto-safe-gate-production.up.railway.app/gate/history/${item.id}'),
        headers: {
          'Authorization': 'Bearer ${authManager._token}', // Token JWT
          'Content-type': 'application/json', // Tipo do conteúdo
        },
      );
      // Se sucesso (200), remove o item da lista local e notifica UI
      if (response.statusCode == 200) {
        _historico.remove(item);
        notifyListeners();
      } else {
        throw Exception('Falha ao remover histórico'); // Erro ao remover
      }
    } catch (error) {
      throw Exception('Erro de conexão: $error'); // Erro na conexão
    }
  }

  // Método auxiliar para retornar o nome do dia da semana a partir do número
  String _getDiaSemana(int weekday) {
    const dias = [
      'Segunda-feira',
      'Terça-feira',
      'Quarta-feira',
      'Quinta-feira',
      'Sexta-feira',
      'Sábado',
      'Domingo'
    ];
    return dias[(weekday - 1) % 7]; // Ajusta índice para array (0-based)
  }
}

// Classe que representa um item do histórico
class ItemHistorico {
  final int id; // ID do registro no banco
  final String descricao; // Descrição da ação
  final String horario; // Horário da ação formatado
  final String diaSemana; // Dia da semana da ação
  final String data; // Data da ação formatada

  ItemHistorico(this.id, this.descricao, this.horario, this.diaSemana, this.data); // Construtor
}


      if (response.statusCode == 200) { // Verifica se a resposta da API foi sucesso
  final index = _historico.indexWhere((i) => i.id == item.id); // Busca índice do item a ser removido na lista

  if (index != -1) { // Se encontrou o item
    final itemRemovido = _historico.removeAt(index); // Remove o item da lista
    final acao = itemRemovido.titulo.replaceAll('Joãozinho', '').trim(); // Remove 'Joãozinho' do título e limpa espaços

    switch (acao) { // Ajusta os contadores de acordo com a ação removida
      case 'abrir':
        _aberturas--;
        break;
      case 'fechar':
        _fechamentos--;
        break;
      case 'parar':
        _paradas--;
        break;
    }

    if (_historico.isEmpty) { // Se não há mais itens no histórico
      _ultimaAcao = null; // Zera a última ação
    } else if (_historico.last.titulo.contains(acao)) { // Se o último item tem a mesma ação
      _ultimaAcao = acao; // Atualiza a última ação
    }

    notifyListeners(); // Notifica UI sobre mudanças
  }
} else {
  throw Exception('Falha ao excluir registro'); // Erro ao excluir registro
}
} catch (error) {
  throw Exception('Erro de conexão: $error'); // Erro de conexão capturado
}
}

// Função para retornar o nome do dia da semana baseado no índice
String _getDiaSemana(int weekday) {
  const dias = [
    'Domingo',
    'Segunda-feira',
    'Terça-feira',
    'Quarta-feira',
    'Quinta-feira',
    'Sexta-feira',
    'Sábado'
  ];
  return dias[weekday % 7]; // Retorna o nome do dia correto
}
}

// Classe para gerenciar autenticação, estende ChangeNotifier para atualizar UI
class AuthManager extends ChangeNotifier {
  String? _token; // Token JWT armazenado
  String? get token => _token; // Getter para token
  Map<String, dynamic>? _user; // Dados do usuário logado

  bool get isAuthenticated => _token != null; // Indica se está autenticado
  Map<String, dynamic>? get user => _user; // Getter para dados do usuário

  // Método para login, recebe email e senha
  Future<void> login(String email, String senha) async {
    try {
      // Faz requisição POST para o endpoint de login
      final response = await http.post(
        Uri.parse(
            'https://projeto-safe-gate-production.up.railway.app/auth/login'),
        headers: {'Content-type': 'application/json'}, // Define header JSON
        body: jsonEncode({'email': email, 'senha': senha}), // Envia dados de login
      );

      if (response.statusCode == 200) { // Se login bem-sucedido
        final responseData = jsonDecode(response.body); // Decodifica resposta JSON
        _token = responseData['token']; // Guarda token recebido
        _user = responseData['user']; // Guarda dados do usuário
        notifyListeners(); // Atualiza a UI
      } else {
        // Caso falhe, lança erro com a mensagem da API ou padrão
        throw Exception(
            jsonDecode(response.body)['error'] ?? 'Credenciais inválidas');
      }
    } catch (error) {
      // Caso erro de conexão ou outro
      throw Exception('Erro ao fazer login: $error');
    }
  }

  // Método para registrar novo usuário, recebe dados como Map<String, String>
  Future<void> register(Map<String, String> dados) async {
    try {
      // Faz requisição POST para endpoint de registro
      final response = await http.post(
        Uri.parse(
            'https://projeto-safe-gate-production.up.railway.app/auth/register'),
        headers: {'Content-type': 'application/json'}, // Header JSON
        body: jsonEncode(dados), // Envia dados do usuário para registro
      );


    if (response.statusCode != 201) { // Se o status não for 201 (Criado)
  final errorData = jsonDecode(response.body); // Decodifica o corpo da resposta
  throw Exception(errorData['error'] ?? 'Erro ao registrar'); // Lança exceção com erro da API ou padrão
}
} catch (error) {
  throw Exception('Erro ao registrar: $error'); // Captura erro de conexão ou outro
}
}

// Método para atualizar dados do usuário
Future<void> updateUser(Map<String, dynamic> dados) async {
  try {
    // Requisição PUT para atualizar usuário
    final response = await http.put(
      Uri.parse(
          'https://projeto-safe-gate-production.up.railway.app/auth/update'),
      headers: {
        'Content-type': 'application/json', // Header JSON
        'Authorization': 'Bearer $_token', // Token para autenticação
      },
      body: jsonEncode(dados), // Envia os dados a serem atualizados
    );

    if (response.statusCode == 200) { // Se atualização foi bem-sucedida
      _user = { // Atualiza localmente o mapa de usuário
        ...?_user, // Mantém os dados antigos
        if (dados['nome'] != null) 'nome': dados['nome'], // Atualiza nome se foi enviado
        if (dados['telefone'] != null) 'telefone': dados['telefone'], // Atualiza telefone se foi enviado
      };
      notifyListeners(); // Notifica listeners para atualizar UI
    }

    if (response.statusCode != 200) { // Se o status não for 200 (OK)
      throw Exception('Erro ao atualizar usuário'); // Lança erro genérico
    }
  } catch (error) {
    throw Exception('Erro ao atualizar: $error'); // Captura erro de conexão ou outro
  }
}

// Método para logout, limpa token e dados do usuário
void logout() {
  _token = null; // Limpa token
  _user = null; // Limpa dados do usuário
  notifyListeners(); // Notifica listeners para atualizar UI
}
}

// Widget principal do app, Stateful para controlar tema
class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool _isDarkMode = false; // Flag para tema escuro/claro
  final authManager = AuthManager(); // Instância do gerenciador de autenticação

  @override
  Widget build(BuildContext context) {
    return MultiProvider( // Provê múltiplos providers para gerenciamento de estado
      providers: [
        ChangeNotifierProvider(create: (context) => authManager), // Provider do AuthManager
        ChangeNotifierProvider(
          create: (context) => HistoricoManager(authManager), // Provider do Histórico com dependência do AuthManager
        ),
      ],
      child: MaterialApp(
        title: 'SafeGate', // Título do app
        debugShowCheckedModeBanner: false, // Remove a faixa de debug
        theme: _isDarkMode
            ? ThemeData.dark().copyWith(primaryColor: const Color(0xFF002366)) // Tema escuro customizado
            : ThemeData.light().copyWith(primaryColor: const Color(0xFF4682B4)), // Tema claro customizado
        initialRoute: '/', // Rota inicial
        routes: { // Rotas nomeadas do app
          '/': (context) => LoginScreen( // Tela de login
                onLoginSuccess: () {
                  Navigator.pushReplacementNamed(context, '/home'); // Navega para home após login
                },
              ),
          '/home': (context) => MyHomePage( // Tela principal após login
                isDarkMode: _isDarkMode, // Passa estado do tema
                onThemeChanged: () {
                  setState(
                    () {
                      _isDarkMode = !_isDarkMode; // Alterna o tema entre claro e escuro
                    },
                  );
                },
              ),
          '/telaHistorico': (context) => const TelaHistorico(), // Tela de histórico
          '/telaAltSenha': (context) => const TelaAltSenha(), // Tela de alteração de senha
          '/tela_gestao_users': (context) => const TelaGestaoUsers(), // Tela de gestão de usuários
          '/perfil': (context) => const TelaPerfil(), // Tela de perfil do usuário
        },
      ),
    );
  }
}


class MyHomePage extends StatelessWidget {
  final VoidCallback onThemeChanged; // Callback para alternar tema
  final bool isDarkMode; // Flag que indica se está no modo escuro

  const MyHomePage({
    super.key,
    required this.onThemeChanged,
    required this.isDarkMode,
  });

  // Método privado que cria o botão de ação (abrir, fechar, parar portão)
  Widget _buildBotaoAcao({
    required BuildContext context,
    required String texto, // Texto do botão
    required IconData icone, // Ícone do botão
    required String acaoTipo, // Tipo da ação (abrir, fechar, parar)
  }) {
    return Consumer<HistoricoManager>( // Consumer para acessar estado do histórico
      builder: (context, historico, child) {
        final podeExecutar = historico.podeRealizarAcao(acaoTipo); // Verifica se ação é permitida

        return Card( // Cartão para o botão
          color: Theme.of(context).colorScheme.secondaryContainer, // Cor do tema
          elevation: 6, // Sombra do cartão
          child: InkWell( // Efeito de clique
            borderRadius: BorderRadius.circular(4), // Borda arredondada
            onTap: podeExecutar // Se pode executar ação
                ? () async {
                    try {
                      await historico.adicionarAcao(acaoTipo); // Executa ação no histórico
                    } catch (error) {
                      // Mostra erro na tela via SnackBar
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: Text('Erro: ${error.toString()}'),
                        duration: const Duration(seconds: 1),
                      ));
                    }
                  }
                : () { // Se ação não pode ser executada (bloqueada)
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text('Ação bloqueada: Portão já $acaoTipo'),
                      duration: const Duration(seconds: 1),
                    ));
                  },
            child: Padding( // Espaçamento interno
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: SizedBox(
                height: 65, // Altura fixa do botão
                child: Row( // Linha para alinhar ícone, texto e contador
                  mainAxisAlignment: MainAxisAlignment.spaceBetween, // Espaço entre elementos
                  children: [
                    Icon(icone), // Ícone da ação
                    Text(
                      texto, // Texto da ação
                      style: GoogleFonts.roboto(
                        fontSize: 25.6,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '${historico.getContador(acaoTipo)}', // Mostra quantas vezes a ação foi feita
                      style: GoogleFonts.inter(
                        fontSize: 25.6,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar( // Barra superior do app
        backgroundColor: Theme.of(context).primaryColor, // Cor do tema principal
        title: Text(
          'SafeGate', // Título do app
          style: GoogleFonts.workSans(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          Builder( // Usado para pegar contexto do Scaffold e abrir o drawer
            builder: (context) => IconButton(
              icon: const Icon(Icons.settings, color: Colors.white), // Ícone de configurações
              onPressed: () => Scaffold.of(context).openEndDrawer(), // Abre a gaveta lateral
            ),
          ),
        ],
      ),
      endDrawer: Drawer( // Gaveta lateral (continua...)

       width: 300, // Define a largura fixa da gaveta lateral (Drawer)
// Define o formato da borda com canto arredondado só no lado esquerdo
shape: const RoundedRectangleBorder(
  borderRadius: BorderRadius.horizontal(
    left: Radius.circular(20), // Arredonda apenas o canto esquerdo
  ),
),
elevation: 10, // Sombra da gaveta para destaque

child: ListView( // Conteúdo da gaveta em uma lista rolável
  padding: EdgeInsets.zero, // Remove o padding padrão
  children: [
    DrawerHeader( // Cabeçalho da gaveta
      decoration: BoxDecoration(color: Theme.of(context).primaryColor), // Fundo da cor principal
      padding: const EdgeInsets.all(16), // Espaçamento interno
      child: SizedBox(
        height: 30, // Altura fixa para o conteúdo
        child: Column( // Coluna para alinhar título e texto de boas-vindas
          mainAxisAlignment: MainAxisAlignment.end, // Alinha conteúdo no final verticalmente
          crossAxisAlignment: CrossAxisAlignment.start, // Alinha à esquerda horizontalmente
          children: [
            const Text(
              'Configurações', // Título do Drawer
              style: TextStyle(
                color: Colors.white, // Cor branca para contraste
                fontSize: 24, // Tamanho da fonte
                fontWeight: FontWeight.bold, // Negrito
              ),
            ),
            const SizedBox(height: 8), // Espaço vertical entre o título e o texto
            Consumer<AuthManager>( // Atualiza o texto com o nome do usuário logado
              builder: (content, auth, child) => Text(
                'Olá, ${auth.user?['nome'] ?? 'Usuário'}!', // Saudação personalizada
                style: const TextStyle(
                  fontSize: 18.6,
                  color: Colors.white, // Cor branca
                ),
              ),
            ),
          ],
        ),
      ),
    ),
    InkWell( // Elemento clicável para ir à tela de perfil
      onTap: () {
        Navigator.pushNamed(context, '/perfil'); // Navega para a rota do perfil
      },
      child: Container( // Container com margem e decoração
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), // Espaço em volta
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.secondaryContainer, // Cor de fundo secundária
          borderRadius: BorderRadius.circular(12), // Borda arredondada
        ),
        child: Consumer<AuthManager>( // Usa o estado do usuário para preencher dados
          builder: (context, auth, child) => ListTile( // Tile padrão do Flutter
            title: Text(
              auth.user?['nome'] ?? 'Usuário', // Nome do usuário ou padrão
              style: TextStyle(
                fontSize: 20.8,
                fontWeight: FontWeight.w500,
                color: Theme.of(context).colorScheme.onSecondaryContainer, // Cor do texto no container secundário
              ),
            ),
            leading: const CircleAvatar( // Avatar circular com ícone de pessoa
              radius: 28,
              child: Icon(Icons.person, size: 36),
            ),
            subtitle: Text(
              auth.user?['email'] ?? '', // Email do usuário
              style: TextStyle(
                color: Colors.grey[600], // Cinza médio para o subtítulo
                fontSize: 14,
              ),
            ),
          ),
        ),
      ),
    ),
    const Divider(height: 2), // Linha divisória fina
    ListTile( // Item da lista para configurar o tema
      leading: Icon(
        Icons.brightness_6, // Ícone para tema
        color: Colors.grey[700], // Cor cinza escuro
      ),
      title: const Text(
        'Tema', // Texto do item
        style: TextStyle(
          fontSize: 20.8,
        ),
      ),

           trailing: Switch( // Interruptor para alternar tema claro/escuro
  value: isDarkMode, // Estado atual do tema (true se modo escuro)
  onChanged: (value) {
    onThemeChanged(); // Chama função para alterar o tema ao mudar o switch
  },
  activeColor: Theme.of(context).primaryColor, // Cor do switch quando ativo
),
),
const Divider(height: 1), // Linha divisória fina entre os itens

ListTile( // Item de menu para alteração de senha
  leading: Icon(
    Icons.lock, // Ícone de cadeado
    color: Colors.grey[700], // Cor cinza escura
  ),
  title: const Text(
    'Alterar senha', // Texto do item
    style: TextStyle(
      fontSize: 20.8,
    ),
  ),
  onTap: () {
    Navigator.pushNamed(context, '/telaAltSenha'); // Navega para a tela de alteração de senha
  },
),

const Divider(height: 1), // Linha divisória

ListTile( // Item para acessar histórico
  leading: Icon(
    Icons.history, // Ícone de histórico
    color: Colors.grey[700],
  ),
  title: const Text(
    'Histórico',
    style: TextStyle(
      fontSize: 20.8,
    ),
  ),
  onTap: () {
    Navigator.pushNamed(context, '/telaHistorico'); // Navega para a tela de histórico
  },
),

const Divider(height: 1), // Linha divisória

ListTile( // Item para gestão de usuários
  leading: Icon(
    Icons.admin_panel_settings, // Ícone de administração
    color: Colors.grey[700],
  ),
  title: Text(
    'Gestão de Usuários',
    style: TextStyle(
      fontSize: 20.8,
    ),
  ),
  onTap: () {
    Navigator.pushNamed(context, '/tela_gestao_users'); // Navega para tela de gestão de usuários
  },
),

const Divider(height: 1), // Linha divisória

ListTile( // Item para sair/logout
  leading: Icon(
    Icons.exit_to_app, // Ícone de saída
    color: Colors.red[400], // Cor vermelha para chamar atenção
  ),
  title: const Text(
    'Sair',
    style: TextStyle(
      fontSize: 20.8,
    ),
  ),
  onTap: () {
    Provider.of<AuthManager>(context, listen: false).logout(); // Executa logout no gerenciador de autenticação
    Navigator.pushReplacementNamed(context, '/'); // Redireciona para a tela inicial/login
  },
),
],
),
),
body: Container( // Corpo principal da tela
  padding: const EdgeInsets.all(24), // Espaçamento interno em todas as direções
  child: Column( // Coluna para organizar widgets verticalmente
    mainAxisAlignment: MainAxisAlignment.spaceBetween, // Espaça os filhos entre si
    children: [
      SizedBox( // Caixa com tamanho fixo
        width: 200,
        height: 200,
        child: Card( // Cartão com sombra e cor
          color: Theme.of(context).primaryColor, // Cor principal do tema
          elevation: 5, // Sombra do cartão
          child: Padding(
            padding: const EdgeInsets.all(8), // Espaçamento interno no cartão
            child: Consumer<HistoricoManager>( // Atualiza UI conforme o estado do histórico
              builder: (context, historico, child) {
                return Column( // Coluna para organizar os textos
                  mainAxisAlignment: MainAxisAlignment.spaceAround, // Espaçamento ao redor
                  children: [
                    SizedBox( // Caixa com altura fixa para o texto animado
                      height: 32,
                      child: Marquee( // Texto rolante para chamar atenção
                        text: 'Total de vezes utilizado', // Texto exibido
                        style: GoogleFonts.roboto( // Fonte estilizada
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white, // Cor branca para contraste
                        ),
                        scrollAxis: Axis.horizontal, // Texto rola na horizontal
                        velocity: 30.0, // Velocidade da rolagem
                        blankSpace: 40.0, // Espaço vazio após o texto
                        pauseAfterRound: Duration(seconds: 1), // Pausa após uma volta completa
                        startPadding: 10.0, // Espaço antes de iniciar o texto
                        accelerationDuration: Duration(seconds: 1), // Tempo para acelerar
                        decelerationDuration: Duration(milliseconds: 500), // Tempo para desacelerar
                      ),
                    ),

                          Text(
  '${historico.totalAcoes}', // Exibe o total de ações realizadas (contador)
  style: GoogleFonts.inter( // Usa a fonte Inter do Google Fonts
    fontSize: 64, // Tamanho grande para destaque
    fontWeight: FontWeight.w600, // Peso da fonte semi-negrito
    color: Colors.white, // Cor branca para contraste no fundo colorido
  ),
),

// Fecha Column com os textos acima

SizedBox(
  width: 300,
  height: 225,
  child: Column( // Coluna para botões de ação
    mainAxisAlignment: MainAxisAlignment.spaceAround, // Espaça os botões igualmente verticalmente
    children: [
      _buildBotaoAcao( // Botão para "ABRIR"
        context: context,
        texto: 'ABRIR',
        icone: Icons.lock_open,
        acaoTipo: 'abrir',
      ),
      _buildBotaoAcao( // Botão para "FECHAR"
        context: context,
        texto: 'FECHAR',
        icone: Icons.lock,
        acaoTipo: 'fechar',
      ),
      _buildBotaoAcao( // Botão para "PARAR"
        context: context,
        texto: 'PARAR',
        icone: Icons.cancel,
        acaoTipo: 'parar',
      ),
    ],
  ),
),

Card(
  color: Theme.of(context).primaryColor, // Cartão com cor principal do tema
  elevation: 4, // Sombra suave
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(8), // Bordas arredondadas
  ),
  child: Padding(
    padding: const EdgeInsets.all(16), // Espaçamento interno do cartão
    child: Consumer<HistoricoManager>( // Atualiza a UI conforme o estado do histórico
      builder: (context, historico, child) {
        if (historico.historico.isEmpty) { // Se não há histórico
          return const SizedBox(
            height: 35, // Altura fixa
            child: Center( // Centraliza texto
              child: Text(
                'Nenhuma ação registrada', // Mensagem de ausência de registros
                style: TextStyle(
                  fontSize: 24,
                  color: Colors.white,
                ),
              ),
            ),
          );
        }

        final ultimo = historico.historico.first; // Pega o registro mais recente
        final acao = ultimo.titulo.replaceAll('Joãozinho', ''); // Limpa o nome para mostrar só a ação
        final texto = // Monta a string para mostrar o último registro formatado
            'Último registro: $acao às ${ultimo.hora} | ${ultimo.dia} | ${ultimo.data}';

        return SizedBox(
          height: 35,
          child: Center(
            child: Marquee( // Texto rolante para exibir o último registro
              text: texto,
              style: GoogleFonts.inter(
                fontSize: 24,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
              scrollAxis: Axis.horizontal,
              blankSpace: 40.0,
              velocity: 30.0,
              pauseAfterRound: Duration(seconds: 1),
              startPadding: 10.0,
              accelerationDuration: Duration(seconds: 1),
              accelerationCurve: Curves.linear,
              decelerationDuration: Duration(milliseconds: 500),
              decelerationCurve: Curves.easeOut,
            ),
          ),
        );
      },
    ),
  ),
),
