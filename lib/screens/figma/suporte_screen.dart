import 'package:flutter/material.dart';
import '../../models/figma_models.dart';
import 'widgets.dart';

class SuporteScreen extends StatelessWidget {
  final FigmaUser user;
  final void Function(BuildContext context) onLogout;

  const SuporteScreen({
    super.key,
    required this.user,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    return SectorShell(
      user: user,
      title: 'Suporte',
      subtitle: 'Tratativa de defeitos por OP',
      onLogout: onLogout,
      children: const [
        DemoStatusCard(
          title: 'Defeitos recebidos',
          value: '12',
          icon: Icons.handyman_outlined,
          color: Colors.orange,
        ),
        DemoOrderTile(
          op: 'OP-550-001',
          product: 'Defeito T-A - 8 un',
          status: 'Em suporte',
        ),
      ],
    );
  }
}
