import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/figma_models.dart';
import '../../services/figma_service.dart';

class FigmaAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final FigmaUser user;
  final IconData icon;
  final void Function(BuildContext) onLogout;
  final VoidCallback? onRefresh;
  final Color? backgroundColor;

  const FigmaAppBar({
    super.key,
    required this.title,
    required this.user,
    required this.icon,
    required this.onLogout,
    this.onRefresh,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final canPop = Navigator.canPop(context);

    return AppBar(
      backgroundColor: backgroundColor,
      leading: canPop
          ? IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => Navigator.pop(context),
            )
          : Icon(icon),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title),
          Text('${user.name} (${user.role.name.toUpperCase()})', style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.normal)),
        ],
      ),
      actions: [
        if (onRefresh != null)
          IconButton(icon: const Icon(Icons.refresh), onPressed: onRefresh),
        IconButton(
          icon: const Icon(Icons.logout),
          onPressed: () {
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Sair'),
                content: const Text('Deseja realmente sair do sistema?'),
                actions: [
                  TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCELAR')),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context); // Close dialog
                      onLogout(context);
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
                    child: const Text('SAIR'),
                  ),
                ],
              ),
            );
          },
        ),
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
          const Text('Seu PIN será registrado como assinatura desta produção.', style: TextStyle(fontSize: 13, color: Colors.grey)),
          const SizedBox(height: 24),
          TextField(
            controller: _ctrl,
            obscureText: true,
            maxLength: 4,
            textAlign: TextAlign.center,
            keyboardType: TextInputType.number,
            style: const TextStyle(fontSize: 28, letterSpacing: 12, fontWeight: FontWeight.bold),
            decoration: InputDecoration(
              errorText: _error, 
              helperText: widget.message,
              counterText: "",
              contentPadding: const EdgeInsets.all(20),
            ),
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
            Text('Produzido: $produced / $total', style: const TextStyle(fontSize: 13, color: Colors.grey, fontWeight: FontWeight.w500)),
            Text('${(progress * 100).toStringAsFixed(1)}%', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: color)),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 10,
            backgroundColor: Colors.grey.shade200,
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }
}

class SignatureBadge extends StatelessWidget {
  final String stage;
  final String name;
  final DateTime? timestamp;

  const SignatureBadge({super.key, required this.stage, required this.name, this.timestamp});

  @override
  Widget build(BuildContext context) {
    final df = DateFormat('dd/MM HH:mm');
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.history_edu, size: 12, color: Colors.blue),
              const SizedBox(width: 4),
              Text(
                'De: ${stage.toUpperCase()}',
                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.blue),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            name,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black87),
          ),
          if (timestamp != null)
            Text(
              df.format(timestamp!),
              style: const TextStyle(fontSize: 9, color: Colors.blueGrey),
            ),
        ],
      ),
    );
  }
}

class GlobalRequisitionButton extends StatelessWidget {
  final FigmaUser user;
  final VoidCallback? onSuccess;

  const GlobalRequisitionButton({super.key, required this.user, this.onSuccess});

  String _getWarehouseCode(FigmaRole role) {
    switch (role) {
      case FigmaRole.almoxarifado: return '01';
      case FigmaRole.smd: return '02';
      case FigmaRole.gravacao:
      case FigmaRole.soldagem:
      case FigmaRole.embalagem: return '03'; // General production
      case FigmaRole.expedicao: return '04';
      case FigmaRole.suporte: return '05';
      default: return '01';
    }
  }

  void _showDialog(BuildContext context) {
    final sourceWhCtrl = TextEditingController(text: _getWarehouseCode(user.role));
    final targetWhCtrl = TextEditingController();
    final List<Map<String, TextEditingController>> itemCtrls = [
      {'code': TextEditingController(), 'qty': TextEditingController()},
      {'code': TextEditingController(), 'qty': TextEditingController()},
      {'code': TextEditingController(), 'qty': TextEditingController()},
    ];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('CRIAR REQUISIÇÃO DE EMPENHO'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('INFORMAÇÕES DE ARMAZÉM', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue, fontSize: 12)),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: sourceWhCtrl,
                      decoration: const InputDecoration(labelText: 'Armazém Atual', isDense: true),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: targetWhCtrl,
                      decoration: const InputDecoration(labelText: 'Armazém Solicitado', isDense: true, hintText: 'Ex: 01'),
                    ),
                  ),
                ],
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Divider(),
              ),
              const Text('ITENS DA REQUISIÇÃO', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue, fontSize: 12)),
              const SizedBox(height: 12),
              ...itemCtrls.map((ctrls) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: TextField(
                        controller: ctrls['code'],
                        decoration: const InputDecoration(labelText: 'Código / Item', isDense: true),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 1,
                      child: TextField(
                        controller: ctrls['qty'],
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Qtd', isDense: true),
                      ),
                    ),
                  ],
                ),
              )),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCELAR')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _confirmPin(context, sourceWhCtrl.text, targetWhCtrl.text, itemCtrls);
            },
            child: const Text('ENVIAR REQUISIÇÃO'),
          ),
        ],
      ),
    );
  }

  void _confirmPin(BuildContext context, String sourceWh, String targetWh, List<Map<String, TextEditingController>> ctrls) {
    showDialog(
      context: context,
      builder: (ctx) => PinDialog(
        expectedPin: user.pin,
        message: 'Confirmar requisição do Armazém $sourceWh para $targetWh',
        onResult: (ok) {
          if (ok) {
            final List<FigmaRequisitionItem> items = [];
            for (var c in ctrls) {
              if (c['code']!.text.isNotEmpty) {
                items.add(FigmaRequisitionItem(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  code: c['code']!.text,
                  description: 'Requisição Global',
                  requestedQuantity: double.tryParse(c['qty']!.text) ?? 0,
                ));
              }
            }
            
            if (items.isNotEmpty) {
              final newReq = FigmaRequisition(
                id: DateTime.now().millisecondsSinceEpoch.toString(),
                number: (DateTime.now().millisecondsSinceEpoch % 10000).toString(),
                status: RequisitionStatus.pending,
                requesterName: user.name,
                originStage: user.role.name,
                sourceWarehouse: sourceWh,
                targetWarehouse: targetWh,
                createdAt: DateTime.now(),
                items: items,
              );
              FigmaService().addRequisition(newReq);
              onSuccess?.call();
              _showSuccess(context);
            }
          }
        },
      ),
    );
  }

  void _showSuccess(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Requisição enviada com sucesso!'),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: () => _showDialog(context),
      icon: const Icon(Icons.swap_horiz),
      label: const Text('CRIAR REQUISIÇÃO'),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.orange.shade800,
        foregroundColor: Colors.white,
      ),
    );
  }
}
