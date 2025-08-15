import 'package:flutter/foundation.dart';

/// Environment configuration manager that loads settings from environment variables
/// This ensures sensitive data is not hardcoded in the application
class EnvironmentConfig {
  // Private constructor
  EnvironmentConfig._();

  static final EnvironmentConfig _instance = EnvironmentConfig._();
  static EnvironmentConfig get instance => _instance;

  // Environment type
  static const String _environment = String.fromEnvironment(
    'FLUTTER_ENV',
    defaultValue: 'development',
  );

  static bool get isDevelopment => _environment == 'development';
  static bool get isProduction => _environment == 'production';
  static bool get isStaging => _environment == 'staging';

  // API Configuration
  static const String _prodApiBaseUrl = String.fromEnvironment(
    'PROD_API_BASE_URL',
    defaultValue:
        'https://guruai-backend-282796537878.us-central1.run.app/api/v1', // Updated base URL
  );

  static const String _devApiBaseUrl = String.fromEnvironment(
    'DEV_API_BASE_URL',
    defaultValue:
        'https://guruai-backend-282796537878.us-central1.run.app/api/v1', // Updated dev URL
  );

  // Mock service fallback configuration
  static const bool _useMockService = bool.fromEnvironment(
    'USE_MOCK_SERVICE',
    defaultValue: false, // Disable mock service by default to test real API
  );

  static const String _prodWebSocketUrl = String.fromEnvironment(
    'PROD_WEBSOCKET_URL',
    defaultValue: 'wss://api.sahayak.app',
  );

  static const String _devWebSocketUrl = String.fromEnvironment(
    'DEV_WEBSOCKET_URL',
    defaultValue: 'ws://127.0.0.1:5000',
  );

  // API Keys (these should be injected at build time)
  static const String _apiKey = String.fromEnvironment(
    'API_KEY',
    defaultValue: '',
  );

  static const String _jwtSecret = String.fromEnvironment(
    'JWT_SECRET',
    defaultValue: '',
  );

  static const String _encryptionKey = String.fromEnvironment(
    'ENCRYPTION_KEY',
    defaultValue: '',
  );

  // Third-party service keys
  static const String _googleCloudApiKey = String.fromEnvironment(
    'GOOGLE_CLOUD_API_KEY',
    defaultValue: '',
  );

  static const String _firebaseApiKey = String.fromEnvironment(
    'FIREBASE_API_KEY',
    defaultValue: '',
  );

  // Timeout configuration
  static const int _apiTimeoutMs = int.fromEnvironment(
    'API_TIMEOUT_MS',
    defaultValue: 30000,
  );

  // Feature flags
  static const bool _enableLogging = bool.fromEnvironment(
    'ENABLE_LOGGING',
    defaultValue: kDebugMode,
  );

  static const bool _enableDebugMode = bool.fromEnvironment(
    'ENABLE_DEBUG_MODE',
    defaultValue: kDebugMode,
  );

  static const bool _enableAnalytics = bool.fromEnvironment(
    'ENABLE_ANALYTICS',
    defaultValue: !kDebugMode,
  );

  static const bool _enableCrashReporting = bool.fromEnvironment(
    'ENABLE_CRASH_REPORTING',
    defaultValue: !kDebugMode,
  );

  static const bool _enablePerformanceMonitoring = bool.fromEnvironment(
    'ENABLE_PERFORMANCE_MONITORING',
    defaultValue: true,
  );

  // Public getters
  String get environment => _environment;

  String get apiBaseUrl => isProduction ? _prodApiBaseUrl : _devApiBaseUrl;
  String get webSocketUrl =>
      isProduction ? _prodWebSocketUrl : _devWebSocketUrl;

  String get apiKey => _apiKey;
  String get jwtSecret => _jwtSecret;
  String get encryptionKey => _encryptionKey;
  String get googleCloudApiKey => _googleCloudApiKey;
  String get firebaseApiKey => _firebaseApiKey;

  int get apiTimeoutMs => _apiTimeoutMs;
  Duration get apiTimeout => Duration(milliseconds: _apiTimeoutMs);

  bool get enableLogging => _enableLogging;
  bool get enableDebugMode => _enableDebugMode;
  bool get enableAnalytics => _enableAnalytics;
  bool get enableCrashReporting => _enableCrashReporting;
  bool get enablePerformanceMonitoring => _enablePerformanceMonitoring;
  bool get useMockService => isDevelopment && _useMockService;

  // Validation methods
  bool get hasValidApiKey => _apiKey.isNotEmpty;
  bool get hasValidEncryptionKey => _encryptionKey.isNotEmpty;
  bool get hasValidGoogleCloudKey => _googleCloudApiKey.isNotEmpty;
  bool get hasValidFirebaseKey => _firebaseApiKey.isNotEmpty;

  /// Validate all required environment variables are set
  List<String> validateConfiguration() {
    final List<String> errors = [];

    if (isProduction) {
      if (!hasValidApiKey) {
        errors.add('Production API_KEY is required but not set');
      }
      if (!hasValidEncryptionKey) {
        errors.add('Production ENCRYPTION_KEY is required but not set');
      }
      if (_prodApiBaseUrl.contains('sahayak.app') &&
          _prodApiBaseUrl == 'https://api.sahayak.app/api/v1') {
        errors.add(
            'Production API base URL is using default fallback - please set PROD_API_BASE_URL');
      }
    }

    return errors;
  }

  /// Log configuration (without sensitive data)
  void logConfiguration() {
    if (!enableLogging) return;

    debugPrint('🔧 Environment Configuration:');
    debugPrint('   Environment: $environment');
    debugPrint('   API Base URL: $apiBaseUrl');
    debugPrint('   Use Mock Service: $useMockService');
    debugPrint('   WebSocket URL: $webSocketUrl');
    debugPrint('   API Timeout: ${apiTimeoutMs}ms');
    debugPrint('   Debug Mode: $enableDebugMode');
    debugPrint('   Analytics: $enableAnalytics');
    debugPrint('   Crash Reporting: $enableCrashReporting');
    debugPrint('   Performance Monitoring: $enablePerformanceMonitoring');
    debugPrint('   Has API Key: ${hasValidApiKey ? "✅" : "❌"}');
    debugPrint('   Has Encryption Key: ${hasValidEncryptionKey ? "✅" : "❌"}');

    final errors = validateConfiguration();
    if (errors.isNotEmpty) {
      debugPrint('⚠️ Configuration Errors:');
      for (final error in errors) {
        debugPrint('   - $error');
      }
    }
  }
}
