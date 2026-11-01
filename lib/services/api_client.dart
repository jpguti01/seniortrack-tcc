import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

import 'api_exception.dart';

/// Wrapper fino sobre o pacote http: injeta o token JWT, resolve a URL base
/// e converte respostas de erro do backend (GlobalExceptionHandler) em
/// ApiException com uma mensagem pronta para mostrar na tela.
///
/// A URL base pode ser trocada em tempo de build, sem mudar o código:
///   flutter run -d chrome --dart-define=API_BASE_URL=http://localhost:8080
class ApiClient {
  ApiClient._();
  static final ApiClient instancia = ApiClient._();

  static const String _baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:8080',
  );

  final _armazenamento = const FlutterSecureStorage();
  static const _chaveToken = 'jwt_token';
  static const _chaveSessao = 'sessao_usuario';

  // Guarda o token (usado em todo header Authorization) e, separadamente, o
  // JSON da sessão inteira (nome/tipo/id), para poder restaurar a tela certa
  // quando o app reabre sem precisar logar de novo.
  Future<void> salvarToken(String token) =>
      _armazenamento.write(key: _chaveToken, value: token);

  Future<void> salvarSessaoJson(String json) =>
      _armazenamento.write(key: _chaveSessao, value: json);

  Future<String?> lerSessaoJson() => _armazenamento.read(key: _chaveSessao);

  Future<String?> lerToken() => _armazenamento.read(key: _chaveToken);

  Future<void> limparToken() async {
    await _armazenamento.delete(key: _chaveToken);
    await _armazenamento.delete(key: _chaveSessao);
  }

  Uri _uri(String caminho, [Map<String, String>? query]) {
    return Uri.parse('$_baseUrl$caminho').replace(queryParameters: query);
  }

  Future<Map<String, String>> _headers({bool autenticado = true}) async {
    final headers = {'Content-Type': 'application/json'};
    if (autenticado) {
      final token = await lerToken();
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }
    }
    return headers;
  }

  dynamic _tratarResposta(http.Response resposta) {
    if (resposta.statusCode >= 200 && resposta.statusCode < 300) {
      if (resposta.body.isEmpty) return null;
      return jsonDecode(utf8.decode(resposta.bodyBytes));
    }

    if (resposta.statusCode == 401 || resposta.statusCode == 403) {
      throw ApiException(resposta.statusCode,
          'Sessão expirada ou acesso não permitido. Faça login novamente.');
    }

    String mensagem = 'Erro inesperado (${resposta.statusCode}).';
    try {
      final corpo = jsonDecode(utf8.decode(resposta.bodyBytes));
      if (corpo is Map<String, dynamic>) {
        if (corpo.containsKey('erro')) {
          mensagem = corpo['erro'] as String;
        } else if (corpo.isNotEmpty) {
          // Erros de validação (@Valid): um mapa {campo: mensagem}.
          mensagem = corpo.values.map((v) => v.toString()).join('\n');
        }
      } else if (corpo is String) {
        mensagem = corpo;
      }
    } catch (_) {
      // Corpo não era JSON (ou estava vazio) - mantém a mensagem genérica.
    }
    throw ApiException(resposta.statusCode, mensagem);
  }

  Future<dynamic> get(String caminho, {Map<String, String>? query}) async {
    final resposta =
        await http.get(_uri(caminho, query), headers: await _headers());
    return _tratarResposta(resposta);
  }

  Future<dynamic> post(String caminho, {Object? corpo, bool autenticado = true}) async {
    final resposta = await http.post(
      _uri(caminho),
      headers: await _headers(autenticado: autenticado),
      body: corpo == null ? null : jsonEncode(corpo),
    );
    return _tratarResposta(resposta);
  }

  Future<dynamic> put(String caminho, {Object? corpo}) async {
    final resposta = await http.put(
      _uri(caminho),
      headers: await _headers(),
      body: corpo == null ? null : jsonEncode(corpo),
    );
    return _tratarResposta(resposta);
  }

  Future<dynamic> delete(String caminho) async {
    final resposta = await http.delete(_uri(caminho), headers: await _headers());
    return _tratarResposta(resposta);
  }
}
