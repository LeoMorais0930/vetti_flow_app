import 'package:flutter/material.dart';
import 'dart:async';
import '../../models/figma_models.dart';
import '../../services/figma_service.dart';
import 'widgets.dart';

class SuporteScreen extends StatefulWidget {
  final FigmaUser user;
  final void Function(BuildContext) onLogout;

  const SuporteScreen({super.key, required this.user, required this.onLogout});

  @override
  State<SuporteScreen> createState() => _SuporteScreenState();
}

class _SuporteScreenState extends State<SuporteScreen> with SingleTickerProviderStateMixin {
  late List<FigmaOrder> _orders;
  final FigmaService _service = FigmaService();
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadOrders();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _loadOrders() {
    setState(() {
      _orders = _service.getOrdersByStage('suporte');
    });
  }

  void _handleResolve(FigmaOrder order) {
    showDialog(
      context: context,
      builder: (context) => PinDialog(
        expectedPin: widget.user.pin,
        message: 'Confirmar correção de ${order.opNumber}',
        onResult: (ok) {
          if (ok) {
            final updatedOrder = order.copyWith(
              currentStage: 'teste',
              producedQuantity: 0,
              remainingQuantity: order.totalQuantity,
              status: FigmaStatus.pending,
              lastSignature: widget.user.name,
              originStage: 'suporte',
              lastMoveAt: DateTime.now(),
            );
            _service.updateOrder(updatedOrder);
            _loadOrders();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('OP ${order.opNumber} corrigida e enviada de volta para Teste')),
            );
          }
        },
      ),
    );
  }

  void _handleEditValue(FigmaOrder order) {
    final qtyCtrl = TextEditingController(text: order.totalQuantity.toString());
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Editar Valor da OP'),
        content: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Ajuste a quantidade após recontagem humana.', style: TextStyle(color: Colors.grey, fontSize: 13)),
              const SizedBox(height: 16),
              TextField(
                controller: qtyCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Nova Quantidade',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCELAR')),
          ElevatedButton(
            onPressed: () {
              final newQty = int.tryParse(qtyCtrl.text) ?? 0;
              if (newQty > 0) {
                Navigator.pop(context);
                _showSyncProgress(order, newQty);
              }
            },
            child: const Text('ATUALIZAR NO PROTHEUS'),
          ),
        ],
      ),
    );
  }

  void _showSyncProgress(FigmaOrder order, int newQty) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => _SyncTimerDialog(
        onComplete: () {
          final updatedOrder = order.copyWith(
            totalQuantity: newQty,
            remainingQuantity: newQty,
            producedQuantity: 0,
          );
          _service.updateOrder(updatedOrder);
          _loadOrders();
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Quantidade atualizada com sucesso no Protheus.')),
          );
        },
      ),
    );
  }

  void _showRequisitionDialog() {
    final codeCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final nameCtrl = TextEditingController();
    final qtyCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Nova Requisição ao Almoxarifado'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Preencha os dados do material necessário para o reparo.', 
                style: TextStyle(color: Colors.grey, fontSize: 12)),
              const SizedBox(height: 20),
              TextField(
                controller: codeCtrl,
                decoration: const InputDecoration(
                  labelText: 'Código do Produto',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Nome do Produto',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: descCtrl,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Descrição / Motivo',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: qtyCtrl,
                decoration: const InputDecoration(
                  labelText: 'Quantidade',
                  border: OutlineInputBorder(),
                  isDense: true,
                  suffixText: 'un',
                ),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCELAR')),
          ElevatedButton(
            onPressed: () {
              final qty = double.tryParse(qtyCtrl.text) ?? 0;
              if (codeCtrl.text.isNotEmpty && qty > 0) {
                final newReq = FigmaRequisition(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  number: (DateTime.now().millisecondsSinceEpoch % 10000).toString(),
                  status: RequisitionStatus.pending,
                  requesterName: widget.user.name,
                  originStage: 'suporte',
                  createdAt: DateTime.now(),
                  items: [
                    FigmaRequisitionItem(
                      id: 'item_${DateTime.now().millisecondsSinceEpoch}',
                      code: codeCtrl.text,
                      description: descCtrl.text,
                      productName: nameCtrl.text,
                      requestedQuantity: qty,
                    )
                  ],
                );
                _service.addRequisition(newReq);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Requisição enviada para a Vera.')),
                );
                setState(() {}); // Refresh history tab if active
              }
            },
            child: const Text('REQUISITAR'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: FigmaAppBar(
        title: 'SUPORTE TÉCNICO', 
        user: widget.user, 
        icon: Icons.build, 
        onLogout: widget.onLogout, 
        backgroundColor: Colors.red.shade700
      ),
      body: Column(
        children: [
          Material(
            color: Colors.red.shade700,
            child: TabBar(
              controller: _tabController,
              indicatorColor: Colors.white,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.red.shade100,
              tabs: const [
                Tab(icon: Icon(Icons.build_circle), text: 'MANUTENÇÃO'),
                Tab(icon: Icon(Icons.history), text: 'REQUISIÇÕES'),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildOrdersTab(),
                _buildHistoryTab(),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: _tabController.index == 1 ? FloatingActionButton.extended(
        onPressed: _showRequisitionDialog,
        backgroundColor: Colors.orange,
        icon: const Icon(Icons.add),
        label: const Text('NOVA REQUISIÇÃO'),
      ) : null,
    );
  }

  Widget _buildOrdersTab() {
    if (_orders.isEmpty) {
      return const Center(
        child: Text('Nenhuma OP aguardando suporte técnico.', style: TextStyle(color: Colors.grey)),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _orders.length,
      itemBuilder: (context, index) {
        final o = _orders[index];
        return Card(
          elevation: 3,
          margin: const EdgeInsets.only(bottom: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(o.opNumber, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.red)),
                    if (o.originStage != null)
                      SignatureBadge(
                        stage: o.originStage!,
                        name: o.lastSignature ?? 'Desconhecido',
                        timestamp: o.lastMoveAt,
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                Text('${o.productCode} - ${o.productName}', style: const TextStyle(fontSize: 15)),
                const SizedBox(height: 4),
                Text('Quantidade Total: ${o.totalQuantity}', style: const TextStyle(fontWeight: FontWeight.w500)),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Divider(),
                ),
                if (o.defectLogs.isNotEmpty) ...[
                  const Text('RESUMO DOS DEFEITOS:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red, fontSize: 12)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: o.defectLogs.last.defectTypes.map((d) => Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(4), border: Border.all(color: Colors.red.shade200)),
                      child: Text('Tipo $d', style: const TextStyle(color: Colors.red, fontSize: 11, fontWeight: FontWeight.bold)),
                    )).toList(),
                  ),
                  const SizedBox(height: 12),
                  Text('Observações:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.grey.shade700)),
                  Text(o.defectLogs.last.description, style: const TextStyle(fontSize: 13, fontStyle: FontStyle.italic)),
                  const SizedBox(height: 20),
                ],
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _handleResolve(o), 
                        icon: const Icon(Icons.check),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green, 
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ), 
                        label: const Text('CORRIGIDO'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _handleEditValue(o), 
                        icon: const Icon(Icons.edit),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        label: const Text('RECONTAR'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHistoryTab() {
    final reqs = _service.requisitions.where((r) => r.originStage == 'suporte').toList();
    if (reqs.isEmpty) {
      return const Center(child: Text('Nenhuma requisição realizada.', style: TextStyle(color: Colors.grey)));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: reqs.length,
      itemBuilder: (context, index) {
        final req = reqs[index];
        final item = req.items.first;
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            title: Text('Requisição #${req.number}', style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text('${item.productName} (${item.code})'),
                Text('Qtd: ${item.requestedQuantity} un'),
              ],
            ),
            trailing: _getStatusBadge(req.status),
          ),
        );
      },
    );
  }

  Widget _getStatusBadge(RequisitionStatus status) {
    Color color = Colors.grey;
    String text = 'PENDENTE';
    if (status == RequisitionStatus.approved) { color = Colors.green; text = 'APROVADA'; }
    if (status == RequisitionStatus.refused) { color = Colors.red; text = 'RECUSADA'; }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(20)),
      child: Text(text, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }
}

class _SyncTimerDialog extends StatefulWidget {
  final VoidCallback onComplete;
  const _SyncTimerDialog({required this.onComplete});

  @override
  State<_SyncTimerDialog> createState() => _SyncTimerDialogState();
}

class _SyncTimerDialogState extends State<_SyncTimerDialog> {
  int _seconds = 60;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_seconds > 0) {
        setState(() => _seconds--);
      } else {
        _timer?.cancel();
        widget.onComplete();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Row(
        children: [
          Icon(Icons.sync, color: Colors.blue),
          SizedBox(width: 12),
          Text('Sincronização Protheus'),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: SizedBox(
              width: 60,
              height: 60,
              child: CircularProgressIndicator(strokeWidth: 6),
            ),
          ),
          const Text('Aguardando atualização de saldo nas APIs...', 
            textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.w500)),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(8)),
            child: Text('$_seconds segundos restantes', 
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blue)),
          ),
        ],
      ),
    );
  }
}
