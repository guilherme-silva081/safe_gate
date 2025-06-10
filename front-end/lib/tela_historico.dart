import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hello/main.dart';             // Importa para acessar o Provider do HistoricoManager
import 'package:provider/provider.dart';

// Tela principal que exibe o histórico completo para o usuário
class TelaHistorico extends StatelessWidget {
  const TelaHistorico({super.key});

  @override
  Widget build(BuildContext context) {
    // Obtém a cor primária definida no tema do app (para manter padrão visual)
    final primaryColor = Theme.of(context).primaryColor;

    return Scaffold(
      // AppBar com cor de fundo da cor primária e texto/ícones brancos
      appBar: AppBar(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
      ),
      // Corpo da tela - container com cor primária que engloba toda a tela
      body: Container(
        color: primaryColor,
        child: Column(
          children: [
            // Card simples que exibe o título da tela: "HISTÓRICO"
            Card(
              elevation: 2, // sombra leve para destacar o card
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                child: Text(
                  'HISTÓRICO',
                  // Estilo personalizado usando a fonte Roboto, negrito e tamanho 28
                  style: GoogleFonts.roboto(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.64, // espaçamento entre letras um pouco reduzido
                  ),
                  textAlign: TextAlign.center, // texto centralizado horizontalmente
                ),
              ),
            ),
            const SizedBox(height: 24), // Espaçamento vertical entre título e lista

            // Expande para ocupar espaço restante da tela
            Expanded(
              // Card que contém a lista de histórico
              child: Card(
                margin: const EdgeInsets.symmetric(horizontal: 24), // margem lateral do card
                elevation: 6, // sombra mais destacada para o card
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16), // cantos arredondados do card
                ),
                // Padding para dar espaçamento interno ao conteúdo do card
                child: const Padding(
                  padding: EdgeInsets.all(16),
                  // Widget que constrói e mostra a lista dos itens do histórico
                  child: ListaHistorico(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Widget Stateful que vai carregar e exibir a lista de itens do histórico
class ListaHistorico extends StatefulWidget {
  const ListaHistorico({super.key});

  @override
  State<ListaHistorico> createState() => _ListaHistoricoState();
}

class _ListaHistoricoState extends State<ListaHistorico> {
  // Future que vai conter a lista carregada de forma assíncrona do histórico
  late Future<List<ItemHistorico>> _futureHistorico;

  @override
  void initState() {
    super.initState();
    // No init, faz a requisição para buscar os dados do histórico via Provider
    // O listen: false evita que este widget seja reconstruído automaticamente em mudanças
    _futureHistorico =
        Provider.of<HistoricoManager>(context, listen: false).fetchHistory();
  }

  @override
  Widget build(BuildContext context) {
    // FutureBuilder para reagir ao estado do Future (_futureHistorico)
    return FutureBuilder<List<ItemHistorico>>(
      future: _futureHistorico,
      builder: (context, snapshot) {
        // Caso esteja aguardando resposta do Future, mostra um indicador de loading
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } 
        // Caso ocorra algum erro na requisição, exibe a mensagem de erro na tela
        else if (snapshot.hasError) {
          return Center(child: Text('Erro: ${snapshot.error}'));
        } 
        // Caso a lista retorne vazia, exibe uma mensagem avisando que não há registros
        else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('Nenhum histórico encontrado'));
        }

        // Se chegou aqui, temos dados válidos e podemos exibir a lista
        return ListView.builder(
          itemCount: snapshot.data!.length,  // número de itens a serem exibidos
          itemBuilder: (context, index) {
            // Para cada índice cria um widget ElementoHistorico para exibir o item
            return ElementoHistorico(item: snapshot.data![index]);
          },
        );
      },
    );
  }
}

// Classe que representa o modelo de dados do item histórico
class ItemHistorico {
  final int id;         // Identificador único do registro
  final String titulo;  // Título ou nome do evento histórico
  final String hora;    // Hora do evento
  final String dia;     // Dia da semana (ex: Segunda-feira)
  final String data;    // Data completa (ex: 09/06/2025)

  // Construtor para facilitar criação dos objetos
  ItemHistorico(this.id, this.titulo, this.hora, this.dia, this.data);
}

// Widget que representa cada item da lista, com possibilidade de interagir e excluir
class ElementoHistorico extends StatefulWidget {
  const ElementoHistorico({super.key, required this.item});

  // Recebe o item histórico para exibir os dados
  final ItemHistorico item;

  @override
  State<ElementoHistorico> createState() => _ElementoHistoricoState();
}

class _ElementoHistoricoState extends State<ElementoHistorico> {
  // Controla se o botão de excluir está visível ou não
  bool _mostrarBotaoExcluir = false;

  @override
  Widget build(BuildContext context) {
    // Obtém a instância do HistoricoManager para manipular os dados (exclusão)
    final historico = Provider.of<HistoricoManager>(context, listen: false);

    return GestureDetector(
      // Ao tocar no card, alterna entre mostrar ou esconder o botão de excluir
      onTap: () {
        setState(() {
          _mostrarBotaoExcluir = !_mostrarBotaoExcluir;
        });
      },
      child: Card(
        color: Theme.of(context).colorScheme.secondaryContainer,  // cor do card conforme tema
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), // espaçamento externo
        elevation: 2,  // sombra leve para destaque
        child: ListTile(
          contentPadding: const EdgeInsets.all(16),  // espaçamento interno
          leading: const CircleAvatar(
            radius: 28,
            child: Icon(Icons.person, size: 36),  // ícone padrão para usuário
          ),
          // Título do item exibe o ID e título em negrito
          title: Text(
            '${widget.item.id} - ${widget.item.titulo}',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          // Subtítulo mostra dia, data e hora formatados
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 5),  // espaçamento vertical
              Text('${widget.item.dia}, ${widget.item.data}'),
              const SizedBox(height: 3),  // espaçamento pequeno
              Text(
                widget.item.hora,
                style: TextStyle(color: Colors.grey[600]),  // texto em cinza claro
              )
            ],
          ),
          // Área de trailing contém ícones: seta para direita e botão de excluir (condicional)
          trailing: Row(
            mainAxisSize: MainAxisSize.min, // só ocupa espaço necessário
            children: [
              const Icon(Icons.chevron_right),  // seta para indicar ação
              if (_mostrarBotaoExcluir)  // se deve mostrar o botão excluir
                AnimatedSize(
                  duration: const Duration(milliseconds: 200),  // animação suave para aparecer/desaparecer
                  child: Padding(
                    padding: const EdgeInsets.only(left: 8), // espaçamento à esquerda do ícone
                    child: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),  // ícone de exclusão vermelho
                      onPressed: () {
                        // Ao clicar em excluir, exibe um diálogo de confirmação
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Confirmar exclusão'),
                            content: const Text(
                                'Deseja realmente excluir este registro?'),
                            actions: [
                              // Botão cancelar fecha o diálogo sem fazer nada
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text('Cancelar'),
                              ),
                              // Botão excluir chama método para remover o item e fecha diálogo
                              TextButton(
                                onPressed: () {
                                  historico.removerItem(widget.item);  // remove o item da lista
                                  Navigator.pop(context);              // fecha o diálogo
                                  // Exibe uma mensagem de confirmação na tela
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content:
