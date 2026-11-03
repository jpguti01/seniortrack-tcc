import 'tipo_sinal_vital.dart';

/// Espelha RegistroSinalVital do backend.
class SinalVital {
  final int id;
  final TipoSinalVital tipo;
  final double valor;
  final DateTime horaRegistro;

  SinalVital({
    required this.id,
    required this.tipo,
    required this.valor,
    required this.horaRegistro,
  });

  factory SinalVital.fromJson(Map<String, dynamic> json) {
    return SinalVital(
      id: json['id'] as int,
      tipo: TipoSinalVital.fromApi(json['tipoSinalVital'] as String),
      valor: (json['valorSinalVital'] as num).toDouble(),
      horaRegistro: DateTime.parse(json['horaRegistro'] as String),
    );
  }
}
