import 'package:flutter/material.dart';

/// Theme-aware surface and text colors for QuestBoard.
///
/// Brand accents (gold, XP blue, difficulty colors) live in [AppColors] and stay
/// constant across themes. Everything that must flip between dark and light mode
/// lives here and is read through `context.palette`.
@immutable
class AppPalette extends ThemeExtension<AppPalette> {
  const AppPalette({
    required this.background,
    required this.surface,
    required this.surfaceAlt,
    required this.border,
    required this.textPrimary,
    required this.textSecondary,
    required this.navBackground,
    required this.heading,
  });

  /// Scaffold / page background.
  final Color background;

  /// Card and panel background.
  final Color surface;

  /// Elevated or alternate surface (chips, avatars, inner panels).
  final Color surfaceAlt;

  /// Hairline borders and dividers.
  final Color border;

  /// Primary body text.
  final Color textPrimary;

  /// Secondary / muted text.
  final Color textSecondary;

  /// Bottom navigation background.
  final Color navBackground;

  /// Gold tone used for headings and accents with adequate contrast per theme.
  final Color heading;

  static const dark = AppPalette(
    background: Color(0xFF0A0E1A),
    surface: Color(0xFF141824),
    surfaceAlt: Color(0xFF1A2035),
    border: Color(0xFF252D45),
    textPrimary: Color(0xFFE8EBF0),
    textSecondary: Color(0xFF8892A4),
    navBackground: Color(0xFF0D1117),
    heading: Color(0xFFF6C90E),
  );

  static const light = AppPalette(
    background: Color(0xFFF4F6FC),
    surface: Color(0xFFFFFFFF),
    surfaceAlt: Color(0xFFEAEEF7),
    border: Color(0xFFD7DEEC),
    textPrimary: Color(0xFF161B2E),
    textSecondary: Color(0xFF5B6678),
    navBackground: Color(0xFFFFFFFF),
    heading: Color(0xFFB8860B),
  );

  @override
  AppPalette copyWith({
    Color? background,
    Color? surface,
    Color? surfaceAlt,
    Color? border,
    Color? textPrimary,
    Color? textSecondary,
    Color? navBackground,
    Color? heading,
  }) {
    return AppPalette(
      background: background ?? this.background,
      surface: surface ?? this.surface,
      surfaceAlt: surfaceAlt ?? this.surfaceAlt,
      border: border ?? this.border,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      navBackground: navBackground ?? this.navBackground,
      heading: heading ?? this.heading,
    );
  }

  @override
  AppPalette lerp(ThemeExtension<AppPalette>? other, double t) {
    if (other is! AppPalette) {
      return this;
    }
    return AppPalette(
      background: Color.lerp(background, other.background, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      surfaceAlt: Color.lerp(surfaceAlt, other.surfaceAlt, t)!,
      border: Color.lerp(border, other.border, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      navBackground: Color.lerp(navBackground, other.navBackground, t)!,
      heading: Color.lerp(heading, other.heading, t)!,
    );
  }
}

/// Convenient access to the active [AppPalette] from any widget context.
extension AppPaletteX on BuildContext {
  AppPalette get palette =>
      Theme.of(this).extension<AppPalette>() ?? AppPalette.dark;
}
