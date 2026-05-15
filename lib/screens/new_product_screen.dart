import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/api_service.dart';
import '../theme.dart';

class NewProductScreen extends StatefulWidget {
  const NewProductScreen({super.key});

  @override
  State<NewProductScreen> createState() => _NewProductScreenState();
}

class _NewProductScreenState extends State<NewProductScreen> {
  final _formKey = GlobalKey<FormState>();
  final _codeCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  final _batchCtrl = TextEditingController(text: '100');
  
  final List<TextEditingController> _stageCtrls = [
    TextEditingController(text: 'Montagem'),
    TextEditingController(text: 'Teste'),
    TextEditingController(text: 'Expedição'),
  ];

  bool _submitting = false;

  void _addStage() {
    setState(() {
      _stageCtrls.add(TextEditingController());
    });
  }

  void _removeStage(int index) {
    if (_stageCtrls.length > 1) {
      setState(() {
        _stageCtrls.removeAt(index);
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _submitting = true);
    try {
      final stages = _stageCtrls.map((c) => c.text.trim()).where((t) => t.isNotEmpty).toList();
      
      await ApiService.instance.createBlueprint(
        code: _codeCtrl.text.trim(),
        name: _nameCtrl.text.trim(),
        defaultBatchSize: int.parse(_batchCtrl.text.trim()),
        stages: stages,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Produto cadastrado com sucesso!'), backgroundColor: Colors.green),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  void dispose() {
    _codeCtrl.dispose();
    _nameCtrl.dispose();
    _batchCtrl.dispose();
    for (var c in _stageCtrls) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Cadastrar Novo Produto')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const _SectionTitle('Informações Básicas'),
              const SizedBox(height: 12),
              TextFormField(
                controller: _codeCtrl,
                decoration: const InputDecoration(
                  labelText: 'Código do Produto',
                  hintText: 'Ex: 105-141',
                  prefixIcon: Icon(Icons.qr_code),
                ),
                validator: (v) => (v == null || v.isEmpty) ? 'Campo obrigatório' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Nome / Descrição',
                  hintText: 'Ex: Central Vetti Smart v2',
                  prefixIcon: Icon(Icons.description_outlined),
                ),
                validator: (v) => (v == null || v.isEmpty) ? 'Campo obrigatório' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _batchCtrl,
                decoration: const InputDecoration(
                  labelText: 'Lote Padrão (unidades)',
                  prefixIcon: Icon(Icons.numbers),
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                validator: (v) => (int.tryParse(v ?? '') ?? 0) <= 0 ? 'Valor inválido' : null,
              ),
              
              const SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const _SectionTitle('Etapas de Produção'),
                  TextButton.icon(
                    onPressed: _addStage,
                    icon: const Icon(Icons.add),
                    label: const Text('Nova Etapa'),
                  ),
                ],
              ),
              const Text(
                'Defina a ordem das etapas que o produto percorrerá.',
                style: TextStyle(color: kVettiGrayDk, fontSize: 12),
              ),
              const SizedBox(height: 8),
              
              ..._stageCtrls.asMap().entries.map((entry) {
                int idx = entry.key;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 14,
                        backgroundColor: kVettiBlue,
                        child: Text('${idx + 1}', style: const TextStyle(color: Colors.white, fontSize: 12)),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: entry.value,
                          decoration: InputDecoration(
                            hintText: 'Nome da etapa',
                            suffixIcon: _stageCtrls.length > 1 
                              ? IconButton(
                                  icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
                                  onPressed: () => _removeStage(idx),
                                )
                              : null,
                          ),
                          validator: (v) => (v == null || v.isEmpty) ? 'Obrigatório' : null,
                        ),
                      ),
                    ],
                  ),
                );
              }),

              const SizedBox(height: 40),
              FilledButton(
                onPressed: _submitting ? null : _submit,
                child: _submitting
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('SALVAR PRODUTO NO SISTEMA'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle(this.title);
  @override
  Widget build(BuildContext context) => Text(
    title,
    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
  );
}
