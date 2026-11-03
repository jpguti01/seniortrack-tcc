/// Número só com dígitos e com o código do Brasil (55) quando faltar, no
/// formato que o WhatsApp espera. Devolve null se o número estiver incompleto.
String? telefoneInternacional(String telefone) {
  var digitos = telefone.replaceAll(RegExp(r'\D'), '');
  if (digitos.startsWith('00')) {
    digitos = digitos.substring(2);
  } else if (digitos.startsWith('0')) {
    digitos = digitos.substring(1);
  }
  if (digitos.length == 10 || digitos.length == 11) digitos = '55$digitos';
  return digitos.length >= 12 && digitos.length <= 15 ? digitos : null;
}

/// Link que abre a conversa no WhatsApp (app ou web), já com a mensagem.
Uri? linkWhatsApp(String telefone, {String? mensagem}) {
  final numero = telefoneInternacional(telefone);
  if (numero == null) return null;
  return Uri.https(
      'wa.me', '/$numero', mensagem == null ? null : {'text': mensagem});
}
