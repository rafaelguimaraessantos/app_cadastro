import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'login.dart';
import 'cadastro.dart';
import 'home.dart';
import 'agendamento.dart';
import 'solicitacoes_page.dart';
import 'editar.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: 'https://hrekhyzzsawygvdiegwk.supabase.co',  // Coloque a URL do seu projeto aqui
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImhyZWtoeXp6c2F3eWd2ZGllZ3drIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDQ0MjY3NDcsImV4cCI6MjA2MDAwMjc0N30.56Lqt-H-D2JrYv7iRZjkCVPX5a3QUE7ltx0XVhgOPgo',  // Substitua pela sua anon key
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'App Cadastro',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      initialRoute: '/login', // Inicializa a tela de login
      routes: {
        '/login': (context) => const LoginPage(), // Rota para a tela de login
        '/cadastro': (context) => const CadastroPage(), // Rota para a tela de cadastro
        '/home': (context) => const HomePage(), // Rota para a tela principal após login
        '/solicitacoes': (context) => const SolicitacoesPage(),
        '/editar-perfil': (context) => const EditarPerfilPage(),
      },
    );
  }
}
