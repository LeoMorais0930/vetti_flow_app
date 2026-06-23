# VETTI Flow — App do Gestor

Aplicativo móvel desenvolvido em Flutter para controle e gestão do fluxo de produção em tempo real.

## 🚀 Funcionalidades
- **Gestão de Produtos**: Cadastro e edição de roteiros de produção (Blueprints).
- **Controle de Pedidos**: Criação, edição e avanço de etapas de produção.
- **Sincronização em Tempo Real**: Recebe atualizações via SignalR.
- **Alta Performance**: Otimizado para 90Hz/120Hz em dispositivos compatíveis.
- **PWA**: Instalável como aplicação web no Windows/Desktop.

## 🛠️ Configuração e Execução

### Pré-requisitos
- [Flutter SDK](https://docs.flutter.dev/get-started/install)

### Comandos Principais
```bash
# Obter dependências
flutter pub get

# Executar o projeto (Web/Chrome)
flutter run -d chrome

# Executar o projeto (Android)
flutter run -d android
```

## ⚙️ Configurações do Servidor
No primeiro acesso ou ao mudar de ambiente (Casa/Escritório), vá na tela de **Configurações** e utilize os atalhos rápidos de IP para conectar ao servidor local.

## 🍎 Desenvolvimento no Mac

O app Flutter já está configurado para usar a API da empresa em:

```text
http://10.36.0.4:5000
```

### Pré-requisitos no Mac

- Flutter SDK instalado
- Android Studio instalado
- Android SDK configurado pelo Android Studio
- Acesso à rede da empresa ou VPN enxergando o servidor `10.36.0.4`

### Primeiro uso

```bash
git clone https://github.com/LeoMorais0930/vetti_flow_app.git
cd vetti_flow_app
flutter doctor
flutter pub get
```

Antes de rodar o app, valide se o Mac acessa a API:

```bash
curl http://10.36.0.4:5000/api/orders
```

Se preferir testar pelo navegador:

```text
http://10.36.0.4:5000/swagger
```

### Rodando pelo Android Studio

1. Abra a pasta `vetti_flow_app` no Android Studio.
2. Selecione um emulador Android ou um celular conectado.
3. Rode o arquivo `lib/main.dart`.

### Rodando pelo terminal

```bash
flutter run -d android
```

Para testar web no Chrome:

```bash
flutter run -d chrome
```

Se o app abrir sem dados, verifique:

- se a API está rodando no servidor;
- se a porta `5000` está liberada no firewall;
- se o Mac está na VPN/rede da empresa;
- se a tela de Configurações do app continua apontando para `http://10.36.0.4:5000`.

---
Desenvolvido para **VETTI — Segurança e Tecnologia**.
