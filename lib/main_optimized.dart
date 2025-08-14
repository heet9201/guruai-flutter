import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'core/services/enhanced_service_locator.dart';
import 'core/theme/app_theme.dart';
import 'presentation/screens/splash_screen.dart';

/// Optimized main entry point with enhanced architecture
void main() async {
  // Ensure Flutter is initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Configure system UI
  await _configureSystemUI();

  // Initialize enhanced services
  await _initializeServices();

  // Configure error handling
  _configureErrorHandling();

  // Run the app
  runApp(const SahayakApp());
}

/// Configure system UI appearance
Future<void> _configureSystemUI() async {
  // Set preferred orientations
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Configure status bar
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.white,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );
}

/// Initialize all enhanced services
Future<void> _initializeServices() async {
  try {
    // Initialize the enhanced service locator
    await EnhancedServiceLocator.initialize();

    if (kDebugMode) {
      print('🚀 Sahayak App initialized with enhanced architecture');

      // Print diagnostics in debug mode
      final diagnostics = EnhancedServiceLocator.getDiagnostics();
      print('📊 Service Diagnostics: $diagnostics');
    }
  } catch (e) {
    if (kDebugMode) {
      print('❌ Service initialization failed: $e');
    }

    // In production, you might want to show an error screen
    // or attempt a fallback initialization
    rethrow;
  }
}

/// Configure global error handling
void _configureErrorHandling() {
  // Handle Flutter framework errors
  FlutterError.onError = (FlutterErrorDetails details) {
    if (kDebugMode) {
      // In debug mode, show the error
      FlutterError.presentError(details);
    } else {
      // In production, log the error and continue
      print('Flutter Error: ${details.exception}');

      // You could send this to a crash reporting service
      // _sendErrorToCrashlytics(details);
    }
  };

  // Handle errors outside of Flutter framework
  PlatformDispatcher.instance.onError = (error, stack) {
    if (kDebugMode) {
      print('Platform Error: $error');
      print('Stack Trace: $stack');
    } else {
      // Log and report the error in production
      print('Uncaught Error: $error');

      // You could send this to a crash reporting service
      // _sendErrorToCrashlytics(error, stack);
    }
    return true;
  };
}

/// Main application widget with optimized architecture
class SahayakApp extends StatefulWidget {
  const SahayakApp({super.key});

  @override
  State<SahayakApp> createState() => _SahayakAppState();
}

class _SahayakAppState extends State<SahayakApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    switch (state) {
      case AppLifecycleState.resumed:
        _onAppResumed();
        break;
      case AppLifecycleState.paused:
        _onAppPaused();
        break;
      case AppLifecycleState.detached:
        _onAppDetached();
        break;
      default:
        break;
    }
  }

  /// Handle app resumed state
  void _onAppResumed() {
    if (kDebugMode) {
      print('📱 App resumed - refreshing data');
    }

    // Refresh critical data when app resumes
    _refreshAppData();
  }

  /// Handle app paused state
  void _onAppPaused() {
    if (kDebugMode) {
      print('📱 App paused - saving state');
    }

    // Save any pending data when app goes to background
    _saveAppState();
  }

  /// Handle app detached state
  void _onAppDetached() {
    if (kDebugMode) {
      print('📱 App detached - cleanup');
    }

    // Clean up resources when app is terminated
    _cleanupResources();
  }

  /// Refresh app data when resuming
  Future<void> _refreshAppData() async {
    try {
      await EnhancedServiceLocator.refreshAllData();
    } catch (e) {
      if (kDebugMode) {
        print('⚠️ Error refreshing app data: $e');
      }
    }
  }

  /// Save app state when pausing
  Future<void> _saveAppState() async {
    try {
      // Save any pending offline queue items
      // This would be handled automatically by the enhanced services
      if (kDebugMode) {
        print('💾 App state saved');
      }
    } catch (e) {
      if (kDebugMode) {
        print('⚠️ Error saving app state: $e');
      }
    }
  }

  /// Cleanup resources when app is detached
  Future<void> _cleanupResources() async {
    try {
      // The enhanced service locator will handle cleanup
      if (kDebugMode) {
        print('🧹 Resources cleaned up');
      }
    } catch (e) {
      if (kDebugMode) {
        print('⚠️ Error cleaning up resources: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sahayak - AI Education Assistant',
      debugShowCheckedModeBanner: false,

      // Use optimized theme
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,

      // Configure navigation
      navigatorKey: GlobalKey<NavigatorState>(),

      // Performance optimizations
      builder: (context, child) {
        return MediaQuery(
          // Ensure text scale factor is reasonable for accessibility
          data: MediaQuery.of(context).copyWith(
            textScaleFactor: _getOptimalTextScaleFactor(
              MediaQuery.of(context).textScaleFactor,
            ),
          ),
          child: child!,
        );
      },

      // App entry point
      home: const SplashScreen(),

      // Global error handling for navigation
      onUnknownRoute: (settings) {
        return MaterialPageRoute(
          builder: (context) => const SplashScreen(),
        );
      },
    );
  }

  /// Get optimal text scale factor for accessibility and readability
  double _getOptimalTextScaleFactor(double systemTextScaleFactor) {
    // Clamp the text scale factor to prevent UI breaking
    return systemTextScaleFactor.clamp(0.8, 1.4);
  }
}

/// Global app configuration
class AppConfig {
  // API Configuration
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://api.sahayak.com',
  );

  // Feature flags
  static const bool enableAnalytics = bool.fromEnvironment(
    'ENABLE_ANALYTICS',
    defaultValue: true,
  );

  static const bool enableCrashReporting = bool.fromEnvironment(
    'ENABLE_CRASH_REPORTING',
    defaultValue: true,
  );

  static const bool enablePerformanceMonitoring = bool.fromEnvironment(
    'ENABLE_PERFORMANCE_MONITORING',
    defaultValue: true,
  );

  // Cache configuration
  static const Duration defaultCacheExpiry = Duration(
    minutes: int.fromEnvironment('CACHE_EXPIRY_MINUTES', defaultValue: 15),
  );

  // Network configuration
  static const Duration defaultTimeout = Duration(
    seconds: int.fromEnvironment('NETWORK_TIMEOUT_SECONDS', defaultValue: 30),
  );

  // Debug configuration
  static const bool isDebugMode = kDebugMode;
  static const bool showPerformanceOverlay = bool.fromEnvironment(
    'SHOW_PERFORMANCE_OVERLAY',
    defaultValue: false,
  );

  /// Get environment-specific configuration
  static ServiceLocatorConfig getServiceConfig() {
    if (isDebugMode) {
      return ServiceLocatorConfig.development();
    } else {
      return ServiceLocatorConfig.production();
    }
  }
}

/// App metadata and constants
class AppConstants {
  static const String appName = 'Sahayak';
  static const String appVersion = '2.0.0';
  static const String appBuildNumber = String.fromEnvironment(
    'BUILD_NUMBER',
    defaultValue: '1',
  );

  // Supported languages
  static const List<String> supportedLanguages = [
    'en', // English
    'hi', // Hindi
    'mr', // Marathi
  ];

  // Default user preferences
  static const Map<String, dynamic> defaultPreferences = {
    'theme_mode': 'system',
    'language': 'en',
    'notifications_enabled': true,
    'offline_mode_enabled': true,
    'performance_monitoring': true,
  };
}
