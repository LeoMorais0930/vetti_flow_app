import 'package:flutter/material.dart';
import '../../models/figma_models.dart';

String roleLabel(FigmaRole role) {
  switch (role) {
    case FigmaRole.almoxarifado:
      return 'Almoxarifado';
    case FigmaRole.smd:
      return 'SMD';
    case FigmaRole.gravacao:
      return 'Gravacao';
    case FigmaRole.soldagem:
      return 'Soldagem';
    case FigmaRole.teste:
      return 'Teste';
    case FigmaRole.embalagem:
      return 'Embalagem';
    case FigmaRole.expedicao:
      return 'Expedicao';
    case FigmaRole.suporte:
      return 'Suporte';
  }
}

class PinDialog extends StatefulWidget {
  final String expectedPin;
  final String message;
  final ValueChanged<bool> onResult;

  const PinDialog({
    super.key,
    required this.expectedPin,
    required this.message,
    required this.onResult,
  });

  @override
  State<PinDialog> createState() => _PinDialogState();
}

class _PinDialogState extends State<PinDialog> {
  final _pinCtrl = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _pinCtrl.dispose();
    super.dispose();
  }

  void _confirm() {
    final ok = _pinCtrl.text.trim() == widget.expectedPin;
    if (!ok) {
      setState(() => _error = 'PIN invalido');
      widget.onResult(false);
      return;
    }

    widget.onResult(true);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Assinatura do operador'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(widget.message),
          const SizedBox(height: 16),
          TextField(
            controller: _pinCtrl,
            keyboardType: TextInputType.number,
            obscureText: true,
            autofocus: true,
            decoration: InputDecoration(
              labelText: 'PIN',
              errorText: _error,
              prefixIcon: const Icon(Icons.password_outlined),
            ),
            onSubmitted: (_) => _confirm(),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {
            widget.onResult(false);
            Navigator.pop(context);
          },
          child: const Text('CANCELAR'),
        ),
        FilledButton(
          onPressed: _confirm,
          child: const Text('ASSINAR'),
        ),
      ],
    );
  }
}

class SectorShell extends StatelessWidget {
  final FigmaUser user;
  final String title;
  final String subtitle;
  final void Function(BuildContext context) onLogout;
  final List<Widget> children;
  final List<Widget>? actions;

  const SectorShell({
    super.key,
    required this.user,
    required this.title,
    required this.subtitle,
    required this.onLogout,
    required this.children,
    this.actions,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          ...?actions,
          IconButton(
            tooltip: 'Sair',
            icon: const Icon(Icons.logout),
            onPressed: () => onLogout(context),
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final maxWidth = constraints.maxWidth >= 900 ? 980.0 : double.infinity;
          return Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxWidth),
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  Text(
                    subtitle,
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    user.name,
                    style: const TextStyle(color: Colors.black54, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 20),
                  ...children,
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class DemoStatusCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const DemoStatusCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: color.withValues(alpha: 0.12),
              foregroundColor: color,
              child: Icon(icon),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(color: Colors.black54, fontSize: 12)),
                  const SizedBox(height: 2),
                  Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class DemoOrderTile extends StatelessWidget {
  final String op;
  final String product;
  final String status;
  final VoidCallback? onTap;

  const DemoOrderTile({
    super.key,
    required this.op,
    required this.product,
    required this.status,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        onTap: onTap,
        leading: const Icon(Icons.assignment_outlined),
        title: Text(op, style: const TextStyle(fontWeight: FontWeight.w800)),
        subtitle: Text(product),
        trailing: Chip(
          label: Text(status),
          visualDensity: VisualDensity.compact,
        ),
      ),
    );
  }
}
