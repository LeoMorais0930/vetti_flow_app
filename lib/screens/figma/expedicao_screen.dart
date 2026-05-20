import 'package:flutter/material.dart';
import '../../models/figma_models.dart';
import 'widgets.dart';

class ExpedicaoScreen extends StatefulWidget {
  final FigmaUser user;
  final VoidCallback onLogout;

  const ExpedicaoScreen({super.key, required this.user, required this.onLogout});

  @override
  State<ExpedicaoScreen> createState() => _ExpedicaoScreenState();
}

class _ExpedicaoScreenState extends State<ExpedicaoScreen> {
  late List<FigmaOrder> _orders;
  final List<String> _selectedIds = [];

  @override
  void initState() {
    super.initState();
    _orders = _getAvailableOrders();
  }

  List<FigmaOrder> _getAvailableOrders() {
    return [
      FigmaOrder(
        id: 'e1', opNumber: 'OP-EXP-001', productCode: 'CSA-5000', productName: 'Central Smart Alarm',
        totalQuantity: 100, producedQuantity: 100, remainingQuantity: 0,
        status: FigmaStatus.completed, createdBy: 'Admin', createdAt: DateTime.now(),
        currentStage: 'expedicao', productionLogs: [],
      ),
      FigmaOrder(
        id: 'e2', opNumber: 'OP-EXP-002', productCode: 'BAT-12V', productName: 'Bateria 12V',
        totalQuantity: 50, producedQuantity: 50, remainingQuantity: 0,
        status: FigmaStatus.completed, createdBy: 'Admin', createdAt: DateTime.now(),
        currentStage: 'expedicao', productionLogs: [],
      ),
    ];
  }

  void _handleCreateKit() {
    if (_selectedIds.isEmpty) return;
    showDialog(
      context: context,
      builder: (context) => PinDialog(
        expectedPin: widget.user.pin,
        message: 'Expedir Kit com ${_selectedIds.length} itens',
        onResult: (ok) {
          if (ok) {
            setState(() {
              _orders = _orders.where((o) => !_selectedIds.contains(o.id)).toList();
              _selectedIds.clear();
            });
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: FigmaAppBar(title: 'EXPEDIÇÃO E KITS', user: widget.user, icon: Icons.local_shipping, onLogout: widget.onLogout, backgroundColor: Colors.deepPurple),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('${_selectedIds.length} selecionados', style: const TextStyle(fontWeight: FontWeight.bold)),
                ElevatedButton(onPressed: _selectedIds.isEmpty ? null : _handleCreateKit, child: const Text('CRIAR KIT')),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: _orders.map((o) => CheckboxListTile(
                value: _selectedIds.contains(o.id),
                onChanged: (v) {
                  setState(() {
                    if (v!) _selectedIds.add(o.id);
                    else _selectedIds.remove(o.id);
                  });
                },
                title: Text(o.opNumber, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text('${o.productCode} - ${o.productName}\nQtd: ${o.totalQuantity}'),
              )).toList(),
            ),
          ),
        ],
      ),
    );
  }
}
