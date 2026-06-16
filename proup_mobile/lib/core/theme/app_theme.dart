import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  const AppTheme._();

  static const primaryColor = Color(0xFF003EC7);
  static const secondaryColor = Color(0xFF5C5F61);
  static const tertiaryColor = Color(0xFF007550);
  static const surfaceColor = Color(0xFFF8F9FF);
  static const textColor = Color(0xFF0B1C30);
  static const mutedTextColor = Color(0xFF434656);

  static ThemeData get light {
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        primary: primaryColor,
        secondary: secondaryColor,
        tertiary: tertiaryColor,
        surface: surfaceColor,
        onSurface: textColor,
      ),
    );

    const customText = TextTheme(
      headlineMedium: TextStyle(fontSize: 32, height: 1.25, fontWeight: FontWeight.w800, color: textColor),
      headlineSmall: TextStyle(fontSize: 24, height: 1.25, fontWeight: FontWeight.w800, color: textColor),
      titleLarge: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: textColor),
      titleMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: textColor),
      bodyLarge: TextStyle(fontSize: 18, height: 1.45, color: mutedTextColor),
      bodyMedium: TextStyle(fontSize: 16, height: 1.4, color: textColor),
      bodySmall: TextStyle(fontSize: 13, height: 1.4, color: mutedTextColor),
    );

    return base.copyWith(
      scaffoldBackgroundColor: surfaceColor,
      textTheme: GoogleFonts.interTextTheme(customText),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(54),
          textStyle: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: mutedTextColor),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFE2E5F0)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFE2E5F0)),
        ),
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
      appBarTheme: const AppBarTheme(
        centerTitle: false,
        backgroundColor: surfaceColor,
        foregroundColor: textColor,
        elevation: 0,
      ),
    );
  }
}
