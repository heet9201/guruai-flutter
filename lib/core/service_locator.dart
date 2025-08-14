import 'dart:async';
import '../data/services/chat_service.dart';
import '../data/services/dashboard_service.dart';
import '../data/services/content_service.dart';
import '../data/services/optimized_chat_service.dart';
import '../data/services/optimized_dashboard_service.dart';
import '../data/services/optimized_content_service.dart';
import 'api/enhanced_api_client.dart';
import 'api/api_orchestrator.dart';
import 'cache/cache_manager.dart';
import 'performance/performance_monitor.dart';

/// Enhanced service locator with comprehensive API optimizations
class ServiceLocator {
  static final ServiceLocator _instance = ServiceLocator._internal();
  factory ServiceLocator() => _instance;
  ServiceLocator._internal();

  // Core optimization components
  late final EnhancedApiClient _enhancedApiClient;
  late final ApiOrchestrator _apiOrchestrator;
  late final CacheManager _cacheManager;
  late final PerformanceMonitor _performanceMonitor;

  // Legacy services (for backward compatibility)
  late final ChatService _chatService;
  late final DashboardService _dashboardService;
  late final ContentService _contentService;

  // Optimized services (recommended for new implementations)
  late final OptimizedChatService _optimizedChatService;
  late final OptimizedDashboardService _optimizedDashboardService;
  late final OptimizedContentService _optimizedContentService;

  // Service health tracking
  final Map<String, bool> _serviceHealth = {};
  DateTime? _lastInitialization;

  void initialize() {
    final startTime = DateTime.now();
    print('🚀 Initializing Enhanced Service Locator...');

    try {
      // Initialize core optimization components
      _initializeCoreComponents();

      // Initialize legacy services for backward compatibility
      _initializeLegacyServices();

      // Initialize optimized services
      _initializeOptimizedServices();

      // Setup service health monitoring
      _setupServiceHealthMonitoring();

      // Track initialization performance
      _lastInitialization = DateTime.now();
      final initDuration = _lastInitialization!.difference(startTime);

      print(
          '✅ Service Locator initialized in ${initDuration.inMilliseconds}ms');
      print('📊 Available services: ${_getServiceSummary()}');
    } catch (e) {
      print('❌ Service Locator initialization failed: $e');
      rethrow;
    }
  }

  void _initializeCoreComponents() {
    // Enhanced API client with circuit breaker and optimizations
    _enhancedApiClient = EnhancedApiClient();
    _serviceHealth['enhanced_api_client'] = true;

    // Cache manager for multi-level caching
    _cacheManager = CacheManager();
    _serviceHealth['cache_manager'] = true;

    // Performance monitor for tracking optimization effectiveness
    _performanceMonitor = PerformanceMonitor();
    _serviceHealth['performance_monitor'] = true;

    // API orchestrator for request coordination and optimization
    _apiOrchestrator = ApiOrchestrator();
    _apiOrchestrator.initialize();
    _serviceHealth['api_orchestrator'] = true;

    print('🔧 Core optimization components initialized');
  }

  void _initializeLegacyServices() {
    try {
      _chatService = ChatService();
      _dashboardService = DashboardService();
      _contentService = ContentService();

      _serviceHealth['legacy_chat'] = true;
      _serviceHealth['legacy_dashboard'] = true;
      _serviceHealth['legacy_content'] = true;

      print('📦 Legacy services initialized (backward compatibility)');
    } catch (e) {
      print('⚠️ Legacy services initialization failed: $e');
      // Continue with optimized services even if legacy fails
    }
  }

  void _initializeOptimizedServices() {
    // Optimized chat service with real-time features
    _optimizedChatService = OptimizedChatService(_enhancedApiClient);
    _serviceHealth['optimized_chat'] = true;

    // Optimized dashboard service with progressive loading
    _optimizedDashboardService = OptimizedDashboardService(_enhancedApiClient);
    _serviceHealth['optimized_dashboard'] = true;

    // Optimized content service with intelligent caching
    _optimizedContentService = OptimizedContentService(_enhancedApiClient);
    _serviceHealth['optimized_content'] = true;

    print('⚡ Optimized services initialized');
  }

  void _setupServiceHealthMonitoring() {
    // Setup periodic health checks
    Timer.periodic(const Duration(minutes: 5), (timer) {
      _performHealthCheck();
    });

    print('💗 Service health monitoring active');
  }

  void _performHealthCheck() {
    try {
      // Check enhanced API client health
      _serviceHealth['enhanced_api_client'] = _enhancedApiClient.isHealthy();

      // Check cache manager health
      _serviceHealth['cache_manager'] = _cacheManager.isHealthy();

      // Check performance monitor health
      _serviceHealth['performance_monitor'] = _performanceMonitor.isHealthy();

      // Log unhealthy services
      final unhealthyServices = _serviceHealth.entries
          .where((entry) => !entry.value)
          .map((entry) => entry.key)
          .toList();

      if (unhealthyServices.isNotEmpty) {
        print(
            '⚠️ Unhealthy services detected: ${unhealthyServices.join(', ')}');
      }
    } catch (e) {
      print('❌ Health check failed: $e');
    }
  }

  String _getServiceSummary() {
    final healthyCount = _serviceHealth.values.where((health) => health).length;
    final totalCount = _serviceHealth.length;
    return '$healthyCount/$totalCount services healthy';
  }

  // Legacy service getters (for backward compatibility)
  static ChatService get chatService => _instance._chatService;
  static DashboardService get dashboardService => _instance._dashboardService;
  static ContentService get contentService => _instance._contentService;

  // Optimized service getters (recommended for new implementations)
  static OptimizedChatService get optimizedChatService =>
      _instance._optimizedChatService;
  static OptimizedDashboardService get optimizedDashboardService =>
      _instance._optimizedDashboardService;
  static OptimizedContentService get optimizedContentService =>
      _instance._optimizedContentService;

  // Core component getters
  static EnhancedApiClient get enhancedApiClient =>
      _instance._enhancedApiClient;
  static ApiOrchestrator get apiOrchestrator => _instance._apiOrchestrator;
  static CacheManager get cacheManager => _instance._cacheManager;
  static PerformanceMonitor get performanceMonitor =>
      _instance._performanceMonitor;

  // Service selection helpers for gradual migration
  static ChatService get recommendedChatService {
    try {
      // Return optimized service if available and healthy
      if (_instance._serviceHealth['optimized_chat'] == true) {
        return _instance._optimizedChatService;
      }
    } catch (e) {
      print('⚠️ Falling back to legacy chat service: $e');
    }

    // Fallback to legacy service
    return _instance._chatService;
  }

  static DashboardService get recommendedDashboardService {
    try {
      // Return optimized service if available and healthy
      if (_instance._serviceHealth['optimized_dashboard'] == true) {
        return _instance._optimizedDashboardService;
      }
    } catch (e) {
      print('⚠️ Falling back to legacy dashboard service: $e');
    }

    // Fallback to legacy service
    return _instance._dashboardService;
  }

  static ContentService get recommendedContentService {
    try {
      // Return optimized service if available and healthy
      if (_instance._serviceHealth['optimized_content'] == true) {
        return _instance._optimizedContentService;
      }
    } catch (e) {
      print('⚠️ Falling back to legacy content service: $e');
    }

    // Fallback to legacy service
    return _instance._contentService;
  }

  // Performance and health monitoring
  static Map<String, bool> get serviceHealth =>
      Map.unmodifiable(_instance._serviceHealth);

  static ServiceLocatorStats get stats {
    final uptime = _instance._lastInitialization != null
        ? DateTime.now().difference(_instance._lastInitialization!)
        : Duration.zero;

    return ServiceLocatorStats(
      uptime: uptime,
      healthyServices:
          _instance._serviceHealth.values.where((health) => health).length,
      totalServices: _instance._serviceHealth.length,
      cacheHitRate: _instance._cacheManager.getHitRate(),
      apiOptimizationStats: _instance._apiOrchestrator.getOptimizationStats(),
    );
  }

  // Service migration helpers
  static bool get isOptimizedChatAvailable =>
      _instance._serviceHealth['optimized_chat'] == true;
  static bool get isOptimizedDashboardAvailable =>
      _instance._serviceHealth['optimized_dashboard'] == true;
  static bool get isOptimizedContentAvailable =>
      _instance._serviceHealth['optimized_content'] == true;

  // Cleanup method
  static void dispose() {
    try {
      _instance._apiOrchestrator.dispose();
      _instance._optimizedChatService.dispose();
      _instance._optimizedDashboardService.dispose();
      _instance._optimizedContentService.dispose();

      print('🧹 Service Locator disposed');
    } catch (e) {
      print('⚠️ Service Locator disposal failed: $e');
    }
  }

  // Debug information
  static void printDebugInfo() {
    print('\n📊 === Service Locator Debug Info ===');
    print('Initialization Time: ${_instance._lastInitialization}');
    print('Service Health: ${_instance._serviceHealth}');
    print('Stats: ${_instance.stats}');
    print(
        'API Orchestrator: ${_instance._apiOrchestrator.getOptimizationStats()}');
    print('Performance Monitor: ${_instance._performanceMonitor.getStats()}');
    print(
        'Cache Manager: Hit Rate ${(_instance._cacheManager.getHitRate() * 100).toStringAsFixed(1)}%');
    print('================================\n');
  }
}

/// Service locator statistics
class ServiceLocatorStats {
  final Duration uptime;
  final int healthyServices;
  final int totalServices;
  final double cacheHitRate;
  final ApiOptimizationStats apiOptimizationStats;

  const ServiceLocatorStats({
    required this.uptime,
    required this.healthyServices,
    required this.totalServices,
    required this.cacheHitRate,
    required this.apiOptimizationStats,
  });

  double get healthPercentage => healthyServices / totalServices;

  @override
  String toString() {
    return 'ServiceLocatorStats('
        'uptime: ${uptime.inMinutes}m, '
        'health: $healthyServices/$totalServices (${(healthPercentage * 100).toStringAsFixed(1)}%), '
        'cache: ${(cacheHitRate * 100).toStringAsFixed(1)}%, '
        'api: $apiOptimizationStats)';
  }
}
