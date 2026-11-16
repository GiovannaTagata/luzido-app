import 'package:flutter/material.dart';

/// Cores e tamanhos do app (RNF04 — acessibilidade).
/// Textos escuros sobre fundo claro (contraste alto) e botões grandes.
class CoresLuzido {
  static const lilas = Color(0xFF6B4FA0);
  static const laranja = Color(0xFFC25E00);
  static const laranjaClaro = Color(0xFFFFF1E0);
  static const verde = Color(0xFF1E7B45);
  static const texto = Color(0xFF2B2235);
  static const fundo = Color(0xFFFBF8F4);
}

ThemeData temaLuzido() {
  final esquema = ColorScheme.fromSeed(
    seedColor: CoresLuzido.lilas,
    primary: CoresLuzido.lilas,
    surface: CoresLuzido.fundo,
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: esquema,
    scaffoldBackgroundColor: CoresLuzido.fundo,
    textTheme: const TextTheme(
      bodyLarge: TextStyle(fontSize: 18, color: CoresLuzido.texto),
      bodyMedium: TextStyle(fontSize: 16, color: CoresLuzido.texto),
      titleLarge: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: CoresLuzido.texto,
      ),
    ),
    // Área de toque mínima de 48 dp em todos os botões.
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(48, 56),
        textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(48, 56),
        foregroundColor: CoresLuzido.lilas,
        side: const BorderSide(color: CoresLuzido.lilas, width: 2),
        textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    ),
    inputDecorationTheme: const InputDecorationTheme(
      border: OutlineInputBorder(),
      labelStyle: TextStyle(fontSize: 18),
    ),
  );
}
