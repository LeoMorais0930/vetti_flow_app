import 'package:flutter/material.dart';
import '../../models/figma_models.dart';
import '../../services/figma_service.dart';
import 'widgets.dart';

class CreateOPScreen extends StatefulWidget {
  final FigmaUser user;

  const CreateOPScreen({super.key, required this.user});

  @override
  State<CreateOPScreen> createState() => _CreateOPScreenState();
}

class _CreateOPScreenState extends State<CreateOPScreen> {
  final _opCtrl = TextEditingController();
  final _productCtrl = TextEditingController();
  final _qtyCtrl = TextEditingController();
  final FigmaService _service = FigmaService();

  List<FigmaRequisitionItem> _availableMaterials = [
    FigmaRequisitionItem(id: 'm1', code: 'RES-10K', description: 'Resistor 10k', requestedQuantity: 0),
    FigmaRequisitionItem(id: 'm2', code: 'CAP-100U', description: 'Capacitor 100uF', requestedQuantity: 0),
    FigmaRequisitionItem(id: 'm3', code: 'LED-RED', description: 'LED Vermelho', requestedQuantity: 0),
    FigmaRequisitionItem(id: 'm4', code: 'IC-555', description: 'CI 555', requestedQuantity: 0),
    FigmaRequisitionItem(id: 'm5', code: 'PCB-V1', description: 'Placa de Circuito V1', requestedQuantity: 0),
    FigmaRequisitionItem(id: 'm6', code: 'CASE-V1', description: 'Gabinete Plástico V1', requestedQuantity: 0),
  ];

  void _handleSubmit() {
    if (_opCtrl.text.isEmpty || _productCtrl.text.isEmpty || _qtyCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Preencha todos os campos obrigatórios.')));
      return;
    }

    final selectedMaterials = _availableMaterials.where((m) => m.isMarked).toList();
    if (selectedMaterials.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Selecione pelo menos uma matéria-prima.')));
      return;
    }

    showDialog(
      context: context,
      builder: (context) => PinDialog(
        expectedPin: widget.user.pin,
        message: 'Assinar criação da OP ${_opCtrl.text}',
        onResult: (ok) {
          if (ok) {
            final newOrder = FigmaOrder(
              id: DateTime.now().millisecondsSinceEpoch.toString(),
              opNumber: _opCtrl.text,
              productCode: _productCtrl.text,
              productName: _productCtrl.text, // Using code as name for simplicity or we could add another field
              totalQuantity: int.parse(_qtyCtrl.text),
              producedQuantity: 0,
              remainingQuantity: int.parse(_qtyCtrl.text),
              status: FigmaStatus.pending,
              createdBy: widget.user.name,
              createdAt: DateTime.now(),
              currentStage: 'smd', // Goes to Paula (SMD)
              productionLogs: [],
              lastSignature: widget.user.name,
              originStage: 'almoxarifado',
              lastMoveAt: DateTime.now(),
              rawMaterials: selectedMaterials,
            );
            _service.addOrder(newOrder);
            _showSuccessScreen();
          }
        },
      ),
    );
  }

  void _showSuccessScreen() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.check_circle, size: 100, color: Colors.green),
                const SizedBox(height: 24),
                const Text('ENVIADO', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.green)),
                const SizedBox(height: 16),
                const Text('A Ordem de Produção foi enviada para o SMD.', textAlign: TextAlign.center),
                const SizedBox(height: 48),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('VOLTAR AO ALMOXARIFADO'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('CRIAR ORDEM DE PRODUÇÃO')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('DADOS DA OP', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.blue)),
            const SizedBox(height: 20),
            TextField(
              controller: _opCtrl,
              decoration: const InputDecoration(labelText: 'Número da OP', hintText: 'Ex: 123-123'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _productCtrl,
              decoration: const InputDecoration(labelText: 'Produto', hintText: 'Ex: Controle 4 Botões'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _qtyCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Quantidade Total', suffixText: 'un'),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 32),
              child: Divider(),
            ),
            const Text('MATÉRIA-PRIMA', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.blue)),
            const Text('Selecione e informe a quantidade de cada item.', style: TextStyle(fontSize: 12, color: Colors.grey)),
            const SizedBox(height: 16),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _availableMaterials.length,
              itemBuilder: (context, index) {
                final item = _availableMaterials[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          Checkbox(
                            value: item.isMarked,
                            onChanged: (val) {
                              setState(() {
                                _availableMaterials[index] = item.copyWith(isMarked: val ?? false);
                              });
                            },
                          ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(item.description, style: const TextStyle(fontWeight: FontWeight.bold)),
                                Text(item.code, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                              ],
                            ),
                          ),
                          if (item.isMarked)
                            SizedBox(
                              width: 80,
                              child: TextField(
                                keyboardType: TextInputType.number,
                                textAlign: TextAlign.center,
                                decoration: const InputDecoration(
                                  isDense: true,
                                  contentPadding: EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                                  hintText: 'Qtd',
                                ),
                                onChanged: (v) {
                                  _availableMaterials[index] = item.copyWith(requestedQuantity: double.tryParse(v) ?? 0);
                                },
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _handleSubmit,
              style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 60)),
              child: const Text('CRIAR E ENVIAR PARA SMD'),
            ),
          ],
        ),
      ),
    );
  }
}
