import 'package:flutter/material.dart';
import 'package:flutter_displaymode/flutter_displaymode.dart';
import 'theme.dart';
import 'screens/login_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    // Tenta setar a maior taxa de atualização disponível (Android)
    await FlutterDisplayMode.setHighRefreshRate();
  } catch (e) {
    debugPrint('Erro ao setar high refresh rate: $e');
  }

  runApp(const VettiFlowApp());
}

class VettiFlowApp extends StatelessWidget {
  const VettiFlowApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'VETTI Flow',
      theme: vettiTheme,
      debugShowCheckedModeBanner: false,
      home: const LoginScreen(),
    );
  }
}
