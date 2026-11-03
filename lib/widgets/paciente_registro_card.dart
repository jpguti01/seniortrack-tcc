import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/sinal_vital.dart';
import '../models/tipo_sinal_vital.dart';
import '../theme/app_theme.dart';
import '../utils/formatar_medicao.dart';

class PacienteRegistroCard extends StatefulWidget {
  final TipoSinalVital tipo;
  final SinalVital? ultimo;
  final bool historicoDisponivel;
  final bool compacto;
  final VoidCallback onRegistrar;
  const PacienteRegistroCard(
      {super.key,
      required this.tipo,
      required this.ultimo,
      required this.historicoDisponivel,
      this.compacto = false,
      required this.onRegistrar});
  @override
  State<PacienteRegistroCard> createState() => _PacienteRegistroCardState();
}

class _PacienteRegistroCardState extends State<PacienteRegistroCard> {
  bool _foco = false;
  bool _hover = false;
  @override
  Widget build(BuildContext context) {
    final tipo = widget.tipo;
    final ultimo = widget.ultimo;
    return AnimatedContainer(
      duration: MediaQuery.disableAnimationsOf(context)
          ? Duration.zero
          : const Duration(milliseconds: 150),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
              color: _foco || _hover ? tipo.cor : AppTheme.borda, width: 2)),
      child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.onRegistrar,
            onFocusChange: (valor) => setState(() => _foco = valor),
            onHover: (valor) => setState(() => _hover = valor),
            borderRadius: BorderRadius.circular(16),
            focusColor: tipo.cor.withValues(alpha: .1),
            hoverColor: tipo.cor.withValues(alpha: .06),
            child: Padding(
                padding: const EdgeInsets.all(20),
                child: widget.compacto
                    ? _conteudoCompacto()
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(children: [
                            Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                    color: tipo.cor.withValues(alpha: .09),
                                    borderRadius: BorderRadius.circular(12)),
                                child: Icon(tipo.icone,
                                    color: tipo.cor, size: 25)),
                            const SizedBox(width: 12),
                            Expanded(
                                child: Text(tipo.rotulo,
                                    style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w600))),
                          ]),
                          const SizedBox(height: 16),
                          Text(
                              ultimo == null
                                  ? '— ${tipo.unidade}'
                                  : '${formatarMedicao(ultimo.valor)} ${tipo.unidade}',
                              style: AppTheme.numeroDestaque(fontSize: 29)),
                          const SizedBox(height: 7),
                          Text(
                              ultimo == null
                                  ? (widget.historicoDisponivel
                                      ? 'Nenhum registro ainda'
                                      : 'Última medição indisponível')
                                  : 'Último: ${DateFormat('dd/MM • HH:mm').format(ultimo.horaRegistro.toLocal())}',
                              style: const TextStyle(
                                  fontSize: 13,
                                  color: AppTheme.textoSecundario)),
                          const SizedBox(height: 20),
                          Row(children: [
                            Icon(Icons.add_circle_outline_rounded,
                                color: tipo.cor, size: 22),
                            const SizedBox(width: 8),
                            Text('Registrar',
                                style: TextStyle(
                                    color: tipo.cor,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 16))
                          ]),
                        ],
                      )),
          )),
    );
  }

  Widget _conteudoCompacto() {
    final tipo = widget.tipo;
    final ultimo = widget.ultimo;
    return Row(children: [
      Icon(tipo.icone, color: tipo.cor, size: 27),
      const SizedBox(width: 12),
      Expanded(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(tipo.rotulo,
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        Text(
            ultimo == null
                ? '— ${tipo.unidade}'
                : '${formatarMedicao(ultimo.valor)} ${tipo.unidade}',
            style: const TextStyle(fontSize: 15, color: AppTheme.texto)),
        const SizedBox(height: 4),
        Text(
            ultimo == null
                ? (widget.historicoDisponivel ? 'Sem registro' : 'Indisponível')
                : DateFormat('dd/MM • HH:mm')
                    .format(ultimo.horaRegistro.toLocal()),
            style:
                const TextStyle(fontSize: 12, color: AppTheme.textoSecundario)),
      ])),
      const SizedBox(width: 8),
      Column(children: [
        Icon(Icons.add_circle_outline_rounded, color: tipo.cor, size: 24),
        const SizedBox(height: 6),
        Text('Registrar',
            style: TextStyle(
                fontSize: 13, fontWeight: FontWeight.w600, color: tipo.cor)),
      ]),
    ]);
  }
}
