import '../models/sinal_vital.dart';
import '../models/tipo_sinal_vital.dart';
import 'api_client.dart';

class SinalVitalService {
  final _api = ApiClient.instancia;

  // RF06: o paciente autenticado registra o próprio sinal vital - o backend
  // ignora qualquer "paciente" enviado aqui e usa sempre o dono do token.
  Future<SinalVital> registrar(TipoSinalVital tipo, double valor) async {
    final json = await _api.post('/registrosinalvital', corpo: {
      'tipoSinalVital': tipo.valorApi,
      'valorSinalVital': valor,
    });
    return SinalVital.fromJson(json as Map<String, dynamic>);
  }

  // RF10/RF11: histórico do paciente, com filtro opcional por tipo.
  Future<List<SinalVital>> listarPorPaciente(int pacienteId, {TipoSinalVital? tipo}) async {
    final json = await _api.get(
      '/registrosinalvital/paciente/$pacienteId',
      query: tipo == null ? null : {'tipo': tipo.valorApi},
    );
    return (json as List).map((e) => SinalVital.fromJson(e as Map<String, dynamic>)).toList();
  }

  // RF07
  Future<SinalVital> editarUltimo(int pacienteId, double novoValor) async {
    final json = await _api.put(
      '/registrosinalvital/paciente/$pacienteId/ultimo',
      corpo: {'valorSinalVital': novoValor},
    );
    return SinalVital.fromJson(json as Map<String, dynamic>);
  }

  // RF07
  Future<void> excluirUltimo(int pacienteId) {
    return _api.delete('/registrosinalvital/paciente/$pacienteId/ultimo');
  }
}
