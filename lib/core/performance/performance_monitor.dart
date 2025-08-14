import 'dart:math' as math;
import 'package:flutter/foundation.dart';

/// API performance statistics
class ApiPerformanceStats {
  final String endpoint;
  final Duration averageResponseTime;
  final Duration p95ResponseTime;
  final double errorRate;
  final int totalRequests;
  final int successfulRequests;
  final int failedRequests;

  const ApiPerformanceStats({
    required this.endpoint,
    required this.averageResponseTime,
    required this.p95ResponseTime,
    required this.errorRate,
    required this.totalRequests,
    required this.successfulRequests,
    required this.failedRequests,
  });

  factory ApiPerformanceStats.empty() {
    return const ApiPerformanceStats(
      endpoint: '',
      averageResponseTime: Duration.zero,
      p95ResponseTime: Duration.zero,
      errorRate: 0.0,
      totalRequests: 0,
      successfulRequests: 0,
      failedRequests: 0,
    );
  }

  @override
  String toString() {
    return 'ApiPerformanceStats('
        'endpoint: $endpoint, '
        'avgTime: ${averageResponseTime.inMilliseconds}ms, '
        'p95: ${p95ResponseTime.inMilliseconds}ms, '
        'errorRate: ${(errorRate * 100).toStringAsFixed(1)}%, '
        'requests: $totalRequests)';
  }
}

/// Screen performance metrics
class ScreenPerformanceMetrics {
  final String screenName;
  final Duration loadTime;
  final List<Duration> apiCallTimes;
  final int rerenderCount;
  final DateTime timestamp;

  const ScreenPerformanceMetrics({
    required this.screenName,
    required this.loadTime,
    required this.apiCallTimes,
    required this.rerenderCount,
    required this.timestamp,
  });

  Duration get totalApiTime => apiCallTimes.fold(
        Duration.zero,
        (total, time) => total + time,
      );

  bool get isSlowLoad => loadTime.inSeconds > 3;
  bool get hasSlowApis => apiCallTimes.any((time) => time.inSeconds > 2);
}

/// Performance monitoring and analytics
class PerformanceMonitor {
  static final PerformanceMonitor _instance = PerformanceMonitor._internal();
  factory PerformanceMonitor() => _instance;
  PerformanceMonitor._internal();

  // API performance tracking
  final Map<String, List<Duration>> _responseTimes = {};
  final Map<String, int> _errorCounts = {};
  final Map<String, int> _successCounts = {};

  // Screen performance tracking
  final Map<String, List<ScreenPerformanceMetrics>> _screenMetrics = {};

  // Performance thresholds
  static const Duration _slowApiThreshold = Duration(seconds: 5);
  static const Duration _slowScreenThreshold = Duration(seconds: 3);
  static const int _maxStoredMeasurements = 100;

  /// Track API request performance
  void trackRequest(String endpoint, Duration responseTime, bool success) {
    // Clean endpoint for consistent tracking
    final cleanEndpoint = _cleanEndpoint(endpoint);

    // Track response times
    _responseTimes.putIfAbsent(cleanEndpoint, () => []).add(responseTime);

    // Keep only recent measurements
    if (_responseTimes[cleanEndpoint]!.length > _maxStoredMeasurements) {
      _responseTimes[cleanEndpoint]!.removeAt(0);
    }

    // Track success/error counts
    if (success) {
      _successCounts[cleanEndpoint] = (_successCounts[cleanEndpoint] ?? 0) + 1;
    } else {
      _errorCounts[cleanEndpoint] = (_errorCounts[cleanEndpoint] ?? 0) + 1;
    }

    // Log slow requests
    if (responseTime > _slowApiThreshold) {
      _logSlowRequest(cleanEndpoint, responseTime);
    }

    // Check for performance degradation
    _checkPerformanceDegradation(cleanEndpoint);
  }

  /// Track screen load performance
  void trackScreenLoad(
    String screenName,
    Duration loadTime, {
    List<Duration> apiCallTimes = const [],
    int rerenderCount = 0,
  }) {
    final metrics = ScreenPerformanceMetrics(
      screenName: screenName,
      loadTime: loadTime,
      apiCallTimes: List.from(apiCallTimes),
      rerenderCount: rerenderCount,
      timestamp: DateTime.now(),
    );

    _screenMetrics.putIfAbsent(screenName, () => []).add(metrics);

    // Keep only recent measurements
    if (_screenMetrics[screenName]!.length > _maxStoredMeasurements) {
      _screenMetrics[screenName]!.removeAt(0);
    }

    // Log slow screen loads
    if (loadTime > _slowScreenThreshold) {
      _logSlowScreenLoad(screenName, loadTime);
    }

    if (kDebugMode) {
      print(
          '📊 Screen Performance: $screenName loaded in ${loadTime.inMilliseconds}ms');
    }
  }

  /// Track API call from specific UI context
  void trackAPICallFromUI(
      String screen, String endpoint, Duration responseTime) {
    final contextKey = '${screen}_$endpoint';
    trackRequest(contextKey, responseTime, true);

    if (kDebugMode) {
      print(
          '📱 UI API Call: $screen -> $endpoint (${responseTime.inMilliseconds}ms)');
    }
  }

  /// Get performance statistics for an endpoint
  ApiPerformanceStats getApiStats(String endpoint) {
    final cleanEndpoint = _cleanEndpoint(endpoint);
    final times = _responseTimes[cleanEndpoint] ?? [];
    final errors = _errorCounts[cleanEndpoint] ?? 0;
    final successes = _successCounts[cleanEndpoint] ?? 0;
    final total = errors + successes;

    if (times.isEmpty) return ApiPerformanceStats.empty();

    final averageMs =
        times.map((t) => t.inMilliseconds).reduce((a, b) => a + b) /
            times.length;

    final p95 = _calculatePercentile(times, 0.95);
    final errorRate = total > 0 ? errors / total : 0.0;

    return ApiPerformanceStats(
      endpoint: cleanEndpoint,
      averageResponseTime: Duration(milliseconds: averageMs.round()),
      p95ResponseTime: p95,
      errorRate: errorRate,
      totalRequests: total,
      successfulRequests: successes,
      failedRequests: errors,
    );
  }

  /// Get screen performance metrics
  List<ScreenPerformanceMetrics> getScreenMetrics(String screenName) {
    return _screenMetrics[screenName] ?? [];
  }

  /// Get overall performance summary
  PerformanceSummary getPerformanceSummary() {
    final allEndpoints = {
      ..._responseTimes.keys,
      ..._errorCounts.keys,
      ..._successCounts.keys
    };
    final apiStats = allEndpoints.map(getApiStats).toList();

    final slowApis = apiStats
        .where((stats) => stats.averageResponseTime > _slowApiThreshold)
        .toList();

    final highErrorApis = apiStats
        .where((stats) => stats.errorRate > 0.1) // 10% error rate
        .toList();

    final slowScreens = _screenMetrics.entries
        .where((entry) => entry.value.any((metric) => metric.isSlowLoad))
        .map((entry) => entry.key)
        .toList();

    return PerformanceSummary(
      totalApiEndpoints: allEndpoints.length,
      slowApis: slowApis,
      highErrorApis: highErrorApis,
      slowScreens: slowScreens,
      averageScreenLoadTime: _calculateAverageScreenLoadTime(),
    );
  }

  /// Reset all performance data
  void reset() {
    _responseTimes.clear();
    _errorCounts.clear();
    _successCounts.clear();
    _screenMetrics.clear();
  }

  /// Export performance data for analysis
  Map<String, dynamic> exportData() {
    return {
      'responseTimes': _responseTimes.map(
        (key, value) => MapEntry(
          key,
          value.map((duration) => duration.inMilliseconds).toList(),
        ),
      ),
      'errorCounts': _errorCounts,
      'successCounts': _successCounts,
      'screenMetrics': _screenMetrics.map(
        (key, value) => MapEntry(
          key,
          value
              .map((metric) => {
                    'loadTime': metric.loadTime.inMilliseconds,
                    'apiCallTimes': metric.apiCallTimes
                        .map((t) => t.inMilliseconds)
                        .toList(),
                    'rerenderCount': metric.rerenderCount,
                    'timestamp': metric.timestamp.toIso8601String(),
                  })
              .toList(),
        ),
      ),
      'timestamp': DateTime.now().toIso8601String(),
    };
  }

  // Private methods

  String _cleanEndpoint(String endpoint) {
    // Remove query parameters and normalize
    return endpoint.split('?').first.toLowerCase();
  }

  Duration _calculatePercentile(List<Duration> times, double percentile) {
    if (times.isEmpty) return Duration.zero;

    final sorted = List<Duration>.from(times)..sort();
    final index = (sorted.length * percentile).floor();

    return sorted[math.min(index, sorted.length - 1)];
  }

  void _logSlowRequest(String endpoint, Duration responseTime) {
    if (kDebugMode) {
      print(
          '🐌 Slow API Request: $endpoint (${responseTime.inMilliseconds}ms)');
    }

    // In production, you might want to send this to analytics
    // AnalyticsService.logEvent('slow_api_request', {
    //   'endpoint': endpoint,
    //   'response_time_ms': responseTime.inMilliseconds,
    // });
  }

  void _logSlowScreenLoad(String screenName, Duration loadTime) {
    if (kDebugMode) {
      print('🐌 Slow Screen Load: $screenName (${loadTime.inSeconds}s)');
    }

    // In production, you might want to send this to analytics
    // AnalyticsService.logEvent('slow_screen_load', {
    //   'screen_name': screenName,
    //   'load_time_ms': loadTime.inMilliseconds,
    // });
  }

  void _checkPerformanceDegradation(String endpoint) {
    final times = _responseTimes[endpoint];
    if (times == null || times.length < 10) return;

    // Check if recent requests are significantly slower
    final recentTimes = times.takeLast(5);
    final olderTimes = times.take(times.length - 5);

    final recentAvg =
        recentTimes.map((t) => t.inMilliseconds).reduce((a, b) => a + b) /
            recentTimes.length;

    final olderAvg =
        olderTimes.map((t) => t.inMilliseconds).reduce((a, b) => a + b) /
            olderTimes.length;

    // If recent average is 50% slower than older average
    if (recentAvg > olderAvg * 1.5) {
      if (kDebugMode) {
        print('⚠️ Performance degradation detected for $endpoint');
        print('   Recent avg: ${recentAvg.toStringAsFixed(1)}ms');
        print('   Older avg: ${olderAvg.toStringAsFixed(1)}ms');
      }
    }
  }

  Duration _calculateAverageScreenLoadTime() {
    final allLoadTimes = _screenMetrics.values
        .expand((metrics) => metrics)
        .map((metric) => metric.loadTime)
        .toList();

    if (allLoadTimes.isEmpty) return Duration.zero;

    final totalMs =
        allLoadTimes.map((t) => t.inMilliseconds).reduce((a, b) => a + b);

    return Duration(milliseconds: (totalMs / allLoadTimes.length).round());
  }
}

/// Overall performance summary
class PerformanceSummary {
  final int totalApiEndpoints;
  final List<ApiPerformanceStats> slowApis;
  final List<ApiPerformanceStats> highErrorApis;
  final List<String> slowScreens;
  final Duration averageScreenLoadTime;

  const PerformanceSummary({
    required this.totalApiEndpoints,
    required this.slowApis,
    required this.highErrorApis,
    required this.slowScreens,
    required this.averageScreenLoadTime,
  });

  bool get hasPerformanceIssues =>
      slowApis.isNotEmpty || highErrorApis.isNotEmpty || slowScreens.isNotEmpty;

  @override
  String toString() {
    return 'PerformanceSummary('
        'endpoints: $totalApiEndpoints, '
        'slowApis: ${slowApis.length}, '
        'errorApis: ${highErrorApis.length}, '
        'slowScreens: ${slowScreens.length}, '
        'avgScreenLoad: ${averageScreenLoadTime.inMilliseconds}ms)';
  }
}

/// Utility extension for list operations
extension ListExtensions<T> on List<T> {
  List<T> takeLast(int count) {
    if (count >= length) return this;
    return skip(length - count).toList();
  }
}

/// UX metrics tracker for specific user experience events
class UXMetricsTracker {
  static final PerformanceMonitor _performanceMonitor = PerformanceMonitor();

  /// Track screen load start
  static void trackScreenLoadStart(String screenName) {
    if (kDebugMode) {
      print('📱 Screen Load Started: $screenName');
    }
  }

  /// Track complete screen load time
  static void trackScreenLoadTime(String screenName, Duration loadTime) {
    _performanceMonitor.trackScreenLoad(screenName, loadTime);

    // Alert for very slow screen loads
    if (loadTime.inSeconds > 5) {
      if (kDebugMode) {
        print('🚨 Very slow screen load: $screenName (${loadTime.inSeconds}s)');
      }
    }
  }

  /// Track API call from UI context
  static void trackAPICallFromUI(
      String screen, String endpoint, Duration responseTime) {
    _performanceMonitor.trackAPICallFromUI(screen, endpoint, responseTime);
  }

  /// Track user interaction response time
  static void trackInteractionTime(String interaction, Duration responseTime) {
    if (kDebugMode) {
      print('👆 Interaction: $interaction (${responseTime.inMilliseconds}ms)');
    }

    // Alert for slow interactions
    if (responseTime.inMilliseconds > 500) {
      if (kDebugMode) {
        print('🐌 Slow interaction: $interaction');
      }
    }
  }

  /// Track scroll performance
  static void trackScrollPerformance(String screen, int frameDrops) {
    if (kDebugMode && frameDrops > 0) {
      print('📜 Scroll performance issue in $screen: $frameDrops frame drops');
    }
  }
}
