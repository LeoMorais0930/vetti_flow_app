import 'package:shared_preferences/shared_preferences.dart';
import 'package:signalr_netcore/signalr_client.dart';
import '../models/models.dart';

typedef RefreshCallback = void Function();
typedef OrderUpdateCallback = void Function(ProductionOrder order);

class SignalRService {
  static SignalRService? _instance;
  static SignalRService get instance => _instance ??= SignalRService._();
  SignalRService._();

  HubConnection? _hub;
  bool _connected = false;

  final List<RefreshCallback> _refreshListeners = [];
  final List<OrderUpdateCallback> _orderListeners = [];

  void addRefreshListener(RefreshCallback cb) => _refreshListeners.add(cb);
  void removeRefreshListener(RefreshCallback cb) => _refreshListeners.remove(cb);

  void addListener(OrderUpdateCallback cb) => _orderListeners.add(cb);
  void removeListener(OrderUpdateCallback cb) => _orderListeners.remove(cb);

  Future<void> connect() async {
    if (_hub?.state == HubConnectionState.Connected) return;

    final prefs = await SharedPreferences.getInstance();
    final base  = prefs.getString('server_ip') ?? 'http://10.36.0.85:5000';

    _hub = HubConnectionBuilder()
        .withUrl('$base/hubs/production', options: HttpConnectionOptions(
          skipNegotiation: true,
          transport: HttpTransportType.WebSockets,
        ))
        .withAutomaticReconnect()
        .build();

    // Configurações de timeout robustas
    _hub!.serverTimeoutInMilliseconds = 60000;
    _hub!.keepAliveIntervalInMilliseconds = 15000;

    // ESCUTA ÚNICA E SIMPLIFICADA
    _hub!.on('RefreshAll', (args) {
      print('SignalR: RefreshAll recebido');
      for (final cb in _refreshListeners) {
        cb();
      }
    });

    _hub!.on('OrderUpdated', (args) {
      print('SignalR: OrderUpdated recebido');
      if (args != null && args.isNotEmpty) {
        try {
          final data = args[0] as Map<String, dynamic>;
          final order = ProductionOrder.fromSignalR(data);
          for (final cb in _orderListeners) {
            cb(order);
          }
        } catch (e) {
          print('SignalR Erro ao processar OrderUpdated: $e');
        }
      }
    });

    _hub!.onreconnected(({connectionId}) {
      _connected = true;
      for (final cb in _refreshListeners) cb(); // Refresh ao voltar
    });

    _hub!.onclose(({error}) => _connected = false);

    try {
      await _hub!.start();
      _connected = true;
      print('SignalR: Conectado');
    } catch (e) {
      print('SignalR Erro: $e');
      _connected = false;
      Future.delayed(const Duration(seconds: 10), connect);
    }
  }

  bool get isConnected => _connected && _hub?.state == HubConnectionState.Connected;
}
