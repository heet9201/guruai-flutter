import 'package:flutter/material.dart';

/// Supported languages in Sahayak app
class SahayakLocales {
  static const Locale english = Locale('en', '');
  static const Locale hindi = Locale('hi', 'IN');
  static const Locale marathi = Locale('mr', 'IN');
  static const Locale tamil = Locale('ta', 'IN');
  static const Locale telugu = Locale('te', 'IN');
  static const Locale kannada = Locale('kn', 'IN');
  static const Locale malayalam = Locale('ml', 'IN');
  static const Locale gujarati = Locale('gu', 'IN');
  static const Locale bengali = Locale('bn', 'IN');
  static const Locale punjabi = Locale('pa', 'IN');
  static const Locale odia = Locale('or', 'IN');
  static const Locale assamese = Locale('as', 'IN');

  /// List of all supported locales
  static const List<Locale> supportedLocales = [
    english,
    hindi,
    marathi,
    tamil,
    telugu,
    kannada,
    malayalam,
    gujarati,
    bengali,
    punjabi,
    odia,
    assamese,
  ];

  /// Map of language codes to display names in English
  static const Map<String, String> languageNames = {
    'en': 'English',
    'hi': 'हिंदी (Hindi)',
    'mr': 'मराठी (Marathi)',
    'ta': 'தமிழ் (Tamil)',
    'te': 'తెలుగు (Telugu)',
    'kn': 'ಕನ್ನಡ (Kannada)',
    'ml': 'മലയാളം (Malayalam)',
    'gu': 'ગુજરાતી (Gujarati)',
    'bn': 'বাংলা (Bengali)',
    'pa': 'ਪੰਜਾਬੀ (Punjabi)',
    'or': 'ଓଡ଼ିଆ (Odia)',
    'as': 'অসমীয়া (Assamese)',
  };

  /// Map of language codes to native script names
  static const Map<String, String> nativeLanguageNames = {
    'en': 'English',
    'hi': 'हिंदी',
    'mr': 'मराठी',
    'ta': 'தமிழ்',
    'te': 'తెలుగు',
    'kn': 'ಕನ್ನಡ',
    'ml': 'മലയാളം',
    'gu': 'ગુજરાતી',
    'bn': 'বাংলা',
    'pa': 'ਪੰਜਾਬੀ',
    'or': 'ଓଡ଼ିଆ',
    'as': 'অসমীয়া',
  };

  /// Returns the display name for a language code
  static String getLanguageName(String languageCode) {
    return languageNames[languageCode] ?? 'Unknown';
  }

  /// Returns the native script name for a language code
  static String getNativeLanguageName(String languageCode) {
    return nativeLanguageNames[languageCode] ?? 'Unknown';
  }

  /// Checks if a language code is supported
  static bool isSupported(String languageCode) {
    return languageNames.containsKey(languageCode);
  }

  /// Returns locale for a language code
  static Locale getLocale(String languageCode) {
    switch (languageCode) {
      case 'en':
        return english;
      case 'hi':
        return hindi;
      case 'mr':
        return marathi;
      case 'ta':
        return tamil;
      case 'te':
        return telugu;
      case 'kn':
        return kannada;
      case 'ml':
        return malayalam;
      case 'gu':
        return gujarati;
      case 'bn':
        return bengali;
      case 'pa':
        return punjabi;
      case 'or':
        return odia;
      case 'as':
        return assamese;
      default:
        return english;
    }
  }
}
