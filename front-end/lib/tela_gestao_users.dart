import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hello/main.dart';          // Importa o AuthManager (gerenciamento de autenticação)
import 'package:hello/admin_manager.dart'; // Importa a lógica para administração (excluir usuários, etc)

class TelaGestaoUsers extends StatefulWidget {
  const TelaGestaoUsers({super.key});

  @override
  State<TelaGestaoUsers> createState() => _TelaGestaoUsersState();
}

class _TelaGestaoUsersState extends State<TelaGestaoUsers> {
  // Instância do AdminManager que vai fazer chamadas administrativas (requisições ao backend)
  late AdminManager adminManager;

  // Future que vai carregar a lista de usuários (assíncrono)
  late Future<List<Map<String, dynamic>>> _usuariosFuture;

  @override
  void initState() {
    super.initState();
    // Pega o token do usuário autenticado para criar o AdminManager
    final auth = Provider.of<AuthManager>(context, listen: false);
    adminManager = AdminManager(auth.token!);

    // Carrega a lista de usuários ao iniciar a tela
    _usuariosFuture = adminManager.fetchUsuarios();
  }

  // Método para atualizar a lista de usuários na tela (chama fetchUsuarios de novo)
  void _atualizarLista() {
    setState(() {
      _usuariosFuture = adminManager.fetchUsuarios();
    });
  }

  // Exibe um diálogo para confirmar a exclusão do usuário com o email fornecido
  void _confirmarExclusao(String email) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Confimar exclusão'),
        content: Text('Deseja realmente excluir o usuário $email'),
        actions: [
          // Botão para cancelar a exclusão e fechar o diálogo
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          // Botão para confirmar exclusão
          TextButton(
            onPressed: () async {
              Navigator.pop(context); // Fecha o diálogo
              try {
                // Chama o método para excluir o usuário via adminManager
                await adminManager.deleteUsuario(email);

                // Exibe mensagem de sucesso na tela
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Usuário excluído com sucesso!')),
                );

                // Atualiza a lista para refletir a exclusão
                _atualizarLista();
              } catch (error) {
                // Em caso de erro, exibe mensagem de erro
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Erro: $error')),
                );
              }
            },
            child: const Text('Excluir', style: TextStyle(color: Colors.red)),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Obtém o AuthManager para verificar o tipo do usuário autenticado
    final auth = Provider.of<AuthManager>(context);

    // Se o usuário logado não for admin, exibe mensagem de acesso negado
    if (auth.user?['tipo'] != 'admin') {
      return Scaffold(
        appBar: AppBar(title: const Text('Gestão de Usuários')),
        body: const Center(child: Text('Acesso restrito a administradores')),
      );
    }

    // Caso seja admin, mostra a lista de usuários e as opções
    return Scaffold(
      appBar: AppBar(title: const Text('Gestão de Usuários')),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _usuariosFuture, // Usa o Future que carrega os usuários
        builder: (context, snapshot) {
          // Enquanto estiver carregando, mostra um indicador circular
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } 
          // Se houve erro na requisição, exibe o erro
          else if (snapshot.hasError) {
            return Center(child: Text('Erro: ${snapshot.error}'));
          } 
          // Se não trouxe dados, exibe que não encontrou usuários
          else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('Nenhum usuário encontrado'));
          }

          // Se trouxe dados, armazena em variável local
          final usuarios = snapshot.data!;

          // Lista dinâmica que monta os itens da lista de usuários
          return ListView.builder(
            itemCount: usuarios.length,
            itemBuilder: (context, index) {
              final usuario = usuarios[index];

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: ListTile(
                  leading: const Icon(Icons.person), // Ícone de pessoa
                  title: Text(usuario['nome']), // Nome do usuário
                  subtitle: Text('${usuario['email']} | ${usuario['tipo_usuario']}'), // Email e tipo
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red), // Ícone de deletar
                    onPressed: () => _confirmarExclusao(usuario['email']), // Chama o diálogo de exclusão
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
