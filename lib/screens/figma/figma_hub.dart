import 'package:flutter/material.dart';
import '../../models/figma_models.dart';
import 'almoxarifado_screen.dart';
import 'smd_screen.dart'; // These will be created next
import 'teste_screen.dart';
import 'suporte_screen.dart';
import 'expedicao_screen.dart';
import 'generic_production_screen.dart';

class FigmaHub extends StatelessWidget {
  const FigmaHub({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Figma Workspace Hub'), backgroundColor: Colors.black87, foregroundColor: Colors.white),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _tile(context, 'Almoxarifado (Vera)', 'vera', '8888', FigmaRole.almoxarifado, Colors.blueGrey, Icons.inventory, (u) => AlmoxarifadoScreen(user: u, onLogout: () => Navigator.pop(context))),
          _tile(context, 'SMD (Paula)', 'paula', '1234', FigmaRole.smd, Colors.blue, Icons.memory, (u) => SMDScreen(user: u, onLogout: () => Navigator.pop(context))),
          _tile(context, 'Gravação (Carlos)', 'carlos', '2222', FigmaRole.gravacao, Colors.purple, Icons.code, (u) => GenericProductionScreen(user: u, stage: 'gravacao', onLogout: () => Navigator.pop(context))),
          _tile(context, 'Soldagem (Ana)', 'ana', '3333', FigmaRole.soldagem, Colors.orange, Icons.flash_on, (u) => GenericProductionScreen(user: u, stage: 'soldagem', onLogout: () => Navigator.pop(context))),
          _tile(context, 'Teste (Joao)', 'joao', '4444', FigmaRole.teste, Colors.lightBlue, Icons.fact_check, (u) => TesteScreen(user: u, onLogout: () => Navigator.pop(context))),
          _tile(context, 'Embalagem (Maria)', 'maria', '5555', FigmaRole.embalagem, Colors.green, Icons.inventory_2, (u) => GenericProductionScreen(user: u, stage: 'embalagem', onLogout: () => Navigator.pop(context))),
          _tile(context, 'Expedição (Pedro)', 'pedro', '6666', FigmaRole.expedicao, Colors.deepPurple, Icons.local_shipping, (u) => ExpedicaoScreen(user: u, onLogout: () => Navigator.pop(context))),
          _tile(context, 'Suporte (Lucas)', 'lucas', '7777', FigmaRole.suporte, Colors.red, Icons.build, (u) => SuporteScreen(user: u, onLogout: () => Navigator.pop(context))),
        ],
      ),
    );
  }

  Widget _tile(BuildContext context, String title, String user, String pin, FigmaRole role, Color color, IconData icon, Widget Function(FigmaUser) builder) {
    return Card(
      child: ListTile(
        leading: Icon(icon, color: color),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text('User: $user | PIN: $pin'),
        onTap: () {
          final u = FigmaUser(id: user, name: title, username: user, role: role, pin: pin);
          Navigator.push(context, MaterialPageRoute(builder: (_) => builder(u)));
        },
      ),
    );
  }
}
