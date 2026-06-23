import 'package:flutter/material.dart';
import '../../models/figma_models.dart';
import 'almoxarifado_screen.dart';
import 'expedicao_screen.dart';
import 'generic_production_screen.dart';
import 'smd_screen.dart';
import 'suporte_screen.dart';
import 'teste_screen.dart';

class FigmaHub extends StatelessWidget {
  const FigmaHub({super.key});

  static const _users = [
    FigmaUser(id: 'vera', name: 'Vera (Almoxarifado)', username: 'vera', role: FigmaRole.almoxarifado, pin: '8888'),
    FigmaUser(id: 'paula', name: 'Paula (SMD)', username: 'paula', role: FigmaRole.smd, pin: '1234'),
    FigmaUser(id: 'carlos', name: 'Carlos (Gravacao)', username: 'carlos', role: FigmaRole.gravacao, pin: '2222'),
    FigmaUser(id: 'ana', name: 'Ana (Soldagem)', username: 'ana', role: FigmaRole.soldagem, pin: '3333'),
    FigmaUser(id: 'joao', name: 'Joao (Teste)', username: 'joao', role: FigmaRole.teste, pin: '4444'),
    FigmaUser(id: 'maria', name: 'Maria (Embalagem)', username: 'maria', role: FigmaRole.embalagem, pin: '5555'),
    FigmaUser(id: 'pedro', name: 'Pedro (Expedicao)', username: 'pedro', role: FigmaRole.expedicao, pin: '6666'),
    FigmaUser(id: 'lucas', name: 'Lucas (Suporte)', username: 'lucas', role: FigmaRole.suporte, pin: '7777'),
  ];

  Widget _screenFor(FigmaUser user) {
    void logout(BuildContext context) => Navigator.pop(context);

    switch (user.role) {
      case FigmaRole.almoxarifado:
        return AlmoxarifadoScreen(user: user, onLogout: logout);
      case FigmaRole.smd:
        return SMDScreen(user: user, onLogout: logout);
      case FigmaRole.gravacao:
        return GenericProductionScreen(user: user, stage: 'gravacao', onLogout: logout);
      case FigmaRole.soldagem:
        return GenericProductionScreen(user: user, stage: 'soldagem', onLogout: logout);
      case FigmaRole.teste:
        return TesteScreen(user: user, onLogout: logout);
      case FigmaRole.embalagem:
        return GenericProductionScreen(user: user, stage: 'embalagem', onLogout: logout);
      case FigmaRole.expedicao:
        return ExpedicaoScreen(user: user, onLogout: logout);
      case FigmaRole.suporte:
        return SuporteScreen(user: user, onLogout: logout);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Figma Hub')),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _users.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          final user = _users[index];
          return Card(
            child: ListTile(
              leading: const Icon(Icons.person_outline),
              title: Text(user.name),
              subtitle: Text(user.username),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => _screenFor(user)),
              ),
            ),
          );
        },
      ),
    );
  }
}
