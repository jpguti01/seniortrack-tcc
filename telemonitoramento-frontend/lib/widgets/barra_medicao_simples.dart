import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/limiar.dart';
import '../models/sinal_vital.dart';
import '../models/status_medicao.dart';
import '../models/tipo_sinal_vital.dart';
import '../theme/app_theme.dart';
import '../utils/formatar_medicao.dart';

/// Versão simples do gráfico para o paciente: a última medição como um
/// marcador sobre uma barra com a faixa combinada com o cuidador em verde,
/// a zona de atenção em âmbar e a zona crítica em vermelho.
class BarraMedicaoSimples extends StatelessWidget {
  final TipoSinalVital tipo;
  final SinalVital? ultimo;
  final Limiar? limiar;

  const BarraMedicaoSimples(
      {super.key, required this.tipo, required this.ultimo, this.limiar});

  @override
  Widget build(BuildContext context) {
    final valor = ultimo?.valor;
    final status = valor == null || limiar == null
        ? null
        : StatusMedicao.classificar(valor, limiar!);
    final corStatus = switch (status) {
      StatusMedicao.normal => AppTheme.sucesso,
      StatusMedicao.atencao => AppTheme.atencao,
      StatusMedicao.critico => AppTheme.alerta,
      null => AppTheme.textoSecundario,
    };
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.borda)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(tipo.icone, color: tipo.cor, size: 28),
          const SizedBox(width: 10),
          Expanded(
              child: Text(tipo.rotulo,
                  style: const TextStyle(
                      fontSize: 19, fontWeight: FontWeight.w600))),
          if (valor != null)
            Text('${formatarMedicao(valor)} ${tipo.unidade}',
                style: AppTheme.numeroDestaque(fontSize: 28, color: corStatus)),
        ]),
        const SizedBox(height: 12),
        if (valor == null)
          const Text('Você ainda não registrou esta medição.',
              style: TextStyle(fontSize: 16, color: AppTheme.textoSecundario))
        else if (limiar == null)
          const Text(
              'Seu cuidador ainda não combinou uma faixa para esta medição.',
              style: TextStyle(fontSize: 16, color: AppTheme.textoSecundario))
        else ...[
          Semantics(
            label:
                '${tipo.rotulo}: ${formatarMedicao(valor)} ${tipo.unidade}, ${status!.rotulo.toLowerCase()}. Faixa combinada de ${formatarMedicao(limiar!.valorMinimo)} a ${formatarMedicao(limiar!.valorMaximo)}.',
            excludeSemantics: true,
            child: _Barra(valor: valor, limiar: limiar!, cor: corStatus),
          ),
          const SizedBox(height: 10),
          Text(_mensagem(status, valor),
              style: TextStyle(
                  fontSize: 17, fontWeight: FontWeight.w600, color: corStatus)),
          const SizedBox(height: 2),
          Text(
              'Faixa combinada: ${formatarMedicao(limiar!.valorMinimo)} a ${formatarMedicao(limiar!.valorMaximo)} ${tipo.unidade}',
              style: const TextStyle(
                  fontSize: 14, color: AppTheme.textoSecundario)),
        ],
        if (ultimo != null) ...[
          const SizedBox(height: 4),
          Text(
              'Medido em ${DateFormat("dd/MM 'às' HH:mm").format(ultimo!.horaRegistro.toLocal())}',
              style: const TextStyle(
                  fontSize: 14, color: AppTheme.textoSecundario)),
        ],
      ]),
    );
  }

  String _mensagem(StatusMedicao status, double valor) {
    final acima = valor > limiar!.valorMaximo;
    return switch (status) {
      StatusMedicao.normal => 'Dentro da faixa combinada',
      StatusMedicao.atencao =>
        acima ? 'Um pouco acima da faixa' : 'Um pouco abaixo da faixa',
      StatusMedicao.critico => acima
          ? 'Bem acima da faixa: avise seu cuidador'
          : 'Bem abaixo da faixa: avise seu cuidador',
    };
  }
}

class _Barra extends StatelessWidget {
  final double valor;
  final Limiar limiar;
  final Color cor;
  const _Barra({required this.valor, required this.limiar, required this.cor});

  @override
  Widget build(BuildContext context) {
    final minimo = limiar.valorMinimo;
    final maximo = limiar.valorMaximo;
    final criticoBaixo = minimo * (1 - StatusMedicao.margemCritica);
    final criticoAlto = maximo * (1 + StatusMedicao.margemCritica);
    final folga = (criticoAlto - criticoBaixo) * .12;
    var inicio = criticoBaixo - folga;
    var fim = criticoAlto + folga;
    if (valor < inicio) inicio = valor - folga;
    if (valor > fim) fim = valor + folga;
    final total = fim - inicio;
    int peso(double de, double ate) => ((ate - de) / total * 1000).round();
    final posicao = ((valor - inicio) / total).clamp(0.0, 1.0);

    return SizedBox(
      height: 34,
      child: Stack(alignment: Alignment.center, children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: SizedBox(
            height: 16,
            child: Row(children: [
              Expanded(
                  flex: peso(inicio, criticoBaixo),
                  child: Container(color: const Color(0xFFE9B9B3))),
              Expanded(
                  flex: peso(criticoBaixo, minimo),
                  child: Container(color: const Color(0xFFF2D7A6))),
              Expanded(
                  flex: peso(minimo, maximo),
                  child: Container(color: const Color(0xFFA9D3C5))),
              Expanded(
                  flex: peso(maximo, criticoAlto),
                  child: Container(color: const Color(0xFFF2D7A6))),
              Expanded(
                  flex: peso(criticoAlto, fim),
                  child: Container(color: const Color(0xFFE9B9B3))),
            ]),
          ),
        ),
        Align(
          alignment: Alignment(posicao * 2 - 1, 0),
          child: Container(
            width: 14,
            height: 34,
            decoration: BoxDecoration(
                color: cor,
                borderRadius: BorderRadius.circular(7),
                border: Border.all(color: Colors.white, width: 3)),
          ),
        ),
      ]),
    );
  }
}
