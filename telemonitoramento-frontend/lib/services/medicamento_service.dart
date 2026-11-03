import '../models/medicamento.dart';
import 'api_client.dart';

class MedicamentoService {
  final _api = ApiClient.instancia;

  Future<List<Medicamento>> listarPorPaciente(int pacienteId) async {
    final json = await _api.get('/medicamentos/paciente/$pacienteId');
    return (json as List)
        .map((e) => Medicamento.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // Só o cuidador vinculado cadastra e edita; o backend valida o vínculo.
  Future<Medicamento> salvar({
    required int pacienteId,
    int? id,
    required String nome,
    String? dosagem,
    String? instrucoes,
    required List<String> horarios,
    String? foto,
  }) async {
    final corpo = {
      'nome': nome,
      'dosagem': dosagem,
      'instrucoes': instrucoes,
      'horarios': horarios,
      'foto': foto,
    };
    final json = id == null
        ? await _api.post('/medicamentos/paciente/$pacienteId', corpo: corpo)
        : await _api.put('/medicamentos/$id', corpo: corpo);
    return Medicamento.fromJson(json as Map<String, dynamic>);
  }

  Future<void> remover(int id) => _api.delete('/medicamentos/$id');

  Future<List<Dose>> dosesDeHoje(int pacienteId) async {
    final json = await _api.get('/medicamentos/paciente/$pacienteId/hoje');
    return (json as List)
        .map((e) => Dose.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // "Tomei": só o próprio paciente confirma; dia e hora vêm do servidor.
  Future<Dose> confirmarTomada(int medicamentoId, String horario) async {
    final json = await _api.post('/medicamentos/$medicamentoId/tomadas',
        corpo: {'horario': horario});
    return Dose.fromJson(json as Map<String, dynamic>);
  }

  Future<List<Adesao>> adesao(int pacienteId, {int dias = 30}) async {
    final json = await _api.get('/medicamentos/paciente/$pacienteId/adesao',
        query: {'dias': '$dias'});
    return (json as List)
        .map((e) => Adesao.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
