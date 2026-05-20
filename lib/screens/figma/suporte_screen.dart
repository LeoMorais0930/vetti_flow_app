import 'package:flutter/material.dart';
import '../../models/figma_models.dart';
import 'widgets.dart';

class SuporteScreen extends StatefulWidget {
  final FigmaUser user;
  final void Function(BuildContext) onLogout;

  const SuporteScreen({super.key, required this.user, required this.onLogout});

  @override
  State<SuporteScreen> createState() => _SuporteScreenState();
}

class _SuporteScreenState extends State<SuporteScreen> {
  late List<FigmaOrder> _orders;

  @override
  void initState() {
    super.initState();
    _orders = _getMockDefectiveOrders();
  }

  List<FigmaOrder> _getMockDefectiveOrders() {
    return [
      FigmaOrder(
        id: 's1', opNumber: 'OP-550-DEF', productCode: 'CSA-5000', productName: 'Central Smart Alarm',
        totalQuantity: 10, producedQuantity: 10, remainingQuantity: 0,
        status: FigmaStatus.inProgress, createdBy: 'Admin', createdAt: DateTime.now(),
        currentStage: 'suporte', productionLogs: [],
        defectLogs: [
          FigmaDefectLog(
            id: 'd1', defectType: 'A', description: 'Curto circuito detectado',
            reportedBy: 'João Teste', reportedById: '4', reportedAt: DateTime.now().subtract(const Duration(hours: 2)),
          )
        ],
      ),
    ];
  }

  void _handleResolve(FigmaOrder order) {
    showDialog(
      context: context,
      builder: (context) => PinDialog(
        expectedPin: widget.user.pin,
        message: 'Confirmar correção de ${order.opNumber}',
        onResult: (ok) {
          if (ok) {
            setState(() {
              _orders = _orders.map((o) => o.id == order.id ? o.copyWith(status: FigmaStatus.completed) : o).toList();
            });
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: FigmaAppBar(title: 'SUPORTE TÉCNICO', user: widget.user, icon: Icons.build, onLogout: widget.onLogout, backgroundColor: Colors.red),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: _orders.map((o) => Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(o.opNumber, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.red)),
                Text('${o.productCode} - ${o.productName}'),
                const Divider(height: 24),
                Text('DEFEITO: ${o.defectLogs.last.description}', style: const TextStyle(fontWeight: FontWeight.bold)),
                Text('Tipo: ${o.defectLogs.last.defectType} | Reportado por: ${o.defectLogs.last.reportedBy}'),
                const SizedBox(height: 16),
                if (o.status != FigmaStatus.completed)
                  SizedBox(width: double.infinity, child: ElevatedButton(onPressed: () => _handleResolve(o), style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white), child: const Text('CORRIGIDO'))),
              ],
            ),
          ),
        )).toList(),
      ),
    );
  }
}
