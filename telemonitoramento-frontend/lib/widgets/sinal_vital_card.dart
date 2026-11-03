import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../models/sinal_vital.dart';
import '../theme/app_theme.dart';
import '../utils/formatar_medicao.dart';

final _formatoHora = DateFormat('dd/MM • HH:mm');

/// Cada card tem uma barra lateral na cor do tipo de sinal vital (não é
/// decoração: é o que deixa a lista legível de relance, sem precisar ler o
/// rótulo). O valor medido usa a serifa de destaque do app - é o dado mais
/// importante do card.
class SinalVitalCard extends StatelessWidget {
  final SinalVital sinal;
  final bool emAlerta;

  const SinalVitalCard({super.key, required this.sinal, this.emAlerta = false});

  @override
  Widget build(BuildContext context) {
    final cor = emAlerta ? AppTheme.alerta : sinal.tipo.cor;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border(left: BorderSide(color: cor, width: 5)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        child: Row(
          children: [
            Icon(sinal.tipo.icone, color: cor, size: 26),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(sinal.tipo.rotulo, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                  const SizedBox(height: 2),
                  Text(
                    _formatoHora.format(sinal.horaRegistro.toLocal()),
                    style: const TextStyle(color: AppTheme.textoSecundario, fontSize: 13),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  formatarMedicao(sinal.valor),
                  style: GoogleFonts.sourceSerif4(fontSize: 24, fontWeight: FontWeight.w600, color: cor, height: 1),
                ),
                Text(sinal.tipo.unidade, style: const TextStyle(fontSize: 13, color: AppTheme.textoSecundario)),
              ],
            ),
            if (emAlerta) ...[
              const SizedBox(width: 10),
              const Icon(Icons.priority_high_rounded, color: AppTheme.alerta, size: 20),
            ],
          ],
        ),
      ),
    );
  }
}
