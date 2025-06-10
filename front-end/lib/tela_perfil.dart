import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hello/main.dart';       // Para acessar AuthManager via Provider
import 'package:provider/provider.dart';

// Tela de perfil do usuário, que mostra dados e permite edição parcial
class TelaPerfil extends StatelessWidget {
  const TelaPerfil({super.key});

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).primaryColor;  // Cor principal do tema

    return Scaffold(
      backgroundColor: primaryColor,  // Fundo da tela com cor do tema
      appBar: AppBar(
        backgroundColor: primaryColor,  // Cor do appbar igual ao fundo
        foregroundColor: Colors.white,  // Texto e ícones em branco
        title: Text(
          'Conta',
          style: GoogleFonts.roboto(),  // Fonte Roboto para o título
        ),
        centerTitle: true,  // Centraliza o título do appbar
      ),
      body: Consumer<AuthManager>(
        // Consumer para escutar as mudanças no AuthManager (dados do usuário)
        builder: (context, auth, child) {
          final user = auth.user ?? {}; // Pega dados do usuário, ou vazio

          return Container(
            color: primaryColor,  // Fundo da área do corpo
            child: Column(
              children: [
                // Card com avatar, nome e email do usuário
                Card(
                  elevation: 2,  // Sombra leve
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: ListTile(
                      leading: const CircleAvatar(
                        radius: 40,  // Tamanho do avatar
                        child: Icon(Icons.person, size: 48), // Ícone padrão
                      ),
                      title: Text(
                        user['nome'] ?? 'Usuário',  // Nome do usuário ou texto padrão
                        style: GoogleFonts.roboto(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: Text(
                        user['email'] ?? '',  // Email do usuário
                        style: GoogleFonts.roboto(
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),  // Espaço entre cards

                // Card que contém o formulário para editar perfil
                Card(
                  margin: const EdgeInsets.symmetric(horizontal: 24),
                  elevation: 6,  // Sombra mais forte para destaque
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),  // Bordas arredondadas
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(24),  // Espaçamento interno
                    child: FormularioPerfil(user: user),  // Widget do formulário
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// Widget com formulário para edição dos dados do perfil
class FormularioPerfil extends StatefulWidget {
  final Map<String, dynamic> user;  // Dados do usuário a serem exibidos

  const FormularioPerfil({super.key, required this.user});

  @override
  State<FormularioPerfil> createState() => _FormularioPerfilState();
}

class _FormularioPerfilState extends State<FormularioPerfil> {
  final _formKey = GlobalKey<FormState>();  // Chave para o formulário

  // Controladores para os campos de texto
  late TextEditingController _nomeController;
  late TextEditingController _telefoneController;
  late TextEditingController _cpfController;
  late TextEditingController _emailController;
  late TextEditingController _tipoUsuarioController;

  @override
  void initState() {
    super.initState();

    // Inicializa os controladores com os dados do usuário, ou vazio
    _nomeController = TextEditingController(text: widget.user['nome'] ?? '');
    _telefoneController = TextEditingController(text: widget.user['telefone'] ?? '');
    _cpfController = TextEditingController(text: widget.user['cpf'] ?? '');
    _emailController = TextEditingController(text: widget.user['email'] ?? '');

    // Define tipo de usuário, só permite 'admin' ou 'cliente' (somente leitura)
    _tipoUsuarioController = TextEditingController(
      text: widget.user['tipo_usuario'] == 'admin' ? 'admin' : 'cliente'
    );
  }

  @override
  void dispose() {
    // Libera os controladores para evitar vazamento de memória
    _nomeController.dispose();
    _telefoneController.dispose();
    _cpfController.dispose();
    _emailController.dispose();
    _tipoUsuarioController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,  // Associando a chave ao formulário
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,  // Expande botões e campos horizontalmente
        children: [
          // Campo para editar nome
          TextFormField(
            controller: _nomeController,
            decoration: InputDecoration(
              labelText: 'Nome',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),

          const SizedBox(height: 16),  // Espaço entre campos

          // Campo email apenas leitura, não permite edição
          TextFormField(
            controller: _emailController,
            readOnly: true,
            decoration: InputDecoration(
              labelText: 'Email',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Campo CPF apenas leitura
          TextFormField(
            controller: _cpfController,
            readOnly: true,
            decoration: InputDecoration(
              labelText: 'CPF',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Campo telefone editável
          TextFormField(
            controller: _telefoneController,
            decoration: InputDecoration(
              labelText: 'Telefone',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Campo tipo de usuário apenas leitura
          TextFormField(
            controller: _tipoUsuarioController,
            readOnly: true,
            decoration: InputDecoration(
              labelText: 'Tipo de Usuário',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Botão para salvar alterações
          ElevatedButton(
            onPressed: _salvarAlteracoes,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              backgroundColor: const Color(0xFF007AFF),  // Azul
              foregroundColor: Colors.white,
            ),
            child: const Text('Salvar Alterações'),
          )
        ],
      ),
    );
  }

  // Função que valida e salva as alterações no perfil
  void _salvarAlteracoes() async {
    if (_formKey.currentState!.validate()) {  // Verifica se formulário é válido
      try {
        // Obtém AuthManager para atualizar dados do usuário
        final auth = Provider.of<AuthManager>(context, listen: false);

        // Atualiza o usuário com os campos editáveis
        await auth.updateUser({
          'nome': _nomeController.text.isNotEmpty ? _nomeController.text : null,
          'telefone': _telefoneController.text.isNotEmpty ? _telefoneController.text : null,
          'email': _emailController.text,  // Email é fixo, só para manter na API
        });

        // Exibe mensagem de sucesso para o usuário
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Perfil atualizado com sucesso!')),
        );

        // Volta para a tela anterior após salvar
        Navigator.pop(context);
      } catch (error) {
        // Caso erro, exibe mensagem para o usuário
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.toString())),
        );
      }
    }
  }
}
