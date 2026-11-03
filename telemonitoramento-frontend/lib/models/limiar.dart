import 'tipo_sinal_vital.dart';

/// Espelha LimiarSeguranca do backend.
class Limiar {
  final int id;
  final TipoSinalVital tipo;
  final double valorMinimo;
  final double valorMaximo;

  Limiar({
    required this.id,
    required this.tipo,
    required this.valorMinimo,
    required this.valorMaximo,
  });

  factory Limiar.fromJson(Map<String, dynamic> json) {
    return Limiar(
      id: json['id'] as int,
      tipo: TipoSinalVital.fromApi(json['tipoSinalVital'] as String),
      valorMinimo: (json['valorMin'] as num).toDouble(),
      valorMaximo: (json['valorMax'] as num).toDouble(),
    );
  }
}
