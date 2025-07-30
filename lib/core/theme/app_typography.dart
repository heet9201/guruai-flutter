import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Typography system optimized for Indian languages and educational content
class SahayakTypography {
  // Base font sizes (minimum 16px for body text as required)
  static const double displayLarge = 57.0;
  static const double displayMedium = 45.0;
  static const double displaySmall = 36.0;
  static const double headlineLarge = 32.0;
  static const double headlineMedium = 28.0;
  static const double headlineSmall = 24.0;
  static const double titleLarge = 22.0;
  static const double titleMedium = 20.0;
  static const double titleSmall = 18.0;
  static const double bodyLarge = 18.0;
  static const double bodyMedium = 16.0; // Minimum 16px as required
  static const double bodySmall = 16.0; // Kept at 16px for readability
  static const double labelLarge = 16.0;
  static const double labelMedium = 14.0;
  static const double labelSmall = 12.0;

  /// Creates text theme for light mode
  static TextTheme lightTextTheme(String languageCode) {
    return _createTextTheme(
      languageCode: languageCode,
      primaryColor: const Color(0xFF2C1810), // Dark brown
      onSurfaceColor: const Color(0xFF2C1810),
    );
  }

  /// Creates text theme for dark mode
  static TextTheme darkTextTheme(String languageCode) {
    return _createTextTheme(
      languageCode: languageCode,
      primaryColor: const Color(0xFFE8E2DB), // Chalk white
      onSurfaceColor: const Color(0xFFE8E2DB),
    );
  }

  /// Internal method to create text theme based on language
  static TextTheme _createTextTheme({
    required String languageCode,
    required Color primaryColor,
    required Color onSurfaceColor,
  }) {
    // Choose font family based on language
    TextStyle Function({
      Color? color,
      double? fontSize,
      FontWeight? fontWeight,
      double? letterSpacing,
      double? height,
    }) headingFont;

    TextStyle Function({
      Color? color,
      double? fontSize,
      FontWeight? fontWeight,
      double? letterSpacing,
      double? height,
    }) bodyFont;

    switch (languageCode) {
      case 'hi': // Hindi
        headingFont = GoogleFonts.notoSansDevanagari;
        bodyFont = GoogleFonts.notoSansDevanagari;
        break;
      case 'mr': // Marathi
        headingFont = GoogleFonts.notoSansDevanagari;
        bodyFont = GoogleFonts.notoSansDevanagari;
        break;
      case 'ta': // Tamil
        headingFont = GoogleFonts.notoSansTamil;
        bodyFont = GoogleFonts.notoSansTamil;
        break;
      case 'te': // Telugu
        headingFont = GoogleFonts.notoSansTelugu;
        bodyFont = GoogleFonts.notoSansTelugu;
        break;
      case 'kn': // Kannada
        headingFont = GoogleFonts.notoSansKannada;
        bodyFont = GoogleFonts.notoSansKannada;
        break;
      case 'ml': // Malayalam
        headingFont = GoogleFonts.notoSansMalayalam;
        bodyFont = GoogleFonts.notoSansMalayalam;
        break;
      case 'gu': // Gujarati
        headingFont = GoogleFonts.notoSansGujarati;
        bodyFont = GoogleFonts.notoSansGujarati;
        break;
      case 'bn': // Bengali
        headingFont = GoogleFonts.notoSansBengali;
        bodyFont = GoogleFonts.notoSansBengali;
        break;
      case 'pa': // Punjabi
        headingFont = GoogleFonts.notoSansGurmukhi;
        bodyFont = GoogleFonts.notoSansGurmukhi;
        break;
      default: // English and other languages
        headingFont = GoogleFonts.poppins;
        bodyFont = GoogleFonts.inter;
        break;
    }

    return TextTheme(
      // Display styles for large headings
      displayLarge: headingFont(
        fontSize: displayLarge,
        fontWeight: FontWeight.w700,
        color: primaryColor,
        height: 1.12,
        letterSpacing: -0.25,
      ),
      displayMedium: headingFont(
        fontSize: displayMedium,
        fontWeight: FontWeight.w700,
        color: primaryColor,
        height: 1.16,
        letterSpacing: 0,
      ),
      displaySmall: headingFont(
        fontSize: displaySmall,
        fontWeight: FontWeight.w600,
        color: primaryColor,
        height: 1.22,
        letterSpacing: 0,
      ),

      // Headline styles for section headers
      headlineLarge: headingFont(
        fontSize: headlineLarge,
        fontWeight: FontWeight.w600,
        color: primaryColor,
        height: 1.25,
        letterSpacing: 0,
      ),
      headlineMedium: headingFont(
        fontSize: headlineMedium,
        fontWeight: FontWeight.w600,
        color: primaryColor,
        height: 1.29,
        letterSpacing: 0,
      ),
      headlineSmall: headingFont(
        fontSize: headlineSmall,
        fontWeight: FontWeight.w600,
        color: primaryColor,
        height: 1.33,
        letterSpacing: 0,
      ),

      // Title styles for subsections
      titleLarge: headingFont(
        fontSize: titleLarge,
        fontWeight: FontWeight.w600,
        color: primaryColor,
        height: 1.27,
        letterSpacing: 0,
      ),
      titleMedium: headingFont(
        fontSize: titleMedium,
        fontWeight: FontWeight.w500,
        color: primaryColor,
        height: 1.50,
        letterSpacing: 0.15,
      ),
      titleSmall: headingFont(
        fontSize: titleSmall,
        fontWeight: FontWeight.w500,
        color: primaryColor,
        height: 1.44,
        letterSpacing: 0.1,
      ),

      // Body styles for main content
      bodyLarge: bodyFont(
        fontSize: bodyLarge,
        fontWeight: FontWeight.w400,
        color: onSurfaceColor,
        height: 1.50,
        letterSpacing: 0.5,
      ),
      bodyMedium: bodyFont(
        fontSize: bodyMedium,
        fontWeight: FontWeight.w400,
        color: onSurfaceColor,
        height: 1.50,
        letterSpacing: 0.25,
      ),
      bodySmall: bodyFont(
        fontSize: bodySmall,
        fontWeight: FontWeight.w400,
        color: onSurfaceColor,
        height: 1.43,
        letterSpacing: 0.4,
      ),

      // Label styles for buttons and small text
      labelLarge: bodyFont(
        fontSize: labelLarge,
        fontWeight: FontWeight.w500,
        color: onSurfaceColor,
        height: 1.43,
        letterSpacing: 0.1,
      ),
      labelMedium: bodyFont(
        fontSize: labelMedium,
        fontWeight: FontWeight.w500,
        color: onSurfaceColor,
        height: 1.33,
        letterSpacing: 0.5,
      ),
      labelSmall: bodyFont(
        fontSize: labelSmall,
        fontWeight: FontWeight.w500,
        color: onSurfaceColor,
        height: 1.45,
        letterSpacing: 0.5,
      ),
    );
  }

  /// High contrast text theme for better accessibility
  static TextTheme highContrastTextTheme(String languageCode, bool isDark) {
    final baseTheme =
        isDark ? darkTextTheme(languageCode) : lightTextTheme(languageCode);

    final contrastColor = isDark ? Colors.white : Colors.black;

    return baseTheme.copyWith(
      displayLarge: baseTheme.displayLarge?.copyWith(color: contrastColor),
      displayMedium: baseTheme.displayMedium?.copyWith(color: contrastColor),
      displaySmall: baseTheme.displaySmall?.copyWith(color: contrastColor),
      headlineLarge: baseTheme.headlineLarge?.copyWith(color: contrastColor),
      headlineMedium: baseTheme.headlineMedium?.copyWith(color: contrastColor),
      headlineSmall: baseTheme.headlineSmall?.copyWith(color: contrastColor),
      titleLarge: baseTheme.titleLarge?.copyWith(color: contrastColor),
      titleMedium: baseTheme.titleMedium?.copyWith(color: contrastColor),
      titleSmall: baseTheme.titleSmall?.copyWith(color: contrastColor),
      bodyLarge: baseTheme.bodyLarge?.copyWith(color: contrastColor),
      bodyMedium: baseTheme.bodyMedium?.copyWith(color: contrastColor),
      bodySmall: baseTheme.bodySmall?.copyWith(color: contrastColor),
      labelLarge: baseTheme.labelLarge?.copyWith(color: contrastColor),
      labelMedium: baseTheme.labelMedium?.copyWith(color: contrastColor),
      labelSmall: baseTheme.labelSmall?.copyWith(color: contrastColor),
    );
  }
}
