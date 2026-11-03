import 'tipo_sinal_vital.dart';
import '../utils/formatar_medicao.dart';

/// Espelha o enum Gravidade do backend. Alertas criados antes da
/// classificação chegam sem gravidade e são tratados como atenção.
enum GravidadeAlerta {
  atencao('ATENCAO', 'Atenção'),
  critico('CRITICO', 'Crítico');

  const GravidadeAlerta(this.valorApi, this.rotulo);
  final String valorApi;
  final String rotulo;

  static GravidadeAlerta fromApi(String? valor) =>
      valor == critico.valorApi ? critico : atencao;
}

/// Espelha Alerta do backend, incluindo os dados do sinal vital que o originou.
class Alerta {
  final int id;
  final String mensagem;
  final DateTime dataHora;
  final bool resolvido;
  final TipoSinalVital tipoSinal;
  final double valorSinal;
  final GravidadeAlerta gravidade;

  /// O mesmo sinal também ficou fora da faixa no dia anterior.
  final bool persistente;

  Alerta({
    required this.id,
    required this.mensagem,
    required this.dataHora,
    required this.resolvido,
    required this.tipoSinal,
    required this.valorSinal,
    this.gravidade = GravidadeAlerta.atencao,
    this.persistente = false,
  });

  bool get critico => gravidade == GravidadeAlerta.critico;

  String get titulo => 'Alerta de ${tipoSinal.rotulo}';
  String get medicao => '${formatarMedicao(valorSinal)} ${tipoSinal.unidade}';

  String get mensagemLegivel {
    var texto = mensagem;
    for (final tipo in TipoSinalVital.values) {
      texto = texto.replaceAll(tipo.valorApi, tipo.rotulo);
    }
    texto = texto.replaceAll('faixa normal:', 'faixa configurada:');
    texto = texto.replaceAllMapped(RegExp(r'(-?\d+)[.,]0\b'), (m) => m[1]!);
    texto = texto.replaceAllMapped(
        RegExp(r'(valor medido\s+)(-?\d+(?:[.,]\d+)?)(?![\d.,])',
            caseSensitive: false),
        (m) => texto.substring(m.end).trimLeft().startsWith(tipoSinal.unidade)
            ? m[0]!
            : '${m[1]}${m[2]} ${tipoSinal.unidade}');
    return texto;
  }

  factory Alerta.fromJson(Map<String, dynamic> json) {
    final registro = json['registroSinalVital'] as Map<String, dynamic>;
    return Alerta(
      id: json['id'] as int,
      mensagem: json['mensagem'] as String,
      dataHora: DateTime.parse(json['dataHora'] as String),
      resolvido: json['resolvido'] as bool,
      tipoSinal: TipoSinalVital.fromApi(registro['tipoSinalVital'] as String),
      valorSinal: (registro['valorSinalVital'] as num).toDouble(),
      gravidade: GravidadeAlerta.fromApi(json['gravidade'] as String?),
      persistente: json['persistente'] == true,
    );
  }
}
