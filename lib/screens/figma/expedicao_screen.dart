import 'package:flutter/material.dart';
import '../../models/figma_models.dart';
import '../../services/figma_service.dart';
import 'widgets.dart';

class ExpedicaoScreen extends StatefulWidget {
  final FigmaUser user;
  final void Function(BuildContext) onLogout;

  const ExpedicaoScreen({super.key, required this.user, required this.onLogout});

  @override
  State<ExpedicaoScreen> createState() => _ExpedicaoScreenState();
}

class _ExpedicaoScreenState extends State<ExpedicaoScreen> {
  late List<FigmaOrder> _orders;
  final FigmaService _service = FigmaService();

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  void _loadOrders() {
    setState(() {
      _orders = _service.getOrdersByStage('expedicao');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: FigmaAppBar(title: 'EXPEDIÇÃO', user: widget.user, icon: Icons.local_shipping, onLogout: widget.onLogout, backgroundColor: Colors.deepPurple),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: GlobalRequisitionButton(user: widget.user, onSuccess: () => setState(() {})),
          ),
          Expanded(
            child: _orders.isEmpty
              ? const Center(child: Text('Nenhuma OP pendente na expedição.'))
              : ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: _orders.map((o) => Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(o.opNumber, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.deepPurple)),
                              if (o.originStage != null)
                                SignatureBadge(stage: o.originStage!, name: o.lastSignature!, timestamp: o.lastMoveAt),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text('${o.productCode} - ${o.productName}'),
                          const Divider(height: 32),
                          ElevatedButton.icon(
                            onPressed: () {},
                            icon: const Icon(Icons.check_circle),
                            label: const Text('FINALIZAR EXPEDIÇÃO'),
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                          ),
                        ],
                      ),
                    ),
                  )).toList(),
                ),
          ),
        ],
      ),
    );
  }
}
