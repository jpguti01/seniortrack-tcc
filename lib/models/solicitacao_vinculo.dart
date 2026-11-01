/// Espelha SolicitacaoVinculoResponse do backend: um pedido de vínculo de um
/// cuidador, aguardando o paciente aceitar ou recusar (RF05).
class SolicitacaoVinculo {
  final int id;
  final int cuidadorId;
  final String cuidadorNome;
  final DateTime criadoEm;

  SolicitacaoVinculo({
    required this.id,
    required this.cuidadorId,
    required this.cuidadorNome,
    required this.criadoEm,
  });

  factory SolicitacaoVinculo.fromJson(Map<String, dynamic> json) {
    return SolicitacaoVinculo(
      id: json['id'] as int,
      cuidadorId: json['cuidadorId'] as int,
      cuidadorNome: json['cuidadorNome'] as String,
      criadoEm: DateTime.parse(json['criadoEm'] as String),
    );
  }
}
