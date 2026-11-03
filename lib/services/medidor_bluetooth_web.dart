import 'dart:async';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import '../models/tipo_sinal_vital.dart';
import '../utils/leitura_bluetooth.dart';

// Recorte da API Web Bluetooth usado pelo app (navigator.bluetooth).
extension type _Bluetooth._(JSObject _) implements JSObject {
  external JSPromise<_Aparelho> requestDevice(JSAny opcoes);
}

extension type _Aparelho._(JSObject _) implements JSObject {
  external _Gatt? get gatt;
}

extension type _Gatt._(JSObject _) implements JSObject {
  external JSPromise<_Gatt> connect();
  external void disconnect();
  external JSPromise<_Servico> getPrimaryService(JSNumber servico);
}

extension type _Servico._(JSObject _) implements JSObject {
  external JSPromise<_Caracteristica> getCharacteristic(JSNumber id);
}

extension type _Caracteristica._(JSObject _) implements JSObject {
  external JSDataView? get value;
  external JSPromise<JSAny?> startNotifications();
  external JSPromise<JSAny?> writeValue(JSUint8Array dados);
  external void addEventListener(String tipo, JSFunction ouvinte);
  external void removeEventListener(String tipo, JSFunction ouvinte);
}

_Bluetooth? get _bluetooth {
  final bluetooth = globalContext
      .getProperty<JSObject>('navigator'.toJS)
      .getProperty<JSAny?>('bluetooth'.toJS);
  return bluetooth.isUndefinedOrNull ? null : bluetooth as _Bluetooth;
}

bool bluetoothDisponivel() => _bluetooth != null;

Future<double> lerMedicao(TipoSinalVital tipo) async {
  final bluetooth = _bluetooth;
  if (bluetooth == null) {
    throw const MedidorBluetoothException(
        'Este navegador não tem Bluetooth. Abra o app no Chrome ou no Edge.');
  }
  final perfil = PerfilBluetooth.de(tipo);

  final _Aparelho aparelho;
  try {
    aparelho = await bluetooth
        .requestDevice({
          'filters': [
            {
              'services': [perfil.servico]
            }
          ],
        }.jsify()!)
        .toDart;
  } catch (_) {
    throw const MedidorBluetoothException(
        'Nenhum aparelho foi escolhido. Ligue o aparelho e tente de novo.');
  }
  final gatt = aparelho.gatt;
  if (gatt == null) {
    throw const MedidorBluetoothException(
        'Não foi possível conectar a este aparelho.');
  }

  final resultado = Completer<double>();
  _Caracteristica? medicao;
  final ouvinte = ((JSObject _) {
    final dados = medicao?.value?.toDart;
    final valor = dados == null ? null : perfil.ler(dados);
    if (valor != null && !resultado.isCompleted) resultado.complete(valor);
  }).toJS;

  try {
    final servidor = await gatt.connect().toDart;
    final servico =
        await servidor.getPrimaryService(perfil.servico.toJS).toDart;
    final caracteristica =
        await servico.getCharacteristic(perfil.caracteristica.toJS).toDart;
    medicao = caracteristica;
    caracteristica.addEventListener('characteristicvaluechanged', ouvinte);
    await caracteristica.startNotifications().toDart;
    final controle = perfil.controleRegistros;
    if (controle != null) {
      final racp = await servico.getCharacteristic(controle.toJS).toDart;
      await racp.startNotifications().toDart;
      await racp.writeValue(PerfilBluetooth.pedidoUltimoRegistro.toJS).toDart;
    }
    // O medidor de pressão e a balança enviam o valor ao terminar a medição.
    return await resultado.future.timeout(const Duration(seconds: 90));
  } on TimeoutException {
    throw const MedidorBluetoothException(
        'O aparelho não enviou a medição. Faça a medição com ele perto e tente de novo.');
  } catch (_) {
    throw const MedidorBluetoothException(
        'A conexão com o aparelho falhou. Verifique se ele está ligado e perto.');
  } finally {
    medicao?.removeEventListener('characteristicvaluechanged', ouvinte);
    gatt.disconnect();
  }
}
