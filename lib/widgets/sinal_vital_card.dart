import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/sinal_vital.dart';
import '../models/tipo_sinal_vital.dart';

final _formatoHora = DateFormat('dd/MM HH:mm');

IconData iconePara(TipoSinalVital tipo) {
  switch (tipo) {
    case TipoSinalVital.pressaoArterial:
      return Icons.monitor_heart_outlined;
    case TipoSinalVital.glicemia:
      return Icons.water_drop_outlined;
    case TipoSinalVital.peso:
      return Icons.monitor_weight_outlined;
  }
}

class SinalVitalCard extends StatelessWidget {
  final SinalVital sinal;
  final bool emAlerta;

  const SinalVitalCard({super.key, required this.sinal, this.emAlerta = false});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: emAlerta ? Colors.red.withValues(alpha: 0.06) : null,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: emAlerta ? Colors.red.shade100 : Colors.blue.shade50,
          child: Icon(iconePara(sinal.tipo), color: emAlerta ? Colors.red.shade700 : Colors.blue.shade700),
        ),
        title: Text(sinal.tipo.rotulo, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(_formatoHora.format(sinal.horaRegistro)),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '${sinal.valor.toStringAsFixed(1)} ${sinal.tipo.unidade}',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: emAlerta ? Colors.red.shade700 : Colors.black87,
              ),
            ),
            if (emAlerta)
              const Text('fora da faixa', style: TextStyle(fontSize: 12, color: Colors.red)),
          ],
        ),
      ),
    );
  }
}
