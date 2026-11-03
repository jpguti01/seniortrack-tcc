import '../models/paciente.dart';
import '../models/solicitacao_vinculo.dart';
import 'api_client.dart';

class PacienteService {
  final _api = ApiClient.instancia;

  // RNF05: lista só os pacientes vinculados ao cuidador autenticado.
  Future<List<Paciente>> listarMeusPacientes() async {
    final json = await _api.get('/pacientes');
    return (json as List).map((e) => Paciente.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<Paciente> buscarPorId(int id) async {
    final json = await _api.get('/pacientes/$id');
    return Paciente.fromJson(json as Map<String, dynamic>);
  }

  // RF05, US05: o cuidador autenticado SOLICITA o vínculo por e-mail; o
  // backend sempre responde com a mesma mensagem genérica (não revela se o
  // e-mail existe). O vínculo só é efetivado quando o paciente aceita.
  Future<void> solicitarVinculo(String emailPaciente) {
    return _api.post('/cuidador/pacientes/vincular', corpo: {
      'emailPaciente': emailPaciente,
    });
  }

  // Lado do paciente: solicitações de vínculo pendentes para ele responder.
  Future<List<SolicitacaoVinculo>> listarSolicitacoesPendentes() async {
    final json = await _api.get('/pacientes/solicitacoes-vinculo');
    return (json as List).map((e) => SolicitacaoVinculo.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> aceitarSolicitacao(int solicitacaoId) {
    return _api.put('/pacientes/solicitacoes-vinculo/$solicitacaoId/aceitar');
  }

  Future<void> recusarSolicitacao(int solicitacaoId) {
    return _api.put('/pacientes/solicitacoes-vinculo/$solicitacaoId/recusar');
  }
}
