import 'package:flutter/material.dart';
import '../../models/figma_models.dart';
import 'widgets.dart';

class SMDScreen extends StatefulWidget {
  final FigmaUser user;
  final VoidCallback onLogout;

  const SMDScreen({super.key, required this.user, required this.onLogout});

  @override
  State<SMDScreen> createState() => _SMDScreenState();
}

class _SMDScreenState extends State<SMDScreen> {
  late List<FigmaOrder> _orders;

  @override
  void initState() {
    super.initState();
    _orders = _getMockOrders();
  }

  List<FigmaOrder> _getMockOrders() {
    return [
      FigmaOrder(
        id: '1', opNumber: 'OP-550-001', productCode: 'CSA-5000', productName: 'Central Smart Alarm',
        totalQuantity: 5000, producedQuantity: 2500, remainingQuantity: 2500,
        status: FigmaStatus.inProgress, createdBy: 'Vera Silva', createdAt: DateTime.now().subtract(const Duration(days: 1)),
        currentStage: 'smd', productionLogs: [],
      ),
    ];
  }

  void _handleProduce(FigmaOrder order) {
    final qtyCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Produzir Lote'),
        content: TextField(controller: qtyCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Quantidade')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCELAR')),
          ElevatedButton(
            onPressed: () {
              final qty = int.tryParse(qtyCtrl.text) ?? 0;
              if (qty > 0 && qty <= order.remainingQuantity) {
                Navigator.pop(context);
                _confirmPin(order, qty);
              }
            },
            child: const Text('CONFIRMAR'),
          ),
        ],
      ),
    );
  }

  void _confirmPin(FigmaOrder order, int qty) {
    showDialog(
      context: context,
      builder: (context) => PinDialog(
        expectedPin: widget.user.pin,
        message: 'Assinar lote de $qty un',
        onResult: (ok) {
          if (ok) {
            setState(() {
              int newProduced = order.producedQuantity + qty;
              int newRemaining = order.totalQuantity - newProduced;
              _orders = _orders.map((o) => o.id == order.id ? o.copyWith(
                producedQuantity: newProduced,
                remainingQuantity: newRemaining,
                status: newRemaining == 0 ? FigmaStatus.completed : FigmaStatus.inProgress,
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
      appBar: FigmaAppBar(title: 'SMD', user: widget.user, icon: Icons.memory, onLogout: widget.onLogout),
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
                const SizedBox(height: 12),
                ProgressIndicatorWidget(produced: o.producedQuantity, total: o.totalQuantity, color: Colors.blue),
                const SizedBox(height: 16),
                if (o.status != FigmaStatus.completed)
                  SizedBox(width: double.infinity, child: ElevatedButton(onPressed: () => _handleProduce(o), child: const Text('PRODUZIR LOTE'))),
              ],
            ),
          ),
        )).toList(),
      ),
    );
  }
}
