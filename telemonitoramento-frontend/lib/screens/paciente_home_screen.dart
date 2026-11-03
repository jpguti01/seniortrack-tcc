import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/alerta.dart';
import '../models/bem_estar.dart';
import '../models/historico_paciente.dart';
import '../models/limiar.dart';
import '../models/medicamento.dart';
import '../models/paciente.dart';
import '../models/sinal_vital.dart';
import '../models/solicitacao_vinculo.dart';
import '../models/tipo_sinal_vital.dart';
import '../providers/auth_provider.dart';
import '../services/alerta_service.dart';
import '../services/api_exception.dart';
import '../services/bem_estar_service.dart';
import '../services/limiar_service.dart';
import '../services/medicamento_service.dart';
import '../services/paciente_service.dart';
import '../services/preferencias_service.dart';
import '../services/relatorio_paciente_service.dart';
import '../services/sinal_vital_service.dart';
import '../services/sos_service.dart';
import '../theme/app_brand.dart';
import '../theme/app_theme.dart';
import '../utils/telefone.dart';
import '../widgets/alerta_card.dart';
import '../widgets/barra_medicao_simples.dart';
import '../widgets/botao_sos.dart';
import '../widgets/checkin_bem_estar_card.dart';
import '../widgets/evolucao_paciente_card.dart';
import '../widgets/paciente_registro_card.dart';
import '../widgets/registrar_sinal_vital_dialog.dart';
import '../widgets/remedios_do_dia_card.dart';
import '../widgets/sinal_vital_card.dart';
import '../widgets/seniortrack_brand.dart';
import '../widgets/solicitacao_vinculo_card.dart';
import 'convite_cuidador_screen.dart';

class PacienteHomeScreen extends StatefulWidget {
  const PacienteHomeScreen({super.key});
  @override
  State<PacienteHomeScreen> createState() => _PacienteHomeScreenState();
}

class _PacienteHomeScreenState extends State<PacienteHomeScreen> {
  final _sinais = SinalVitalService();
  final _alertaService = AlertaService();
  final _pacientes = PacienteService();
  final _voz = FlutterTts();
  final _sos = SosService();
  final _remedios = MedicamentoService();
  final _bemEstar = BemEstarService();
  final _limiarService = LimiarService();
  final _preferencias = PreferenciasService();
  late Future<List<SinalVital>> _historico;
  late Future<List<Alerta>> _alertas;
  late Future<List<SolicitacaoVinculo>> _solicitacoes;
  late Future<Paciente> _perfil;
  late Future<List<Dose>> _doses;
  late Future<List<Medicamento>> _medicamentos;
  late Future<CheckinBemEstar?> _checkinHoje;
  late Future<List<Limiar>> _limiares;
  late final Timer _timer;
  final _respondendo = <int>{};
  final _confirmandoDose = <String>{};
  bool _pedindoAjuda = false;
  bool _respondendoHumor = false;
  // Modo idoso: só o essencial, em botões grandes. O painel completo
  // (histórico, gráficos, PDF) fica a um toque, no topo da tela.
  bool _modoSimples = true;
  bool _atualizando = false;
  Completer<void>? _cargaAtual;
  bool _exportando = false;
  int? _dias = 7;
  TipoSinalVital? _tipo;
  int _limite = 10;

  @override
  void initState() {
    super.initState();
    _voz.setErrorHandler((_) =>
        _aviso('A leitura por voz está indisponível neste dispositivo.'));
    _preferencias.modoSimples().then((ativo) {
      if (mounted) setState(() => _modoSimples = ativo);
    });
    _carregar();
    _timer = Timer.periodic(const Duration(seconds: 60), (_) {
      if (ModalRoute.of(context)?.isCurrent != true) return;
      final ciclo = WidgetsBinding.instance.lifecycleState;
      if (ciclo == null || ciclo == AppLifecycleState.resumed) _carregar();
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    _voz.stop();
    super.dispose();
  }

  Future<void> _aguardar(Future<Object?> consulta) async {
    try {
      await consulta;
    } catch (_) {/* O FutureBuilder da seção apresenta o erro. */}
  }

  Future<void> _carregar({bool garantirNovaConsulta = false}) async {
    if (!mounted) return;
    if (_atualizando) {
      await _cargaAtual!.future;
      if (garantirNovaConsulta && mounted) await _carregar();
      return;
    }
    final carga = Completer<void>();
    _cargaAtual = carga;
    final id = context.read<AuthProvider>().sessao!.id;
    setState(() {
      _atualizando = true;
      _historico =
          _sinais.listarPorPaciente(id).timeout(const Duration(seconds: 12));
      _alertas = _alertaService
          .listarPorPaciente(id)
          .timeout(const Duration(seconds: 12));
      _solicitacoes = _pacientes
          .listarSolicitacoesPendentes()
          .timeout(const Duration(seconds: 12));
      _perfil = _pacientes.buscarPorId(id).timeout(const Duration(seconds: 12));
      _doses = _remedios.dosesDeHoje(id).timeout(const Duration(seconds: 12));
      _medicamentos =
          _remedios.listarPorPaciente(id).timeout(const Duration(seconds: 12));
      _checkinHoje = _bemEstar.deHoje(id).timeout(const Duration(seconds: 12));
      _limiares = _limiarService
          .listarPorPaciente(id)
          .timeout(const Duration(seconds: 12));
    });
    await Future.wait([
      _aguardar(_historico),
      _aguardar(_alertas),
      _aguardar(_solicitacoes),
      _aguardar(_perfil),
      _aguardar(_doses),
      _aguardar(_medicamentos),
      _aguardar(_checkinHoje),
      _aguardar(_limiares),
    ]);
    if (mounted) setState(() => _atualizando = false);
    carga.complete();
  }

  void _aviso(String mensagem) {
    if (mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(mensagem)));
    }
  }

  Future<void> _registrar(TipoSinalVital tipo) async {
    final salvou = await abrirDialogoRegistrarSinalVital(context, tipo);
    if (salvou == true && mounted) {
      _aviso('${tipo.rotulo}: registro salvo com sucesso.');
      await _carregar(garantirNovaConsulta: true);
    }
  }

  Future<void> _responder(int id, bool aceitar) async {
    if (_respondendo.contains(id)) return;
    setState(() => _respondendo.add(id));
    try {
      if (aceitar) {
        await _pacientes.aceitarSolicitacao(id);
      } else {
        await _pacientes.recusarSolicitacao(id);
      }
      if (mounted) {
        _aviso(aceitar
            ? 'Cuidador vinculado com sucesso.'
            : 'Solicitação recusada.');
        await _carregar(garantirNovaConsulta: true);
      }
    } catch (_) {
      _aviso('Não foi possível responder à solicitação. Tente novamente.');
    } finally {
      if (mounted) setState(() => _respondendo.remove(id));
    }
  }

  Future<void> _ouvir(Alerta alerta) async {
    try {
      await _voz.stop();
      await _voz.setLanguage('pt-BR');
      final resultado = await _voz.speak(
          '${alerta.titulo}. ${alerta.medicao}. ${alerta.mensagemLegivel}');
      if (resultado == 0) throw StateError('Voz indisponível');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: const Text('Leitura do alerta solicitada.'),
        duration: const Duration(seconds: 15),
        action: SnackBarAction(
            label: 'Parar',
            onPressed: () {
              _voz.stop();
            }),
      ));
    } catch (_) {
      _aviso('A leitura por voz está indisponível neste dispositivo.');
    }
  }

  Future<void> _exportar(List<SinalVital> registros) async {
    if (_exportando || registros.isEmpty) return;
    setState(() => _exportando = true);
    try {
      final agora = DateTime.now();
      final nome = context.read<AuthProvider>().sessao!.nome;
      final periodo =
          '${_dias == null ? 'Todo o histórico' : 'Últimos $_dias dias'} • ${_tipo?.rotulo ?? 'Todos os sinais'}';
      final bytes = await RelatorioPacienteService().gerar(
          nome: nome, periodo: periodo, registros: registros, emitidoEm: agora);
      await Printing.sharePdf(
          bytes: bytes,
          filename:
              '${AppBrand.nome}-historico-${DateFormat('yyyyMMdd').format(agora)}.pdf');
    } catch (_) {
      _aviso('Não foi possível exportar o PDF. Tente novamente.');
    } finally {
      if (mounted) setState(() => _exportando = false);
    }
  }

  Future<void> _pedirAjuda() async {
    setState(() => _pedindoAjuda = true);
    try {
      final chamado = await _sos.acionar();
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          icon: const Icon(Icons.check_circle_rounded,
              color: AppTheme.sucesso, size: 44),
          title: const Text('Seu cuidador foi avisado'),
          content: Text(
              'Pedido enviado às ${DateFormat('HH:mm').format(chamado.criadoEm.toLocal())}. Em uma emergência, ligue também para o SAMU (192).',
              style: const TextStyle(fontSize: 17, height: 1.4)),
          actionsOverflowButtonSpacing: 8,
          actions: [
            TextButton.icon(
                onPressed: () => _ligar('192'),
                icon: const Icon(Icons.local_hospital_outlined),
                label: const Text('Ligar 192')),
            TextButton.icon(
                onPressed: () {
                  Navigator.of(dialogContext).pop();
                  _mostrarPerfil(contato: true);
                },
                icon: const Icon(Icons.phone_outlined),
                label: const Text('Falar com cuidador')),
            FilledButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: const Text('Entendi')),
          ],
        ),
      );
    } catch (_) {
      _aviso(
          'Não foi possível avisar pelo app. Ligue para seu cuidador ou para o SAMU (192).');
    } finally {
      if (mounted) setState(() => _pedindoAjuda = false);
    }
  }

  Future<void> _tomei(Dose dose) async {
    if (_confirmandoDose.contains(dose.chave)) return;
    setState(() => _confirmandoDose.add(dose.chave));
    try {
      await _remedios.confirmarTomada(dose.medicamentoId, dose.horario);
      if (!mounted) return;
      _aviso('Anotado: ${dose.nome} das ${dose.horario}.');
      final id = context.read<AuthProvider>().sessao!.id;
      final doses = _remedios.dosesDeHoje(id);
      setState(() => _doses = doses);
      await _aguardar(doses);
    } on ApiException catch (e) {
      _aviso(e.mensagem);
    } catch (_) {
      _aviso('Não foi possível anotar o remédio. Tente novamente.');
    } finally {
      if (mounted) setState(() => _confirmandoDose.remove(dose.chave));
    }
  }

  Future<void> _responderBemEstar(Humor humor) async {
    String? observacao;
    if (humor.preocupante) {
      observacao = await _perguntarObservacao(humor);
      if (observacao == null) return;
    }
    setState(() => _respondendoHumor = true);
    try {
      final checkin = await _bemEstar.registrar(humor, observacao: observacao);
      if (!mounted) return;
      setState(() => _checkinHoje = Future.value(checkin));
      _aviso(humor.preocupante
          ? 'Obrigado por contar. Seu cuidador foi avisado.'
          : 'Obrigado! Sua resposta de hoje foi salva.');
    } on ApiException catch (e) {
      _aviso(e.mensagem);
    } catch (_) {
      _aviso('Não foi possível salvar sua resposta. Tente novamente.');
    } finally {
      if (mounted) setState(() => _respondendoHumor = false);
    }
  }

  // Devolve null se o paciente cancelar; texto vazio se não quiser detalhar.
  Future<String?> _perguntarObservacao(Humor humor) {
    final texto = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        icon: Icon(humor.icone, color: humor.cor, size: 40),
        title: Text('Você está ${humor.rotulo.toLowerCase()}'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          const Text('Quer contar mais ao seu cuidador? (opcional)',
              style: TextStyle(fontSize: 16)),
          const SizedBox(height: 12),
          TextField(
              controller: texto,
              maxLength: 255,
              maxLines: 3,
              minLines: 1,
              decoration: const InputDecoration(
                  hintText: 'Ex.: dor nas costas desde cedo',
                  counterText: '')),
        ]),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancelar')),
          FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(texto.text),
              child: const Text('Enviar')),
        ],
      ),
    ).whenComplete(texto.dispose);
  }

  void _alternarModo() {
    setState(() => _modoSimples = !_modoSimples);
    _preferencias.definirModoSimples(_modoSimples);
  }

  Future<void> _abrirWhatsApp(Uri link) async {
    try {
      if (!await launchUrl(link, mode: LaunchMode.externalApplication)) {
        _aviso('Não foi possível abrir o WhatsApp.');
      }
    } catch (_) {
      _aviso('Não foi possível abrir o WhatsApp.');
    }
  }

  Future<void> _ligar(String telefone) async {
    try {
      final numero = telefone.replaceAll(RegExp(r'[^0-9+]'), '');
      if (numero.isEmpty ||
          !await launchUrl(Uri(scheme: 'tel', path: numero))) {
        _aviso(
            'Não foi possível abrir o telefone. Use a opção de copiar o número.');
      }
    } catch (_) {
      _aviso(
          'Não foi possível abrir o telefone. Use a opção de copiar o número.');
    }
  }

  void _mostrarPerfil({bool contato = false}) {
    showDialog<void>(
        context: context,
        builder: (dialogContext) => AlertDialog(
              title: Text(contato ? 'Contato do cuidador' : 'Minha conta'),
              content: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: SingleChildScrollView(
                    child: FutureBuilder<Paciente>(
                        future: _perfil,
                        builder: (_, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Center(
                                child: CircularProgressIndicator());
                          }
                          if (snapshot.hasError || snapshot.data == null) {
                            return const Text(
                                'Não foi possível consultar o perfil. Atualize o painel e tente novamente.');
                          }
                          final paciente = snapshot.data!;
                          final cuidador = paciente.cuidador;
                          final telefone = cuidador?.telefone?.trim() ?? '';
                          return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (!contato) ...[
                                  Text(paciente.nome,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 20)),
                                  const SizedBox(height: 8),
                                  Text(paciente.email),
                                  const SizedBox(height: 8),
                                  Text(
                                      '${paciente.idade} anos • Perfil paciente'),
                                  const Divider(height: 30),
                                ],
                                Text(
                                    cuidador?.nome ??
                                        'Nenhum cuidador vinculado',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w600)),
                                const SizedBox(height: 10),
                                if (cuidador == null) ...[
                                  OutlinedButton.icon(
                                    onPressed: () {
                                      Navigator.of(dialogContext).pop();
                                      Navigator.of(context).push(MaterialPageRoute(
                                        builder: (_) => const ConviteCuidadorScreen()));
                                    },
                                    icon: const Icon(Icons.qr_code),
                                    label: const Text('Convidar meu cuidador')),
                                  const SizedBox(height: 12),
                                ],
                                if (telefone.isEmpty)
                                  Text(cuidador == null
                                      ? 'Seu cuidador pode solicitar o vínculo pelo seu e-mail. Você aceita o pedido neste painel.'
                                      : 'O cuidador ainda não tem um telefone informado no cadastro.')
                                else ...[
                                  Text(telefone,
                                      style: const TextStyle(fontSize: 20)),
                                  const SizedBox(height: 16),
                                  FilledButton.icon(
                                      onPressed: () => _ligar(telefone),
                                      icon: const Icon(Icons.phone_outlined),
                                      label: const Text('Ligar'),
                                      style: FilledButton.styleFrom(
                                          minimumSize: const Size(0, 48))),
                                  if (linkWhatsApp(telefone) != null) ...[
                                    const SizedBox(height: 8),
                                    OutlinedButton.icon(
                                        onPressed: () => _abrirWhatsApp(
                                            linkWhatsApp(telefone,
                                                mensagem:
                                                    'Olá, ${cuidador!.nome.split(' ').first}! Aqui é ${paciente.nome.split(' ').first}, pelo ${AppBrand.nome}.')!),
                                        icon: const Icon(
                                            Icons.chat_outlined),
                                        label: const Text(
                                            'Mandar mensagem no WhatsApp'),
                                        style: OutlinedButton.styleFrom(
                                            minimumSize: const Size(0, 48))),
                                  ],
                                  TextButton.icon(
                                      onPressed: () async {
                                        await Clipboard.setData(
                                            ClipboardData(text: telefone));
                                        _aviso('Telefone copiado.');
                                      },
                                      icon: const Icon(Icons.copy_outlined,
                                          size: 18),
                                      label: const Text('Copiar telefone')),
                                ],
                              ]);
                        }),
                  )),
              actions: [
                if (!contato)
                  TextButton.icon(
                      onPressed: () {
                        Navigator.of(dialogContext).pop();
                        context.read<AuthProvider>().logout();
                      },
                      icon: const Icon(Icons.logout_rounded, size: 18),
                      label: const Text('Sair da conta')),
                TextButton(
                    onPressed: () => Navigator.of(dialogContext).pop(),
                    child: const Text('Fechar')),
              ],
            ));
  }

  void _abrirAlertas() => showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        showDragHandle: true,
        builder: (context) => SafeArea(
            child: ConstrainedBox(
          constraints:
              BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * .8),
          child: SingleChildScrollView(
              padding: const EdgeInsets.all(16), child: _painelAlertas()),
        )),
      );

  @override
  Widget build(BuildContext context) {
    final nome =
        context.watch<AuthProvider>().sessao?.nome.split(' ').first ?? '';
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 72,
        titleSpacing: 20,
        title: const SeniorTrackHeader(),
        actions: [
          IconButton(
              onPressed: _alternarModo,
              tooltip:
                  _modoSimples ? 'Ver painel completo' : 'Usar o modo simples',
              icon: Icon(_modoSimples
                  ? Icons.dashboard_outlined
                  : Icons.accessibility_new_rounded)),
          FutureBuilder<List<Alerta>>(
              future: _alertas,
              builder: (_, snapshot) {
                final total =
                    snapshot.data?.where((a) => !a.resolvido).length ?? 0;
                return IconButton(
                    onPressed: _abrirAlertas,
                    tooltip: 'Meus alertas',
                    icon: Badge(
                        isLabelVisible: total > 0,
                        label: Text('$total'),
                        child: const Icon(Icons.notifications_outlined)));
              }),
          IconButton(
              onPressed: _mostrarPerfil,
              tooltip: 'Minha conta',
              icon: const Icon(Icons.account_circle_outlined)),
          const SizedBox(width: 8),
        ],
      ),
      body: RefreshIndicator(
          onRefresh: _carregar,
          child: LayoutBuilder(
              builder: (context, espaco) => SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: EdgeInsets.all(espaco.maxWidth < 600 ? 16 : 32),
                    child: Center(
                        child: ConstrainedBox(
                      constraints: BoxConstraints(
                          maxWidth: _modoSimples ? 720 : 1380),
                      child: _modoSimples
                          ? _conteudoSimples(nome)
                          : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                                'ÁREA DO PACIENTE  /  MEU ACOMPANHAMENTO',
                                style: TextStyle(
                                    fontSize: 11,
                                    letterSpacing: .8,
                                    color: AppTheme.textoSecundario,
                                    fontWeight: FontWeight.w600)),
                            const SizedBox(height: 12),
                            Wrap(
                                spacing: 24,
                                runSpacing: 12,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                children: [
                                  Text('Olá, $nome',
                                      style: GoogleFonts.sourceSerif4(
                                          fontSize: 34,
                                          fontWeight: FontWeight.w600)),
                                  OutlinedButton.icon(
                                      onPressed: () =>
                                          _mostrarPerfil(contato: true),
                                      icon: const Icon(Icons.phone_outlined,
                                          size: 20),
                                      label: const Text('Falar com cuidador'),
                                      style: OutlinedButton.styleFrom(
                                          minimumSize: const Size(0, 48),
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 16))),
                                  BotaoSos(
                                      onConfirmar: _pedirAjuda,
                                      enviando: _pedindoAjuda),
                                ]),
                            const SizedBox(height: 8),
                            const Text(
                                'Seus registros, sua rotina e quem cuida de você.',
                                style: TextStyle(
                                    fontSize: 15,
                                    color: AppTheme.textoSecundario)),
                            const SizedBox(height: 12),
                            Wrap(
                                spacing: 12,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                children: [
                                  TextButton.icon(
                                      onPressed:
                                          _atualizando ? null : _carregar,
                                      icon: _atualizando
                                          ? const SizedBox(
                                              width: 16,
                                              height: 16,
                                              child: CircularProgressIndicator(
                                                  strokeWidth: 2))
                                          : const Icon(Icons.refresh_rounded,
                                              size: 20),
                                      label: Text(_atualizando
                                          ? 'Atualizando…'
                                          : 'Atualizar painel')),
                                  const Text(
                                      'Atualização automática a cada 60 s',
                                      style: TextStyle(
                                          fontSize: 12,
                                          color: AppTheme.textoSecundario)),
                                ]),
                            const SizedBox(height: 20),
                            _solicitacoesPendentes(),
                            FutureBuilder<List<SinalVital>>(
                                future: _historico,
                                builder: (_, snapshot) {
                                  final dados =
                                      snapshot.hasError ? null : snapshot.data;
                                  final hoje = dados == null
                                      ? null
                                      : HistoricoPaciente(dados)
                                          .tiposHoje(DateTime.now());
                                  return _caixa(Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Row(children: [
                                          Icon(Icons.today_outlined,
                                              color: AppTheme.primaria,
                                              size: 22),
                                          SizedBox(width: 10),
                                          Expanded(
                                              child: Text(
                                                  'Seus registros de hoje',
                                                  style: TextStyle(
                                                      fontSize: 17,
                                                      fontWeight:
                                                          FontWeight.w600))),
                                        ]),
                                        const SizedBox(height: 12),
                                        Text(
                                            hoje == null
                                                ? (snapshot.hasError
                                                    ? 'Resumo indisponível no momento'
                                                    : 'Consultando suas medições…')
                                                : '${hoje.length} de ${TipoSinalVital.values.length} tipos registrados hoje',
                                            style: const TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w600)),
                                        if (hoje != null) ...[
                                          const SizedBox(height: 12),
                                          Semantics(
                                              label:
                                                  '${hoje.length} de ${TipoSinalVital.values.length} tipos registrados hoje',
                                              child: LinearProgressIndicator(
                                                  value: hoje.length /
                                                      TipoSinalVital
                                                          .values.length,
                                                  minHeight: 8,
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                  color: AppTheme.primaria,
                                                  backgroundColor:
                                                      AppTheme.borda)),
                                        ],
                                        const SizedBox(height: 10),
                                        const Text(
                                            'O resumo considera os três tipos disponíveis no aplicativo.',
                                            style: TextStyle(
                                                fontSize: 13,
                                                color:
                                                    AppTheme.textoSecundario)),
                                      ]));
                                }),
                            const SizedBox(height: 20),
                            LayoutBuilder(builder: (context, espaco) {
                              if (espaco.maxWidth >= 1050) {
                                return Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Expanded(child: _remediosDoDia()),
                                      const SizedBox(width: 24),
                                      Expanded(child: _checkin()),
                                    ]);
                              }
                              return Column(children: [
                                _remediosDoDia(),
                                const SizedBox(height: 20),
                                _checkin(),
                              ]);
                            }),
                            const SizedBox(height: 26),
                            _titulo('Registrar sinal vital'),
                            const SizedBox(height: 6),
                            const Text(
                                'Escolha uma medição para adicionar um novo registro.',
                                style: TextStyle(
                                    fontSize: 14,
                                    color: AppTheme.textoSecundario)),
                            const SizedBox(height: 16),
                            _registrosRapidos(),
                            const SizedBox(height: 28),
                            LayoutBuilder(builder: (context, tamanho) {
                              if (tamanho.maxWidth >= 1050) {
                                return Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Expanded(
                                          flex: 3, child: _painelHistorico()),
                                      const SizedBox(width: 24),
                                      Expanded(
                                          flex: 2, child: _painelAlertas()),
                                    ]);
                              }
                              return Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    _painelAlertas(),
                                    const SizedBox(height: 24),
                                    _painelHistorico(),
                                  ]);
                            }),
                            const SizedBox(height: 24),
                          ]),
                    )),
                  ))),
    );
  }

  /// Modo idoso: uma coluna só, letras e botões grandes, na ordem do que
  /// mais importa no dia (ajuda, remédios, como está, medir).
  Widget _conteudoSimples(String nome) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Olá, $nome',
                style: GoogleFonts.sourceSerif4(
                    fontSize: 36, fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            const Text('O que você precisa agora?',
                style:
                    TextStyle(fontSize: 19, color: AppTheme.textoSecundario)),
            const SizedBox(height: 20),
            BotaoSos(
                grande: true,
                onConfirmar: _pedirAjuda,
                enviando: _pedindoAjuda),
            const SizedBox(height: 12),
            OutlinedButton.icon(
                onPressed: () => _mostrarPerfil(contato: true),
                icon: const Icon(Icons.phone_outlined, size: 28),
                label: const Text('Falar com meu cuidador'),
                style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(64),
                    textStyle: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.w600))),
            const SizedBox(height: 24),
            _solicitacoesPendentes(),
            _alertasSimples(),
            _remediosDoDia(grande: true, ocultarSeVazio: true),
            _checkin(grande: true),
            const SizedBox(height: 28),
            _titulo('Registrar medição'),
            const SizedBox(height: 12),
            for (final tipo in TipoSinalVital.values)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: FilledButton.icon(
                  onPressed: () => _registrar(tipo),
                  icon: Icon(tipo.icone, size: 30),
                  label: Text(tipo.rotulo),
                  style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(68),
                      alignment: Alignment.centerLeft,
                      padding: const EdgeInsets.symmetric(horizontal: 22),
                      textStyle: const TextStyle(
                          fontSize: 21, fontWeight: FontWeight.w600),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16))),
                ),
              ),
            const SizedBox(height: 16),
            _titulo('Suas últimas medições'),
            const SizedBox(height: 12),
            _medicoesSimples(),
            const SizedBox(height: 12),
            TextButton.icon(
                onPressed: _alternarModo,
                icon: const Icon(Icons.dashboard_outlined),
                label: const Text(
                    'Ver o painel completo (histórico, gráficos e PDF)')),
            const SizedBox(height: 24),
          ]);

  Widget _alertasSimples() => FutureBuilder<List<Alerta>>(
      future: _alertas,
      builder: (_, snapshot) {
        final pendentes = (snapshot.data ?? [])
            .where((a) => !a.resolvido)
            .toList()
          ..sort((a, b) {
            if (a.critico != b.critico) return a.critico ? -1 : 1;
            return b.dataHora.compareTo(a.dataHora);
          });
        if (snapshot.hasError || pendentes.isEmpty) {
          return const SizedBox.shrink();
        }
        return Padding(
          padding: const EdgeInsets.only(bottom: 20),
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _titulo('Avisos importantes'),
                const SizedBox(height: 12),
                for (final alerta in pendentes.take(3))
                  AlertaCard(
                      alerta: alerta,
                      aoOuvir: () => _ouvir(alerta),
                      aoContatar: () => _mostrarPerfil(contato: true)),
                if (pendentes.length > 3)
                  TextButton(
                      onPressed: _abrirAlertas,
                      child: Text('Ver todos os ${pendentes.length} avisos')),
              ]),
        );
      });

  Widget _remediosDoDia({bool grande = false, bool ocultarSeVazio = false}) =>
      FutureBuilder<List<Dose>>(
          future: _doses,
          builder: (_, doses) => FutureBuilder<List<Medicamento>>(
              future: _medicamentos,
              builder: (_, medicamentos) {
                final lista = doses.hasError ? null : doses.data;
                if (ocultarSeVazio &&
                    (lista == null || lista.isEmpty) &&
                    !doses.hasError) {
                  return const SizedBox.shrink();
                }
                final card = RemediosDoDiaCard(
                  doses: lista,
                  erro: doses.hasError,
                  medicamentos: {
                    for (final m in medicamentos.data ?? <Medicamento>[])
                      m.id: m
                  },
                  confirmando: _confirmandoDose,
                  onTomei: _tomei,
                  onTentarDeNovo: _atualizando ? null : _carregar,
                  grande: grande,
                );
                return ocultarSeVazio
                    ? Padding(
                        padding: const EdgeInsets.only(bottom: 20),
                        child: card)
                    : card;
              }));

  Widget _checkin({bool grande = false}) => FutureBuilder<CheckinBemEstar?>(
      future: _checkinHoje,
      builder: (_, snapshot) => CheckinBemEstarCard(
            hoje: snapshot.hasError ? null : snapshot.data,
            carregando: snapshot.connectionState == ConnectionState.waiting,
            erro: snapshot.hasError,
            enviando: _respondendoHumor,
            onResponder: _responderBemEstar,
            grande: grande,
          ));

  Widget _medicoesSimples() => FutureBuilder<List<SinalVital>>(
      future: _historico,
      builder: (_, historico) => FutureBuilder<List<Limiar>>(
          future: _limiares,
          builder: (_, limiares) {
            if (historico.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (historico.hasError) {
              return _estado('Medições indisponíveis',
                  'Não conseguimos consultar suas medições agora.',
                  erro: true);
            }
            final registros = HistoricoPaciente(historico.data ?? [])
                .filtrar(agora: DateTime.now());
            return Column(children: [
              for (final tipo in TipoSinalVital.values)
                BarraMedicaoSimples(
                  tipo: tipo,
                  ultimo: registros.where((r) => r.tipo == tipo).firstOrNull,
                  limiar: (limiares.data ?? <Limiar>[])
                      .where((l) => l.tipo == tipo)
                      .firstOrNull,
                ),
            ]);
          }));

  Widget _registrosRapidos() => FutureBuilder<List<SinalVital>>(
      future: _historico,
      builder: (_, snapshot) {
        final registros =
            HistoricoPaciente(snapshot.hasError ? [] : snapshot.data ?? [])
                .filtrar(agora: DateTime.now());
        return LayoutBuilder(builder: (context, largura) {
          final colunas = largura.maxWidth >= 760 &&
                  MediaQuery.textScalerOf(context).scale(16) < 25
              ? 3
              : 1;
          final tamanho = (largura.maxWidth - 16 * (colunas - 1)) / colunas;
          return Wrap(spacing: 16, runSpacing: 12, children: [
            for (final tipo in TipoSinalVital.values)
              SizedBox(
                  width: tamanho,
                  child: PacienteRegistroCard(
                    compacto: colunas == 1,
                    tipo: tipo,
                    historicoDisponivel: snapshot.hasData && !snapshot.hasError,
                    ultimo: registros.where((r) => r.tipo == tipo).firstOrNull,
                    onRegistrar: () => _registrar(tipo),
                  )),
          ]);
        });
      });

  Widget _solicitacoesPendentes() => FutureBuilder<List<SolicitacaoVinculo>>(
      future: _solicitacoes,
      builder: (_, snapshot) {
        if (snapshot.hasError) {
          return Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: _estado('Solicitações indisponíveis',
                  'Não foi possível consultar seus pedidos de vínculo.',
                  erro: true));
        }
        final dados = snapshot.data ?? [];
        if (dados.isEmpty) return const SizedBox.shrink();
        return Padding(
            padding: const EdgeInsets.only(bottom: 20),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              _titulo('Solicitações de vínculo'),
              const SizedBox(height: 12),
              for (final solicitacao in dados)
                SolicitacaoVinculoCard(
                    solicitacao: solicitacao,
                    processando: _respondendo.contains(solicitacao.id),
                    aoAceitar: () => _responder(solicitacao.id, true),
                    aoRecusar: () => _responder(solicitacao.id, false)),
            ]));
      });

  Widget _painelAlertas() =>
      _caixa(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _titulo('Meus alertas'),
        const SizedBox(height: 6),
        const Text('Ocorrências que precisam da sua atenção',
            style: TextStyle(fontSize: 14, color: AppTheme.textoSecundario)),
        const SizedBox(height: 18),
        FutureBuilder<List<Alerta>>(
            future: _alertas,
            builder: (_, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return _estado('Alertas indisponíveis',
                    'Não conseguimos consultar seus alertas agora.',
                    erro: true);
              }
              final dados = (snapshot.data ?? [])
                  .where((a) => !a.resolvido)
                  .toList()
                ..sort((a, b) => b.dataHora.compareTo(a.dataHora));
              if (dados.isEmpty) {
                return _estado('Nenhum alerta pendente',
                    'As ocorrências registradas aparecerão aqui.',
                    icone: Icons.notifications_none_outlined);
              }
              return Column(children: [
                for (final alerta in dados)
                  AlertaCard(
                      alerta: alerta,
                      aoOuvir: () => _ouvir(alerta),
                      aoContatar: () => _mostrarPerfil(contato: true)),
              ]);
            }),
      ]));

  Widget _painelHistorico() =>
      _caixa(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _titulo('Histórico e evolução'),
        const SizedBox(height: 6),
        const Text('Veja os valores que você registrou ao longo do tempo.',
            style: TextStyle(fontSize: 14, color: AppTheme.textoSecundario)),
        const SizedBox(height: 20),
        Wrap(spacing: 8, runSpacing: 8, children: [
          for (final dias in <int?>[7, 30, null])
            ChoiceChip(
                label: Text(
                    dias == null ? 'Todo o histórico' : 'Últimos $dias dias'),
                selected: _dias == dias,
                onSelected: (_) => setState(() {
                      _dias = dias;
                      _limite = 10;
                    })),
        ]),
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          initialValue: _tipo?.valorApi ?? 'todos',
          decoration:
              const InputDecoration(labelText: 'Filtrar por sinal vital'),
          isExpanded: true,
          items: [
            const DropdownMenuItem(
                value: 'todos', child: Text('Todos os sinais')),
            for (final tipo in TipoSinalVital.values)
              DropdownMenuItem(value: tipo.valorApi, child: Text(tipo.rotulo))
          ],
          onChanged: (valor) => setState(() {
            _tipo = valor == 'todos' ? null : TipoSinalVital.fromApi(valor!);
            _limite = 10;
          }),
        ),
        const SizedBox(height: 20),
        FutureBuilder<List<SinalVital>>(
            future: _historico,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return _estado('Histórico indisponível',
                    'Seus registros não puderam ser carregados. Tente reconectar.',
                    erro: true);
              }
              final dados = HistoricoPaciente(snapshot.data ?? [])
                  .filtrar(agora: DateTime.now(), dias: _dias, tipo: _tipo);
              if (dados.isEmpty) {
                return _estado('Nenhum registro neste período',
                    'Escolha outro período ou registre uma medição pelo painel.',
                    icone: Icons.show_chart_rounded);
              }
              return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    LayoutBuilder(builder: (context, espaco) {
                      final tipos =
                          _tipo == null ? TipoSinalVital.values : [_tipo!];
                      final colunas =
                          espaco.maxWidth >= 640 && tipos.length > 1 ? 3 : 1;
                      final largura =
                          (espaco.maxWidth - 12 * (colunas - 1)) / colunas;
                      return Wrap(spacing: 12, runSpacing: 12, children: [
                        for (final tipo in tipos)
                          SizedBox(
                              width: largura,
                              child: EvolucaoPacienteCard(
                                  tipo: tipo, registros: dados)),
                      ]);
                    }),
                    const SizedBox(height: 20),
                    Wrap(
                        alignment: WrapAlignment.spaceBetween,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 12,
                        runSpacing: 8,
                        children: [
                          Text('${dados.length} registro(s) encontrado(s)',
                              style: const TextStyle(
                                  fontSize: 13,
                                  color: AppTheme.textoSecundario)),
                          OutlinedButton.icon(
                              onPressed:
                                  _exportando ? null : () => _exportar(dados),
                              icon: const Icon(Icons.picture_as_pdf_outlined,
                                  size: 20),
                              label: Text(_exportando
                                  ? 'Preparando PDF…'
                                  : 'Exportar PDF'),
                              style: OutlinedButton.styleFrom(
                                  minimumSize: const Size(0, 48),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 14))),
                        ]),
                    const SizedBox(height: 16),
                    for (final sinal in dados.take(_limite))
                      SinalVitalCard(sinal: sinal),
                    if (dados.length > _limite)
                      TextButton(
                          onPressed: () => setState(() => _limite += 10),
                          child: const Text('Mostrar mais registros')),
                  ]);
            }),
      ]));

  Widget _titulo(String texto) => Text(texto,
      style:
          GoogleFonts.sourceSerif4(fontSize: 24, fontWeight: FontWeight.w600));
  Widget _caixa(Widget child) => Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppTheme.borda)),
      child: child);

  Widget _estado(String titulo, String descricao,
          {bool erro = false, IconData? icone}) =>
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(icone ?? (erro ? Icons.cloud_off_outlined : Icons.info_outline),
              size: 30, color: AppTheme.textoSecundario),
          const SizedBox(height: 12),
          Text(titulo,
              style:
                  const TextStyle(fontWeight: FontWeight.w600, fontSize: 17)),
          const SizedBox(height: 8),
          Text(descricao,
              style: const TextStyle(
                  fontSize: 14, height: 1.5, color: AppTheme.textoSecundario)),
          if (erro) ...[
            const SizedBox(height: 8),
            TextButton.icon(
                onPressed: _atualizando ? null : _carregar,
                icon: const Icon(Icons.refresh_rounded, size: 20),
                label: const Text('Retentar conexão'))
          ],
        ]),
      );
}
