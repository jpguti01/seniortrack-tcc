import 'tipo_sinal_vital.dart';

/// Espelha Alerta do backend, incluindo os dados do sinal vital que o originou.
class Alerta {
  final int id;
  final String mensagem;
  final DateTime dataHora;
  final bool resolvido;
  final TipoSinalVital tipoSinal;
  final double valorSinal;

  Alerta({
    required this.id,
    required this.mensagem,
    required this.dataHora,
    required this.resolvido,
    required this.tipoSinal,
    required this.valorSinal,
  });

  factory Alerta.fromJson(Map<String, dynamic> json) {
    final registro = json['registroSinalVital'] as Map<String, dynamic>;
    return Alerta(
      id: json['id'] as int,
      mensagem: json['mensagem'] as String,
      dataHora: DateTime.parse(json['dataHora'] as String),
      resolvido: json['resolvido'] as bool,
      tipoSinal: TipoSinalVital.fromApi(registro['tipoSinalVital'] as String),
      valorSinal: (registro['valorSinalVital'] as num).toDouble(),
    );
  }
}
