// Teste de fumaça: garante que o app sobe sem lançar exceção e mostra o
// indicador de carregamento inicial enquanto a sessão salva é restaurada.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:telemonitoramento_app/main.dart';

void main() {
  testWidgets('App inicializa sem erros e mostra tela de carregamento', (WidgetTester tester) async {
    await tester.pumpWidget(const TelemonitoramentoApp());

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });
}
