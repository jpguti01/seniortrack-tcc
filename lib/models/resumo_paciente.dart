import 'alerta.dart';
import 'chamado_sos.dart';
import 'paciente.dart';
import 'sinal_vital.dart';
import 'tipo_sinal_vital.dart';

enum StatusMonitoramento {
  comAlertas('Com alertas'),
  semAlertas('Sem alertas'),
  semMedicoes('Sem medições'),
  indisponivel('Dados incompletos');

  const StatusMonitoramento(this.rotulo);
  final String rotulo;
}

/// Null distingue uma consulta que falhou de uma lista realmente vazia.
class ResumoPaciente {
  final Paciente paciente;
  final List<SinalVital>? historico;
  final List<Alerta>? alertas;

  /// SOS, remédios e bem-estar de hoje; null se o painel não pôde ser consultado.
  final PainelPaciente? cuidados;

  const ResumoPaciente(
      {required this.paciente, this.historico, this.alertas, this.cuidados});

  // Críticos primeiro; dentro da mesma gravidade, os mais recentes.
  List<Alerta> get pendentes =>
      (alertas ?? []).where((a) => !a.resolvido).toList()
        ..sort((a, b) {
          if (a.critico != b.critico) return a.critico ? -1 : 1;
          return b.dataHora.compareTo(a.dataHora);
        });

  bool get temCritico => pendentes.any((a) => a.critico);

  bool get pediuAjuda => cuidados?.sosPendentes.isNotEmpty ?? false;

  /// Ordem de atenção no painel do cuidador: SOS, alerta crítico, mais alertas.
  int get prioridade =>
      (pediuAjuda ? 10000 : 0) + (temCritico ? 1000 : 0) + pendentes.length;

  StatusMonitoramento get status {
    if (pendentes.isNotEmpty) return StatusMonitoramento.comAlertas;
    if (historico == null || alertas == null) {
      return StatusMonitoramento.indisponivel;
    }
    if (historico!.isEmpty) return StatusMonitoramento.semMedicoes;
    return StatusMonitoramento.semAlertas;
  }

  SinalVital? ultimo([TipoSinalVital? tipo]) {
    SinalVital? resultado;
    for (final sinal in historico ?? <SinalVital>[]) {
      if (tipo != null && sinal.tipo != tipo) continue;
      if (resultado == null ||
          sinal.horaRegistro.isAfter(resultado.horaRegistro)) {
        resultado = sinal;
      }
    }
    return resultado;
  }

  // Só conta ausência de medição se o histórico pôde ser consultado.
  bool semMedicaoRecente(DateTime agora) {
    if (historico == null) return false;
    final sinal = ultimo();
    return sinal == null ||
        sinal.horaRegistro.isBefore(agora.subtract(const Duration(hours: 24)));
  }

  List<SinalVital> ultimas24Horas(TipoSinalVital tipo, DateTime agora) =>
      (historico ?? <SinalVital>[])
          .where((s) =>
              s.tipo == tipo &&
              !s.horaRegistro
                  .isBefore(agora.subtract(const Duration(hours: 24))) &&
              !s.horaRegistro.isAfter(agora))
          .toList()
        ..sort((a, b) => a.horaRegistro.compareTo(b.horaRegistro));
}
