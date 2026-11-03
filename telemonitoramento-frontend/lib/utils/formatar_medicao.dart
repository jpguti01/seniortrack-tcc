import 'package:intl/intl.dart';

final _numero = NumberFormat('0.########', 'pt_BR');
String formatarMedicao(double valor) =>
    valor.isFinite ? _numero.format(valor) : '—';
