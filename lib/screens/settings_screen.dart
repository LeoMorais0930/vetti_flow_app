import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/signalr_service.dart';
import '../theme.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _ipCtrl     = TextEditingController();
  final _deviceCtrl = TextEditingController();
  String _sortBy    = 'prioridade';
  List<String> _ipHistory = [];
  bool _saving = false;

  final List<({String name, String ip})> _presets = [
    (name: 'Casa', ip: 'http://192.168.0.18:5000'),
    (name: 'Escritório (Atual)', ip: 'http://10.36.0.75:5000'),
    (name: 'Emulador', ip: 'http://10.0.2.2:5000'),
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _ipCtrl.dispose();
    _deviceCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final s = await ApiService.instance.loadSettings();
    setState(() {
      _ipCtrl.text     = s.serverIp;
      _deviceCtrl.text = s.deviceId;
      _sortBy          = s.sortBy;
      _ipHistory       = s.ipHistory;
    });
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    await ApiService.instance.saveSettings(
      serverIp: _ipCtrl.text.trim(),
      deviceId: _deviceCtrl.text.trim(),
      sortBy: _sortBy,
    );
    
    // Notifica o SignalR para reconectar se o IP mudou
    await SignalRService.instance.reconnectWithNewIp();

    setState(() => _saving = false);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Configurações salvas'), backgroundColor: Colors.green),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Configurações')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text(
            'Servidor',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
          ),
          const SizedBox(height: 4),
          const Text(
            'IP do computador que roda o backend na rede Wi-Fi local.',
            style: TextStyle(color: kVettiGrayDk, fontSize: 13),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _ipCtrl,
            decoration: const InputDecoration(
              labelText: 'Endereço do servidor',
              hintText: 'http://192.168.1.50:5000',
              prefixIcon: Icon(Icons.dns_outlined),
            ),
            keyboardType: TextInputType.url,
            autocorrect: false,
          ),
          const SizedBox(height: 12),
          const Text(
            'Atalhos rápidos',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: kVettiGrayDk),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: _presets.map((p) => ActionChip(
              label: Text(p.name),
              onPressed: () => setState(() => _ipCtrl.text = p.ip),
              backgroundColor: kVettiGray,
              labelStyle: const TextStyle(fontSize: 12),
              padding: EdgeInsets.zero,
            )).toList(),
          ),
          if (_ipHistory.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Text(
              'Histórico recente',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: kVettiGrayDk),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: _ipHistory.where((ip) => !_presets.any((p) => p.ip == ip)).map((ip) => ActionChip(
                label: Text(ip.replaceFirst('http://', '').replaceFirst(':5000', '')),
                onPressed: () => setState(() => _ipCtrl.text = ip),
                backgroundColor: Colors.white,
                labelStyle: const TextStyle(fontSize: 12),
                padding: EdgeInsets.zero,
              )).toList(),
            ),
          ],
          const SizedBox(height: 28),
          const Text(
            'Este dispositivo',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
          ),
          const SizedBox(height: 4),
          const Text(
            'Nome que aparecerá no log de auditoria ao avançar etapas.',
            style: TextStyle(color: kVettiGrayDk, fontSize: 13),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _deviceCtrl,
            decoration: const InputDecoration(
              labelText: 'Identificador do dispositivo',
              hintText: 'Ex: gestor-joao, tablet-producao',
              prefixIcon: Icon(Icons.phone_android_outlined),
            ),
          ),
          const SizedBox(height: 28),
          const Text(
            'Visualização',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
          ),
          const SizedBox(height: 4),
          const Text(
            'Defina como as ordens em curso devem ser ordenadas.',
            style: TextStyle(color: kVettiGrayDk, fontSize: 13),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: _sortBy,
            decoration: const InputDecoration(
              labelText: 'Ordenar por',
              prefixIcon: Icon(Icons.sort_outlined),
            ),
            items: const [
              DropdownMenuItem(value: 'prioridade', child: Text('Prioridade (Alta primeiro)')),
              DropdownMenuItem(value: 'data', child: Text('Data de Criação (Novos primeiro)')),
            ],
            onChanged: (val) {
              if (val != null) setState(() => _sortBy = val);
            },
          ),
          const SizedBox(height: 36),
          FilledButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(
                    width: 22, height: 22,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                  )
                : const Text('SALVAR'),
          ),
        ],
      ),
    );
  }
}
