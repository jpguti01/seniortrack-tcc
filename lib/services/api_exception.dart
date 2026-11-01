/// Erro de API já traduzido para uma mensagem exibível ao usuário.
class ApiException implements Exception {
  final int statusCode;
  final String mensagem;

  ApiException(this.statusCode, this.mensagem);

  @override
  String toString() => mensagem;
}
