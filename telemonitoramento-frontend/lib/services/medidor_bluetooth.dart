import '../models/tipo_sinal_vital.dart';
import 'medidor_bluetooth_stub.dart'
    if (dart.library.js_interop) 'medidor_bluetooth_web.dart' as plataforma;

export '../utils/leitura_bluetooth.dart' show MedidorBluetoothException;

/// Lê a medição de um aparelho Bluetooth que segue os perfis padrão
/// (medidor de pressão, glicosímetro e balança). Usa o Web Bluetooth, então
/// funciona no app web aberto no Chrome ou no Edge; nos demais, [disponivel]
/// é false e o paciente digita ou fala o valor.
class MedidorBluetooth {
  bool get disponivel => plataforma.bluetoothDisponivel();

  /// Lança MedidorBluetoothException com uma mensagem pronta para a tela.
  Future<double> ler(TipoSinalVital tipo) => plataforma.lerMedicao(tipo);
}
