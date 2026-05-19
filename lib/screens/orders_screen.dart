import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import '../services/signalr_service.dart';
import '../theme.dart';
import 'new_order_screen.dart';
import 'new_product_screen.dart';
import 'order_detail_screen.dart';
import 'settings_screen.dart';
import 'products_screen.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<ProductionOrder> _orders = [];
  List<ProductionOrder> _completedOrders = [];
  bool _loading = true;
  String? _error;
  bool _isSignalRConnected = false;
  String _logFilter = 'Hoje'; // 'Hoje', 'Semana', 'Mês', 'Tudo'

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (mounted) setState(() {}); // Atualiza para mostrar/esconder o botão de delete
    });
    _load();
    _initSignalR();
  }

  Future<void> _confirmDeleteCompleted() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Limpar Histórico'),
        content: const Text('Deseja apagar todos os lotes finalizados? Esta ação não pode ser desfeita.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('CANCELAR')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('LIMPAR TUDO'),
          ),
        ],
      ),
    );

    if (ok == true) {
      try {
        setState(() => _loading = true);
        await ApiService.instance.deleteCompletedOrders();
        _load();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
          );
        }
      } finally {
        if (mounted) setState(() => _loading = false);
      }
    }
  }

  Future<void> _initSignalR() async {
    SignalRService.instance.addRefreshListener(_load);
    await SignalRService.instance.connect();
    if (mounted) {
      setState(() => _isSignalRConnected = SignalRService.instance.isConnected);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    SignalRService.instance.removeRefreshListener(_load);
    super.dispose();
  }

  Future<void> _load() async {
    try {
      if (!mounted) return;
      setState(() { _loading = true; _error = null; });
      final allOrders = await ApiService.instance.getActiveOrders();
      final settings = await ApiService.instance.loadSettings();
      if (!mounted) return;
      
      // Ordenação baseada em preferência
      allOrders.sort((a, b) {
        if (settings.sortBy == 'prioridade') {
          if (a.isHighPriority != b.isHighPriority) {
            return a.isHighPriority ? -1 : 1;
          }
        }
        return b.id.compareTo(a.id);
      });

      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final weekStart = today.subtract(Duration(days: now.weekday - 1));
      final monthStart = DateTime(now.year, now.month, 1);

      setState(() { 
        _orders = allOrders.where((o) => !o.isCompleted).toList();
        
        final completed = allOrders.where((o) => o.isCompleted).toList();
        _completedOrders = completed.where((o) {
          if (_logFilter == 'Tudo') return true;
          
          final dateToCompare = (o.completedAt ?? o.createdAt ?? DateTime.now()).toLocal();

          if (_logFilter == 'Hoje') {
            return dateToCompare.year == now.year && 
                   dateToCompare.month == now.month && 
                   dateToCompare.day == now.day;
          } else if (_logFilter == 'Semana') {
            // Considerar hoje inclusive
            return dateToCompare.isAfter(weekStart.subtract(const Duration(seconds: 1)));
          } else if (_logFilter == 'Mês') {
            return dateToCompare.isAfter(monthStart.subtract(const Duration(seconds: 1)));
          }
          return true;
        }).toList();

        _isSignalRConnected = SignalRService.instance.isConnected;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() { _error = 'Não foi possível conectar ao servidor'; });
    } finally {
      if (mounted) {
        setState(() { _loading = false; });
      }
    }
  }

  void _exportLogs() {
    if (_completedOrders.isEmpty) return;
    
    final buffer = StringBuffer();
    // Cabeçalho separado por TAB para compatibilidade Excel direta (ao colar)
    buffer.writeln('ID\tLote/Pedido\tQuantidade\tCriação\tConclusão\tPrioridade');
    for (var o in _completedOrders) {
      final created = o.createdAt != null ? '${o.createdAt!.day.toString().padLeft(2, '0')}/${o.createdAt!.month.toString().padLeft(2, '0')} ${o.createdAt!.hour.toString().padLeft(2, '0')}:${o.createdAt!.minute.toString().padLeft(2, '0')}' : '—';
      final completed = o.completedAt != null ? '${o.completedAt!.day.toString().padLeft(2, '0')}/${o.completedAt!.month.toString().padLeft(2, '0')} ${o.completedAt!.hour.toString().padLeft(2, '0')}:${o.completedAt!.minute.toString().padLeft(2, '0')}' : '—';
      
      buffer.writeln('${o.id}\t${o.label}\t${o.totalQty}\t$created\t$completed\t${o.isHighPriority ? 'ALTA' : 'NORMAL'}');
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Exportar para Excel'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Instruções:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            const Text('1. Clique no texto abaixo e copie tudo.\n2. Abra o Excel e cole (Ctrl+V).\n3. O Excel organizará as colunas automaticamente.', 
              style: TextStyle(fontSize: 12, color: kVettiGrayDk)),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              height: 250,
              width: double.maxFinite,
              decoration: BoxDecoration(
                color: Colors.blueGrey.withOpacity(0.05),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: kVettiGray),
              ),
              child: SingleChildScrollView(
                child: SelectableText(
                  buffer.toString(), 
                  style: const TextStyle(fontSize: 11, fontFamily: 'monospace', color: Colors.blueGrey)
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('FECHAR')),
          FilledButton.icon(
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: buffer.toString()));
              if (mounted) {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Conteúdo copiado com sucesso!')));
              }
            },
            icon: const Icon(Icons.copy, size: 18),
            label: const Text('COPIAR TUDO'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final showCompletedActions = _tabController.index == 1 && _completedOrders.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Text('VETTI Flow', style: TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(width: 8),
            Container(
              width: 8, height: 8,
              decoration: BoxDecoration(
                color: _isSignalRConnected ? Colors.green : Colors.red,
                shape: BoxShape.circle,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.inventory_2_outlined),
            tooltip: 'Produtos',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ProductsScreen()),
            ),
          ),
          if (showCompletedActions) ...[
            IconButton(
              icon: const Icon(Icons.ios_share_outlined),
              tooltip: 'Exportar logs',
              onPressed: _exportLogs,
            ),
            IconButton(
              icon: const Icon(Icons.delete_sweep_outlined),
              tooltip: 'Limpar finalizados',
              onPressed: _confirmDeleteCompleted,
            ),
          ],
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              );
              _load(); // Recarrega para aplicar possiveis mudanças de ordenação
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'EM CURSO', icon: Icon(Icons.play_circle_outline)),
            Tab(text: 'FINALIZADOS', icon: Icon(Icons.check_circle_outline)),
          ],
        ),
      ),
      body: Column(
        children: [
          if (_tabController.index == 1)
            Container(
              color: kVettiGray.withOpacity(0.3),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  const Text('Filtro:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  const SizedBox(width: 12),
                  ...['Hoje', 'Semana', 'Mês', 'Tudo'].map((f) => Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(f, style: const TextStyle(fontSize: 11)),
                      selected: _logFilter == f,
                      onSelected: (val) {
                        if (val) {
                          setState(() => _logFilter = f);
                          _load();
                        }
                      },
                      padding: EdgeInsets.zero,
                      visualDensity: VisualDensity.compact,
                    ),
                  )),
                ],
              ),
            ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                RefreshIndicator(
                  color: kVettiBlue,
                  onRefresh: _load,
                  child: _buildList(_orders, false),
                ),
                RefreshIndicator(
                  color: kVettiBlue,
                  onRefresh: _load,
                  child: _buildList(_completedOrders, true),
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          FloatingActionButton.extended(
            heroTag: 'newProduct',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const NewProductScreen()),
            ),
            backgroundColor: kVettiGray,
            foregroundColor: kVettiBlue,
            icon: const Icon(Icons.inventory_2_outlined),
            label: const Text('Novo Produto', style: TextStyle(fontWeight: FontWeight.w600)),
          ),
          const SizedBox(height: 12),
          FloatingActionButton.extended(
            heroTag: 'newOrder',
            onPressed: () async {
              final created = await Navigator.push<bool>(
                context,
                MaterialPageRoute(builder: (_) => const NewOrderScreen()),
              );
              if (created == true) _load();
            },
            backgroundColor: kVettiBlue,
            foregroundColor: Colors.white,
            icon: const Icon(Icons.add),
            label: const Text('Novo Lote', style: TextStyle(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  Widget _buildList(List<ProductionOrder> list, bool isCompletedList) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: kVettiBlue));
    }
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.wifi_off, size: 48, color: kVettiGrayDk),
            const SizedBox(height: 12),
            const Text('Sem conexão com o servidor', style: TextStyle(color: kVettiGrayDk)),
            const SizedBox(height: 8),
            TextButton(onPressed: _load, child: const Text('Tentar novamente')),
          ],
        ),
      );
    }
    if (list.isEmpty) {
      return Center(
        child: Text(
          isCompletedList ? 'Nenhum lote finalizado ainda.' : 'Nenhum lote em andamento.\nToque em + para lançar.', 
          textAlign: TextAlign.center
        ),
      );
    }
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 500),
      child: ListView.separated(
        key: ValueKey('${list.length}_$isCompletedList'),
        padding: const EdgeInsets.all(16),
        itemCount: list.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (_, i) => _OrderCard(
          order: list[i],
          onRefresh: _load,
          onTap: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => OrderDetailScreen(order: list[i])),
            );
            _load(); // Refresh ao voltar, garantindo dados novos
          },
        ),
      ),
    );
  }
}

// ── Card de resumo na lista ───────────────────────────────────────────────────

class _OrderCard extends StatefulWidget {
  final ProductionOrder order;
  final VoidCallback onTap;
  final VoidCallback onRefresh;

  const _OrderCard({required this.order, required this.onTap, required this.onRefresh});

  @override
  State<_OrderCard> createState() => _OrderCardState();
}

class _OrderCardState extends State<_OrderCard> {
  @override
  Widget build(BuildContext context) {
    final progress = widget.order.stageNames.isEmpty
        ? 0.0
        : (widget.order.currentStageIndex + 1) / widget.order.stageNames.length;

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: widget.onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.order.productCode.isNotEmpty 
                              ? '${widget.order.productCode} — ${widget.order.productName}'
                              : widget.order.label,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: kVettiBlue),
                        ),
                        if (widget.order.productCode.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Text(
                              'Lote: ${widget.order.label}',
                              style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13, color: Colors.black87),
                            ),
                          ),
                      ],
                    ),
                  ),
                  if (widget.order.isHighPriority)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: kVettiBlue,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        'ALTA',
                        style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                '${widget.order.totalQty} un · Etapa: ${widget.order.currentStageName}',
                style: const TextStyle(color: kVettiGrayDk, fontSize: 13, fontWeight: FontWeight.w500),
              ),
              if (widget.order.componentCodes.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  'Composição: ${widget.order.componentCodes}',
                  style: const TextStyle(color: Colors.blueGrey, fontSize: 11, fontStyle: FontStyle.italic),
                ),
              ],
              
              if (widget.order.kitStatuses.isNotEmpty) ...[
                const SizedBox(height: 12),
                const Divider(height: 1, color: kVettiGray),
                const SizedBox(height: 8),
                ...widget.order.kitStatuses.asMap().entries.map((entry) {
                  final comp = entry.value;
                  final compProgress = widget.order.stageNames.isEmpty
                      ? 0.0
                      : (comp.currentStageIndex + 1) / widget.order.stageNames.length;
                  
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '${comp.productCode} - ${comp.productName}',
                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                            ),
                            if (!widget.order.isCompleted)
                            InkWell(
                              onTap: () async {
                                try {
                                  // Feedback imediato local
                                  setState(() {
                                    final nextIdx = comp.currentStageIndex + 1;
                                    final isDone = nextIdx >= widget.order.stageNames.length;
                                    final updatedComp = KitComponentStatus(
                                      productCode: comp.productCode,
                                      productName: comp.productName,
                                      quantity: comp.quantity,
                                      currentStageIndex: nextIdx,
                                      isCompleted: isDone,
                                    );
                                    widget.order.kitStatuses[entry.key] = updatedComp;
                                  });
                                  
                                  await ApiService.instance.advanceStage(widget.order.id, componentIndex: entry.key);
                                  widget.onRefresh(); 
                                } catch (e) {
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('Erro: $e'), backgroundColor: Colors.red),
                                    );
                                  }
                                }
                              },
                              child: const Icon(Icons.skip_next, size: 24, color: kVettiBlue),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        LinearProgressIndicator(
                          value: compProgress,
                          minHeight: 3,
                          backgroundColor: kVettiGray,
                          valueColor: AlwaysStoppedAnimation(comp.isCompleted ? Colors.green : Colors.green.withOpacity(0.5)),
                        ),
                      ],
                    ),
                  );
                }),
              ] else ...[
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 6,
                    backgroundColor: kVettiGray,
                    valueColor: const AlwaysStoppedAnimation(kVettiBlue),
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: widget.order.stageNames.asMap().entries.map((e) {
                    final done = e.key <= widget.order.currentStageIndex;
                    return Flexible(
                      child: Text(
                        e.value,
                        style: TextStyle(
                          fontSize: 10,
                          color: done ? kVettiBlue : kVettiGrayDk,
                          fontWeight: done ? FontWeight.w600 : FontWeight.normal,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  }).toList(),
                ),
              ],
              
              if (widget.order.isCompleted && widget.order.completedAt != null) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(Icons.history, size: 14, color: kVettiGrayDk),
                    const SizedBox(width: 4),
                    Text(
                      'Finalizado em: ${_formatDate(widget.order.completedAt!)}',
                      style: const TextStyle(color: kVettiGrayDk, fontSize: 11),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime dt) {
    return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}
