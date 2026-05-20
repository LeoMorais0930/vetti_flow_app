import 'package:flutter/material.dart';

class AlarmStatusScreen extends StatelessWidget {
  const AlarmStatusScreen({super.key});

  // Colors from HTML
  static const Color primaryBlue = Color(0xFF003A63);
  static const Color vettiBlue = Color(0xFF0076CB);
  static const Color bgColor = Color(0xFFF0F0F0);
  static const Color cardBg = Color(0xFFF9F9FA);
  static const Color innerCardBg = Color(0xFFDCE3EB);
  static const Color textDark = Color(0xFF2E2E2E);
  static const Color textLight = Color(0xFFF0F0F0);
  static const Color successGreen = Color(0xFF339D57);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: const Text('Status do Sistema'),
        backgroundColor: vettiBlue,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: () {}),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 16),
            _buildPartitionsCard(),
            const SizedBox(height: 16),
            _buildMetricsGrid(),
            const SizedBox(height: 16),
            _buildInfoCard(),
            const SizedBox(height: 16),
            _buildScanList(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Nome da central',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: textDark),
        ),
        const Text(
          'SmartAlarm M4 - V1.0',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: textDark),
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: innerCardBg,
            borderRadius: BorderRadius.circular(4),
          ),
          child: const Text(
            'MAC: FF-FF-FF-FF-FF-FF',
            style: TextStyle(fontSize: 14, fontFamily: 'Courier', fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }

  Widget _buildPartitionsCard() {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          _buildCardHeader('Partições'),
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              children: [
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 3,
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
                  childAspectRatio: 0.85,
                  children: [
                    _buildPartitionItem('Partição 1', 'DESARMADO', true),
                    _buildPartitionItem('Partição 2', 'Não utilizada', false),
                    _buildPartitionItem('Partição 3', 'Não utilizada', false),
                    _buildPartitionItem('Partição 4', 'Não utilizada', false),
                    _buildPartitionItem('Partição 5', 'Não utilizada', false),
                    _buildPartitionItem('Partição 6', 'Não utilizada', false),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildActionButton(Icons.lock, 'Arme Total'),
                    _buildActionButton(Icons.home_outlined, 'Arme Stay'),
                    _buildActionButton(Icons.lock_open, 'Desarme'),
                    _buildActionButton(Icons.warning_amber_rounded, 'Pânico', isAlert: true),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPartitionItem(String title, String status, bool isActive) {
    return Container(
      decoration: BoxDecoration(
        color: innerCardBg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: isActive ? vettiBlue : Colors.transparent, width: 2),
      ),
      padding: const EdgeInsets.all(4),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
          const Spacer(),
          Text(
            status,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: status == 'DESARMADO' ? successGreen : textDark,
            ),
          ),
          const SizedBox(height: 4),
        ],
      ),
    );
  }

  Widget _buildActionButton(IconData icon, String label, {bool isAlert = false}) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        CircleAvatar(
          backgroundColor: isAlert ? Colors.red.shade900 : primaryBlue,
          radius: 24,
          child: Icon(icon, color: Colors.white, size: 24),
        ),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildMetricsGrid() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 2.2,
      children: [
        _buildMetricItem('Tensão fonte', '12 Vcc'),
        _buildMetricItem('Tensão bateria', '12 Vcc'),
        _buildMetricItem('Tamper central', 'Violado', isWarning: true),
        _buildMetricItem('Sirene com fio', 'Ausente'),
      ],
    );
  }

  Widget _buildMetricItem(String title, String value, {bool isWarning = false}) {
    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
            color: primaryBlue,
            child: Text(
              title,
              style: const TextStyle(color: textLight, fontSize: 10, fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: Container(
              color: innerCardBg,
              alignment: Alignment.center,
              child: Text(
                value,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isWarning ? Colors.red.shade700 : textDark,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard() {
    return Column(
      children: [
        Card(
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              _buildCardHeader('Painel de Alarme'),
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: Row(
                  children: [
                    Expanded(child: _buildValueBox('Data', '30/12/2026')),
                    const SizedBox(width: 12),
                    Expanded(child: _buildValueBox('Hora', '00:00:00')),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Card(
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              _buildCardHeader('Conexão com servidor'),
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  children: [
                    _buildStatusRow('Status:', 'Conectado via ethernet'),
                    _buildStatusRow('Modem GPRS:', 'Não instalado'),
                    _buildStatusRow('Modem WiFi:', 'Não instalado'),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildValueBox(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: innerCardBg,
            borderRadius: BorderRadius.circular(8),
          ),
          alignment: Alignment.center,
          child: Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }

  Widget _buildStatusRow(String label, String status) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(width: 8),
          Expanded(child: Text(status)),
        ],
      ),
    );
  }

  Widget _buildScanList() {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          _buildCardHeader('Scan'),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: 4,
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final items = [
                {'name': 'Presença LR (001)', 'zone': '001', 'status': 'Ok', 'rssi': '108'},
                {'name': 'Sirene SF (002)', 'zone': '002', 'status': 'Ok', 'rssi': '115'},
                {'name': 'Abertura Shox (003)', 'zone': '003', 'status': 'Violado', 'rssi': '95'},
                {'name': 'Controle 4T (005)', 'zone': '005', 'status': 'Ausente', 'rssi': '100'},
              ];
              final item = items[index];
              final isWarning = item['status'] == 'Violado';
              final isAbsent = item['status'] == 'Ausente';

              return ListTile(
                tileColor: isAbsent ? Colors.red.shade100 : (index % 2 == 0 ? Colors.white : Colors.grey.shade50),
                title: Text(item['name']!, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                subtitle: Text('Zona: ${item['zone']} | RSSI: ${item['rssi']}'),
                trailing: Text(
                  item['status']!,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isWarning || isAbsent ? Colors.red : successGreen,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCardHeader(String title) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      color: primaryBlue,
      child: Text(
        title,
        style: const TextStyle(color: textLight, fontSize: 16, fontWeight: FontWeight.bold),
      ),
    );
  }
}
