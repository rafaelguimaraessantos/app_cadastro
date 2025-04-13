import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'agendamento.dart';
import 'meus_agendamentos.dart'; // Novo arquivo que criaremos

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _supabase = Supabase.instance.client;
  List<Map<String, dynamic>> prestadores = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _carregarPrestadores();
  }

  Future<void> _carregarPrestadores() async {
    try {
      final response = await _supabase
          .from('users')
          .select()
          .eq('tipo', 'prestador')
          .order('nome');

      setState(() {
        prestadores = List<Map<String, dynamic>>.from(response);
        isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao carregar prestadores: $e')),
        );
        setState(() => isLoading = false);
      }
    }
  }

  Future<void> _verMeusAgendamentos() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MeusAgendamentosPage(clienteId: user.id),
      ),
    );

    // Recarrega os prestadores quando voltar da tela de agendamentos
    await _carregarPrestadores();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // Fundo branco da tela
      appBar: AppBar(
        backgroundColor: Colors.white, // Fundo branco da AppBar
        elevation: 0, // Remove sombra se quiser um visual flat
        title: const Text(
          'Prestadores de Serviço',
          style: TextStyle(color: Colors.black), // Texto preto
        ),
        iconTheme: const IconThemeData(color: Colors.black), // Ícones pretos
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today),
            onPressed: _verMeusAgendamentos,
            tooltip: 'Meus Agendamentos',
          ),
          IconButton(
            icon: const Icon(Icons.exit_to_app),
            onPressed: () async {
              await _supabase.auth.signOut();
              if (mounted) {
                Navigator.pushReplacementNamed(context, '/login');
              }
            },
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : prestadores.isEmpty
              ? const Center(child: Text('Nenhum prestador disponível'))
              : ListView.builder(
                  itemCount: prestadores.length,
                  itemBuilder: (context, index) {
                    final prestador = prestadores[index];
                    return Card(
                      color: Colors.white, // Cor branca do card
                      elevation: 3.0, // Elevação sutil
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12), // Cantos arredondados
                      ),
                      margin: const EdgeInsets.all(8.0),
                      child: ListTile(
                        title: Text(prestador['nome'] ?? 'Nome não informado'),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(prestador['categoria'] ?? 'Sem categoria'),
                            Row(
                              children: [
                                const Icon(Icons.star, color: Colors.amber, size: 16),
                                Text(' ${prestador['nota']?.toStringAsFixed(1) ?? '0.0'}'),
                              ],
                            ),
                          ],
                        ),
                        trailing: Text(
                          prestador['status'] ?? 'indisponível',
                          style: TextStyle(
                            color: prestador['status'] == 'disponível'
                                ? Colors.green
                                : Colors.red,
                          ),
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => AgendamentoPage(
                                prestadorId: prestador['id'],
                                prestadorNome: prestador['nome'],
                              ),
                            ),
                          );
                        },
                      ),
                    );

                  },
                ),
    );
  }

}