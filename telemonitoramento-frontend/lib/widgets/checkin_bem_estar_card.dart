import 'package:flutter/material.dart';

import '../models/bem_estar.dart';
import '../theme/app_theme.dart';

/// Diário de bem-estar: uma pergunta por dia, quatro respostas grandes.
class CheckinBemEstarCard extends StatelessWidget {
  final CheckinBemEstar? hoje;
  final bool carregando;
  final bool erro;
  final bool enviando;
  final ValueChanged<Humor> onResponder;
  final bool grande;

  const CheckinBemEstarCard({
    super.key,
    required this.hoje,
    required this.onResponder,
    this.carregando = false,
    this.erro = false,
    this.enviando = false,
    this.grande = false,
  });

  @override
  Widget build(BuildContext context) {
    final respondido = hoje?.humor;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(grande ? 20 : 22),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppTheme.borda)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(Icons.favorite_outline_rounded,
              color: AppTheme.primaria, size: grande ? 30 : 22),
          const SizedBox(width: 10),
          Expanded(
              child: Text('Como você está se sentindo hoje?',
                  style: TextStyle(
                      fontSize: grande ? 22 : 17,
                      fontWeight: FontWeight.w600))),
        ]),
        const SizedBox(height: 8),
        Text(
            erro
                ? 'Não foi possível consultar sua resposta de hoje, mas você pode responder.'
                : respondido == null
                    ? 'Toque na opção que combina com você agora.'
                    : 'Hoje você respondeu "${respondido.rotulo}". Se mudar, é só tocar em outra opção.',
            style: TextStyle(
                fontSize: grande ? 17 : 14, color: AppTheme.textoSecundario)),
        const SizedBox(height: 14),
        if (carregando)
          const Center(child: CircularProgressIndicator())
        else
          LayoutBuilder(builder: (context, espaco) {
            final colunas = espaco.maxWidth >= 520 ? 4 : 2;
            final largura = (espaco.maxWidth - 10 * (colunas - 1)) / colunas;
            return Wrap(spacing: 10, runSpacing: 10, children: [
              for (final humor in Humor.values)
                SizedBox(
                  width: largura,
                  child: _Opcao(
                      humor: humor,
                      selecionado: humor == respondido,
                      grande: grande,
                      onTap: enviando ? null : () => onResponder(humor)),
                ),
            ]);
          }),
      ]),
    );
  }
}

class _Opcao extends StatelessWidget {
  final Humor humor;
  final bool selecionado;
  final bool grande;
  final VoidCallback? onTap;
  const _Opcao(
      {required this.humor,
      required this.selecionado,
      required this.grande,
      this.onTap});

  @override
  Widget build(BuildContext context) => Semantics(
        button: true,
        selected: selecionado,
        label: 'Estou ${humor.rotulo.toLowerCase()}',
        // Com excludeSemantics o InkWell some da árvore de acessibilidade;
        // sem este onTap, leitores de tela não conseguiriam acionar a opção.
        onTap: onTap,
        excludeSemantics: true,
        child: Material(
          color: selecionado ? humor.cor : humor.cor.withValues(alpha: .07),
          borderRadius: BorderRadius.circular(14),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(14),
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: grande ? 16 : 12),
              child: Column(children: [
                Icon(humor.icone,
                    size: grande ? 40 : 30,
                    color: selecionado ? Colors.white : humor.cor),
                const SizedBox(height: 6),
                Text(humor.rotulo,
                    style: TextStyle(
                        fontSize: grande ? 19 : 15,
                        fontWeight: FontWeight.w600,
                        color: selecionado ? Colors.white : AppTheme.texto)),
              ]),
            ),
          ),
        ),
      );
}
