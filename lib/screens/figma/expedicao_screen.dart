import 'package:flutter/material.dart';
import '../../models/figma_models.dart';
import 'widgets.dart';

class ExpedicaoScreen extends StatelessWidget {
  final FigmaUser user;
  final void Function(BuildContext context) onLogout;

  const ExpedicaoScreen({
    super.key,
    required this.user,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    return SectorShell(
      user: user,
      title: 'Expedicao',
      subtitle: 'Conferencia final e fechamento da OP',
      onLogout: onLogout,
      children: const [
        DemoStatusCard(
          title: 'Prontos para expedir',
          value: '6',
          icon: Icons.local_shipping_outlined,
          color: Colors.green,
        ),
        DemoOrderTile(
          op: 'OP-550-003',
          product: 'Central Smart Alarm - 1200 un',
          status: 'Conferir volumes',
        ),
      ],
    );
  }
}
