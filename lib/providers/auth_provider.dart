import 'package:flutter/foundation.dart';

import '../models/sessao_usuario.dart';
import '../services/auth_service.dart';
import '../services/biometria_service.dart';
import '../services/api_client.dart';
import '../services/api_exception.dart';

enum StatusAuth { carregando, autenticado, naoAutenticado, bloqueado }

/// Mantém a sessão atual (ou a falta dela) visível para toda a árvore de
/// widgets, e decide qual fluxo de telas mostrar (login vs. paciente vs. cuidador).
class AuthProvider extends ChangeNotifier {
  final AuthService _authService;
  final BiometriaService _biometria;
  bool biometriaDisponivel = false;
  bool biometriaAtiva = false;
  SessaoUsuario? _sessaoBloqueada;
  bool _descartado = false;

  @override
  void notifyListeners() {
    if (!_descartado) super.notifyListeners();
  }

  @override
  void dispose() {
    _descartado = true;
    super.dispose();
  }

  StatusAuth status = StatusAuth.carregando;
  SessaoUsuario? sessao;

  AuthProvider({AuthService? authService, BiometriaService? biometria})
      : _authService = authService ?? AuthService(),
        _biometria = biometria ?? BiometriaService() {
    _restaurarSessao();
  }

  Future<void> _restaurarSessao() async {
    // A sessão salva é reaberta otimisticamente; se o token estiver expirado,
    // a primeira chamada à API devolve 401/403 e a tela trata isso chamando
    // logout() e voltando para a tela de login.
    try {
      biometriaDisponivel = await _biometria.disponivel();
      biometriaAtiva = await _biometria.habilitada();
      sessao = await _authService.restaurarSessao();
      status =
          sessao != null ? StatusAuth.autenticado : StatusAuth.naoAutenticado;
      if (sessao != null && biometriaAtiva) {
        _sessaoBloqueada = sessao;
        sessao = null;
        ApiClient.instancia.sessaoBloqueada = true;
        status = StatusAuth.bloqueado;
      }
    } catch (_) {
      sessao = null;
      status = StatusAuth.naoAutenticado;
    }
    notifyListeners();
  }

  Future<void> _concluirAcesso({bool usarBiometria = false}) async {
    biometriaAtiva = usarBiometria && await _biometria.autenticar();
    await _biometria.configurar(biometriaAtiva);
    _sessaoBloqueada = null;
    ApiClient.instancia.sessaoBloqueada = false;
    status = StatusAuth.autenticado;
    notifyListeners();
  }

  Future<void> login(String email, String senha,
      {bool usarBiometria = false, TipoUsuario? perfil}) async {
    sessao = await _authService.login(email, senha, perfil: perfil);
    await _concluirAcesso(usarBiometria: usarBiometria);
  }

  Future<void> entrarComGoogle(String idToken, TipoUsuario perfil,
      {bool usarBiometria = false}) async {
    sessao = await _authService.google(idToken, perfil);
    await _concluirAcesso(usarBiometria: usarBiometria);
  }

  Future<void> confirmarCodigo(String desafio, String codigo,
      {String? novaSenha, bool usarBiometria = false}) async {
    sessao = await _authService.confirmarCodigo(desafio, codigo,
        novaSenha: novaSenha);
    await _concluirAcesso(usarBiometria: usarBiometria);
  }

  void bloquearSessao() {
    if (!biometriaAtiva || status != StatusAuth.autenticado) return;
    _sessaoBloqueada = sessao;
    sessao = null;
    ApiClient.instancia.sessaoBloqueada = true;
    status = StatusAuth.bloqueado;
    notifyListeners();
  }

  Future<bool> desbloquearSessao() async {
    if (_sessaoBloqueada == null || !await _biometria.autenticar()) {
      return false;
    }
    ApiClient.instancia.sessaoBloqueada = false;
    try {
      await _authService.validarSessao();
      sessao = _sessaoBloqueada;
      _sessaoBloqueada = null;
      status = StatusAuth.autenticado;
      notifyListeners();
      return true;
    } catch (e) {
      ApiClient.instancia.sessaoBloqueada = true;
      if (e is ApiException && (e.statusCode == 401 || e.statusCode == 403)) {
        await logout();
      }
      rethrow;
    }
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
    await _concluirAcesso();
  }

  Future<void> cadastrarCuidador({
    required String nome,
    required String email,
    required String senha,
    required int idade,
    required String telefone,
    String? codigoConvite,
  }) async {
    sessao = await _authService.cadastrarCuidador(
      nome: nome,
      email: email,
      senha: senha,
      idade: idade,
      telefone: telefone,
      codigoConvite: codigoConvite,
    );
    await _concluirAcesso();
  }

  Future<void> logout() async {
    await _authService.logout();
    await _biometria.configurar(false);
    biometriaAtiva = false;
    _sessaoBloqueada = null;
    ApiClient.instancia.sessaoBloqueada = false;
    sessao = null;
    status = StatusAuth.naoAutenticado;
    notifyListeners();
  }
}
