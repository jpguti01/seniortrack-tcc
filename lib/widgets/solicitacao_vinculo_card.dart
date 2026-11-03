import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/solicitacao_vinculo.dart';

final _formatoData = DateFormat('dd/MM/yyyy HH:mm');

/// RF05: card de uma solicitação de vínculo pendente, com os botões de
/// aceitar/recusar que efetivam (ou não) o consentimento do paciente.
class SolicitacaoVinculoCard extends StatelessWidget {
  final SolicitacaoVinculo solicitacao;
  final VoidCallback aoAceitar;
  final VoidCallback aoRecusar;
  final bool processando;

  const SolicitacaoVinculoCard({
    super.key,
    required this.solicitacao,
    required this.aoAceitar,
    required this.aoRecusar,
    this.processando = false,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.amber.withValues(alpha: 0.12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const CircleAvatar(child: Icon(Icons.volunteer_activism)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        solicitacao.cuidadorNome,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      const Text('quer ser seu cuidador no app', style: TextStyle(color: Colors.black54)),
                      Text(
                        'Pedido em ${_formatoData.format(solicitacao.criadoEm)}',
                        style: const TextStyle(color: Colors.black38, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: processando ? null : aoRecusar,
                    style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(44)),
                    child: const Text('Recusar'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: processando ? null : aoAceitar,
                    style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(44)),
                    child: const Text('Aceitar'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
