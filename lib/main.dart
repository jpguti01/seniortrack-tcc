import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'models/sessao_usuario.dart';
import 'providers/auth_provider.dart';
import 'screens/cuidador_home_screen.dart';
import 'screens/login_screen.dart';
import 'screens/paciente_home_screen.dart';
import 'theme/app_theme.dart';

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
        title: 'Telemonitoramento',
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
class _RaizDaAplicacao extends StatelessWidget {
  const _RaizDaAplicacao();

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    switch (auth.status) {
      case StatusAuth.carregando:
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      case StatusAuth.naoAutenticado:
        return const LoginScreen();
      case StatusAuth.autenticado:
        return auth.sessao!.tipo == TipoUsuario.paciente
            ? const PacienteHomeScreen()
            : const CuidadorHomeScreen();
    }
  }
}
