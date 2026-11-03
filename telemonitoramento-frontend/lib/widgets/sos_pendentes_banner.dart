import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/chamado_sos.dart';
import '../models/resumo_paciente.dart';
import '../theme/app_theme.dart';
import '../utils/telefone.dart';

/// Pedidos de ajuda em aberto, no topo do painel do cuidador: é a primeira
/// coisa que ele vê, com os atalhos para ligar, mandar WhatsApp e encerrar.
class SosPendentesBanner extends StatelessWidget {
  final List<ResumoPaciente> resumos;
  final Set<int> atendendo;
  final ValueChanged<ChamadoSos> onAtender;

  const SosPendentesBanner(
      {super.key,
      required this.resumos,
      required this.onAtender,
      this.atendendo = const {}});

  Future<void> _abrir(BuildContext context, Uri link) async {
    try {
      if (await launchUrl(link, mode: LaunchMode.externalApplication)) return;
    } catch (_) {/* segue para o aviso */}
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Não foi possível abrir o aplicativo.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final itens = [
      for (final resumo in resumos)
        for (final chamado in resumo.cuidados?.sosPendentes ?? <ChamadoSos>[])
          (resumo: resumo, chamado: chamado),
    ]..sort((a, b) => b.chamado.criadoEm.compareTo(a.chamado.criadoEm));
    if (itens.isEmpty) return const SizedBox.shrink();

    return Column(children: [
      for (final item in itens)
        Container(
          width: double.infinity,
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: AppTheme.alertaFundo,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.alerta, width: 2),
          ),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              const Icon(Icons.sos_rounded, color: AppTheme.alerta, size: 32),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${item.resumo.paciente.nome} pediu ajuda',
                          style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.alerta)),
                      Text(
                          'Pedido às ${DateFormat("HH:mm 'de' dd/MM").format(item.chamado.criadoEm.toLocal())}',
                          style: const TextStyle(
                              fontSize: 14, color: AppTheme.texto)),
                    ]),
              ),
            ]),
            const SizedBox(height: 14),
            Wrap(spacing: 10, runSpacing: 8, children: [
              if ((item.resumo.paciente.telefone ?? '').trim().isNotEmpty)
                FilledButton.icon(
                    onPressed: () => _abrir(
                        context,
                        Uri(
                            scheme: 'tel',
                            path: item.resumo.paciente.telefone!
                                .replaceAll(RegExp(r'[^0-9+]'), ''))),
                    style: FilledButton.styleFrom(
                        backgroundColor: AppTheme.alerta,
                        minimumSize: const Size(0, 48)),
                    icon: const Icon(Icons.phone_rounded),
                    label: const Text('Ligar')),
              if (linkWhatsApp(item.resumo.paciente.telefone ?? '') != null)
                OutlinedButton.icon(
                    onPressed: () => _abrir(
                        context,
                        linkWhatsApp(item.resumo.paciente.telefone!,
                            mensagem:
                                'Recebi seu pedido de ajuda. Estou indo falar com você.')!),
                    style: OutlinedButton.styleFrom(
                        minimumSize: const Size(0, 48)),
                    icon: const Icon(Icons.chat_outlined),
                    label: const Text('WhatsApp')),
              OutlinedButton.icon(
                  onPressed: atendendo.contains(item.chamado.id)
                      ? null
                      : () => onAtender(item.chamado),
                  style:
                      OutlinedButton.styleFrom(minimumSize: const Size(0, 48)),
                  icon: const Icon(Icons.task_alt_rounded),
                  label: Text(atendendo.contains(item.chamado.id)
                      ? 'Registrando…'
                      : 'Marcar como atendido')),
            ]),
          ]),
        ),
    ]);
  }
}
