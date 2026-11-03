import '../models/alerta.dart';
import 'api_client.dart';

class AlertaService {
  final _api = ApiClient.instancia;

  Future<List<Alerta>> listarPorPaciente(int pacienteId) async {
    final json = await _api.get('/alertas/paciente/$pacienteId');
    return (json as List).map((e) => Alerta.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<Alerta> resolver(int alertaId) async {
    final json = await _api.put('/alertas/$alertaId/resolver');
    return Alerta.fromJson(json as Map<String, dynamic>);
  }
}
