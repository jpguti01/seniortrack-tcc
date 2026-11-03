import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../services/api_exception.dart';
import '../services/paciente_service.dart';
import '../theme/app_theme.dart';

/// RF05, US05: formulário para o cuidador solicitar vínculo com um paciente
/// já cadastrado, informando o e-mail dele. O vínculo só vale depois que o
/// próprio paciente aceita no app dele.
Future<bool?> abrirDialogoVincularPaciente(BuildContext context) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) => const _FormularioVincularPaciente(),
  );
}

class _FormularioVincularPaciente extends StatefulWidget {
  const _FormularioVincularPaciente();

  @override
  State<_FormularioVincularPaciente> createState() => _FormularioVincularPacienteState();
}

class _FormularioVincularPacienteState extends State<_FormularioVincularPaciente> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _service = PacienteService();
  bool _enviando = false;
  String? _erro;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _solicitar() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _enviando = true;
      _erro = null;
    });
    try {
      await _service.solicitarVinculo(_emailController.text.trim());
      if (mounted) Navigator.of(context).pop(true);
    } on ApiException catch (e) {
      setState(() => _erro = e.mensagem);
    } catch (e) {
      setState(() => _erro = 'Não foi possível enviar. Verifique sua conexão.');
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 24, right: 24, top: 28,
        bottom: MediaQuery.of(context).viewInsets.bottom + 28,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(color: AppTheme.texto.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 24),
            Center(
              child: Container(
                width: 56, height: 56,
                decoration: BoxDecoration(color: AppTheme.primaria.withValues(alpha: 0.1), shape: BoxShape.circle),
                child: const Icon(Icons.favorite_rounded, color: AppTheme.primaria, size: 26),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Pedir para cuidar de alguém',
              textAlign: TextAlign.center,
              style: GoogleFonts.sourceSerif4(fontSize: 21, fontWeight: FontWeight.w600, color: AppTheme.texto),
            ),
            const SizedBox(height: 6),
            Text(
              'O paciente recebe seu pedido no app e decide se aceita. Nada é compartilhado sem a permissão dele.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: AppTheme.texto.withValues(alpha: 0.6), height: 1.4),
            ),
            const SizedBox(height: 24),
            if (_erro != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: AppTheme.alerta.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
                child: Text(_erro!, style: const TextStyle(color: AppTheme.alerta)),
              ),
              const SizedBox(height: 16),
            ],
            TextFormField(
              controller: _emailController,
              autofocus: true,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(labelText: 'E-mail do paciente', prefixIcon: Icon(Icons.mail_outline_rounded)),
              validator: (v) => (v == null || !v.contains('@')) ? 'Informe um e-mail válido' : null,
              onFieldSubmitted: (_) => _solicitar(),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _enviando ? null : _solicitar,
              child: _enviando
                  ? const SizedBox(
                      height: 24, width: 24,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('Enviar pedido'),
            ),
          ],
        ),
      ),
    );
  }
}
