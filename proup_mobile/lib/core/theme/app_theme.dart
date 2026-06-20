import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

class AppTheme {
  const AppTheme._();

  // Compatibilidad con código previo
  static const primaryColor = AppColors.primary;
  static const secondaryColor = AppColors.secondary;
  static const tertiaryColor = AppColors.tertiaryContainer;
  static const surfaceColor = AppColors.surface;
  static const textColor = AppColors.onSurface;
  static const mutedTextColor = AppColors.onSurfaceVariant;

  static ThemeData get light {
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        primary: AppColors.primary,
        onPrimary: AppColors.onPrimary,
        primaryContainer: AppColors.primaryContainer,
        secondary: AppColors.secondary,
        tertiary: AppColors.tertiaryContainer,
        surface: AppColors.surface,
        onSurface: AppColors.onSurface,
        error: AppColors.error,
      ),
    );

    const t = TextTheme(
      displayLarge: TextStyle(fontSize: 44, fontWeight: FontWeight.w700, height: 1.12, letterSpacing: -0.5, color: AppColors.onSurface),
      headlineMedium: TextStyle(fontSize: 28, fontWeight: FontWeight.w700, height: 1.18, letterSpacing: -0.3, color: AppColors.onSurface),
      headlineSmall: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, height: 1.2, color: AppColors.onSurface),
      titleLarge: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, height: 1.3, color: AppColors.onSurface),
      titleMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.onSurface),
      bodyLarge: TextStyle(fontSize: 17, fontWeight: FontWeight.w400, height: 1.5, color: AppColors.onSurfaceVariant),
      bodyMedium: TextStyle(fontSize: 15, fontWeight: FontWeight.w400, height: 1.45, color: AppColors.onSurfaceVariant),
      bodySmall: TextStyle(fontSize: 13, fontWeight: FontWeight.w400, height: 1.4, color: AppColors.onSurfaceVariant),
      labelLarge: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.onSurface),
      labelSmall: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, letterSpacing: 0.6, color: AppColors.onSurfaceVariant),
    );

    return base.copyWith(
      scaffoldBackgroundColor: AppColors.surface,
      textTheme: GoogleFonts.interTextTheme(t),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(56),
          elevation: 0,
          textStyle: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          minimumSize: const Size.fromHeight(54),
          side: const BorderSide(color: AppColors.outlineVariant),
          textStyle: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          textStyle: GoogleFonts.inter(fontWeight: FontWeight.w600),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceContainerLowest,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        hintStyle: const TextStyle(color: AppColors.outline),
        border: _inputBorder(AppColors.outlineVariant),
        enabledBorder: _inputBorder(AppColors.outlineVariant),
        focusedBorder: _inputBorder(AppColors.primary, width: 2),
        errorBorder: _inputBorder(AppColors.error),
      ),
      cardTheme: CardThemeData(
        color: AppColors.surfaceContainerLowest,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      appBarTheme: const AppBarTheme(
        centerTitle: false,
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.onSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.surfaceContainerLowest,
        indicatorColor: AppColors.surfaceContainerHigh,
        elevation: 0,
        height: 68,
        labelTextStyle: WidgetStateProperty.all(
          GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w500, color: AppColors.onSurfaceVariant),
        ),
      ),
      chipTheme: const ChipThemeData(
        backgroundColor: AppColors.surfaceContainer,
        side: BorderSide.none,
      ),
      dividerTheme: const DividerThemeData(color: AppColors.outlineVariant, thickness: 1),
    );
  }

  static OutlineInputBorder _inputBorder(Color color, {double width = 1}) => OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: color, width: width),
      );
}
