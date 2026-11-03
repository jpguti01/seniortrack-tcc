import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';

import '../providers/auth_provider.dart';
import '../services/api_exception.dart';
import '../theme/app_theme.dart';
import '../theme/app_brand.dart';
import '../models/sessao_usuario.dart';

enum _Perfil { paciente, cuidador }

class CadastroScreen extends StatefulWidget {
  final TipoUsuario perfilInicial;
  const CadastroScreen({super.key, this.perfilInicial = TipoUsuario.paciente});

  @override
  State<CadastroScreen> createState() => _CadastroScreenState();
}

class _CadastroScreenState extends State<CadastroScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nomeController = TextEditingController();
  final _emailController = TextEditingController();
  final _senhaController = TextEditingController();
  final _idadeController = TextEditingController();
  final _telefoneController = TextEditingController();
  final _conviteController = TextEditingController();
  bool _mostrarSenha = false;

  late _Perfil _perfil;
  bool _carregando = false;
  String? _erro;

  @override
  void initState() {
    super.initState();
    _perfil = widget.perfilInicial == TipoUsuario.cuidador
        ? _Perfil.cuidador
        : _Perfil.paciente;
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _emailController.dispose();
    _senhaController.dispose();
    _idadeController.dispose();
    _telefoneController.dispose();
    _conviteController.dispose();
    super.dispose();
  }

  Future<void> _cadastrar() async {
    if (_carregando || !_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _carregando = true;
      _erro = null;
    });
    try {
      final auth = context.read<AuthProvider>();
      final dados = (
        nome: _nomeController.text.trim(),
        email: _emailController.text.trim(),
        senha: _senhaController.text,
        idade: int.tryParse(_idadeController.text) ?? 0,
        telefone: _telefoneController.text.trim(),
      );
      if (_perfil == _Perfil.paciente) {
        await auth.cadastrarPaciente(
          nome: dados.nome,
          email: dados.email,
          senha: dados.senha,
          idade: dados.idade,
          telefone: dados.telefone,
        );
      } else {
        await auth.cadastrarCuidador(
          nome: dados.nome,
          email: dados.email,
          senha: dados.senha,
          idade: dados.idade,
          telefone: dados.telefone,
          codigoConvite: _conviteController.text.trim().isEmpty
              ? null
              : _conviteController.text.trim(),
        );
      }
      TextInput.finishAutofillContext();
      if (mounted) Navigator.of(context).pop();
    } on ApiException catch (e) {
      if (mounted) setState(() => _erro = e.mensagem);
    } catch (e) {
      if (mounted) {
        setState(() =>
            _erro = 'Não foi possível conectar ao servidor. Tente novamente.');
      }
    } finally {
      if (mounted) setState(() => _carregando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Criar conta')),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: AbsorbPointer(
                  absorbing: _carregando,
                  child: AutofillGroup(
                      child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'Como você vai usar o ${AppBrand.nome}?',
                          style: GoogleFonts.workSans(
                              fontSize: 17,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.texto),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Isso define as telas que você vai ver depois de entrar.',
                          style: TextStyle(
                              fontSize: 13,
                              color: AppTheme.texto.withValues(alpha: 0.6)),
                        ),
                        const SizedBox(height: 12),
                        Wrap(spacing: 12, runSpacing: 8, children: [
                          for (final perfil in _Perfil.values)
                            ChoiceChip(
                                selected: _perfil == perfil,
                                avatar: Icon(perfil == _Perfil.paciente
                                    ? Icons.elderly_rounded
                                    : Icons.volunteer_activism_rounded),
                                label: Text(perfil == _Perfil.paciente
                                    ? 'Paciente'
                                    : 'Cuidador'),
                                onSelected: (_) => setState(() {
                                      _perfil = perfil;
                                      _erro = null;
                                    })),
                        ]),
                        const SizedBox(height: 20),
                        Text(_perfil == _Perfil.paciente
                            ? 'Vamos começar com seus dados básicos.'
                            : 'Crie seu acesso para acompanhar familiares ou pacientes. Se recebeu um convite, informe o código abaixo.'),
                        if (_perfil == _Perfil.cuidador) ...[
                          const SizedBox(height: 20),
                          TextFormField(
                              controller: _conviteController,
                              textCapitalization: TextCapitalization.characters,
                              autocorrect: false,
                              enableSuggestions: false,
                              decoration: const InputDecoration(
                                  labelText: 'Código de convite (opcional)',
                                  prefixIcon: Icon(Icons.link),
                                  helperText:
                                      'Peça o código ao paciente. Você também pode vincular depois.',
                                  helperMaxLines: 3),
                              validator: (v) => v == null ||
                                      v.trim().isEmpty ||
                                      RegExp(r'^[A-Fa-f0-9]{20}$').hasMatch(
                                          v.trim().replaceAll('-', ''))
                                  ? null
                                  : 'Confira os 20 caracteres do convite.'),
                        ],
                        const SizedBox(height: 24),
                        if (_erro != null) ...[
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppTheme.alerta.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(_erro!,
                                style: const TextStyle(color: AppTheme.alerta)),
                          ),
                          const SizedBox(height: 16),
                        ],
                        TextFormField(
                          controller: _nomeController,
                          decoration:
                              const InputDecoration(labelText: 'Nome completo'),
                          autofillHints: const [AutofillHints.name],
                          textCapitalization: TextCapitalization.words,
                          textInputAction: TextInputAction.next,
                          validator: (v) => (v == null || v.trim().isEmpty)
                              ? 'Informe seu nome'
                              : null,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          autofillHints: const [AutofillHints.email],
                          autocorrect: false,
                          textInputAction: TextInputAction.next,
                          decoration:
                              const InputDecoration(labelText: 'E-mail'),
                          validator: (v) =>
                              !RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$')
                                      .hasMatch((v ?? '').trim())
                                  ? 'Informe um e-mail válido'
                                  : null,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _senhaController,
                          obscureText: !_mostrarSenha,
                          autofillHints: const [AutofillHints.newPassword],
                          textInputAction: TextInputAction.next,
                          decoration: InputDecoration(
                              labelText: 'Senha',
                              helperText: 'Use de 8 a 72 caracteres.',
                              suffixIcon: IconButton(
                                  tooltip: _mostrarSenha
                                      ? 'Ocultar senha'
                                      : 'Mostrar senha',
                                  onPressed: () => setState(
                                      () => _mostrarSenha = !_mostrarSenha),
                                  icon: Icon(_mostrarSenha
                                      ? Icons.visibility_off_outlined
                                      : Icons.visibility_outlined))),
                          validator: (v) =>
                              (v == null || v.length < 8 || v.length > 72)
                                  ? 'Use de 8 a 72 caracteres.'
                                  : null,
                        ),
                        const SizedBox(height: 16),
                        if (_perfil == _Perfil.paciente) ...[
                          TextFormField(
                            controller: _idadeController,
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly
                            ],
                            decoration:
                                const InputDecoration(labelText: 'Idade'),
                            validator: (v) {
                              final idade = int.tryParse(v ?? '');
                              return idade == null || idade < 1 || idade > 120
                                  ? 'Informe sua idade, entre 1 e 120 anos.'
                                  : null;
                            },
                          ),
                          const SizedBox(height: 16),
                        ],
                        TextFormField(
                          controller: _telefoneController,
                          keyboardType: TextInputType.phone,
                          autofillHints: const [AutofillHints.telephoneNumber],
                          decoration: const InputDecoration(
                              labelText: 'Celular com DDD',
                              hintText: '(11) 99999-9999'),
                          validator: (v) => RegExp(r'^(55)?[1-9][0-9]{9,10}$')
                                  .hasMatch(
                                      (v ?? '').replaceAll(RegExp(r'\D'), ''))
                              ? null
                              : 'Informe um celular com DDD.',
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: _carregando ? null : _cadastrar,
                          child: _carregando
                              ? const SizedBox(
                                  height: 24,
                                  width: 24,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2, color: Colors.white),
                                )
                              : const Text('Criar conta'),
                        ),
                      ],
                    ),
                  ))),
            ),
          ),
        ),
      ),
    );
  }
}
