import 'package:flutter/material.dart';
import '../../models/figma_models.dart';
import '../../services/figma_service.dart';
import 'widgets.dart';

class GenericProductionScreen extends StatefulWidget {
  final FigmaUser user;
  final String stage;
  final void Function(BuildContext) onLogout;

  const GenericProductionScreen({super.key, required this.user, required this.stage, required this.onLogout});

  @override
  State<GenericProductionScreen> createState() => _GenericProductionScreenState();
}

class _GenericProductionScreenState extends State<GenericProductionScreen> {
  late List<FigmaOrder> _orders;
  final FigmaService _service = FigmaService();

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  void _loadOrders() {
    setState(() {
      _orders = _service.getOrdersByStage(widget.stage);
    });
  }

  void _handleFinalize(FigmaOrder order) {
    showDialog(
      context: context,
      builder: (context) => PinDialog(
        expectedPin: widget.user.pin,
        message: 'Finalizar etapa ${widget.stage.toUpperCase()} para ${order.opNumber}',
        onResult: (ok) {
          if (ok) {
            final nextStage = _getNextStage(widget.stage);
            final updatedOrder = order.copyWith(
              producedQuantity: order.totalQuantity,
              remainingQuantity: 0,
              status: FigmaStatus.completed,
              lastSignature: widget.user.name,
              originStage: widget.stage,
              lastMoveAt: DateTime.now(),
            );
            _service.updateOrder(updatedOrder);
            _loadOrders();

            if (nextStage != null) {
              _showNextStageDialog(updatedOrder, nextStage);
            }
          }
        },
      ),
    );
  }

  String? _getNextStage(String current) {
    const stages = ['smd', 'gravacao', 'soldagem', 'teste', 'embalagem', 'expedicao'];
    int idx = stages.indexOf(current);
    if (idx != -1 && idx < stages.length - 1) {
      return stages[idx + 1];
    }
    return null;
  }

  void _showNextStageDialog(FigmaOrder order, String nextStage) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Enviar para próxima etapa?'),
        content: Text('Deseja enviar a OP ${order.opNumber} para $nextStage?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('MAIS TARDE')),
          ElevatedButton(
            onPressed: () {
              final updatedOrder = order.copyWith(
                currentStage: nextStage,
                producedQuantity: 0,
                remainingQuantity: order.totalQuantity,
                status: FigmaStatus.pending,
                lastSignature: widget.user.name,
                originStage: widget.stage,
                lastMoveAt: DateTime.now(),
              );
              _service.updateOrder(updatedOrder);
              _loadOrders();
              Navigator.pop(context);
            },
            child: const Text('ENVIAR'),
          ),
        ],
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
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              children: [
                ListTile(
                  title: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(o.opNumber, style: const TextStyle(fontWeight: FontWeight.bold)),
                      if (o.originStage != null)
                        SignatureBadge(
                          stage: o.originStage!,
                          name: o.lastSignature ?? 'Desconhecido',
                          timestamp: o.lastMoveAt,
                        ),
                    ],
                  ),
                  subtitle: Text('${o.productCode} - ${o.productName}\nQtd: ${o.totalQuantity}'),
                  trailing: o.status == FigmaStatus.completed 
                    ? const Icon(Icons.check_circle, color: Colors.green)
                    : ElevatedButton(onPressed: () => _handleFinalize(o), child: const Text('FINALIZAR')),
                ),
              ],
            ),
          ),
        )).toList(),
      ),
    );
  }
}
