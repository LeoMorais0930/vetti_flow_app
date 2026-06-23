import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import '../services/signalr_service.dart';
import '../theme.dart';

class OrderDetailScreen extends StatefulWidget {
  final ProductionOrder order;
  const OrderDetailScreen({super.key, required this.order});

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  late ProductionOrder _order;
  bool _advancing = false;

  @override
  void initState() {
    super.initState();
    _order = widget.order;
    SignalRService.instance.addListener(_onOrderUpdated);
  }

  @override
  void dispose() {
    SignalRService.instance.removeListener(_onOrderUpdated);
    super.dispose();
  }

  void _onOrderUpdated(ProductionOrder updated) {
    if (updated.id == _order.id) {
      setState(() => _order = updated);
      if (updated.isCompleted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Pedido concluído!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    }
  }

  Future<void> _advance() async {
    // Feedback local imediato
    final oldOrder = _order;
    setState(() {
      final nextIdx = _order.currentStageIndex + 1;
      final isDone = nextIdx >= _order.stageNames.length;
      _order = _order.copyWith(currentStageIndex: nextIdx, isCompleted: isDone);
      _advancing = true;
    });

    try {
      await ApiService.instance.advanceStage(oldOrder.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Etapa avançada com sucesso!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 1),
          ),
        );
        if (_order.isCompleted) {
          Navigator.pop(context);
        }
      }
    } catch (e) {
      // Reverte em caso de erro
      setState(() {
        _order = oldOrder;
        _advancing = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _advancing = false);
    }
  }

  Future<void> _finalizeKit() async {
    setState(() => _advancing = true);
    try {
      // Loop para garantir que todas as etapas sejam puladas de uma vez
      bool kitStillActive = true;
      int attempts = 0;
      
      while (kitStillActive && attempts < 15) {
        await ApiService.instance.advanceStage(_order.id);
        
        // Verifica se ainda está na lista de ativos
        final activeOrders = await ApiService.instance.getActiveOrders();
        final match = activeOrders.cast<ProductionOrder?>().firstWhere((o) => o?.id == _order.id, orElse: () => null);
        
        if (match == null || match.isCompleted) {
          kitStillActive = false;
        }
        attempts++;
        // Pequeno delay para não sobrecarregar o servidor
        await Future.delayed(const Duration(milliseconds: 200));
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Kit finalizado com sucesso!'), backgroundColor: Colors.green),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao finalizar kit: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _advancing = false);
    }
  }

  Future<void> _advanceComponent(int index) async {
    final comp = _order.kitStatuses[index];
    try {
      // Feedback local imediato
      setState(() {
        _advancing = true;
        final nextIdx = comp.currentStageIndex + 1;
        final isDone = nextIdx >= _order.stageNames.length;
        _order.kitStatuses[index] = KitComponentStatus(
          productCode: comp.productCode,
          productName: comp.productName,
          quantity: comp.quantity,
          currentStageIndex: nextIdx,
          isCompleted: isDone,
        );
      });

      await ApiService.instance.advanceStage(_order.id, componentIndex: index);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Item avançado!'), duration: Duration(seconds: 1)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _advancing = false);
    }
  }

  Future<void> _editComponent(int index) async {
    final comp = _order.kitStatuses[index];
    final qtyCtrl = TextEditingController(text: comp.quantity.toString());

    final newQty = await showDialog<int>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Editar: ${comp.productCode}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Ajuste a quantidade deste item no kit:'),
            const SizedBox(height: 12),
            TextField(
              controller: qtyCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Quantidade'),
              autofocus: true,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('CANCELAR')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, int.tryParse(qtyCtrl.text)),
            child: const Text('SALVAR'),
          ),
        ],
      ),
    );

    if (newQty != null && newQty > 0) {
      final updatedList = _order.kitStatuses.asMap().entries.map((e) {
        if (e.key == index) {
          return {
            'productCode': comp.productCode,
            'productName': comp.productName,
            'quantity': newQty,
          };
        }
        return {
          'productCode': e.value.productCode,
          'productName': e.value.productName,
          'quantity': e.value.quantity,
        };
      }).toList();

      try {
        setState(() => _advancing = true);
        await ApiService.instance.updateOrder(
          _order.id,
          label: _order.label,
          totalQty: _order.totalQty,
          isHighPriority: _order.isHighPriority,
          components: updatedList,
        );
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erro ao atualizar: $e'), backgroundColor: Colors.red),
          );
        }
      } finally {
        if (mounted) setState(() => _advancing = false);
      }
    }
  }

  Future<void> _deleteComponent(int index) async {
    final comp = _order.kitStatuses[index];
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remover Item'),
        content: Text('Deseja remover ${comp.productCode} deste kit?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('CANCELAR')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('REMOVER'),
          ),
        ],
      ),
    );

    if (ok == true) {
      final updatedList = _order.kitStatuses.asMap().entries
          .where((e) => e.key != index)
          .map((e) => {
                'productCode': e.value.productCode,
                'productName': e.value.productName,
                'quantity': e.value.quantity,
              })
          .toList();

      try {
        setState(() => _advancing = true);
        await ApiService.instance.updateOrder(
          _order.id,
          label: _order.label,
          totalQty: _order.totalQty,
          isHighPriority: _order.isHighPriority,
          components: updatedList,
        );
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erro ao remover: $e'), backgroundColor: Colors.red),
          );
        }
      } finally {
        if (mounted) setState(() => _advancing = false);
      }
    }
  }

  Future<void> _confirmDelete() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Excluir Lote'),
        content: const Text('Deseja realmente excluir este lote em produção? Esta ação é irreversível.'),
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
        await ApiService.instance.deleteOrder(_order.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Lote excluído')),
          );
          Navigator.pop(context);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final totalStages = _order.stageNames.length;
    final progress    = totalStages == 0 ? 0.0 : (_order.currentStageIndex + 1) / totalStages;
    final isLast      = _order.currentStageIndex == totalStages - 1;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _order.productCode.isNotEmpty 
              ? '${_order.productCode} — ${_order.productName}'
              : _order.label, 
          overflow: TextOverflow.ellipsis
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.white),
            onPressed: _confirmDelete,
            tooltip: 'Excluir lote',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Info do pedido ────────────────────────────────────────────
            if (_order.productCode.isNotEmpty)
              _InfoRow('Identificação do Lote', _order.label),
            _InfoRow('Quantidade total', '${_order.totalQty} unidades'),
            _InfoRow('Prioridade', _order.isHighPriority ? 'Alta' : 'Normal'),
            if (_order.componentCodes.isNotEmpty)
              _InfoRow('Composição', _order.componentCodes),
            const SizedBox(height: 16),

            // ── Lista de componentes do KIT (SE FOR KIT) ──────────────────
            if (_order.kitStatuses.isNotEmpty) ...[
              const Text('Itens do Kit (Avanço Individual)', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: kVettiGray.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: kVettiGray.withValues(alpha: 0.5)),
                  ),
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: _order.kitStatuses.length,
                    separatorBuilder: (_, __) => const Divider(height: 1, indent: 16, endIndent: 16),
                    itemBuilder: (ctx, idx) {
                      final comp = _order.kitStatuses[idx];
                      final compProgress = totalStages == 0 ? 0.0 : (comp.currentStageIndex + 1) / totalStages;
                      final compStageName = totalStages > comp.currentStageIndex ? _order.stageNames[comp.currentStageIndex] : '—';
                      
                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        title: Row(
                          children: [
                            Expanded(child: Text('${comp.productCode} (${comp.quantity} un)', style: const TextStyle(fontWeight: FontWeight.bold))),
                            if (comp.isCompleted)
                              const Icon(Icons.check_circle, color: Colors.green, size: 16),
                          ],
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(comp.productName, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12)),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('Etapa: $compStageName', style: TextStyle(fontSize: 11, color: comp.isCompleted ? Colors.green : kVettiBlue, fontWeight: FontWeight.w600)),
                                      const SizedBox(height: 4),
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(2),
                                        child: LinearProgressIndicator(
                                          value: compProgress,
                                          minHeight: 4,
                                          backgroundColor: kVettiGray,
                                          valueColor: AlwaysStoppedAnimation(comp.isCompleted ? Colors.green : kVettiBlue),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 12),
                                PopupMenuButton<String>(
                                  icon: const Icon(Icons.more_vert, size: 22, color: kVettiGrayDk),
                                  onSelected: (val) {
                                    if (val == 'advance') _advanceComponent(idx);
                                    if (val == 'edit') _editComponent(idx);
                                    if (val == 'delete') _deleteComponent(idx);
                                  },
                                  itemBuilder: (context) => [
                                    if (!comp.isCompleted)
                                      const PopupMenuItem(
                                        value: 'advance',
                                        child: Row(
                                          children: [
                                            Icon(Icons.skip_next_outlined, size: 20, color: kVettiBlue),
                                            SizedBox(width: 8),
                                            Text('Avançar Etapa'),
                                          ],
                                        ),
                                      ),
                                    const PopupMenuItem(
                                      value: 'edit',
                                      child: Row(
                                        children: [
                                          Icon(Icons.edit_outlined, size: 20, color: Colors.grey),
                                          SizedBox(width: 8),
                                          Text('Editar Quantidade'),
                                        ],
                                      ),
                                    ),
                                    const PopupMenuItem(
                                      value: 'delete',
                                      child: Row(
                                        children: [
                                          Icon(Icons.delete_outline, size: 20, color: Colors.red),
                                          SizedBox(width: 8),
                                          Text('Remover Item'),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // ── Progresso geral ───────────────────────────────────────────
            const Text('Progresso', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 10,
                backgroundColor: kVettiGray,
                valueColor: const AlwaysStoppedAnimation(kVettiBlue),
              ),
            ),
            const SizedBox(height: 12),

            // ── Linha de etapas ───────────────────────────────────────────
            Row(
              children: _order.stageNames.asMap().entries.map((e) {
                final idx  = e.key;
                final done = idx < _order.currentStageIndex;
                final curr = idx == _order.currentStageIndex;
                return Expanded(
                  child: Column(
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        height: 4,
                        margin: const EdgeInsets.symmetric(horizontal: 2),
                        decoration: BoxDecoration(
                          color: done || curr ? kVettiBlue : kVettiGray,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        e.value,
                        style: TextStyle(
                          fontSize: 10,
                          color: curr ? kVettiBlue : done ? Colors.green : kVettiGrayDk,
                          fontWeight: curr ? FontWeight.w700 : FontWeight.normal,
                        ),
                        textAlign: TextAlign.center,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 32),

            // ── Etapa atual em destaque ───────────────────────────────────
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: kVettiBlue.withValues(alpha: 0.07),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: kVettiBlue.withValues(alpha: 0.3)),
              ),
              child: Column(
                children: [
                  const Text(
                    'Etapa atual',
                    style: TextStyle(color: kVettiBlue, fontSize: 12, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _order.currentStageName,
                    style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w700, color: kVettiBlue),
                  ),
                  Text(
                    '${_order.currentStageIndex + 1} de $totalStages',
                    style: const TextStyle(color: kVettiGrayDk, fontSize: 13),
                  ),
                ],
              ),
            ),

            if (_order.kitStatuses.isEmpty) ...[
              const Spacer(),
              // ── Botão principal ───────────────────────────────────────────
              FilledButton(
                onPressed: _advancing ? null : _advance,
                style: FilledButton.styleFrom(
                  minimumSize: const Size(double.infinity, 64),
                  backgroundColor: isLast ? Colors.green : kVettiBlue,
                  disabledBackgroundColor: kVettiGray,
                ),
                child: _advancing
                    ? const SizedBox(
                        width: 24, height: 24,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                      )
                    : Text(
                        isLast ? 'CONCLUIR PEDIDO' : 'PRÓXIMA ETAPA',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white),
                      ),
              ),
            ] else ...[
              const SizedBox(height: 12),
              const Center(
                child: Text(
                  'O kit pode ser finalizado quando todos os itens forem concluídos.',
                  style: TextStyle(color: kVettiGrayDk, fontSize: 11, fontStyle: FontStyle.italic),
                ),
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: (_advancing || !_order.kitStatuses.every((s) => s.isCompleted)) ? null : _finalizeKit,
                style: FilledButton.styleFrom(
                  minimumSize: const Size(double.infinity, 64),
                  backgroundColor: Colors.green,
                  disabledBackgroundColor: kVettiGray,
                ),
                child: _advancing
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        'FINALIZAR LOTE KIT',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white),
                      ),
              ),
            ],
            const SizedBox(height: 8),
            const Text(
              'A TV atualiza automaticamente ao tocar',
              textAlign: TextAlign.center,
              style: TextStyle(color: kVettiGrayDk, fontSize: 12),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: kVettiGrayDk)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
