import 'package:flutter/material.dart';
import '../../models/figma_models.dart';
import 'widgets.dart';

class GenericProductionScreen extends StatelessWidget {
  final FigmaUser user;
  final String stage;
  final void Function(BuildContext context) onLogout;

  const GenericProductionScreen({
    super.key,
    required this.user,
    required this.stage,
    required this.onLogout,
  });

  String get _title {
    switch (stage) {
      case 'gravacao':
        return 'Gravacao';
      case 'soldagem':
        return 'Soldagem';
      case 'embalagem':
        return 'Embalagem';
      default:
        return 'Producao';
    }
  }

  @override
  Widget build(BuildContext context) {
    return SectorShell(
      user: user,
      title: _title,
      subtitle: 'Apontamento parcial com PIN',
      onLogout: onLogout,
      children: [
        const DemoStatusCard(
          title: 'OPs no posto',
          value: '2',
          icon: Icons.build_circle_outlined,
          color: Color(0xFF1976D2),
        ),
        DemoOrderTile(
          op: 'OP-550-TEST',
          product: 'Controle 4 Botoes - saldo 1500',
          status: stage == 'gravacao' ? 'Registrar defeitos' : 'Em andamento',
        ),
      ],
    );
  }
}
