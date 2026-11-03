import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/chamado_sos.dart';
import '../models/resumo_paciente.dart';
import '../providers/auth_provider.dart';
import '../services/api_exception.dart';
import '../services/painel_cuidador_service.dart';
import '../services/resumo_cuidador_service.dart';
import '../services/sos_service.dart';
import '../theme/app_theme.dart';
import '../widgets/seniortrack_brand.dart';
import '../widgets/paciente_monitoramento_card.dart';
import '../widgets/painel_alertas_cuidador.dart';
import '../widgets/sos_pendentes_banner.dart';
import '../widgets/vincular_paciente_dialog.dart';
import 'paciente_detalhe_screen.dart';

class CuidadorHomeScreen extends StatefulWidget {
  final ResumoCuidadorService? service;
  const CuidadorHomeScreen({super.key, this.service});
  @override
  State<CuidadorHomeScreen> createState() => _CuidadorHomeScreenState();
}

class _CuidadorHomeScreenState extends State<CuidadorHomeScreen> {
  late final _service = widget.service ?? ResumoCuidadorService();
  final _sos = SosService();
  final _busca = TextEditingController();
  List<ResumoPaciente>? _resumos;
  StatusMonitoramento? _filtro;
  bool _carregando = false;
  String? _erro;
  DateTime? _atualizado;
  List<String>? _canais;
  final _atendendo = <int>{};
  late final Timer _timer;

  @override
  void initState() {
    super.initState();
    _carregar();
    if (widget.service == null) {
      PainelCuidadorService().canaisAtivos().then((canais) {
        if (mounted) setState(() => _canais = canais);
      }, onError: (_) {/* Sem a informação, a linha não aparece. */});
    }
    _timer = Timer.periodic(const Duration(seconds: 60), (_) {
      if (ModalRoute.of(context)?.isCurrent != true) return;
      final ciclo = WidgetsBinding.instance.lifecycleState;
      if (ciclo != null && ciclo != AppLifecycleState.resumed) return;
      _carregar();
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    _busca.dispose();
    super.dispose();
  }

  Future<void> _carregar() async {
    if (_carregando) return;
    setState(() => _carregando = true);
    try {
      final resumos = await _service.carregar();
      if (!mounted) return;
      setState(() {
        _resumos = resumos;
        _atualizado = DateTime.now();
        _erro = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _erro = e is ApiException
          ? e.mensagem
          : 'Não foi possível atualizar o painel. Verifique a conexão e tente novamente.');
    } finally {
      if (mounted) setState(() => _carregando = false);
    }
  }

  Future<void> _atenderSos(ChamadoSos chamado) async {
    setState(() => _atendendo.add(chamado.id));
    try {
      await _sos.atender(chamado.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(
              'Pedido de ajuda de ${chamado.pacienteNome} marcado como atendido.')));
      await _carregar();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(e is ApiException
              ? e.mensagem
              : 'Não foi possível registrar o atendimento. Tente novamente.')));
    } finally {
      if (mounted) setState(() => _atendendo.remove(chamado.id));
    }
  }

  Future<void> _vincularPaciente() async {
    final enviou = await abrirDialogoVincularPaciente(context);
    if (enviou == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text(
              'Solicitação enviada. O paciente precisa aceitar no app dele.')));
    }
  }

  Future<void> _abrirPaciente(ResumoPaciente resumo,
      {bool alertas = false}) async {
    await Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => PacienteDetalheScreen(
            paciente: resumo.paciente, abaInicial: alertas ? 1 : 0)));
    if (mounted) await _carregar();
  }

  void _abrirCentral() {
    if (_resumos == null) return;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: AppTheme.fundo,
      builder: (sheetContext) => SafeArea(
          child: ConstrainedBox(
        constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(sheetContext).height * 0.8),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          child: PainelAlertasCuidador(
              resumos: _resumos!,
              onAbrir: (resumo) {
                Navigator.of(sheetContext).pop();
                _abrirPaciente(resumo, alertas: true);
              }),
        ),
      )),
    );
  }

  String _normalizar(String valor) {
    var resultado = valor.toLowerCase().trim();
    const grupos = {
      'áàâãä': 'a',
      'éèêë': 'e',
      'íìîï': 'i',
      'óòôõö': 'o',
      'úùûü': 'u',
      'ç': 'c'
    };
    grupos.forEach((letras, letra) {
      for (final caractere in letras.split('')) {
        resultado = resultado.replaceAll(caractere, letra);
      }
    });
    return resultado;
  }

  @override
  Widget build(BuildContext context) {
    final nome =
        context.watch<AuthProvider>().sessao?.nome.trim().split(' ').first ??
            '';
    final alertas =
        (_resumos ?? []).fold<int>(0, (n, r) => n + r.pendentes.length);
    final parcial = _resumos?.any((r) => r.alertas == null) ?? false;
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 72,
        titleSpacing: 20,
        title: const SeniorTrackHeader(),
        actions: [
          IconButton(
            onPressed: _resumos == null ? null : _abrirCentral,
            tooltip: parcial
                ? 'Central de alertas: consulta parcial'
                : 'Central de alertas: $alertas pendentes',
            icon: Badge(
                isLabelVisible: alertas > 0 || parcial,
                label: Text(parcial ? '$alertas+' : '$alertas'),
                child: const Icon(Icons.notifications_outlined)),
          ),
          IconButton(
              tooltip: 'Sair',
              onPressed: () => context.read<AuthProvider>().logout(),
              icon: const Icon(Icons.logout_rounded)),
          const SizedBox(width: 8),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _carregar,
        child: LayoutBuilder(
            builder: (context, constraints) => SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: EdgeInsets.symmetric(
                      horizontal: constraints.maxWidth < 600 ? 16 : 36,
                      vertical: 28),
                  child: Center(
                      child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1480),
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('ÁREA DO CUIDADOR  /  VISÃO GERAL',
                              style: TextStyle(
                                  color: AppTheme.textoSecundario,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 1)),
                          const SizedBox(height: 12),
                          Text(
                              nome.isEmpty
                                  ? 'Seu painel de cuidados'
                                  : 'Olá, $nome',
                              style: GoogleFonts.sourceSerif4(
                                  fontSize: 34, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 6),
                          const Text(
                              'Um olhar sobre quem está sob seus cuidados.',
                              style: TextStyle(
                                  color: AppTheme.textoSecundario,
                                  fontSize: 15)),
                          const SizedBox(height: 16),
                          Wrap(
                              spacing: 12,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                TextButton.icon(
                                    onPressed: _carregando ? null : _carregar,
                                    icon: _carregando
                                        ? const SizedBox(
                                            width: 16,
                                            height: 16,
                                            child: CircularProgressIndicator(
                                                strokeWidth: 2))
                                        : const Icon(Icons.refresh_rounded,
                                            size: 18),
                                    label: Text(_carregando
                                        ? 'Atualizando…'
                                        : 'Atualizar painel')),
                                Text(
                                    _atualizado == null
                                        ? 'Atualização automática a cada 60 s'
                                        : 'Atualizado às ${DateFormat('HH:mm').format(_atualizado!)} • a cada 60 s',
                                    style: const TextStyle(
                                        fontSize: 12,
                                        color: AppTheme.textoSecundario)),
                              ]),
                          if (_canais != null) ...[
                            const SizedBox(height: 4),
                            Row(children: [
                              Icon(
                                  _canais!.isEmpty
                                      ? Icons.notifications_off_outlined
                                      : Icons.forward_to_inbox_outlined,
                                  size: 16,
                                  color: AppTheme.textoSecundario),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                    _canais!.isEmpty
                                        ? 'Avisos de urgência por WhatsApp/SMS: não configurados no servidor.'
                                        : 'Urgências (SOS, alerta crítico, remédio esquecido) também chegam por: ${_canais!.join(', ')}.',
                                    style: const TextStyle(
                                        fontSize: 12,
                                        color: AppTheme.textoSecundario)),
                              ),
                            ]),
                          ],
                          if (_erro != null) ...[
                            const SizedBox(height: 12),
                            Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                    color: const Color(0xFFFFF1E2),
                                    borderRadius: BorderRadius.circular(12)),
                                child: Text(
                                    '$_erro${_resumos == null ? '' : ' Os dados exibidos são da última atualização bem-sucedida.'}',
                                    style: const TextStyle(
                                        color: AppTheme.atencao))),
                          ],
                          const SizedBox(height: 24),
                          if (_resumos != null)
                            SosPendentesBanner(
                                resumos: _resumos!,
                                atendendo: _atendendo,
                                onAtender: _atenderSos),
                          if (_resumos != null) _metricas(),
                          if (_resumos != null) const SizedBox(height: 32),
                          _cabecalhoPacientes(),
                          const SizedBox(height: 20),
                          if (_resumos == null)
                            _carregando
                                ? const Padding(
                                    padding: EdgeInsets.all(60),
                                    child: Center(
                                        child: CircularProgressIndicator()))
                                : _estado('Painel indisponível',
                                    'Tente carregar os dados novamente.',
                                    acao: TextButton(
                                        onPressed: _carregar,
                                        child: const Text('Tentar novamente')))
                          else if (_resumos!.isEmpty)
                            _estado('Seu acompanhamento começa aqui',
                                'Solicite um vínculo pelo e-mail do paciente. Quando ele aceitar, as medições e os alertas aparecerão neste painel.')
                          else ...[
                            _filtros(),
                            const SizedBox(height: 24),
                            LayoutBuilder(builder: (context, espaco) {
                              final lista = _grade(_pacientesFiltrados());
                              final painel = PainelAlertasCuidador(
                                  resumos: _resumos!,
                                  limite: 5,
                                  onVerTodos: _abrirCentral,
                                  onAbrir: (r) =>
                                      _abrirPaciente(r, alertas: true));
                              if (espaco.maxWidth >= 1080) {
                                return Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Expanded(child: lista),
                                      const SizedBox(width: 24),
                                      SizedBox(width: 320, child: painel),
                                    ]);
                              }
                              return Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    lista,
                                    const SizedBox(height: 24),
                                    painel
                                  ]);
                            }),
                          ],
                          const SizedBox(height: 24),
                        ]),
                  )),
                )),
      ),
    );
  }

  Widget _cabecalhoPacientes() => LayoutBuilder(builder: (context, espaco) {
        final titulo =
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Sob seus cuidados',
              style: GoogleFonts.sourceSerif4(
                  fontSize: 26, fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          const Text('Medições e alertas em um só lugar',
              style: TextStyle(fontSize: 14, color: AppTheme.textoSecundario)),
        ]);
        final botao = FilledButton.icon(
            onPressed: _vincularPaciente,
            icon: const Icon(Icons.person_add_alt_1_rounded, size: 19),
            label: const Text('Solicitar vínculo'),
            style: FilledButton.styleFrom(
                minimumSize: const Size(0, 50),
                padding: const EdgeInsets.symmetric(horizontal: 20),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12))));
        if (espaco.maxWidth < 600) {
          return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [titulo, const SizedBox(height: 16), botao]);
        }
        return Row(children: [
          Expanded(child: titulo),
          const SizedBox(width: 16),
          botao
        ]);
      });

  Widget _metricas() {
    final resumos = _resumos!;
    final parcialAlertas = resumos.any((r) => r.alertas == null);
    final parcialHistorico = resumos.any((r) => r.historico == null);
    final pendentes =
        resumos.fold<int>(0, (total, r) => total + r.pendentes.length);
    final semMedicao =
        resumos.where((r) => r.semMedicaoRecente(DateTime.now())).length;
    return LayoutBuilder(builder: (context, espaco) {
      final compacto = espaco.maxWidth < 640 &&
          MediaQuery.textScalerOf(context).scale(14) <= 21;
      final largura = compacto
          ? (espaco.maxWidth - 24) / 3
          : espaco.maxWidth < 640
              ? espaco.maxWidth
              : (espaco.maxWidth - 32) / 3;
      return Wrap(spacing: compacto ? 12 : 16, runSpacing: 12, children: [
        SizedBox(
            width: largura,
            child: _Metrica(
                titulo: compacto ? 'Pacientes' : 'Pacientes monitorados',
                compacto: compacto,
                valor: '${resumos.length}',
                descricao: 'Vínculos ativos com você',
                icone: Icons.people_outline_rounded,
                cor: AppTheme.primaria)),
        SizedBox(
            width: largura,
            child: _Metrica(
                titulo: compacto ? 'Alertas' : 'Alertas pendentes',
                compacto: compacto,
                valor: '${parcialAlertas ? '≥ ' : ''}$pendentes',
                descricao: parcialAlertas
                    ? 'Consulta parcial dos alertas'
                    : 'Ocorrências ainda não resolvidas',
                icone: Icons.notifications_active_outlined,
                cor: AppTheme.alerta)),
        SizedBox(
            width: largura,
            child: _Metrica(
                titulo: compacto ? 'Sem medição\n24 h' : 'Sem medição em 24 h',
                compacto: compacto,
                valor: '${parcialHistorico ? '≥ ' : ''}$semMedicao',
                descricao: parcialHistorico
                    ? 'Consulta parcial das medições'
                    : 'Pacientes sem registros recentes',
                icone: Icons.schedule_rounded,
                cor: AppTheme.atencao)),
      ]);
    });
  }

  Widget _filtros() =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        TextField(
            controller: _busca,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
                labelText: 'Buscar paciente por nome',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: _busca.text.isEmpty
                    ? null
                    : IconButton(
                        tooltip: 'Limpar busca',
                        onPressed: () => setState(() => _busca.clear()),
                        icon: const Icon(Icons.close_rounded)))),
        const SizedBox(height: 14),
        Wrap(spacing: 8, runSpacing: 8, children: [
          ChoiceChip(
              label: Text('Todos (${_resumos!.length})'),
              selected: _filtro == null,
              onSelected: (_) => setState(() => _filtro = null)),
          for (final status in StatusMonitoramento.values)
            ChoiceChip(
                label: Text(
                    '${status.rotulo} (${_resumos!.where((r) => r.status == status).length})'),
                selected: _filtro == status,
                onSelected: (selecionado) =>
                    setState(() => _filtro = selecionado ? status : null)),
        ]),
      ]);

  List<ResumoPaciente> _pacientesFiltrados() => _resumos!
      .where((r) =>
          (_filtro == null || r.status == _filtro) &&
          _normalizar(r.paciente.nome).contains(_normalizar(_busca.text)))
      .toList()
    ..sort((a, b) {
      final prioridade = b.prioridade.compareTo(a.prioridade);
      return prioridade != 0
          ? prioridade
          : a.paciente.nome.compareTo(b.paciente.nome);
    });

  Widget _grade(List<ResumoPaciente> pacientes) {
    if (pacientes.isEmpty) {
      return _estado('Nenhum paciente encontrado',
          'Ajuste a busca ou o filtro para ver outros pacientes.',
          acao: TextButton(
              onPressed: () => setState(() {
                    _busca.clear();
                    _filtro = null;
                  }),
              child: const Text('Limpar filtros')));
    }
    return LayoutBuilder(builder: (context, espaco) {
      final colunas = espaco.maxWidth >= 780 && pacientes.length > 1 ? 2 : 1;
      final largura = (espaco.maxWidth - (colunas - 1) * 16) / colunas;
      return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('${pacientes.length} de ${_resumos!.length} pacientes',
            style:
                const TextStyle(fontSize: 13, color: AppTheme.textoSecundario)),
        const SizedBox(height: 12),
        Wrap(spacing: 16, runSpacing: 16, children: [
          for (final resumo in pacientes)
            SizedBox(
                width: largura,
                child: PacienteMonitoramentoCard(
                    key: ValueKey(resumo.paciente.id),
                    resumo: resumo,
                    onAbrir: () => _abrirPaciente(resumo),
                    onAlertas: () => _abrirPaciente(resumo, alertas: true))),
        ]),
      ]);
    });
  }

  Widget _estado(String titulo, String descricao, {Widget? acao}) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: AppTheme.borda),
            borderRadius: BorderRadius.circular(20)),
        child: Column(children: [
          const Icon(Icons.monitor_heart_outlined,
              size: 36, color: AppTheme.primaria),
          const SizedBox(height: 16),
          Text(titulo,
              textAlign: TextAlign.center,
              style: GoogleFonts.sourceSerif4(
                  fontSize: 23, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 500),
              child: Text(descricao,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      color: AppTheme.textoSecundario, height: 1.6))),
          if (acao != null) ...[const SizedBox(height: 12), acao],
        ]),
      );
}

class _Metrica extends StatelessWidget {
  final String titulo;
  final String valor;
  final String descricao;
  final IconData icone;
  final Color cor;
  final bool compacto;
  const _Metrica(
      {required this.titulo,
      required this.valor,
      required this.descricao,
      required this.icone,
      required this.cor,
      this.compacto = false});
  @override
  Widget build(BuildContext context) => Container(
        padding: EdgeInsets.all(compacto ? 12 : 22),
        decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: AppTheme.borda),
            borderRadius: BorderRadius.circular(16)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          if (compacto) ...[
            Icon(icone, color: cor, size: 19),
            const SizedBox(height: 10),
            Text(valor,
                style: AppTheme.numeroDestaque(fontSize: 28, color: cor)),
            const SizedBox(height: 8),
            SizedBox(
                height: 40,
                child: Text(titulo,
                    style: const TextStyle(
                        fontSize: 12,
                        height: 1.4,
                        color: AppTheme.textoSecundario))),
            if (descricao.startsWith('Consulta parcial'))
              const Text('Parcial',
                  style: TextStyle(fontSize: 11, color: AppTheme.atencao)),
          ] else ...[
            Row(children: [
              Expanded(
                  child: Text(titulo,
                      style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: AppTheme.textoSecundario))),
              const SizedBox(width: 8),
              Icon(icone, color: cor, size: 23),
            ]),
            const SizedBox(height: 16),
            Text(valor,
                style: AppTheme.numeroDestaque(fontSize: 38, color: cor)),
            const SizedBox(height: 10),
            Text(descricao,
                style: const TextStyle(
                    fontSize: 12, color: AppTheme.textoSecundario)),
          ],
        ]),
      );
}
