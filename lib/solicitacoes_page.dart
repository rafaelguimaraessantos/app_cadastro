import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

class SolicitacoesPage extends StatefulWidget {
  const SolicitacoesPage({Key? key}) : super(key: key);

  @override
  State<SolicitacoesPage> createState() => _SolicitacoesPageState();
}

class _SolicitacoesPageState extends State<SolicitacoesPage> {
  final supabase = Supabase.instance.client;
  List<dynamic> _solicitacoes = [];
  bool _isLoading = true;

  Future<void> _buscarSolicitacoes() async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    setState(() => _isLoading = true);

    try {
      final response = await supabase
        .from('bookings')
        .select('id, cliente_id, descricao, data_hora, status, cliente:users!fk_cliente(nome)')
        .eq('prestador_id', user.id)
        .not('prestador_id', 'is', null)
        .order('data_hora', ascending: false);

      setState(() {
        _solicitacoes = response;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _mostrarErro('Erro ao carregar solicitações: $e');
    }
  }

  Future<void> _confirmarAgendamento(String id) async {
    try {
      await supabase.from('bookings').update({'status': 'confirmado'}).eq('id', id);
      _mostrarSucesso('Agendamento confirmado!');
      _buscarSolicitacoes();
    } catch (e) {
      _mostrarErro('Erro ao confirmar: $e');
    }
  }

  Future<void> _recusarAgendamento(String id) async {
    try {
      await supabase.from('bookings').delete().eq('id', id);
      _mostrarSucesso('Agendamento recusado e removido!');
      _buscarSolicitacoes();
    } catch (e) {
      _mostrarErro('Erro ao recusar: $e');
    }
  }

  void _mostrarSucesso(String mensagem) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(mensagem), backgroundColor: Colors.green),
    );
  }

  void _mostrarErro(String mensagem) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(mensagem), backgroundColor: Colors.red),
    );
  }

  @override
  void initState() {
    super.initState();
    _buscarSolicitacoes();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // ✅ Fundo branco
      appBar: AppBar(
        title: const Text('Solicitações Recebidas'),
        backgroundColor: Colors.white, // Fundo branco
        foregroundColor: Colors.black, // Ícones e texto pretos
        elevation: 1,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            tooltip: 'Editar Perfil',
            onPressed: () {
              Navigator.pushNamed(context, '/editar-perfil');
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Sair',
            onPressed: () async {
              await Supabase.instance.client.auth.signOut();
              if (mounted) {
                Navigator.pushReplacementNamed(context, '/login');
              }
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _buscarSolicitacoes,
              child: _solicitacoes.isEmpty
                  ? const Center(child: Text('Nenhuma solicitação encontrada'))
                  : ListView.builder(
                      itemCount: _solicitacoes.length,
                      itemBuilder: (context, index) {
                        final solicitacao = _solicitacoes[index];
                        final dataHora = DateTime.parse(solicitacao['data_hora']);
                        final clienteNome = solicitacao['cliente']?['nome'] ?? 'Desconhecido';

                        return Card(
                          color: Colors.white, // ✅ Força o fundo branco
                          elevation: 4,
                          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  solicitacao['descricao'] ?? 'Sem descrição',
                                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 8),
                                Text('Cliente: $clienteNome'),
                                Text('Data: ${DateFormat('dd/MM/yyyy').format(dataHora)}'),
                                Text('Hora: ${DateFormat('HH:mm').format(dataHora)}'),
                                Text(
                                  'Status: ${solicitacao['status'] ?? 'Pendente'}',
                                  style: TextStyle(
                                    color: _getStatusColor(solicitacao['status']),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                if (solicitacao['status'] == 'pendente')
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.check, color: Colors.green),
                                        onPressed: () => _confirmarAgendamento(solicitacao['id']),
                                        tooltip: 'Confirmar',
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.close, color: Colors.red),
                                        onPressed: () => _recusarAgendamento(solicitacao['id']),
                                        tooltip: 'Recusar e Excluir',
                                      ),
                                    ],
                                  ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
    );
  }

  Color _getStatusColor(String? status) {
    switch (status) {
      case 'confirmado':
        return Colors.green;
      case 'pendente':
        return Colors.orange;
      case 'recusado':
      case 'cancelado':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}
