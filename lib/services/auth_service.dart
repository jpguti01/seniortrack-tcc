import 'dart:convert';

import '../models/sessao_usuario.dart';
import 'api_client.dart';

class AuthService {
  final _api = ApiClient.instancia;

  Future<SessaoUsuario> _processarResposta(dynamic json) async {
    final sessao = SessaoUsuario.fromJson(json as Map<String, dynamic>);
    await _api.salvarToken(sessao.token);
    await _api.salvarSessaoJson(jsonEncode(sessao.toJson()));
    return sessao;
  }

  Future<SessaoUsuario> login(String email, String senha) async {
    final json = await _api.post(
      '/auth/login',
      corpo: {'email': email, 'senha': senha},
      autenticado: false,
    );
    return _processarResposta(json);
  }

  Future<SessaoUsuario> cadastrarPaciente({
    required String nome,
    required String email,
    required String senha,
    required int idade,
    required String telefone,
  }) async {
    final json = await _api.post(
      '/auth/cadastro/paciente',
      corpo: {
        'nome': nome,
        'email': email,
        'senha': senha,
        'idade': idade,
        'telefone': telefone,
      },
      autenticado: false,
    );
    return _processarResposta(json);
  }

  Future<SessaoUsuario> cadastrarCuidador({
    required String nome,
    required String email,
    required String senha,
    required int idade,
    required String telefone,
  }) async {
    final json = await _api.post(
      '/auth/cadastro/cuidador',
      corpo: {
        'nome': nome,
        'email': email,
        'senha': senha,
        'idade': idade,
        'telefone': telefone,
      },
      autenticado: false,
    );
    return _processarResposta(json);
  }

  Future<SessaoUsuario?> restaurarSessao() async {
    final json = await _api.lerSessaoJson();
    if (json == null) return null;
    return SessaoUsuario.fromJson(jsonDecode(json) as Map<String, dynamic>);
  }

  Future<void> logout() => _api.limparToken();
}
