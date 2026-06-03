import 'package:flutter/material.dart';

export 'app_palette.dart';

/// Brand accent palette for QuestBoard.
///
/// These colors read the same in light and dark mode. Theme-dependent surfaces
/// and text colors live in [AppPalette] and are read via `context.palette`.
abstract final class AppColors {
  static const gold = Color(0xFFF6C90E);
  static const goldDark = Color(0xFFE8A500);
  static const goldGlow = Color(0x33F6C90E);
  static const xpBlue = Color(0xFF3D9CF0);
  static const easy = Color(0xFF4CAF50);
  static const medium = Color(0xFFFF9800);
  static const hard = Color(0xFFE53935);
  static const danger = Color(0xFFFF5C65);
  static const silver = Color(0xFFC0C7D1);
  static const bronze = Color(0xFFCD7F32);

  /// Dark ink used for text and icons sitting on top of [gold] surfaces.
  /// Stays dark in both themes for contrast on gold.
  static const onAccent = Color(0xFF0A0E1A);

  /// Deep background used by brand "hero" screens (splash, auth) which stay
  /// dark regardless of the active theme.
  static const heroBackground = Color(0xFF0A0E1A);
  static const heroGradientEnd = Color(0xFF1A1F3A);
}
