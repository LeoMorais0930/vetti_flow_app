import 'package:flutter/material.dart';
import '../../models/figma_models.dart';
import 'widgets.dart';

class TesteScreen extends StatefulWidget {
  final FigmaUser user;
  final VoidCallback onLogout;

  const TesteScreen({super.key, required this.user, required this.onLogout});

  @override
  State<TesteScreen> createState() => _TesteScreenState();
}

class _TesteScreenState extends State<TesteScreen> {
  late List<FigmaOrder> _orders;

  @override
  void initState() {
    super.initState();
    _orders = _getMockOrders();
  }

  List<FigmaOrder> _getMockOrders() {
    return [
      FigmaOrder(
        id: 't1', opNumber: 'OP-TST-001', productCode: 'CSA-5000', productName: 'Central Smart Alarm',
        totalQuantity: 100, producedQuantity: 100, remainingQuantity: 0,
        status: FigmaStatus.inProgress, createdBy: 'Vera', createdAt: DateTime.now(),
        currentStage: 'teste', productionLogs: [],
      ),
    ];
  }

  void _handleResult(FigmaOrder order, bool pass) {
    if (pass) {
      showDialog(
        context: context,
        builder: (context) => PinDialog(
          expectedPin: widget.user.pin,
          message: 'Aprovar ${order.opNumber}',
          onResult: (ok) {
            if (ok) {
              setState(() {
                _orders = _orders.map((o) => o.id == order.id ? o.copyWith(status: FigmaStatus.completed) : o).toList();
              });
            }
          },
        ),
      );
    } else {
      _showDefectDialog(order);
    }
  }

  void _showDefectDialog(FigmaOrder order) {
    final descCtrl = TextEditingController();
    String type = 'A';
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reportar Defeito'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              value: type,
              items: ['A', 'B', 'C', 'D'].map((e) => DropdownMenuItem(value: e, child: Text('Tipo $e'))).toList(),
              onChanged: (v) => type = v!,
              decoration: const InputDecoration(labelText: 'Tipo de Defeito'),
            ),
            TextField(controller: descCtrl, decoration: const InputDecoration(labelText: 'Descrição')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCELAR')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _confirmDefectPin(order, type, descCtrl.text);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text('REPORTAR'),
          ),
        ],
      ),
    );
  }

  void _confirmDefectPin(FigmaOrder order, String type, String desc) {
    showDialog(
      context: context,
      builder: (context) => PinDialog(
        expectedPin: widget.user.pin,
        message: 'Confirmar defeito Tipo $type em ${order.opNumber}',
        onResult: (ok) {
          if (ok) {
            setState(() {
              _orders = _orders.map((o) => o.id == order.id ? o.copyWith(
                defectLogs: [...o.defectLogs, FigmaDefectLog(
                  id: DateTime.now().toString(), defectType: type, description: desc,
                  reportedBy: widget.user.name, reportedById: widget.user.id, reportedAt: DateTime.now(),
                )],
              ) : o).toList();
            });
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: FigmaAppBar(title: 'TESTE DE QUALIDADE', user: widget.user, icon: Icons.fact_check, onLogout: widget.onLogout, backgroundColor: Colors.lightBlue),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: _orders.map((o) => Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(o.opNumber, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                Text('${o.productCode} - ${o.productName}'),
                const Divider(height: 24),
                if (o.status != FigmaStatus.completed && o.defectLogs.isEmpty)
                  Row(
                    children: [
                      Expanded(child: ElevatedButton(onPressed: () => _handleResult(o, true), style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white), child: const Text('APROVAR'))),
                      const SizedBox(width: 8),
                      Expanded(child: ElevatedButton(onPressed: () => _handleResult(o, false), style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white), child: const Text('DEFEITO'))),
                    ],
                  )
                else if (o.defectLogs.isNotEmpty)
                  const Text('REPORTADO AO SUPORTE', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold))
                else
                  const Text('APROVADO', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        )).toList(),
      ),
    );
  }
}
