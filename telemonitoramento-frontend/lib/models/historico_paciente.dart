import 'sinal_vital.dart';
import 'tipo_sinal_vital.dart';

class HistoricoPaciente {
  final List<SinalVital> registros;
  HistoricoPaciente(this.registros);

  Set<TipoSinalVital> tiposHoje(DateTime agora) {
    final local = agora.toLocal();
    final inicio = DateTime(local.year, local.month, local.day);
    return registros
        .where((s) =>
            !s.horaRegistro.isBefore(inicio) && !s.horaRegistro.isAfter(agora))
        .map((s) => s.tipo)
        .toSet();
  }

  List<SinalVital> filtrar(
      {required DateTime agora, int? dias, TipoSinalVital? tipo}) {
    final local = agora.toLocal();
    final inicio = dias == null
        ? null
        : DateTime(local.year, local.month, local.day - dias + 1);
    return registros
        .where((s) =>
            (tipo == null || s.tipo == tipo) &&
            !s.horaRegistro.isAfter(agora) &&
            (inicio == null || !s.horaRegistro.isBefore(inicio)))
        .toList()
      ..sort((a, b) => b.horaRegistro.compareTo(a.horaRegistro));
  }
}
