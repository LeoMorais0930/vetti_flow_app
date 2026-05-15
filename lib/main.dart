import 'package:flutter/material.dart';
import 'theme.dart';
import 'screens/orders_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
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
      home: const OrdersScreen(),
    );
  }
}
