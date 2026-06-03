import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

/// Builds the QuestBoard RPG theme for both dark and light modes.
abstract final class AppTheme {
  static ThemeData dark() => _build(Brightness.dark, AppPalette.dark);

  static ThemeData light() => _build(Brightness.light, AppPalette.light);

  static ThemeData _build(Brightness brightness, AppPalette palette) {
    final isDark = brightness == Brightness.dark;
    final cinzel = GoogleFonts.cinzelTextTheme();
    final nunito = GoogleFonts.nunitoTextTheme();
    final rajdhani = GoogleFonts.rajdhaniTextTheme();
    final primary = isDark ? AppColors.gold : AppColors.goldDark;

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      scaffoldBackgroundColor: palette.background,
      extensions: [palette],
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.gold,
        brightness: brightness,
        primary: primary,
        secondary: AppColors.xpBlue,
        surface: palette.surface,
        onSurface: palette.textPrimary,
        error: AppColors.danger,
      ),
      textTheme: TextTheme(
        displayLarge: cinzel.displayLarge?.copyWith(
          fontSize: 32,
          fontWeight: FontWeight.w800,
          color: palette.textPrimary,
          letterSpacing: 0,
        ),
        headlineMedium: cinzel.headlineMedium?.copyWith(
          fontSize: 22,
          fontWeight: FontWeight.w700,
          color: palette.heading,
          letterSpacing: 0,
        ),
        titleLarge: cinzel.titleLarge?.copyWith(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: palette.textPrimary,
          letterSpacing: 0,
        ),
        titleMedium: nunito.titleMedium?.copyWith(
          fontWeight: FontWeight.w700,
          color: palette.textPrimary,
          letterSpacing: 0,
        ),
        bodyLarge: nunito.bodyLarge?.copyWith(
          fontSize: 16,
          color: palette.textPrimary,
          letterSpacing: 0,
        ),
        bodyMedium: nunito.bodyMedium?.copyWith(
          fontSize: 14,
          color: palette.textSecondary,
          letterSpacing: 0,
        ),
        bodySmall: nunito.bodySmall?.copyWith(
          color: palette.textSecondary,
          letterSpacing: 0,
        ),
        labelLarge: cinzel.labelLarge?.copyWith(
          fontWeight: FontWeight.w800,
          color: AppColors.onAccent,
          letterSpacing: 0,
        ),
        labelSmall: rajdhani.labelSmall?.copyWith(
          fontSize: 12,
          color: palette.heading,
          fontWeight: FontWeight.w700,
          letterSpacing: 0,
        ),
      ),
      iconTheme: IconThemeData(color: palette.textPrimary),
      appBarTheme: AppBarTheme(
        backgroundColor: palette.background,
        surfaceTintColor: Colors.transparent,
        centerTitle: false,
        iconTheme: IconThemeData(color: palette.textPrimary),
        titleTextStyle: GoogleFonts.cinzel(
          fontSize: 22,
          fontWeight: FontWeight.w800,
          color: palette.heading,
          letterSpacing: 0,
        ),
      ),
      cardTheme: CardThemeData(
        color: palette.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: palette.border),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: palette.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: palette.border),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: palette.surface,
        hintStyle: TextStyle(color: palette.textSecondary),
        labelStyle: TextStyle(color: palette.textSecondary),
        prefixIconColor: primary,
        suffixIconColor: palette.textSecondary,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: palette.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: primary, width: 1.4),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.danger),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.danger, width: 1.4),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: AppColors.onAccent,
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          textStyle: GoogleFonts.cinzel(fontWeight: FontWeight.w800),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: primary),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: palette.surfaceAlt,
        selectedColor: AppColors.gold,
        disabledColor: palette.surface,
        side: BorderSide(color: palette.border),
        labelStyle: TextStyle(color: palette.textSecondary),
        secondaryLabelStyle: const TextStyle(
          color: AppColors.onAccent,
          fontWeight: FontWeight.w800,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: palette.navBackground,
        selectedItemColor: primary,
        unselectedItemColor: palette.textSecondary,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: palette.surface,
        contentTextStyle: TextStyle(color: palette.textPrimary),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        behavior: SnackBarBehavior.floating,
      ),
      dividerColor: palette.border,
    );
  }
}
