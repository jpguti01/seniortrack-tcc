import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';

class BiometriaService {
  final _local = LocalAuthentication();
  final _storage = const FlutterSecureStorage();
  static const _chave = 'sessao_protegida_biometria';

  Future<bool> disponivel() async {
    if (kIsWeb || defaultTargetPlatform == TargetPlatform.windows) return false;
    try {
      return await _local.canCheckBiometrics &&
          (await _local.getAvailableBiometrics()).isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  Future<bool> habilitada() async => await _storage.read(key: _chave) == 'true';
  Future<void> configurar(bool ativa) =>
      _storage.write(key: _chave, value: ativa.toString());

  Future<bool> autenticar() async {
    if (!await disponivel()) return false;
    try {
      return await _local.authenticate(
        localizedReason: 'Confirme sua identidade para acessar o SeniorTrack',
        options:
            const AuthenticationOptions(biometricOnly: true, stickyAuth: true),
      );
    } catch (_) {
      return false;
    }
  }
}
