import '../models/limiar.dart';
import '../models/tipo_sinal_vital.dart';
import 'api_client.dart';

class LimiarService {
  final _api = ApiClient.instancia;

  // RF08, UC-04: só o cuidador vinculado ao paciente pode chamar isto - o
  // backend valida a posse e preenche o campo "cuidador" com quem está logado.
  Future<Limiar> salvar({
    required int pacienteId,
    required TipoSinalVital tipo,
    required double valorMinimo,
    required double valorMaximo,
  }) async {
    final json = await _api.post('/limiarseguranca', corpo: {
      'paciente': {'id': pacienteId},
      'tipoSinalVital': tipo.valorApi,
      'valorMin': valorMinimo,
      'valorMax': valorMaximo,
    });
    return Limiar.fromJson(json as Map<String, dynamic>);
  }

  Future<List<Limiar>> listarPorPaciente(int pacienteId) async {
    final json = await _api.get('/limiarseguranca/paciente/$pacienteId');
    return (json as List).map((e) => Limiar.fromJson(e as Map<String, dynamic>)).toList();
  }
}
