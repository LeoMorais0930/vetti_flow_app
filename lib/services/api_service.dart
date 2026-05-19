import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/models.dart';

class ApiService {
  static ApiService? _instance;
  static ApiService get instance => _instance ??= ApiService._();
  ApiService._();

  // IP configurável pelo gestor na tela de Settings
  static const _defaultBase = 'http://10.36.0.75:5000';

  Future<String> get _base async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('server_ip') ?? _defaultBase;
  }

  Future<String> get _deviceId async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('device_id') ?? 'gestor-01';
  }

  Future<Map<String, String>> get _headers async => {
        'Content-Type': 'application/json',
        'X-Device-Id': await _deviceId,
      };

  // ── Blueprints ─────────────────────────────────────────────────────────────

  Future<List<Blueprint>> getBlueprints() async {
    final url = '${await _base}/api/blueprints';
    try {
      final res = await http.get(
        Uri.parse(url),
        headers: await _headers,
      ).timeout(const Duration(seconds: 5)); // Timeout de 5 segundos
      
      if (res.statusCode != 200) throw Exception('Erro ao buscar produtos (${res.statusCode})');
      final list = jsonDecode(res.body) as List;
      return list.map((j) => Blueprint.fromJson(j)).toList();
    } catch (e) {
      print('Erro API getBlueprints em $url: $e');
      rethrow;
    }
  }

  Future<void> createBlueprint({
    required String code,
    required String name,
    required int defaultBatchSize,
    required List<String> stages,
  }) async {
    final res = await http.post(
      Uri.parse('${await _base}/api/blueprints'),
      headers: await _headers,
      body: jsonEncode({
        'code': code,
        'name': name,
        'defaultBatchSize': defaultBatchSize,
        'stages': stages,
      }),
    );
    if (res.statusCode != 201) throw Exception('Erro ao criar produto');
  }

  Future<void> updateBlueprint(int id, {
    required String name,
    required int defaultBatchSize,
  }) async {
    final res = await http.put(
      Uri.parse('${await _base}/api/blueprints/$id'),
      headers: await _headers,
      body: jsonEncode({
        'name': name,
        'defaultBatchSize': defaultBatchSize,
      }),
    );
    if (res.statusCode != 200) throw Exception('Erro ao editar produto');
  }

  Future<void> deleteBlueprint(int id) async {
    final res = await http.delete(
      Uri.parse('${await _base}/api/blueprints/$id'),
      headers: await _headers,
    );
    if (res.statusCode != 204) throw Exception('Erro ao excluir produto');
  }

  // ── Orders ─────────────────────────────────────────────────────────────────

  Future<List<ProductionOrder>> getActiveOrders() async {
    final url = '${await _base}/api/orders';
    try {
      final res = await http.get(
        Uri.parse(url),
        headers: await _headers,
      ).timeout(const Duration(seconds: 5)); // Timeout de 5 segundos
      
      if (res.statusCode != 200) throw Exception('Erro ao buscar pedidos (${res.statusCode})');
      final list = jsonDecode(res.body) as List;
      return list.map((j) => ProductionOrder.fromJson(j)).toList();
    } catch (e) {
      print('Erro API getActiveOrders em $url: $e');
      rethrow;
    }
  }

  Future<ProductionOrder> createOrder({
    required int blueprintId,
    required String label,
    required int totalQty,
    required bool isHighPriority,
    String componentCodes = '',
    List<Map<String, dynamic>>? components,
  }) async {
    final res = await http.post(
      Uri.parse('${await _base}/api/orders'),
      headers: await _headers,
      body: jsonEncode({
        'blueprintId': blueprintId,
        'label': label,
        'totalQty': totalQty,
        'isHighPriority': isHighPriority,
        'componentCodes': componentCodes,
        'components': components,
      }),
    );
    if (res.statusCode != 201) throw Exception('Erro ao criar pedido');
    return ProductionOrder.fromJson(jsonDecode(res.body));
  }

  Future<void> updateOrder(int id, {
    required String label,
    required int totalQty,
    required bool isHighPriority,
    List<Map<String, dynamic>>? components,
  }) async {
    final res = await http.put(
      Uri.parse('${await _base}/api/orders/$id'),
      headers: await _headers,
      body: jsonEncode({
        'label': label,
        'totalQty': totalQty,
        'isHighPriority': isHighPriority,
        'components': components,
      }),
    );
    if (res.statusCode != 200) throw Exception('Erro ao editar pedido');
  }

  Future<void> deleteOrder(int id) async {
    final res = await http.delete(
      Uri.parse('${await _base}/api/orders/$id'),
      headers: await _headers,
    );
    if (res.statusCode != 204) throw Exception('Erro ao excluir pedido');
  }

  Future<void> advanceStage(int orderId, {int? componentIndex}) async {
    final queryParams = componentIndex != null ? '?componentIndex=$componentIndex' : '';
    final res = await http.post(
      Uri.parse('${await _base}/api/orders/$orderId/advance$queryParams'),
      headers: await _headers,
    );
    if (res.statusCode != 200) {
      final body = jsonDecode(res.body);
      throw Exception(body.toString());
    }
  }

  Future<void> deleteCompletedOrders() async {
    final res = await http.delete(
      Uri.parse('${await _base}/api/orders/completed'),
      headers: await _headers,
    );
    if (res.statusCode != 204) throw Exception('Erro ao limpar lotes finalizados');
  }

  // ── Settings ───────────────────────────────────────────────────────────────

  Future<void> saveSettings({String? serverIp, String? deviceId, String? sortBy}) async {
    final prefs = await SharedPreferences.getInstance();
    if (serverIp != null) {
      // Normalizar IP para garantir protocolo http://
      String normalizedIp = serverIp.trim();
      if (normalizedIp.isNotEmpty && !normalizedIp.startsWith('http://') && !normalizedIp.startsWith('https://')) {
        normalizedIp = 'http://$normalizedIp';
      }
      
      await prefs.setString('server_ip', normalizedIp);
      
      // Atualizar histórico de IPs
      List<String> history = prefs.getStringList('server_ip_history') ?? [];
      history.remove(normalizedIp); // Remove se já existir para mover para o topo
      history.insert(0, normalizedIp);
      if (history.length > 5) history = history.sublist(0, 5); // Mantém apenas os 5 últimos
      await prefs.setStringList('server_ip_history', history);
    }
    if (deviceId != null) await prefs.setString('device_id', deviceId);
    if (sortBy != null) await prefs.setString('sort_by', sortBy);
  }

  Future<({String serverIp, String deviceId, String sortBy, List<String> ipHistory})> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    return (
      serverIp: prefs.getString('server_ip') ?? _defaultBase,
      deviceId: prefs.getString('device_id') ?? 'gestor-01',
      sortBy: prefs.getString('sort_by') ?? 'prioridade',
      ipHistory: prefs.getStringList('server_ip_history') ?? [],
    );
  }
}
