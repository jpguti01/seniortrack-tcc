import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';

import '../models/alerta.dart';
import '../models/bem_estar.dart';
import '../models/chamado_sos.dart';
import '../models/limiar.dart';
import '../models/medicamento.dart';
import '../models/paciente.dart';
import '../models/sinal_vital.dart';
import '../models/tipo_sinal_vital.dart';
import '../services/alerta_service.dart';
import '../services/api_exception.dart';
import '../services/bem_estar_service.dart';
import '../services/limiar_service.dart';
import '../services/medicamento_service.dart';
import '../services/relatorio_paciente_service.dart';
import '../services/sinal_vital_service.dart';
import '../services/sos_service.dart';
import '../theme/app_brand.dart';
import '../theme/app_theme.dart';
import '../widgets/alerta_card.dart';
import '../widgets/bem_estar_paciente_aba.dart';
import '../widgets/medicamento_form.dart';
import '../widgets/remedios_paciente_aba.dart';
import '../widgets/sinal_vital_card.dart';

class PacienteDetalheScreen extends StatefulWidget {
  final Paciente paciente;
  final int abaInicial;
  const PacienteDetalheScreen({super.key, required this.paciente, this.abaInicial = 0})
      : assert(abaInicial >= 0 && abaInicial < 5);

  @override
  State<PacienteDetalheScreen> createState() => _PacienteDetalheScreenState();
}

class _PacienteDetalheScreenState extends State<PacienteDetalheScreen>
    with SingleTickerProviderStateMixin {
  static const _abaRemedios = 2;
  static const _abaLimiares = 4;
  static const _diasRelatorio = 30;

  final _sinalVitalService = SinalVitalService();
  final _alertaService = AlertaService();
  final _limiarService = LimiarService();
  final _medicamentoService = MedicamentoService();
  final _bemEstarService = BemEstarService();
  final _sosService = SosService();

  late final TabController _abas = TabController(
      length: 5, vsync: this, initialIndex: widget.abaInicial)
    ..addListener(() => setState(() {}));

  late Future<List<SinalVital>> _historico;
  late Future<List<Alerta>> _alertas;
  late Future<List<Limiar>> _limiares;
  late Future<List<Medicamento>> _medicamentos;
  late Future<List<Dose>> _dosesHoje;
  late Future<List<Adesao>> _adesao;
  late Future<List<CheckinBemEstar>> _checkins;
  late Future<List<ChamadoSos>> _chamados;

  TipoSinalVital _tipoSelecionado = TipoSinalVital.pressaoArterial;
  bool _gerandoRelatorio = false;

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  @override
  void dispose() {
    _abas.dispose();
    super.dispose();
  }

  void _carregar() {
    final id = widget.paciente.id;
    setState(() {
      _historico = _sinalVitalService.listarPorPaciente(id);
      _alertas = _alertaService.listarPorPaciente(id);
      _limiares = _limiarService.listarPorPaciente(id);
      _medicamentos = _medicamentoService.listarPorPaciente(id);
      _dosesHoje = _medicamentoService.dosesDeHoje(id);
      _adesao = _medicamentoService.adesao(id, dias: _diasRelatorio);
      _checkins = _bemEstarService.listarPorPaciente(id, dias: _diasRelatorio);
      _chamados = _sosService.listarPorPaciente(id, dias: _diasRelatorio);
    });
  }

  void _aviso(String mensagem) {
    if (mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(mensagem)));
    }
  }

  Future<void> _abrirFormularioMedicamento([Medicamento? existente]) async {
    final salvou = await abrirFormularioMedicamento(context,
        pacienteId: widget.paciente.id, existente: existente);
    if (salvou == true) {
      _aviso(existente == null ? 'Remédio cadastrado.' : 'Remédio atualizado.');
      _carregar();
    }
  }

  Future<void> _removerMedicamento(Medicamento remedio) async {
    final confirmou = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Remover ${remedio.nome}?'),
        content: const Text(
            'O remédio sai da rotina do paciente. O histórico de doses já confirmadas continua no relatório.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancelar')),
          FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              style: FilledButton.styleFrom(backgroundColor: AppTheme.alerta),
              child: const Text('Remover')),
        ],
      ),
    );
    if (confirmou != true) return;
    try {
      await _medicamentoService.remover(remedio.id);
      _aviso('${remedio.nome} removido da rotina.');
      _carregar();
    } on ApiException catch (e) {
      _aviso(e.mensagem);
    } catch (_) {
      _aviso('Não foi possível remover. Tente novamente.');
    }
  }

  // Dados opcionais do relatório: se a consulta falhar, a seção sai como
  // "indisponível" em vez de impedir o PDF inteiro.
  Future<T?> _opcional<T>(Future<T> consulta) async {
    try {
      return await consulta;
    } catch (_) {
      return null;
    }
  }

  Future<void> _gerarRelatorio() async {
    if (_gerandoRelatorio) return;
    setState(() => _gerandoRelatorio = true);
    try {
      final agora = DateTime.now();
      final bytes = await RelatorioPacienteService().gerarClinico(
        paciente: widget.paciente,
        dias: _diasRelatorio,
        emitidoEm: agora,
        registros: await _historico,
        limiares: await _opcional(_limiares) ?? [],
        alertas: await _alertas,
        adesao: await _opcional(_adesao),
        checkins: await _opcional(_checkins),
        chamados: await _opcional(_chamados),
      );
      final nome = widget.paciente.nome.split(' ').first.toLowerCase();
      await Printing.sharePdf(
          bytes: bytes,
          filename:
              '${AppBrand.nome}-relatorio-clinico-$nome-${DateFormat('yyyyMMdd').format(agora)}.pdf');
    } catch (_) {
      _aviso('Não foi possível gerar o relatório. Atualize e tente novamente.');
    } finally {
      if (mounted) setState(() => _gerandoRelatorio = false);
    }
  }

  Future<void> _resolverAlerta(int alertaId) async {
    try {
      await _alertaService.resolver(alertaId);
      _carregar();
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.mensagem)));
      }
    }
  }

  Future<void> _abrirFormularioLimiar() async {
    final salvou = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => _FormularioLimiar(pacienteId: widget.paciente.id),
    );
    if (salvou == true) _carregar();
  }

  Widget? _botaoDaAba() {
    if (_abas.index == _abaRemedios) {
      return FloatingActionButton.extended(
        onPressed: () => _abrirFormularioMedicamento(),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Novo remédio'),
      );
    }
    if (_abas.index == 0 || _abas.index == _abaLimiares) {
      return FloatingActionButton.extended(
        onPressed: _abrirFormularioLimiar,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Novo limiar'),
      );
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text(widget.paciente.nome),
          actions: [
            IconButton(
              onPressed: _gerandoRelatorio ? null : _gerarRelatorio,
              tooltip: 'Relatório clínico em PDF (últimos 30 dias)',
              icon: _gerandoRelatorio
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.picture_as_pdf_outlined),
            ),
            const SizedBox(width: 8),
          ],
          bottom: TabBar(
            controller: _abas,
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            indicatorColor: Colors.white,
            indicatorWeight: 3,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            labelStyle: const TextStyle(fontWeight: FontWeight.w600),
            tabs: const [
              Tab(text: 'Histórico'),
              Tab(text: 'Alertas'),
              Tab(text: 'Remédios'),
              Tab(text: 'Bem-estar'),
              Tab(text: 'Limiares'),
            ],
          ),
        ),
        body: TabBarView(
          controller: _abas,
          children: [
            RefreshIndicator(
              onRefresh: () async => _carregar(),
              child: _abaHistorico(),
            ),
            RefreshIndicator(
              onRefresh: () async => _carregar(),
              child: FutureBuilder<List<Alerta>>(
                future: _alertas,
                builder: (context, snapshot) => _listaOuVazio(
                  snapshot: snapshot,
                  icone: Icons.notifications_none_rounded,
                  vazio: 'Nenhum alerta para este paciente.',
                  builder: (dados) => ([...dados]
                        ..sort((a, b) {
                          if (a.resolvido != b.resolvido) return a.resolvido ? 1 : -1;
                          if (a.critico != b.critico) return a.critico ? -1 : 1;
                          return b.dataHora.compareTo(a.dataHora);
                        }))
                      .map((a) => AlertaCard(
                            alerta: a,
                            aoResolver: a.resolvido ? null : () => _resolverAlerta(a.id),
                          ))
                      .toList(),
                ),
              ),
            ),
            RemediosPacienteAba(
              medicamentos: _medicamentos,
              dosesHoje: _dosesHoje,
              adesao: _adesao,
              onRecarregar: () async => _carregar(),
              onEditar: _abrirFormularioMedicamento,
              onRemover: _removerMedicamento,
            ),
            BemEstarPacienteAba(
              checkins: _checkins,
              chamados: _chamados,
              onRecarregar: () async => _carregar(),
            ),
            RefreshIndicator(
              onRefresh: () async => _carregar(),
              child: FutureBuilder<List<Limiar>>(
                future: _limiares,
                builder: (context, snapshot) => _listaOuVazio(
                  snapshot: snapshot,
                  icone: Icons.tune_rounded,
                  vazio: 'Nenhum limiar configurado ainda.',
                  builder: (dados) => dados.map((l) => _LimiarCard(limiar: l)).toList(),
                ),
              ),
            ),
          ],
        ),
        floatingActionButton: _botaoDaAba(),
    );
  }

  Widget _abaHistorico() {
    return FutureBuilder<List<SinalVital>>(
      future: _historico,
      builder: (context, snapshotHistorico) {
        if (snapshotHistorico.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: AppTheme.primaria));
        }
        if (snapshotHistorico.hasError) {
          return _mensagemEstado(Icons.wifi_off_rounded, 'Não foi possível carregar.');
        }
        final todos = snapshotHistorico.data ?? [];
        if (todos.isEmpty) {
          return _mensagemEstado(Icons.monitor_heart_outlined, 'Nenhum sinal vital registrado ainda.');
        }

        final doTipo = todos.where((s) => s.tipo == _tipoSelecionado).toList()
          ..sort((a, b) => a.horaRegistro.compareTo(b.horaRegistro));

        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
          children: [
            _SeletorTipo(
              selecionado: _tipoSelecionado,
              onSelecionado: (t) => setState(() => _tipoSelecionado = t),
            ),
            const SizedBox(height: 20),
            if (doTipo.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 40),
                child: Center(
                  child: Text(
                    'Sem registros de ${_tipoSelecionado.rotulo.toLowerCase()} ainda.',
                    style: TextStyle(color: AppTheme.texto.withValues(alpha: 0.5)),
                  ),
                ),
              )
            else ...[
              FutureBuilder<List<Limiar>>(
                future: _limiares,
                builder: (context, snapshotLimiar) {
                  Limiar? limiar;
                  final limiares = snapshotLimiar.data;
                  if (limiares != null) {
                    for (final l in limiares) {
                      if (l.tipo == _tipoSelecionado) limiar = l;
                    }
                  }
                  return _GraficoEvolucao(pontos: doTipo, limiar: limiar);
                },
              ),
              const SizedBox(height: 24),
              Text(
                'Registros',
                style: GoogleFonts.workSans(fontSize: 15, fontWeight: FontWeight.w600, color: AppTheme.texto),
              ),
              const SizedBox(height: 10),
              ...doTipo.reversed.map((s) => SinalVitalCard(sinal: s)),
            ],
          ],
        );
      },
    );
  }

  Widget _listaOuVazio<T>({
    required AsyncSnapshot<List<T>> snapshot,
    required IconData icone,
    required String vazio,
    required List<Widget> Function(List<T>) builder,
  }) {
    if (snapshot.connectionState == ConnectionState.waiting) {
      return const Center(child: CircularProgressIndicator(color: AppTheme.primaria));
    }
    if (snapshot.hasError) {
      return _mensagemEstado(Icons.wifi_off_rounded, 'Não foi possível carregar.');
    }
    final dados = snapshot.data ?? [];
    if (dados.isEmpty) {
      return _mensagemEstado(icone, vazio);
    }
    return ListView(padding: const EdgeInsets.fromLTRB(16, 16, 16, 100), children: builder(dados));
  }

  Widget _mensagemEstado(IconData icone, String texto) {
    return ListView(
      children: [
        const SizedBox(height: 90),
        Icon(icone, size: 44, color: AppTheme.primaria.withValues(alpha: 0.3)),
        const SizedBox(height: 14),
        Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(texto, textAlign: TextAlign.center, style: TextStyle(color: AppTheme.texto.withValues(alpha: 0.55))),
          ),
        ),
      ],
    );
  }
}

/// Seletor dos 3 tipos de sinal vital — cada chip já carrega a cor da
/// categoria, a mesma usada no gráfico e nos cards (consistência de ponta a
/// ponta, não uma escolha de cor isolada por tela).
class _SeletorTipo extends StatelessWidget {
  final TipoSinalVital selecionado;
  final ValueChanged<TipoSinalVital> onSelecionado;

  const _SeletorTipo({required this.selecionado, required this.onSelecionado});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: TipoSinalVital.values.map((tipo) {
        final ativo = tipo == selecionado;
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: GestureDetector(
              onTap: () => onSelecionado(tipo),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                height: 52,
                decoration: BoxDecoration(
                  color: ativo ? tipo.cor : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: ativo ? tipo.cor : AppTheme.texto.withValues(alpha: 0.12)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(tipo.icone, size: 18, color: ativo ? Colors.white : tipo.cor),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        tipo.rotulo,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: ativo ? Colors.white : AppTheme.texto,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

/// O gráfico que resolve a reclamação de "parece genérico": em vez de uma
/// lista plana de números, o cuidador vê a tendência de um relance, com a
/// faixa segura (se configurada) sombreada atrás da linha.
class _GraficoEvolucao extends StatelessWidget {
  final List<SinalVital> pontos;
  final Limiar? limiar;

  const _GraficoEvolucao({required this.pontos, required this.limiar});

  @override
  Widget build(BuildContext context) {
    final cor = pontos.first.tipo.cor;
    final valores = pontos.map((p) => p.valor).toList();

    var minY = valores.reduce((a, b) => a < b ? a : b);
    var maxY = valores.reduce((a, b) => a > b ? a : b);
    if (limiar != null) {
      minY = [minY, limiar!.valorMinimo].reduce((a, b) => a < b ? a : b);
      maxY = [maxY, limiar!.valorMaximo].reduce((a, b) => a > b ? a : b);
    }
    final folga = (maxY - minY).abs() * 0.2 + 1;
    minY -= folga;
    maxY += folga;

    final spots = <FlSpot>[
      for (var i = 0; i < pontos.length; i++) FlSpot(i.toDouble(), pontos[i].valor),
    ];

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 20, 20, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 3))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                valores.last.toStringAsFixed(1),
                style: AppTheme.numeroDestaque(fontSize: 30, color: cor),
              ),
              const SizedBox(width: 6),
              Text(pontos.first.tipo.unidade, style: TextStyle(fontSize: 13, color: AppTheme.texto.withValues(alpha: 0.55))),
              const Spacer(),
              Text('última medição', style: TextStyle(fontSize: 12, color: AppTheme.texto.withValues(alpha: 0.45))),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 160,
            child: LineChart(
              LineChartData(
                minY: minY,
                maxY: maxY,
                gridData: const FlGridData(show: false),
                borderData: FlBorderData(show: false),
                titlesData: const FlTitlesData(show: false),
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipColor: (_) => AppTheme.texto,
                    getTooltipItems: (spots) => spots.map((s) {
                      final p = pontos[s.x.toInt()];
                      return LineTooltipItem(
                        '${p.valor.toStringAsFixed(1)} ${p.tipo.unidade}\n${DateFormat('dd/MM HH:mm').format(p.horaRegistro)}',
                        const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                      );
                    }).toList(),
                  ),
                ),
                extraLinesData: limiar == null
                    ? null
                    : ExtraLinesData(horizontalLines: [
                        HorizontalLine(
                          y: limiar!.valorMaximo,
                          color: AppTheme.alerta.withValues(alpha: 0.5),
                          strokeWidth: 1.5,
                          dashArray: [6, 4],
                        ),
                        HorizontalLine(
                          y: limiar!.valorMinimo,
                          color: AppTheme.alerta.withValues(alpha: 0.5),
                          strokeWidth: 1.5,
                          dashArray: [6, 4],
                        ),
                      ]),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    curveSmoothness: 0.25,
                    color: cor,
                    barWidth: 3,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, _, __, index) {
                        final foraDoLimiar = limiar != null &&
                            (spot.y > limiar!.valorMaximo || spot.y < limiar!.valorMinimo);
                        return FlDotCirclePainter(
                          radius: foraDoLimiar ? 5 : 3,
                          color: foraDoLimiar ? AppTheme.alerta : cor,
                          strokeWidth: 2,
                          strokeColor: Colors.white,
                        );
                      },
                    ),
                    belowBarData: BarAreaData(show: true, color: cor.withValues(alpha: 0.08)),
                  ),
                ],
              ),
            ),
          ),
          if (limiar != null) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                Container(width: 16, height: 1.5, color: AppTheme.alerta.withValues(alpha: 0.5)),
                const SizedBox(width: 6),
                Text(
                  'faixa segura: ${limiar!.valorMinimo.toStringAsFixed(0)} a ${limiar!.valorMaximo.toStringAsFixed(0)} ${pontos.first.tipo.unidade}',
                  style: TextStyle(fontSize: 12, color: AppTheme.texto.withValues(alpha: 0.55)),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _LimiarCard extends StatelessWidget {
  final Limiar limiar;
  const _LimiarCard({required this.limiar});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border(left: BorderSide(color: limiar.tipo.cor, width: 5)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Row(
        children: [
          Icon(limiar.tipo.icone, color: limiar.tipo.cor, size: 24),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(limiar.tipo.rotulo, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                const SizedBox(height: 2),
                Text(
                  'Faixa segura: ${limiar.valorMinimo.toStringAsFixed(1)} a ${limiar.valorMaximo.toStringAsFixed(1)} ${limiar.tipo.unidade}',
                  style: TextStyle(fontSize: 13, color: AppTheme.texto.withValues(alpha: 0.6)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FormularioLimiar extends StatefulWidget {
  final int pacienteId;
  const _FormularioLimiar({required this.pacienteId});

  @override
  State<_FormularioLimiar> createState() => _FormularioLimiarState();
}

class _FormularioLimiarState extends State<_FormularioLimiar> {
  final _formKey = GlobalKey<FormState>();
  final _minController = TextEditingController();
  final _maxController = TextEditingController();
  final _service = LimiarService();
  TipoSinalVital _tipo = TipoSinalVital.pressaoArterial;
  bool _enviando = false;
  String? _erro;

  @override
  void dispose() {
    _minController.dispose();
    _maxController.dispose();
    super.dispose();
  }

  Future<void> _salvar() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _enviando = true;
      _erro = null;
    });
    try {
      await _service.salvar(
        pacienteId: widget.pacienteId,
        tipo: _tipo,
        valorMinimo: double.parse(_minController.text.replaceAll(',', '.')),
        valorMaximo: double.parse(_maxController.text.replaceAll(',', '.')),
      );
      if (mounted) Navigator.of(context).pop(true);
    } on ApiException catch (e) {
      setState(() => _erro = e.mensagem);
    } catch (e) {
      setState(() => _erro = 'Não foi possível salvar. Verifique sua conexão.');
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 24, right: 24, top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Novo limiar de segurança',
              style: GoogleFonts.sourceSerif4(fontSize: 20, fontWeight: FontWeight.w600, color: AppTheme.texto),
            ),
            const SizedBox(height: 16),
            if (_erro != null) ...[
              Text(_erro!, style: const TextStyle(color: AppTheme.alerta)),
              const SizedBox(height: 12),
            ],
            DropdownButtonFormField<TipoSinalVital>(
              initialValue: _tipo,
              decoration: const InputDecoration(labelText: 'Tipo de sinal vital'),
              items: TipoSinalVital.values
                  .map((t) => DropdownMenuItem(value: t, child: Text(t.rotulo)))
                  .toList(),
              onChanged: (v) => setState(() => _tipo = v!),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _minController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(labelText: 'Mínimo (${_tipo.unidade})'),
                    validator: (v) => (v == null || double.tryParse(v.replaceAll(',', '.')) == null) ? 'Inválido' : null,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _maxController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(labelText: 'Máximo (${_tipo.unidade})'),
                    validator: (v) {
                      final max = double.tryParse((v ?? '').replaceAll(',', '.'));
                      final min = double.tryParse(_minController.text.replaceAll(',', '.'));
                      if (max == null) return 'Inválido';
                      if (min != null && max <= min) return 'Deve ser > mínimo';
                      return null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _enviando ? null : _salvar,
              child: _enviando
                  ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Salvar limiar'),
            ),
          ],
        ),
      ),
    );
  }
}
