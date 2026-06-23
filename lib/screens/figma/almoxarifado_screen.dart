import 'package:flutter/material.dart';
import '../../models/figma_models.dart';
import '../../theme.dart';
import 'create_op_screen.dart';
import 'widgets.dart';

enum WarehouseOrderStatus {
  waiting,
  separating,
  partial,
  blocked,
  ready,
  releasedSmd,
  releasedProduction,
}

class WarehouseOrder {
  final String id;
  final String opNumber;
  final String productCode;
  final String productName;
  final int quantity;
  final String destination;
  final bool highPriority;
  final WarehouseOrderStatus status;
  final List<WarehouseMaterial> materials;
  final List<WarehouseEvent> events;
  final String? blockedReason;

  const WarehouseOrder({
    required this.id,
    required this.opNumber,
    required this.productCode,
    required this.productName,
    required this.quantity,
    required this.destination,
    required this.highPriority,
    required this.status,
    required this.materials,
    required this.events,
    this.blockedReason,
  });

  WarehouseOrder copyWith({
    String? destination,
    WarehouseOrderStatus? status,
    List<WarehouseMaterial>? materials,
    List<WarehouseEvent>? events,
    String? blockedReason,
  }) {
    return WarehouseOrder(
      id: id,
      opNumber: opNumber,
      productCode: productCode,
      productName: productName,
      quantity: quantity,
      destination: destination ?? this.destination,
      highPriority: highPriority,
      status: status ?? this.status,
      materials: materials ?? this.materials,
      events: events ?? this.events,
      blockedReason: blockedReason,
    );
  }

  bool get hasShortage => materials.any((m) => m.shortage > 0);
  bool get isFullySeparated => materials.every((m) => m.separatedQty >= m.requiredQty);
  int get separatedLines => materials.where((m) => m.separatedQty >= m.requiredQty).length;
}

class WarehouseMaterial {
  final String code;
  final String description;
  final String unit;
  final double requiredQty;
  final double stockQty;
  final double separatedQty;
  final String warehouse;
  final String lot;
  final String address;

  const WarehouseMaterial({
    required this.code,
    required this.description,
    required this.unit,
    required this.requiredQty,
    required this.stockQty,
    required this.separatedQty,
    required this.warehouse,
    required this.lot,
    required this.address,
  });

  double get shortage => requiredQty > stockQty ? requiredQty - stockQty : 0;

  WarehouseMaterial copyWith({double? separatedQty}) {
    return WarehouseMaterial(
      code: code,
      description: description,
      unit: unit,
      requiredQty: requiredQty,
      stockQty: stockQty,
      separatedQty: separatedQty ?? this.separatedQty,
      warehouse: warehouse,
      lot: lot,
      address: address,
    );
  }
}

class WarehouseEvent {
  final String label;
  final String user;
  final DateTime at;

  const WarehouseEvent({
    required this.label,
    required this.user,
    required this.at,
  });
}

class AlmoxarifadoScreen extends StatefulWidget {
  final FigmaUser user;
  final void Function(BuildContext context) onLogout;

  const AlmoxarifadoScreen({
    super.key,
    required this.user,
    required this.onLogout,
  });

  @override
  State<AlmoxarifadoScreen> createState() => _AlmoxarifadoScreenState();
}

class _AlmoxarifadoScreenState extends State<AlmoxarifadoScreen> {
  late List<WarehouseOrder> _orders;
  String? _selectedId;
  String _statusFilter = 'Todas';
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _orders = _mockOrders();
    _selectedId = _orders.first.id;
    _searchCtrl.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  WarehouseOrder get _selectedOrder {
    return _orders.firstWhere(
      (order) => order.id == _selectedId,
      orElse: () => _orders.first,
    );
  }

  List<WarehouseOrder> get _filteredOrders {
    final query = _searchCtrl.text.trim().toLowerCase();
    return _orders.where((order) {
      final matchesStatus = _statusFilter == 'Todas' || _statusLabel(order.status) == _statusFilter;
      final matchesQuery = query.isEmpty ||
          order.opNumber.toLowerCase().contains(query) ||
          order.productCode.toLowerCase().contains(query) ||
          order.productName.toLowerCase().contains(query);
      return matchesStatus && matchesQuery;
    }).toList();
  }

  void _upsertOrder(WarehouseOrder updated) {
    setState(() {
      final index = _orders.indexWhere((order) => order.id == updated.id);
      if (index >= 0) _orders[index] = updated;
      _selectedId = updated.id;
    });
  }

  void _addEvent(WarehouseOrder order, String label, WarehouseOrderStatus status) {
    _upsertOrder(order.copyWith(
      status: status,
      events: [
        WarehouseEvent(label: label, user: widget.user.name, at: DateTime.now()),
        ...order.events,
      ],
    ));
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

  Future<void> _startSeparation(WarehouseOrder order) async {
    if (!await _confirmPin('Iniciar separacao da ${order.opNumber}')) return;
    _addEvent(order, 'Separacao iniciada', WarehouseOrderStatus.separating);
  }

  Future<void> _separateMaterial(WarehouseOrder order, int materialIndex) async {
    final material = order.materials[materialIndex];
    if (material.shortage > 0) {
      _showSnack('Material sem saldo suficiente. A OP fica aguardando compra ou reposicao.', Colors.orange);
      return;
    }
    if (!await _confirmPin('Separar ${material.code} na ${order.opNumber}')) return;

    final updatedMaterials = order.materials.asMap().entries.map((entry) {
      if (entry.key != materialIndex) return entry.value;
      return entry.value.copyWith(separatedQty: entry.value.requiredQty);
    }).toList();
    final updated = order.copyWith(
      materials: updatedMaterials,
      status: updatedMaterials.every((m) => m.separatedQty >= m.requiredQty)
          ? WarehouseOrderStatus.ready
          : WarehouseOrderStatus.partial,
      events: [
        WarehouseEvent(label: '${material.code} separado', user: widget.user.name, at: DateTime.now()),
        ...order.events,
      ],
    );
    _upsertOrder(updated);
  }

  Future<void> _releaseOrder(WarehouseOrder order, String destination) async {
    if (order.hasShortage) {
      _showSnack('Esta OP tem falta de material e nao pode ser liberada.', Colors.orange);
      return;
    }
    if (!order.isFullySeparated) {
      _showSnack('Separe todos os itens antes de liberar a OP.', Colors.orange);
      return;
    }
    if (!await _confirmPin('Liberar ${order.opNumber} para $destination')) return;

    _upsertOrder(order.copyWith(
      destination: destination,
      status: destination == 'SMD' ? WarehouseOrderStatus.releasedSmd : WarehouseOrderStatus.releasedProduction,
      events: [
        WarehouseEvent(label: 'Liberada para $destination', user: widget.user.name, at: DateTime.now()),
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
        title: const Text('Almoxarifado'),
        actions: [
          IconButton(
            tooltip: 'Criar OP',
            icon: const Icon(Icons.add_box_outlined),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => CreateOPScreen(user: widget.user)),
            ),
          ),
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
                SizedBox(
                  width: 520,
                  child: _buildQueue(isDesktop: true),
                ),
                const VerticalDivider(width: 1),
                Expanded(child: _buildDetail(_selectedOrder, isDesktop: true)),
              ],
            );
          }

          return _buildMobile();
        },
      ),
    );
  }

  Widget _buildMobile() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 24),
      children: [
        _buildMobileHeader(),
        const SizedBox(height: 12),
        _buildFilters(),
        const SizedBox(height: 12),
        ..._filteredOrders.map((order) => _MobileOrderCard(
              order: order,
              statusLabel: _statusLabel(order.status),
              statusColor: _statusColor(order.status),
              onTap: () => _openMobileDetail(order),
            )),
      ],
    );
  }

  Widget _buildMobileHeader() {
    final blocked = _orders.where((o) => o.status == WarehouseOrderStatus.blocked).length;
    final ready = _orders.where((o) => o.status == WarehouseOrderStatus.ready).length;
    return Card(
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                _VettiWordmark(),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Separacao de OP', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
                      SizedBox(height: 2),
                      Text('Fila simples para uso no celular', style: TextStyle(color: kVettiGrayDk, fontSize: 12)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(child: _TinyMetric(label: 'Prontas', value: ready.toString(), color: Colors.green)),
                const SizedBox(width: 8),
                Expanded(child: _TinyMetric(label: 'Faltas', value: blocked.toString(), color: Colors.orange)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openMobileDetail(WarehouseOrder order) async {
    setState(() => _selectedId = order.id);
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: kVettiBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (sheetContext) {
        final currentOrder = _orders.firstWhere((item) => item.id == order.id, orElse: () => order);
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.82,
          minChildSize: 0.42,
          maxChildSize: 0.94,
          builder: (_, scrollController) {
            return ListView(
              controller: scrollController,
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
              children: [
                Center(
                  child: Container(
                    width: 42,
                    height: 4,
                    decoration: BoxDecoration(
                      color: kVettiGray,
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                _buildMobileDetailSummary(currentOrder),
                const SizedBox(height: 14),
                _buildMobilePrimaryActions(sheetContext, currentOrder),
                if (currentOrder.blockedReason != null) ...[
                  const SizedBox(height: 12),
                  _WarningBox(message: currentOrder.blockedReason!),
                ],
                const SizedBox(height: 18),
                const Text('Separacao', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                const SizedBox(height: 8),
                ...currentOrder.materials.asMap().entries.map((entry) {
                  return _MobileMaterialRow(
                    material: entry.value,
                    onSeparate: () async {
                      await _separateMaterial(currentOrder, entry.key);
                      if (sheetContext.mounted) Navigator.pop(sheetContext);
                    },
                  );
                }),
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

  Widget _buildMobileDetailSummary(WarehouseOrder order) {
    return Card(
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.all(14),
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
            Text(
              '${order.productCode} - ${order.productName}',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w700, color: kVettiBlue),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: _InfoBadge(label: 'Qtd', value: '${order.quantity} un')),
                const SizedBox(width: 8),
                Expanded(child: _InfoBadge(label: 'Destino', value: order.destination)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMobilePrimaryActions(BuildContext sheetContext, WarehouseOrder order) {
    final canStart = order.status == WarehouseOrderStatus.waiting;
    final canRelease = order.isFullySeparated && !order.hasShortage && order.status == WarehouseOrderStatus.ready;

    Future<void> runAndClose(Future<void> Function() action) async {
      await action();
      if (sheetContext.mounted) Navigator.pop(sheetContext);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (canStart)
          FilledButton.icon(
            onPressed: () => runAndClose(() => _startSeparation(order)),
            icon: const Icon(Icons.play_arrow),
            label: const Text('INICIAR'),
          ),
        if (canRelease) ...[
          FilledButton.icon(
            onPressed: () => runAndClose(() => _releaseOrder(order, 'SMD')),
            icon: const Icon(Icons.precision_manufacturing_outlined),
            label: const Text('LIBERAR PARA SMD'),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: () => runAndClose(() => _releaseOrder(order, 'Producao')),
            icon: const Icon(Icons.factory_outlined),
            label: const Text('LIBERAR PARA PRODUCAO'),
          ),
        ],
      ],
    );
  }

  Widget _buildQueue({required bool isDesktop}) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildHeader(),
        const SizedBox(height: 16),
        _buildFilters(),
        const SizedBox(height: 12),
        ..._filteredOrders.map((order) => _OrderCard(
              order: order,
              selected: order.id == _selectedId,
              onTap: () => setState(() => _selectedId = order.id),
            )),
      ],
    );
  }

  Widget _buildHeader() {
    final waiting = _orders.where((o) => o.status == WarehouseOrderStatus.waiting).length;
    final blocked = _orders.where((o) => o.status == WarehouseOrderStatus.blocked).length;
    final ready = _orders.where((o) => o.status == WarehouseOrderStatus.ready).length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: kVettiBlue,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              const _VettiWordmark(onDark: true),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('VETTI Flow', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900)),
                    Text(widget.user.name, style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            _MetricChip(label: 'Aguardando', value: waiting.toString(), color: kVettiBlue),
            _MetricChip(label: 'Com falta', value: blocked.toString(), color: Colors.orange),
            _MetricChip(label: 'Prontas', value: ready.toString(), color: Colors.green),
          ],
        ),
      ],
    );
  }

  Widget _buildFilters() {
    final statuses = ['Todas', ...WarehouseOrderStatus.values.map(_statusLabel).toSet()];
    return Column(
      children: [
        TextField(
          controller: _searchCtrl,
          decoration: const InputDecoration(
            labelText: 'Buscar OP, codigo ou produto',
            prefixIcon: Icon(Icons.search),
          ),
        ),
        const SizedBox(height: 10),
        Align(
          alignment: Alignment.centerLeft,
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: statuses.map((status) {
              return ChoiceChip(
                label: Text(status, overflow: TextOverflow.ellipsis),
                selected: _statusFilter == status,
                onSelected: (_) => setState(() => _statusFilter = status),
                visualDensity: VisualDensity.compact,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildDetail(WarehouseOrder order, {required bool isDesktop}) {
    final canStart = order.status == WarehouseOrderStatus.waiting;
    final canRelease = order.isFullySeparated && !order.hasShortage && order.status == WarehouseOrderStatus.ready;

    return ListView(
      padding: EdgeInsets.all(isDesktop ? 24 : 0),
      shrinkWrap: !isDesktop,
      physics: isDesktop ? null : const NeverScrollableScrollPhysics(),
      children: [
        _DetailHeader(order: order),
        const SizedBox(height: 16),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            if (canStart)
              FilledButton.icon(
                onPressed: () => _startSeparation(order),
                icon: const Icon(Icons.play_arrow),
                label: const Text('INICIAR SEPARACAO'),
              ),
            if (canRelease) ...[
              FilledButton.icon(
                onPressed: () => _releaseOrder(order, 'SMD'),
                icon: const Icon(Icons.precision_manufacturing_outlined),
                label: const Text('LIBERAR SMD'),
              ),
              FilledButton.icon(
                onPressed: () => _releaseOrder(order, 'Producao'),
                icon: const Icon(Icons.factory_outlined),
                label: const Text('LIBERAR PRODUCAO'),
              ),
            ],
          ],
        ),
        if (order.blockedReason != null) ...[
          const SizedBox(height: 12),
          _WarningBox(message: order.blockedReason!),
        ],
        const SizedBox(height: 20),
        Text(
          'Materia-prima',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 8),
        isDesktop ? _buildMaterialsTable(order) : _buildMaterialsList(order),
        const SizedBox(height: 20),
        Text(
          'Historico',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 8),
        ...order.events.map((event) => _EventTile(event: event)),
      ],
    );
  }

  Widget _buildMaterialsList(WarehouseOrder order) {
    return Column(
      children: order.materials.asMap().entries.map((entry) {
        final material = entry.value;
        return _MaterialCard(
          material: material,
          onSeparate: () => _separateMaterial(order, entry.key),
        );
      }).toList(),
    );
  }

  Widget _buildMaterialsTable(WarehouseOrder order) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Card(
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          clipBehavior: Clip.antiAlias,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: ConstrainedBox(
              constraints: BoxConstraints(minWidth: constraints.maxWidth),
              child: DataTable(
                columnSpacing: 18,
                horizontalMargin: 18,
                headingRowHeight: 42,
                dataRowMinHeight: 44,
                dataRowMaxHeight: 52,
                headingTextStyle: const TextStyle(fontWeight: FontWeight.w800, color: kVettiGrayDk),
                columns: const [
                  DataColumn(label: Text('Codigo')),
                  DataColumn(label: Text('Descricao')),
                  DataColumn(label: Text('Nec.')),
                  DataColumn(label: Text('Saldo')),
                  DataColumn(label: Text('Sep.')),
                  DataColumn(label: Text('Lote')),
                  DataColumn(label: Text('Endereco')),
                  DataColumn(label: Text('Acao')),
                ],
                rows: order.materials.asMap().entries.map((entry) {
                  final material = entry.value;
                  final shortage = material.shortage > 0;
                  final done = material.separatedQty >= material.requiredQty;
                  return DataRow(
                    color: WidgetStatePropertyAll(
                      shortage ? Colors.orange.withValues(alpha: 0.08) : null,
                    ),
                    cells: [
                      DataCell(Text(material.code, style: const TextStyle(fontWeight: FontWeight.w800))),
                      DataCell(SizedBox(width: 260, child: Text(material.description, overflow: TextOverflow.ellipsis))),
                      DataCell(Text(_qty(material.requiredQty, material.unit))),
                      DataCell(Text(_qty(material.stockQty, material.unit), style: TextStyle(color: shortage ? Colors.orange : null, fontWeight: shortage ? FontWeight.w800 : null))),
                      DataCell(Text(_qty(material.separatedQty, material.unit))),
                      DataCell(Text(material.lot)),
                      DataCell(Text(material.address)),
                      DataCell(
                        IconButton(
                          tooltip: done ? 'Separado' : shortage ? 'Sem saldo' : 'Separar item',
                          onPressed: done || shortage ? null : () => _separateMaterial(order, entry.key),
                          icon: Icon(done ? Icons.check_circle : shortage ? Icons.warning_amber_rounded : Icons.inventory_2_outlined),
                          color: done ? Colors.green : shortage ? Colors.orange : kVettiBlue,
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
        );
      },
    );
  }

  String _qty(double value, String unit) {
    final formatted = value == value.roundToDouble() ? value.toInt().toString() : value.toStringAsFixed(2);
    return '$formatted $unit';
  }

  String _statusLabel(WarehouseOrderStatus status) {
    switch (status) {
      case WarehouseOrderStatus.waiting:
        return 'Aguardando';
      case WarehouseOrderStatus.separating:
        return 'Em separacao';
      case WarehouseOrderStatus.partial:
        return 'Parcial';
      case WarehouseOrderStatus.blocked:
        return 'Falta mat.';
      case WarehouseOrderStatus.ready:
        return 'Pronta';
      case WarehouseOrderStatus.releasedSmd:
        return 'Liberada SMD';
      case WarehouseOrderStatus.releasedProduction:
        return 'Liberada Producao';
    }
  }

  Color _statusColor(WarehouseOrderStatus status) {
    switch (status) {
      case WarehouseOrderStatus.blocked:
        return Colors.orange;
      case WarehouseOrderStatus.ready:
      case WarehouseOrderStatus.releasedSmd:
      case WarehouseOrderStatus.releasedProduction:
        return Colors.green;
      case WarehouseOrderStatus.partial:
      case WarehouseOrderStatus.separating:
        return kVettiBlue;
      case WarehouseOrderStatus.waiting:
        return kVettiGrayDk;
    }
  }

  List<WarehouseOrder> _mockOrders() {
    // Dados demonstrativos locais. A proxima etapa e substituir esta origem por Postgres/Protheus.
    final now = DateTime.now();
    return [
      WarehouseOrder(
        id: '1',
        opNumber: 'OP-550-001',
        productCode: '105-141',
        productName: 'Central Vetti Smart',
        quantity: 5000,
        destination: 'SMD',
        highPriority: true,
        status: WarehouseOrderStatus.waiting,
        events: [
          WarehouseEvent(label: 'OP criada no VETTI Flow', user: 'Vera (Almoxarifado)', at: now.subtract(const Duration(minutes: 42))),
        ],
        materials: const [
          WarehouseMaterial(
            code: 'PCB-VS-01',
            description: 'Placa circuito central smart',
            unit: 'un',
            requiredQty: 5000,
            stockQty: 6800,
            separatedQty: 0,
            warehouse: 'Almoxarifado',
            lot: 'L2406-A',
            address: 'A01-R03-N02',
          ),
          WarehouseMaterial(
            code: 'IC-ESP32',
            description: 'Modulo ESP32 homologado',
            unit: 'un',
            requiredQty: 5000,
            stockQty: 5200,
            separatedQty: 0,
            warehouse: 'Almoxarifado',
            lot: 'L2405-C',
            address: 'A02-R01-N04',
          ),
          WarehouseMaterial(
            code: 'CON-8V',
            description: 'Conector borne 8 vias',
            unit: 'un',
            requiredQty: 10000,
            stockQty: 8300,
            separatedQty: 0,
            warehouse: 'Almoxarifado',
            lot: 'L2404-B',
            address: 'A03-R02-N01',
          ),
        ],
      ),
      WarehouseOrder(
        id: '2',
        opNumber: 'OP-550-002',
        productCode: '220-018',
        productName: 'Controle 4 Botoes',
        quantity: 1500,
        destination: 'Producao',
        highPriority: false,
        status: WarehouseOrderStatus.partial,
        events: [
          WarehouseEvent(label: 'RES-10K separado', user: 'Vera (Almoxarifado)', at: now.subtract(const Duration(minutes: 20))),
          WarehouseEvent(label: 'Separacao iniciada', user: 'Vera (Almoxarifado)', at: now.subtract(const Duration(minutes: 28))),
        ],
        materials: const [
          WarehouseMaterial(
            code: 'RES-10K',
            description: 'Resistor 10k 0603',
            unit: 'un',
            requiredQty: 1500,
            stockQty: 7000,
            separatedQty: 1500,
            warehouse: 'Almoxarifado',
            lot: 'L2406-R',
            address: 'B01-R01-N01',
          ),
          WarehouseMaterial(
            code: 'CASE-4B',
            description: 'Gabinete controle 4 botoes',
            unit: 'un',
            requiredQty: 1500,
            stockQty: 2100,
            separatedQty: 0,
            warehouse: 'Almoxarifado',
            lot: 'L2406-G',
            address: 'C02-R04-N03',
          ),
        ],
      ),
      WarehouseOrder(
        id: '3',
        opNumber: 'OP-550-003',
        productCode: '330-070',
        productName: 'Sensor Shox',
        quantity: 3000,
        destination: 'SMD',
        highPriority: false,
        status: WarehouseOrderStatus.blocked,
        blockedReason: 'Aguardando compra ou reposicao de CAP-100U',
        events: [
          WarehouseEvent(label: 'Falta de saldo em CAP-100U identificada', user: 'Vera (Almoxarifado)', at: now.subtract(const Duration(hours: 1))),
        ],
        materials: const [
          WarehouseMaterial(
            code: 'CAP-100U',
            description: 'Capacitor eletrolitico 100uF',
            unit: 'un',
            requiredQty: 3000,
            stockQty: 1200,
            separatedQty: 0,
            warehouse: 'Almoxarifado',
            lot: 'L2403-E',
            address: 'B03-R02-N04',
          ),
          WarehouseMaterial(
            code: 'SENSOR-SHX',
            description: 'Elemento sensor shox',
            unit: 'un',
            requiredQty: 3000,
            stockQty: 3600,
            separatedQty: 0,
            warehouse: 'Almoxarifado',
            lot: 'L2405-S',
            address: 'A04-R01-N05',
          ),
        ],
      ),
    ];
  }
}

class _OrderCard extends StatelessWidget {
  final WarehouseOrder order;
  final bool selected;
  final VoidCallback onTap;

  const _OrderCard({
    required this.order,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final state = context.findAncestorStateOfType<_AlmoxarifadoScreenState>()!;
    final color = state._statusColor(order.status);
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: selected ? kVettiBlue : Colors.transparent, width: 1.5),
      ),
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
                  Expanded(
                    child: Text(order.opNumber, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                  ),
                  if (order.highPriority)
                    const Padding(
                      padding: EdgeInsets.only(right: 6),
                      child: Icon(Icons.priority_high, color: Colors.orange, size: 18),
                    ),
                  _StatusPill(label: state._statusLabel(order.status), color: color),
                ],
              ),
              const SizedBox(height: 6),
              Text('${order.productCode} - ${order.productName}', overflow: TextOverflow.ellipsis),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(child: Text('${order.quantity} un', style: const TextStyle(color: kVettiGrayDk))),
                  Text('${order.separatedLines}/${order.materials.length} itens', style: const TextStyle(fontWeight: FontWeight.w700)),
                ],
              ),
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: order.materials.isEmpty ? 0 : order.separatedLines / order.materials.length,
                minHeight: 5,
                backgroundColor: kVettiGray,
                valueColor: AlwaysStoppedAnimation(color),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MobileOrderCard extends StatelessWidget {
  final WarehouseOrder order;
  final String statusLabel;
  final Color statusColor;
  final VoidCallback onTap;

  const _MobileOrderCard({
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
                  Expanded(
                    child: Text(order.opNumber, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900)),
                  ),
                  _StatusPill(label: statusLabel, color: statusColor),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                order.productName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Icon(Icons.inventory_2_outlined, size: 16, color: order.hasShortage ? Colors.orange : kVettiGrayDk),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      order.hasShortage ? 'Falta material' : '${order.separatedLines}/${order.materials.length} itens separados',
                      style: TextStyle(
                        color: order.hasShortage ? Colors.orange : kVettiGrayDk,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  Text('${order.quantity} un', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 12)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MobileMaterialRow extends StatelessWidget {
  final WarehouseMaterial material;
  final VoidCallback onSeparate;

  const _MobileMaterialRow({
    required this.material,
    required this.onSeparate,
  });

  @override
  Widget build(BuildContext context) {
    final shortage = material.shortage > 0;
    final done = material.separatedQty >= material.requiredQty;
    final color = shortage ? Colors.orange : done ? Colors.green : kVettiBlue;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: color.withValues(alpha: 0.12),
              foregroundColor: color,
              child: Icon(done ? Icons.check : shortage ? Icons.warning_amber_rounded : Icons.inventory_2_outlined, size: 20),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(material.code, style: const TextStyle(fontWeight: FontWeight.w900)),
                  const SizedBox(height: 2),
                  Text(
                    shortage
                        ? 'Falta ${material.shortage.toInt()} ${material.unit}'
                        : '${material.requiredQty.toInt()} ${material.unit} | ${material.address}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: shortage ? Colors.orange : kVettiGrayDk, fontSize: 12),
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: done ? 'Separado' : 'Separar',
              onPressed: done ? null : onSeparate,
              icon: Icon(done ? Icons.check_circle : Icons.chevron_right),
              color: color,
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailHeader extends StatelessWidget {
  final WarehouseOrder order;

  const _DetailHeader({required this.order});

  @override
  Widget build(BuildContext context) {
    final state = context.findAncestorStateOfType<_AlmoxarifadoScreenState>()!;
    return Card(
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
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
                      Text(order.opNumber, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
                      const SizedBox(height: 4),
                      Text('${order.productCode} - ${order.productName}', style: const TextStyle(color: kVettiBlue, fontWeight: FontWeight.w800)),
                    ],
                  ),
                ),
                _StatusPill(
                  label: state._statusLabel(order.status),
                  color: state._statusColor(order.status),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _InfoBadge(label: 'Quantidade', value: '${order.quantity} un'),
                _InfoBadge(label: 'Destino', value: order.destination),
                _InfoBadge(label: 'Itens separados', value: '${order.separatedLines}/${order.materials.length}'),
                const _InfoBadge(label: 'Armazem origem', value: 'Almoxarifado'),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MaterialCard extends StatelessWidget {
  final WarehouseMaterial material;
  final VoidCallback onSeparate;

  const _MaterialCard({
    required this.material,
    required this.onSeparate,
  });

  @override
  Widget build(BuildContext context) {
    final shortage = material.shortage > 0;
    final done = material.separatedQty >= material.requiredQty;
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(child: Text(material.code, style: const TextStyle(fontWeight: FontWeight.w900))),
                IconButton(
                  tooltip: done ? 'Separado' : 'Separar',
                  onPressed: done ? null : onSeparate,
                  icon: Icon(done ? Icons.check_circle : Icons.inventory_2_outlined),
                  color: done ? Colors.green : kVettiBlue,
                ),
              ],
            ),
            Text(material.description),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _InfoBadge(label: 'Nec.', value: '${material.requiredQty.toInt()} ${material.unit}'),
                _InfoBadge(label: 'Saldo', value: '${material.stockQty.toInt()} ${material.unit}', color: shortage ? Colors.orange : null),
                _InfoBadge(label: 'Sep.', value: '${material.separatedQty.toInt()} ${material.unit}'),
                _InfoBadge(label: 'Lote', value: material.lot),
                _InfoBadge(label: 'Endereco', value: material.address),
              ],
            ),
            if (shortage) ...[
              const SizedBox(height: 10),
              _WarningBox(message: 'Falta ${material.shortage.toInt()} ${material.unit} para completar este item.'),
            ],
          ],
        ),
      ),
    );
  }
}

class _MetricChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _MetricChip({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 150,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: kVettiGray),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: color)),
          const SizedBox(width: 10),
          Expanded(child: Text(label, style: const TextStyle(fontSize: 12, color: kVettiGrayDk))),
        ],
      ),
    );
  }
}

class _TinyMetric extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _TinyMetric({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 58,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: color)),
          Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 10, color: color)),
        ],
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
      constraints: const BoxConstraints(maxWidth: 118),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(6),
        ),
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

class _WarningBox extends StatelessWidget {
  final String message;

  const _WarningBox({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.orange.withValues(alpha: 0.12),
        border: Border.all(color: Colors.orange.withValues(alpha: 0.35)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded, color: Colors.orange),
          const SizedBox(width: 10),
          Expanded(child: Text(message, style: const TextStyle(fontWeight: FontWeight.w700))),
        ],
      ),
    );
  }
}

class _EventTile extends StatelessWidget {
  final WarehouseEvent event;

  const _EventTile({required this.event});

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
  final bool onDark;

  const _VettiWordmark({
    this.onDark = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = onDark ? Colors.white : kVettiBlue;
    return Container(
      width: 72,
      height: 36,
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
          fontSize: 19,
          fontWeight: FontWeight.w900,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}
