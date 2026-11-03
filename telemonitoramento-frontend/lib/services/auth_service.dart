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

  Future<SessaoUsuario> login(String email, String senha,
      {TipoUsuario? perfil}) async {
    final json = await _api.post(
      '/auth/login',
      corpo: {
        'email': email,
        'senha': senha,
        if (perfil != null) 'perfil': perfil.name.toUpperCase()
      },
      autenticado: false,
    );
    return _processarResposta(json);
  }

  Future<Map<String, bool>> opcoes() async {
    final json =
        await _api.get('/auth/opcoes').timeout(const Duration(seconds: 8));
    return {'codigo': json['codigo'] == true, 'google': json['google'] == true};
  }

  Future<String> solicitarCodigo(
      String telefone, TipoUsuario perfil, String canal,
      {bool recuperar = false}) async {
    final json =
        await _api.post('/auth/codigo/solicitar', autenticado: false, corpo: {
      'telefone': telefone,
      'perfil': perfil.name.toUpperCase(),
      'canal': canal,
      'finalidade': recuperar ? 'recuperacao' : 'login',
    });
    return json['desafio'] as String;
  }

  Future<SessaoUsuario> confirmarCodigo(String desafio, String codigo,
      {String? novaSenha}) async {
    final json = await _api.post(
      novaSenha == null ? '/auth/codigo/confirmar' : '/auth/senha/recuperar',
      autenticado: false,
      corpo: {
        'desafio': desafio,
        'codigo': codigo,
        if (novaSenha != null) 'novaSenha': novaSenha
      },
    );
    return _processarResposta(json);
  }

  Future<SessaoUsuario> google(String idToken, TipoUsuario perfil) async {
    final json = await _api.post('/auth/google',
        autenticado: false,
        corpo: {'idToken': idToken, 'perfil': perfil.name.toUpperCase()});
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
    String? codigoConvite,
  }) async {
    final json = await _api.post(
      '/auth/cadastro/cuidador',
      corpo: {
        'nome': nome,
        'email': email,
        'senha': senha,
        'idade': idade,
        'telefone': telefone,
        if (codigoConvite != null) 'codigoConvite': codigoConvite,
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

  Future<void> validarSessao() async {
    await _api.get('/sessao').timeout(const Duration(seconds: 10));
  }

  Future<void> logout() => _api.limparToken();
}
