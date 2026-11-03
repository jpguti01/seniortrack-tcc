import 'package:flutter/material.dart';

/// Espelha o enum RegistroSinalVital.TipoSinalVital do backend.
/// Cada tipo tem sua própria cor de identidade - não decoração, mas uma forma
/// de diferenciar as 3 categorias de medição à primeira vista, inclusive para
/// quem tem dificuldade de leitura de texto pequeno (RNF02).
enum TipoSinalVital {
  pressaoArterial('PRESSAO_ARTERIAL', 'Pressão Arterial', 'mmHg', Color(0xFF9D4335), Icons.speed_rounded),
  glicemia('GLICEMIA', 'Glicemia', 'mg/dL', Color(0xFF875300), Icons.water_drop_rounded),
  peso('PESO', 'Peso', 'kg', Color(0xFF3F7D6E), Icons.monitor_weight_rounded);

  const TipoSinalVital(this.valorApi, this.rotulo, this.unidade, this.cor, this.icone);

  final String valorApi;
  final String rotulo;
  final String unidade;
  final Color cor;
  final IconData icone;

  static TipoSinalVital fromApi(String valor) {
    return TipoSinalVital.values.firstWhere(
      (t) => t.valorApi == valor,
      orElse: () => throw ArgumentError('Tipo de sinal vital desconhecido: $valor'),
    );
  }
}
