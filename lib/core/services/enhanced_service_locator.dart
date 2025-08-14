import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../api/enhanced_api_client.dart';
import '../cache/cache_manager.dart';
import '../performance/performance_monitor.dart';
import '../offline/offline_queue.dart';
import '../../data/services/optimized_chat_service.dart';
import '../../data/services/optimized_dashboard_service.dart';
import '../../data/services/optimized_content_service.dart';

/// Enhanced service locator with optimized architecture
class EnhancedServiceLocator {
  static final GetIt _getIt = GetIt.instance;
  static bool _isInitialized = false;

  /// Initialize all services with dependency injection
  static Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Core dependencies
      await _registerCoreDependencies();

      // Infrastructure services
      await _registerInfrastructureServices();

      // Business services
      await _registerBusinessServices();

      // Start background services
      await _startBackgroundServices();

      _isInitialized = true;
      print('✅ Enhanced ServiceLocator initialized successfully');
    } catch (e) {
      print('❌ ServiceLocator initialization failed: $e');
      rethrow;
    }
  }

  /// Register core dependencies (singletons)
  static Future<void> _registerCoreDependencies() async {
    // Shared Preferences
    final sharedPreferences = await SharedPreferences.getInstance();
    _getIt.registerSingleton<SharedPreferences>(sharedPreferences);

    // Connectivity
    _getIt.registerSingleton<Connectivity>(Connectivity());

    // Performance Monitor
    _getIt.registerSingleton<PerformanceMonitor>(PerformanceMonitor());

    // Cache Manager
    _getIt.registerSingleton<CacheManager>(CacheManager());

    // Offline Queue
    _getIt.registerSingleton<OfflineQueue>(OfflineQueue());
  }

  /// Register infrastructure services
  static Future<void> _registerInfrastructureServices() async {
    // Enhanced API Client with all optimizations
    _getIt.registerSingleton<EnhancedApiClient>(
      EnhancedApiClient(),
    );
  }

  /// Register business services
  static Future<void> _registerBusinessServices() async {
    final apiClient = _getIt<EnhancedApiClient>();

    // Auth Service (using legacy API client for now)
    // Note: This would need to be updated to use EnhancedApiClient
    // _getIt.registerSingleton<AuthService>(
    //   AuthService(apiClient),
    // );

    // Optimized Chat Service
    _getIt.registerSingleton<OptimizedChatService>(
      OptimizedChatService(apiClient),
    );

    // Optimized Dashboard Service
    _getIt.registerSingleton<OptimizedDashboardService>(
      OptimizedDashboardService(apiClient),
    );

    // Optimized Content Service
    _getIt.registerSingleton<OptimizedContentService>(
      OptimizedContentService(apiClient),
    );
  }

  /// Start background services
  static Future<void> _startBackgroundServices() async {
    // Start background refresh for dashboard
    _getIt<OptimizedDashboardService>().getDashboardDataStream();

    // Start background sync for content
    _getIt<OptimizedContentService>().startBackgroundSync();

    // Initialize offline queue processing
    await _getIt<OfflineQueue>().initialize();

    print('🔄 Background services started');
  }

  /// Get service instance
  static T get<T extends Object>() {
    if (!_isInitialized) {
      throw StateError(
          'ServiceLocator not initialized. Call initialize() first.');
    }
    return _getIt<T>();
  }

  /// Check if service is registered
  static bool isRegistered<T extends Object>() {
    return _getIt.isRegistered<T>();
  }

  /// Reset all services (for testing)
  static Future<void> reset() async {
    if (_isInitialized) {
      // Dispose services that need cleanup
      if (_getIt.isRegistered<OptimizedChatService>()) {
        _getIt<OptimizedChatService>().dispose();
      }
      if (_getIt.isRegistered<OptimizedDashboardService>()) {
        _getIt<OptimizedDashboardService>().dispose();
      }
      if (_getIt.isRegistered<OptimizedContentService>()) {
        _getIt<OptimizedContentService>().dispose();
      }
    }

    await _getIt.reset();
    _isInitialized = false;
    print('🔄 ServiceLocator reset');
  }

  /// Get enhanced API client
  static EnhancedApiClient get apiClient => get<EnhancedApiClient>();

  /// Get optimized chat service
  static OptimizedChatService get chatService => get<OptimizedChatService>();

  /// Get optimized dashboard service
  static OptimizedDashboardService get dashboardService =>
      get<OptimizedDashboardService>();

  /// Get optimized content service
  static OptimizedContentService get contentService =>
      get<OptimizedContentService>();

  /// Get cache manager
  static CacheManager get cacheManager => get<CacheManager>();

  /// Get performance monitor
  static PerformanceMonitor get performanceMonitor => get<PerformanceMonitor>();

  /// Get offline queue
  static OfflineQueue get offlineQueue => get<OfflineQueue>();

  /// Get app health status
  static AppHealthStatus getHealthStatus() {
    if (!_isInitialized) {
      return AppHealthStatus.notInitialized;
    }

    try {
      // Simple health check based on service availability
      final hasApiClient = isRegistered<EnhancedApiClient>();
      final hasCacheManager = isRegistered<CacheManager>();
      final hasPerformanceMonitor = isRegistered<PerformanceMonitor>();

      if (hasApiClient && hasCacheManager && hasPerformanceMonitor) {
        return AppHealthStatus.healthy;
      } else {
        return AppHealthStatus.degraded;
      }
    } catch (e) {
      return AppHealthStatus.error;
    }
  }

  /// Get service diagnostics
  static Map<String, dynamic> getDiagnostics() {
    if (!_isInitialized) {
      return {'status': 'not_initialized'};
    }

    return {
      'status': 'initialized',
      'services_registered': [
        'EnhancedApiClient',
        'CacheManager',
        'PerformanceMonitor',
        'OfflineQueue',
        'OptimizedChatService',
        'OptimizedDashboardService',
        'OptimizedContentService'
      ].where((service) => _isServiceRegistered(service)).length,
      'health_status': getHealthStatus().name,
      'api_client': {
        'is_healthy': true, // Simplified health check
      },
      'cache_manager': {
        'is_available': isRegistered<CacheManager>(),
      },
      'performance': {
        'is_monitoring': isRegistered<PerformanceMonitor>(),
      },
      'offline_queue': {
        'is_available': isRegistered<OfflineQueue>(),
      },
    };
  }

  static bool _isServiceRegistered(String serviceName) {
    try {
      switch (serviceName) {
        case 'EnhancedApiClient':
          return isRegistered<EnhancedApiClient>();
        case 'CacheManager':
          return isRegistered<CacheManager>();
        case 'PerformanceMonitor':
          return isRegistered<PerformanceMonitor>();
        case 'OfflineQueue':
          return isRegistered<OfflineQueue>();
        case 'OptimizedChatService':
          return isRegistered<OptimizedChatService>();
        case 'OptimizedDashboardService':
          return isRegistered<OptimizedDashboardService>();
        case 'OptimizedContentService':
          return isRegistered<OptimizedContentService>();
        default:
          return false;
      }
    } catch (e) {
      return false;
    }
  }

  /// Clear all caches
  static Future<void> clearAllCaches() async {
    if (!_isInitialized) return;

    await Future.wait([
      get<CacheManager>().clear(),
      get<OptimizedChatService>().clearCache(),
      get<OptimizedDashboardService>().clearCache(),
      get<OptimizedContentService>().clearCache(),
    ]);

    print('🧹 All caches cleared');
  }

  /// Refresh all data
  static Future<void> refreshAllData() async {
    if (!_isInitialized) return;

    try {
      await Future.wait([
        get<OptimizedDashboardService>().loadDashboardData(forceRefresh: true),
        get<OptimizedContentService>().getContentList(forceRefresh: true),
      ]);

      print('🔄 All data refreshed');
    } catch (e) {
      print('⚠️ Error refreshing data: $e');
    }
  }
}

/// App health status
enum AppHealthStatus {
  notInitialized,
  healthy,
  degraded,
  unhealthy,
  error,
}

/// Service locator configuration
class ServiceLocatorConfig {
  final String apiBaseUrl;
  final bool enableCaching;
  final bool enableOfflineQueue;
  final bool enablePerformanceMonitoring;
  final Duration cacheExpiry;
  final Duration offlineRetryInterval;

  const ServiceLocatorConfig({
    this.apiBaseUrl = 'https://api.sahayak.com',
    this.enableCaching = true,
    this.enableOfflineQueue = true,
    this.enablePerformanceMonitoring = true,
    this.cacheExpiry = const Duration(minutes: 15),
    this.offlineRetryInterval = const Duration(minutes: 5),
  });

  /// Default production configuration
  factory ServiceLocatorConfig.production() {
    return const ServiceLocatorConfig(
      apiBaseUrl: 'https://api.sahayak.com',
      enableCaching: true,
      enableOfflineQueue: true,
      enablePerformanceMonitoring: true,
    );
  }

  /// Development configuration with extended caching
  factory ServiceLocatorConfig.development() {
    return const ServiceLocatorConfig(
      apiBaseUrl: 'https://dev-api.sahayak.com',
      enableCaching: true,
      enableOfflineQueue: true,
      enablePerformanceMonitoring: true,
      cacheExpiry: Duration(hours: 1),
    );
  }

  /// Testing configuration with minimal caching
  factory ServiceLocatorConfig.testing() {
    return const ServiceLocatorConfig(
      apiBaseUrl: 'https://test-api.sahayak.com',
      enableCaching: false,
      enableOfflineQueue: false,
      enablePerformanceMonitoring: false,
      cacheExpiry: Duration(seconds: 30),
    );
  }
}
