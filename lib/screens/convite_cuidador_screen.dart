import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../services/api_client.dart';
import '../services/api_exception.dart';
import '../theme/app_theme.dart';

class ConviteCuidadorScreen extends StatefulWidget {
  const ConviteCuidadorScreen({super.key});
  @override
  State<ConviteCuidadorScreen> createState() => _ConviteCuidadorScreenState();
}

class _ConviteCuidadorScreenState extends State<ConviteCuidadorScreen> {
  String? _codigo;
  String? _erro;
  bool _ocupado = false;

  Future<void> _gerar() async {
    if (_ocupado) return;
    setState(() {
      _ocupado = true;
      _erro = null;
    });
    try {
      final resposta = await ApiClient.instancia.post('/convites');
      if (mounted) setState(() => _codigo = resposta['codigo'] as String);
    } on ApiException catch (e) {
      if (mounted) setState(() => _erro = e.mensagem);
    } catch (_) {
      if (mounted) {
        setState(() => _erro =
            'Não foi possível gerar o convite. Confira sua conexão e tente novamente.');
      }
    } finally {
      if (mounted) setState(() => _ocupado = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Convidar meu cuidador')),
        body: SafeArea(
            child: Center(
                child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Icon(Icons.volunteer_activism_outlined,
                        size: 48, color: AppTheme.primaria),
                    const SizedBox(height: 20),
                    Text('Compartilhe o cuidado',
                        style: Theme.of(context).textTheme.headlineSmall),
                    const SizedBox(height: 16),
                    const Text(
                        'Ao usar este convite no cadastro, seu cuidador terá acesso às suas medições e à sua rotina. Compartilhe apenas com a pessoa que você escolheu.'),
                    const SizedBox(height: 20),
                    if (_erro != null) ...[
                      Semantics(
                          liveRegion: true,
                          child: Text(_erro!,
                              style: const TextStyle(color: AppTheme.alerta))),
                      const SizedBox(height: 20),
                    ],
                    if (_codigo != null) ...[
                      Center(
                          child: Semantics(
                              label: 'QR Code do convite para o cuidador',
                              child: QrImageView(
                                  data: _codigo!,
                                  size: 220,
                                  backgroundColor: Colors.white))),
                      const SizedBox(height: 20),
                      const Text('Código de convite',
                          textAlign: TextAlign.center),
                      SelectableText(_codigo!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                              fontSize: 22, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 16),
                      OutlinedButton.icon(
                          onPressed: () async {
                            await Clipboard.setData(
                                ClipboardData(text: _codigo!));
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content: Text('Código copiado.')));
                            }
                          },
                          icon: const Icon(Icons.copy),
                          label: const Text('Copiar código')),
                      const SizedBox(height: 20),
                      const Text(
                          'O convite vale por 24 horas e pode ser usado uma única vez. O cuidador pode copiar o código ou ler o QR Code com a câmera do celular e informar o conteúdo no cadastro. Gerar outro convite cancela o anterior.'),
                      const SizedBox(height: 20),
                    ],
                    ElevatedButton.icon(
                        onPressed: _ocupado ? null : _gerar,
                        icon: _ocupado
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2))
                            : const Icon(Icons.qr_code),
                        label: Text(_codigo == null
                            ? 'Gerar código de convite'
                            : 'Gerar novo convite')),
                  ])),
        ))),
      );
}
