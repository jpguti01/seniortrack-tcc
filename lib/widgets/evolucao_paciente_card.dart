import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/sinal_vital.dart';
import '../models/tipo_sinal_vital.dart';
import '../theme/app_theme.dart';
import '../utils/formatar_medicao.dart';

class EvolucaoPacienteCard extends StatelessWidget {
  final TipoSinalVital tipo;
  final List<SinalVital> registros;
  const EvolucaoPacienteCard(
      {super.key, required this.tipo, required this.registros});
  @override
  Widget build(BuildContext context) {
    final pontos = registros.where((r) => r.tipo == tipo).toList()
      ..sort((a, b) => a.horaRegistro.compareTo(b.horaRegistro));
    final ultimo = pontos.isEmpty ? null : pontos.last;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppTheme.borda)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(tipo.rotulo,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
        const SizedBox(height: 10),
        Text(
            ultimo == null
                ? 'Sem registros'
                : '${formatarMedicao(ultimo.valor)} ${tipo.unidade}',
            style: AppTheme.numeroDestaque(fontSize: 24, color: tipo.cor)),
        const SizedBox(height: 16),
        if (pontos.length < 2)
          SizedBox(
              height: 100,
              child: Center(
                  child: Text(
                      pontos.isEmpty
                          ? 'Nenhuma medição neste período.'
                          : 'O gráfico aparece a partir de dois registros.',
                      style: const TextStyle(
                          fontSize: 13, color: AppTheme.textoSecundario))))
        else
          _grafico(pontos),
        const SizedBox(height: 10),
        Text('${pontos.length} registro(s) no período',
            style:
                const TextStyle(fontSize: 12, color: AppTheme.textoSecundario)),
      ]),
    );
  }

  Widget _grafico(List<SinalVital> pontos) {
    final inicio = pontos.first.horaRegistro;
    final intervalo =
        pontos.last.horaRegistro.difference(inicio).inMilliseconds.toDouble();
    return Semantics(
      label:
          '${tipo.rotulo}: ${pontos.length} registros, de ${formatarMedicao(pontos.first.valor)} a ${formatarMedicao(pontos.last.valor)} ${tipo.unidade}, em ordem cronológica.',
      child: SizedBox(
          height: 100,
          child: LineChart(
              LineChartData(
                minX: 0,
                maxX: intervalo == 0 ? 1 : intervalo,
                gridData: const FlGridData(show: false),
                titlesData: const FlTitlesData(show: false),
                borderData: FlBorderData(show: false),
                lineTouchData: LineTouchData(
                    touchTooltipData: LineTouchTooltipData(
                  getTooltipItems: (spots) => spots.map((s) {
                    final ponto = pontos[s.spotIndex];
                    return LineTooltipItem(
                        '${formatarMedicao(ponto.valor)} ${tipo.unidade}\n${DateFormat('dd/MM HH:mm').format(ponto.horaRegistro.toLocal())}',
                        const TextStyle(
                            color: Colors.white, fontWeight: FontWeight.w600));
                  }).toList(),
                )),
                lineBarsData: [
                  LineChartBarData(
                    spots: pontos
                        .map((p) => FlSpot(
                            p.horaRegistro
                                .difference(inicio)
                                .inMilliseconds
                                .toDouble(),
                            p.valor))
                        .toList(),
                    isCurved: false,
                    color: tipo.cor,
                    barWidth: 2.5,
                    dotData: FlDotData(show: pontos.length <= 12),
                    belowBarData: BarAreaData(
                        show: true, color: tipo.cor.withValues(alpha: .07)),
                  )
                ],
              ),
              duration: Duration.zero)),
    );
  }
}
