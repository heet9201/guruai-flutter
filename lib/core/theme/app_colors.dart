import 'package:flutter/material.dart';

/// Color palette inspired by rural teaching environments and earth tones
class SahayakColors {
  // Primary Colors - Warm Earth Tones
  static const Color ochre = Color(0xFFCC8400);
  static const Color burntSienna = Color(0xFFA0522D);

  // Accent Color
  static const Color deepTeal = Color(0xFF008B8B);

  // Light Theme Colors
  static const Color lightBackground =
      Color(0xFFFBF9F6); // Warm white like paper
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightOnPrimary = Color(0xFFFFFFFF);
  static const Color lightOnSecondary = Color(0xFFFFFFFF);
  static const Color lightOnBackground =
      Color(0xFF2C1810); // Dark brown for text
  static const Color lightOnSurface = Color(0xFF2C1810);
  static const Color lightError = Color(0xFFBA1A1A);
  static const Color lightOnError = Color(0xFFFFFFFF);

  // Dark Theme Colors - "Blackboard Mode"
  static const Color darkBackground = Color(0xFF1A1F1A); // Deep forest green
  static const Color darkSurface = Color(0xFF242B24);
  static const Color darkPrimary =
      Color(0xFFE6A852); // Lighter ochre for dark mode
  static const Color darkSecondary = Color(0xFFD4A574); // Lighter burnt sienna
  static const Color darkTertiary = Color(0xFF4DD5D5); // Lighter teal
  static const Color darkOnPrimary = Color(0xFF2C1810);
  static const Color darkOnSecondary = Color(0xFF2C1810);
  static const Color darkOnBackground = Color(0xFFE8E2DB); // Chalk white
  static const Color darkOnSurface = Color(0xFFE8E2DB);
  static const Color darkError = Color(0xFFFFB4AB);
  static const Color darkOnError = Color(0xFF690005);

  // Surface variants for depth
  static const Color lightSurfaceVariant = Color(0xFFF3EFE8);
  static const Color darkSurfaceVariant = Color(0xFF3A3E3A);

  // Outline colors for borders
  static const Color lightOutline = Color(0xFF857970);
  static const Color darkOutline = Color(0xFFA19189);

  // Success colors for educational feedback
  static const Color successLight = Color(0xFF2E7D32);
  static const Color successDark = Color(0xFF66BB6A);

  // Warning colors
  static const Color warningLight = Color(0xFFED6C02);
  static const Color warningDark = Color(0xFFFFB74D);

  // Info colors
  static const Color infoLight = Color(0xFF0288D1);
  static const Color infoDark = Color(0xFF64B5F6);
}

/// Creates color schemes for light and dark themes
class SahayakColorScheme {
  static ColorScheme light = ColorScheme(
    brightness: Brightness.light,
    primary: SahayakColors.ochre,
    onPrimary: SahayakColors.lightOnPrimary,
    secondary: SahayakColors.burntSienna,
    onSecondary: SahayakColors.lightOnSecondary,
    tertiary: SahayakColors.deepTeal,
    onTertiary: SahayakColors.lightOnPrimary,
    error: SahayakColors.lightError,
    onError: SahayakColors.lightOnError,
    surface: SahayakColors.lightSurface,
    onSurface: SahayakColors.lightOnSurface,
    onSurfaceVariant: SahayakColors.lightOnSurface,
    outline: SahayakColors.lightOutline,
    outlineVariant: SahayakColors.lightOutline.withOpacity(0.5),
    surfaceContainerHighest: SahayakColors.lightSurfaceVariant,
  );

  static ColorScheme dark = ColorScheme(
    brightness: Brightness.dark,
    primary: SahayakColors.darkPrimary,
    onPrimary: SahayakColors.darkOnPrimary,
    secondary: SahayakColors.darkSecondary,
    onSecondary: SahayakColors.darkOnSecondary,
    tertiary: SahayakColors.darkTertiary,
    onTertiary: SahayakColors.darkOnPrimary,
    error: SahayakColors.darkError,
    onError: SahayakColors.darkOnError,
    surface: SahayakColors.darkSurface,
    onSurface: SahayakColors.darkOnSurface,
    onSurfaceVariant: SahayakColors.darkOnSurface,
    outline: SahayakColors.darkOutline,
    outlineVariant: SahayakColors.darkOutline.withOpacity(0.5),
    surfaceContainerHighest: SahayakColors.darkSurfaceVariant,
  );
}
