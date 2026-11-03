import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:flutter/foundation.dart';

import '../models/sessao_usuario.dart';
import '../providers/auth_provider.dart';
import '../services/api_exception.dart';
import '../services/auth_service.dart';
import '../theme/app_brand.dart';
import '../theme/app_theme.dart';
import '../widgets/seniortrack_brand.dart';
import '../widgets/google_access_button.dart';
import 'cadastro_screen.dart';
import 'acesso_codigo_screen.dart';

enum _Ajuste { fonte, contraste, restaurar }

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key, this.authService});
  final AuthService? authService;
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _senhaController = TextEditingController();
  bool _carregando = false;
  bool _mostrarSenha = false;
  bool _fonteAmpliada = false;
  bool _altoContraste = false;
  TipoUsuario _perfil = TipoUsuario.paciente;
  String? _erro;
  final _voz = FlutterTts();
  bool _lendo = false;
  bool _usarBiometria = false;
  bool _codigoDisponivel = false;
  bool _googleDisponivel = false;
  bool _carregandoOpcoes = true;
  bool _falhaOpcoes = false;

  @override
  void initState() {
    super.initState();
    _carregarOpcoes();
    _voz.setCompletionHandler(() {
      if (mounted) setState(() => _lendo = false);
    });
    _voz.setErrorHandler((_) => _erroVoz());
  }

  Future<void> _carregarOpcoes() async {
    setState(() {
      _carregandoOpcoes = true;
      _falhaOpcoes = false;
    });
    try {
      final opcoes = await (widget.authService ?? AuthService()).opcoes();
      if (mounted) {
        setState(() {
          _codigoDisponivel = opcoes['codigo']!;
          _googleDisponivel = opcoes['google']! &&
              GoogleAccessButton.clientId.isNotEmpty &&
              (kIsWeb ||
                  defaultTargetPlatform == TargetPlatform.android ||
                  defaultTargetPlatform == TargetPlatform.iOS ||
                  defaultTargetPlatform == TargetPlatform.macOS);
        });
      }
    } catch (_) {
      if (mounted) setState(() => _falhaOpcoes = true);
    } finally {
      if (mounted) setState(() => _carregandoOpcoes = false);
    }
  }

  void _erroVoz() {
    if (!mounted) return;
    setState(() => _lendo = false);
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content:
            Text('A leitura por voz está indisponível neste dispositivo.')));
  }

  Future<void> _ouvir() async {
    try {
      await _voz.stop();
      if (_lendo) {
        if (mounted) setState(() => _lendo = false);
        return;
      }
      await _voz.setLanguage('pt-BR');
      await _voz.setSpeechRate(0.45);
      if (!mounted) return;
      setState(() => _lendo = true);
      final resultado = await _voz.speak('SeniorTrack. Acesse sua conta. '
          'Perfil ${_perfil == TipoUsuario.paciente ? 'Paciente. Veja suas medições e acompanhe sua rotina.' : 'Cuidador. Acompanhe a rotina dos seus familiares ou pacientes.'} '
          'Informe seu e-mail e sua senha e toque em Entrar. '
          '${_codigoDisponivel ? 'Você também pode entrar com um código por SMS ou WhatsApp. ' : ''}'
          'Para criar uma conta, toque em Criar minha conta. '
          'Para aumentar as letras, use o botão A mais. ${_erro ?? ''}');
      if (resultado == 0) _erroVoz();
    } catch (_) {
      _erroVoz();
    }
  }

  Future<void> _abrirTela(Widget tela) async {
    try {
      await _voz.stop();
    } catch (_) {/* A navegação independe da voz. */}
    if (!mounted) return;
    setState(() => _lendo = false);
    final media = MediaQuery.of(context);
    final tema = Theme.of(context);
    await Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => Theme(
            data: tema.copyWith(
                inputDecorationTheme: tema.inputDecorationTheme.copyWith(
                    focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                            color: AppTheme.primaria, width: 3)),
                    errorMaxLines: 4)),
            child: MediaQuery(
                data: media.copyWith(
                    highContrast: _altoContraste || media.highContrast,
                    textScaler: _fonteAmpliada
                        ? TextScaler.linear(media.textScaler.scale(1) * 1.25)
                        : media.textScaler),
                child: tela))));
  }

  @override
  void dispose() {
    _voz.stop().catchError((_) => 0);
    _emailController.dispose();
    _senhaController.dispose();
    super.dispose();
  }

  Future<void> _entrar() async {
    if (_carregando || !_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _carregando = true;
      _erro = null;
    });
    try {
      await context.read<AuthProvider>().login(
          _emailController.text.trim(), _senhaController.text,
          usarBiometria: _usarBiometria, perfil: _perfil);
      TextInput.finishAutofillContext();
    } on ApiException catch (e) {
      if (mounted) {
        setState(() => _erro = e.statusCode == 401 || e.statusCode == 403
            ? 'E-mail ou senha incorretos. Confira os dados ou toque em “Esqueceu a senha?” para redefinir.'
            : e.mensagem);
      }
    } catch (_) {
      if (mounted) {
        setState(() =>
            _erro = 'Não foi possível conectar ao servidor. Tente novamente.');
      }
    } finally {
      if (mounted) setState(() => _carregando = false);
    }
  }

  Future<void> _google(String token) async {
    if (_carregando || ModalRoute.of(context)?.isCurrent != true) return;
    setState(() {
      _carregando = true;
      _erro = null;
    });
    try {
      await context
          .read<AuthProvider>()
          .entrarComGoogle(token, _perfil, usarBiometria: _usarBiometria);
    } on ApiException catch (e) {
      if (mounted) setState(() => _erro = e.mensagem);
    } catch (_) {
      if (mounted) {
        setState(() =>
            _erro = 'Não foi possível entrar com Google. Tente novamente.');
      }
    } finally {
      if (mounted) setState(() => _carregando = false);
    }
  }

  Future<void> _biometria() async {
    setState(() {
      _carregando = true;
      _erro = null;
    });
    try {
      final entrou = await context.read<AuthProvider>().desbloquearSessao();
      if (!entrou && mounted) {
        setState(() => _erro =
            'A biometria não foi confirmada. Tente novamente ou entre com sua senha.');
      }
    } on ApiException catch (e) {
      if (mounted) setState(() => _erro = e.mensagem);
    } catch (_) {
      if (mounted) {
        setState(() => _erro =
            'Não foi possível verificar a sessão. Confira sua conexão ou entre com sua senha.');
      }
    } finally {
      if (mounted) setState(() => _carregando = false);
    }
  }

  void _ajuda({bool recuperar = false}) {
    showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
              title: Text(recuperar ? 'Recuperar acesso' : 'Ajuda para entrar'),
              content: SingleChildScrollView(
                  child: Text(recuperar
                      ? 'A recuperação por mensagens está indisponível no momento. Tente novamente mais tarde.\n\nSe você lembra sua senha, use o ícone de olho para conferir a digitação antes de entrar.'
                      : 'Use o e-mail e a senha cadastrados no SeniorTrack. Você pode conferir a senha pelo ícone de olho e ampliar os textos em “Acessibilidade”.\n\nSe ainda não tem uma conta, escolha “Criar minha conta”. O perfil da conta define as telas e as permissões após o login.\n\nO canal de suporte será informado quando estiver disponível.')),
              actions: [
                TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Entendi'))
              ],
            ));
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final media = MediaQuery.of(context);
    final contraste = _altoContraste || media.highContrast;
    final corTexto = contraste ? Colors.black : AppTheme.texto;
    final corSecundaria = contraste ? Colors.black : AppTheme.textoSecundario;
    final tema = Theme.of(context).copyWith(
      inputDecorationTheme: Theme.of(context).inputDecorationTheme.copyWith(
            fillColor: Colors.white,
            labelStyle: TextStyle(
                color: corSecundaria,
                fontWeight: FontWeight.w600,
                fontSize: 16),
            floatingLabelStyle: TextStyle(
                color: corTexto, fontWeight: FontWeight.w600, fontSize: 20),
            floatingLabelBehavior: FloatingLabelBehavior.always,
            prefixIconColor: contraste ? Colors.black : AppTheme.primaria,
            suffixIconColor: contraste ? Colors.black : AppTheme.primaria,
            errorMaxLines: 4,
            focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                    color: contraste ? Colors.black : AppTheme.primaria,
                    width: 3)),
            focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppTheme.alerta, width: 3)),
            enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                    color: contraste ? Colors.black : const Color(0xFF8A9C94),
                    width: contraste ? 2 : 1)),
          ),
    );
    return Theme(
        data: tema,
        child: MediaQuery(
          data: media.copyWith(
            highContrast: contraste,
            textScaler: _fonteAmpliada
                ? TextScaler.linear(media.textScaler.scale(1) * 1.25)
                : media.textScaler,
          ),
          child: Scaffold(
            backgroundColor:
                contraste ? const Color(0xFF062B25) : AppTheme.primaria,
            body: SafeArea(
                child: Center(
                    child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 500),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Align(
                          alignment: Alignment.centerRight,
                          child: Wrap(
                              alignment: WrapAlignment.end,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                IconButton(
                                    onPressed: _fonteAmpliada
                                        ? () => setState(
                                            () => _fonteAmpliada = false)
                                        : null,
                                    tooltip: 'Diminuir letras',
                                    color: Colors.white,
                                    disabledColor: Colors.white54,
                                    constraints: const BoxConstraints(
                                        minWidth: 48, minHeight: 48),
                                    icon: Text('A−',
                                        style: TextStyle(
                                            color: _fonteAmpliada ? Colors.white : Colors.white54,
                                            fontSize: 20))),
                                IconButton(
                                    onPressed: !_fonteAmpliada
                                        ? () => setState(
                                            () => _fonteAmpliada = true)
                                        : null,
                                    tooltip: 'Aumentar letras',
                                    color: Colors.white,
                                    constraints: const BoxConstraints(
                                        minWidth: 48, minHeight: 48),
                                    icon: Text('A+',
                                        style: TextStyle(
                                            color: !_fonteAmpliada ? Colors.white : Colors.white54,
                                            fontSize: 20))),
                                IconButton(
                                    onPressed: _ouvir,
                                    tooltip: _lendo
                                        ? 'Parar leitura'
                                        : 'Ouvir instruções de acesso',
                                    color: Colors.white,
                                    isSelected: _lendo,
                                    constraints: const BoxConstraints(
                                        minWidth: 48, minHeight: 48),
                                    icon: Icon(_lendo
                                        ? Icons.stop_circle_outlined
                                        : Icons.volume_up_outlined)),
                                _acessibilidade(),
                              ])),
                      const SizedBox(height: 8),
                      Center(
                          child: SeniorTrackLogo(
                              altura: media.size.width < 400 ? 180 : 220)),
                      const SizedBox(height: 18),
                      const Text(AppBrand.descricao,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: Colors.white,
                              height: 1.5)),
                      const SizedBox(height: 26),
                      Container(
                        padding:
                            EdgeInsets.all(media.size.width < 400 ? 20 : 28),
                        decoration: BoxDecoration(
                          color: contraste ? Colors.white : AppTheme.fundo,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                              color: Colors.white.withValues(alpha: 0.6)),
                          boxShadow: [
                            BoxShadow(
                                color: Colors.black.withValues(alpha: 0.12),
                                blurRadius: 28,
                                offset: const Offset(0, 12))
                          ],
                        ),
                        child: AutofillGroup(
                            child: Form(
                                key: _formKey,
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    Text('Acesse sua conta',
                                        style: GoogleFonts.sourceSerif4(
                                            fontSize: 25,
                                            fontWeight: FontWeight.w600,
                                            color: corTexto)),
                                    const SizedBox(height: 14),
                                    Wrap(spacing: 8, runSpacing: 8, children: [
                                      for (final perfil in TipoUsuario.values)
                                        ChoiceChip(
                                          label: Text(
                                              perfil == TipoUsuario.paciente
                                                  ? 'Paciente'
                                                  : 'Cuidador'),
                                          avatar: Icon(
                                              perfil == TipoUsuario.paciente
                                                  ? Icons.elderly_rounded
                                                  : Icons
                                                      .volunteer_activism_outlined,
                                              size: 20),
                                          selected: _perfil == perfil,
                                          selectedColor:
                                              perfil == TipoUsuario.cuidador
                                                  ? const Color(0xFFEADFC9)
                                                  : const Color(0xFFCFE7E0),
                                          onSelected: _carregando
                                              ? null
                                              : (_) => setState(
                                                  () { _perfil = perfil; _erro = null; }),
                                          labelStyle: TextStyle(
                                              color: corTexto,
                                              fontWeight: FontWeight.w600),
                                          side: BorderSide(
                                              color: contraste
                                                  ? Colors.black
                                                  : const Color(0xFF8A9C94)),
                                        ),
                                    ]),
                                    const SizedBox(height: 10),
                                    Text(
                                        _perfil == TipoUsuario.paciente
                                            ? 'Veja suas medições e acompanhe sua rotina.'
                                            : 'Acesse para acompanhar a rotina dos seus familiares ou pacientes.',
                                        style: TextStyle(
                                            fontSize: 14,
                                            height: 1.4,
                                            color: corSecundaria)),
                                    const SizedBox(height: 24),
                                    if (auth.status ==
                                        StatusAuth.bloqueado) ...[
                                      OutlinedButton.icon(
                                          onPressed:
                                              _carregando ? null : _biometria,
                                          icon: const Icon(Icons.fingerprint),
                                          label: const Text(
                                              'Entrar com biometria')),
                                      const SizedBox(height: 12),
                                      const Text(
                                          'Sua sessão está protegida neste aparelho. Você também pode entrar com sua senha.'),
                                      const SizedBox(height: 24),
                                    ],
                                    if (_erro != null) ...[
                                      Semantics(
                                          liveRegion: true,
                                          child: Container(
                                            padding: const EdgeInsets.all(14),
                                            decoration: BoxDecoration(
                                                color: const Color(0xFFFFECE7),
                                                borderRadius:
                                                    BorderRadius.circular(10)),
                                            child: Row(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  const Icon(
                                                      Icons.error_outline,
                                                      color: AppTheme.alerta,
                                                      size: 21),
                                                  const SizedBox(width: 10),
                                                  Expanded(
                                                      child: Text(_erro!,
                                                          style: TextStyle(
                                                              color: contraste
                                                                  ? Colors.black
                                                                  : AppTheme
                                                                      .alerta,
                                                              fontSize: 17,
                                                              height: 1.4))),
                                                ]),
                                          )),
                                      const SizedBox(height: 20),
                                    ],
                                    TextFormField(
                                      controller: _emailController,
                                      enabled: !_carregando,
                                      keyboardType: TextInputType.emailAddress,
                                      textInputAction: TextInputAction.next,
                                      autofillHints: const [
                                        AutofillHints.username,
                                        AutofillHints.email
                                      ],
                                      autocorrect: false,
                                      style: TextStyle(
                                          color: corTexto, fontSize: 17),
                                      decoration: const InputDecoration(
                                          labelText: 'E-mail',
                                          prefixIcon:
                                              Icon(Icons.mail_outline_rounded)),
                                      validator: (valor) {
                                        final email = (valor ?? '').trim();
                                        if (email.isEmpty) {
                                          return 'Informe seu e-mail';
                                        }
                                        if (!RegExp(
                                                r'^[^\s@]+@[^\s@]+\.[^\s@]+$')
                                            .hasMatch(email)) {
                                          return 'Informe um e-mail válido';
                                        }
                                        return null;
                                      },
                                    ),
                                    const SizedBox(height: 20),
                                    TextFormField(
                                      controller: _senhaController,
                                      enabled: !_carregando,
                                      obscureText: !_mostrarSenha,
                                      autocorrect: false,
                                      enableSuggestions: false,
                                      autofillHints: const [
                                        AutofillHints.password
                                      ],
                                      textInputAction: TextInputAction.done,
                                      style: TextStyle(
                                          color: corTexto, fontSize: 17),
                                      decoration: InputDecoration(
                                          labelText: 'Senha',
                                          prefixIcon: const Icon(
                                              Icons.lock_outline_rounded),
                                          suffixIcon: IconButton(
                                            tooltip: _mostrarSenha
                                                ? 'Ocultar senha'
                                                : 'Mostrar senha',
                                            isSelected: _mostrarSenha,
                                            onPressed: _carregando
                                                ? null
                                                : () => setState(() =>
                                                    _mostrarSenha =
                                                        !_mostrarSenha),
                                            icon: Icon(_mostrarSenha
                                                ? Icons.visibility_off_outlined
                                                : Icons.visibility_outlined),
                                          )),
                                      validator: (v) => (v == null || v.isEmpty)
                                          ? 'Informe sua senha'
                                          : null,
                                      onFieldSubmitted: (_) => _entrar(),
                                    ),
                                    Align(
                                        alignment: Alignment.centerRight,
                                        child: TextButton(
                                            onPressed: _carregando
                                                ? null
                                                : () => _codigoDisponivel
                                                    ? _abrirTela(
                                                        AcessoCodigoScreen(
                                                            perfil: _perfil,
                                                            recuperar: true))
                                                    : _ajuda(recuperar: true),
                                            style: TextButton.styleFrom(
                                                foregroundColor: contraste
                                                    ? Colors.black
                                                    : AppTheme.primaria),
                                            child: const Text(
                                                'Esqueceu a senha?'))),
                                    const SizedBox(height: 6),
                                    if (auth.biometriaDisponivel) ...[
                                      Material(
                                          type: MaterialType.transparency,
                                          child: CheckboxListTile(
                                              value: _usarBiometria,
                                              onChanged: _carregando
                                                  ? null
                                                  : (v) => setState(() =>
                                                      _usarBiometria =
                                                          v ?? false),
                                              contentPadding: EdgeInsets.zero,
                                              controlAffinity:
                                                  ListTileControlAffinity
                                                      .leading,
                                              title: const Text(
                                                  'Usar biometria neste aparelho'),
                                              subtitle: const Text(
                                                  'Confirme com sua digital ou reconhecimento facial para proteger os próximos acessos.'))),
                                      const SizedBox(height: 12),
                                    ],
                                    ElevatedButton(
                                      onPressed: _carregando ? null : _entrar,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: contraste
                                            ? const Color(0xFF062B25)
                                            : const Color(0xFFF0C674),
                                        foregroundColor: contraste
                                            ? Colors.white
                                            : const Color(0xFF173D35),
                                        elevation: 2,
                                        shadowColor: Colors.black26,
                                        side: BorderSide(
                                            color: contraste
                                                ? Colors.black
                                                : const Color(0xFFB78A3E)),
                                      ),
                                      child: _carregando
                                          ? Semantics(
                                              label: 'Entrando',
                                              liveRegion: true,
                                              child: SizedBox(
                                                  height: 24,
                                                  width: 24,
                                                  child:
                                                      CircularProgressIndicator(
                                                          strokeWidth: 2,
                                                          color: contraste
                                                              ? Colors.white
                                                              : AppTheme
                                                                  .primaria)))
                                          : const Text('Entrar',
                                              style: TextStyle(
                                                  fontSize: 18,
                                                  fontWeight: FontWeight.w700)),
                                    ),
                                    const SizedBox(height: 10),
                                    const Padding(
                                        padding:
                                            EdgeInsets.symmetric(vertical: 16),
                                        child: Row(children: [
                                          Expanded(child: Divider()),
                                          Padding(
                                              padding: EdgeInsets.symmetric(
                                                  horizontal: 12),
                                              child: Text('ou entre com')),
                                          Expanded(child: Divider())
                                        ])),
                                    OutlinedButton.icon(
                                        onPressed:
                                            _carregando || !_codigoDisponivel
                                                ? null
                                                : () => _abrirTela(
                                                    AcessoCodigoScreen(
                                                        perfil: _perfil)),
                                        icon: const Icon(Icons.sms_outlined),
                                        label: const Text(
                                            'Código por SMS ou WhatsApp',
                                            textAlign: TextAlign.center)),
                                    const SizedBox(height: 12),
                                    if (_googleDisponivel)
                                      GoogleAccessButton(
                                          onToken: _google,
                                          enabled: !_carregando,
                                          onError: (mensagem) {
                                            if (mounted) {
                                              setState(() => _erro = mensagem);
                                            }
                                          })
                                    else
                                      const OutlinedButton(
                                          onPressed: null,
                                          child: Text('Entrar com o Google')),
                                    if (_carregandoOpcoes)
                                      const Padding(
                                          padding: EdgeInsets.all(12),
                                          child: Text(
                                              'Consultando formas de acesso…'))
                                    else if (_falhaOpcoes)
                                      TextButton(
                                          onPressed: _carregarOpcoes,
                                          child: const Text(
                                              'Tentar carregar outras formas de acesso'))
                                    else if (!_codigoDisponivel ||
                                        !_googleDisponivel)
                                      Padding(
                                          padding:
                                              const EdgeInsets.only(top: 12),
                                          child: Text(
                                              'Algumas formas de acesso estão indisponíveis no momento.',
                                              style: TextStyle(
                                                  color: corSecundaria,
                                                  fontSize: 14))),
                                    const SizedBox(height: 16),
                                    TextButton(
                                      onPressed: _carregando
                                          ? null
                                          : () => _abrirTela(CadastroScreen(
                                              perfilInicial: _perfil)),
                                      style: TextButton.styleFrom(
                                          foregroundColor: contraste
                                              ? Colors.black
                                              : AppTheme.primaria),
                                      child: const Text('Criar minha conta'),
                                    ),
                                  ],
                                ))),
                      ),
                      const SizedBox(height: 12),
                      Center(
                          child: TextButton.icon(
                        onPressed: () => _ajuda(),
                        icon: const Icon(Icons.help_outline_rounded, size: 20),
                        label: const Text('Precisa de ajuda para acessar?'),
                        style:
                            TextButton.styleFrom(foregroundColor: Colors.white),
                      )),
                    ]),
              ),
            ))),
          ),
        ));
  }

  Widget _acessibilidade() => PopupMenuButton<_Ajuste>(
        tooltip: 'Acessibilidade',
        onSelected: (ajuste) => setState(() {
          switch (ajuste) {
            case _Ajuste.fonte:
              _fonteAmpliada = !_fonteAmpliada;
            case _Ajuste.contraste:
              _altoContraste = !_altoContraste;
            case _Ajuste.restaurar:
              _fonteAmpliada = false;
              _altoContraste = false;
          }
        }),
        itemBuilder: (_) => [
          CheckedPopupMenuItem(
              value: _Ajuste.fonte,
              checked: _fonteAmpliada,
              child: const Text('Ampliar textos')),
          CheckedPopupMenuItem(
              value: _Ajuste.contraste,
              checked: _altoContraste,
              child: const Text('Alto contraste')),
          const PopupMenuItem(
              value: _Ajuste.restaurar, child: Text('Restaurar ajustes')),
        ],
        child: const ExcludeSemantics(
            child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.accessibility_new_rounded,
                      size: 20, color: Colors.white),
                  SizedBox(width: 6),
                  Text('Acessibilidade',
                      style: TextStyle(
                          color: Colors.white, fontWeight: FontWeight.w500)),
                ]))),
      );
}
