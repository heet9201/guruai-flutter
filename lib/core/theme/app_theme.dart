import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'app_colors.dart';
import 'app_typography.dart';
import '../accessibility/accessible_themes.dart';

/// Comprehensive theme system for Sahayak educational app with enhanced warm earth tones
class AppTheme {
  /// Creates light theme with optional language code for typography - "Classroom Mode"
  static ThemeData lightTheme({String languageCode = 'en'}) {
    final colorScheme = SahayakColorScheme.light;
    final textTheme = SahayakTypography.lightTextTheme(languageCode);

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: colorScheme,
      textTheme: textTheme,

      // App Bar Theme - Clean and inviting
      appBarTheme: AppBarTheme(
        centerTitle: false, // Left-aligned for better UX
        elevation: 0,
        scrolledUnderElevation: 1,
        backgroundColor: SahayakColors.lightBackground,
        foregroundColor: SahayakColors.charcoal,
        titleTextStyle: textTheme.headlineMedium?.copyWith(
          fontWeight: FontWeight.w600,
        ),
        toolbarTextStyle: textTheme.bodyMedium,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        surfaceTintColor: Colors.transparent,
      ),

      // Card Theme - Soft shadows and warm tones
      cardTheme: CardTheme(
        elevation: 2,
        shadowColor: SahayakColors.charcoal.withOpacity(0.1),
        surfaceTintColor: SahayakColors.warmIvory,
        shape: RoundedRectangleBorder(
          borderRadius:
              BorderRadius.circular(20), // More rounded for friendliness
        ),
        margin: const EdgeInsets.all(8),
      ),

      // Elevated Button Theme - Primary actions with ochre
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: SahayakColors.ochre,
          foregroundColor: Colors.white,
          elevation: 2,
          shadowColor: SahayakColors.ochre.withOpacity(0.3),
          padding: const EdgeInsets.symmetric(
            horizontal: 32, // Larger touch targets
            vertical: 20,
          ),
          minimumSize: const Size(120, 56), // Better accessibility
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
      ),

      // Text Button Theme
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: SahayakColors.deepTeal,
          padding: const EdgeInsets.symmetric(
            horizontal: 24,
            vertical: 16,
          ),
          textStyle: textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // Outlined Button Theme
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: SahayakColors.burntSienna,
          side: BorderSide(
            color: SahayakColors.burntSienna,
            width: 2,
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: 24,
            vertical: 16,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // Input Decoration Theme - Enhanced for educational content
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: SahayakColors.warmIvory,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 20,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: SahayakColors.outlineLight,
            width: 1,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: SahayakColors.outlineLight,
            width: 1,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: SahayakColors.deepTeal,
            width: 2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: SahayakColors.lightError,
            width: 2,
          ),
        ),
        labelStyle: textTheme.bodyLarge?.copyWith(
          color: SahayakColors.charcoal.withOpacity(0.7),
        ),
        hintStyle: textTheme.bodyMedium?.copyWith(
          color: SahayakColors.charcoal.withOpacity(0.5),
        ),
      ),

      // Floating Action Button Theme - Enhanced with gradient
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: SahayakColors.ochre,
        foregroundColor: Colors.white,
        elevation: 6,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),

      // Chip Theme
      chipTheme: ChipThemeData(
        backgroundColor: SahayakColors.warmIvory,
        selectedColor: SahayakColors.ochre,
        secondarySelectedColor: SahayakColors.deepTeal,
        labelStyle: textTheme.labelMedium,
        secondaryLabelStyle: textTheme.labelMedium?.copyWith(
          color: Colors.white,
        ),
        brightness: Brightness.light,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),

      // Dialog Theme
      dialogTheme: DialogTheme(
        backgroundColor: SahayakColors.lightSurface,
        elevation: 12,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        titleTextStyle: textTheme.headlineSmall?.copyWith(
          fontWeight: FontWeight.w600,
        ),
        contentTextStyle: textTheme.bodyMedium,
      ),

      // Bottom Sheet Theme
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: SahayakColors.lightSurface,
        elevation: 12,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(24),
          ),
        ),
      ),

      // Snack Bar Theme
      snackBarTheme: SnackBarThemeData(
        backgroundColor: SahayakColors.charcoal,
        contentTextStyle: textTheme.bodyMedium?.copyWith(
          color: SahayakColors.chalkWhite,
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),

      // Navigation Bar Theme - Enhanced for thumb reach
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: SahayakColors.lightSurface,
        elevation: 8,
        height: 70, // Optimized for thumb reach
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return textTheme.labelMedium?.copyWith(
              color: SahayakColors.ochre,
              fontWeight: FontWeight.w600,
            );
          }
          return textTheme.labelMedium?.copyWith(
            color: SahayakColors.charcoal.withOpacity(0.6),
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return IconThemeData(
              color: SahayakColors.ochre,
              size: 28,
            );
          }
          return IconThemeData(
            color: SahayakColors.charcoal.withOpacity(0.6),
            size: 24,
          );
        }),
      ),

      // List Tile Theme
      listTileTheme: ListTileThemeData(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 8,
        ),
        titleTextStyle: textTheme.bodyLarge?.copyWith(
          fontWeight: FontWeight.w500,
        ),
        subtitleTextStyle: textTheme.bodyMedium?.copyWith(
          color: SahayakColors.charcoal.withOpacity(0.7),
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  /// Creates dark theme (Enhanced Blackboard Mode) with optional language code
  static ThemeData darkTheme({String languageCode = 'en'}) {
    final colorScheme = SahayakColorScheme.dark;
    final textTheme = SahayakTypography.darkTextTheme(languageCode);

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: colorScheme,
      textTheme: textTheme,

      // App Bar Theme - Blackboard aesthetic
      appBarTheme: AppBarTheme(
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 1,
        backgroundColor: SahayakColors.darkBackground,
        foregroundColor: SahayakColors.chalkWhite,
        titleTextStyle: textTheme.headlineMedium?.copyWith(
          fontWeight: FontWeight.w600,
          color: SahayakColors.chalkWhite,
        ),
        toolbarTextStyle: textTheme.bodyMedium,
        systemOverlayStyle: SystemUiOverlayStyle.light,
        surfaceTintColor: Colors.transparent,
      ),

      // Card Theme - Elevated blackboard panels
      cardTheme: CardTheme(
        elevation: 4,
        shadowColor: Colors.black.withOpacity(0.4),
        surfaceTintColor: SahayakColors.darkSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        margin: const EdgeInsets.all(8),
        color: SahayakColors.darkSurface,
      ),

      // Elevated Button Theme - Chalk-inspired
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: SahayakColors.darkPrimary,
          foregroundColor: SahayakColors.darkBackground,
          elevation: 3,
          shadowColor: SahayakColors.darkPrimary.withOpacity(0.4),
          padding: const EdgeInsets.symmetric(
            horizontal: 32,
            vertical: 20,
          ),
          minimumSize: const Size(120, 56),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
      ),

      // Text Button Theme
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: SahayakColors.darkTertiary,
          padding: const EdgeInsets.symmetric(
            horizontal: 24,
            vertical: 16,
          ),
          textStyle: textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // Outlined Button Theme
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: SahayakColors.darkSecondary,
          side: BorderSide(
            color: SahayakColors.darkSecondary,
            width: 2,
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: 24,
            vertical: 16,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // Input Decoration Theme - Chalk on blackboard
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: SahayakColors.darkSurface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 20,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: SahayakColors.outlineDark,
            width: 1,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: SahayakColors.outlineDark,
            width: 1,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: SahayakColors.darkTertiary,
            width: 2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: SahayakColors.darkError,
            width: 2,
          ),
        ),
        labelStyle: textTheme.bodyLarge?.copyWith(
          color: SahayakColors.chalkWhite.withOpacity(0.7),
        ),
        hintStyle: textTheme.bodyMedium?.copyWith(
          color: SahayakColors.chalkWhite.withOpacity(0.5),
        ),
      ),

      // Floating Action Button Theme - Glowing chalk
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: SahayakColors.darkPrimary,
        foregroundColor: SahayakColors.darkBackground,
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),

      // Chip Theme
      chipTheme: ChipThemeData(
        backgroundColor: SahayakColors.darkSurface,
        selectedColor: SahayakColors.darkPrimary,
        secondarySelectedColor: SahayakColors.darkTertiary,
        labelStyle: textTheme.labelMedium?.copyWith(
          color: SahayakColors.chalkWhite,
        ),
        secondaryLabelStyle: textTheme.labelMedium?.copyWith(
          color: SahayakColors.darkBackground,
        ),
        brightness: Brightness.dark,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),

      // Dialog Theme
      dialogTheme: DialogTheme(
        backgroundColor: SahayakColors.darkSurface,
        elevation: 16,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        titleTextStyle: textTheme.headlineSmall?.copyWith(
          fontWeight: FontWeight.w600,
          color: SahayakColors.chalkWhite,
        ),
        contentTextStyle: textTheme.bodyMedium?.copyWith(
          color: SahayakColors.chalkWhite,
        ),
      ),

      // Bottom Sheet Theme
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: SahayakColors.darkSurface,
        elevation: 16,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(24),
          ),
        ),
      ),

      // Snack Bar Theme
      snackBarTheme: SnackBarThemeData(
        backgroundColor: SahayakColors.darkPrimary,
        contentTextStyle: textTheme.bodyMedium?.copyWith(
          color: SahayakColors.darkBackground,
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),

      // Navigation Bar Theme - Blackboard bottom rail
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: SahayakColors.darkSurface,
        elevation: 12,
        height: 70,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return textTheme.labelMedium?.copyWith(
              color: SahayakColors.darkPrimary,
              fontWeight: FontWeight.w600,
            );
          }
          return textTheme.labelMedium?.copyWith(
            color: SahayakColors.chalkWhite.withOpacity(0.6),
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return IconThemeData(
              color: SahayakColors.darkPrimary,
              size: 28,
            );
          }
          return IconThemeData(
            color: SahayakColors.chalkWhite.withOpacity(0.6),
            size: 24,
          );
        }),
      ),

      // List Tile Theme
      listTileTheme: ListTileThemeData(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 8,
        ),
        titleTextStyle: textTheme.bodyLarge?.copyWith(
          fontWeight: FontWeight.w500,
          color: SahayakColors.chalkWhite,
        ),
        subtitleTextStyle: textTheme.bodyMedium?.copyWith(
          color: SahayakColors.chalkWhite.withOpacity(0.7),
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  /// High contrast theme for better accessibility in low-light conditions
  static ThemeData highContrastTheme({
    String languageCode = 'en',
    bool isDark = false,
  }) {
    final baseTheme = isDark
        ? darkTheme(languageCode: languageCode)
        : lightTheme(languageCode: languageCode);

    final highContrastTextTheme = SahayakTypography.highContrastTextTheme(
      languageCode,
      isDark,
    );

    return baseTheme.copyWith(
      textTheme: highContrastTextTheme,
      // Increase contrast ratios for better visibility
      colorScheme: baseTheme.colorScheme.copyWith(
        outline: isDark ? Colors.white : Colors.black,
        onSurface: isDark ? Colors.white : Colors.black,
      ),
    );
  }

  /// Create accessible theme with enhanced contrast and text scaling
  static ThemeData accessibleTheme({
    String languageCode = 'en',
    bool isDark = false,
    bool isHighContrast = false,
    double textScaleFactor = 1.0,
  }) {
    return AccessibleThemeData.createLightTheme(
      isHighContrast: isHighContrast,
      textScaleFactor: textScaleFactor,
      languageCode: languageCode,
    );
  }

  /// Create accessible dark theme
  static ThemeData accessibleDarkTheme({
    String languageCode = 'en',
    bool isHighContrast = false,
    double textScaleFactor = 1.0,
  }) {
    return AccessibleThemeData.createDarkTheme(
      isHighContrast: isHighContrast,
      textScaleFactor: textScaleFactor,
      languageCode: languageCode,
    );
  }
}
