import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MeusAgendamentosPage extends StatefulWidget {
  final String clienteId;

  const MeusAgendamentosPage({Key? key, required this.clienteId}) : super(key: key);

  @override
  _MeusAgendamentosPageState createState() => _MeusAgendamentosPageState();
}

class _MeusAgendamentosPageState extends State<MeusAgendamentosPage> {
  final _supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _agendamentos = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _carregarAgendamentos();
  }

  Future<void> _carregarAgendamentos() async {
    try {
      final response = await _supabase
          .from('bookings')
          .select('''
            *,
            prestador:users!prestador_id(nome, categoria)
          ''')
          .eq('cliente_id', widget.clienteId)
          .order('data_hora', ascending: false);

      setState(() {
        _agendamentos = List<Map<String, dynamic>>.from(response);
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao carregar agendamentos: $e')),
        );
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _marcarComoConcluido(String agendamentoId) async {
    try {
      await _supabase
          .from('bookings')
          .update({'status': 'concluido'})
          .eq('id', agendamentoId);

      _carregarAgendamentos();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao marcar como concluído: $e')),
      );
    }
  }

  Future<void> _mostrarPopupAvaliacao(Map<String, dynamic> agendamento) async {
    double _avaliacao = 0;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white, // <-- fundo branco aqui
          title: const Text('Avalie o prestador'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Como foi sua experiência com este serviço?'),
              const SizedBox(height: 12),
              StatefulBuilder(
                builder: (context, setState) {
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (index) {
                      return IconButton(
                        icon: Icon(
                          index < _avaliacao
                              ? Icons.star
                              : Icons.star_border,
                          color: Colors.amber,
                        ),
                        onPressed: () {
                          setState(() {
                            _avaliacao = (index + 1).toDouble();
                          });
                        },
                      );
                    }),
                  );
                },
              ),
            ],
          ),
          actions: [
            SizedBox(
              height: 40,
              child: TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                ),
                child: const Text(
                  'Cancelar',
                  style: TextStyle(color: Colors.black, fontSize: 14),
                ),
              ),
            ),
            SizedBox(
              height: 40,
              child: ElevatedButton(
                onPressed: () async {
                  if (_avaliacao == 0) return;

                  final prestadorId = agendamento['prestador_id'];

                  final prestador = await _supabase
                      .from('users')
                      .select('nota, avaliacoes')
                      .eq('id', prestadorId)
                      .single();

                  final notaAtual = (prestador['nota'] ?? 0.0) as double;
                  final numAvaliacoes = (prestador['avaliacoes'] ?? 0) as int;

                  // Fórmula para calcular a média corretamente
                  final novaNota = ((notaAtual * numAvaliacoes) + _avaliacao) / (numAvaliacoes + 1);
                  final novaQuantidade = numAvaliacoes + 1;

                  // Atualiza nota + quantidade de avaliações
                  await _supabase.from('users').update({
                    'nota': novaNota,
                    'avaliacoes': novaQuantidade,
                  }).eq('id', prestadorId);

                  // Marca como avaliado
                  await _supabase.from('bookings').update({'avaliado': true}).eq('id', agendamento['id']);

                  Navigator.of(context).pop();
                  _carregarAgendamentos();
                },

                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF337ab7),
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'Enviar',
                  style: TextStyle(fontSize: 14, color: Colors.white),
                ),
              ),
            ),
          ],


        );
      },
    );
  }

  String _formatarStatus(String status) {
    switch (status) {
      case 'pendente':
        return 'Pendente';
      case 'confirmado':
        return 'Confirmado';
      case 'cancelado':
        return 'Cancelado';
      case 'concluido':
        return 'Concluído';
      default:
        return status;
    }
  }

  Color _corStatus(String status) {
    switch (status) {
      case 'pendente':
        return Colors.orange;
      case 'confirmado':
        return Colors.green;
      case 'cancelado':
        return Colors.red;
      case 'concluido':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // Fundo branco da tela
      appBar: AppBar(
        title: const Text('Meus Agendamentos'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _agendamentos.isEmpty
              ? const Center(child: Text('Nenhum agendamento encontrado'))
              : RefreshIndicator(
                  onRefresh: _carregarAgendamentos,
                  child: ListView.builder(
                    itemCount: _agendamentos.length,
                    itemBuilder: (context, index) {
                      final agendamento = _agendamentos[index];
                      final prestador = agendamento['prestador'] as Map<String, dynamic>?;

                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (agendamento['status'] == 'concluido' &&
                            agendamento['avaliado'] != true) {
                          _mostrarPopupAvaliacao(agendamento);
                        }
                      });

                      return Card(
                        color: Colors.white,
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Stack(
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(right: 80.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      prestador?['nome'] ?? 'Prestador não encontrado',
                                      style: const TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                    const SizedBox(height: 6),
                                    Text('Serviço: ${agendamento['descricao'] ?? 'Não especificado'}'),
                                    Text('Data: ${DateTime.parse(agendamento['data_hora']).toLocal()}'),
                                    const SizedBox(height: 12),
                                    if (agendamento['status'] == 'confirmado')
                                      ElevatedButton(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: const Color(0xFF337ab7),
                                        ),
                                        onPressed: () => _marcarComoConcluido(agendamento['id']),
                                        child: const Text(
                                          'Marcar como Concluído',
                                          style: TextStyle(color: Colors.white),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              Positioned(
                                top: 0,
                                right: 0,
                                child: Chip(
                                  label: Text(
                                    _formatarStatus(agendamento['status']),
                                    style: const TextStyle(color: Colors.white),
                                  ),
                                  backgroundColor: _corStatus(agendamento['status']),
                                ),
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
}
