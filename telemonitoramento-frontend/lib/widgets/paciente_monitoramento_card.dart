import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../models/resumo_paciente.dart';
import '../models/tipo_sinal_vital.dart';
import '../theme/app_theme.dart';

class PacienteMonitoramentoCard extends StatefulWidget {
  final ResumoPaciente resumo;
  final VoidCallback onAbrir;
  final VoidCallback onAlertas;

  const PacienteMonitoramentoCard({
    super.key,
    required this.resumo,
    required this.onAbrir,
    required this.onAlertas,
  });

  @override
  State<PacienteMonitoramentoCard> createState() =>
      _PacienteMonitoramentoCardState();
}

class _PacienteMonitoramentoCardState extends State<PacienteMonitoramentoCard> {
  bool _expandido = false;
  TipoSinalVital _tipo = TipoSinalVital.pressaoArterial;

  @override
  Widget build(BuildContext context) {
    final resumo = widget.resumo;
    final paciente = resumo.paciente;
    // SOS e alerta crítico em vermelho; alertas só de atenção em âmbar.
    final cor = resumo.pediuAjuda || resumo.temCritico
        ? AppTheme.alerta
        : switch (resumo.status) {
            StatusMonitoramento.comAlertas => AppTheme.atencao,
            StatusMonitoramento.semAlertas => AppTheme.primaria,
            StatusMonitoramento.semMedicoes => AppTheme.atencao,
            StatusMonitoramento.indisponivel => AppTheme.textoSecundario,
          };
    final icone = resumo.pediuAjuda
        ? Icons.sos_rounded
        : switch (resumo.status) {
            StatusMonitoramento.comAlertas =>
              Icons.notification_important_outlined,
            StatusMonitoramento.semAlertas => Icons.check_circle_outline_rounded,
            StatusMonitoramento.semMedicoes => Icons.schedule_rounded,
            StatusMonitoramento.indisponivel => Icons.cloud_off_rounded,
          };
    final rotulo = resumo.pediuAjuda
        ? 'Pediu ajuda (SOS)'
        : resumo.temCritico
            ? 'Alerta crítico'
            : resumo.status.rotulo;
    final ultimo = resumo.ultimo();
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.borda),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(height: 4, color: cor),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 25,
                      backgroundColor: cor.withValues(alpha: 0.1),
                      child: Text(
                        paciente.nome.isEmpty
                            ? '?'
                            : paciente.nome[0].toUpperCase(),
                        style:
                            GoogleFonts.sourceSerif4(fontSize: 24, color: cor),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(paciente.nome,
                              style: GoogleFonts.sourceSerif4(
                                fontSize: 23,
                                fontWeight: FontWeight.w600,
                              )),
                          Text('${paciente.idade} anos',
                              style: const TextStyle(
                                  color: AppTheme.textoSecundario)),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: widget.onAbrir,
                      tooltip: 'Abrir perfil de ${paciente.nome}',
                      icon: const Icon(Icons.arrow_forward_rounded,
                          color: AppTheme.primaria),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                  decoration: BoxDecoration(
                    color: cor.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(icone, size: 17, color: cor),
                    const SizedBox(width: 6),
                    Flexible(
                        child: Text(rotulo,
                            style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: cor))),
                  ]),
                ),
                if (resumo.cuidados != null) ...[
                  const SizedBox(height: 16),
                  const Text('HOJE',
                      style: TextStyle(
                        fontSize: 11,
                        letterSpacing: 1.1,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textoSecundario,
                      )),
                  const SizedBox(height: 8),
                  _Hoje(resumo: resumo),
                ],
                const SizedBox(height: 20),
                const Text('ÚLTIMAS MEDIÇÕES',
                    style: TextStyle(
                      fontSize: 11,
                      letterSpacing: 1.1,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textoSecundario,
                    )),
                const SizedBox(height: 12),
                LayoutBuilder(builder: (context, constraints) {
                  final largura = constraints.maxWidth < 340
                      ? constraints.maxWidth
                      : (constraints.maxWidth - 16) / 3;
                  return Wrap(spacing: 8, runSpacing: 8, children: [
                    for (final tipo in TipoSinalVital.values)
                      SizedBox(
                          width: largura,
                          child: _Medicao(resumo: resumo, tipo: tipo)),
                  ]);
                }),
                const SizedBox(height: 14),
                Text(
                  resumo.historico == null
                      ? 'Medições indisponíveis. Tente atualizar o painel.'
                      : ultimo == null
                          ? 'O paciente ainda não registrou medições.'
                          : 'Último registro: ${DateFormat('dd/MM/yyyy • HH:mm').format(ultimo.horaRegistro.toLocal())}',
                  style: const TextStyle(
                      fontSize: 12, color: AppTheme.textoSecundario),
                ),
                if (resumo.alertas == null) ...[
                  const SizedBox(height: 8),
                  const Text('Não foi possível consultar os alertas.',
                      style: TextStyle(fontSize: 13, color: AppTheme.atencao)),
                ],
                if (resumo.semMedicaoRecente(DateTime.now())) ...[
                  const SizedBox(height: 8),
                  const Row(children: [
                    Icon(Icons.schedule_rounded,
                        size: 16, color: AppTheme.atencao),
                    SizedBox(width: 6),
                    Expanded(
                        child: Text('Sem medição nas últimas 24 horas',
                            style: TextStyle(
                                fontSize: 13, color: AppTheme.atencao))),
                  ]),
                ],
                const SizedBox(height: 16),
                Wrap(spacing: 8, runSpacing: 4, children: [
                  TextButton.icon(
                    onPressed: widget.onAbrir,
                    icon: const Icon(Icons.person_outline_rounded, size: 18),
                    label: const Text('Ver acompanhamento'),
                  ),
                  if (resumo.pendentes.isNotEmpty)
                    TextButton.icon(
                      onPressed: widget.onAlertas,
                      style: TextButton.styleFrom(
                          foregroundColor: AppTheme.alerta),
                      icon: const Icon(Icons.notifications_outlined, size: 18),
                      label: Text('${resumo.pendentes.length} alerta(s)'),
                    ),
                ]),
              ],
            ),
          ),
          const Divider(height: 1, color: AppTheme.borda),
          TextButton.icon(
            onPressed: () => setState(() => _expandido = !_expandido),
            icon:
                Icon(_expandido ? Icons.expand_less : Icons.show_chart_rounded),
            label: Text(_expandido
                ? 'Recolher histórico'
                : 'Evolução nas últimas 24 horas'),
            style: TextButton.styleFrom(
              minimumSize: const Size.fromHeight(52),
              shape: const RoundedRectangleBorder(),
            ),
          ),
          if (_expandido)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
              child: Column(children: [
                DropdownButtonFormField<TipoSinalVital>(
                  initialValue: _tipo,
                  decoration: const InputDecoration(labelText: 'Sinal vital'),
                  items: TipoSinalVital.values
                      .map((t) => DropdownMenuItem(
                            value: t,
                            child: Text(t.rotulo),
                          ))
                      .toList(),
                  onChanged: (tipo) => setState(() => _tipo = tipo!),
                ),
                const SizedBox(height: 16),
                _grafico(),
              ]),
            ),
        ],
      ),
    );
  }

  Widget _grafico() {
    if (widget.resumo.historico == null) {
      return const Text('Histórico indisponível. Atualize o painel.');
    }
    final pontos = widget.resumo.ultimas24Horas(_tipo, DateTime.now());
    if (pontos.length < 2) {
      return Text(
          pontos.isEmpty
              ? 'Nenhuma medição de ${_tipo.rotulo.toLowerCase()} nas últimas 24 horas.'
              : 'Há uma medição neste período. O gráfico aparece a partir de duas.',
          style: const TextStyle(color: AppTheme.textoSecundario));
    }
    final inicio = pontos.first.horaRegistro;
    final valores = pontos.map((s) => s.valor.toStringAsFixed(1));
    return Semantics(
      label:
          '${_tipo.rotulo}, ${pontos.length} medições em ${_tipo.unidade}: ${valores.join(', ')}',
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        SizedBox(
            height: 130,
            child: LineChart(LineChartData(
              gridData: const FlGridData(show: false),
              titlesData: const FlTitlesData(show: false),
              borderData: FlBorderData(show: false),
              lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                getTooltipItems: (spots) => spots.map((spot) {
                  final ponto = pontos[spot.spotIndex];
                  return LineTooltipItem(
                    '${ponto.valor.toStringAsFixed(1)} ${_tipo.unidade}\n${DateFormat('HH:mm').format(ponto.horaRegistro.toLocal())}',
                    const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.w600),
                  );
                }).toList(),
              )),
              lineBarsData: [
                LineChartBarData(
                  spots: pontos
                      .map((s) => FlSpot(
                            s.horaRegistro
                                .difference(inicio)
                                .inMilliseconds
                                .toDouble(),
                            s.valor,
                          ))
                      .toList(),
                  isCurved: false,
                  color: AppTheme.primaria,
                  barWidth: 2.5,
                  dotData: const FlDotData(show: true),
                  belowBarData: BarAreaData(
                      show: true,
                      color: AppTheme.primaria.withValues(alpha: 0.06)),
                )
              ],
            ))),
        const SizedBox(height: 10),
        Text(
            '${DateFormat('HH:mm').format(inicio.toLocal())} – ${DateFormat('HH:mm').format(pontos.last.horaRegistro.toLocal())} • ${pontos.length} medições • ${_tipo.unidade}',
            style:
                const TextStyle(fontSize: 12, color: AppTheme.textoSecundario)),
      ]),
    );
  }
}

/// Remédios, bem-estar e SOS do dia, em selos curtos com texto e cor.
class _Hoje extends StatelessWidget {
  final ResumoPaciente resumo;
  const _Hoje({required this.resumo});

  @override
  Widget build(BuildContext context) {
    final cuidados = resumo.cuidados!;
    final checkin = cuidados.checkinHoje;
    return Wrap(spacing: 8, runSpacing: 8, children: [
      if (cuidados.dosesPrevistasHoje > 0)
        cuidados.dosesAtrasadasHoje > 0
            ? _selo(Icons.medication_rounded,
                '${cuidados.dosesAtrasadasHoje} dose(s) atrasada(s)', AppTheme.alerta)
            : _selo(Icons.medication_rounded, 'Remédios em dia', AppTheme.sucesso),
      if (checkin == null)
        _selo(Icons.favorite_outline_rounded, 'Sem check-in hoje',
            AppTheme.textoSecundario)
      else
        _selo(checkin.humor.icone, 'Está ${checkin.humor.rotulo.toLowerCase()}',
            checkin.humor.preocupante ? AppTheme.alerta : AppTheme.sucesso,
            dica: checkin.observacao),
    ]);
  }

  Widget _selo(IconData icone, String texto, Color cor, {String? dica}) {
    final selo = Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
          color: cor.withValues(alpha: .08),
          borderRadius: BorderRadius.circular(8)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icone, size: 16, color: cor),
        const SizedBox(width: 6),
        Flexible(
            child: Text(texto,
                style: TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w600, color: cor))),
      ]),
    );
    return dica == null || dica.isEmpty
        ? selo
        : Tooltip(message: dica, child: selo);
  }
}

class _Medicao extends StatelessWidget {
  final ResumoPaciente resumo;
  final TipoSinalVital tipo;

  const _Medicao({required this.resumo, required this.tipo});

  @override
  Widget build(BuildContext context) {
    final sinal = resumo.ultimo(tipo);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F7F5),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(tipo.icone, size: 18, color: AppTheme.primaria),
        const SizedBox(height: 8),
        Text(tipo.rotulo,
            style:
                const TextStyle(fontSize: 12, color: AppTheme.textoSecundario)),
        const SizedBox(height: 4),
        Text(
            sinal == null
                ? '—'
                : sinal.valor.toStringAsFixed(1).replaceAll('.', ','),
            style: AppTheme.numeroDestaque(fontSize: 25)),
        Text(tipo.unidade,
            style:
                const TextStyle(fontSize: 12, color: AppTheme.textoSecundario)),
        const SizedBox(height: 6),
        Text(
            sinal == null
                ? (resumo.historico == null ? 'Indisponível' : 'Sem registro')
                : DateFormat('dd/MM HH:mm')
                    .format(sinal.horaRegistro.toLocal()),
            style:
                const TextStyle(fontSize: 11, color: AppTheme.textoSecundario)),
      ]),
    );
  }
}
