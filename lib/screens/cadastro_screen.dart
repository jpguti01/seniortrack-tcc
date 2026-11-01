import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../services/api_exception.dart';
import '../theme/app_theme.dart';

enum _Perfil { paciente, cuidador }

class CadastroScreen extends StatefulWidget {
  const CadastroScreen({super.key});

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

  _Perfil _perfil = _Perfil.paciente;
  bool _carregando = false;
  String? _erro;

  @override
  void dispose() {
    _nomeController.dispose();
    _emailController.dispose();
    _senhaController.dispose();
    _idadeController.dispose();
    _telefoneController.dispose();
    super.dispose();
  }

  Future<void> _cadastrar() async {
    if (!_formKey.currentState!.validate()) return;
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
          nome: dados.nome, email: dados.email, senha: dados.senha,
          idade: dados.idade, telefone: dados.telefone,
        );
      } else {
        await auth.cadastrarCuidador(
          nome: dados.nome, email: dados.email, senha: dados.senha,
          idade: dados.idade, telefone: dados.telefone,
        );
      }
    } on ApiException catch (e) {
      setState(() => _erro = e.mensagem);
    } catch (e) {
      setState(() => _erro = 'Não foi possível conectar ao servidor. Tente novamente.');
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
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text('Eu sou:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    SegmentedButton<_Perfil>(
                      segments: const [
                        ButtonSegment(value: _Perfil.paciente, label: Text('Paciente'), icon: Icon(Icons.elderly)),
                        ButtonSegment(value: _Perfil.cuidador, label: Text('Cuidador'), icon: Icon(Icons.volunteer_activism)),
                      ],
                      selected: {_perfil},
                      onSelectionChanged: (s) => setState(() => _perfil = s.first),
                    ),
                    const SizedBox(height: 24),
                    if (_erro != null) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppTheme.alerta.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(_erro!, style: const TextStyle(color: AppTheme.alerta)),
                      ),
                      const SizedBox(height: 16),
                    ],
                    TextFormField(
                      controller: _nomeController,
                      decoration: const InputDecoration(labelText: 'Nome completo'),
                      validator: (v) => (v == null || v.isEmpty) ? 'Informe o nome' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(labelText: 'E-mail'),
                      validator: (v) => (v == null || !v.contains('@')) ? 'Informe um e-mail válido' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _senhaController,
                      obscureText: true,
                      decoration: const InputDecoration(labelText: 'Senha (mínimo 8 caracteres)'),
                      validator: (v) => (v == null || v.length < 8) ? 'A senha deve ter pelo menos 8 caracteres' : null,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _idadeController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(labelText: 'Idade'),
                            validator: (v) => (v == null || int.tryParse(v) == null) ? 'Idade inválida' : null,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          flex: 2,
                          child: TextFormField(
                            controller: _telefoneController,
                            keyboardType: TextInputType.phone,
                            decoration: const InputDecoration(labelText: 'Telefone'),
                            validator: (v) => (v == null || v.isEmpty) ? 'Informe o telefone' : null,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _carregando ? null : _cadastrar,
                      child: _carregando
                          ? const SizedBox(
                              height: 24, width: 24,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Text('Criar conta'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
