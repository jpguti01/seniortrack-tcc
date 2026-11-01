import 'package:flutter/material.dart';

import '../services/api_exception.dart';
import '../services/paciente_service.dart';

/// RF05, US05: formulário para o cuidador vincular um paciente já cadastrado
/// à sua conta, informando o e-mail dele.
Future<bool?> abrirDialogoVincularPaciente(BuildContext context) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
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

  Future<void> _vincular() async {
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
      setState(() => _erro = 'Não foi possível vincular. Verifique sua conexão.');
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
            const Text('Solicitar vínculo', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            const Text(
              'O paciente vai receber o pedido no app dele e precisa aceitar antes do vínculo valer.',
              style: TextStyle(color: Colors.black54),
            ),
            const SizedBox(height: 20),
            if (_erro != null) ...[
              Text(_erro!, style: const TextStyle(color: Colors.red)),
              const SizedBox(height: 12),
            ],
            TextFormField(
              controller: _emailController,
              autofocus: true,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(labelText: 'E-mail do paciente'),
              validator: (v) => (v == null || !v.contains('@')) ? 'Informe um e-mail válido' : null,
              onFieldSubmitted: (_) => _vincular(),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _enviando ? null : _vincular,
              child: _enviando
                  ? const SizedBox(
                      height: 24, width: 24,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('Enviar solicitação'),
            ),
          ],
        ),
      ),
    );
  }
}
