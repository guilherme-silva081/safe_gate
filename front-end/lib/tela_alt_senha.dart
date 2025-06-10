import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hello/main.dart';
import 'package:provider/provider.dart';

// Tela para alteração de senha, é Stateless porque só exibe o layout geral
class TelaAltSenha extends StatelessWidget {
  const TelaAltSenha({super.key});

  @override
  Widget build(BuildContext context) {
    // Cor principal do tema atual
    final primaryColor = Theme.of(context).primaryColor;

    return Scaffold(
      // Barra superior com cor do tema e texto branco
      appBar: AppBar(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
      ),
      // Corpo da tela
      body: Container(
        color: primaryColor, // fundo com a cor principal
        child: Column(
          children: [
            // Card contendo título da tela
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                child: Text(
                  'ALTERAR SENHA',
                  style: GoogleFonts.roboto(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.64,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            const SizedBox(height: 24), // Espaço vertical
            Expanded(
              child: Center(
                child: SingleChildScrollView(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 24),
                    child: Card(
                      elevation: 6,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      // Formulário para mudança de senha
                      child: const Padding(
                        padding: EdgeInsets.all(24),
                        child: MudarSenhaForm(), // Widget stateful do formulário
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Formulário stateful para permitir interações e controle dos campos
class MudarSenhaForm extends StatefulWidget {
  const MudarSenhaForm({super.key});

  @override
  _MudarSenhaFormState createState() => _MudarSenhaFormState();
}

class _MudarSenhaFormState extends State<MudarSenhaForm> {
  // Chave global para controlar o estado do formulário e validação
  final _formKey = GlobalKey<FormState>();

  // Controladores para capturar os textos digitados nos campos
  final _emailController = TextEditingController();
  final _novaSenhaContreller = TextEditingController();
  final _confirmarSenhaController = TextEditingController();

  // Flags para controlar a visibilidade da senha (mostrar/ocultar)
  bool _esconderNovaSenha = true;
  bool _esconderConfirmarSenha = true;

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey, // vincula o formulário à chave para validação
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Campo para email
          TextFormField(
            controller: _emailController,
            decoration: InputDecoration(
              labelText: 'Seu e-mail',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              prefixIcon: const Icon(Icons.email),
            ),
            validator: (valor) {
              // Validação do email: obrigatório
              if (valor == null || valor.isEmpty) {
                return 'Por favor, insira seu email';
              }
              return null; // campo válido
            },
          ),
          const SizedBox(height: 16), // espaçamento entre campos

          // Campo para nova senha
          TextFormField(
            controller: _novaSenhaContreller,
            obscureText: _esconderNovaSenha, // controla se texto é ocultado
            decoration: InputDecoration(
              labelText: 'Nova senha',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              prefixIcon: const Icon(Icons.lock_outline),
              // Ícone para mostrar/ocultar senha
              suffixIcon: IconButton(
                icon: Icon(
                  _esconderNovaSenha ? Icons.visibility : Icons.visibility_off,
                ),
                onPressed: () {
                  setState(() {
                    _esconderNovaSenha = !_esconderNovaSenha; // alterna visibilidade
                  });
                },
              ),
            ),
            validator: (value) {
              // Validação: obrigatório e no mínimo 8 caracteres
              if (value == null || value.isEmpty) {
                return 'Por favor, insira uma nova senha';
              }
              if (value.length < 8) {
                return 'A senha deve ter pelo menos 8 caracteres';
              }
              return null; // válido
            },
          ),
          const SizedBox(height: 16),

          // Campo para confirmar a nova senha
          TextFormField(
            controller: _confirmarSenhaController,
            obscureText: _esconderConfirmarSenha,
            decoration: InputDecoration(
              labelText: 'Confirmar nova senha',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              prefixIcon: const Icon(Icons.lock_outline),
              suffixIcon: IconButton(
                icon: Icon(
                  _esconderConfirmarSenha ? Icons.visibility : Icons.visibility_off,
                ),
                onPressed: () {
                  setState(() {
                    _esconderConfirmarSenha = !_esconderConfirmarSenha;
                  });
                },
              ),
            ),
            validator: (valor) {
              // Validação: o valor deve ser igual à nova senha
              if (valor != _novaSenhaContreller.text) {
                return 'As senhas não coincidem';
              }
              return null;
            },
          ),
          const SizedBox(height: 24),

          // Botão para enviar formulário
          ElevatedButton(
            onPressed: () {
              // Só executa se o formulário for válido
              if (_formKey.currentState!.validate()) {
                _mudarSenha();
              }
            },
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              backgroundColor: const Color(0xFF007AFF),
              foregroundColor: Colors.white,
            ),
            child: const Text('Alterar Senha'),
          ),
        ],
      ),
    );
  }

  // Função para tentar atualizar a senha do usuário
  void _mudarSenha() async {
    if (_formKey.currentState!.validate()) {
      try {
        // Obtém o AuthManager para fazer atualização
        final auth = Provider.of<AuthManager>(context, listen: false);

        // Atualiza o usuário com novo email e senha
        await auth.updateUser({
          'email': _emailController.text,
          'senha': _novaSenhaContreller.text,
        });

        // Exibe mensagem de sucesso
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Senha alterada com sucesso!')),
        );

        // Volta para a tela anterior
        Navigator.pop(context);
      } catch (error) {
        // Em caso de erro, mostra mensagem
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.toString())),
        );
      }
    }
  }
}
