import 'package:flutter/material.dart';
import '../accessibility/accessibility_manager.dart';

/// Accessibility-enhanced themes with high contrast and large text support
class AccessibleThemeData {
  /// Create accessible light theme
  static ThemeData createLightTheme({
    bool isHighContrast = false,
    double textScaleFactor = 1.0,
    String languageCode = 'en',
  }) {
    final ColorScheme colorScheme = isHighContrast
        ? _highContrastLightColorScheme
        : _standardLightColorScheme;

    return _createBaseTheme(
      colorScheme: colorScheme,
      brightness: Brightness.light,
      textScaleFactor: textScaleFactor,
      languageCode: languageCode,
      isHighContrast: isHighContrast,
    );
  }

  /// Create accessible dark theme
  static ThemeData createDarkTheme({
    bool isHighContrast = false,
    double textScaleFactor = 1.0,
    String languageCode = 'en',
  }) {
    final ColorScheme colorScheme = isHighContrast
        ? _highContrastDarkColorScheme
        : _standardDarkColorScheme;

    return _createBaseTheme(
      colorScheme: colorScheme,
      brightness: Brightness.dark,
      textScaleFactor: textScaleFactor,
      languageCode: languageCode,
      isHighContrast: isHighContrast,
    );
  }

  /// Create base theme with accessibility features
  static ThemeData _createBaseTheme({
    required ColorScheme colorScheme,
    required Brightness brightness,
    required double textScaleFactor,
    required String languageCode,
    required bool isHighContrast,
  }) {
    // Adjust text scale factor for accessibility
    final adjustedTextScale = (textScaleFactor * 1.0).clamp(0.8, 2.0);

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      brightness: brightness,

      // Typography with accessibility considerations
      textTheme: _createAccessibleTextTheme(
        colorScheme: colorScheme,
        textScaleFactor: adjustedTextScale,
        isHighContrast: isHighContrast,
      ),

      // App bar theme
      appBarTheme: AppBarTheme(
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        elevation: isHighContrast ? 4 : 1,
        titleTextStyle: TextStyle(
          fontSize: 20 * adjustedTextScale,
          fontWeight: FontWeight.w600,
          color: colorScheme.onSurface,
        ),
        iconTheme: IconThemeData(
          color: colorScheme.onSurface,
          size: 24 * adjustedTextScale,
        ),
        actionsIconTheme: IconThemeData(
          color: colorScheme.onSurface,
          size: 24 * adjustedTextScale,
        ),
      ),

      // Elevated button theme
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          minimumSize: Size(
            AccessibilityConstants.minTouchTarget,
            AccessibilityConstants.minTouchTarget,
          ),
          padding: EdgeInsets.symmetric(
            horizontal: 16 * adjustedTextScale,
            vertical: 12 * adjustedTextScale,
          ),
          textStyle: TextStyle(
            fontSize: 16 * adjustedTextScale,
            fontWeight: FontWeight.w600,
          ),
          elevation: isHighContrast ? 8 : 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: isHighContrast
                ? BorderSide(
                    color: colorScheme.outline,
                    width: 2,
                  )
                : BorderSide.none,
          ),
        ),
      ),

      // Text button theme
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: colorScheme.primary,
          minimumSize: Size(
            AccessibilityConstants.minTouchTarget,
            AccessibilityConstants.minTouchTarget,
          ),
          padding: EdgeInsets.symmetric(
            horizontal: 16 * adjustedTextScale,
            vertical: 12 * adjustedTextScale,
          ),
          textStyle: TextStyle(
            fontSize: 16 * adjustedTextScale,
            fontWeight: FontWeight.w600,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: isHighContrast
                ? BorderSide(
                    color: colorScheme.primary,
                    width: 2,
                  )
                : BorderSide.none,
          ),
        ),
      ),

      // Outlined button theme
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: colorScheme.primary,
          minimumSize: Size(
            AccessibilityConstants.minTouchTarget,
            AccessibilityConstants.minTouchTarget,
          ),
          padding: EdgeInsets.symmetric(
            horizontal: 16 * adjustedTextScale,
            vertical: 12 * adjustedTextScale,
          ),
          textStyle: TextStyle(
            fontSize: 16 * adjustedTextScale,
            fontWeight: FontWeight.w600,
          ),
          side: BorderSide(
            color: colorScheme.outline,
            width: isHighContrast ? 2 : 1,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),

      // Icon button theme
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          minimumSize: Size(
            AccessibilityConstants.minTouchTarget,
            AccessibilityConstants.minTouchTarget,
          ),
          iconSize: 24 * adjustedTextScale,
          foregroundColor: colorScheme.onSurface,
        ),
      ),

      // Input decoration theme
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
            color: colorScheme.outline,
            width: isHighContrast ? 2 : 1,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
            color: colorScheme.primary,
            width: isHighContrast ? 3 : 2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
            color: colorScheme.error,
            width: isHighContrast ? 3 : 2,
          ),
        ),
        contentPadding: EdgeInsets.symmetric(
          horizontal: 16 * adjustedTextScale,
          vertical: 12 * adjustedTextScale,
        ),
        labelStyle: TextStyle(
          fontSize: 16 * adjustedTextScale,
          color: colorScheme.onSurfaceVariant,
        ),
        hintStyle: TextStyle(
          fontSize: 16 * adjustedTextScale,
          color: colorScheme.onSurfaceVariant.withOpacity(0.6),
        ),
      ),

      // Card theme
      cardTheme: CardTheme(
        elevation: isHighContrast ? 8 : 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: isHighContrast
              ? BorderSide(
                  color: colorScheme.outline,
                  width: 1,
                )
              : BorderSide.none,
        ),
        margin: EdgeInsets.all(8 * adjustedTextScale),
      ),

      // Navigation bar theme
      navigationBarTheme: NavigationBarThemeData(
        height: 80 * adjustedTextScale,
        elevation: isHighContrast ? 8 : 4,
        labelTextStyle: WidgetStateProperty.all(
          TextStyle(
            fontSize: 12 * adjustedTextScale,
            fontWeight: FontWeight.w600,
          ),
        ),
        iconTheme: WidgetStateProperty.all(
          IconThemeData(
            size: 24 * adjustedTextScale,
          ),
        ),
      ),

      // Dialog theme
      dialogTheme: DialogTheme(
        elevation: isHighContrast ? 16 : 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: isHighContrast
              ? BorderSide(
                  color: colorScheme.outline,
                  width: 2,
                )
              : BorderSide.none,
        ),
        titleTextStyle: TextStyle(
          fontSize: 20 * adjustedTextScale,
          fontWeight: FontWeight.w600,
          color: colorScheme.onSurface,
        ),
        contentTextStyle: TextStyle(
          fontSize: 16 * adjustedTextScale,
          color: colorScheme.onSurface,
        ),
      ),

      // Snack bar theme
      snackBarTheme: SnackBarThemeData(
        backgroundColor: colorScheme.inverseSurface,
        contentTextStyle: TextStyle(
          fontSize: 16 * adjustedTextScale,
          color: colorScheme.onInverseSurface,
        ),
        actionTextColor: colorScheme.inversePrimary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        elevation: isHighContrast ? 8 : 4,
      ),

      // List tile theme
      listTileTheme: ListTileThemeData(
        minVerticalPadding: 12 * adjustedTextScale,
        contentPadding: EdgeInsets.symmetric(
          horizontal: 16 * adjustedTextScale,
          vertical: 8 * adjustedTextScale,
        ),
        titleTextStyle: TextStyle(
          fontSize: 16 * adjustedTextScale,
          fontWeight: FontWeight.w500,
          color: colorScheme.onSurface,
        ),
        subtitleTextStyle: TextStyle(
          fontSize: 14 * adjustedTextScale,
          color: colorScheme.onSurfaceVariant,
        ),
      ),

      // Checkbox theme
      checkboxTheme: CheckboxThemeData(
        materialTapTargetSize: MaterialTapTargetSize.padded,
        visualDensity: VisualDensity.comfortable,
        side: BorderSide(
          color: colorScheme.outline,
          width: isHighContrast ? 2 : 1,
        ),
      ),

      // Radio theme
      radioTheme: RadioThemeData(
        materialTapTargetSize: MaterialTapTargetSize.padded,
        visualDensity: VisualDensity.comfortable,
      ),

      // Switch theme
      switchTheme: SwitchThemeData(
        materialTapTargetSize: MaterialTapTargetSize.padded,
      ),

      // Slider theme
      sliderTheme: SliderThemeData(
        thumbShape: RoundSliderThumbShape(
          enabledThumbRadius: 12 * adjustedTextScale,
        ),
        trackHeight: 6 * adjustedTextScale,
        overlayShape: RoundSliderOverlayShape(
          overlayRadius: 20 * adjustedTextScale,
        ),
      ),

      // Tab bar theme
      tabBarTheme: TabBarTheme(
        labelStyle: TextStyle(
          fontSize: 14 * adjustedTextScale,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: TextStyle(
          fontSize: 14 * adjustedTextScale,
          fontWeight: FontWeight.w400,
        ),
        labelPadding: EdgeInsets.symmetric(
          horizontal: 16 * adjustedTextScale,
          vertical: 12 * adjustedTextScale,
        ),
        indicatorSize: TabBarIndicatorSize.tab,
      ),

      // Tooltip theme
      tooltipTheme: TooltipThemeData(
        textStyle: TextStyle(
          fontSize: 14 * adjustedTextScale,
          color: colorScheme.onInverseSurface,
        ),
        decoration: BoxDecoration(
          color: colorScheme.inverseSurface,
          borderRadius: BorderRadius.circular(8),
          border: isHighContrast
              ? Border.all(
                  color: colorScheme.outline,
                  width: 1,
                )
              : null,
        ),
        padding: EdgeInsets.symmetric(
          horizontal: 12 * adjustedTextScale,
          vertical: 8 * adjustedTextScale,
        ),
        margin: EdgeInsets.all(4 * adjustedTextScale),
      ),

      // Focus theme
      focusColor: colorScheme.primary.withOpacity(0.12),
      hoverColor: colorScheme.primary.withOpacity(0.08),

      // Divider theme
      dividerTheme: DividerThemeData(
        color: colorScheme.outline.withOpacity(isHighContrast ? 1.0 : 0.12),
        thickness: isHighContrast ? 2 : 1,
        space: 16 * adjustedTextScale,
      ),
    );
  }

  /// Create accessible text theme
  static TextTheme _createAccessibleTextTheme({
    required ColorScheme colorScheme,
    required double textScaleFactor,
    required bool isHighContrast,
  }) {
    final Color textColor = colorScheme.onSurface;
    final FontWeight normalWeight =
        isHighContrast ? FontWeight.w600 : FontWeight.w400;
    final FontWeight boldWeight =
        isHighContrast ? FontWeight.w800 : FontWeight.w600;

    return TextTheme(
      displayLarge: TextStyle(
        fontSize: 32 * textScaleFactor,
        fontWeight: boldWeight,
        color: textColor,
        height: 1.2,
      ),
      displayMedium: TextStyle(
        fontSize: 28 * textScaleFactor,
        fontWeight: boldWeight,
        color: textColor,
        height: 1.2,
      ),
      displaySmall: TextStyle(
        fontSize: 24 * textScaleFactor,
        fontWeight: boldWeight,
        color: textColor,
        height: 1.2,
      ),
      headlineLarge: TextStyle(
        fontSize: 22 * textScaleFactor,
        fontWeight: boldWeight,
        color: textColor,
        height: 1.3,
      ),
      headlineMedium: TextStyle(
        fontSize: 20 * textScaleFactor,
        fontWeight: boldWeight,
        color: textColor,
        height: 1.3,
      ),
      headlineSmall: TextStyle(
        fontSize: 18 * textScaleFactor,
        fontWeight: boldWeight,
        color: textColor,
        height: 1.3,
      ),
      titleLarge: TextStyle(
        fontSize: 18 * textScaleFactor,
        fontWeight: boldWeight,
        color: textColor,
        height: 1.4,
      ),
      titleMedium: TextStyle(
        fontSize: 16 * textScaleFactor,
        fontWeight: boldWeight,
        color: textColor,
        height: 1.4,
      ),
      titleSmall: TextStyle(
        fontSize: 14 * textScaleFactor,
        fontWeight: boldWeight,
        color: textColor,
        height: 1.4,
      ),
      bodyLarge: TextStyle(
        fontSize: 16 * textScaleFactor,
        fontWeight: normalWeight,
        color: textColor,
        height: 1.5,
      ),
      bodyMedium: TextStyle(
        fontSize: 14 * textScaleFactor,
        fontWeight: normalWeight,
        color: textColor,
        height: 1.5,
      ),
      bodySmall: TextStyle(
        fontSize: 12 * textScaleFactor,
        fontWeight: normalWeight,
        color: textColor.withOpacity(0.8),
        height: 1.5,
      ),
      labelLarge: TextStyle(
        fontSize: 14 * textScaleFactor,
        fontWeight: boldWeight,
        color: textColor,
        height: 1.4,
      ),
      labelMedium: TextStyle(
        fontSize: 12 * textScaleFactor,
        fontWeight: boldWeight,
        color: textColor,
        height: 1.4,
      ),
      labelSmall: TextStyle(
        fontSize: 10 * textScaleFactor,
        fontWeight: boldWeight,
        color: textColor.withOpacity(0.8),
        height: 1.4,
      ),
    );
  }

  /// Standard light color scheme
  static const ColorScheme _standardLightColorScheme = ColorScheme.light(
    primary: Color(0xFF2563EB),
    onPrimary: Color(0xFFFFFFFF),
    primaryContainer: Color(0xFFDBEAFE),
    onPrimaryContainer: Color(0xFF1E3A8A),
    secondary: Color(0xFF059669),
    onSecondary: Color(0xFFFFFFFF),
    secondaryContainer: Color(0xFFD1FAE5),
    onSecondaryContainer: Color(0xFF064E3B),
    tertiary: Color(0xFFDC2626),
    onTertiary: Color(0xFFFFFFFF),
    tertiaryContainer: Color(0xFFFEE2E2),
    onTertiaryContainer: Color(0xFF7F1D1D),
    error: Color(0xFFDC2626),
    onError: Color(0xFFFFFFFF),
    errorContainer: Color(0xFFFEE2E2),
    onErrorContainer: Color(0xFF7F1D1D),
    surface: Color(0xFFFAFAFA),
    onSurface: Color(0xFF171717),
    surfaceContainerHighest: Color(0xFFE5E5E5),
    onSurfaceVariant: Color(0xFF525252),
    outline: Color(0xFFD4D4D4),
    outlineVariant: Color(0xFFE5E5E5),
    shadow: Color(0xFF000000),
    scrim: Color(0xFF000000),
    inverseSurface: Color(0xFF262626),
    onInverseSurface: Color(0xFFFAFAFA),
    inversePrimary: Color(0xFF93C5FD),
  );

  /// Standard dark color scheme
  static const ColorScheme _standardDarkColorScheme = ColorScheme.dark(
    primary: Color(0xFF3B82F6),
    onPrimary: Color(0xFF1E3A8A),
    primaryContainer: Color(0xFF1E40AF),
    onPrimaryContainer: Color(0xFFDBEAFE),
    secondary: Color(0xFF10B981),
    onSecondary: Color(0xFF064E3B),
    secondaryContainer: Color(0xFF047857),
    onSecondaryContainer: Color(0xFFD1FAE5),
    tertiary: Color(0xFFEF4444),
    onTertiary: Color(0xFF7F1D1D),
    tertiaryContainer: Color(0xFFDC2626),
    onTertiaryContainer: Color(0xFFFEE2E2),
    error: Color(0xFFEF4444),
    onError: Color(0xFF7F1D1D),
    errorContainer: Color(0xFFDC2626),
    onErrorContainer: Color(0xFFFEE2E2),
    surface: Color(0xFF171717),
    onSurface: Color(0xFFFAFAFA),
    surfaceContainerHighest: Color(0xFF404040),
    onSurfaceVariant: Color(0xFFD4D4D4),
    outline: Color(0xFF525252),
    outlineVariant: Color(0xFF404040),
    shadow: Color(0xFF000000),
    scrim: Color(0xFF000000),
    inverseSurface: Color(0xFFFAFAFA),
    onInverseSurface: Color(0xFF171717),
    inversePrimary: Color(0xFF2563EB),
  );

  /// High contrast light color scheme
  static const ColorScheme _highContrastLightColorScheme = ColorScheme.light(
    primary: Color(0xFF000000),
    onPrimary: Color(0xFFFFFFFF),
    primaryContainer: Color(0xFFE5E5E5),
    onPrimaryContainer: Color(0xFF000000),
    secondary: Color(0xFF000000),
    onSecondary: Color(0xFFFFFFFF),
    secondaryContainer: Color(0xFFE5E5E5),
    onSecondaryContainer: Color(0xFF000000),
    tertiary: Color(0xFF000000),
    onTertiary: Color(0xFFFFFFFF),
    tertiaryContainer: Color(0xFFE5E5E5),
    onTertiaryContainer: Color(0xFF000000),
    error: Color(0xFF000000),
    onError: Color(0xFFFFFFFF),
    errorContainer: Color(0xFFE5E5E5),
    onErrorContainer: Color(0xFF000000),
    surface: Color(0xFFFFFFFF),
    onSurface: Color(0xFF000000),
    surfaceContainerHighest: Color(0xFFE5E5E5),
    onSurfaceVariant: Color(0xFF000000),
    outline: Color(0xFF000000),
    outlineVariant: Color(0xFF000000),
    shadow: Color(0xFF000000),
    scrim: Color(0xFF000000),
    inverseSurface: Color(0xFF000000),
    onInverseSurface: Color(0xFFFFFFFF),
    inversePrimary: Color(0xFFFFFFFF),
  );

  /// High contrast dark color scheme
  static const ColorScheme _highContrastDarkColorScheme = ColorScheme.dark(
    primary: Color(0xFFFFFFFF),
    onPrimary: Color(0xFF000000),
    primaryContainer: Color(0xFF404040),
    onPrimaryContainer: Color(0xFFFFFFFF),
    secondary: Color(0xFFFFFFFF),
    onSecondary: Color(0xFF000000),
    secondaryContainer: Color(0xFF404040),
    onSecondaryContainer: Color(0xFFFFFFFF),
    tertiary: Color(0xFFFFFFFF),
    onTertiary: Color(0xFF000000),
    tertiaryContainer: Color(0xFF404040),
    onTertiaryContainer: Color(0xFFFFFFFF),
    error: Color(0xFFFFFFFF),
    onError: Color(0xFF000000),
    errorContainer: Color(0xFF404040),
    onErrorContainer: Color(0xFFFFFFFF),
    surface: Color(0xFF000000),
    onSurface: Color(0xFFFFFFFF),
    surfaceContainerHighest: Color(0xFF404040),
    onSurfaceVariant: Color(0xFFFFFFFF),
    outline: Color(0xFFFFFFFF),
    outlineVariant: Color(0xFFFFFFFF),
    shadow: Color(0xFF000000),
    scrim: Color(0xFF000000),
    inverseSurface: Color(0xFFFFFFFF),
    onInverseSurface: Color(0xFF000000),
    inversePrimary: Color(0xFF000000),
  );
}
