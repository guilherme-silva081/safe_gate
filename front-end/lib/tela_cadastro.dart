import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hello/main.dart'; // Importa o arquivo principal da aplicação
import 'package:provider/provider.dart'; // Importa o Provider para gerenciar estado

// Widget Stateful para a tela de cadastro (pois precisa guardar estados dos campos)
class CadastroScreen extends StatefulWidget {
  // Callback que será chamado quando o cadastro for concluído com sucesso
  final VoidCallback onCadastroConcluido;

  // Construtor obrigando a passar a função onCadastroConcluido
  const CadastroScreen({super.key, required this.onCadastroConcluido});

  // Cria o estado do widget
  @override
  State<CadastroScreen> createState() => _CadastroScreenState();
}

class _CadastroScreenState extends State<CadastroScreen> {
  // Chave global para controle e validação do formulário
  final _formKey = GlobalKey<FormState>();

  // Controladores para capturar e manipular texto digitado em cada campo
  final _nomeController = TextEditingController();
  final _cpfController = TextEditingController();
  final _telefoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _senhaController = TextEditingController();
  final _confirmarSenhaController = TextEditingController();

  // Variável que armazena o tipo do usuário selecionado no rádio (cliente ou admin)
  String? _tipoUsuario;

  // Flag para indicar se o tipo de usuário não foi selecionado (validação)
  bool _tipoUsuarioInvalido = false;

  // Função que será chamada ao clicar no botão de cadastrar
  void _cadastrar(BuildContext context) async {
    // Atualiza o estado para refletir se o tipoUsuario está nulo (não selecionado)
    setState(() {
      _tipoUsuarioInvalido = _tipoUsuario == null;
    });

    // Verifica se o formulário está válido E se o tipo de usuário foi selecionado
    if (_formKey.currentState!.validate() && !_tipoUsuarioInvalido) {
      // Verifica se as senhas digitadas são iguais
      if (_senhaController.text != _confirmarSenhaController.text) {
        // Se senhas diferentes, exibe uma mensagem de erro na tela
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('As senhas não coincidem')),
        );
        return; // Sai da função para evitar continuar o cadastro
      }

      try {
        // Obtém a instância do AuthManager sem ficar escutando mudanças
        final auth = Provider.of<AuthManager>(context, listen: false);

        // Chama método register passando um mapa com os dados do usuário
        await auth.register({
          'nome': _nomeController.text,
          'email': _emailController.text,
          'senha': _senhaController.text,
          'cpf': _cpfController.text,
          'telefone': _telefoneController.text,
          'tipo_usuario': _tipoUsuario!, // Não pode ser nulo aqui
        });

        // Se deu certo, mostra mensagem de sucesso para o usuário
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cadastro realizado com sucesso!')),
        );

        // Chama a função passada no widget para indicar que cadastro foi concluído
        widget.onCadastroConcluido();
      } catch (error) {
        // Em caso de erro, exibe mensagem com o erro retornado
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.toString())),
        );
      }
    } else {
      // Se o tipo de usuário não foi selecionado, atualiza o estado para exibir erro
      if (_tipoUsuario == null) {
        setState(() {});
      }
    }
  }

  // Função para criar um campo de texto com validação simples (campo obrigatório)
  Widget buildTextField(TextEditingController controller, String label) {
    return TextFormField(
      controller: controller, // Define qual controlador gerencia esse campo
      decoration: InputDecoration(
        labelText: label, // Texto que aparece como rótulo do campo
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12), // Bordas arredondadas
        ),
      ),
      validator: (value) {
        // Validação que verifica se o campo está vazio
        if (value == null || value.isEmpty) {
          return 'Campo obrigatório'; // Retorna mensagem de erro se vazio
        }
        return null; // Campo válido
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Pega a cor primária do tema da aplicação para usar no layout
    final primaryColor = Theme.of(context).primaryColor;

    return Scaffold(
      backgroundColor: primaryColor, // Define cor de fundo da tela
      appBar: AppBar(
        backgroundColor: primaryColor, // Cor da barra superior
        foregroundColor: Colors.white, // Cor dos textos e ícones na AppBar
      ),
      body: Center(
        child: SingleChildScrollView(
          // Permite a tela rolar quando o teclado abrir ou conteúdo for maior que a tela
          child: Padding(
            padding: const EdgeInsets.only(bottom: 32, left: 32, right: 32),
            child: Form(
              key: _formKey, // Associa o formulário à chave para validação
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Card com o título "CADASTRO"
                  Card(
                    elevation: 2, // Sombra para dar profundidade
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          vertical: 12, horizontal: 24),
                      child: Text(
                        'CADASTRO',
                        style: GoogleFonts.roboto(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          letterSpacing: -0.64,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24), // Espaço entre o título e o formulário

                  // Card que contém todos os campos do formulário
                  Card(
                    elevation: 2,
                    child: Container(
                      padding: const EdgeInsets.all(32), // Espaçamento interno
                      child: Column(
                        children: [
                          // Campo para Nome
                          buildTextField(_nomeController, 'Nome'),
                          const SizedBox(height: 16), // Espaçamento vertical

                          // Campo para CPF
                          buildTextField(_cpfController, 'CPF'),
                          const SizedBox(height: 16),

                          // Campo para Telefone
                          buildTextField(_telefoneController, 'Telefone'),
                          const SizedBox(height: 16),

                          // Campo para Email, com validação extra para formato básico
                          TextFormField(
                            controller: _emailController,
                            decoration: InputDecoration(
                              labelText: 'Email',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Campo obrigatório';
                              }
                              if (!value.contains('@')) {
                                return 'Email inválido'; // Validação simples para '@'
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),

                          // Campo para Senha, texto oculto, validação de tamanho mínimo
                          TextFormField(
                            controller: _senhaController,
                            obscureText: true, // Oculta o texto digitado
                            decoration: InputDecoration(
                              labelText: 'Senha',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Campo obrigatório';
                              }
                              if (value.length < 8) {
                                return 'Mínimo 8 caracteres'; // Validação mínima de senha
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),

                          // Campo para confirmar senha, texto oculto, sem validação no campo
                          // Validação das senhas é feita no botão para exibir snackbar
                          TextFormField(
                            controller: _confirmarSenhaController,
                            obscureText: true,
                            decoration: InputDecoration(
                                labelText: 'Confirmar senha',
                                border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12))),
                          ),
                          const SizedBox(height: 24),

                          // Texto informativo para o tipo de usuário
                          Text(
                            'Tipo de usuário:',
                            style: GoogleFonts.roboto(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),

                          // Exibe mensagem de erro se o tipo de usuário não for selecionado
                          if (_tipoUsuarioInvalido)
                            const Text(
                              'Selecione o tipo de usuário',
                              style: TextStyle(color: Colors.red, fontSize: 12),
                            ),
                          const SizedBox(height: 8),

                          // Linha contendo os dois botões de rádio para escolher tipo de usuário
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              // Botão de rádio para Cliente
                              Radio<String>(
                                value: 'cliente', // Valor atribuído se selecionado
                                groupValue: _tipoUsuario, // Valor atualmente selecionado
                                activeColor: const Color(0xFF007AFF), // Cor do botão ativo
                                onChanged: (value) {
                                  setState(() {
                                    _tipoUsuario = value!; // Atualiza valor selecionado
                                  });
                                },
                              ),
                              Text('Cliente', style: GoogleFonts.roboto()),

                              const SizedBox(width: 20), // Espaço entre os botões

                              // Botão de rádio para Admin
                              Radio<String>(
                                value: 'admin',
                                groupValue: _tipoUsuario,
                               
