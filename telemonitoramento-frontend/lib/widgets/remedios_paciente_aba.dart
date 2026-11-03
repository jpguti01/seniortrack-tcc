import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../models/medicamento.dart';
import '../theme/app_theme.dart';

/// Aba "Remédios" do cuidador: adesão dos últimos 30 dias, doses de hoje e
/// a rotina cadastrada (com foto), com edição e remoção.
class RemediosPacienteAba extends StatelessWidget {
  final Future<List<Medicamento>> medicamentos;
  final Future<List<Dose>> dosesHoje;
  final Future<List<Adesao>> adesao;
  final Future<void> Function() onRecarregar;
  final ValueChanged<Medicamento> onEditar;
  final ValueChanged<Medicamento> onRemover;

  const RemediosPacienteAba({
    super.key,
    required this.medicamentos,
    required this.dosesHoje,
    required this.adesao,
    required this.onRecarregar,
    required this.onEditar,
    required this.onRemover,
  });

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRecarregar,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
        children: [
          FutureBuilder<List<Adesao>>(
              future: adesao,
              builder: (_, snapshot) =>
                  _caixa('Adesão nos últimos 30 dias', _adesao(snapshot))),
          const SizedBox(height: 16),
          FutureBuilder<List<Dose>>(
              future: dosesHoje,
              builder: (_, snapshot) =>
                  _caixa('Doses de hoje', _doses(snapshot))),
          const SizedBox(height: 16),
          FutureBuilder<List<Medicamento>>(
              future: medicamentos,
              builder: (_, snapshot) =>
                  _caixa('Rotina de remédios', _rotina(snapshot))),
        ],
      ),
    );
  }

  Widget _caixa(String titulo, Widget conteudo) => Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.borda)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(titulo,
              style: GoogleFonts.sourceSerif4(
                  fontSize: 20, fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          conteudo,
        ]),
      );

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

  Widget _adesao(AsyncSnapshot<List<Adesao>> snapshot) {
    final estado = _estado(snapshot);
    if (estado != null) return estado;
    final itens = snapshot.data!;
    final geral = Adesao.geral(itens);
    if (geral == null) {
      return const Text('Ainda não há doses previstas neste período.',
          style: TextStyle(color: AppTheme.textoSecundario));
    }
    Color cor(double valor) => valor >= .8
        ? AppTheme.sucesso
        : valor >= .5
            ? AppTheme.atencao
            : AppTheme.alerta;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('${(geral * 100).round()}%',
          style: AppTheme.numeroDestaque(fontSize: 40, color: cor(geral))),
      const SizedBox(height: 4),
      const Text('das doses previstas foram confirmadas pelo paciente',
          style: TextStyle(fontSize: 13, color: AppTheme.textoSecundario)),
      const SizedBox(height: 14),
      for (final item in itens.where((a) => a.previstas > 0)) ...[
        Row(children: [
          Expanded(
              child: Text(
                  [item.nome, if (item.dosagem != null) item.dosagem!]
                      .join(' • '),
                  style: const TextStyle(fontWeight: FontWeight.w600))),
          Text('${item.tomadas}/${item.previstas}',
              style: const TextStyle(color: AppTheme.textoSecundario)),
        ]),
        const SizedBox(height: 6),
        LinearProgressIndicator(
            value: item.percentual,
            minHeight: 8,
            borderRadius: BorderRadius.circular(8),
            color: cor(item.percentual!),
            backgroundColor: AppTheme.borda,
            semanticsLabel: 'Adesão de ${item.nome}',
            semanticsValue: '${(item.percentual! * 100).round()}%'),
        const SizedBox(height: 12),
      ],
    ]);
  }

  Widget _doses(AsyncSnapshot<List<Dose>> snapshot) {
    final estado = _estado(snapshot);
    if (estado != null) return estado;
    final doses = [...snapshot.data!]
      ..sort((a, b) => a.horario.compareTo(b.horario));
    if (doses.isEmpty) {
      return const Text('Nenhuma dose prevista para hoje.',
          style: TextStyle(color: AppTheme.textoSecundario));
    }
    return Column(children: [
      for (final dose in doses)
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading:
              Text(dose.horario, style: AppTheme.numeroDestaque(fontSize: 20)),
          title: Text(dose.nome),
          subtitle: dose.dosagem == null ? null : Text(dose.dosagem!),
          trailing: _seloDose(dose),
        ),
    ]);
  }

  Widget _seloDose(Dose dose) {
    final cor = switch (dose.status) {
      StatusDose.tomado => AppTheme.sucesso,
      StatusDose.pendente => AppTheme.textoSecundario,
      StatusDose.atrasado => AppTheme.alerta,
    };
    final texto = dose.status == StatusDose.tomado && dose.confirmadaEm != null
        ? 'Tomado ${DateFormat('HH:mm').format(dose.confirmadaEm!.toLocal())}'
        : dose.status.rotulo;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
          color: cor.withValues(alpha: .1),
          borderRadius: BorderRadius.circular(8)),
      child: Text(texto,
          style:
              TextStyle(color: cor, fontWeight: FontWeight.w600, fontSize: 13)),
    );
  }

  Widget _rotina(AsyncSnapshot<List<Medicamento>> snapshot) {
    final estado = _estado(snapshot);
    if (estado != null) return estado;
    final remedios = snapshot.data!;
    if (remedios.isEmpty) {
      return const Text(
          'Nenhum remédio cadastrado. Use o botão "Novo remédio" para montar a rotina; o paciente confirma cada dose com "Tomei".',
          style: TextStyle(color: AppTheme.textoSecundario, height: 1.5));
    }
    return Column(children: [
      for (final remedio in remedios)
        Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
              color: const Color(0xFFF4F7F5),
              borderRadius: BorderRadius.circular(12)),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: SizedBox(
                width: 56,
                height: 56,
                child: remedio.fotoBytes == null
                    ? Container(
                        color: Colors.white,
                        child: const Icon(Icons.medication_outlined,
                            color: AppTheme.primaria))
                    : Image.memory(remedio.fotoBytes!, fit: BoxFit.cover),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                        [
                          remedio.nome,
                          if (remedio.dosagem != null) remedio.dosagem!
                        ].join(' • '),
                        style: const TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 15)),
                    const SizedBox(height: 4),
                    Text(remedio.horarios.join('  •  '),
                        style: const TextStyle(color: AppTheme.primaria)),
                    if (remedio.instrucoes != null) ...[
                      const SizedBox(height: 4),
                      Text(remedio.instrucoes!,
                          style: const TextStyle(
                              fontSize: 13, color: AppTheme.textoSecundario)),
                    ],
                  ]),
            ),
            IconButton(
                tooltip: 'Editar ${remedio.nome}',
                onPressed: () => onEditar(remedio),
                icon: const Icon(Icons.edit_outlined)),
            IconButton(
                tooltip: 'Remover ${remedio.nome}',
                onPressed: () => onRemover(remedio),
                icon: const Icon(Icons.delete_outline_rounded)),
          ]),
        ),
    ]);
  }
}
