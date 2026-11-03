import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../models/bem_estar.dart';
import '../models/chamado_sos.dart';
import '../theme/app_theme.dart';

/// Aba "Bem-estar" do cuidador: diário dos últimos 30 dias e pedidos de SOS.
class BemEstarPacienteAba extends StatelessWidget {
  final Future<List<CheckinBemEstar>> checkins;
  final Future<List<ChamadoSos>> chamados;
  final Future<void> Function() onRecarregar;

  const BemEstarPacienteAba({
    super.key,
    required this.checkins,
    required this.chamados,
    required this.onRecarregar,
  });

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRecarregar,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
        children: [
          _titulo('Como o paciente se sentiu'),
          const SizedBox(height: 4),
          const Text('Respostas do check-in diário nos últimos 30 dias.',
              style: TextStyle(fontSize: 13, color: AppTheme.textoSecundario)),
          const SizedBox(height: 12),
          FutureBuilder<List<CheckinBemEstar>>(
              future: checkins, builder: (_, s) => _checkins(s)),
          const SizedBox(height: 28),
          _titulo('Pedidos de ajuda (SOS)'),
          const SizedBox(height: 12),
          FutureBuilder<List<ChamadoSos>>(
              future: chamados, builder: (_, s) => _chamados(s)),
        ],
      ),
    );
  }

  Widget _titulo(String texto) => Text(texto,
      style:
          GoogleFonts.sourceSerif4(fontSize: 20, fontWeight: FontWeight.w600));

  Widget? _estado<T>(AsyncSnapshot<T> snapshot) {
    if (snapshot.connectionState == ConnectionState.waiting) {
      return const Center(child: CircularProgressIndicator());
    }
    if (snapshot.hasError) {
      return const Text('Não foi possível carregar. Puxe para atualizar.',
          style: TextStyle(color: AppTheme.textoSecundario));
    }
    return null;
  }

  Widget _checkins(AsyncSnapshot<List<CheckinBemEstar>> snapshot) {
    final estado = _estado(snapshot);
    if (estado != null) return estado;
    final lista = [...snapshot.data!]..sort((a, b) => b.data.compareTo(a.data));
    if (lista.isEmpty) {
      return const Text('O paciente ainda não respondeu o check-in.',
          style: TextStyle(color: AppTheme.textoSecundario));
    }
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Wrap(spacing: 8, runSpacing: 8, children: [
        for (final humor in Humor.values)
          Chip(
            avatar: Icon(humor.icone, size: 18, color: humor.cor),
            label: Text(
                '${humor.rotulo}: ${lista.where((c) => c.humor == humor).length}'),
          ),
      ]),
      const SizedBox(height: 12),
      for (final checkin in lista)
        Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color:
                checkin.humor.preocupante ? AppTheme.alertaFundo : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: checkin.humor.cor.withValues(alpha: .35)),
          ),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Icon(checkin.humor.icone, color: checkin.humor.cor, size: 28),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                        '${DateFormat('dd/MM').format(checkin.data)} • ${checkin.humor.rotulo}',
                        style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: checkin.humor.cor)),
                    if (checkin.observacao != null) ...[
                      const SizedBox(height: 4),
                      Text('"${checkin.observacao}"',
                          style: const TextStyle(height: 1.4)),
                    ],
                    const SizedBox(height: 2),
                    Text(
                        'Respondido às ${DateFormat('HH:mm').format(checkin.registradoEm.toLocal())}',
                        style: const TextStyle(
                            fontSize: 12, color: AppTheme.textoSecundario)),
                  ]),
            ),
          ]),
        ),
    ]);
  }

  Widget _chamados(AsyncSnapshot<List<ChamadoSos>> snapshot) {
    final estado = _estado(snapshot);
    if (estado != null) return estado;
    final lista = [...snapshot.data!]
      ..sort((a, b) => b.criadoEm.compareTo(a.criadoEm));
    if (lista.isEmpty) {
      return const Text('Nenhum pedido de ajuda nos últimos 30 dias.',
          style: TextStyle(color: AppTheme.textoSecundario));
    }
    final formato = DateFormat("dd/MM 'às' HH:mm");
    return Column(children: [
      for (final chamado in lista)
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: Icon(Icons.sos_rounded,
              color: chamado.atendido
                  ? AppTheme.textoSecundario
                  : AppTheme.alerta),
          title:
              Text('Pedido em ${formato.format(chamado.criadoEm.toLocal())}'),
          subtitle: Text(chamado.atendidoEm == null
              ? 'Em aberto'
              : 'Atendido em ${formato.format(chamado.atendidoEm!.toLocal())}'),
        ),
    ]);
  }
}
