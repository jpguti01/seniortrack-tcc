import '../models/chamado_sos.dart';
import 'api_client.dart';

class PainelCuidadorService {
  final _api = ApiClient.instancia;

  // Uma única consulta com as pendências do dia de todos os pacientes.
  Future<List<PainelPaciente>> carregar() async {
    final json = await _api.get('/cuidador/painel');
    return (json as List)
        .map((e) => PainelPaciente.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // Canais configurados no servidor para urgências (ex.: "SMS/WhatsApp").
  Future<List<String>> canaisAtivos() async {
    final json = await _api.get('/cuidador/canais-notificacao');
    return (json as List).cast<String>();
  }
}
