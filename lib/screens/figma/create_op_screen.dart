import 'package:flutter/material.dart';
import '../../models/figma_models.dart';
import '../../services/figma_service.dart';
import '../../theme.dart';
import 'widgets.dart';

class CreateOPScreen extends StatefulWidget {
  final FigmaUser user;

  const CreateOPScreen({super.key, required this.user});

  @override
  State<CreateOPScreen> createState() => _CreateOPScreenState();
}

class _ProductTemplate {
  final String code;
  final String name;
  final int defaultQuantity;
  final String defaultDestination;
  final List<FigmaRequisitionItem> materials;

  const _ProductTemplate({
    required this.code,
    required this.name,
    required this.defaultQuantity,
    required this.defaultDestination,
    required this.materials,
  });

  String get label => '$code - $name';
}

class _CreateOPScreenState extends State<CreateOPScreen> {
  final _opCtrl = TextEditingController();
  final _qtyCtrl = TextEditingController();
  final FigmaService _service = FigmaService();

  late _ProductTemplate _selectedProduct;
  late String _destination;
  late List<FigmaRequisitionItem> _materials;

  final List<_ProductTemplate> _products = const [
    _ProductTemplate(
      code: '105-141',
      name: 'Central Vetti Smart',
      defaultQuantity: 5000,
      defaultDestination: 'SMD',
      materials: [
        FigmaRequisitionItem(id: 'm1', code: 'PCB-VS-01', description: 'Placa circuito central smart', requestedQuantity: 5000, isMarked: true),
        FigmaRequisitionItem(id: 'm2', code: 'IC-ESP32', description: 'Modulo ESP32 homologado', requestedQuantity: 5000, isMarked: true),
        FigmaRequisitionItem(id: 'm3', code: 'CON-8V', description: 'Conector borne 8 vias', requestedQuantity: 10000, isMarked: true),
      ],
    ),
    _ProductTemplate(
      code: '220-018',
      name: 'Controle 4 Botoes',
      defaultQuantity: 1500,
      defaultDestination: 'Producao',
      materials: [
        FigmaRequisitionItem(id: 'm4', code: 'RES-10K', description: 'Resistor 10k 0603', requestedQuantity: 1500, isMarked: true),
        FigmaRequisitionItem(id: 'm5', code: 'CASE-4B', description: 'Gabinete controle 4 botoes', requestedQuantity: 1500, isMarked: true),
        FigmaRequisitionItem(id: 'm6', code: 'BAT-CR2032', description: 'Bateria CR2032', requestedQuantity: 1500, isMarked: true),
      ],
    ),
    _ProductTemplate(
      code: '330-070',
      name: 'Sensor Shox',
      defaultQuantity: 3000,
      defaultDestination: 'SMD',
      materials: [
        FigmaRequisitionItem(id: 'm7', code: 'CAP-100U', description: 'Capacitor eletrolitico 100uF', requestedQuantity: 3000, isMarked: true),
        FigmaRequisitionItem(id: 'm8', code: 'SENSOR-SHX', description: 'Elemento sensor shox', requestedQuantity: 3000, isMarked: true),
      ],
    ),
  ];

  @override
  void initState() {
    super.initState();
    _selectedProduct = _products.first;
    _destination = _selectedProduct.defaultDestination;
    _opCtrl.text = _nextOpNumber();
    _applyProduct(_selectedProduct);
  }

  @override
  void dispose() {
    _opCtrl.dispose();
    _qtyCtrl.dispose();
    super.dispose();
  }

  String _nextOpNumber() {
    final now = DateTime.now();
    return 'OP-${now.year.toString().substring(2)}${now.month.toString().padLeft(2, '0')}-${now.millisecondsSinceEpoch.toString().substring(8)}';
  }

  void _applyProduct(_ProductTemplate product) {
    _selectedProduct = product;
    _destination = product.defaultDestination;
    _qtyCtrl.text = product.defaultQuantity.toString();
    _materials = product.materials.map((item) => item.copyWith()).toList();
  }

  Future<bool> _confirmPin() async {
    var confirmed = false;
    await showDialog<void>(
      context: context,
      builder: (_) => PinDialog(
        expectedPin: widget.user.pin,
        message: 'Assinar criacao da ${_opCtrl.text}',
        onResult: (ok) => confirmed = ok,
      ),
    );
    return confirmed;
  }

  Future<void> _handleSubmit() async {
    final qty = int.tryParse(_qtyCtrl.text.trim()) ?? 0;
    if (_opCtrl.text.trim().isEmpty || qty <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Confira numero da OP e quantidade.')),
      );
      return;
    }

    final selectedMaterials = _materials.where((m) => m.isMarked && m.requestedQuantity > 0).toList();
    if (selectedMaterials.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('A OP precisa ter pelo menos um material.')),
      );
      return;
    }

    if (!await _confirmPin()) return;

    final newOrder = FigmaOrder(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      opNumber: _opCtrl.text.trim(),
      productCode: _selectedProduct.code,
      productName: _selectedProduct.name,
      totalQuantity: qty,
      producedQuantity: 0,
      remainingQuantity: qty,
      status: FigmaStatus.pending,
      createdBy: widget.user.name,
      createdAt: DateTime.now(),
      currentStage: _destination == 'SMD' ? 'smd' : 'producao',
      productionLogs: const [],
      lastSignature: widget.user.name,
      originStage: 'almoxarifado',
      lastMoveAt: DateTime.now(),
      rawMaterials: selectedMaterials,
    );
    _service.addOrder(newOrder);

    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => _SuccessScreen(
          opNumber: newOrder.opNumber,
          destination: _destination,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Criar OP'),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final wide = constraints.maxWidth >= 900;
          return Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: wide ? 980 : double.infinity),
              child: ListView(
                padding: EdgeInsets.all(wide ? 24 : 14),
                children: [
                  _buildHeader(),
                  const SizedBox(height: 16),
                  wide
                      ? Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(child: _buildOpCard()),
                            const SizedBox(width: 16),
                            Expanded(child: _buildMaterialsCard()),
                          ],
                        )
                      : Column(
                          children: [
                            _buildOpCard(),
                            const SizedBox(height: 12),
                            _buildMaterialsCard(),
                          ],
                        ),
                  const SizedBox(height: 20),
                  FilledButton.icon(
                    onPressed: _handleSubmit,
                    icon: const Icon(Icons.check_circle_outline),
                    label: Text('CRIAR E ENVIAR PARA ${_destination.toUpperCase()}'),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kVettiBlue,
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Row(
        children: [
          _VettiWordmark(onDark: true),
          SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('VETTI Flow', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900)),
                SizedBox(height: 2),
                Text('OP demonstrativa com dados preenchidos', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOpCard() {
    return Card(
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Dados da OP', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
            const SizedBox(height: 14),
            TextField(
              controller: _opCtrl,
              decoration: const InputDecoration(
                labelText: 'Numero da OP',
                prefixIcon: Icon(Icons.confirmation_number_outlined),
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<_ProductTemplate>(
              initialValue: _selectedProduct,
              decoration: const InputDecoration(
                labelText: 'Produto',
                prefixIcon: Icon(Icons.inventory_2_outlined),
              ),
              items: _products
                  .map((product) => DropdownMenuItem(
                        value: product,
                        child: Text(product.label, overflow: TextOverflow.ellipsis),
                      ))
                  .toList(),
              onChanged: (product) {
                if (product == null) return;
                setState(() => _applyProduct(product));
              },
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _qtyCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Quantidade',
                suffixText: 'un',
                prefixIcon: Icon(Icons.numbers),
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _destination,
              decoration: const InputDecoration(
                labelText: 'Destino apos separacao',
                prefixIcon: Icon(Icons.call_split_outlined),
              ),
              items: const [
                DropdownMenuItem(value: 'SMD', child: Text('SMD')),
                DropdownMenuItem(value: 'Producao', child: Text('Producao')),
              ],
              onChanged: (value) {
                if (value != null) setState(() => _destination = value);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMaterialsCard() {
    return Card(
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Materia-prima', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
            const SizedBox(height: 4),
            const Text('Itens sugeridos automaticamente pelo produto.', style: TextStyle(color: kVettiGrayDk, fontSize: 12)),
            const SizedBox(height: 12),
            ..._materials.asMap().entries.map((entry) {
              final item = entry.value;
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: kVettiBackground,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: kVettiGray),
                  ),
                  child: Row(
                    children: [
                      Checkbox(
                        value: item.isMarked,
                        onChanged: (value) {
                          setState(() {
                            _materials[entry.key] = item.copyWith(isMarked: value ?? false);
                          });
                        },
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(item.code, style: const TextStyle(fontWeight: FontWeight.w900)),
                            Text(item.description, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: kVettiGrayDk, fontSize: 12)),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text('${item.requestedQuantity.toInt()} un', style: const TextStyle(fontWeight: FontWeight.w900)),
                    ],
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

class _SuccessScreen extends StatelessWidget {
  final String opNumber;
  final String destination;

  const _SuccessScreen({
    required this.opNumber,
    required this.destination,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const _VettiWordmark(large: true),
              const SizedBox(height: 24),
              const Icon(Icons.check_circle, size: 64, color: Colors.green),
              const SizedBox(height: 18),
              Text(opNumber, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: kVettiBlue)),
              const SizedBox(height: 8),
              Text('OP enviada para $destination', textAlign: TextAlign.center),
              const SizedBox(height: 36),
              FilledButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('VOLTAR AO ALMOXARIFADO'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _VettiWordmark extends StatelessWidget {
  final bool large;
  final bool onDark;

  const _VettiWordmark({
    this.large = false,
    this.onDark = false,
  });

  @override
  Widget build(BuildContext context) {
    final width = large ? 112.0 : 72.0;
    final height = large ? 48.0 : 36.0;
    final color = onDark ? Colors.white : kVettiBlue;
    return Container(
      width: width,
      height: height,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: onDark ? Colors.white.withValues(alpha: 0.1) : Colors.white,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: onDark ? Colors.white24 : kVettiGray),
      ),
      child: Text(
        'VETTI',
        style: TextStyle(
          color: color,
          fontSize: large ? 28 : 19,
          fontWeight: FontWeight.w900,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}
