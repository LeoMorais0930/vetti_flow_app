import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// O import está correto
import 'package:vetti_flow_app/main.dart';

void main() {
  testWidgets('Counter increments smoke test', (WidgetTester tester) async {
    // ALTERAÇÃO AQUI: Trocamos MyApp() por VettiFlowApp()
    await tester.pumpWidget(const VettiFlowApp());

    // O restante do teste pode falhar se você removeu o contador padrão do Flutter,
    // mas o erro de "class not found" vai sumir.
    expect(find.text('0'), findsOneWidget);
    expect(find.text('1'), findsNothing);

    await tester.tap(find.byIcon(Icons.add));
    await tester.pump();

    expect(find.text('0'), findsNothing);
    expect(find.text('1'), findsOneWidget);
  });
}