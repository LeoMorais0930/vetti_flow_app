import 'package:flutter/material.dart';
import '../../models/figma_models.dart';
import 'widgets.dart';

class TesteScreen extends StatelessWidget {
  final FigmaUser user;
  final void Function(BuildContext context) onLogout;

  const TesteScreen({
    super.key,
    required this.user,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    return SectorShell(
      user: user,
      title: 'Teste',
      subtitle: 'Aprovacao, defeitos e envio para suporte',
      onLogout: onLogout,
      children: const [
        DemoStatusCard(
          title: 'Aguardando teste',
          value: '5',
          icon: Icons.fact_check_outlined,
          color: Color(0xFF1976D2),
        ),
        DemoOrderTile(
          op: 'OP-550-TEST',
          product: 'Controle 4 Botoes - saldo 1500',
          status: 'Testar',
        ),
      ],
    );
  }
}
