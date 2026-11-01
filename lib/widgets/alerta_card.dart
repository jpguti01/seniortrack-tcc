import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/alerta.dart';

final _formatoHora = DateFormat('dd/MM HH:mm');

class AlertaCard extends StatelessWidget {
  final Alerta alerta;
  final VoidCallback? aoResolver;

  const AlertaCard({super.key, required this.alerta, this.aoResolver});

  @override
  Widget build(BuildContext context) {
    final resolvido = alerta.resolvido;
    return Card(
      color: resolvido ? Colors.grey.shade50 : Colors.red.withValues(alpha: 0.06),
      child: ListTile(
        leading: Icon(
          resolvido ? Icons.check_circle_outline : Icons.warning_amber_rounded,
          color: resolvido ? Colors.green : Colors.red.shade700,
        ),
        title: Text(
          alerta.mensagem,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            decoration: resolvido ? TextDecoration.lineThrough : null,
          ),
        ),
        subtitle: Text(_formatoHora.format(alerta.dataHora)),
        trailing: resolvido
            ? const Text('Resolvido', style: TextStyle(color: Colors.green, fontSize: 12))
            : (aoResolver == null
                ? null
                : TextButton(onPressed: aoResolver, child: const Text('Resolver'))),
      ),
    );
  }
}
