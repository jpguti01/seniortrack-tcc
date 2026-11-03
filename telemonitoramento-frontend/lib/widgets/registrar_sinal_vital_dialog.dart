import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart';

import '../models/tipo_sinal_vital.dart';
import '../services/api_exception.dart';
import '../services/medidor_bluetooth.dart';
import '../services/sinal_vital_service.dart';
import '../theme/app_theme.dart';
import '../utils/formatar_medicao.dart';
import '../utils/numero_falado.dart';

/// UC-02: formulário de registro de um novo sinal vital pelo paciente.
/// Retorna true se o registro foi salvo com sucesso (para a tela que chamou
/// recarregar a lista).
Future<bool?> abrirDialogoRegistrarSinalVital(
    BuildContext context, TipoSinalVital tipo) {
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
  final _fala = SpeechToText();
  final _medidor = MedidorBluetooth();
  bool _enviando = false;
  bool _falaPronta = false;
  bool _ouvindo = false;
  bool _lendoAparelho = false;
  String? _ouvido;
  String? _origem;
  String? _erro;

  @override
  void dispose() {
    _fala.cancel();
    _valorController.dispose();
    super.dispose();
  }

  // Entrada por voz: o paciente diz o número ("cento e trinta") e o campo é
  // preenchido; ele confere na tela antes de confirmar.
  Future<void> _falar() async {
    if (_ouvindo) {
      await _fala.stop();
      if (mounted) setState(() => _ouvindo = false);
      return;
    }
    setState(() {
      _erro = null;
      _ouvido = null;
    });
    try {
      _falaPronta = _falaPronta ||
          await _fala.initialize(
            onError: (_) => _fimDaFala(
                'Não consegui ouvir. Tente de novo, perto do microfone.'),
            onStatus: (status) {
              if (status == SpeechToText.doneStatus) _fimDaFala(null);
            },
          );
      if (!_falaPronta) {
        _fimDaFala(
            'O reconhecimento de voz não está disponível aqui. Digite o valor.');
        return;
      }
      setState(() => _ouvindo = true);
      await _fala.listen(
        onResult: (resultado) {
          if (!mounted) return;
          final valor = extrairNumeroFalado(resultado.recognizedWords);
          setState(() {
            _ouvido = resultado.recognizedWords;
            if (valor != null) {
              _valorController.text = formatarMedicao(valor);
              _origem = 'Valor reconhecido pela voz. Confira antes de confirmar.';
            }
          });
          if (resultado.finalResult) {
            _fimDaFala(valor == null && resultado.recognizedWords.isNotEmpty
                ? 'Não entendi um número em "${resultado.recognizedWords}". Tente de novo ou digite.'
                : null);
          }
        },
        listenOptions: SpeechListenOptions(
          localeId: kIsWeb ? 'pt-BR' : 'pt_BR',
          listenFor: const Duration(seconds: 12),
          pauseFor: const Duration(seconds: 3),
          cancelOnError: true,
        ),
      );
    } catch (_) {
      _fimDaFala(
          'O reconhecimento de voz não está disponível aqui. Digite o valor.');
    }
  }

  void _fimDaFala(String? erro) {
    if (!mounted) return;
    setState(() {
      _ouvindo = false;
      if (erro != null) _erro = erro;
    });
  }

  Future<void> _lerAparelho() async {
    setState(() {
      _lendoAparelho = true;
      _erro = null;
    });
    try {
      final valor = await _medidor.ler(widget.tipo);
      if (!mounted) return;
      setState(() {
        _valorController.text = formatarMedicao(valor);
        _origem = 'Valor lido do aparelho Bluetooth. Confira antes de confirmar.';
      });
    } on MedidorBluetoothException catch (e) {
      if (mounted) setState(() => _erro = e.mensagem);
    } finally {
      if (mounted) setState(() => _lendoAparelho = false);
    }
  }

  Future<void> _confirmar() async {
    if (_enviando || !_formKey.currentState!.validate()) return;
    setState(() {
      _enviando = true;
      _erro = null;
    });
    try {
      final valor = double.parse(_valorController.text.replaceAll(',', '.'));
      await _service.registrar(widget.tipo, valor);
      if (mounted) Navigator.of(context).pop(true);
    } on ApiException catch (e) {
      if (mounted) setState(() => _erro = e.mensagem);
    } catch (e) {
      if (mounted) {
        setState(
            () => _erro = 'Não foi possível registrar. Verifique sua conexão.');
      }
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
        child: SafeArea(
            top: false,
            child: Padding(
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                top: 24,
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
                      style: const TextStyle(
                          fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.tipo == TipoSinalVital.pressaoArterial
                          ? 'Informe a pressão máxima (sistólica), em ${widget.tipo.unidade}. Você pode digitar, falar ou ler do aparelho.'
                          : 'Informe o valor medido agora (${widget.tipo.unidade}). Você pode digitar, falar ou ler do aparelho.',
                      style: const TextStyle(color: Colors.black54),
                    ),
                    const SizedBox(height: 20),
                    if (_erro != null) ...[
                      Text(_erro!, style: const TextStyle(color: Colors.red)),
                      const SizedBox(height: 12),
                    ],
                    TextFormField(
                      controller: _valorController,
                      enabled: !_enviando,
                      autofocus: true,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      style: const TextStyle(
                          fontSize: 28, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                      decoration: InputDecoration(
                          labelText: 'Valor medido',
                          suffixText: widget.tipo.unidade),
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Informe um valor';
                        final n = double.tryParse(v.replaceAll(',', '.'));
                        if (n == null || !n.isFinite || n <= 0) {
                          return 'Informe um número maior que zero';
                        }
                        return null;
                      },
                      onFieldSubmitted: (_) => _confirmar(),
                      onChanged: (_) {
                        if (_origem != null) setState(() => _origem = null);
                      },
                    ),
                    if (_origem != null) ...[
                      const SizedBox(height: 8),
                      Text(_origem!,
                          style: const TextStyle(
                              fontSize: 14, color: AppTheme.sucesso)),
                    ],
                    const SizedBox(height: 16),
                    Wrap(spacing: 10, runSpacing: 10, children: [
                      OutlinedButton.icon(
                        onPressed: _enviando ? null : _falar,
                        style: OutlinedButton.styleFrom(
                            minimumSize: const Size(0, 52),
                            foregroundColor:
                                _ouvindo ? AppTheme.alerta : AppTheme.primaria),
                        icon: Icon(_ouvindo
                            ? Icons.stop_circle_outlined
                            : Icons.mic_none_rounded),
                        label: Text(_ouvindo ? 'Parar de ouvir' : 'Falar o valor'),
                      ),
                      if (_medidor.disponivel)
                        OutlinedButton.icon(
                          onPressed:
                              _enviando || _lendoAparelho ? null : _lerAparelho,
                          style: OutlinedButton.styleFrom(
                              minimumSize: const Size(0, 52)),
                          icon: _lendoAparelho
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child:
                                      CircularProgressIndicator(strokeWidth: 2))
                              : const Icon(Icons.bluetooth_searching_rounded),
                          label: Text(_lendoAparelho
                              ? 'Aguardando o aparelho…'
                              : 'Ler do aparelho'),
                        ),
                    ]),
                    if (_ouvindo || _ouvido != null) ...[
                      const SizedBox(height: 8),
                      Text(
                          _ouvindo && (_ouvido ?? '').isEmpty
                              ? 'Ouvindo… diga só o número, por exemplo "cento e trinta".'
                              : 'Ouvi: "${_ouvido ?? ''}"',
                          style: const TextStyle(
                              fontSize: 14, color: AppTheme.textoSecundario)),
                    ],
                    if (_lendoAparelho) ...[
                      const SizedBox(height: 8),
                      const Text(
                          'Escolha o aparelho na lista do navegador e faça a medição com ele ligado.',
                          style: TextStyle(
                              fontSize: 14, color: AppTheme.textoSecundario)),
                    ],
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _enviando ? null : _confirmar,
                      child: _enviando
                          ? const SizedBox(
                              height: 24,
                              width: 24,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white),
                            )
                          : const Text('Confirmar registro'),
                    ),
                  ],
                ),
              ),
            )));
  }
}
