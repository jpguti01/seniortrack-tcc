import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:telemonitoramento_app/models/sessao_usuario.dart';
import 'package:telemonitoramento_app/providers/auth_provider.dart';
import 'package:telemonitoramento_app/screens/login_screen.dart';
import 'package:telemonitoramento_app/screens/cadastro_screen.dart';
import 'package:telemonitoramento_app/screens/acesso_codigo_screen.dart';
import 'auth_provider_test.dart' show AuthFake, BiometriaFake;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;
  late AuthProvider auth;

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
            const MethodChannel('flutter_tts'), (_) async => 1);
    auth = AuthProvider(authService: AuthFake(), biometria: BiometriaFake());
  });
  tearDown(() => auth.dispose());

  Future<void> abrir(WidgetTester tester, Widget tela,
      {Size size = const Size(390, 844)}) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(ChangeNotifierProvider.value(
        value: auth, child: MaterialApp(home: tela)));
    await tester.pumpAndSettle();
  }

  testWidgets(
      'Login troca o texto do perfil e mantém controles acessíveis em celular',
      (tester) async {
    await abrir(tester, LoginScreen(authService: AuthFake()));
    await tester.ensureVisible(find.text('Cuidador'));
    await tester.tap(find.text('Cuidador'));
    await tester.pumpAndSettle();
    expect(
        find.text(
            'Acesse para acompanhar a rotina dos seus familiares ou pacientes.'),
        findsOneWidget);
    await tester.ensureVisible(find.byTooltip('Aumentar letras'));
    await tester.tap(find.byTooltip('Aumentar letras'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    final campo = tester.element(find.byType(TextFormField).first);
    expect(MediaQuery.textScalerOf(campo).scale(16), 20);
  });

  testWidgets('Cadastro de cuidador recebe convite e não exige idade',
      (tester) async {
    await abrir(
        tester, const CadastroScreen(perfilInicial: TipoUsuario.cuidador));
    expect(find.text('Código de convite (opcional)'), findsOneWidget);
    expect(find.text('Idade'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Cadastro de paciente pede somente os dados básicos, sem convite',
      (tester) async {
    await abrir(tester, const CadastroScreen());
    expect(find.text('Idade'), findsOneWidget);
    expect(find.text('Código de convite (opcional)'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Tela de código oferece WhatsApp e SMS e valida celular',
      (tester) async {
    await abrir(
        tester,
        AcessoCodigoScreen(
            perfil: TipoUsuario.paciente, authService: AuthFake()));
    expect(find.text('WhatsApp'), findsOneWidget);
    expect(find.text('SMS'), findsOneWidget);
    await tester.ensureVisible(find.text('Enviar código'));
    await tester.tap(find.text('Enviar código'));
    await tester.pumpAndSettle();
    expect(find.text('Informe um celular com DDD.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Login sem formas externas disponíveis informa indisponibilidade',
      (tester) async {
    await abrir(tester, LoginScreen(authService: _SemOpcoes()));
    final codigo = tester.widget<OutlinedButton>(
        find.widgetWithText(OutlinedButton, 'Código por SMS ou WhatsApp'));
    expect(codigo.onPressed, isNull);
    expect(
        find.text('Algumas formas de acesso estão indisponíveis no momento.'),
        findsOneWidget);
  });
}

class _SemOpcoes extends AuthFake {
  @override
  Future<Map<String, bool>> opcoes() async =>
      {'codigo': false, 'google': false};
}
