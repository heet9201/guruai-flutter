import 'package:flutter/material.dart';

/// Color palette inspired by rural teaching environments and earth tones
class SahayakColors {
  // Enhanced Brand Colors - Warm Earth Tones for Educational Environment
  static const Color ochre =
      Color(0xFFDBA44C); // Primary ochre - warm and inviting
  static const Color burntSienna =
      Color(0xFFA0522D); // Secondary burnt sienna - earthy warmth
  static const Color deepTeal =
      Color(0xFF1E6262); // Accent teal - calming focus

  // Additional earth tone palette for richer visual hierarchy
  static const Color warmIvory = Color(0xFFF5F2EA); // Softer than white
  static const Color clayOrange = Color(0xFFE67E22); // Vibrant accent
  static const Color forestGreen =
      Color(0xFF27AE60); // Success/positive actions
  static const Color chalkWhite = Color(0xFFE8E2DB); // Blackboard chalk color
  static const Color charcoal = Color(0xFF2C3E50); // Deep readable text

  // Light Theme Colors - "Classroom Mode"
  static const Color lightBackground = Color(0xFFFBF8F3); // Warm cream
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightSurfaceVariant = warmIvory;
  static const Color lightPrimary = ochre;
  static const Color lightSecondary = burntSienna;
  static const Color lightTertiary = deepTeal;
  static const Color lightOnPrimary = Color(0xFFFFFFFF);
  static const Color lightOnSecondary = Color(0xFFFFFFFF);
  static const Color lightOnBackground = charcoal;
  static const Color lightOnSurface = charcoal;
  static const Color lightError = Color(0xFFE74C3C);
  static const Color lightOnError = Color(0xFFFFFFFF);
  static const Color lightOutline = Color(0xFFBDC3C7);

  // Success and warning colors for feedback
  static const Color lightSuccess = forestGreen;
  static const Color lightWarning = clayOrange;

  // Dark Theme Colors - "Blackboard Mode"
  static const Color darkBackground =
      Color(0xFF1A1F1A); // Deep forest green - like a chalkboard
  static const Color darkSurface = Color(0xFF242B24);
  static const Color darkPrimary =
      Color(0xFFE6A852); // Lighter ochre for dark mode
  static const Color darkSecondary = Color(0xFFD4A574); // Lighter burnt sienna
  static const Color darkTertiary =
      Color(0xFF4DD5D5); // Lighter teal - like chalk
  static const Color darkOnPrimary = Color(0xFF2C1810);
  static const Color darkOnSecondary = Color(0xFF2C1810);
  static const Color darkOnBackground = chalkWhite;
  static const Color darkOnSurface = chalkWhite;
  static const Color darkError = Color(0xFFFFB4AB);
  static const Color darkOnError = Color(0xFF690005);

  // Dark mode success and warning
  static const Color darkSuccess = Color(0xFF58D68D);
  static const Color darkWarning = Color(0xFFF39C12);

  // Touch target and interactive element colors
  static const Color primaryHover = Color(0xFFCF9641); // Darker ochre
  static const Color primaryPressed = Color(0xFFB8852F); // Even darker ochre
  static const Color focusRing = Color(0xFF3498DB); // Clear focus indicator

  // Surface variants for depth
  static const Color surfaceVariantLight = Color(0xFFF3EFE8);
  static const Color surfaceVariantDark = Color(0xFF3A3E3A);

  // Outline colors for borders
  static const Color outlineLight = Color(0xFF857970);
  static const Color outlineDark = Color(0xFFA19189);

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
    outline: SahayakColors.outlineLight,
    outlineVariant: SahayakColors.outlineLight.withOpacity(0.5),
    surfaceContainerHighest: SahayakColors.surfaceVariantLight,
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
    outline: SahayakColors.outlineDark,
    outlineVariant: SahayakColors.outlineDark.withOpacity(0.5),
    surfaceContainerHighest: SahayakColors.surfaceVariantDark,
  );
}
