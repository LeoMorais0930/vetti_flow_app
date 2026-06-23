import '../models/figma_models.dart';

class FigmaService {
  static final FigmaService _instance = FigmaService._internal();
  factory FigmaService() => _instance;
  FigmaService._internal();

  final List<FigmaOrder> _orders = [
    FigmaOrder(
      id: '1',
      opNumber: 'OP-550-001',
      productCode: 'CSA-5000',
      productName: 'Central Smart Alarm',
      totalQuantity: 5000,
      producedQuantity: 0,
      remainingQuantity: 5000,
      status: FigmaStatus.pending,
      createdBy: 'Vera Silva',
      createdAt: DateTime(2026, 5, 1, 8, 0),
      currentStage: 'almoxarifado',
      productionLogs: [],
    ),
    FigmaOrder(
      id: '2',
      opNumber: 'OP-550-002',
      productCode: 'SHOX-2000',
      productName: 'Sensor Shox',
      totalQuantity: 3000,
      producedQuantity: 0,
      remainingQuantity: 3000,
      status: FigmaStatus.pending,
      createdBy: 'Vera Silva',
      createdAt: DateTime(2026, 5, 10, 9, 30),
      currentStage: 'almoxarifado',
      productionLogs: [],
    ),
    FigmaOrder(
      id: 'test_order_1500',
      opNumber: 'OP-550-TEST',
      productCode: '550-999',
      productName: 'Controle 4 Botões',
      totalQuantity: 1500,
      producedQuantity: 0,
      remainingQuantity: 1500,
      status: FigmaStatus.pending,
      createdBy: 'Vera Silva',
      createdAt: DateTime.now(),
      currentStage: 'teste',
      productionLogs: [],
      lastSignature: 'Ana (Soldagem)',
      originStage: 'soldagem',
    ),
  ];

  final List<FigmaRequisition> _requisitions = [
    FigmaRequisition(
      id: '1',
      number: '1',
      status: RequisitionStatus.pending,
      requesterName: 'Paula (SMD)',
      originStage: 'smd',
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
      items: [
        const FigmaRequisitionItem(id: 'r1i1', code: 'RES-10K', description: 'Resistor 10k', requestedQuantity: 100),
        const FigmaRequisitionItem(id: 'r1i2', code: 'CAP-100U', description: 'Capacitor 100uF', requestedQuantity: 50),
      ],
    ),
  ];

  List<FigmaOrder> get orders => List.unmodifiable(_orders);
  List<FigmaRequisition> get requisitions => List.unmodifiable(_requisitions);

  void addOrder(FigmaOrder order) {
    _orders.add(order);
  }

  void updateOrder(FigmaOrder updatedOrder) {
    final index = _orders.indexWhere((o) => o.id == updatedOrder.id);
    if (index != -1) {
      _orders[index] = updatedOrder;
    }
  }

  void addRequisition(FigmaRequisition req) {
    _requisitions.add(req);
  }

  void updateRequisition(FigmaRequisition updatedReq) {
    final index = _requisitions.indexWhere((r) => r.id == updatedReq.id);
    if (index != -1) {
      _requisitions[index] = updatedReq;
    }
  }

  List<FigmaOrder> getOrdersByStage(String stage) {
    return _orders.where((o) => o.currentStage == stage).toList();
  }

  void removeOrder(String id) {
    _orders.removeWhere((o) => o.id == id);
  }
}
