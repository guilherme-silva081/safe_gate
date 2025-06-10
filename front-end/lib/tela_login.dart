import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hello/main.dart';              // Para acessar o AuthManager via Provider
import 'tela_cadastro.dart';                   // Tela para cadastro de novos usuários
import 'tela_alt_senha.dart';                  // Tela para alteração/recuperação de senha

// Tela de Login, Stateful pois há interação com campos e visibilidade de senha
class LoginScreen extends StatefulWidget {
  // Callback para informar que o login foi realizado com sucesso
  final VoidCallback onLoginSuccess;

  const LoginScreen({super.key, required this.onLoginSuccess});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // Controladores para recuperar texto digitado nos campos
  final _emailController = TextEditingController();
  final _senhaController = TextEditingController();

  // Controla se o texto da senha está oculto (true = senha escondida)
  bool _esconderTexto = true;

  // Alterna o estado de visibilidade da senha ao clicar no ícone
  void _alternarVisibilidadeTexto() {
    setState(() {
      _esconderTexto = !_esconderTexto;
    });
  }

  // Função para tentar realizar o login usando AuthManager via Provider
  void _login(BuildContext context) async {
    try {
      // Obtém a instância do AuthManager (sem escutar mudanças)
      final auth = Provider.of<AuthManager>(context, listen: false);

      // Chama o método login com email e senha digitados
      await auth.login(_emailController.text, _senhaController.text);

      // Se deu certo, executa o callback informado para sucesso
      widget.onLoginSuccess();
    } catch (error) {
      // Se ocorreu erro, exibe mensagem Snackbar para o usuário
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString())),
      );
    }
  }

  // Navega para a tela de cadastro, com callback para voltar ao login
  void _navegarParaCadastro(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CadastroScreen(
          onCadastroConcluido: () {
            Navigator.pop(context); // Fecha cadastro e volta ao login
          },
        ),
      ),
    );
  }

  // Navega para a tela de alteração/recuperação de senha
  void _navegarParaEsqueciSenha(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const TelaAltSenha(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Pega a cor primária do tema (para aplicar no fundo da tela)
    final primaryColor = Theme.of(context).primaryColor;

    return Scaffold(
      backgroundColor: primaryColor,  // Fundo azul
      body: SafeArea(
        // Evita que o conteúdo fique em áreas ocupadas por notch, status bar, etc.
        child: Center(
          // Centraliza todo o conteúdo horizontalmente
          child: SingleChildScrollView(
            // Permite rolagem caso a tela seja pequena
            padding: const EdgeInsets.all(24), // Espaço em volta do conteúdo
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center, // Centraliza verticalmente
              children: [
                const SizedBox(height: 40), // Espaço no topo

                // Imagem em círculo no topo da tela de login
                const CircleAvatar(
                  radius: 60,  // Tamanho da imagem circular
                  backgroundImage: AssetImage('assets/safe-gate-img.png'), // Imagem local
                  backgroundColor: Colors.transparent, // Fundo transparente
                ),

                const SizedBox(height: 24), // Espaço entre imagem e card

                // Card branco que contém o formulário de login
                Card(
                  elevation: 2,  // Sombra leve
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16), // Bordas arredondadas
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(32), // Espaço interno do card
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Título 'LOGIN' no topo do card
                        Text(
                          'LOGIN',
                          style: GoogleFonts.roboto(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),

                        const SizedBox(height: 32), // Espaço abaixo do título

                        // Campo para o usuário digitar o email
                        TextField(
                          controller: _emailController,
                          decoration: InputDecoration(
                            labelText: 'Email',  // Texto do label
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12), // Bordas arredondadas
                            ),
                          ),
                        ),

                        const SizedBox(height: 16), // Espaço entre os campos

                        // Campo para digitar a senha, com opção de esconder/mostrar
                        TextField(
                          controller: _senhaController,
                          obscureText: _esconderTexto,  // Se true, esconde texto
                          decoration: InputDecoration(
                            labelText: 'Senha',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            // Ícone para alternar visibilidade da senha
                            suffixIcon: IconButton(
                              icon: Icon(_esconderTexto
                                  ? Icons.visibility
                                  : Icons.visibility_off),
                              onPressed: _alternarVisibilidadeTexto,
                            ),
                          ),
                        ),

                        const SizedBox(height: 8), // Pequeno espaço abaixo da senha

                        // Botão para "Esqueceu a senha?" alinhado à direita
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () {
                              _navegarParaEsqueciSenha(context); // Navega para tela de senha
                            },
                            child: const Text(
                              'Esqueceu a senha?',
                              style: TextStyle(color: Colors.blue),
                            ),
                          ),
                        ),

                        const SizedBox(height: 8), // Espaço entre botão e botão login

                        // Botão para realizar o login
                        ElevatedButton(
                          onPressed: () => _login(context), // Chama função de login
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 32, vertical: 16),
                            backgroundColor: const Color(0xFF007AFF), // Azul
                            foregroundColor: Colors.white, // Texto branco
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text('Entrar'),
                        ),

                        const SizedBox(height: 16), // Espaço abaixo do botão

                        // Linha com divisor e texto "ou"
                        Row(
                          children: [
                            Expanded(
                              child: Divider(
                                color: Theme.of(context).brightness ==
                                        Brightness.dark
                                    ? Colors.white
                                    : Colors.black,
                              ),
                            ),
                            const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 8),
                              child: Text('ou'),
                            ),
                            Expanded(
                              child: Divider(
                                color: Theme.of(context).brightness ==
                                        Brightness.dark
                                    ? Colors.white
                                    : Colors.black,
                              ),
                            ),
                          ],
                        ),

                        // Botão para criar conta, com texto azul e negrito
                        TextButton(
                          onPressed: () => _navegarParaCadastro(context),
                          child: const Text(
                            'Criar conta',
                            style: TextStyle(
                              color: Colors.blue,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
