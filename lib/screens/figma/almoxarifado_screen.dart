import 'package:flutter/material.dart';
import '../../models/figma_models.dart';
import '../../services/figma_service.dart';
import 'widgets.dart';
import 'create_op_screen.dart';

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
  int _activeTab = 0;

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

  void _handleRequisitionAction(FigmaRequisition req, bool approve) {
    showDialog(
      context: context,
      builder: (context) => PinDialog(
        expectedPin: widget.user.pin,
        message: '${approve ? 'Aprovar' : 'Recusar'} requisição #${req.number}',
        onResult: (ok) {
          if (ok) {
            final updatedReq = req.copyWith(
              status: approve ? RequisitionStatus.approved : RequisitionStatus.refused,
            );
            _service.updateRequisition(updatedReq);
            setState(() {});
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Requisição #${req.number} ${approve ? 'aprovada' : 'recusada'}.')),
            );
          }
        },
      ),
    );
  }

  void _handleStartSeparation(FigmaOrder order) {
    showDialog(
      context: context,
      builder: (context) => PinDialog(
        expectedPin: widget.user.pin,
        message: 'Assinar separação da OP ${order.opNumber}',
        onResult: (ok) {
          if (ok) {
            final updatedOrder = order.copyWith(
              currentStage: 'smd',
              producedQuantity: 0,
              remainingQuantity: order.totalQuantity,
              status: FigmaStatus.pending,
              lastSignature: widget.user.name,
              originStage: 'almoxarifado',
              lastMoveAt: DateTime.now(),
            );
            _service.updateOrder(updatedOrder);
            _loadOrders();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('OP ${order.opNumber} enviada para o SMD com todos os insumos.')),
            );
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: FigmaAppBar(title: 'ALMOXARIFADO', user: widget.user, icon: Icons.inventory, onLogout: widget.onLogout),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _activeTab,
        onTap: (idx) => setState(() => _activeTab = idx),
        selectedItemColor: Colors.blue.shade800,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.assignment), label: 'Ordens (OPs)'),
          BottomNavigationBarItem(icon: Icon(Icons.swap_horiz), label: 'Empenhos'),
          BottomNavigationBarItem(icon: Icon(Icons.support_agent), label: 'Suporte'),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    switch (_activeTab) {
      case 0: return _buildOrdersList();
      case 1: return _buildEmpenhosList();
      case 2: return _buildSupportRequisitions();
      default: return _buildOrdersList();
    }
  }

  Widget _buildOrdersList() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: ElevatedButton.icon(
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => CreateOPScreen(user: widget.user)),
              );
              _loadOrders();
            },
            icon: const Icon(Icons.add),
            label: const Text('CRIAR ORDEM DE PRODUÇÃO'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue.shade800,
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 56),
            ),
          ),
        ),
        Expanded(
          child: _orders.isEmpty
              ? const Center(child: Text('Nenhuma OP pendente.', style: TextStyle(color: Colors.grey)))
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _orders.length,
                  itemBuilder: (context, index) {
                    final o = _orders[index];
                    return Card(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(o.opNumber, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.blue)),
                            const SizedBox(height: 12),
                            Text('${o.productCode} - ${o.productName}', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
                            Text('Quantidade: ${o.totalQuantity}', style: const TextStyle(color: Colors.grey)),
                            if (o.rawMaterials.isNotEmpty) ...[
                              const Divider(height: 32),
                              const Text('MATERIAIS NECESSÁRIOS:', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)),
                              const SizedBox(height: 8),
                              ...o.rawMaterials.map((m) => Text('• ${m.description}: ${m.requestedQuantity} un', style: const TextStyle(fontSize: 12))),
                            ],
                            const Divider(height: 32),
                            ElevatedButton.icon(
                              onPressed: () => _handleStartSeparation(o),
                              icon: const Icon(Icons.play_arrow),
                              label: const Text('INICIAR SEPARAÇÃO'),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildEmpenhosList() {
    final empenhos = _service.requisitions.where((r) => r.sourceWarehouse != null).toList();
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: GlobalRequisitionButton(user: widget.user, onSuccess: () => setState(() {})),
        ),
        Expanded(
          child: empenhos.isEmpty
              ? const Center(child: Text('Nenhuma requisição de empenho.'))
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: empenhos.length,
                  itemBuilder: (context, index) {
                    final req = empenhos[index];
                    return Card(
                      child: ListTile(
                        title: Text('Req #${req.number} (${req.sourceWarehouse} -> ${req.targetWarehouse})'),
                        subtitle: Text('${req.items.length} itens - ${req.requesterName}'),
                        trailing: _getStatusBadge(req.status),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildSupportRequisitions() {
    final supportReqs = _service.requisitions.where((r) => r.originStage == 'suporte').toList();
    if (supportReqs.isEmpty) {
      return const Center(child: Text('Nenhuma requisição do suporte.', style: TextStyle(color: Colors.grey)));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: supportReqs.length,
      itemBuilder: (context, index) {
        final req = supportReqs[index];
        final item = req.items.first;
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Requisição #${req.number}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
                    _getStatusBadge(req.status),
                  ],
                ),
                Text('Solicitante: ${req.requesterName}', style: const TextStyle(color: Colors.grey, fontSize: 13)),
                const Divider(height: 32),
                Text(item.productName ?? item.code, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                Text('${item.requestedQuantity} un'),
                if (req.status == RequisitionStatus.pending) ...[
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(child: ElevatedButton(onPressed: () => _handleRequisitionAction(req, true), style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white), child: const Text('APROVAR'))),
                      const SizedBox(width: 12),
                      Expanded(child: OutlinedButton(onPressed: () => _handleRequisitionAction(req, false), style: OutlinedButton.styleFrom(foregroundColor: Colors.red, side: const BorderSide(color: Colors.red)), child: const Text('RECUSAR'))),
                    ],
                  ),
                ],
              ],
            ),
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
