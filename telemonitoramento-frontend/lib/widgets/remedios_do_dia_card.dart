import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/medicamento.dart';
import '../theme/app_theme.dart';

/// Doses de hoje do paciente, com o botão "Tomei" em cada uma que ainda não
/// foi confirmada. A foto cadastrada pelo cuidador ajuda a reconhecer o remédio.
class RemediosDoDiaCard extends StatelessWidget {
  final List<Dose>? doses;
  final bool erro;
  final Map<int, Medicamento> medicamentos;
  final Set<String> confirmando;
  final ValueChanged<Dose> onTomei;
  final VoidCallback? onTentarDeNovo;
  final bool grande;

  const RemediosDoDiaCard({
    super.key,
    required this.doses,
    required this.onTomei,
    this.erro = false,
    this.medicamentos = const {},
    this.confirmando = const {},
    this.onTentarDeNovo,
    this.grande = false,
  });

  @override
  Widget build(BuildContext context) {
    final lista = [...?doses]..sort((a, b) => a.horario.compareTo(b.horario));
    final tomadas = lista.where((d) => d.status == StatusDose.tomado).length;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(grande ? 20 : 22),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppTheme.borda)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(Icons.medication_rounded,
              color: AppTheme.primaria, size: grande ? 30 : 22),
          const SizedBox(width: 10),
          Expanded(
              child: Text('Remédios de hoje',
                  style: TextStyle(
                      fontSize: grande ? 22 : 17,
                      fontWeight: FontWeight.w600))),
        ]),
        const SizedBox(height: 8),
        if (erro)
          Wrap(crossAxisAlignment: WrapCrossAlignment.center, children: [
            const Text('Não foi possível consultar seus remédios.',
                style: TextStyle(color: AppTheme.textoSecundario)),
            if (onTentarDeNovo != null)
              TextButton(
                  onPressed: onTentarDeNovo,
                  child: const Text('Tentar de novo')),
          ])
        else if (doses == null)
          const Padding(
              padding: EdgeInsets.all(12),
              child: Center(child: CircularProgressIndicator()))
        else if (lista.isEmpty)
          const Text(
              'Nenhum remédio previsto para hoje. Seu cuidador pode cadastrar a sua rotina.',
              style: TextStyle(fontSize: 15, color: AppTheme.textoSecundario))
        else ...[
          Text('$tomadas de ${lista.length} tomados',
              style: TextStyle(
                  fontSize: grande ? 18 : 15, color: AppTheme.textoSecundario)),
          const SizedBox(height: 12),
          for (final dose in lista) _linha(dose),
        ],
      ]),
    );
  }

  Widget _linha(Dose dose) {
    final foto = medicamentos[dose.medicamentoId]?.fotoBytes;
    final tomado = dose.status == StatusDose.tomado;
    final atrasado = dose.status == StatusDose.atrasado;
    final cor = tomado
        ? AppTheme.sucesso
        : atrasado
            ? AppTheme.alerta
            : AppTheme.texto;
    final enviando = confirmando.contains(dose.chave);
    final detalhe = [
      if (dose.dosagem?.isNotEmpty ?? false) dose.dosagem!,
      if (dose.instrucoes?.isNotEmpty ?? false) dose.instrucoes!,
    ].join(' • ');
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
          color: atrasado ? AppTheme.alertaFundo : const Color(0xFFF4F7F5),
          borderRadius: BorderRadius.circular(14)),
      child: LayoutBuilder(builder: (context, espaco) {
        final info = Row(children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: SizedBox(
              width: grande ? 64 : 48,
              height: grande ? 64 : 48,
              child: foto == null
                  ? Container(
                      color: Colors.white,
                      child: const Icon(Icons.medication_outlined,
                          color: AppTheme.primaria))
                  : Image.memory(foto,
                      fit: BoxFit.cover,
                      semanticLabel: 'Foto de ${dose.nome}',
                      errorBuilder: (_, __, ___) =>
                          const Icon(Icons.medication_outlined)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('${dose.horario}  ${dose.nome}',
                  style: TextStyle(
                      fontSize: grande ? 20 : 16, fontWeight: FontWeight.w600)),
              if (detalhe.isNotEmpty)
                Text(detalhe,
                    style: TextStyle(
                        fontSize: grande ? 16 : 13,
                        color: AppTheme.textoSecundario)),
              Text(
                  tomado && dose.confirmadaEm != null
                      ? 'Tomado às ${DateFormat('HH:mm').format(dose.confirmadaEm!.toLocal())}'
                      : dose.status.rotulo,
                  style: TextStyle(
                      fontSize: grande ? 16 : 13,
                      fontWeight: FontWeight.w600,
                      color: cor)),
            ]),
          ),
          if (tomado) ...[
            const SizedBox(width: 8),
            Icon(Icons.check_circle_rounded,
                color: AppTheme.sucesso,
                size: grande ? 40 : 30,
                semanticLabel: 'Tomado'),
          ],
        ]);
        if (tomado) return info;
        final botao = FilledButton.icon(
          onPressed: enviando ? null : () => onTomei(dose),
          style: FilledButton.styleFrom(
              minimumSize: Size(grande ? 150 : 120, grande ? 60 : 48),
              textStyle: TextStyle(
                  fontSize: grande ? 20 : 16, fontWeight: FontWeight.w700)),
          icon: enviando
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white))
              : const Icon(Icons.check_rounded),
          label: const Text('Tomei'),
        );
        // Em telas estreitas o botão desce e ocupa a largura toda.
        if (espaco.maxWidth >= 480) {
          return Row(children: [
            Expanded(child: info),
            const SizedBox(width: 12),
            botao,
          ]);
        }
        return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [info, const SizedBox(height: 10), botao]);
      }),
    );
  }
}
