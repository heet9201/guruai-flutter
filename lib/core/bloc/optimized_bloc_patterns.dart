import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/foundation.dart';
import '../../core/api/api_orchestrator.dart';
import '../../data/services/optimized_dashboard_service.dart';
import '../../data/services/optimized_chat_service.dart';
import '../../data/services/optimized_content_service.dart';
import '../../core/cache/cache_manager.dart';

/// Enhanced BLoC state management with API optimization patterns
abstract class OptimizedBlocState {
  final bool isLoading;
  final bool isRefreshing;
  final String? error;
  final DateTime? lastUpdated;
  final bool isFromCache;

  const OptimizedBlocState({
    this.isLoading = false,
    this.isRefreshing = false,
    this.error,
    this.lastUpdated,
    this.isFromCache = false,
  });

  /// Check if data is stale and needs refresh
  bool get isStale {
    if (lastUpdated == null) return true;
    return DateTime.now().difference(lastUpdated!).inMinutes > 5;
  }

  /// Check if refresh is needed
  bool get needsRefresh => isStale && !isLoading && !isRefreshing;
}

/// Enhanced BLoC event management
abstract class OptimizedBlocEvent {
  final bool forceRefresh;
  final bool silent;
  final Map<String, dynamic>? metadata;

  const OptimizedBlocEvent({
    this.forceRefresh = false,
    this.silent = false,
    this.metadata,
  });
}

/// Base optimized BLoC with common API optimization patterns
abstract class OptimizedBloc<Event extends OptimizedBlocEvent,
    State extends OptimizedBlocState> extends Bloc<Event, State> {
  final ApiOrchestrator _orchestrator = ApiOrchestrator();
  final CacheManager _cacheManager = CacheManager();

  // Track ongoing operations to prevent duplicates
  final Set<String> _ongoingOperations = {};

  // Progressive loading state
  final Map<String, StreamController<dynamic>> _progressStreams = {};

  // Background refresh timer
  Timer? _backgroundRefreshTimer;

  // Screen name for orchestrator
  final String screenName;

  OptimizedBloc({
    required this.screenName,
    required State initialState,
  }) : super(initialState) {
    _initializeOptimizations();
  }

  void _initializeOptimizations() {
    // Register for background refresh
    _orchestrator.registerForBackgroundRefresh(screenName);

    // Setup background refresh timer
    _setupBackgroundRefresh();

    // Setup progressive loading streams
    _setupProgressiveLoading();
  }

  void _setupBackgroundRefresh() {
    _backgroundRefreshTimer = Timer.periodic(
      const Duration(minutes: 2),
      (timer) => _handleBackgroundRefresh(),
    );
  }

  void _setupProgressiveLoading() {
    // Initialize progress streams for different data types
    _progressStreams['primary'] = StreamController<dynamic>.broadcast();
    _progressStreams['secondary'] = StreamController<dynamic>.broadcast();
    _progressStreams['tertiary'] = StreamController<dynamic>.broadcast();
  }

  /// Handle background refresh if data is stale
  Future<void> _handleBackgroundRefresh() async {
    if (state.needsRefresh) {
      await handleSilentRefresh();
    }
  }

  /// Execute optimized API call with all optimization patterns
  Future<T> executeOptimizedCall<T>(
    String operationName,
    Future<T> Function() apiCall, {
    bool enableCaching = true,
    bool enableBatching = true,
    bool enableProgressive = false,
    String? cacheKey,
  }) async {
    // Prevent duplicate operations
    if (_ongoingOperations.contains(operationName)) {
      if (kDebugMode) {
        print('🚫 Skipping duplicate operation: $operationName');
      }
      throw Exception('Operation already in progress: $operationName');
    }

    _ongoingOperations.add(operationName);

    try {
      // Check cache first if enabled
      if (enableCaching && cacheKey != null) {
        final cached = await _cacheManager.get(cacheKey);
        if (cached != null) {
          if (kDebugMode) {
            print('💾 Using cached data for: $operationName');
          }
          return cached as T;
        }
      }

      // Execute optimized API call through orchestrator
      final result = await _orchestrator.optimizedApiCall<T>(
        screenName,
        operationName,
        apiCall,
        enableBatching: enableBatching,
        enableDeduplication: true,
        enableCaching: enableCaching,
      );

      // Cache result if enabled
      if (enableCaching && cacheKey != null) {
        await _cacheManager.store(
          cacheKey,
          result,
          expiry: const Duration(minutes: 10),
        );
      }

      return result;
    } finally {
      _ongoingOperations.remove(operationName);
    }
  }

  /// Execute progressive loading with multiple priority levels
  Future<Map<String, dynamic>> executeProgressiveLoading(
    Map<String, Future<dynamic> Function()> operations,
  ) async {
    final results = <String, dynamic>{};

    // Group operations by priority
    final primaryOps = <String, Future<dynamic> Function()>{};
    final secondaryOps = <String, Future<dynamic> Function()>{};
    final tertiaryOps = <String, Future<dynamic> Function()>{};

    for (final entry in operations.entries) {
      if (entry.key.contains('primary') || entry.key.contains('critical')) {
        primaryOps[entry.key] = entry.value;
      } else if (entry.key.contains('secondary') ||
          entry.key.contains('important')) {
        secondaryOps[entry.key] = entry.value;
      } else {
        tertiaryOps[entry.key] = entry.value;
      }
    }

    try {
      // Execute primary operations first
      if (primaryOps.isNotEmpty) {
        final primaryResults =
            await _executeOperationBatch(primaryOps, 'primary');
        results.addAll(primaryResults);

        // Emit progress update
        _progressStreams['primary']?.add(primaryResults);
      }

      // Execute secondary operations
      if (secondaryOps.isNotEmpty) {
        final secondaryResults =
            await _executeOperationBatch(secondaryOps, 'secondary');
        results.addAll(secondaryResults);

        // Emit progress update
        _progressStreams['secondary']?.add(secondaryResults);
      }

      // Execute tertiary operations
      if (tertiaryOps.isNotEmpty) {
        final tertiaryResults =
            await _executeOperationBatch(tertiaryOps, 'tertiary');
        results.addAll(tertiaryResults);

        // Emit progress update
        _progressStreams['tertiary']?.add(tertiaryResults);
      }

      return results;
    } catch (e) {
      if (kDebugMode) {
        print('⚠️ Progressive loading failed: $e');
      }
      rethrow;
    }
  }

  /// Execute a batch of operations in parallel
  Future<Map<String, dynamic>> _executeOperationBatch(
    Map<String, Future<dynamic> Function()> operations,
    String priority,
  ) async {
    final results = <String, dynamic>{};

    try {
      // Execute all operations in parallel
      final futures = operations.entries.map((entry) async {
        try {
          final result = await executeOptimizedCall(
            '${priority}_${entry.key}',
            entry.value,
            enableCaching: true,
            enableBatching: true,
            cacheKey: '${screenName}_${entry.key}',
          );
          return MapEntry(entry.key, result);
        } catch (e) {
          if (kDebugMode) {
            print('⚠️ Operation ${entry.key} failed: $e');
          }
          return MapEntry(entry.key, null);
        }
      });

      final completedOperations = await Future.wait(futures);

      for (final entry in completedOperations) {
        if (entry.value != null) {
          results[entry.key] = entry.value;
        }
      }

      if (kDebugMode) {
        print('✅ Completed $priority batch: ${results.keys.join(', ')}');
      }

      return results;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Batch execution failed for $priority: $e');
      }
      return results;
    }
  }

  /// Optimistic update - immediately update UI, then sync with API
  Future<void> executeOptimisticUpdate<T>(
    T optimisticData,
    Future<T> Function() apiCall,
    void Function(T data, bool isOptimistic) updateState,
  ) async {
    try {
      // Immediately update UI with optimistic data
      updateState(optimisticData, true);

      if (kDebugMode) {
        print('⚡ Applied optimistic update for $screenName');
      }

      // Execute actual API call
      final actualData = await executeOptimizedCall(
        'optimistic_update',
        apiCall,
        enableCaching: true,
      );

      // Update UI with actual data
      updateState(actualData, false);

      if (kDebugMode) {
        print('✅ Confirmed optimistic update for $screenName');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Optimistic update failed for $screenName: $e');
      }

      // Handle optimistic update failure
      await handleOptimisticUpdateFailure(e);
    }
  }

  /// Handle failed optimistic updates
  Future<void> handleOptimisticUpdateFailure(dynamic error) async {
    // Revert to previous state or show error
    // This should be implemented by each specific BLoC
  }

  /// Silent refresh in background without loading indicators
  Future<void> handleSilentRefresh() async {
    try {
      await performSilentRefresh();
    } catch (e) {
      if (kDebugMode) {
        print('⚠️ Silent refresh failed for $screenName: $e');
      }
    }
  }

  /// Perform silent refresh - implemented by each BLoC
  Future<void> performSilentRefresh();

  /// Get progress stream for specific priority level
  Stream<dynamic> getProgressStream(String priority) {
    return _progressStreams[priority]?.stream ?? const Stream.empty();
  }

  /// Check if operation is currently ongoing
  bool isOperationOngoing(String operationName) {
    return _ongoingOperations.contains(operationName);
  }

  /// Get current optimization statistics
  String getOptimizationStats() {
    final orchestratorStats = _orchestrator.getOptimizationStats();
    return 'Screen: $screenName, '
        'Ongoing Ops: ${_ongoingOperations.length}, '
        'Progress Streams: ${_progressStreams.length}, '
        'Orchestrator: $orchestratorStats';
  }

  @override
  Future<void> close() async {
    // Cleanup resources
    _backgroundRefreshTimer?.cancel();

    // Unregister from background refresh
    _orchestrator.unregisterFromBackgroundRefresh(screenName);

    // Close progress streams
    for (final stream in _progressStreams.values) {
      await stream.close();
    }
    _progressStreams.clear();

    // Clear ongoing operations
    _ongoingOperations.clear();

    await super.close();
  }
}

/// Optimized dashboard BLoC implementation
class OptimizedDashboardBloc
    extends OptimizedBloc<DashboardEvent, DashboardState> {
  final OptimizedDashboardService _dashboardService;

  OptimizedDashboardBloc(this._dashboardService)
      : super(
          screenName: 'dashboard',
          initialState: const DashboardState(),
        ) {
    on<LoadDashboardEvent>(_onLoadDashboard);
    on<RefreshDashboardEvent>(_onRefreshDashboard);
    on<LoadDashboardSectionEvent>(_onLoadDashboardSection);
  }

  Future<void> _onLoadDashboard(
    LoadDashboardEvent event,
    Emitter<DashboardState> emit,
  ) async {
    if (!event.silent) {
      emit(state.copyWith(isLoading: true, error: null));
    }

    try {
      // Progressive loading - load critical data first
      final progressiveData = await executeProgressiveLoading({
        'primary_user_stats': () => _loadUserStats(),
        'primary_recent_activities': () => _loadRecentActivities(),
        'secondary_analytics': () => _loadAnalytics(),
        'secondary_recommendations': () => _loadRecommendations(),
        'tertiary_insights': () => _loadInsights(),
        'tertiary_achievements': () => _loadAchievements(),
      });

      // Emit state with available data
      emit(state.copyWith(
        isLoading: false,
        isRefreshing: false,
        dashboardData: DashboardData.fromMap(progressiveData),
        lastUpdated: DateTime.now(),
        isFromCache: false,
        error: null,
      ));
    } catch (e) {
      emit(state.copyWith(
        isLoading: false,
        isRefreshing: false,
        error: e.toString(),
      ));
    }
  }

  Future<void> _onRefreshDashboard(
    RefreshDashboardEvent event,
    Emitter<DashboardState> emit,
  ) async {
    if (!event.silent) {
      emit(state.copyWith(isRefreshing: true, error: null));
    }

    try {
      final data = await executeOptimizedCall(
        'refresh_dashboard',
        () => _dashboardService.loadDashboardData(forceRefresh: true),
        enableCaching: true,
        cacheKey: 'dashboard_refresh_${DateTime.now().millisecondsSinceEpoch}',
      );

      emit(state.copyWith(
        isLoading: false,
        isRefreshing: false,
        dashboardData: data,
        lastUpdated: DateTime.now(),
        isFromCache: false,
        error: null,
      ));
    } catch (e) {
      emit(state.copyWith(
        isLoading: false,
        isRefreshing: false,
        error: e.toString(),
      ));
    }
  }

  Future<void> _onLoadDashboardSection(
    LoadDashboardSectionEvent event,
    Emitter<DashboardState> emit,
  ) async {
    try {
      // Load specific section without affecting overall loading state
      final sectionData = await executeOptimizedCall(
        'load_section_${event.sectionName}',
        () => _loadDashboardSection(event.sectionName),
        enableCaching: true,
        cacheKey: 'dashboard_section_${event.sectionName}',
      );

      // Update state with new section data
      final updatedData = state.dashboardData?.updateSection(
        event.sectionName,
        sectionData,
      );

      emit(state.copyWith(dashboardData: updatedData));
    } catch (e) {
      if (kDebugMode) {
        print('⚠️ Failed to load dashboard section ${event.sectionName}: $e');
      }
    }
  }

  // Helper methods for progressive loading
  Future<Map<String, dynamic>> _loadUserStats() async {
    return executeOptimizedCall(
      'user_stats',
      () => _dashboardService.getUserStats(),
      enableCaching: true,
      cacheKey: 'dashboard_user_stats',
    );
  }

  Future<List<dynamic>> _loadRecentActivities() async {
    return executeOptimizedCall(
      'recent_activities',
      () => _dashboardService.getRecentActivities(),
      enableCaching: true,
      cacheKey: 'dashboard_recent_activities',
    );
  }

  Future<Map<String, dynamic>> _loadAnalytics() async {
    return executeOptimizedCall(
      'analytics',
      () => _dashboardService.getAnalyticsData(),
      enableCaching: true,
      cacheKey: 'dashboard_analytics',
    );
  }

  Future<List<dynamic>> _loadRecommendations() async {
    return executeOptimizedCall(
      'recommendations',
      () => _dashboardService.getRecommendations(),
      enableCaching: true,
      cacheKey: 'dashboard_recommendations',
    );
  }

  Future<Map<String, dynamic>> _loadInsights() async {
    return executeOptimizedCall(
      'insights',
      () => _dashboardService.getInsights(),
      enableCaching: true,
      cacheKey: 'dashboard_insights',
    );
  }

  Future<List<dynamic>> _loadAchievements() async {
    return executeOptimizedCall(
      'achievements',
      () => _dashboardService.getAchievements(),
      enableCaching: true,
      cacheKey: 'dashboard_achievements',
    );
  }

  Future<dynamic> _loadDashboardSection(String sectionName) async {
    // Load specific dashboard section
    switch (sectionName) {
      case 'stats':
        return _loadUserStats();
      case 'activities':
        return _loadRecentActivities();
      case 'analytics':
        return _loadAnalytics();
      case 'recommendations':
        return _loadRecommendations();
      case 'insights':
        return _loadInsights();
      case 'achievements':
        return _loadAchievements();
      default:
        throw Exception('Unknown section: $sectionName');
    }
  }

  @override
  Future<void> performSilentRefresh() async {
    add(const RefreshDashboardEvent(silent: true));
  }
}

// Dashboard events
abstract class DashboardEvent extends OptimizedBlocEvent {
  const DashboardEvent({
    super.forceRefresh,
    super.silent,
    super.metadata,
  });
}

class LoadDashboardEvent extends DashboardEvent {
  const LoadDashboardEvent({
    super.forceRefresh,
    super.silent,
    super.metadata,
  });
}

class RefreshDashboardEvent extends DashboardEvent {
  const RefreshDashboardEvent({
    super.forceRefresh,
    super.silent,
    super.metadata,
  });
}

class LoadDashboardSectionEvent extends DashboardEvent {
  final String sectionName;

  const LoadDashboardSectionEvent(
    this.sectionName, {
    super.forceRefresh,
    super.silent,
    super.metadata,
  });
}

// Dashboard state
class DashboardState extends OptimizedBlocState {
  final DashboardData? dashboardData;

  const DashboardState({
    this.dashboardData,
    super.isLoading,
    super.isRefreshing,
    super.error,
    super.lastUpdated,
    super.isFromCache,
  });

  DashboardState copyWith({
    DashboardData? dashboardData,
    bool? isLoading,
    bool? isRefreshing,
    String? error,
    DateTime? lastUpdated,
    bool? isFromCache,
  }) {
    return DashboardState(
      dashboardData: dashboardData ?? this.dashboardData,
      isLoading: isLoading ?? this.isLoading,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      error: error,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      isFromCache: isFromCache ?? this.isFromCache,
    );
  }
}

// Dashboard data model
class DashboardData {
  final Map<String, dynamic> userStats;
  final List<dynamic> recentActivities;
  final Map<String, dynamic> analytics;
  final List<dynamic> recommendations;
  final Map<String, dynamic> insights;
  final List<dynamic> achievements;

  const DashboardData({
    required this.userStats,
    required this.recentActivities,
    required this.analytics,
    required this.recommendations,
    required this.insights,
    required this.achievements,
  });

  factory DashboardData.fromMap(Map<String, dynamic> data) {
    return DashboardData(
      userStats: data['primary_user_stats'] ?? {},
      recentActivities: data['primary_recent_activities'] ?? [],
      analytics: data['secondary_analytics'] ?? {},
      recommendations: data['secondary_recommendations'] ?? [],
      insights: data['tertiary_insights'] ?? {},
      achievements: data['tertiary_achievements'] ?? [],
    );
  }

  DashboardData updateSection(String sectionName, dynamic sectionData) {
    switch (sectionName) {
      case 'stats':
        return copyWith(userStats: sectionData);
      case 'activities':
        return copyWith(recentActivities: sectionData);
      case 'analytics':
        return copyWith(analytics: sectionData);
      case 'recommendations':
        return copyWith(recommendations: sectionData);
      case 'insights':
        return copyWith(insights: sectionData);
      case 'achievements':
        return copyWith(achievements: sectionData);
      default:
        return this;
    }
  }

  DashboardData copyWith({
    Map<String, dynamic>? userStats,
    List<dynamic>? recentActivities,
    Map<String, dynamic>? analytics,
    List<dynamic>? recommendations,
    Map<String, dynamic>? insights,
    List<dynamic>? achievements,
  }) {
    return DashboardData(
      userStats: userStats ?? this.userStats,
      recentActivities: recentActivities ?? this.recentActivities,
      analytics: analytics ?? this.analytics,
      recommendations: recommendations ?? this.recommendations,
      insights: insights ?? this.insights,
      achievements: achievements ?? this.achievements,
    );
  }
}
