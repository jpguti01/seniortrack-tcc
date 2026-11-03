import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'models/sessao_usuario.dart';
import 'providers/auth_provider.dart';
import 'screens/cuidador_home_screen.dart';
import 'screens/login_screen.dart';
import 'screens/paciente_home_screen.dart';
import 'theme/app_theme.dart';
import 'theme/app_brand.dart';

void main() {
  runApp(const TelemonitoramentoApp());
}

class TelemonitoramentoApp extends StatelessWidget {
  const TelemonitoramentoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AuthProvider(),
      child: MaterialApp(
        title: AppBrand.nome,
        debugShowCheckedModeBanner: false,
        theme: AppTheme.tema,
        home: const _RaizDaAplicacao(),
      ),
    );
  }
}

/// Decide qual tela mostrar de acordo com o estado de autenticação (RF02/RF03):
/// carregando -> splash; não autenticado -> login; autenticado -> home do
/// perfil correto (paciente ou cuidador).
class _RaizDaAplicacao extends StatefulWidget {
  const _RaizDaAplicacao();

  @override
  State<_RaizDaAplicacao> createState() => _RaizDaAplicacaoState();
}

class _RaizDaAplicacaoState extends State<_RaizDaAplicacao>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final auth = context.read<AuthProvider>();
    if (state == AppLifecycleState.paused &&
        auth.biometriaAtiva &&
        auth.status == StatusAuth.autenticado) {
      Navigator.of(context).popUntil((route) => route.isFirst);
      auth.bloquearSessao();
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    switch (auth.status) {
      case StatusAuth.carregando:
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      case StatusAuth.naoAutenticado:
      case StatusAuth.bloqueado:
        return const LoginScreen();
      case StatusAuth.autenticado:
        return auth.sessao!.tipo == TipoUsuario.paciente
            ? const PacienteHomeScreen()
            : const CuidadorHomeScreen();
    }
  }
}
