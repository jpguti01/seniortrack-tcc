import 'package:flutter/material.dart';

import '../models/tipo_sinal_vital.dart';
import '../services/api_exception.dart';
import '../services/sinal_vital_service.dart';

/// UC-02: formulário de registro de um novo sinal vital pelo paciente.
/// Retorna true se o registro foi salvo com sucesso (para a tela que chamou
/// recarregar a lista).
Future<bool?> abrirDialogoRegistrarSinalVital(BuildContext context, TipoSinalVital tipo) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => _FormularioSinalVital(tipo: tipo),
  );
}

class _FormularioSinalVital extends StatefulWidget {
  final TipoSinalVital tipo;
  const _FormularioSinalVital({required this.tipo});

  @override
  State<_FormularioSinalVital> createState() => _FormularioSinalVitalState();
}

class _FormularioSinalVitalState extends State<_FormularioSinalVital> {
  final _formKey = GlobalKey<FormState>();
  final _valorController = TextEditingController();
  final _service = SinalVitalService();
  bool _enviando = false;
  String? _erro;

  @override
  void dispose() {
    _valorController.dispose();
    super.dispose();
  }

  Future<void> _confirmar() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _enviando = true;
      _erro = null;
    });
    try {
      final valor = double.parse(_valorController.text.replaceAll(',', '.'));
      await _service.registrar(widget.tipo, valor);
      if (mounted) Navigator.of(context).pop(true);
    } on ApiException catch (e) {
      setState(() => _erro = e.mensagem);
    } catch (e) {
      setState(() => _erro = 'Não foi possível registrar. Verifique sua conexão.');
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
              'Registrar ${widget.tipo.rotulo}',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              'Informe o valor medido agora (${widget.tipo.unidade})',
              style: const TextStyle(color: Colors.black54),
            ),
            const SizedBox(height: 20),
            if (_erro != null) ...[
              Text(_erro!, style: const TextStyle(color: Colors.red)),
              const SizedBox(height: 12),
            ],
            TextFormField(
              controller: _valorController,
              autofocus: true,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
              decoration: InputDecoration(suffixText: widget.tipo.unidade),
              validator: (v) {
                if (v == null || v.isEmpty) return 'Informe um valor';
                final n = double.tryParse(v.replaceAll(',', '.'));
                if (n == null || n <= 0) return 'Valor inválido';
                return null;
              },
              onFieldSubmitted: (_) => _confirmar(),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _enviando ? null : _confirmar,
              child: _enviando
                  ? const SizedBox(
                      height: 24, width: 24,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('Confirmar registro'),
            ),
          ],
        ),
      ),
    );
  }
}
