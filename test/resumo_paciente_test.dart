import 'package:flutter_test/flutter_test.dart';
import 'package:telemonitoramento_app/models/alerta.dart';
import 'package:telemonitoramento_app/models/paciente.dart';
import 'package:telemonitoramento_app/models/resumo_paciente.dart';
import 'package:telemonitoramento_app/models/sinal_vital.dart';
import 'package:telemonitoramento_app/models/tipo_sinal_vital.dart';
import 'package:telemonitoramento_app/services/alerta_service.dart';
import 'package:telemonitoramento_app/services/api_exception.dart';
import 'package:telemonitoramento_app/services/paciente_service.dart';
import 'package:telemonitoramento_app/services/resumo_cuidador_service.dart';
import 'package:telemonitoramento_app/services/sinal_vital_service.dart';

final paciente =
    Paciente(id: 1, nome: 'João', email: 'teste@example.com', idade: 72);
final agora = DateTime(2026, 11, 1, 15);
SinalVital sinal(int id, DateTime hora,
        {TipoSinalVital tipo = TipoSinalVital.peso}) =>
    SinalVital(id: id, tipo: tipo, valor: 72, horaRegistro: hora);
Alerta alerta(bool resolvido) => Alerta(
    id: 1,
    mensagem: 'Fora do limiar',
    dataHora: agora,
    resolvido: resolvido,
    tipoSinal: TipoSinalVital.peso,
    valorSinal: 72);

void main() {
  test('Falhas e ausência de medições não são classificadas como sem alertas',
      () {
    expect(ResumoPaciente(paciente: paciente).status,
        StatusMonitoramento.indisponivel);
    expect(
        ResumoPaciente(paciente: paciente, historico: [], alertas: []).status,
        StatusMonitoramento.semMedicoes);
    expect(
        ResumoPaciente(
            paciente: paciente,
            historico: [sinal(1, agora)],
            alertas: []).status,
        StatusMonitoramento.semAlertas);
  });

  test('Alertas pendentes têm prioridade, inclusive com histórico indisponível',
      () {
    final resumo = ResumoPaciente(
        paciente: paciente, alertas: [alerta(true), alerta(false)]);
    expect(resumo.pendentes.length, 1);
    expect(resumo.status, StatusMonitoramento.comAlertas);
  });

  test('Última medição é escolhida por data e por tipo, não pela ordem da API',
      () {
    final resumo = ResumoPaciente(paciente: paciente, historico: [
      sinal(2, agora),
      sinal(1, agora.subtract(const Duration(hours: 2))),
      sinal(3, agora.add(const Duration(minutes: 1)),
          tipo: TipoSinalVital.glicemia),
    ]);
    expect(resumo.ultimo()!.id, 3);
    expect(resumo.ultimo(TipoSinalVital.peso)!.id, 2);
    expect(resumo.ultimo(TipoSinalVital.pressaoArterial), isNull);
  });

  test('Indicador de ausência em 24 h exclui histórico desconhecido', () {
    expect(
        ResumoPaciente(paciente: paciente).semMedicaoRecente(agora), isFalse);
    expect(
        ResumoPaciente(paciente: paciente, historico: [])
            .semMedicaoRecente(agora),
        isTrue);
    expect(
        ResumoPaciente(paciente: paciente, historico: [
          sinal(1, agora.subtract(const Duration(hours: 24))),
        ]).semMedicaoRecente(agora),
        isFalse);
    expect(
        ResumoPaciente(paciente: paciente, historico: [
          sinal(1, agora.subtract(const Duration(hours: 25))),
        ]).semMedicaoRecente(agora),
        isTrue);
  });

  test('Gráfico separa tipos e exclui registros antigos e futuros', () {
    final resumo = ResumoPaciente(paciente: paciente, historico: [
      sinal(1, agora.subtract(const Duration(hours: 25))),
      sinal(3, agora),
      sinal(2, agora.subtract(const Duration(hours: 2))),
      sinal(4, agora.add(const Duration(hours: 1))),
      sinal(5, agora, tipo: TipoSinalVital.glicemia),
    ]);
    expect(resumo.ultimas24Horas(TipoSinalVital.peso, agora).map((s) => s.id),
        [2, 3]);
  });

  test('Falha em alertas preserva medições e marca consulta parcial', () async {
    final service = ResumoCuidadorService(
        pacientes: _Pacientes(),
        sinais: _Sinais(),
        alertas: _Alertas(ApiException(500, 'Indisponível')));
    final resumo = (await service.carregar()).single;
    expect(resumo.historico!.single.id, 1);
    expect(resumo.alertas, isNull);
    expect(resumo.status, StatusMonitoramento.indisponivel);
  });

  test('Falha de autorização não se transforma em lista vazia', () async {
    final service = ResumoCuidadorService(
        pacientes: _Pacientes(),
        sinais: _Sinais(),
        alertas: _Alertas(ApiException(403, 'Sem acesso')));
    await expectLater(service.carregar(), throwsA(isA<ApiException>()));
  });
}

class _Pacientes extends PacienteService {
  @override
  Future<List<Paciente>> listarMeusPacientes() async => [paciente];
}

class _Sinais extends SinalVitalService {
  @override
  Future<List<SinalVital>> listarPorPaciente(int pacienteId,
          {TipoSinalVital? tipo}) async =>
      [sinal(1, agora)];
}

class _Alertas extends AlertaService {
  final Exception erro;
  _Alertas(this.erro);
  @override
  Future<List<Alerta>> listarPorPaciente(int pacienteId) async => throw erro;
}
