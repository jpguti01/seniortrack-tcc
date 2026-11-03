import 'package:flutter/material.dart';

/// Espelha CheckinBemEstar.Humor do backend. "Com dor" e "Mal" avisam o
/// cuidador.
enum Humor {
  otimo('OTIMO', 'Ótimo', Icons.sentiment_very_satisfied_rounded,
      Color(0xFF3F7D6E)),
  bem('BEM', 'Bem', Icons.sentiment_satisfied_rounded, Color(0xFF0F5C53)),
  comDor('COM_DOR', 'Com dor', Icons.healing_rounded, Color(0xFF875300)),
  mal('MAL', 'Mal', Icons.sentiment_very_dissatisfied_rounded,
      Color(0xFFB5433A));

  const Humor(this.valorApi, this.rotulo, this.icone, this.cor);
  final String valorApi;
  final String rotulo;
  final IconData icone;
  final Color cor;

  bool get preocupante => this == comDor || this == mal;

  static Humor fromApi(String valor) =>
      values.firstWhere((h) => h.valorApi == valor, orElse: () => bem);
}

/// Check-in diário de bem-estar (um por dia; responder de novo substitui).
class CheckinBemEstar {
  final int id;
  final DateTime data;
  final Humor humor;
  final String? observacao;
  final DateTime registradoEm;

  CheckinBemEstar({
    required this.id,
    required this.data,
    required this.humor,
    this.observacao,
    required this.registradoEm,
  });

  bool eDoDia(DateTime dia) =>
      data.year == dia.year && data.month == dia.month && data.day == dia.day;

  factory CheckinBemEstar.fromJson(Map<String, dynamic> json) =>
      CheckinBemEstar(
        id: json['id'] as int,
        data: DateTime.parse(json['data'] as String),
        humor: Humor.fromApi(json['humor'] as String),
        observacao: json['observacao'] as String?,
        registradoEm: DateTime.parse(json['registradoEm'] as String),
      );
}
