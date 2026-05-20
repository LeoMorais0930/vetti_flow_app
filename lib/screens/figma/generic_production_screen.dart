import 'package:flutter/material.dart';
import '../../models/figma_models.dart';
import 'widgets.dart';

class GenericProductionScreen extends StatefulWidget {
  final FigmaUser user;
  final String stage;
  final VoidCallback onLogout;

  const GenericProductionScreen({super.key, required this.user, required this.stage, required this.onLogout});

  @override
  State<GenericProductionScreen> createState() => _GenericProductionScreenState();
}

class _GenericProductionScreenState extends State<GenericProductionScreen> {
  late List<FigmaOrder> _orders;

  @override
  void initState() {
    super.initState();
    _orders = _getMockOrders();
  }

  List<FigmaOrder> _getMockOrders() {
    return [
      FigmaOrder(
        id: 'g1', opNumber: 'OP-GEN-001', productCode: 'PROD-123', productName: 'Produto Genérico',
        totalQuantity: 1000, producedQuantity: 0, remainingQuantity: 1000,
        status: FigmaStatus.pending, createdBy: 'Vera', createdAt: DateTime.now(),
        currentStage: widget.stage, productionLogs: [],
      ),
    ];
  }

  void _handleFinalize(FigmaOrder order) {
    showDialog(
      context: context,
      builder: (context) => PinDialog(
        expectedPin: widget.user.pin,
        message: 'Finalizar etapa ${widget.stage.toUpperCase()} para ${order.opNumber}',
        onResult: (ok) {
          if (ok) {
            setState(() {
              _orders = _orders.map((o) => o.id == order.id ? o.copyWith(
                producedQuantity: o.totalQuantity,
                remainingQuantity: 0,
                status: FigmaStatus.completed,
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
      appBar: FigmaAppBar(title: widget.stage.toUpperCase(), user: widget.user, icon: Icons.settings, onLogout: widget.onLogout),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: _orders.map((o) => Card(
          child: ListTile(
            title: Text(o.opNumber, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text('${o.productCode} - ${o.productName}\nQtd: ${o.totalQuantity}'),
            trailing: o.status == FigmaStatus.completed 
              ? const Icon(Icons.check_circle, color: Colors.green)
              : ElevatedButton(onPressed: () => _handleFinalize(o), child: const Text('FINALIZAR')),
          ),
        )).toList(),
      ),
    );
  }
}
