import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../models/alerta.dart';
import '../models/bem_estar.dart';
import '../models/chamado_sos.dart';
import '../models/limiar.dart';
import '../models/medicamento.dart';
import '../models/paciente.dart';
import '../models/sinal_vital.dart';
import '../models/status_medicao.dart';
import '../models/tipo_sinal_vital.dart';
import '../theme/app_brand.dart';
import '../utils/formatar_medicao.dart';

/// Resumo de um sinal vital no período, para o relatório clínico.
class EstatisticaSinal {
  final TipoSinalVital tipo;
  final int medicoes;
  final double? minimo;
  final double? media;
  final double? maximo;
  final Limiar? limiar;

  /// Medições fora da faixa; null quando não há faixa configurada.
  final int? foraDaFaixa;

  const EstatisticaSinal._(this.tipo, this.medicoes, this.minimo, this.media,
      this.maximo, this.limiar, this.foraDaFaixa);

  factory EstatisticaSinal.calcular(
      TipoSinalVital tipo, List<SinalVital> registros, Limiar? limiar) {
    final valores =
        registros.where((r) => r.tipo == tipo).map((r) => r.valor).toList();
    if (valores.isEmpty) {
      return EstatisticaSinal._(
          tipo, 0, null, null, null, limiar, limiar == null ? null : 0);
    }
    final soma = valores.reduce((a, b) => a + b);
    return EstatisticaSinal._(
      tipo,
      valores.length,
      valores.reduce((a, b) => a < b ? a : b),
      soma / valores.length,
      valores.reduce((a, b) => a > b ? a : b),
      limiar,
      limiar == null
          ? null
          : valores
              .where((v) =>
                  StatusMedicao.classificar(v, limiar) != StatusMedicao.normal)
              .length,
    );
  }
}

String _percentual(double? valor) =>
    valor == null ? '—' : '${(valor * 100).round()}%';

class RelatorioPacienteService {
  // Fontes locais mantêm acentos e pontuação no PDF, inclusive sem internet.
  static Future<pw.ThemeData>? _tema;
  static Future<pw.ThemeData> _carregarTema() => _tema ??= () async {
        final regular =
            await rootBundle.load('assets/fonts/WorkSans-Regular.ttf');
        final negrito = await rootBundle.load('assets/fonts/WorkSans-Bold.ttf');
        return pw.ThemeData.withFont(
          base: pw.Font.ttf(regular),
          bold: pw.Font.ttf(negrito),
        );
      }();

  /// Relatório para levar à consulta: medições do período com a faixa
  /// combinada, alertas por gravidade, adesão aos remédios, bem-estar e SOS.
  Future<Uint8List> gerarClinico({
    required Paciente paciente,
    required int dias,
    required DateTime emitidoEm,
    required List<SinalVital> registros,
    required List<Limiar> limiares,
    required List<Alerta> alertas,
    List<Adesao>? adesao,
    List<CheckinBemEstar>? checkins,
    List<ChamadoSos>? chamados,
  }) async {
    final inicio = DateTime(emitidoEm.year, emitidoEm.month, emitidoEm.day)
        .subtract(Duration(days: dias - 1));
    bool noPeriodo(DateTime data) => !data.toLocal().isBefore(inicio);
    final medicoes = registros.where((r) => noPeriodo(r.horaRegistro)).toList()
      ..sort((a, b) => b.horaRegistro.compareTo(a.horaRegistro));
    final alertasPeriodo = alertas.where((a) => noPeriodo(a.dataHora)).toList()
      ..sort((a, b) => b.dataHora.compareTo(a.dataHora));
    Limiar? limiarDe(TipoSinalVital tipo) {
      for (final l in limiares) {
        if (l.tipo == tipo) return l;
      }
      return null;
    }

    final data = DateFormat('dd/MM/yyyy');
    final dataHora = DateFormat('dd/MM/yyyy HH:mm');
    const verde = PdfColor.fromInt(0xFF0F5C53);
    pw.Widget secao(String titulo) => pw.Padding(
        padding: const pw.EdgeInsets.only(top: 18, bottom: 8),
        child: pw.Text(titulo,
            style: const pw.TextStyle(
                fontSize: 14, fontWeight: pw.FontWeight.bold, color: verde)));
    pw.Widget tabela(List<String> cabecalho, List<List<String>> linhas) =>
        pw.TableHelper.fromTextArray(
          headers: cabecalho,
          data: linhas,
          headerStyle: const pw.TextStyle(
              fontSize: 9,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.white),
          headerDecoration: const pw.BoxDecoration(color: verde),
          cellStyle: const pw.TextStyle(fontSize: 9),
          cellPadding: const pw.EdgeInsets.all(5),
        );
    pw.Widget nota(String texto) => pw.Text(texto,
        style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700));

    final criticos = alertasPeriodo.where((a) => a.critico).length;
    final persistentes = alertasPeriodo.where((a) => a.persistente).length;
    final checkinsPeriodo = (checkins ?? [])
        .where((c) => !c.data.isBefore(inicio))
        .toList()
      ..sort((a, b) => b.data.compareTo(a.data));
    final chamadosPeriodo =
        (chamados ?? []).where((c) => noPeriodo(c.criadoEm)).toList();

    final documento = pw.Document(
        title: '${AppBrand.nome} - Relatório clínico',
        author: AppBrand.nome,
        theme: await _carregarTema());
    documento.addPage(pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(36),
      header: (context) => context.pageNumber == 1
          ? pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                  pw.Text(AppBrand.nome,
                      style: const pw.TextStyle(
                          fontSize: 22, fontWeight: pw.FontWeight.bold)),
                  pw.SizedBox(height: 4),
                  pw.Text('Relatório clínico para consulta',
                      style: const pw.TextStyle(fontSize: 15)),
                  pw.SizedBox(height: 10),
                  pw.Text(
                      'Paciente: ${paciente.nome} • ${paciente.idade} anos'),
                  pw.Text(
                      'Período: ${data.format(inicio)} a ${data.format(emitidoEm)} ($dias dias)'),
                  pw.Text(
                      'Emitido em: ${dataHora.format(emitidoEm.toLocal())}'),
                ])
          : pw.SizedBox(),
      footer: (context) => pw.Padding(
          padding: const pw.EdgeInsets.only(top: 12),
          child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Expanded(
                    child: pw.Text(
                        'Dados informados pelo paciente e pelo cuidador no ${AppBrand.nome}. As faixas são as combinadas para este paciente e não substituem a avaliação médica.',
                        style: const pw.TextStyle(fontSize: 8))),
                pw.SizedBox(width: 12),
                pw.Text('${context.pageNumber}/${context.pagesCount}',
                    style: const pw.TextStyle(fontSize: 9)),
              ])),
      build: (_) => [
        secao('Sinais vitais'),
        tabela([
          'Sinal vital',
          'Medições',
          'Mínimo',
          'Média',
          'Máximo',
          'Faixa combinada',
          'Fora da faixa'
        ], [
          for (final tipo in TipoSinalVital.values)
            () {
              final e =
                  EstatisticaSinal.calcular(tipo, medicoes, limiarDe(tipo));
              String valor(double? v) => v == null
                  ? '—'
                  : '${formatarMedicao(double.parse(v.toStringAsFixed(1)))} ${tipo.unidade}';
              return [
                tipo.rotulo,
                '${e.medicoes}',
                valor(e.minimo),
                valor(e.media),
                valor(e.maximo),
                e.limiar == null
                    ? 'Não definida'
                    : '${formatarMedicao(e.limiar!.valorMinimo)} a ${formatarMedicao(e.limiar!.valorMaximo)}',
                e.foraDaFaixa == null ? '—' : '${e.foraDaFaixa}',
              ];
            }(),
        ]),
        secao('Alertas'),
        if (alertasPeriodo.isEmpty)
          nota('Nenhum alerta no período.')
        else ...[
          nota(
              '${alertasPeriodo.length} alerta(s): $criticos crítico(s), ${alertasPeriodo.length - criticos} de atenção; $persistentes repetido(s) em dias seguidos.'),
          pw.SizedBox(height: 6),
          tabela([
            'Data e hora',
            'Sinal vital',
            'Valor',
            'Gravidade',
            'Situação'
          ], [
            for (final a in alertasPeriodo.take(40))
              [
                dataHora.format(a.dataHora.toLocal()),
                a.tipoSinal.rotulo,
                a.medicao,
                a.persistente
                    ? '${a.gravidade.rotulo} (repetido)'
                    : a.gravidade.rotulo,
                a.resolvido ? 'Resolvido' : 'Pendente',
              ],
          ]),
          if (alertasPeriodo.length > 40)
            nota('Mostrando os 40 alertas mais recentes.'),
        ],
        secao('Remédios'),
        if (adesao == null)
          nota('Adesão indisponível no momento da emissão.')
        else if (adesao.isEmpty)
          nota('Nenhum remédio cadastrado.')
        else ...[
          nota(
              'Adesão geral: ${_percentual(Adesao.geral(adesao))} das doses previstas foram confirmadas pelo paciente.'),
          pw.SizedBox(height: 6),
          tabela([
            'Remédio',
            'Dosagem',
            'Doses previstas',
            'Confirmadas',
            'Adesão'
          ], [
            for (final a in adesao)
              [
                a.ativo ? a.nome : '${a.nome} (suspenso)',
                a.dosagem ?? '—',
                '${a.previstas}',
                '${a.tomadas}',
                _percentual(a.percentual),
              ],
          ]),
        ],
        secao('Bem-estar relatado'),
        if (checkins == null)
          nota('Diário de bem-estar indisponível no momento da emissão.')
        else if (checkinsPeriodo.isEmpty)
          nota('Nenhum check-in no período.')
        else ...[
          nota([
            for (final humor in Humor.values)
              '${humor.rotulo}: ${checkinsPeriodo.where((c) => c.humor == humor).length}'
          ].join(' • ')),
          if (checkinsPeriodo.any((c) => c.humor.preocupante)) ...[
            pw.SizedBox(height: 6),
            tabela([
              'Data',
              'Como estava',
              'Observação'
            ], [
              for (final c in checkinsPeriodo.where((c) => c.humor.preocupante))
                [data.format(c.data), c.humor.rotulo, c.observacao ?? '—'],
            ]),
          ],
        ],
        secao('Pedidos de ajuda (SOS)'),
        if (chamados == null)
          nota('Histórico de SOS indisponível no momento da emissão.')
        else if (chamadosPeriodo.isEmpty)
          nota('Nenhum pedido de ajuda no período.')
        else
          tabela([
            'Pedido em',
            'Atendido em'
          ], [
            for (final c in chamadosPeriodo)
              [
                dataHora.format(c.criadoEm.toLocal()),
                c.atendidoEm == null
                    ? 'Em aberto'
                    : dataHora.format(c.atendidoEm!.toLocal()),
              ],
          ]),
      ],
    ));
    return documento.save();
  }

  Future<Uint8List> gerar(
      {required String nome,
      required String periodo,
      required List<SinalVital> registros,
      required DateTime emitidoEm}) async {
    final documento = pw.Document(
        title: '${AppBrand.nome} - Histórico de sinais vitais',
        author: AppBrand.nome,
        theme: await _carregarTema());
    documento.addPage(pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(36),
      header: (_) =>
          pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
        pw.Text(AppBrand.nome,
            style: const pw.TextStyle(
                fontSize: 22, fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 8),
        pw.Text('Histórico de sinais vitais',
            style: const pw.TextStyle(fontSize: 16)),
        pw.SizedBox(height: 12),
        pw.Text('Paciente: $nome'),
        pw.Text('Período: $periodo'),
        pw.Text(
            'Emitido em: ${DateFormat('dd/MM/yyyy HH:mm').format(emitidoEm.toLocal())}'),
        pw.SizedBox(height: 16),
      ]),
      footer: (context) => pw.Padding(
          padding: const pw.EdgeInsets.only(top: 12),
          child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('Registros informados pelo paciente.',
                    style: const pw.TextStyle(fontSize: 9)),
                pw.Text('${context.pageNumber}/${context.pagesCount}',
                    style: const pw.TextStyle(fontSize: 9)),
              ])),
      build: (_) => [
        pw.TableHelper.fromTextArray(
          headers: ['Data e hora', 'Sinal vital', 'Valor', 'Unidade'],
          data: registros
              .map((s) => [
                    DateFormat('dd/MM/yyyy HH:mm')
                        .format(s.horaRegistro.toLocal()),
                    s.tipo.rotulo,
                    formatarMedicao(s.valor),
                    s.tipo.unidade
                  ])
              .toList(),
          headerStyle: const pw.TextStyle(
              fontWeight: pw.FontWeight.bold, color: PdfColors.white),
          headerDecoration:
              const pw.BoxDecoration(color: PdfColor.fromInt(0xFF0F5C53)),
          cellStyle: const pw.TextStyle(fontSize: 10),
          cellPadding: const pw.EdgeInsets.all(8),
        )
      ],
    ));
    return documento.save();
  }
}
