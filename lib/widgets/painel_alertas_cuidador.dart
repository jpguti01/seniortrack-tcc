import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/resumo_paciente.dart';
import '../theme/app_theme.dart';

class PainelAlertasCuidador extends StatelessWidget {
  final List<ResumoPaciente> resumos;
  final ValueChanged<ResumoPaciente> onAbrir;
  final int? limite;
  final VoidCallback? onVerTodos;
  const PainelAlertasCuidador(
      {super.key,
      required this.resumos,
      required this.onAbrir,
      this.limite,
      this.onVerTodos});

  @override
  Widget build(BuildContext context) {
    // Críticos no topo; dentro da mesma gravidade, os mais recentes.
    final itens = [
      for (final resumo in resumos)
        for (final alerta in resumo.pendentes) (resumo: resumo, alerta: alerta),
    ]..sort((a, b) {
        if (a.alerta.critico != b.alerta.critico) {
          return a.alerta.critico ? -1 : 1;
        }
        return b.alerta.dataHora.compareTo(a.alerta.dataHora);
      });
    final parcial = resumos.any((r) => r.alertas == null);
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppTheme.borda)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Row(children: [
          Icon(Icons.notifications_outlined,
              size: 21, color: AppTheme.primaria),
          SizedBox(width: 9),
          Expanded(
              child: Text('Central de alertas',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600))),
        ]),
        const SizedBox(height: 6),
        const Text('Pendências dos seus pacientes',
            style: TextStyle(fontSize: 13, color: AppTheme.textoSecundario)),
        const SizedBox(height: 20),
        if (parcial) ...[
          const Text(
              'Consulta parcial: os alertas de alguns pacientes estão indisponíveis.',
              style: TextStyle(fontSize: 13, color: AppTheme.atencao)),
          const SizedBox(height: 12),
        ],
        if (itens.isEmpty)
          Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                        parcial
                            ? Icons.cloud_off_outlined
                            : Icons.task_alt_rounded,
                        color: parcial ? AppTheme.atencao : AppTheme.primaria,
                        size: 30),
                    const SizedBox(height: 12),
                    Text(
                        parcial
                            ? 'Não há alertas confirmados nesta consulta.'
                            : 'Nenhum alerta pendente',
                        style: const TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 6),
                    const Text(
                        'As novas ocorrências aparecerão aqui após a atualização.',
                        style: TextStyle(
                            fontSize: 13,
                            height: 1.5,
                            color: AppTheme.textoSecundario)),
                  ])),
        for (final item in itens.take(limite ?? itens.length)) ...[
          Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => onAbrir(item.resumo),
                borderRadius: BorderRadius.circular(10),
                child: Padding(
                    padding:
                        const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
                    child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                              item.alerta.critico
                                  ? Icons.error_rounded
                                  : Icons.warning_amber_rounded,
                              color:
                                  AppTheme.corGravidade(item.alerta.gravidade),
                              size: 19),
                          const SizedBox(width: 10),
                          Expanded(
                              child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                Text(
                                    '${item.resumo.paciente.nome} • ${item.alerta.gravidade.rotulo}${item.alerta.persistente ? ' (repetiu ontem)' : ''}',
                                    style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: AppTheme.corGravidade(
                                            item.alerta.gravidade))),
                                const SizedBox(height: 4),
                    Text(item.alerta.mensagemLegivel,
                                    style: const TextStyle(
                                        fontSize: 13,
                                        height: 1.4,
                                        color: AppTheme.textoSecundario)),
                                const SizedBox(height: 5),
                                Text(
                                    DateFormat('dd/MM/yyyy • HH:mm')
                                        .format(item.alerta.dataHora.toLocal()),
                                    style: const TextStyle(
                                        fontSize: 12,
                                        color: AppTheme.textoSecundario)),
                              ])),
                          const Icon(Icons.chevron_right_rounded,
                              size: 18, color: AppTheme.textoSecundario),
                        ])),
              )),
          const Divider(height: 1, color: AppTheme.borda),
        ],
        if (limite != null && itens.length > limite! && onVerTodos != null) ...[
          const SizedBox(height: 12),
          TextButton(
              onPressed: onVerTodos,
              child: Text('Ver todos os ${itens.length} alertas')),
        ],
        const SizedBox(height: 16),
        const Text(
            'O status indica alertas do sistema, sem substituir uma avaliação de saúde.',
            style: TextStyle(
                fontSize: 12, height: 1.5, color: AppTheme.textoSecundario)),
      ]),
    );
  }
}
