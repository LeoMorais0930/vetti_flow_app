import 'package:flutter/material.dart';
import 'dart:async';
import '../../models/figma_models.dart';
import '../../services/figma_service.dart';
import 'widgets.dart';

class RequisitionsScreen extends StatefulWidget {
  final FigmaUser user;
  final void Function(BuildContext) onLogout;

  const RequisitionsScreen({super.key, required this.user, required this.onLogout});

  @override
  State<RequisitionsScreen> createState() => _RequisitionsScreenState();
}

class _RequisitionsScreenState extends State<RequisitionsScreen> {
  final FigmaService _service = FigmaService();
  int _viewIndex = 0; // 0: Summary, 1: List, 2: Detail, 3: Selection, 4: Transfer, 5: Success
  FigmaRequisition? _selectedRequisition;

  void _nextView() => setState(() => _viewIndex++);
  void _resetFlow() => setState(() {
    _viewIndex = 0;
    _selectedRequisition = null;
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: FigmaAppBar(
        title: 'Requisições',
        user: widget.user,
        icon: Icons.list_alt,
        onLogout: widget.onLogout,
      ),
      body: _buildCurrentView(),
    );
  }

  Widget _buildCurrentView() {
    switch (_viewIndex) {
      case 0: return _buildSummary();
      case 1: return _buildList();
      case 2: return _buildDetail();
      case 3: return _buildSelection();
      case 4: return _buildTransferProgress();
      case 5: return _buildSuccess();
      default: return _buildSummary();
    }
  }

  Widget _buildSummary() {
    final count = _service.requisitions.where((r) => r.status != RequisitionStatus.completed).length;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.inventory_2, size: 80, color: Colors.blue),
          const SizedBox(height: 16),
          Text('$count', style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold)),
          const Text('Requisições Pendentes', style: TextStyle(fontSize: 18, color: Colors.grey)),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: () => setState(() => _viewIndex = 1),
            style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16)),
            child: const Text('VER REQUISIÇÕES'),
          ),
        ],
      ),
    );
  }

  Widget _buildList() {
    final pending = _service.requisitions.where((r) => r.status != RequisitionStatus.completed).toList();
    return ListView.builder(
      itemCount: pending.length,
      itemBuilder: (context, index) {
        final req = pending[index];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: ListTile(
            title: Text('Requisição ${req.number}', style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text('${req.items.length} itens'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              setState(() {
                _selectedRequisition = req;
                _viewIndex = 2;
              });
            },
          ),
        );
      },
    );
  }

  Widget _buildDetail() {
    if (_selectedRequisition == null) return const SizedBox();
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Itens da Requisição ${_selectedRequisition!.number}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.builder(
              itemCount: _selectedRequisition!.items.length,
              itemBuilder: (context, index) {
                final item = _selectedRequisition!.items[index];
                return ListTile(
                  title: Text(item.description),
                  subtitle: Text(item.code),
                  trailing: Text('${item.requestedQuantity}', style: const TextStyle(fontWeight: FontWeight.bold)),
                );
              },
            ),
          ),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _nextView,
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white),
              child: const Text('INICIAR'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSelection() {
    if (_selectedRequisition == null) return const SizedBox();
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Marque os itens disponíveis para transferência', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.builder(
              itemCount: _selectedRequisition!.items.length,
              itemBuilder: (context, index) {
                final item = _selectedRequisition!.items[index];
                return CheckboxListTile(
                  title: Text(item.description),
                  subtitle: Text(item.code),
                  value: item.isMarked,
                  onChanged: (val) {
                    setState(() {
                      final updatedItems = List<FigmaRequisitionItem>.from(_selectedRequisition!.items);
                      updatedItems[index] = item.copyWith(isMarked: val ?? false);
                      _selectedRequisition = _selectedRequisition!.copyWith(items: updatedItems);
                    });
                  },
                );
              },
            ),
          ),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => _confirmPin(),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
              child: const Text('APROVAR'),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmPin() {
    showDialog(
      context: context,
      builder: (context) => PinDialog(
        expectedPin: widget.user.pin,
        message: 'Aprovar transferência da Req. ${_selectedRequisition!.number}',
        onResult: (ok) {
          if (ok) {
            _nextView();
          }
        },
      ),
    );
  }

  Widget _buildTransferProgress() {
    return _TransferTimer(onComplete: _nextView);
  }

  Widget _buildSuccess() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.check_circle, size: 100, color: Colors.green),
          const SizedBox(height: 24),
          const Text('COMPLETO', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.green)),
          const SizedBox(height: 16),
          const Text('Transferência realizada com sucesso no Protheus.', textAlign: TextAlign.center),
          const SizedBox(height: 48),
          ElevatedButton(
            onPressed: () {
              // Mark as completed in service
              if (_selectedRequisition != null) {
                _service.updateRequisition(_selectedRequisition!.copyWith(status: RequisitionStatus.completed));
              }
              _resetFlow();
            },
            child: const Text('VOLTAR'),
          ),
        ],
      ),
    );
  }
}

class _TransferTimer extends StatefulWidget {
  final VoidCallback onComplete;
  const _TransferTimer({required this.onComplete});

  @override
  State<_TransferTimer> createState() => _TransferTimerState();
}

class _TransferTimerState extends State<_TransferTimer> {
  int _seconds = 60;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_seconds > 0) {
        setState(() => _seconds--);
      } else {
        _timer?.cancel();
        widget.onComplete();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 32),
            const Text('Aguardando lançamentos no Protheus...', textAlign: TextAlign.center, style: TextStyle(fontSize: 18)),
            const SizedBox(height: 16),
            Text('$_seconds segundos restantes', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.blue)),
          ],
        ),
      ),
    );
  }
}
