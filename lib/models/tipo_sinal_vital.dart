/// Espelha o enum RegistroSinalVital.TipoSinalVital do backend.
enum TipoSinalVital {
  pressaoArterial('PRESSAO_ARTERIAL', 'Pressão Arterial', 'mmHg'),
  glicemia('GLICEMIA', 'Glicemia', 'mg/dL'),
  peso('PESO', 'Peso', 'kg');

  const TipoSinalVital(this.valorApi, this.rotulo, this.unidade);

  final String valorApi;
  final String rotulo;
  final String unidade;

  static TipoSinalVital fromApi(String valor) {
    return TipoSinalVital.values.firstWhere(
      (t) => t.valorApi == valor,
      orElse: () => throw ArgumentError('Tipo de sinal vital desconhecido: $valor'),
    );
  }
}
