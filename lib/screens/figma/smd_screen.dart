import 'package:flutter/material.dart';
import '../../models/figma_models.dart';
import '../../services/figma_service.dart';
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
  final FigmaService _service = FigmaService();

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  void _loadOrders() {
    setState(() {
      _orders = _service.getOrdersByStage('smd');
    });
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
            int newProduced = order.producedQuantity + qty;
            int newRemaining = order.totalQuantity - newProduced;
            final updatedOrder = order.copyWith(
              producedQuantity: newProduced,
              remainingQuantity: newRemaining,
              status: newRemaining == 0 ? FigmaStatus.completed : FigmaStatus.inProgress,
            );
            _service.updateOrder(updatedOrder);
            _loadOrders();
          }
        },
      ),
    );
  }

  void _sendToNext(FigmaOrder order) {
    final updatedOrder = order.copyWith(
      currentStage: 'gravacao',
      producedQuantity: 0,
      remainingQuantity: order.totalQuantity,
      status: FigmaStatus.pending,
    );
    _service.updateOrder(updatedOrder);
    _loadOrders();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('OP ${order.opNumber} enviada para Gravação')),
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
                if (o.status == FigmaStatus.completed)
                  SizedBox(width: double.infinity, child: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                    onPressed: () => _sendToNext(o),
                    child: const Text('ENVIAR PARA PRÓXIMA ETAPA'),
                  )),
              ],
            ),
          ),
        )).toList(),
      ),
    );
  }
}
