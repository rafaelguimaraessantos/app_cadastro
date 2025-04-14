import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;
  final _supabase = Supabase.instance.client;

  Future<void> _login() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Preencha e-mail e senha')),
      );
      return;
    }

    try {
      setState(() => _isLoading = true);

      final authResponse = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      final user = authResponse.user;
      if (user == null) {
        throw Exception('Usuário não encontrado');
      }

      if (user.emailConfirmedAt == null) {
        throw Exception('Confirme seu e-mail antes de fazer login');
      }

      final userData = await _supabase
          .from('users')
          .select()
          .eq('id', user.id)
          .maybeSingle();

      if (userData == null) {
        throw Exception('Dados do usuário não encontrados');
      }

      if (mounted) {
        Navigator.pushReplacementNamed(
          context,
          userData['tipo'] == 'prestador' ? '/solicitacoes' : '/home',
        );
      }
    } on AuthException catch (e) {
      final message = e.message?.toLowerCase() ?? '';

      String errorMessage;
      if (message.contains('invalid login credentials') ||
          message.contains('invalid_credentials')) {
        errorMessage = 'Verifique suas credenciais';
      } else {
        errorMessage = e.message ?? 'Erro de autenticação';
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }


  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
      backgroundColor: Colors.white,
      elevation: 0, // Remove a sombra (opcional)
      title: const Text(
        'Login',
        style: TextStyle(color: Colors.black), // Texto preto
      ),
      iconTheme: const IconThemeData(color: Colors.black), // Ícones pretos, se houver
      leading: null, // Isso vai remover completamente o ícone de "hamburger"
    ),


      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            const SizedBox(height: 40),
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: 'E-mail',
                prefixIcon: Icon(Icons.email),
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _passwordController,
              obscureText: _obscurePassword,
              decoration: InputDecoration(
                labelText: 'Senha',
                prefixIcon: const Icon(Icons.lock),
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: Icon(_obscurePassword ? Icons.visibility : Icons.visibility_off),
                  onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                ),
              ),
            ),
            const SizedBox(height: 30),
            ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF337ab7), // Azul escuro
            ),
            onPressed: _isLoading ? null : _login,
            child: _isLoading
                ? const CircularProgressIndicator(color: Colors.white)
                : const Text(
                    'Entrar',
                    style: TextStyle(color: Colors.white),
                  ),
          ),
            const SizedBox(height: 20),
            TextButton(
              style: TextButton.styleFrom(
                foregroundColor: Colors.black, // texto preto
                overlayColor: Colors.transparent, // sem splash ao tocar
              ),
              onPressed: _isLoading
                  ? null
                  : () => Navigator.pushNamed(context, '/cadastro'),
              child: const Text('Ainda não tem conta? Cadastre-se'),
            ),
          ],
        ),
      ),
    );
  }
}
