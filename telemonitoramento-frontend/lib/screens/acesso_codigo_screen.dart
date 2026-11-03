import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/sessao_usuario.dart';
import '../providers/auth_provider.dart';
import '../services/auth_service.dart';
import '../services/api_exception.dart';
import '../theme/app_theme.dart';

class AcessoCodigoScreen extends StatefulWidget {
  const AcessoCodigoScreen(
      {super.key,
      required this.perfil,
      this.recuperar = false,
      this.authService});
  final AuthService? authService;
  final TipoUsuario perfil;
  final bool recuperar;
  @override
  State<AcessoCodigoScreen> createState() => _AcessoCodigoScreenState();
}

class _AcessoCodigoScreenState extends State<AcessoCodigoScreen> {
  final _form = GlobalKey<FormState>();
  final _telefone = TextEditingController();
  final _codigo = TextEditingController();
  final _senha = TextEditingController();
  final _confirmacao = TextEditingController();
  String _canal = 'whatsapp';
  String? _desafio;
  String? _erro;
  bool _ocupado = false;
  bool _mostrarSenha = false;
  bool _usarBiometria = false;
  int _segundos = 0;
  Timer? _timer;

  @override
  void dispose() {
    _timer?.cancel();
    _telefone.dispose();
    _codigo.dispose();
    _senha.dispose();
    _confirmacao.dispose();
    super.dispose();
  }

  Future<void> _executar(Future<void> Function() acao) async {
    if (_ocupado) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _ocupado = true;
      _erro = null;
    });
    try {
      await acao();
    } on ApiException catch (e) {
      if (mounted) setState(() => _erro = e.mensagem);
    } catch (_) {
      if (mounted) {
        setState(() => _erro =
            'Não foi possível conectar. Confira sua conexão e tente novamente.');
      }
    } finally {
      if (mounted) setState(() => _ocupado = false);
    }
  }

  Future<void> _enviar() async {
    if (_desafio == null && !_form.currentState!.validate()) return;
    await _executar(() async {
      final desafio = await (widget.authService ?? AuthService())
          .solicitarCodigo(_telefone.text, widget.perfil, _canal,
              recuperar: widget.recuperar);
      if (!mounted) return;
      setState(() {
        _desafio = desafio;
        _segundos = 60;
        _codigo.clear();
      });
      _timer?.cancel();
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (!mounted || _segundos <= 1) timer.cancel();
        if (mounted) setState(() => _segundos--);
      });
    });
  }

  Future<void> _confirmar() async {
    if (!_form.currentState!.validate()) return;
    await _executar(() async {
      await context.read<AuthProvider>().confirmarCodigo(
          _desafio!, _codigo.text,
          novaSenha: widget.recuperar ? _senha.text : null,
          usarBiometria: _usarBiometria);
      TextInput.finishAutofillContext();
      if (mounted) Navigator.of(context).pop();
    });
  }

  @override
  Widget build(BuildContext context) {
    final enviado = _desafio != null;
    return Scaffold(
      appBar: AppBar(
          title: Text(widget.recuperar
              ? 'Recuperar minha senha'
              : 'Entrar com código')),
      body: SafeArea(
          child: Center(
              child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: AutofillGroup(
                child: Form(
                    key: _form,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Icon(
                            enviado
                                ? Icons.mark_chat_read_outlined
                                : Icons.phone_android,
                            size: 44,
                            color: AppTheme.primaria),
                        const SizedBox(height: 16),
                        Text(
                            enviado
                                ? 'Confira suas mensagens'
                                : 'Use seu celular cadastrado',
                            style: Theme.of(context).textTheme.headlineSmall),
                        const SizedBox(height: 12),
                        Text(
                            'Perfil: ${widget.perfil == TipoUsuario.paciente ? 'Paciente' : 'Cuidador'}. '
                            '${enviado ? 'Se o celular estiver cadastrado neste perfil, enviaremos um código de seis dígitos por ${_canal == 'sms' ? 'SMS' : 'WhatsApp'} para ${_telefone.text}. O código vale por 10 minutos.' : 'Informe o número que você usou ao criar a conta, incluindo o DDD.'}'),
                        const SizedBox(height: 24),
                        if (_erro != null) ...[
                          Semantics(
                              liveRegion: true,
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                color: const Color(0xFFFFECE7),
                                child: Text(_erro!,
                                    style: const TextStyle(
                                        color: AppTheme.alerta, fontSize: 17)),
                              )),
                          const SizedBox(height: 20),
                        ],
                        if (!enviado) ...[
                          TextFormField(
                              controller: _telefone,
                              enabled: !_ocupado,
                              keyboardType: TextInputType.phone,
                              autofillHints: const [
                                AutofillHints.telephoneNumber
                              ],
                              decoration: const InputDecoration(
                                  labelText: 'Celular com DDD',
                                  hintText: '(11) 99999-9999',
                                  prefixIcon: Icon(Icons.phone_outlined)),
                              validator: (v) {
                                final n =
                                    (v ?? '').replaceAll(RegExp(r'\D'), '');
                                return RegExp(r'^(55)?[1-9][0-9]{9,10}$')
                                        .hasMatch(n)
                                    ? null
                                    : 'Informe um celular com DDD.';
                              }),
                          const SizedBox(height: 16),
                          const Text('Como deseja receber o código?'),
                          RadioGroup<String>(
                              groupValue: _canal,
                              onChanged: (v) {
                                if (!_ocupado && v != null) {
                                  setState(() => _canal = v);
                                }
                              },
                              child: const Column(children: [
                                RadioListTile<String>(
                                    value: 'whatsapp', title: Text('WhatsApp')),
                                RadioListTile<String>(
                                    value: 'sms', title: Text('SMS')),
                              ])),
                        ] else ...[
                          TextFormField(
                              controller: _codigo,
                              enabled: !_ocupado,
                              autofocus: true,
                              keyboardType: TextInputType.number,
                              autofillHints: const [AutofillHints.oneTimeCode],
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                                LengthLimitingTextInputFormatter(6)
                              ],
                              style: const TextStyle(
                                  fontSize: 26, letterSpacing: 6),
                              decoration: const InputDecoration(
                                  labelText: 'Código de 6 dígitos',
                                  prefixIcon: Icon(Icons.pin_outlined)),
                              validator: (v) =>
                                  RegExp(r'^\d{6}$').hasMatch(v ?? '')
                                      ? null
                                      : 'Digite os seis números recebidos.'),
                          if (widget.recuperar) ...[
                            const SizedBox(height: 24),
                            TextFormField(
                                controller: _senha,
                                enabled: !_ocupado,
                                obscureText: !_mostrarSenha,
                                autofillHints: const [
                                  AutofillHints.newPassword
                                ],
                                decoration: InputDecoration(
                                    labelText: 'Nova senha',
                                    helperText: 'Use de 8 a 72 caracteres.',
                                    suffixIcon: IconButton(
                                        onPressed: () => setState(() =>
                                            _mostrarSenha = !_mostrarSenha),
                                        tooltip: _mostrarSenha
                                            ? 'Ocultar senha'
                                            : 'Mostrar senha',
                                        icon: Icon(_mostrarSenha
                                            ? Icons.visibility_off
                                            : Icons.visibility))),
                                validator: (v) =>
                                    v == null || v.length < 8 || v.length > 72
                                        ? 'Use de 8 a 72 caracteres.'
                                        : null),
                            const SizedBox(height: 20),
                            TextFormField(
                                controller: _confirmacao,
                                enabled: !_ocupado,
                                obscureText: !_mostrarSenha,
                                autofillHints: const [
                                  AutofillHints.newPassword
                                ],
                                decoration: const InputDecoration(
                                    labelText: 'Repita a nova senha'),
                                validator: (v) => v != _senha.text
                                    ? 'As senhas precisam ser iguais.'
                                    : null),
                          ],
                        ],
                        const SizedBox(height: 24),
                        if (enviado &&
                            context.watch<AuthProvider>().biometriaDisponivel)
                          CheckboxListTile(
                              value: _usarBiometria,
                              onChanged: _ocupado
                                  ? null
                                  : (v) => setState(
                                      () => _usarBiometria = v ?? false),
                              contentPadding: EdgeInsets.zero,
                              controlAffinity: ListTileControlAffinity.leading,
                              title:
                                  const Text('Usar biometria neste aparelho'),
                              subtitle: const Text(
                                  'Proteja seus próximos acessos com sua digital ou reconhecimento facial.')),
                        ElevatedButton(
                            onPressed: _ocupado
                                ? null
                                : enviado
                                    ? _confirmar
                                    : _enviar,
                            child: _ocupado
                                ? const SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2))
                                : Text(enviado
                                    ? widget.recuperar
                                        ? 'Salvar senha e entrar'
                                        : 'Confirmar e entrar'
                                    : 'Enviar código')),
                        if (enviado) ...[
                          const SizedBox(height: 12),
                          TextButton(
                              onPressed:
                                  _ocupado || _segundos > 0 ? null : _enviar,
                              child: Text(_segundos > 0
                                  ? 'Reenviar código em ${_segundos}s'
                                  : 'Reenviar código')),
                          TextButton(
                              onPressed: _ocupado
                                  ? null
                                  : () {
                                      _timer?.cancel();
                                      setState(() {
                                        _desafio = null;
                                        _erro = null;
                                        _codigo.clear();
                                        _senha.clear();
                                        _confirmacao.clear();
                                      });
                                    },
                              child: const Text(
                                  'Alterar celular ou forma de envio')),
                        ],
                        TextButton(
                            onPressed: _ocupado
                                ? null
                                : () => Navigator.of(context).pop(),
                            child: const Text('Voltar para e-mail e senha')),
                      ],
                    )))),
      ))),
    );
  }
}
