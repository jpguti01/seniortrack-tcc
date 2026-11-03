import 'package:flutter/material.dart';
import '../theme/app_brand.dart';

/// A arte original já contém o nome e o slogan; não duplica esses textos.
class SeniorTrackLogo extends StatelessWidget {
  final double altura;
  const SeniorTrackLogo({super.key, this.altura = 220});

  @override
  Widget build(BuildContext context) => ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Image.asset(AppBrand.logo,
            height: altura,
            fit: BoxFit.contain,
            filterQuality: FilterQuality.high,
            semanticLabel: '${AppBrand.nome}, Cuidado & Saúde'),
      );
}

class SeniorTrackHeader extends StatelessWidget {
  const SeniorTrackHeader({super.key});

  @override
  Widget build(BuildContext context) =>
      Row(mainAxisSize: MainAxisSize.min, children: [
        ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.asset(AppBrand.emblema,
                width: 32,
                height: 32,
                filterQuality: FilterQuality.high,
                excludeFromSemantics: true)),
        const SizedBox(width: 10),
        const Flexible(
            child: Text(AppBrand.nome,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 18))),
      ]);
}
