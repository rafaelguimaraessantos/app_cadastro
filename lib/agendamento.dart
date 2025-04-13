import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

class AgendamentoPage extends StatefulWidget {
  final String prestadorId;
  final String prestadorNome;

  const AgendamentoPage({
    Key? key,
    required this.prestadorId,
    required this.prestadorNome,
  }) : super(key: key);

  @override
  _AgendamentoPageState createState() => _AgendamentoPageState();
}

class _AgendamentoPageState extends State<AgendamentoPage> {
  final _descricaoController = TextEditingController();
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2101),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            dialogBackgroundColor: Colors.white, // Fundo branco
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF337ab7), // Azul escuro no cabeçalho
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            dialogBackgroundColor: Colors.white,
            timePickerTheme: const TimePickerThemeData(
              backgroundColor: Colors.white,
              dialHandColor: Color(0xFF337ab7),
              hourMinuteTextColor: Colors.black,
            ),
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF337ab7),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedTime) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }


  Future<void> _agendarServico() async {
    if (_selectedDate == null || _selectedTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecione data e hora')),
      );
      return;
    }

    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    final dataHora = DateTime(
      _selectedDate!.year,
      _selectedDate!.month,
      _selectedDate!.day,
      _selectedTime!.hour,
      _selectedTime!.minute,
    );

    try {
      await Supabase.instance.client.from('bookings').insert({
        'cliente_id': user.id,
        'prestador_id': widget.prestadorId,
        'data_hora': dataHora.toIso8601String(),
        'descricao': _descricaoController.text,
        'status': 'pendente',
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Agendamento realizado com sucesso!')),
      );
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao agendar: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // Fundo branco
      appBar: AppBar(
        title: Text('Agendar com ${widget.prestadorNome}'),
        backgroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _descricaoController,
              decoration: const InputDecoration(
                labelText: 'Descrição do serviço',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _selectDate(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF337ab7),
                    ),
                    child: Text(
                      _selectedDate == null
                          ? 'Selecionar Data'
                          : DateFormat('dd/MM/yyyy').format(_selectedDate!),
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _selectTime(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF337ab7),
                    ),
                    child: Text(
                      _selectedTime == null
                          ? 'Selecionar Hora'
                          : _selectedTime!.format(context),
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _agendarServico,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF337ab7),
                minimumSize: const Size(double.infinity, 50),
              ),
              child: const Text(
                'Confirmar Agendamento',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
