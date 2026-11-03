import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/alerta.dart';

/// Identidade visual do app: verde-petróleo profundo (saúde, confiança) sobre
/// marfim quente - não o azul Material padrão, não o clichê creme+terracota.
/// Números de sinais vitais usam a serifa Source Serif 4 (peso visual de "isto
/// importa"); o resto da interface usa Work Sans, humanista e muito legível
/// em tamanhos grandes (RNF02: acessibilidade para pacientes idosos).
class AppTheme {
  static const Color primaria = Color(0xFF0F5C53);
  static const Color primariaClara = Color(0xFF4F9A8B);
  static const Color fundo = Color(0xFFFAF7F2);
  static const Color texto = Color(0xFF2A2521);
  static const Color alerta = Color(0xFFB5433A);
  static const Color sucesso = Color(0xFF3F7D6E);
  static const Color textoSecundario = Color(0xFF59615D);
  static const Color borda = Color(0xFFDEE5E0);
  static const Color atencao = Color(0xFF875300);
  static const Color alertaFundo = Color(0xFFFFF1EE);
  static const Color atencaoFundo = Color(0xFFFFF7EA);

  // Gravidade de alertas e medições: crítico em vermelho, atenção em âmbar.
  // O texto do selo também diz a gravidade, para não depender só da cor.
  static Color corGravidade(GravidadeAlerta gravidade) =>
      gravidade == GravidadeAlerta.critico ? alerta : atencao;
  static Color fundoGravidade(GravidadeAlerta gravidade) =>
      gravidade == GravidadeAlerta.critico ? alertaFundo : atencaoFundo;

  static TextStyle numeroDestaque({double fontSize = 24, Color? color, FontWeight? fontWeight}) {
    return GoogleFonts.sourceSerif4(
      fontSize: fontSize,
      fontWeight: fontWeight ?? FontWeight.w600,
      color: color ?? texto,
      height: 1,
    );
  }

  static ThemeData get tema {
    final corpoTexto = GoogleFonts.workSansTextTheme().apply(
      bodyColor: texto,
      displayColor: texto,
    );

    final base = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaria,
        primary: primaria,
        secondary: primariaClara,
        error: alerta,
        surface: Colors.white,
      ),
      scaffoldBackgroundColor: fundo,
      visualDensity: VisualDensity.comfortable,
      textTheme: _escalarFontes(corpoTexto),
    );

    return base.copyWith(
      appBarTheme: AppBarTheme(
        backgroundColor: primaria,
        foregroundColor: Colors.white,
        centerTitle: false,
        elevation: 0,
        titleTextStyle: GoogleFonts.workSans(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaria,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(56), // área de toque ampliada (RNF02)
          textStyle: GoogleFonts.workSans(fontSize: 17, fontWeight: FontWeight.w600),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaria,
          side: const BorderSide(color: primaria, width: 1.4),
          minimumSize: const Size.fromHeight(56),
          textStyle: GoogleFonts.workSans(fontSize: 17, fontWeight: FontWeight.w600),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaria,
          textStyle: GoogleFonts.workSans(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        labelStyle: GoogleFonts.workSans(color: texto.withValues(alpha: 0.65)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: texto.withValues(alpha: 0.15)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: texto.withValues(alpha: 0.15)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primaria, width: 2),
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        margin: const EdgeInsets.symmetric(vertical: 6),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: primaria,
        foregroundColor: Colors.white,
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: SegmentedButton.styleFrom(
          selectedBackgroundColor: primaria,
          selectedForegroundColor: Colors.white,
          minimumSize: const Size.fromHeight(52),
          textStyle: GoogleFonts.workSans(fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  // Aumenta a fonte em 10% (RNF02), só nos estilos que já têm um tamanho
  // definido — TextStyle.apply(fontSizeFactor:) quebra se algum estilo do
  // tema base tiver fontSize nulo, o que o Material 3 por padrão tem.
  static TextTheme _escalarFontes(TextTheme t) {
    TextStyle? escalar(TextStyle? s) =>
        (s == null || s.fontSize == null) ? s : s.copyWith(fontSize: s.fontSize! * 1.1);

    return t.copyWith(
      displayLarge: escalar(t.displayLarge),
      displayMedium: escalar(t.displayMedium),
      displaySmall: escalar(t.displaySmall),
      headlineLarge: escalar(t.headlineLarge),
      headlineMedium: escalar(t.headlineMedium),
      headlineSmall: escalar(t.headlineSmall),
      titleLarge: escalar(t.titleLarge),
      titleMedium: escalar(t.titleMedium),
      titleSmall: escalar(t.titleSmall),
      bodyLarge: escalar(t.bodyLarge),
      bodyMedium: escalar(t.bodyMedium),
      bodySmall: escalar(t.bodySmall),
      labelLarge: escalar(t.labelLarge),
      labelMedium: escalar(t.labelMedium),
      labelSmall: escalar(t.labelSmall),
    );
  }
}
