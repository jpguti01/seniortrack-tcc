import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:telemonitoramento_app/models/alerta.dart';
import 'package:telemonitoramento_app/models/historico_paciente.dart';
import 'package:telemonitoramento_app/models/paciente.dart';
import 'package:telemonitoramento_app/models/sinal_vital.dart';
import 'package:telemonitoramento_app/models/tipo_sinal_vital.dart';
import 'package:telemonitoramento_app/services/relatorio_paciente_service.dart';
import 'package:telemonitoramento_app/utils/formatar_medicao.dart';

SinalVital registro(int id, DateTime data,
        [TipoSinalVital tipo = TipoSinalVital.peso]) =>
    SinalVital(id: id, tipo: tipo, valor: 72.5, horaRegistro: data);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final agora = DateTime(2026, 11, 1, 14);
  test('Resumo diário conta tipos distintos e exclui registros futuros', () {
    final historico = HistoricoPaciente([
      registro(1, DateTime(2026, 11, 1, 8)),
      registro(2, DateTime(2026, 11, 1, 9)),
      registro(3, DateTime(2026, 10, 31, 23), TipoSinalVital.glicemia),
      registro(4, DateTime(2026, 11, 1, 15), TipoSinalVital.pressaoArterial),
    ]);
    expect(historico.tiposHoje(agora), {TipoSinalVital.peso});
  });
  test('Filtro de sete dias inclui o início do dia e ordena por data', () {
    final historico = HistoricoPaciente([
      registro(1, DateTime(2026, 10, 25, 23, 59)),
      registro(2, DateTime(2026, 10, 26)),
      registro(3, DateTime(2026, 11, 1, 9)),
      registro(4, DateTime(2026, 11, 1, 15)),
    ]);
    expect(historico.filtrar(agora: agora, dias: 7).map((r) => r.id), [3, 2]);
    expect(
        historico.filtrar(agora: agora, dias: 30).map((r) => r.id), [3, 2, 1]);
    expect(historico.filtrar(agora: agora, tipo: TipoSinalVital.glicemia),
        isEmpty);
  });
  test('Valores não exibem zero decimal e preservam a vírgula decimal', () {
    expect(formatarMedicao(155), '155');
    expect(formatarMedicao(72.5), '72,5');
    expect(formatarMedicao(72.05), '72,05');
  });
  test('Filtro combina tipo, período e ordem cronológica', () {
    final historico = HistoricoPaciente([
      registro(1, DateTime(2026, 11, 1, 8), TipoSinalVital.glicemia),
      registro(2, DateTime(2026, 11, 1, 9)),
      registro(3, DateTime(2026, 11, 1, 10), TipoSinalVital.glicemia),
      registro(4, DateTime(2026, 10, 20), TipoSinalVital.glicemia),
    ]);
    expect(
        historico
            .filtrar(agora: agora, dias: 7, tipo: TipoSinalVital.glicemia)
            .map((r) => r.id),
        [3, 1]);
  });
  test('Alertas humanizam nomes e incluem a unidade sem duplicá-la', () {
    Alerta criar(String mensagem) => Alerta(
        id: 1,
        mensagem: mensagem,
        dataHora: agora,
        resolvido: false,
        tipoSinal: TipoSinalVital.pressaoArterial,
        valorSinal: 155);
    final alerta = criar(
        'PRESSAO_ARTERIAL fora da faixa configurada: valor medido 155,0 (faixa normal: 90,0 a 140,0)');
    expect(alerta.medicao, '155 mmHg');
    expect(alerta.mensagemLegivel,
        'Pressão Arterial fora da faixa configurada: valor medido 155 mmHg (faixa configurada: 90 a 140)');
    expect(criar('valor medido 155 mmHg').mensagemLegivel,
        'valor medido 155 mmHg');
  });
  test('Perfil usa apenas o contato do cuidador retornado pela API', () {
    final paciente = Paciente.fromJson({
      'id': 1,
      'nome': 'Paciente Teste',
      'email': 'teste@example.com',
      'idade': 72,
      'cuidador': {'nome': 'Cuidador Teste', 'telefone': '(11) 99999-0000'}
    });
    expect(paciente.cuidador!.telefone, '(11) 99999-0000');
    expect(
        Paciente(id: 2, nome: 'Sem vínculo', email: 'a@example.com', idade: 70)
            .cuidador,
        isNull);
  });
  test('Exportação gera um documento PDF válido com dados de teste', () async {
    final bytes = await RelatorioPacienteService().gerar(
        nome: 'Paciente Teste',
        periodo: 'Últimos 7 dias',
        registros: [registro(1, agora)],
        emitidoEm: agora);
    expect(String.fromCharCodes(bytes.take(5)), '%PDF-');
    await File('${Directory.systemTemp.path}/SeniorTrack-test-report.pdf')
        .writeAsBytes(bytes);
  });
}
