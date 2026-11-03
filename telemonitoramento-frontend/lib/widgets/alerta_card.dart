import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/alerta.dart';
import '../theme/app_theme.dart';

class AlertaCard extends StatelessWidget {
  final Alerta alerta;
  final VoidCallback? aoResolver;
  final VoidCallback? aoOuvir;
  final VoidCallback? aoContatar;
  const AlertaCard(
      {super.key,
      required this.alerta,
      this.aoResolver,
      this.aoOuvir,
      this.aoContatar});

  @override
  Widget build(BuildContext context) {
    // Cor pela gravidade: crítico em vermelho, atenção em âmbar.
    final cor = alerta.resolvido
        ? AppTheme.primaria
        : AppTheme.corGravidade(alerta.gravidade);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: alerta.resolvido
            ? Colors.white
            : AppTheme.fundoGravidade(alerta.gravidade),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: cor.withValues(alpha: alerta.critico ? .8 : .4),
            width: alerta.critico && !alerta.resolvido ? 2 : 1),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(
              alerta.resolvido
                  ? Icons.check_circle_outline_rounded
                  : alerta.critico
                      ? Icons.error_rounded
                      : Icons.warning_amber_rounded,
              color: cor),
          const SizedBox(width: 10),
          Expanded(
              child: Text(alerta.titulo,
                  style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.texto))),
        ]),
        const SizedBox(height: 12),
        Wrap(
            spacing: 10,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(alerta.medicao,
                  style: AppTheme.numeroDestaque(fontSize: 28, color: cor)),
              Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                      color: cor.withValues(alpha: .1),
                      borderRadius: BorderRadius.circular(8)),
                  child: Text(
                      alerta.resolvido ? 'Resolvido' : alerta.gravidade.rotulo,
                      style: TextStyle(
                          color: cor,
                          fontSize: 13,
                          fontWeight: FontWeight.w600))),
              if (alerta.persistente && !alerta.resolvido)
                Tooltip(
                  message:
                      'O mesmo sinal também ficou fora da faixa no dia anterior.',
                  child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                          border: Border.all(color: cor),
                          borderRadius: BorderRadius.circular(8)),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        Icon(Icons.repeat_rounded, size: 15, color: cor),
                        const SizedBox(width: 4),
                        Text('Repetiu ontem',
                            style: TextStyle(
                                color: cor,
                                fontSize: 13,
                                fontWeight: FontWeight.w600)),
                      ])),
                ),
            ]),
        const SizedBox(height: 12),
        Text(alerta.mensagemLegivel,
            style: const TextStyle(
                fontSize: 14, height: 1.5, color: AppTheme.texto)),
        const SizedBox(height: 8),
        Text(DateFormat('dd/MM/yyyy • HH:mm').format(alerta.dataHora.toLocal()),
            style:
                const TextStyle(fontSize: 12, color: AppTheme.textoSecundario)),
        if (aoResolver != null || aoOuvir != null || aoContatar != null) ...[
          const SizedBox(height: 10),
          Wrap(spacing: 8, runSpacing: 4, children: [
            if (aoOuvir != null)
              TextButton.icon(
                  onPressed: aoOuvir,
                  icon: const Icon(Icons.volume_up_outlined, size: 20),
                  label: const Text('Ouvir alerta')),
            if (aoContatar != null)
              TextButton.icon(
                  onPressed: aoContatar,
                  icon: const Icon(Icons.phone_outlined, size: 20),
                  label: const Text('Falar com cuidador')),
            if (aoResolver != null && !alerta.resolvido)
              TextButton(onPressed: aoResolver, child: const Text('Resolver')),
          ]),
        ],
      ]),
    );
  }
}
