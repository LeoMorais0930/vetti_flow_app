import 'package:flutter/material.dart';
import '../../models/figma_models.dart';

class FigmaAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final FigmaUser user;
  final IconData icon;
  final VoidCallback onLogout;
  final Color? backgroundColor;

  const FigmaAppBar({
    super.key,
    required this.title,
    required this.user,
    required this.icon,
    required this.onLogout,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: backgroundColor ?? const Color(0xFF1976D2),
      elevation: 2,
      leading: Icon(icon, color: Colors.white),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
          Text(user.name, style: const TextStyle(color: Colors.white70, fontSize: 12)),
        ],
      ),
      actions: [
        IconButton(icon: const Icon(Icons.logout, color: Colors.white), onPressed: onLogout),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

class PinDialog extends StatefulWidget {
  final String expectedPin;
  final String message;
  final Function(bool) onResult;

  const PinDialog({super.key, required this.expectedPin, required this.message, required this.onResult});

  @override
  State<PinDialog> createState() => _PinDialogState();
}

class _PinDialogState extends State<PinDialog> {
  final TextEditingController _ctrl = TextEditingController();
  String? _error;

  void _submit() {
    if (_ctrl.text == widget.expectedPin) {
      widget.onResult(true);
      Navigator.pop(context);
    } else {
      setState(() {
        _error = 'PIN incorreto';
        _ctrl.clear();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Confirme com seu PIN'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Seu PIN será registrado como assinatura desta produção.', style: TextStyle(fontSize: 12, color: Colors.grey)),
          const SizedBox(height: 16),
          TextField(
            controller: _ctrl,
            obscureText: true,
            maxLength: 4,
            textAlign: TextAlign.center,
            keyboardType: TextInputType.number,
            style: const TextStyle(fontSize: 24, letterSpacing: 8),
            decoration: InputDecoration(errorText: _error, helperText: widget.message),
            onChanged: (v) { if (v.length == 4) _submit(); },
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCELAR')),
      ],
    );
  }
}

class ProgressIndicatorWidget extends StatelessWidget {
  final int produced;
  final int total;
  final Color color;

  const ProgressIndicatorWidget({super.key, required this.produced, required this.total, required this.color});

  @override
  Widget build(BuildContext context) {
    double progress = total > 0 ? produced / total : 0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Produzido: $produced / $total', style: const TextStyle(fontSize: 12, color: Colors.grey)),
            Text('${(progress * 100).toStringAsFixed(1)}%', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(5),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 8,
            backgroundColor: Colors.grey.shade200,
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }
}
