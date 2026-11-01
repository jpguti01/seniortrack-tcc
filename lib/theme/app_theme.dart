import 'package:flutter/material.dart';

/// RNF02: alto contraste, botões com área de toque ampliada e fontes maiores
/// que o padrão, para favorecer o uso por pacientes idosos.
class AppTheme {
  static const Color primaria = Color(0xFF1565C0); // azul forte, alto contraste
  static const Color alerta = Color(0xFFC62828); // vermelho para alertas/erros
  static const Color sucesso = Color(0xFF2E7D32);
  static const Color fundo = Color(0xFFF5F7FA);

  static ThemeData get tema {
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaria,
        primary: primaria,
        error: alerta,
      ),
      scaffoldBackgroundColor: fundo,
      visualDensity: VisualDensity.comfortable,
    );

    return base.copyWith(
      textTheme: _escalarFontes(base.textTheme),
      appBarTheme: const AppBarTheme(
        backgroundColor: primaria,
        foregroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          minimumSize: const Size.fromHeight(56), // área de toque ampliada
          textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primaria, width: 2),
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 1,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        margin: const EdgeInsets.symmetric(vertical: 8),
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
