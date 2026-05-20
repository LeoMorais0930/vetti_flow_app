import '../models/figma_models.dart';

class AuthService {
  static final List<FigmaUser> _users = [
    const FigmaUser(id: 'vera', name: 'Vera (Almoxarifado)', username: 'vera', role: FigmaRole.almoxarifado, pin: '8888'),
    const FigmaUser(id: 'paula', name: 'Paula (SMD)', username: 'paula', role: FigmaRole.smd, pin: '1234'),
    const FigmaUser(id: 'carlos', name: 'Carlos (Gravação)', username: 'carlos', role: FigmaRole.gravacao, pin: '2222'),
    const FigmaUser(id: 'ana', name: 'Ana (Soldagem)', username: 'ana', role: FigmaRole.soldagem, pin: '3333'),
    const FigmaUser(id: 'joao', name: 'Joao (Teste)', username: 'joao', role: FigmaRole.teste, pin: '4444'),
    const FigmaUser(id: 'maria', name: 'Maria (Embalagem)', username: 'maria', role: FigmaRole.embalagem, pin: '5555'),
    const FigmaUser(id: 'pedro', name: 'Pedro (Expedição)', username: 'pedro', role: FigmaRole.expedicao, pin: '6666'),
    const FigmaUser(id: 'lucas', name: 'Lucas (Suporte)', username: 'lucas', role: FigmaRole.suporte, pin: '7777'),
  ];

  static FigmaUser? login(String username, String password) {
    if (password != 'vetti2026') return null;
    try {
      return _users.firstWhere((u) => u.username.toLowerCase() == username.toLowerCase());
    } catch (_) {
      return null;
    }
  }
}
