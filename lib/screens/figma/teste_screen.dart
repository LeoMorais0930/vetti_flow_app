import 'package:flutter/material.dart';
import '../../models/figma_models.dart';
import '../../services/figma_service.dart';
import 'widgets.dart';

class TesteScreen extends StatefulWidget {
  final FigmaUser user;
  final void Function(BuildContext) onLogout;

  const TesteScreen({super.key, required this.user, required this.onLogout});

  @override
  State<TesteScreen> createState() => _TesteScreenState();
}

class _TesteScreenState extends State<TesteScreen> {
  late List<FigmaOrder> _orders;
  final FigmaService _service = FigmaService();

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  void _loadOrders() {
    setState(() {
      _orders = _service.getOrdersByStage('teste');
    });
  }

  void _handleTest(FigmaOrder order) {
    int failCount = 0;
    List<String> selectedDefects = [];
    final descCtrl = TextEditingController();

    final List<Map<String, String>> availableDefects = [
      {'code': 'A', 'desc': 'Falha de Solda'},
      {'code': 'B', 'desc': 'Componente Faltante'},
      {'code': 'C', 'desc': 'Curto Circuito'},
      {'code': 'D', 'desc': 'Inversão de Polaridade'},
      {'code': 'E', 'desc': 'Falha de RF'},
      {'code': 'F', 'desc': 'Carcaça Riscada'},
      {'code': 'G', 'desc': 'Botão Travado'},
      {'code': 'H', 'desc': 'LED Não Acende'},
      {'code': 'I', 'desc': 'Consumo Excessivo'},
      {'code': 'J', 'desc': 'Falha de Gravação'},
      {'code': 'K', 'desc': 'Antena Solta'},
      {'code': 'L', 'desc': 'Sujeira na PCI'},
    ];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          int passCount = order.totalQuantity - failCount;

          return AlertDialog(
            title: Text('Resultado do Teste - ${order.opNumber}'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(8)),
                    child: Text('Total da OP: ${order.totalQuantity} unidades', 
                      style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
                  ),
                  const SizedBox(height: 24),
                  const Text('Defeitos (Não Conformes):', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  const SizedBox(height: 8),
                  TextField(
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      hintText: 'Quantidade de defeitos', 
                      suffixText: 'un',
                    ),
                    onChanged: (v) {
                      setDialogState(() {
                        failCount = int.tryParse(v) ?? 0;
                        if (failCount > order.totalQuantity) failCount = order.totalQuantity;
                      });
                    },
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Aprovados (Conformes):', style: TextStyle(fontSize: 14)),
                      Text('$passCount un', style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 16)),
                    ],
                  ),
                  const Divider(height: 32),
                  const Text('Selecione os tipos de defeitos:', style: TextStyle(fontSize: 13, color: Colors.grey, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: availableDefects.map((d) {
                      bool selected = selectedDefects.contains(d['code']);
                      return FilterChip(
                        label: Text('${d['code']} - ${d['desc']}'),
                        selected: selected,
                        onSelected: (val) {
                          setDialogState(() {
                            if (val) {
                              selectedDefects.add(d['code']!);
                            } else {
                              selectedDefects.remove(d['code']);
                            }
                          });
                        },
                        selectedColor: Colors.red.shade100,
                        checkmarkColor: Colors.red,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),
                  TextField(
                    controller: descCtrl,
                    maxLines: 2,
                    decoration: const InputDecoration(labelText: 'Observações Adicionais'),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCELAR')),
              ElevatedButton(
                onPressed: () {
                  if (failCount > 0 && selectedDefects.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Selecione pelo menos um tipo de defeito.')),
                    );
                    return;
                  }
                  Navigator.pop(context);
                  _confirmPin(order, passCount, failCount, selectedDefects, descCtrl.text);
                },
                child: const Text('CONFIRMAR RESULTADOS'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _confirmPin(FigmaOrder order, int pass, int fail, List<String> defects, String desc) {
    showDialog(
      context: context,
      builder: (context) => PinDialog(
        expectedPin: widget.user.pin,
        message: 'Finalizar teste: $pass OK, $fail Defeitos',
        onResult: (ok) {
          if (ok) {
            _processResults(order, pass, fail, defects, desc);
          }
        },
      ),
    );
  }

  void _processResults(FigmaOrder order, int pass, int fail, List<String> defects, String desc) {
    DateTime now = DateTime.now();
    _service.removeOrder(order.id);

    if (pass > 0) {
      final conformingOrder = order.copyWith(
        id: '${order.id}_ok',
        totalQuantity: pass,
        producedQuantity: 0,
        remainingQuantity: pass,
        status: FigmaStatus.pending,
        currentStage: 'embalagem',
        lastSignature: widget.user.name,
        originStage: 'teste',
        lastMoveAt: now,
      );
      _service.addOrder(conformingOrder);
    }

    if (fail > 0) {
      final defectiveOrder = order.copyWith(
        id: '${order.id}_fail',
        totalQuantity: fail,
        producedQuantity: 0,
        remainingQuantity: fail,
        status: FigmaStatus.pending,
        currentStage: 'suporte',
        lastSignature: widget.user.name,
        originStage: 'teste',
        lastMoveAt: now,
        defectLogs: [
          ...order.defectLogs,
          FigmaDefectLog(
            id: now.toString(),
            defectTypes: defects,
            description: desc.isEmpty ? 'Defeito detectado no teste final' : desc,
            reportedBy: widget.user.name,
            reportedById: widget.user.id,
            reportedAt: now,
          ),
        ],
      );
      _service.addOrder(defectiveOrder);
    }

    _loadOrders();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('OP ${order.opNumber} processada: $pass OK, $fail Defeitos')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: FigmaAppBar(title: 'TESTE DE QUALIDADE', user: widget.user, icon: Icons.fact_check, onLogout: widget.onLogout, backgroundColor: Colors.blue.shade700),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _orders.length,
        itemBuilder: (context, index) {
          final o = _orders[index];
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(o.opNumber, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.blue)),
                      if (o.originStage != null)
                        SignatureBadge(
                          stage: o.originStage!,
                          name: o.lastSignature ?? 'Desconhecido',
                          timestamp: o.lastMoveAt,
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text('${o.productCode} - ${o.productName}', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 4),
                  Text('Quantidade Total: ${o.totalQuantity}', style: const TextStyle(color: Colors.grey)),
                  const Divider(height: 32),
                  ElevatedButton.icon(
                    onPressed: () => _handleTest(o),
                    icon: const Icon(Icons.fact_check_outlined),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue.shade700,
                      foregroundColor: Colors.white,
                    ),
                    label: const Text('ENCERRAR TESTE DESTE PRODUTO'),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
