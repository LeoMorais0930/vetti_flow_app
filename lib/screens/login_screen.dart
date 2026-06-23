import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../models/figma_models.dart';
import 'figma/figma_hub.dart';
import 'figma/almoxarifado_screen.dart';
import 'figma/smd_screen.dart';
import 'figma/teste_screen.dart';
import 'figma/suporte_screen.dart';
import 'figma/expedicao_screen.dart';
import 'figma/generic_production_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  static void logout(BuildContext context) {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _userCtrl = TextEditingController(text: 'vera');
  final _passCtrl = TextEditingController(text: '8888');
  bool _isLoading = false;

  void _handleLogin() {
    setState(() => _isLoading = true);
    final user = AuthService.login(_userCtrl.text, _passCtrl.text);
    setState(() => _isLoading = false);

    if (user != null) {
      Widget nextScreen;
      switch (user.role) {
        case FigmaRole.almoxarifado:
          nextScreen = AlmoxarifadoScreen(user: user, onLogout: (ctx) => LoginScreen.logout(ctx));
          break;
        case FigmaRole.smd:
          nextScreen = SMDScreen(user: user, onLogout: (ctx) => LoginScreen.logout(ctx));
          break;
        case FigmaRole.teste:
          nextScreen = TesteScreen(user: user, onLogout: (ctx) => LoginScreen.logout(ctx));
          break;
        case FigmaRole.suporte:
          nextScreen = SuporteScreen(user: user, onLogout: (ctx) => LoginScreen.logout(ctx));
          break;
        case FigmaRole.expedicao:
          nextScreen = ExpedicaoScreen(user: user, onLogout: (ctx) => LoginScreen.logout(ctx));
          break;
        case FigmaRole.gravacao:
          nextScreen = GenericProductionScreen(user: user, stage: 'gravacao', onLogout: (ctx) => LoginScreen.logout(ctx));
          break;
        case FigmaRole.soldagem:
          nextScreen = GenericProductionScreen(user: user, stage: 'soldagem', onLogout: (ctx) => LoginScreen.logout(ctx));
          break;
        case FigmaRole.embalagem:
          nextScreen = GenericProductionScreen(user: user, stage: 'embalagem', onLogout: (ctx) => LoginScreen.logout(ctx));
          break;
      }

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => nextScreen),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Usuário ou senha inválidos')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1976D2),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 400),
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'VETTI',
                  style: TextStyle(fontSize: 42, fontWeight: FontWeight.w900, color: Color(0xFF1976D2)),
                ),
                const SizedBox(height: 2),
                const Text(
                  'Flow',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: Color(0xFF1976D2)),
                ),
                const Text('Sistema de Produção', style: TextStyle(color: Colors.grey)),
                const SizedBox(height: 32),
                TextField(
                  controller: _userCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Usuário',
                    prefixIcon: Icon(Icons.person),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _passCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Senha',
                    prefixIcon: Icon(Icons.lock),
                    border: OutlineInputBorder(),
                  ),
                  obscureText: true,
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _handleLogin,
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text('ENTRAR', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const FigmaHub())),
                  child: const Text('DEBUG: Figma Hub'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
