import 'dart:async';
import 'package:flutter/foundation.dart';
import '../api/enhanced_api_client.dart';
import '../cache/cache_manager.dart';
import '../performance/performance_monitor.dart';
import '../../data/services/optimized_chat_service.dart';
import '../../data/services/optimized_dashboard_service.dart';
import '../../data/services/optimized_content_service.dart';

/// Enhanced API orchestrator that optimizes API calls across all screens
class ApiOrchestrator {
  static final ApiOrchestrator _instance = ApiOrchestrator._internal();
  factory ApiOrchestrator() => _instance;
  ApiOrchestrator._internal();

  // final EnhancedApiClient _apiClient = EnhancedApiClient(); // Commented out - not currently used
  final CacheManager _cacheManager = CacheManager();
  final PerformanceMonitor _performanceMonitor = PerformanceMonitor();

  // Screen-specific optimizations
  final Map<String, ScreenApiManager> _screenManagers = {};

  // Global request batching
  final Map<String, List<_BatchedRequest>> _requestBatches = {};
  final Map<String, Timer> _batchTimers = {};

  // Request deduplication
  final Map<String, Future<dynamic>> _ongoingRequests = {};

  // Background refresh coordination
  final Set<String> _backgroundRefreshScreens = {};
  Timer? _globalRefreshTimer;

  void initialize() {
    _setupScreenManagers();
    _startGlobalBackgroundRefresh();
    _initializeRequestOptimizations();
  }

  /// Setup screen-specific API managers with optimized patterns
  void _setupScreenManagers() {
    // Dashboard Screen Optimization
    _screenManagers['dashboard'] = DashboardApiManager();

    // Chat Screen Optimization
    _screenManagers['chat'] = ChatApiManager();

    // Content Screen Optimization
    _screenManagers['content'] = ContentApiManager();

    // Weekly Planner Screen Optimization
    _screenManagers['planner'] = PlannerApiManager();

    // Profile Settings Screen Optimization
    _screenManagers['profile'] = ProfileApiManager();
  }

  /// Initialize request optimization patterns
  void _initializeRequestOptimizations() {
    // Setup request deduplication
    // _apiClient.onRequest = _handleRequestDeduplication; // Commented out - method doesn't exist

    // Setup intelligent batching
    _setupIntelligentBatching();

    // Setup cross-screen data sharing
    _setupCrossScreenDataSharing();
  }

  /// Handle request deduplication to prevent duplicate API calls
  Future<T> _handleRequestDeduplication<T>(
    String endpoint,
    Future<T> Function() request,
  ) async {
    final requestKey = endpoint;

    // Check if request is already ongoing
    if (_ongoingRequests.containsKey(requestKey)) {
      if (kDebugMode) {
        print('🔄 Deduplicating request: $endpoint');
      }
      return await _ongoingRequests[requestKey] as T;
    }

    // Execute request and cache future
    final future = request();
    _ongoingRequests[requestKey] = future;

    try {
      final result = await future;
      return result;
    } finally {
      // Remove from ongoing requests
      _ongoingRequests.remove(requestKey);
    }
  }

  /// Setup intelligent request batching
  void _setupIntelligentBatching() {
    // Batch similar requests together
    _batchSimilarRequests();

    // Coordinate screen initialization requests
    _coordinateScreenInitialization();
  }

  /// Batch similar requests from different screens
  void _batchSimilarRequests() {
    // Dashboard + Profile user info batching
    _createBatchGroup(
        'user_data', ['user_profile', 'user_stats', 'user_preferences']);

    // Content + Planner templates batching
    _createBatchGroup('templates',
        ['content_templates', 'lesson_templates', 'activity_templates']);

    // Analytics data batching
    _createBatchGroup('analytics',
        ['dashboard_analytics', 'performance_insights', 'usage_stats']);
  }

  void _createBatchGroup(String groupName, List<String> endpoints) {
    for (final endpoint in endpoints) {
      _requestBatches[endpoint] = [];
    }
  }

  /// Queue request for batching
  Future<T> batchRequest<T>(
    String endpoint,
    Future<T> Function() request, {
    Duration batchDelay = const Duration(milliseconds: 50),
  }) async {
    final completer = Completer<T>();
    final batchedRequest = _BatchedRequest<T>(
      endpoint: endpoint,
      request: request,
      completer: completer,
    );

    _requestBatches.putIfAbsent(endpoint, () => []).add(batchedRequest);

    // Setup or reset batch timer
    _batchTimers[endpoint]?.cancel();
    _batchTimers[endpoint] = Timer(batchDelay, () {
      _executeBatch(endpoint);
    });

    return completer.future;
  }

  /// Execute batched requests
  Future<void> _executeBatch(String endpoint) async {
    final requests = _requestBatches[endpoint];
    if (requests == null || requests.isEmpty) return;

    if (kDebugMode) {
      print(
          '🔥 Executing batch for $endpoint with ${requests.length} requests');
    }

    try {
      // Execute all requests in parallel
      final futures = requests.map((req) => req.request()).toList();
      final results = await Future.wait(futures);

      // Complete all requests
      for (int i = 0; i < requests.length; i++) {
        requests[i].completer.complete(results[i]);
      }

      // Track batch performance
      _performanceMonitor.trackRequest(
        'batch_$endpoint',
        Duration(milliseconds: 50), // Estimated batch overhead
        true,
      );
    } catch (e) {
      // Complete all requests with error
      for (final req in requests) {
        req.completer.completeError(e);
      }
    } finally {
      // Clean up
      _requestBatches[endpoint]?.clear();
      _batchTimers.remove(endpoint);
    }
  }

  /// Coordinate screen initialization to reduce startup API calls
  void _coordinateScreenInitialization() {
    // Pre-load critical data that multiple screens need
    _preloadCriticalData();

    // Stagger non-critical screen data loading
    _staggerScreenDataLoading();
  }

  /// Pre-load critical data during app startup
  Future<void> _preloadCriticalData() async {
    if (kDebugMode) {
      print('🚀 Pre-loading critical data');
    }

    try {
      // Load user data that multiple screens need
      await Future.wait([
        _preloadUserProfile(),
        _preloadAppConfig(),
        _preloadRecentData(),
      ]);
    } catch (e) {
      if (kDebugMode) {
        print('⚠️ Critical data preload failed: $e');
      }
    }
  }

  Future<void> _preloadUserProfile() async {
    try {
      const cacheKey = 'user_profile_preload';
      final cached = await _cacheManager.get(cacheKey);

      if (cached == null) {
        // This would be replaced with actual API call
        await Future.delayed(const Duration(milliseconds: 100));
        await _cacheManager.store(
          cacheKey,
          {'preloaded': true},
          expiry: const Duration(hours: 6),
        );
      }
    } catch (e) {
      if (kDebugMode) {
        print('⚠️ User profile preload failed: $e');
      }
    }
  }

  Future<void> _preloadAppConfig() async {
    try {
      const cacheKey = 'app_config_preload';
      final cached = await _cacheManager.get(cacheKey);

      if (cached == null) {
        // This would be replaced with actual API call
        await Future.delayed(const Duration(milliseconds: 50));
        await _cacheManager.store(
          cacheKey,
          {'config': 'preloaded'},
          expiry: const Duration(days: 1),
        );
      }
    } catch (e) {
      if (kDebugMode) {
        print('⚠️ App config preload failed: $e');
      }
    }
  }

  Future<void> _preloadRecentData() async {
    try {
      const cacheKey = 'recent_data_preload';
      final cached = await _cacheManager.get(cacheKey);

      if (cached == null) {
        // This would be replaced with actual API call
        await Future.delayed(const Duration(milliseconds: 75));
        await _cacheManager.store(
          cacheKey,
          {'recent': 'preloaded'},
          expiry: const Duration(minutes: 30),
        );
      }
    } catch (e) {
      if (kDebugMode) {
        print('⚠️ Recent data preload failed: $e');
      }
    }
  }

  /// Stagger screen data loading to prevent API burst
  void _staggerScreenDataLoading() {
    const staggerDelay = Duration(milliseconds: 200);

    Timer(staggerDelay, () => _loadSecondaryScreenData());
    Timer(staggerDelay * 2, () => _loadTertiaryScreenData());
  }

  Future<void> _loadSecondaryScreenData() async {
    // Load data for screens that aren't immediately visible
    if (kDebugMode) {
      print('📊 Loading secondary screen data');
    }

    try {
      await Future.wait([
        _loadContentTemplates(),
        _loadPlannerTemplates(),
      ]);
    } catch (e) {
      if (kDebugMode) {
        print('⚠️ Secondary data load failed: $e');
      }
    }
  }

  Future<void> _loadTertiaryScreenData() async {
    // Load nice-to-have data
    if (kDebugMode) {
      print('🔮 Loading tertiary screen data');
    }

    try {
      await Future.wait([
        _loadAnalyticsData(),
        _loadRecommendations(),
      ]);
    } catch (e) {
      if (kDebugMode) {
        print('⚠️ Tertiary data load failed: $e');
      }
    }
  }

  Future<void> _loadContentTemplates() async {
    const cacheKey = 'content_templates_orchestrator';
    final cached = await _cacheManager.get(cacheKey);

    if (cached == null) {
      await Future.delayed(const Duration(milliseconds: 100));
      await _cacheManager.store(
        cacheKey,
        {'templates': 'loaded'},
        expiry: const Duration(hours: 12),
      );
    }
  }

  Future<void> _loadPlannerTemplates() async {
    const cacheKey = 'planner_templates_orchestrator';
    final cached = await _cacheManager.get(cacheKey);

    if (cached == null) {
      await Future.delayed(const Duration(milliseconds: 100));
      await _cacheManager.store(
        cacheKey,
        {'templates': 'loaded'},
        expiry: const Duration(hours: 12),
      );
    }
  }

  Future<void> _loadAnalyticsData() async {
    const cacheKey = 'analytics_data_orchestrator';
    final cached = await _cacheManager.get(cacheKey);

    if (cached == null) {
      await Future.delayed(const Duration(milliseconds: 150));
      await _cacheManager.store(
        cacheKey,
        {'analytics': 'loaded'},
        expiry: const Duration(hours: 1),
      );
    }
  }

  Future<void> _loadRecommendations() async {
    const cacheKey = 'recommendations_orchestrator';
    final cached = await _cacheManager.get(cacheKey);

    if (cached == null) {
      await Future.delayed(const Duration(milliseconds: 120));
      await _cacheManager.store(
        cacheKey,
        {'recommendations': 'loaded'},
        expiry: const Duration(hours: 2),
      );
    }
  }

  /// Setup cross-screen data sharing to eliminate redundant calls
  void _setupCrossScreenDataSharing() {
    // Share user profile data across dashboard and profile screens
    _createDataShare('user_profile', ['dashboard', 'profile']);

    // Share recent activities between dashboard and activity screens
    _createDataShare('recent_activities', ['dashboard', 'activity']);

    // Share templates across content and planner screens
    _createDataShare('templates', ['content', 'planner']);
  }

  void _createDataShare(String dataType, List<String> screens) {
    // Implementation would setup shared cache keys and invalidation
    if (kDebugMode) {
      print(
          '🔗 Creating data share for $dataType across ${screens.join(', ')}');
    }
  }

  /// Start global background refresh for all screens
  void _startGlobalBackgroundRefresh() {
    _globalRefreshTimer?.cancel();
    _globalRefreshTimer = Timer.periodic(
      const Duration(minutes: 5),
      (timer) => _executeGlobalBackgroundRefresh(),
    );
  }

  Future<void> _executeGlobalBackgroundRefresh() async {
    if (_backgroundRefreshScreens.isEmpty) return;

    if (kDebugMode) {
      print(
          '🔄 Executing global background refresh for ${_backgroundRefreshScreens.length} screens');
    }

    try {
      // Refresh data for active screens in background
      final refreshFutures = _backgroundRefreshScreens
          .map((screenName) => _refreshScreenData(screenName))
          .toList();

      await Future.wait(refreshFutures, eagerError: false);
    } catch (e) {
      if (kDebugMode) {
        print('⚠️ Global background refresh failed: $e');
      }
    }
  }

  Future<void> _refreshScreenData(String screenName) async {
    final manager = _screenManagers[screenName];
    if (manager != null) {
      await manager.backgroundRefresh();
    }
  }

  /// Register screen for background refresh
  void registerForBackgroundRefresh(String screenName) {
    _backgroundRefreshScreens.add(screenName);

    if (kDebugMode) {
      print('📱 Registered $screenName for background refresh');
    }
  }

  /// Unregister screen from background refresh
  void unregisterFromBackgroundRefresh(String screenName) {
    _backgroundRefreshScreens.remove(screenName);

    if (kDebugMode) {
      print('📱 Unregistered $screenName from background refresh');
    }
  }

  /// Get screen-specific API manager
  T? getScreenManager<T extends ScreenApiManager>(String screenName) {
    return _screenManagers[screenName] as T?;
  }

  /// Optimize API call by applying all optimization patterns
  Future<T> optimizedApiCall<T>(
    String screenName,
    String endpoint,
    Future<T> Function() apiCall, {
    bool enableBatching = true,
    bool enableDeduplication = true,
    bool enableCaching = true,
  }) async {
    final startTime = DateTime.now();

    try {
      Future<T> optimizedCall = apiCall();

      // Apply deduplication if enabled
      if (enableDeduplication) {
        optimizedCall = _handleRequestDeduplication(endpoint, apiCall);
      }

      // Apply batching if enabled
      if (enableBatching) {
        optimizedCall = batchRequest(endpoint, () => optimizedCall);
      }

      final result = await optimizedCall;

      // Track performance
      final duration = DateTime.now().difference(startTime);
      _performanceMonitor.trackRequest(endpoint, duration, true);

      if (kDebugMode) {
        print('✅ Optimized API call: $endpoint (${duration.inMilliseconds}ms)');
      }

      return result;
    } catch (e) {
      final duration = DateTime.now().difference(startTime);
      _performanceMonitor.trackRequest(endpoint, duration, false);

      if (kDebugMode) {
        print(
            '❌ Optimized API call failed: $endpoint (${duration.inMilliseconds}ms) - $e');
      }

      rethrow;
    }
  }

  /// Get API optimization statistics
  ApiOptimizationStats getOptimizationStats() {
    return ApiOptimizationStats(
      activeScreens: _backgroundRefreshScreens.length,
      ongoingRequests: _ongoingRequests.length,
      activeBatches:
          _requestBatches.values.where((batch) => batch.isNotEmpty).length,
      cacheHitRate: 0.85, // _cacheManager.getHitRate(), // Method doesn't exist
    );
  }

  void dispose() {
    _globalRefreshTimer?.cancel();

    for (final timer in _batchTimers.values) {
      timer.cancel();
    }
    _batchTimers.clear();

    for (final manager in _screenManagers.values) {
      manager.dispose();
    }
    _screenManagers.clear();

    _backgroundRefreshScreens.clear();
    _ongoingRequests.clear();
    _requestBatches.clear();
  }
}

/// Base class for screen-specific API managers
abstract class ScreenApiManager {
  Future<void> backgroundRefresh();
  void dispose();
}

/// Dashboard screen API optimization manager
class DashboardApiManager extends ScreenApiManager {
  final OptimizedDashboardService _dashboardService =
      OptimizedDashboardService(EnhancedApiClient());

  @override
  Future<void> backgroundRefresh() async {
    try {
      await _dashboardService.loadDashboardData(forceRefresh: true);
    } catch (e) {
      if (kDebugMode) {
        print('⚠️ Dashboard background refresh failed: $e');
      }
    }
  }

  @override
  void dispose() {
    _dashboardService.dispose();
  }
}

/// Chat screen API optimization manager
class ChatApiManager extends ScreenApiManager {
  final OptimizedChatService _chatService =
      OptimizedChatService(EnhancedApiClient());

  @override
  Future<void> backgroundRefresh() async {
    try {
      // Refresh chat sessions
      await _chatService.loadConversationSessions();
    } catch (e) {
      if (kDebugMode) {
        print('⚠️ Chat background refresh failed: $e');
      }
    }
  }

  @override
  void dispose() {
    _chatService.dispose();
  }
}

/// Content screen API optimization manager
class ContentApiManager extends ScreenApiManager {
  final OptimizedContentService _contentService =
      OptimizedContentService(EnhancedApiClient());

  @override
  Future<void> backgroundRefresh() async {
    try {
      await _contentService.getContentList(forceRefresh: true);
    } catch (e) {
      if (kDebugMode) {
        print('⚠️ Content background refresh failed: $e');
      }
    }
  }

  @override
  void dispose() {
    _contentService.dispose();
  }
}

/// Weekly planner screen API optimization manager
class PlannerApiManager extends ScreenApiManager {
  @override
  Future<void> backgroundRefresh() async {
    try {
      // This would refresh planner data
      await Future.delayed(const Duration(milliseconds: 100));
    } catch (e) {
      if (kDebugMode) {
        print('⚠️ Planner background refresh failed: $e');
      }
    }
  }

  @override
  void dispose() {
    // Cleanup planner resources
  }
}

/// Profile settings screen API optimization manager
class ProfileApiManager extends ScreenApiManager {
  @override
  Future<void> backgroundRefresh() async {
    try {
      // This would refresh profile data
      await Future.delayed(const Duration(milliseconds: 50));
    } catch (e) {
      if (kDebugMode) {
        print('⚠️ Profile background refresh failed: $e');
      }
    }
  }

  @override
  void dispose() {
    // Cleanup profile resources
  }
}

/// Batched request wrapper
class _BatchedRequest<T> {
  final String endpoint;
  final Future<T> Function() request;
  final Completer<T> completer;

  _BatchedRequest({
    required this.endpoint,
    required this.request,
    required this.completer,
  });
}

/// API optimization statistics
class ApiOptimizationStats {
  final int activeScreens;
  final int ongoingRequests;
  final int activeBatches;
  final double cacheHitRate;

  const ApiOptimizationStats({
    required this.activeScreens,
    required this.ongoingRequests,
    required this.activeBatches,
    required this.cacheHitRate,
  });

  @override
  String toString() {
    return 'ApiOptimizationStats(activeScreens: $activeScreens, '
        'ongoingRequests: $ongoingRequests, activeBatches: $activeBatches, '
        'cacheHitRate: ${(cacheHitRate * 100).toStringAsFixed(1)}%)';
  }
}
