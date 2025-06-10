// Importa biblioteca para codificar e decodificar JSON
import 'dart:convert';

// Importa a biblioteca HTTP para fazer requisições web
import 'package:http/http.dart' as http;

// Classe para gerenciar operações administrativas relacionadas a usuários
class AdminManager {
  // Token JWT para autenticação nas requisições protegidas
  final String token;

  // Construtor que recebe o token para autenticação
  AdminManager(this.token);

  // Método assíncrono para buscar a lista de usuários da API
  Future<List<Map<String, dynamic>>> fetchUsuarios() async {
    // Faz uma requisição GET para a rota /admin/users da API, incluindo o token no header Authorization
    final response = await http.get(
      Uri.parse(
          'https://projeto-safe-gate-production.up.railway.app/admin/users'),
      headers: {'Authorization': 'Bearer $token'},
    );

    // Se a resposta for sucesso (status 200), decodifica o JSON e retorna como lista de mapas (objetos)
    if (response.statusCode == 200) {
      return List<Map<String, dynamic>>.from(jsonDecode(response.body));
    } else {
      // Caso contrário, lança uma exceção indicando erro no carregamento dos usuários
      throw Exception('Erro ao carregar usuários');
    }
  }

  // Método assíncrono para excluir um usuário com base no email
  Future<void> deleteUsuario(String email) async {
    // Faz uma requisição DELETE para a rota /admin/users/:email da API, passando o token no header Authorization
    final response = await http.delete(
      Uri.parse(
          'https://projeto-safe-gate-production.up.railway.app/admin/users/:$email'),
      headers: {'Authorization': 'Bearer $token'},
    );

    // Se a resposta não for sucesso (status diferente de 200), lança uma exceção
    if (response.statusCode != 200) {
      throw Exception('Erro ao excluir usuário');
    }
  }
}
