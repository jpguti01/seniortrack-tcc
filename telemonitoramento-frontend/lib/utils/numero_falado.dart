const _palavras = <String, int>{
  'zero': 0,
  'um': 1,
  'uma': 1,
  'dois': 2,
  'duas': 2,
  'tres': 3,
  'quatro': 4,
  'cinco': 5,
  'seis': 6,
  'sete': 7,
  'oito': 8,
  'nove': 9,
  'dez': 10,
  'onze': 11,
  'doze': 12,
  'treze': 13,
  'quatorze': 14,
  'catorze': 14,
  'quinze': 15,
  'dezesseis': 16,
  'dezasseis': 16,
  'dezessete': 17,
  'dezoito': 18,
  'dezenove': 19,
  'vinte': 20,
  'trinta': 30,
  'quarenta': 40,
  'cinquenta': 50,
  'sessenta': 60,
  'setenta': 70,
  'oitenta': 80,
  'noventa': 90,
  'cem': 100,
  'cento': 100,
  'duzentos': 200,
  'duzentas': 200,
  'trezentos': 300,
  'quatrocentos': 400,
  'quinhentos': 500,
  'seiscentos': 600,
  'setecentos': 700,
  'oitocentos': 800,
  'novecentos': 900,
};

String _semAcento(String texto) => texto
    .replaceAll(RegExp('[áàâã]'), 'a')
    .replaceAll(RegExp('[éê]'), 'e')
    .replaceAll('í', 'i')
    .replaceAll(RegExp('[óôõ]'), 'o')
    .replaceAll('ú', 'u')
    .replaceAll('ü', 'u');

/// Converte o que o paciente falou em um número: "130", "72,5", "cento e
/// trinta", "setenta e dois vírgula cinco" ou "setenta e dois e meio".
/// Usa o primeiro número da frase ("cento e vinte por oitenta" -> 120) e
/// devolve null se não houver nenhum.
double? extrairNumeroFalado(String texto) {
  final tokens = RegExp(r'\d+(?:[.,]\d+)?|[a-z]+')
      .allMatches(_semAcento(texto.toLowerCase()))
      .map((m) => m[0]!)
      .toList();

  int? inteiro;
  int? decimal;
  var casasDecimais = 0;
  var naParteDecimal = false;
  var parcial = 0;
  var temParcial = false;

  void fecharParte() {
    if (!temParcial) return;
    if (naParteDecimal) {
      decimal = parcial;
      casasDecimais = parcial.toString().length;
    } else {
      inteiro = (inteiro ?? 0) + parcial;
    }
    parcial = 0;
    temParcial = false;
  }

  for (final token in tokens) {
    final numerico = double.tryParse(token.replaceAll(',', '.'));
    if (numerico != null) {
      if (inteiro != null || temParcial) {
        if (!naParteDecimal) break;
        decimal = numerico.round();
        casasDecimais = token.length;
        break;
      }
      if (numerico != numerico.roundToDouble()) return numerico;
      parcial = numerico.round();
      temParcial = true;
      continue;
    }
    if (_palavras.containsKey(token)) {
      parcial += _palavras[token]!;
      temParcial = true;
    } else if (token == 'mil') {
      parcial = (temParcial ? parcial : 1) * 1000;
      temParcial = true;
    } else if (token == 'e' && (temParcial || inteiro != null)) {
      continue;
    } else if ((token == 'virgula' || token == 'ponto') && temParcial) {
      fecharParte();
      naParteDecimal = true;
    } else if (token == 'meio' && (temParcial || inteiro != null)) {
      fecharParte();
      return (inteiro ?? 0) + 0.5;
    } else if (temParcial || inteiro != null) {
      break;
    }
  }
  fecharParte();
  if (inteiro == null) return null;
  if (decimal == null) return inteiro!.toDouble();
  return inteiro! + decimal! / _potenciaDeDez(casasDecimais);
}

int _potenciaDeDez(int expoente) {
  var resultado = 1;
  for (var i = 0; i < expoente; i++) {
    resultado *= 10;
  }
  return resultado;
}
