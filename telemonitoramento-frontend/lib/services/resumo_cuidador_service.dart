import '../models/chamado_sos.dart';
import '../models/paciente.dart';
import '../models/resumo_paciente.dart';
import '../models/alerta.dart';
import '../models/sinal_vital.dart';
import 'alerta_service.dart';
import 'api_exception.dart';
import 'paciente_service.dart';
import 'painel_cuidador_service.dart';
import 'sinal_vital_service.dart';

class ResumoCuidadorService {
  final PacienteService _pacientes;
  final SinalVitalService _sinais;
  final AlertaService _alertas;
  final PainelCuidadorService _painel;

  ResumoCuidadorService(
      {PacienteService? pacientes,
      SinalVitalService? sinais,
      AlertaService? alertas,
      PainelCuidadorService? painel})
      : _pacientes = pacientes ?? PacienteService(),
        _sinais = sinais ?? SinalVitalService(),
        _alertas = alertas ?? AlertaService(),
        _painel = painel ?? PainelCuidadorService();

  Future<T?> _consultar<T>(Future<T> consulta) async {
    try {
      return await consulta.timeout(const Duration(seconds: 12));
    } on ApiException catch (e) {
      if (e.statusCode == 401 || e.statusCode == 403) rethrow;
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<List<ResumoPaciente>> carregar() async {
    // O painel do dia é opcional: se falhar, os cards mostram só as medições.
    final consultaPainel = _consultar(_painel.carregar());
    final List<Paciente> pacientes;
    try {
      pacientes = await _pacientes
          .listarMeusPacientes()
          .timeout(const Duration(seconds: 12));
    } catch (_) {
      consultaPainel.ignore();
      rethrow;
    }
    final painel = {
      for (final item in await consultaPainel ?? <PainelPaciente>[])
        item.pacienteId: item
    };
    final resumos = <ResumoPaciente>[];
    // Limita as consultas simultâneas sem exigir um novo endpoint no backend.
    for (var i = 0; i < pacientes.length; i += 4) {
      final lote = pacientes.skip(i).take(4);
      resumos.addAll(await Future.wait(lote.map((paciente) async {
        final historico = _consultar(_sinais.listarPorPaciente(paciente.id));
        final alertas = _consultar(_alertas.listarPorPaciente(paciente.id));
        final resultados = await Future.wait([historico, alertas]);
        return ResumoPaciente(
          paciente: paciente,
          historico: resultados[0] as List<SinalVital>?,
          alertas: resultados[1] as List<Alerta>?,
          cuidados: painel[paciente.id],
        );
      })));
    }
    return resumos;
  }
}
