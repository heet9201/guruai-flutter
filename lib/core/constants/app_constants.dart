class AppConstants {
  // API Constants
  static const String baseUrl = 'https://api.example.com';
  static const int connectionTimeout = 30000;
  static const int receiveTimeout = 30000;

  // App Info
  static const String appName = 'Sahayak';
  static const String appVersion = '1.0.0';

  // Storage Keys
  static const String userDataKey = 'user_data';
  static const String tokenKey = 'auth_token';
  static const String languageKey = 'app_language';
  static const String themeKey = 'app_theme';

  // Database
  static const String databaseName = 'sahayak.db';
  static const int databaseVersion = 1;

  // Permissions
  static const List<String> requiredPermissions = [
    'camera',
    'microphone',
    'storage',
    'speech',
  ];
}
