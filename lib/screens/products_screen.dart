import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import '../theme.dart';

class ProductsScreen extends StatefulWidget {
  const ProductsScreen({super.key});

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  List<Blueprint> _products = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      setState(() => _loading = true);
      final list = await ApiService.instance.getBlueprints();
      setState(() => _products = list);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao carregar: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _editProduct(Blueprint bp) async {
    final nameCtrl = TextEditingController(text: bp.name);
    final batchCtrl = TextEditingController(text: bp.defaultBatchSize.toString());

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Editar: ${bp.code}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Nome do Produto')),
            const SizedBox(height: 12),
            TextField(
              controller: batchCtrl,
              decoration: const InputDecoration(labelText: 'Lote Padrão'),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('CANCELAR')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('SALVAR'),
          ),
        ],
      ),
    );

    if (ok == true) {
      try {
        setState(() => _loading = true);
        await ApiService.instance.updateBlueprint(
          bp.id,
          name: nameCtrl.text.trim(),
          defaultBatchSize: int.parse(batchCtrl.text.trim()),
        );
        _load();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Produto atualizado!')));
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erro: $e'), backgroundColor: Colors.red),
          );
        }
      } finally {
        if (mounted) setState(() => _loading = false);
      }
    }
  }

  Future<void> _deleteProduct(Blueprint bp) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Excluir Produto'),
        content: Text('Deseja realmente excluir ${bp.code}? Isso não afetará lotes já em produção.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('CANCELAR')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('EXCLUIR'),
          ),
        ],
      ),
    );

    if (ok == true) {
      try {
        setState(() => _loading = true);
        await ApiService.instance.deleteBlueprint(bp.id);
        _load();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erro: $e'), backgroundColor: Colors.red),
          );
        }
      } finally {
        if (mounted) setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Gestão de Produtos')),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: kVettiBlue))
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: _products.length,
              separatorBuilder: (_, __) => const Divider(),
              itemBuilder: (ctx, i) {
                final bp = _products[i];
                return ListTile(
                  title: Text(bp.code, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(bp.name),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit_outlined, color: kVettiBlue),
                        onPressed: () => _editProduct(bp),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline, color: Colors.red),
                        onPressed: () => _deleteProduct(bp),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
