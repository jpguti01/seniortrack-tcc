import 'bem_estar.dart';

/// Pedido de ajuda (botão SOS) feito pelo paciente.
class ChamadoSos {
  final int id;
  final int pacienteId;
  final String pacienteNome;
  final DateTime criadoEm;
  final bool atendido;
  final DateTime? atendidoEm;

  ChamadoSos({
    required this.id,
    required this.pacienteId,
    required this.pacienteNome,
    required this.criadoEm,
    required this.atendido,
    this.atendidoEm,
  });

  factory ChamadoSos.fromJson(Map<String, dynamic> json) => ChamadoSos(
        id: json['id'] as int,
        pacienteId: json['pacienteId'] as int,
        pacienteNome: json['pacienteNome'] as String,
        criadoEm: DateTime.parse(json['criadoEm'] as String),
        atendido: json['atendido'] as bool,
        atendidoEm: json['atendidoEm'] == null
            ? null
            : DateTime.parse(json['atendidoEm'] as String),
      );
}

/// Pendências do dia de um paciente (GET /cuidador/painel): SOS em aberto,
/// doses sem confirmação e o check-in de bem-estar de hoje.
class PainelPaciente {
  final int pacienteId;
  final List<ChamadoSos> sosPendentes;
  final int dosesAtrasadasHoje;
  final int dosesPrevistasHoje;
  final CheckinBemEstar? checkinHoje;

  PainelPaciente({
    required this.pacienteId,
    this.sosPendentes = const [],
    this.dosesAtrasadasHoje = 0,
    this.dosesPrevistasHoje = 0,
    this.checkinHoje,
  });

  factory PainelPaciente.fromJson(Map<String, dynamic> json) => PainelPaciente(
        pacienteId: json['pacienteId'] as int,
        sosPendentes: (json['sosPendentes'] as List)
            .map((e) => ChamadoSos.fromJson(e as Map<String, dynamic>))
            .toList(),
        dosesAtrasadasHoje: json['dosesAtrasadasHoje'] as int,
        dosesPrevistasHoje: json['dosesPrevistasHoje'] as int,
        checkinHoje: json['checkinHoje'] == null
            ? null
            : CheckinBemEstar.fromJson(
                json['checkinHoje'] as Map<String, dynamic>),
      );
}
