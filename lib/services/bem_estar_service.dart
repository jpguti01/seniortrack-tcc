import '../models/bem_estar.dart';
import 'api_client.dart';

class BemEstarService {
  final _api = ApiClient.instancia;

  // Um check-in por dia: responder de novo no mesmo dia substitui o anterior.
  Future<CheckinBemEstar> registrar(Humor humor, {String? observacao}) async {
    final json = await _api.post('/bemestar', corpo: {
      'humor': humor.valorApi,
      if (observacao != null && observacao.trim().isNotEmpty)
        'observacao': observacao.trim(),
    });
    return CheckinBemEstar.fromJson(json as Map<String, dynamic>);
  }

  Future<List<CheckinBemEstar>> listarPorPaciente(int pacienteId,
      {int dias = 30}) async {
    final json = await _api
        .get('/bemestar/paciente/$pacienteId', query: {'dias': '$dias'});
    return (json as List)
        .map((e) => CheckinBemEstar.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<CheckinBemEstar?> deHoje(int pacienteId) async {
    final hoje = DateTime.now();
    for (final checkin in await listarPorPaciente(pacienteId, dias: 1)) {
      if (checkin.eDoDia(hoje)) return checkin;
    }
    return null;
  }
}
