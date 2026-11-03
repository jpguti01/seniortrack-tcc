import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Botão de pedido de ajuda do paciente. Pede confirmação antes de avisar o
/// cuidador, para um toque acidental não disparar o SOS.
class BotaoSos extends StatelessWidget {
  final Future<void> Function() onConfirmar;
  final bool enviando;
  final bool grande;

  const BotaoSos(
      {super.key,
      required this.onConfirmar,
      this.enviando = false,
      this.grande = false});

  Future<void> _confirmar(BuildContext context) async {
    final confirmou = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        icon: const Icon(Icons.sos_rounded, color: AppTheme.alerta, size: 40),
        title: const Text('Pedir ajuda agora?'),
        content: const Text(
            'Seu cuidador vai receber um aviso de que você precisa de ajuda.',
            style: TextStyle(fontSize: 17, height: 1.4)),
        actionsOverflowButtonSpacing: 8,
        actions: [
          TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancelar')),
          FilledButton.icon(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              style: FilledButton.styleFrom(
                  backgroundColor: AppTheme.alerta,
                  minimumSize: const Size(0, 52)),
              icon: const Icon(Icons.campaign_rounded),
              label: const Text('Sim, pedir ajuda')),
        ],
      ),
    );
    if (confirmou == true) await onConfirmar();
  }

  @override
  Widget build(BuildContext context) {
    // excludeSemantics troca o rótulo curto do botão por um mais claro; o
    // onTap mantém o botão acionável por leitores de tela.
    return Semantics(
      button: true,
      enabled: !enviando,
      label: 'Pedir ajuda ao cuidador',
      onTap: enviando ? null : () => _confirmar(context),
      excludeSemantics: true,
      child: FilledButton.icon(
        onPressed: enviando ? null : () => _confirmar(context),
        style: FilledButton.styleFrom(
          backgroundColor: AppTheme.alerta,
          foregroundColor: Colors.white,
          minimumSize: Size(grande ? double.infinity : 0, grande ? 76 : 48),
          padding: EdgeInsets.symmetric(horizontal: grande ? 24 : 16),
          textStyle: TextStyle(
              fontSize: grande ? 22 : 16, fontWeight: FontWeight.w700),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(grande ? 18 : 12)),
        ),
        icon: enviando
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                    strokeWidth: 2.5, color: Colors.white))
            : Icon(Icons.sos_rounded, size: grande ? 34 : 22),
        label: Text(enviando ? 'Avisando…' : 'Pedir ajuda'),
      ),
    );
  }
}
