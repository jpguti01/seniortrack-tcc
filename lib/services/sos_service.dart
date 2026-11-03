import '../models/chamado_sos.dart';
import 'api_client.dart';

class SosService {
  final _api = ApiClient.instancia;

  // O paciente vem do token; toques repetidos em 2 minutos reaproveitam o
  // mesmo chamado no backend, sem avisar o cuidador de novo.
  Future<ChamadoSos> acionar() async {
    final json = await _api.post('/sos');
    return ChamadoSos.fromJson(json as Map<String, dynamic>);
  }

  Future<List<ChamadoSos>> listarPorPaciente(int pacienteId,
      {int dias = 30}) async {
    final json =
        await _api.get('/sos/paciente/$pacienteId', query: {'dias': '$dias'});
    return (json as List)
        .map((e) => ChamadoSos.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<ChamadoSos> atender(int chamadoId) async {
    final json = await _api.put('/sos/$chamadoId/atender');
    return ChamadoSos.fromJson(json as Map<String, dynamic>);
  }
}
