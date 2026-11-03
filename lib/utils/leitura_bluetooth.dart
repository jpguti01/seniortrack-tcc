import 'dart:math' as math;
import 'dart:typed_data';

import '../models/tipo_sinal_vital.dart';

class MedidorBluetoothException implements Exception {
  final String mensagem;
  const MedidorBluetoothException(this.mensagem);
  @override
  String toString() => mensagem;
}

/// Serviço e característica GATT padrão (Bluetooth SIG) de cada medição. Só
/// aparelhos que seguem esses perfis são lidos; os de protocolo próprio não.
class PerfilBluetooth {
  final int servico;
  final int caracteristica;

  /// Record Access Control Point: o glicosímetro só envia a medição guardada
  /// depois de receber o pedido "último registro".
  final int? controleRegistros;
  final double? Function(ByteData dados) ler;

  const PerfilBluetooth._(this.servico, this.caracteristica, this.ler,
      [this.controleRegistros]);

  static PerfilBluetooth de(TipoSinalVital tipo) => switch (tipo) {
        TipoSinalVital.pressaoArterial =>
          const PerfilBluetooth._(0x1810, 0x2A35, lerPressaoSistolica),
        TipoSinalVital.glicemia =>
          const PerfilBluetooth._(0x1808, 0x2A18, lerGlicemia, 0x2A52),
        TipoSinalVital.peso => const PerfilBluetooth._(0x181D, 0x2A9D, lerPeso),
      };

  /// Opcode 0x01 (enviar registros) com o operador 0x06 (último registro).
  static final pedidoUltimoRegistro = Uint8List.fromList([0x01, 0x06]);
}

/// SFLOAT do IEEE 11073: mantissa de 12 bits e expoente de 4 bits, ambos com
/// sinal. Devolve null para os valores especiais (NaN, NRes, infinito).
double? lerSfloat(ByteData dados, int posicao) {
  final bruto = dados.getUint16(posicao, Endian.little);
  if (const {0x07FF, 0x0800, 0x07FE, 0x0801, 0x0802}.contains(bruto)) {
    return null;
  }
  var mantissa = bruto & 0x0FFF;
  if (mantissa >= 0x0800) mantissa -= 0x1000;
  var expoente = bruto >> 12;
  if (expoente >= 0x8) expoente -= 0x10;
  return mantissa * math.pow(10, expoente).toDouble();
}

/// Blood Pressure Measurement (0x2A35): pressão sistólica em mmHg, o valor
/// que o app registra como "Pressão Arterial".
double? lerPressaoSistolica(ByteData dados) {
  if (dados.lengthInBytes < 7) return null;
  final sistolica = lerSfloat(dados, 1);
  if (sistolica == null) return null;
  final emKpa = dados.getUint8(0) & 0x01 != 0;
  return (emKpa ? sistolica * 7.50062 : sistolica).roundToDouble();
}

/// Glucose Measurement (0x2A18): glicemia em mg/dL.
double? lerGlicemia(ByteData dados) {
  if (dados.lengthInBytes < 1) return null;
  final flags = dados.getUint8(0);
  var posicao = 1 + 2 + 7; // flags, número de sequência, data e hora base
  if (flags & 0x01 != 0) posicao += 2; // deslocamento de horário
  if (flags & 0x02 == 0 || dados.lengthInBytes < posicao + 2) return null;
  final valor = lerSfloat(dados, posicao);
  if (valor == null) return null;
  final emMolPorLitro = flags & 0x04 != 0;
  return (emMolPorLitro ? valor * 1000 * 18.016 : valor * 100000)
      .roundToDouble();
}

/// Weight Measurement (0x2A9D): peso em kg, com uma casa decimal.
double? lerPeso(ByteData dados) {
  if (dados.lengthInBytes < 3) return null;
  final bruto = dados.getUint16(1, Endian.little);
  if (bruto == 0xFFFF) return null; // medição sem sucesso
  final emLibras = dados.getUint8(0) & 0x01 != 0;
  final kg = emLibras ? bruto * 0.01 * 0.45359237 : bruto * 0.005;
  return (kg * 10).roundToDouble() / 10;
}
