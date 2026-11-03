import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Preferências do aparelho que não dependem do servidor.
class PreferenciasService {
  final _armazenamento = const FlutterSecureStorage();
  static const _chaveModoSimples = 'modo_simples';

  // O modo simples (botões grandes, só o essencial) é o padrão do paciente;
  // o painel completo fica a um toque de distância.
  Future<bool> modoSimples() async {
    try {
      return await _armazenamento.read(key: _chaveModoSimples) != 'nao';
    } catch (_) {
      return true;
    }
  }

  Future<void> definirModoSimples(bool ativo) async {
    try {
      await _armazenamento.write(
          key: _chaveModoSimples, value: ativo ? 'sim' : 'nao');
    } catch (_) {/* Sem armazenamento, a escolha vale só para esta sessão. */}
  }
}
