import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/figma_models.dart';
import '../../theme.dart';
import 'widgets.dart';

enum SmdOrderStatus {
  waiting,
  inProgress,
  partial,
  ready,
  sent,
}

class SmdOrder {
  final String id;
  final String opNumber;
  final String productCode;
  final String productName;
  final int plannedQty;
  final int receivedQty;
  final int producedQty;
  final int pendingQty;
  final int lossQty;
  final String nextStage;
  final SmdOrderStatus status;
  final List<SmdMaterial> materials;
  final List<SmdEvent> events;

  const SmdOrder({
    required this.id,
    required this.opNumber,
    required this.productCode,
    required this.productName,
    required this.plannedQty,
    required this.receivedQty,
    required this.producedQty,
    required this.pendingQty,
    required this.lossQty,
    required this.nextStage,
    required this.status,
    required this.materials,
    required this.events,
  });

  SmdOrder copyWith({
    int? producedQty,
    int? pendingQty,
    int? lossQty,
    String? nextStage,
    SmdOrderStatus? status,
    List<SmdEvent>? events,
  }) {
    return SmdOrder(
      id: id,
      opNumber: opNumber,
      productCode: productCode,
      productName: productName,
      plannedQty: plannedQty,
      receivedQty: receivedQty,
      producedQty: producedQty ?? this.producedQty,
      pendingQty: pendingQty ?? this.pendingQty,
      lossQty: lossQty ?? this.lossQty,
      nextStage: nextStage ?? this.nextStage,
      status: status ?? this.status,
      materials: materials,
      events: events ?? this.events,
    );
  }

  double get progress => receivedQty == 0 ? 0 : producedQty / receivedQty;
}

class SmdMaterial {
  final String code;
  final String description;
  final int quantity;
  final String lot;

  const SmdMaterial({
    required this.code,
    required this.description,
    required this.quantity,
    required this.lot,
  });
}

class SmdEvent {
  final String label;
  final String user;
  final DateTime at;

  const SmdEvent({
    required this.label,
    required this.user,
    required this.at,
  });
}

class SMDScreen extends StatefulWidget {
  final FigmaUser user;
  final void Function(BuildContext context) onLogout;

  const SMDScreen({
    super.key,
    required this.user,
    required this.onLogout,
  });

  @override
  State<SMDScreen> createState() => _SMDScreenState();
}

class _SMDScreenState extends State<SMDScreen> {
  late List<SmdOrder> _orders;
  String? _selectedId;
  final _qtyCtrl = TextEditingController();
  final _lossCtrl = TextEditingController(text: '0');
  String _nextStage = 'Gravacao';

  @override
  void initState() {
    super.initState();
    _orders = _mockOrders();
    _selectedId = _orders.first.id;
    _syncForm(_selectedOrder);
  }

  @override
  void dispose() {
    _qtyCtrl.dispose();
    _lossCtrl.dispose();
    super.dispose();
  }

  SmdOrder get _selectedOrder {
    return _orders.firstWhere(
      (order) => order.id == _selectedId,
      orElse: () => _orders.first,
    );
  }

  void _syncForm(SmdOrder order) {
    _qtyCtrl.text = order.pendingQty > 0 ? order.pendingQty.toString() : '0';
    _lossCtrl.text = '0';
    _nextStage = order.nextStage;
  }

  void _selectOrder(SmdOrder order) {
    setState(() {
      _selectedId = order.id;
      _syncForm(order);
    });
  }

  void _upsert(SmdOrder updated) {
    setState(() {
      final index = _orders.indexWhere((order) => order.id == updated.id);
      if (index >= 0) _orders[index] = updated;
      _selectedId = updated.id;
      _syncForm(updated);
    });
  }

  Future<bool> _confirmPin(String message) async {
    var confirmed = false;
    await showDialog<void>(
      context: context,
      builder: (_) => PinDialog(
        expectedPin: widget.user.pin,
        message: message,
        onResult: (ok) => confirmed = ok,
      ),
    );
    return confirmed;
  }

  Future<void> _startOrder(SmdOrder order) async {
    if (!await _confirmPin('Iniciar SMD da ${order.opNumber}')) return;
    _upsert(order.copyWith(
      status: SmdOrderStatus.inProgress,
      events: [
        SmdEvent(label: 'SMD iniciado', user: widget.user.name, at: DateTime.now()),
        ...order.events,
      ],
    ));
  }

  Future<void> _pointProduction(SmdOrder order) async {
    final qty = int.tryParse(_qtyCtrl.text.trim()) ?? 0;
    final loss = int.tryParse(_lossCtrl.text.trim()) ?? 0;

    if (qty <= 0 && loss <= 0) {
      _showSnack('Informe quantidade produzida ou perda.', Colors.orange);
      return;
    }

    if (qty + loss > order.pendingQty) {
      _showSnack('Quantidade maior que o saldo pendente.', Colors.orange);
      return;
    }

    if (!await _confirmPin('Apontar SMD da ${order.opNumber}')) return;

    final produced = order.producedQty + qty;
    final losses = order.lossQty + loss;
    final pending = order.pendingQty - qty - loss;
    _upsert(order.copyWith(
      producedQty: produced,
      lossQty: losses,
      pendingQty: pending,
      status: pending == 0 ? SmdOrderStatus.ready : SmdOrderStatus.partial,
      events: [
        SmdEvent(label: 'Apontado $qty un | perda $loss un', user: widget.user.name, at: DateTime.now()),
        ...order.events,
      ],
    ));
  }

  Future<void> _sendNext(SmdOrder order) async {
    if (order.producedQty <= 0) {
      _showSnack('Aponte ao menos uma quantidade antes de enviar.', Colors.orange);
      return;
    }
    if (!await _confirmPin('Enviar ${order.producedQty} un da ${order.opNumber} para $_nextStage')) return;

    _upsert(order.copyWith(
      nextStage: _nextStage,
      status: SmdOrderStatus.sent,
      events: [
        SmdEvent(label: 'Enviado para $_nextStage', user: widget.user.name, at: DateTime.now()),
        ...order.events,
      ],
    ));
  }

  void _showSnack(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: color),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('SMD'),
        actions: [
          IconButton(
            tooltip: 'Sair',
            icon: const Icon(Icons.logout),
            onPressed: () => widget.onLogout(context),
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isDesktop = constraints.maxWidth >= 980;
          if (isDesktop) {
            return Row(
              children: [
                SizedBox(width: 500, child: _buildQueue()),
                const VerticalDivider(width: 1),
                Expanded(child: _buildDetail(_selectedOrder, isDesktop: true)),
              ],
            );
          }

          return ListView(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 24),
            children: [
              _buildMobileHeader(),
              const SizedBox(height: 12),
              ..._orders.map((order) => _SmdMobileCard(
                    order: order,
                    statusLabel: _statusLabel(order.status),
                    statusColor: _statusColor(order.status),
                    onTap: () => _openMobileDetail(order),
                  )),
            ],
          );
        },
      ),
    );
  }

  Widget _buildQueue() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildDesktopHeader(),
        const SizedBox(height: 16),
        ..._orders.map((order) => _SmdQueueCard(
              order: order,
              selected: order.id == _selectedId,
              statusLabel: _statusLabel(order.status),
              statusColor: _statusColor(order.status),
              onTap: () => _selectOrder(order),
            )),
      ],
    );
  }

  Widget _buildMobileHeader() {
    final pending = _orders.where((order) => order.status == SmdOrderStatus.waiting).length;
    final ready = _orders.where((order) => order.status == SmdOrderStatus.ready).length;
    return _FlowHeader(
      subtitle: 'Apontamento de SMD',
      metrics: [
        _HeaderMetric(label: 'Fila', value: pending.toString(), color: kVettiBlue),
        _HeaderMetric(label: 'Prontas', value: ready.toString(), color: Colors.green),
      ],
    );
  }

  Widget _buildDesktopHeader() {
    final active = _orders.where((order) => order.status != SmdOrderStatus.sent).length;
    final sent = _orders.where((order) => order.status == SmdOrderStatus.sent).length;
    return _FlowHeader(
      subtitle: widget.user.name,
      metrics: [
        _HeaderMetric(label: 'Ativas', value: active.toString(), color: kVettiBlue),
        _HeaderMetric(label: 'Enviadas', value: sent.toString(), color: Colors.green),
      ],
    );
  }

  Future<void> _openMobileDetail(SmdOrder order) async {
    _selectOrder(order);
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: kVettiBackground,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(18))),
      builder: (sheetContext) {
        final current = _orders.firstWhere((item) => item.id == order.id, orElse: () => order);
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.86,
          minChildSize: 0.44,
          maxChildSize: 0.95,
          builder: (_, scrollController) {
            return ListView(
              controller: scrollController,
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
              children: [
                Center(
                  child: Container(
                    width: 42,
                    height: 4,
                    decoration: BoxDecoration(color: kVettiGray, borderRadius: BorderRadius.circular(20)),
                  ),
                ),
                const SizedBox(height: 16),
                _buildSummary(current),
                const SizedBox(height: 14),
                _buildActionForm(current, closeAfterAction: true, sheetContext: sheetContext),
                const SizedBox(height: 18),
                _buildMaterials(current),
                const SizedBox(height: 12),
                TextButton.icon(
                  onPressed: () => Navigator.pop(sheetContext),
                  icon: const Icon(Icons.close),
                  label: const Text('FECHAR'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildDetail(SmdOrder order, {required bool isDesktop}) {
    return ListView(
      padding: EdgeInsets.all(isDesktop ? 24 : 0),
      children: [
        _buildSummary(order),
        const SizedBox(height: 16),
        _buildActionForm(order),
        const SizedBox(height: 18),
        _buildMaterials(order),
        const SizedBox(height: 20),
        Text('Historico', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
        const SizedBox(height: 8),
        ...order.events.map((event) => _SmdEventTile(event: event)),
      ],
    );
  }

  Widget _buildSummary(SmdOrder order) {
    return Card(
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(order.opNumber, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
                ),
                _StatusPill(label: _statusLabel(order.status), color: _statusColor(order.status)),
              ],
            ),
            const SizedBox(height: 6),
            Text('${order.productCode} - ${order.productName}', style: const TextStyle(color: kVettiBlue, fontWeight: FontWeight.w800)),
            const SizedBox(height: 14),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _InfoBadge(label: 'Recebido', value: '${order.receivedQty} un'),
                _InfoBadge(label: 'Produzido', value: '${order.producedQty} un'),
                _InfoBadge(label: 'Pendente', value: '${order.pendingQty} un'),
                _InfoBadge(label: 'Perda', value: '${order.lossQty} un', color: order.lossQty > 0 ? Colors.orange : null),
              ],
            ),
            const SizedBox(height: 14),
            LinearProgressIndicator(
              value: order.progress.clamp(0, 1),
              minHeight: 7,
              backgroundColor: kVettiGray,
              valueColor: AlwaysStoppedAnimation(_statusColor(order.status)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionForm(SmdOrder order, {bool closeAfterAction = false, BuildContext? sheetContext}) {
    final isStarted = order.status != SmdOrderStatus.waiting;
    final canStart = order.status == SmdOrderStatus.waiting;
    final canPoint = isStarted && order.status != SmdOrderStatus.sent && order.pendingQty > 0;
    final canSend = isStarted && order.producedQty > 0 && order.status != SmdOrderStatus.sent;

    Future<void> run(Future<void> Function() action) async {
      await action();
      if (closeAfterAction && sheetContext != null && sheetContext.mounted) {
        Navigator.pop(sheetContext);
      }
    }

    return Card(
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Apontamento', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
            const SizedBox(height: 12),
            if (canStart) ...[
              const Text(
                'Inicie a etapa para liberar os apontamentos desta OP.',
                style: TextStyle(color: kVettiGrayDk, fontSize: 13),
              ),
              const SizedBox(height: 10),
              FilledButton.icon(
                onPressed: () => run(() => _startOrder(order)),
                icon: const Icon(Icons.play_arrow),
                label: const Text('INICIAR SMD'),
              ),
            ],
            if (canPoint) ...[
              const Text(
                'Quantidade desta etapa',
                style: TextStyle(color: kVettiGrayDk, fontSize: 13, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 10),
              LayoutBuilder(
                builder: (context, constraints) {
                  final fields = [
                    TextField(
                      controller: _qtyCtrl,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: const InputDecoration(
                        labelText: 'Qtd boa',
                        suffixText: 'un',
                        contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                      ),
                    ),
                    TextField(
                      controller: _lossCtrl,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: const InputDecoration(
                        labelText: 'Perda',
                        suffixText: 'un',
                        contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                      ),
                    ),
                  ];

                  if (constraints.maxWidth < 420) {
                    return Column(
                      children: [
                        fields.first,
                        const SizedBox(height: 10),
                        fields.last,
                      ],
                    );
                  }

                  return Row(
                    children: [
                      Expanded(child: fields.first),
                      const SizedBox(width: 10),
                      Expanded(child: fields.last),
                    ],
                  );
                },
              ),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: () => run(() => _pointProduction(order)),
                icon: const Icon(Icons.check),
                label: const Text('APONTAR'),
              ),
            ],
            if (canSend) ...[
              const Divider(height: 28),
              DropdownButtonFormField<String>(
                initialValue: _nextStage,
                decoration: const InputDecoration(
                  labelText: 'Proxima etapa',
                  prefixIcon: Icon(Icons.call_split_outlined),
                  contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                ),
                items: const [
                  DropdownMenuItem(value: 'Gravacao', child: Text('Gravacao')),
                  DropdownMenuItem(value: 'Soldagem', child: Text('Soldagem')),
                ],
                onChanged: (value) {
                  if (value != null) setState(() => _nextStage = value);
                },
              ),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: () => run(() => _sendNext(order)),
                icon: const Icon(Icons.send_outlined),
                label: const Text('ENVIAR PARA PROXIMA ETAPA'),
              ),
            ],
            if (!canStart && !canPoint && !canSend)
              const Text(
                'Esta OP ja foi enviada para a proxima etapa.',
                style: TextStyle(color: kVettiGrayDk, fontSize: 13),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMaterials(SmdOrder order) {
    return Card(
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Materiais recebidos', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
            const SizedBox(height: 10),
            ...order.materials.map((material) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      const Icon(Icons.inventory_2_outlined, color: kVettiBlue, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(material.code, style: const TextStyle(fontWeight: FontWeight.w900)),
                            Text(material.description, overflow: TextOverflow.ellipsis, style: const TextStyle(color: kVettiGrayDk, fontSize: 12)),
                          ],
                        ),
                      ),
                      Text('${material.quantity} un', style: const TextStyle(fontWeight: FontWeight.w900)),
                    ],
                  ),
                )),
          ],
        ),
      ),
    );
  }

  String _statusLabel(SmdOrderStatus status) {
    switch (status) {
      case SmdOrderStatus.waiting:
        return 'Aguardando';
      case SmdOrderStatus.inProgress:
        return 'Em SMD';
      case SmdOrderStatus.partial:
        return 'Parcial';
      case SmdOrderStatus.ready:
        return 'Pronta';
      case SmdOrderStatus.sent:
        return 'Enviada';
    }
  }

  Color _statusColor(SmdOrderStatus status) {
    switch (status) {
      case SmdOrderStatus.waiting:
        return kVettiGrayDk;
      case SmdOrderStatus.inProgress:
      case SmdOrderStatus.partial:
        return kVettiBlue;
      case SmdOrderStatus.ready:
      case SmdOrderStatus.sent:
        return Colors.green;
    }
  }

  List<SmdOrder> _mockOrders() {
    final now = DateTime.now();
    return [
      SmdOrder(
        id: 'smd-1',
        opNumber: 'OP-2606-001',
        productCode: '105-141',
        productName: 'Central Vetti Smart',
        plannedQty: 5000,
        receivedQty: 5000,
        producedQty: 0,
        pendingQty: 5000,
        lossQty: 0,
        nextStage: 'Gravacao',
        status: SmdOrderStatus.waiting,
        materials: const [
          SmdMaterial(code: 'PCB-VS-01', description: 'Placa circuito central smart', quantity: 5000, lot: 'L2406-A'),
          SmdMaterial(code: 'IC-ESP32', description: 'Modulo ESP32 homologado', quantity: 5000, lot: 'L2405-C'),
          SmdMaterial(code: 'CON-8V', description: 'Conector borne 8 vias', quantity: 10000, lot: 'L2404-B'),
        ],
        events: [
          SmdEvent(label: 'Recebida do Almoxarifado', user: 'Vera (Almoxarifado)', at: now.subtract(const Duration(minutes: 18))),
        ],
      ),
      SmdOrder(
        id: 'smd-2',
        opNumber: 'OP-2606-002',
        productCode: '220-018',
        productName: 'Controle 4 Botoes',
        plannedQty: 1500,
        receivedQty: 1500,
        producedQty: 500,
        pendingQty: 1000,
        lossQty: 0,
        nextStage: 'Gravacao',
        status: SmdOrderStatus.partial,
        materials: const [
          SmdMaterial(code: 'RES-10K', description: 'Resistor 10k 0603', quantity: 1500, lot: 'L2406-R'),
          SmdMaterial(code: 'CASE-4B', description: 'Gabinete controle 4 botoes', quantity: 1500, lot: 'L2406-G'),
        ],
        events: [
          SmdEvent(label: 'Apontado 500 un | perda 0 un', user: 'Paula (SMD)', at: now.subtract(const Duration(minutes: 7))),
          SmdEvent(label: 'SMD iniciado', user: 'Paula (SMD)', at: now.subtract(const Duration(minutes: 12))),
        ],
      ),
    ];
  }
}

class _FlowHeader extends StatelessWidget {
  final String subtitle;
  final List<_HeaderMetric> metrics;

  const _FlowHeader({
    required this.subtitle,
    required this.metrics,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const _VettiWordmark(),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(subtitle, style: const TextStyle(color: kVettiGrayDk, fontWeight: FontWeight.w700)),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: metrics
                  .map((metric) => Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: metric,
                        ),
                      ))
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeaderMetric extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _HeaderMetric({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: color)),
          const SizedBox(width: 8),
          Expanded(child: Text(label, overflow: TextOverflow.ellipsis, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w700))),
        ],
      ),
    );
  }
}

class _SmdMobileCard extends StatelessWidget {
  final SmdOrder order;
  final String statusLabel;
  final Color statusColor;
  final VoidCallback onTap;

  const _SmdMobileCard({
    required this.order,
    required this.statusLabel,
    required this.statusColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(child: Text(order.opNumber, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900))),
                  _StatusPill(label: statusLabel, color: statusColor),
                ],
              ),
              const SizedBox(height: 6),
              Text(order.productName, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: LinearProgressIndicator(
                      value: order.progress.clamp(0, 1),
                      minHeight: 5,
                      backgroundColor: kVettiGray,
                      valueColor: AlwaysStoppedAnimation(statusColor),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text('${order.pendingQty} pend.', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 12)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SmdQueueCard extends StatelessWidget {
  final SmdOrder order;
  final bool selected;
  final String statusLabel;
  final Color statusColor;
  final VoidCallback onTap;

  const _SmdQueueCard({
    required this.order,
    required this.selected,
    required this.statusLabel,
    required this.statusColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: selected ? kVettiBlue : Colors.transparent, width: 1.5),
      ),
      child: ListTile(
        onTap: onTap,
        title: Text(order.opNumber, style: const TextStyle(fontWeight: FontWeight.w900)),
        subtitle: Text('${order.productCode} - ${order.productName}', overflow: TextOverflow.ellipsis),
        trailing: _StatusPill(label: statusLabel, color: statusColor),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  final String label;
  final Color color;

  const _StatusPill({
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 112),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(6)),
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w900),
        ),
      ),
    );
  }
}

class _InfoBadge extends StatelessWidget {
  final String label;
  final String value;
  final Color? color;

  const _InfoBadge({
    required this.label,
    required this.value,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: (color ?? kVettiBlue).withValues(alpha: color == null ? 0.06 : 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: const TextStyle(fontSize: 10, color: kVettiGrayDk, fontWeight: FontWeight.w700)),
          const SizedBox(height: 2),
          Text(value, style: TextStyle(fontWeight: FontWeight.w900, color: color ?? Colors.black87)),
        ],
      ),
    );
  }
}

class _SmdEventTile extends StatelessWidget {
  final SmdEvent event;

  const _SmdEventTile({required this.event});

  @override
  Widget build(BuildContext context) {
    final hour = event.at.hour.toString().padLeft(2, '0');
    final minute = event.at.minute.toString().padLeft(2, '0');
    return ListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      leading: const Icon(Icons.history, size: 20, color: kVettiGrayDk),
      title: Text(event.label, style: const TextStyle(fontWeight: FontWeight.w700)),
      subtitle: Text('${event.user} - $hour:$minute'),
    );
  }
}

class _VettiWordmark extends StatelessWidget {
  const _VettiWordmark();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 72,
      height: 36,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: kVettiGray),
      ),
      child: const Text(
        'VETTI',
        style: TextStyle(
          color: kVettiBlue,
          fontSize: 19,
          fontWeight: FontWeight.w900,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}
