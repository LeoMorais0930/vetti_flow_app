import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/figma_models.dart';
import '../../services/figma_service.dart';
import 'widgets.dart';

class AlmoxarifadoScreen extends StatefulWidget {
  final FigmaUser user;
  final void Function(BuildContext) onLogout;

  const AlmoxarifadoScreen({super.key, required this.user, required this.onLogout});

  @override
  State<AlmoxarifadoScreen> createState() => _AlmoxarifadoScreenState();
}

class _AlmoxarifadoScreenState extends State<AlmoxarifadoScreen> {
  late List<FigmaOrder> _orders;
  final FigmaService _service = FigmaService();
  final DateFormat _df = DateFormat('dd/MM/yyyy HH:mm');

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  void _loadOrders() {
    setState(() {
      _orders = _service.getOrdersByStage('almoxarifado');
    });
  }

  void _showCreateDialog() {
    final opCtrl = TextEditingController();
    final codeCtrl = TextEditingController();
    final nameCtrl = TextEditingController();
    final qtyCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Criar Nova Ordem de Produção'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: opCtrl, decoration: const InputDecoration(labelText: 'Número da OP')),
              TextField(controller: codeCtrl, decoration: const InputDecoration(labelText: 'Código do Produto')),
              TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Nome do Produto')),
              TextField(controller: qtyCtrl, decoration: const InputDecoration(labelText: 'Quantidade Total'), keyboardType: TextInputType.number),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCELAR')),
          ElevatedButton(
            onPressed: () {
              final qty = int.tryParse(qtyCtrl.text) ?? 0;
              if (opCtrl.text.isNotEmpty && qty > 0) {
                final newOrder = FigmaOrder(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  opNumber: opCtrl.text,
                  productCode: codeCtrl.text,
                  productName: nameCtrl.text,
                  totalQuantity: qty,
                  producedQuantity: 0,
                  remainingQuantity: qty,
                  status: FigmaStatus.pending,
                  createdBy: widget.user.name,
                  createdAt: DateTime.now(),
                  currentStage: 'almoxarifado',
                  productionLogs: [],
                );
                _service.addOrder(newOrder);
                _loadOrders();
                Navigator.pop(context);
              }
            },
            child: const Text('CRIAR'),
          ),
        ],
      ),
    );
  }

  void _handleProduce(FigmaOrder order) {
    final qtyCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Produzir Lote - ${order.opNumber}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Restante: ${order.remainingQuantity} un'),
            TextField(controller: qtyCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Quantidade')),
          ],
        ),
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
        message: 'Produzir $qty un de ${order.opNumber}',
        onResult: (ok) {
          if (ok) {
            int newProduced = order.producedQuantity + qty;
            int newRemaining = order.totalQuantity - newProduced;
            final updatedOrder = order.copyWith(
              producedQuantity: newProduced,
              remainingQuantity: newRemaining,
              status: newRemaining == 0 ? FigmaStatus.completed : FigmaStatus.inProgress,
              productionLogs: [
                ...order.productionLogs,
                FigmaProductionLog(
                  id: DateTime.now().toString(),
                  operatorName: widget.user.name,
                  operatorId: widget.user.id,
                  pin: widget.user.pin,
                  timestamp: DateTime.now(),
                  quantityProduced: qty,
                  stage: 'almoxarifado',
                )
              ],
            );
            _service.updateOrder(updatedOrder);
            _loadOrders();
          }
        },
      ),
    );
  }

  void _sendToSMD(FigmaOrder order) {
    final updatedOrder = order.copyWith(
      currentStage: 'smd',
      producedQuantity: 0, // Reset production for next stage
      remainingQuantity: order.totalQuantity,
      status: FigmaStatus.pending,
    );
    _service.updateOrder(updatedOrder);
    _loadOrders();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('OP ${order.opNumber} enviada para o SMD')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pending = _orders.where((o) => o.status != FigmaStatus.completed).toList();
    final completed = _orders.where((o) => o.status == FigmaStatus.completed).toList();

    return Scaffold(
      appBar: FigmaAppBar(title: 'Almoxarifado', user: widget.user, icon: Icons.inventory, onLogout: widget.onLogout),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Ordens de Produção', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ElevatedButton.icon(onPressed: _showCreateDialog, icon: const Icon(Icons.add), label: const Text('NOVA OP')),
              ],
            ),
            const SizedBox(height: 16),
            ...pending.map(_buildCard),
            if (completed.isNotEmpty) ...[
              const SizedBox(height: 24),
              const Text('Concluídas', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              ...completed.map(_buildCard),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCard(FigmaOrder order) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(order.opNumber, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.blue)),
            Text('${order.productCode} - ${order.productName}'),
            const SizedBox(height: 12),
            ProgressIndicatorWidget(produced: order.producedQuantity, total: order.totalQuantity, color: Colors.blue),
            const SizedBox(height: 16),
            if (order.status != FigmaStatus.completed)
              SizedBox(width: double.infinity, child: ElevatedButton(onPressed: () => _handleProduce(order), child: const Text('PRODUZIR LOTE'))),
            if (order.status == FigmaStatus.completed)
              SizedBox(width: double.infinity, child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                onPressed: () => _sendToSMD(order),
                child: const Text('ENVIAR PARA SMD'),
              )),
          ],
        ),
      ),
    );
  }
}
