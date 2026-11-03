import '../models/tipo_sinal_vital.dart';
import '../utils/leitura_bluetooth.dart';

bool bluetoothDisponivel() => false;

Future<double> lerMedicao(TipoSinalVital tipo) =>
    Future.error(const MedidorBluetoothException(
        'A leitura por Bluetooth está disponível na versão web do app, no Chrome ou no Edge.'));
