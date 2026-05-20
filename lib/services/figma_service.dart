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
  ];

  List<FigmaOrder> get orders => List.unmodifiable(_orders);

  void addOrder(FigmaOrder order) {
    _orders.add(order);
  }

  void updateOrder(FigmaOrder updatedOrder) {
    final index = _orders.indexWhere((o) => o.id == updatedOrder.id);
    if (index != -1) {
      _orders[index] = updatedOrder;
    }
  }

  List<FigmaOrder> getOrdersByStage(String stage) {
    return _orders.where((o) => o.currentStage == stage).toList();
  }
}
