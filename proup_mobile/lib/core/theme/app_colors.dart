import 'package:flutter/material.dart';

/// Paleta de ProUp (tokens tomados del DESIGN.md de los mockups).
class AppColors {
  const AppColors._();

  // Superficies
  static const surface = Color(0xFFF8F9FF);
  static const surfaceDim = Color(0xFFCBDBF5);
  static const surfaceContainerLowest = Color(0xFFFFFFFF);
  static const surfaceContainerLow = Color(0xFFEFF4FF);
  static const surfaceContainer = Color(0xFFE5EEFF);
  static const surfaceContainerHigh = Color(0xFFDCE9FF);
  static const surfaceContainerHighest = Color(0xFFD3E4FE);

  // Texto
  static const onSurface = Color(0xFF0B1C30);
  static const onSurfaceVariant = Color(0xFF434656);
  static const outline = Color(0xFF737688);
  static const outlineVariant = Color(0xFFC3C5D9);
  static const inverseSurface = Color(0xFF213145);
  static const inverseOnSurface = Color(0xFFEAF1FF);

  // Primario (azul)
  static const primary = Color(0xFF003EC7);
  static const onPrimary = Color(0xFFFFFFFF);
  static const primaryContainer = Color(0xFF0052FF);
  static const onPrimaryContainer = Color(0xFFDFE3FF);
  static const primaryFixed = Color(0xFFDDE1FF);
  static const inversePrimary = Color(0xFFB7C4FF);

  // Secundario (gris)
  static const secondary = Color(0xFF5C5F61);
  static const secondaryContainer = Color(0xFFE0E3E5);

  // Terciario (verde éxito)
  static const tertiary = Color(0xFF005A3C);
  static const tertiaryContainer = Color(0xFF007550);
  static const onTertiaryContainer = Color(0xFF72FEC0);

  // Error
  static const error = Color(0xFFBA1A1A);
  static const errorContainer = Color(0xFFFFDAD6);
  static const onErrorContainer = Color(0xFF93000A);

  // Acentos de score
  static const scoreLow = Color(0xFFBA1A1A);
  static const scoreMid = Color(0xFFE0A100);
  static const scoreHigh = Color(0xFF007550);

  /// Sombra ambiental difusa y tenue, tintada de azul (DESIGN.md).
  static List<BoxShadow> get ambientShadow => [
        BoxShadow(
          color: const Color(0xFF003EC7).withValues(alpha: 0.06),
          blurRadius: 20,
          spreadRadius: 0,
          offset: const Offset(0, 6),
        ),
      ];
}
