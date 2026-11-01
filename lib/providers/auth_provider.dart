import 'package:flutter/foundation.dart';

import '../models/sessao_usuario.dart';
import '../services/auth_service.dart';

enum StatusAuth { carregando, autenticado, naoAutenticado }

/// Mantém a sessão atual (ou a falta dela) visível para toda a árvore de
/// widgets, e decide qual fluxo de telas mostrar (login vs. paciente vs. cuidador).
class AuthProvider extends ChangeNotifier {
  final _authService = AuthService();

  StatusAuth status = StatusAuth.carregando;
  SessaoUsuario? sessao;

  AuthProvider() {
    _restaurarSessao();
  }

  Future<void> _restaurarSessao() async {
    // A sessão salva é reaberta otimisticamente; se o token estiver expirado,
    // a primeira chamada à API devolve 401/403 e a tela trata isso chamando
    // logout() e voltando para a tela de login.
    sessao = await _authService.restaurarSessao();
    status = sessao != null ? StatusAuth.autenticado : StatusAuth.naoAutenticado;
    notifyListeners();
  }

  Future<void> login(String email, String senha) async {
    sessao = await _authService.login(email, senha);
    status = StatusAuth.autenticado;
    notifyListeners();
  }

  Future<void> cadastrarPaciente({
    required String nome,
    required String email,
    required String senha,
    required int idade,
    required String telefone,
  }) async {
    sessao = await _authService.cadastrarPaciente(
      nome: nome,
      email: email,
      senha: senha,
      idade: idade,
      telefone: telefone,
    );
    status = StatusAuth.autenticado;
    notifyListeners();
  }

  Future<void> cadastrarCuidador({
    required String nome,
    required String email,
    required String senha,
    required int idade,
    required String telefone,
  }) async {
    sessao = await _authService.cadastrarCuidador(
      nome: nome,
      email: email,
      senha: senha,
      idade: idade,
      telefone: telefone,
    );
    status = StatusAuth.autenticado;
    notifyListeners();
  }

  Future<void> logout() async {
    await _authService.logout();
    sessao = null;
    status = StatusAuth.naoAutenticado;
    notifyListeners();
  }
}
