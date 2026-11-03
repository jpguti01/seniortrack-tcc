import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

import '../models/medicamento.dart';
import '../services/api_exception.dart';
import '../services/medicamento_service.dart';
import '../theme/app_theme.dart';

/// Cadastro e edição de um remédio pelo cuidador. Devolve true se salvou.
Future<bool?> abrirFormularioMedicamento(BuildContext context,
    {required int pacienteId, Medicamento? existente}) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
    builder: (_) =>
        _FormularioMedicamento(pacienteId: pacienteId, existente: existente),
  );
}

class _FormularioMedicamento extends StatefulWidget {
  final int pacienteId;
  final Medicamento? existente;
  const _FormularioMedicamento({required this.pacienteId, this.existente});

  @override
  State<_FormularioMedicamento> createState() => _FormularioMedicamentoState();
}

class _FormularioMedicamentoState extends State<_FormularioMedicamento> {
  // A foto vai como data URL no JSON; 1,5 MB já cobre uma foto reduzida.
  static const _tamanhoMaximoFoto = 1500000;

  final _formKey = GlobalKey<FormState>();
  final _service = MedicamentoService();
  late final _nome = TextEditingController(text: widget.existente?.nome);
  late final _dosagem = TextEditingController(text: widget.existente?.dosagem);
  late final _instrucoes =
      TextEditingController(text: widget.existente?.instrucoes);
  late final List<String> _horarios = [...?widget.existente?.horarios];
  late String? _foto = widget.existente?.foto;
  bool _enviando = false;
  String? _erro;

  @override
  void dispose() {
    _nome.dispose();
    _dosagem.dispose();
    _instrucoes.dispose();
    super.dispose();
  }

  Future<void> _adicionarHorario() async {
    final hora = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 8, minute: 0),
      helpText: 'Horário da dose',
      builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
          child: child!),
    );
    if (hora == null) return;
    final texto =
        '${hora.hour.toString().padLeft(2, '0')}:${hora.minute.toString().padLeft(2, '0')}';
    if (_horarios.contains(texto)) return;
    setState(() => _horarios
      ..add(texto)
      ..sort());
  }

  Future<void> _escolherFoto(ImageSource origem) async {
    try {
      final arquivo = await ImagePicker().pickImage(
          source: origem, maxWidth: 640, maxHeight: 640, imageQuality: 70);
      if (arquivo == null) return;
      final bytes = await arquivo.readAsBytes();
      if (bytes.length > _tamanhoMaximoFoto) {
        setState(() => _erro = 'A foto ficou grande demais. Tente outra.');
        return;
      }
      final tipo = arquivo.mimeType ?? 'image/jpeg';
      setState(() {
        _foto = 'data:$tipo;base64,${base64Encode(bytes)}';
        _erro = null;
      });
    } catch (_) {
      setState(() => _erro = 'Não foi possível abrir a foto.');
    }
  }

  Future<void> _salvar() async {
    if (_enviando || !_formKey.currentState!.validate()) return;
    if (_horarios.isEmpty) {
      setState(() => _erro = 'Adicione ao menos um horário.');
      return;
    }
    setState(() {
      _enviando = true;
      _erro = null;
    });
    try {
      await _service.salvar(
        pacienteId: widget.pacienteId,
        id: widget.existente?.id,
        nome: _nome.text.trim(),
        dosagem: _dosagem.text.trim().isEmpty ? null : _dosagem.text.trim(),
        instrucoes:
            _instrucoes.text.trim().isEmpty ? null : _instrucoes.text.trim(),
        horarios: _horarios,
        foto: _foto,
      );
      if (mounted) Navigator.of(context).pop(true);
    } on ApiException catch (e) {
      if (mounted) setState(() => _erro = e.mensagem);
    } catch (_) {
      if (mounted) {
        setState(
            () => _erro = 'Não foi possível salvar. Verifique sua conexão.');
      }
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final foto = bytesDaFoto(_foto);
    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 24,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(widget.existente == null ? 'Novo remédio' : 'Editar remédio',
                  style: GoogleFonts.sourceSerif4(
                      fontSize: 22, fontWeight: FontWeight.w600)),
              const SizedBox(height: 16),
              if (_erro != null) ...[
                Text(_erro!, style: const TextStyle(color: AppTheme.alerta)),
                const SizedBox(height: 12),
              ],
              TextFormField(
                controller: _nome,
                maxLength: 100,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                    labelText: 'Nome do remédio', counterText: ''),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Informe o nome do remédio'
                    : null,
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _dosagem,
                maxLength: 60,
                decoration: const InputDecoration(
                    labelText: 'Dosagem (opcional)',
                    hintText: 'Ex.: 50 mg, 1 comprimido',
                    counterText: ''),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _instrucoes,
                maxLength: 255,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                    labelText: 'Instruções (opcional)',
                    hintText: 'Ex.: tomar após o café da manhã',
                    counterText: ''),
              ),
              const SizedBox(height: 12),
              const Text('Horários',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
              const SizedBox(height: 8),
              Wrap(spacing: 8, runSpacing: 8, children: [
                for (final horario in _horarios)
                  Chip(
                    label: Text(horario,
                        style: const TextStyle(fontWeight: FontWeight.w600)),
                    onDeleted: () => setState(() => _horarios.remove(horario)),
                    deleteButtonTooltipMessage: 'Remover $horario',
                  ),
                if (_horarios.length < 8)
                  ActionChip(
                    avatar: const Icon(Icons.add_alarm_rounded, size: 18),
                    label: const Text('Adicionar horário'),
                    onPressed: _adicionarHorario,
                  ),
              ]),
              const SizedBox(height: 20),
              const Text('Foto do comprimido ou da caixa (opcional)',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
              const SizedBox(height: 8),
              Row(children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    width: 84,
                    height: 84,
                    color: const Color(0xFFF4F7F5),
                    child: foto == null
                        ? const Icon(Icons.medication_outlined,
                            size: 34, color: AppTheme.primaria)
                        : Image.memory(foto, fit: BoxFit.cover),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Wrap(spacing: 4, runSpacing: 4, children: [
                    TextButton.icon(
                        onPressed: () => _escolherFoto(ImageSource.camera),
                        icon: const Icon(Icons.photo_camera_outlined),
                        label: const Text('Tirar foto')),
                    TextButton.icon(
                        onPressed: () => _escolherFoto(ImageSource.gallery),
                        icon: const Icon(Icons.photo_library_outlined),
                        label: const Text('Escolher foto')),
                    if (_foto != null)
                      TextButton.icon(
                          onPressed: () => setState(() => _foto = null),
                          icon: const Icon(Icons.delete_outline_rounded),
                          label: const Text('Remover')),
                  ]),
                ),
              ]),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _enviando ? null : _salvar,
                child: _enviando
                    ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Text('Salvar remédio'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
