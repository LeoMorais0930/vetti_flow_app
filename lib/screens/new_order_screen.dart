import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import '../theme.dart';

class NewOrderScreen extends StatefulWidget {
  const NewOrderScreen({super.key});

  @override
  State<NewOrderScreen> createState() => _NewOrderScreenState();
}

class _NewOrderScreenState extends State<NewOrderScreen> {
  final _formKey = GlobalKey<FormState>();
  final _labelCtrl = TextEditingController();
  final _qtyCtrl = TextEditingController();
  final _searchCtrl = TextEditingController();

  List<Blueprint> _blueprints = [];
  List<Blueprint> _filtered = [];
  
  // Para Kits (Múltipla seleção)
  final Map<int, int> _kitQuantities = {};
  final Set<Blueprint> _selectedKits = {};
  
  // Para Seleção única (Produto normal)
  Blueprint? _selected;
  
  bool _isKitMode = false;
  bool _highPriority = false;
  bool _loading = true;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _loadBlueprints();
    _searchCtrl.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _labelCtrl.dispose();
    _qtyCtrl.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final query = _searchCtrl.text.toLowerCase();
    setState(() {
      _filtered = _blueprints.where((bp) {
        return bp.code.toLowerCase().contains(query) || 
               bp.name.toLowerCase().contains(query);
      }).toList();
    });
  }

  Future<void> _loadBlueprints() async {
    try {
      final list = await ApiService.instance.getBlueprints();
      setState(() {
        _blueprints = list;
        _filtered = list;
        if (list.isNotEmpty) {
          _selected = list.first;
          _qtyCtrl.text = list.first.defaultBatchSize.toString();
        }
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao carregar produtos: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    
    final mainProduct = _isKitMode ? _selectedKits.firstOrNull : _selected;
    if (mainProduct == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecione ao menos um produto')),
      );
      return;
    }

    setState(() => _submitting = true);
    try {
      final List<Map<String, dynamic>> components = _isKitMode
          ? _selectedKits.map((bp) => {
              'blueprintId': bp.id,
              'quantity': _kitQuantities[bp.id] ?? 1,
            }).toList()
          : [];

      final componentCodes = _isKitMode 
          ? _selectedKits.map((e) => e.code).join('; ')
          : '';

      await ApiService.instance.createOrder(
        blueprintId: mainProduct.id,
        label: _labelCtrl.text.trim(),
        totalQty: int.parse(_qtyCtrl.text.trim()),
        isHighPriority: _highPriority,
        componentCodes: componentCodes,
        components: components,
      );
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Lançar Lote')),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: kVettiBlue))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // --- MODO KIT ---
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const _Label('Tipo de Lote'),
                        ChoiceChip(
                          label: const Text('Pedido / Kit'),
                          selected: _isKitMode,
                          onSelected: (v) => setState(() => _isKitMode = v),
                          selectedColor: kVettiBlue.withValues(alpha: 0.2),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // --- BUSCA POR CÓDIGO ---
                    TextField(
                      controller: _searchCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Buscar por Código ou Nome',
                        prefixIcon: Icon(Icons.search),
                        hintText: 'Ex: 105-141',
                      ),
                    ),
                    const SizedBox(height: 12),

                    // --- LISTA DE PRODUTOS ---
                    Container(
                      height: 200,
                      decoration: BoxDecoration(
                        border: Border.all(color: kVettiGray),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: ListView.builder(
                        itemCount: _filtered.length,
                        itemBuilder: (context, index) {
                          final bp = _filtered[index];
                          final isSelected = _isKitMode 
                              ? _selectedKits.contains(bp)
                              : _selected == bp;

                          return ListTile(
                            title: Text(bp.code, style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Text(bp.name),
                            selected: isSelected,
                            trailing: _isKitMode && isSelected
                                ? SizedBox(
                                    width: 100,
                                    child: TextFormField(
                                      initialValue: (_kitQuantities[bp.id] ?? 1).toString(),
                                      keyboardType: TextInputType.number,
                                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                                      decoration: const InputDecoration(
                                        isDense: true,
                                        contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                                        hintText: 'Qtd',
                                      ),
                                      textAlign: TextAlign.center,
                                      onChanged: (v) {
                                        final val = int.tryParse(v);
                                        if (val != null) {
                                          setState(() => _kitQuantities[bp.id] = val);
                                        }
                                      },
                                    ),
                                  )
                                : isSelected
                                    ? const Icon(Icons.check_circle, color: kVettiBlue)
                                    : null,
                            onTap: () {
                              setState(() {
                                if (_isKitMode) {
                                  if (_selectedKits.contains(bp)) {
                                    _selectedKits.remove(bp);
                                    _kitQuantities.remove(bp.id);
                                  } else {
                                    _selectedKits.add(bp);
                                    _kitQuantities[bp.id] = 1;
                                  }
                                } else {
                                  _selected = bp;
                                  _qtyCtrl.text = bp.defaultBatchSize.toString();
                                }
                              });
                            },
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 20),

                    // --- IDENTIFICAÇÃO ---
                    const _Label('Identificação do Lote'),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _labelCtrl,
                      decoration: const InputDecoration(hintText: 'Ex: Pedido Cliente Especial'),
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Campo obrigatório' : null,
                    ),
                    const SizedBox(height: 16),

                    // --- QUANTIDADE ---
                    const _Label('Quantidade Total'),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _qtyCtrl,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      validator: (v) => (int.tryParse(v ?? '') ?? 0) <= 0 ? 'Qtd inválida' : null,
                    ),
                    const SizedBox(height: 20),

                    // --- PRIORIDADE ---
                    Card(
                      child: SwitchListTile(
                        title: const Text('Alta Prioridade'),
                        value: _highPriority,
                        onChanged: (v) => setState(() => _highPriority = v),
                      ),
                    ),
                    const SizedBox(height: 32),

                    // --- BOTÃO ---
                    FilledButton(
                      onPressed: _submitting ? null : _submit,
                      child: _submitting
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text('LANÇAR NA TV'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}

class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);
  @override
  Widget build(BuildContext context) => Text(text, style: const TextStyle(fontWeight: FontWeight.w700));
}
