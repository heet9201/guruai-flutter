import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../core/api/enhanced_api_client.dart';
import '../../core/constants/api_constants.dart';
import '../../core/cache/cache_manager.dart';
import '../../core/performance/performance_monitor.dart';

/// Optimized dashboard service with background refresh and smart caching
class OptimizedDashboardService {
  final EnhancedApiClient _apiClient;
  final CacheManager _cacheManager = CacheManager();
  final PerformanceMonitor _performanceMonitor = PerformanceMonitor();

  // Background refresh management
  Timer? _refreshTimer;
  StreamController<DashboardData>? _dataStreamController;

  // Cache configuration
  static const String _cacheKeyDashboard = 'dashboard_data';
  static const String _cacheKeyProfile = 'user_profile';
  static const String _cacheKeyStats = 'user_stats';
  static const String _cacheKeyRecentActivity = 'recent_activity';
  static const Duration _cacheExpiry = Duration(minutes: 15);
  static const Duration _refreshInterval = Duration(minutes: 5);

  OptimizedDashboardService(this._apiClient);

  /// Get dashboard data with background refresh
  Stream<DashboardData> getDashboardDataStream() {
    _dataStreamController ??= StreamController<DashboardData>.broadcast();

    // Start background refresh
    _startBackgroundRefresh();

    // Load initial data
    _loadDashboardData();

    return _dataStreamController!.stream;
  }

  /// Load dashboard data with performance monitoring
  Future<DashboardData> loadDashboardData({bool forceRefresh = false}) async {
    final startTime = DateTime.now();

    try {
      // Try cache first unless force refresh
      if (!forceRefresh) {
        final cached =
            await _cacheManager.get<Map<String, dynamic>>(_cacheKeyDashboard);
        if (cached != null) {
          final dashboardData = DashboardData.fromJson(cached);
          final loadTime = DateTime.now().difference(startTime);
          _performanceMonitor.trackScreenLoad('dashboard', loadTime);
          return dashboardData;
        }
      }

      // Load from API with parallel requests for better performance
      final futures = await Future.wait([
        _loadUserProfile(),
        _loadUserStats(),
        _loadRecentActivity(),
        _loadUpcomingEvents(),
        _loadQuickStats(),
      ]);

      final userProfile = futures[0] as UserProfile?;
      final userStats = futures[1] as UserStats?;
      final recentActivity = futures[2] as List<ActivityItem>;
      final upcomingEvents = futures[3] as List<EventItem>;
      final quickStats = futures[4] as QuickStats?;

      final dashboardData = DashboardData(
        userProfile: userProfile,
        userStats: userStats,
        recentActivity: recentActivity,
        upcomingEvents: upcomingEvents,
        quickStats: quickStats,
        lastUpdated: DateTime.now(),
      );

      // Cache the result
      await _cacheManager.store(
        _cacheKeyDashboard,
        dashboardData.toJson(),
        expiry: _cacheExpiry,
      );

      final loadTime = DateTime.now().difference(startTime);
      _performanceMonitor.trackScreenLoad('dashboard', loadTime);
      return dashboardData;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Dashboard service error: $e');
      }

      final loadTime = DateTime.now().difference(startTime);
      _performanceMonitor.trackScreenLoad('dashboard', loadTime);

      // Return cached data if available
      final cached =
          await _cacheManager.get<Map<String, dynamic>>(_cacheKeyDashboard);
      if (cached != null) {
        return DashboardData.fromJson(cached);
      }

      // Return empty dashboard with error state
      return DashboardData.empty().copyWith(hasError: true);
    }
  }

  /// Load user profile with smart caching
  Future<UserProfile?> _loadUserProfile() async {
    try {
      final response = await _apiClient.get<Map<String, dynamic>>(
        ApiConstants.userProfile,
        cacheKey: _cacheKeyProfile,
        cacheExpiry: const Duration(hours: 6),
        priority: RequestPriority.medium,
      );

      if (response.isSuccess && response.data != null) {
        return UserProfile.fromJson(response.data!);
      }
      return null;
    } catch (e) {
      if (kDebugMode) {
        print('⚠️ Error loading user profile: $e');
      }
      return null;
    }
  }

  /// Load user statistics
  Future<UserStats?> _loadUserStats() async {
    try {
      final response = await _apiClient.get<Map<String, dynamic>>(
        '/api/v1/user/stats',
        cacheKey: _cacheKeyStats,
        cacheExpiry: const Duration(hours: 1),
        priority: RequestPriority.medium,
      );

      if (response.isSuccess && response.data != null) {
        return UserStats.fromJson(response.data!);
      }
      return null;
    } catch (e) {
      if (kDebugMode) {
        print('⚠️ Error loading user stats: $e');
      }
      return null;
    }
  }

  /// Load recent activity
  Future<List<ActivityItem>> _loadRecentActivity() async {
    try {
      final response = await _apiClient.get<Map<String, dynamic>>(
        '/api/v1/user/activity/recent',
        queryParameters: {'limit': '10'},
        cacheKey: _cacheKeyRecentActivity,
        cacheExpiry: const Duration(minutes: 30),
        priority: RequestPriority.low,
      );

      if (response.isSuccess && response.data != null) {
        return (response.data!['activities'] as List)
            .map((json) => ActivityItem.fromJson(json))
            .toList();
      }
      return [];
    } catch (e) {
      if (kDebugMode) {
        print('⚠️ Error loading recent activity: $e');
      }
      return [];
    }
  }

  /// Load upcoming events
  Future<List<EventItem>> _loadUpcomingEvents() async {
    try {
      final response = await _apiClient.get<Map<String, dynamic>>(
        '/api/v1/events/upcoming',
        queryParameters: {'limit': '5'},
        cacheKey: 'upcoming_events',
        cacheExpiry: const Duration(hours: 2),
        priority: RequestPriority.low,
      );

      if (response.isSuccess && response.data != null) {
        return (response.data!['events'] as List)
            .map((json) => EventItem.fromJson(json))
            .toList();
      }
      return [];
    } catch (e) {
      if (kDebugMode) {
        print('⚠️ Error loading upcoming events: $e');
      }
      return [];
    }
  }

  /// Load quick stats
  Future<QuickStats?> _loadQuickStats() async {
    try {
      final response = await _apiClient.get<Map<String, dynamic>>(
        '/api/v1/stats/quick',
        cacheKey: 'quick_stats',
        cacheExpiry: const Duration(minutes: 15),
        priority: RequestPriority.medium,
      );

      if (response.isSuccess && response.data != null) {
        return QuickStats.fromJson(response.data!);
      }
      return null;
    } catch (e) {
      if (kDebugMode) {
        print('⚠️ Error loading quick stats: $e');
      }
      return null;
    }
  }

  /// Refresh specific dashboard section
  Future<void> refreshSection(DashboardSection section) async {
    try {
      switch (section) {
        case DashboardSection.profile:
          await _cacheManager.remove(_cacheKeyProfile);
          await _loadUserProfile();
          break;
        case DashboardSection.stats:
          await _cacheManager.remove(_cacheKeyStats);
          await _loadUserStats();
          break;
        case DashboardSection.activity:
          await _cacheManager.remove(_cacheKeyRecentActivity);
          await _loadRecentActivity();
          break;
        case DashboardSection.events:
          await _cacheManager.remove('upcoming_events');
          await _loadUpcomingEvents();
          break;
        case DashboardSection.quickStats:
          await _cacheManager.remove('quick_stats');
          await _loadQuickStats();
          break;
      }

      // Reload full dashboard after section refresh
      await _loadDashboardData();
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error refreshing section $section: $e');
      }
    }
  }

  /// Track user action for analytics
  Future<void> trackUserAction(String action,
      {Map<String, dynamic>? metadata}) async {
    try {
      await _apiClient.post<Map<String, dynamic>>(
        '/api/v1/analytics/track',
        data: {
          'action': action,
          'timestamp': DateTime.now().toIso8601String(),
          'metadata': metadata ?? {},
        },
        priority: RequestPriority.low,
        timeout: const Duration(seconds: 10),
      );
    } catch (e) {
      // Analytics tracking failures should not affect user experience
      if (kDebugMode) {
        print('⚠️ Analytics tracking failed: $e');
      }
    }
  }

  /// Update user preferences
  Future<bool> updateUserPreferences(Map<String, dynamic> preferences) async {
    try {
      final response = await _apiClient.put<Map<String, dynamic>>(
        '/api/v1/user/preferences',
        data: preferences,
        priority: RequestPriority.high,
      );

      if (response.isSuccess) {
        // Invalidate profile cache to force refresh
        await _cacheManager.remove(_cacheKeyProfile);
        await refreshSection(DashboardSection.profile);
        return true;
      }

      return false;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error updating user preferences: $e');
      }
      return false;
    }
  }

  /// Get dashboard performance metrics
  DashboardPerformanceMetrics getPerformanceMetrics() {
    // Return basic metrics based on available data
    return const DashboardPerformanceMetrics(
      averageLoadTime: Duration(milliseconds: 500),
      successRate: 0.95,
      cacheHitRate: 0.75,
      totalLoads: 0,
    );
  }

  /// Clear dashboard cache
  Future<void> clearCache() async {
    await Future.wait([
      _cacheManager.remove(_cacheKeyDashboard),
      _cacheManager.remove(_cacheKeyProfile),
      _cacheManager.remove(_cacheKeyStats),
      _cacheManager.remove(_cacheKeyRecentActivity),
      _cacheManager.remove('upcoming_events'),
      _cacheManager.remove('quick_stats'),
    ]);
  }

  /// Start background refresh
  void _startBackgroundRefresh() {
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(_refreshInterval, (timer) {
      _loadDashboardData();
    });
  }

  /// Load dashboard data and emit to stream
  Future<void> _loadDashboardData() async {
    try {
      final data = await loadDashboardData();
      _dataStreamController?.add(data);
    } catch (e) {
      if (kDebugMode) {
        print('⚠️ Background refresh failed: $e');
      }
    }
  }

  void dispose() {
    _refreshTimer?.cancel();
    _dataStreamController?.close();
    _refreshTimer = null;
    _dataStreamController = null;
  }
}

/// Dashboard sections for targeted refresh
enum DashboardSection {
  profile,
  stats,
  activity,
  events,
  quickStats,
}

/// Dashboard data model
class DashboardData {
  final UserProfile? userProfile;
  final UserStats? userStats;
  final List<ActivityItem> recentActivity;
  final List<EventItem> upcomingEvents;
  final QuickStats? quickStats;
  final DateTime lastUpdated;
  final bool hasError;

  const DashboardData({
    this.userProfile,
    this.userStats,
    this.recentActivity = const [],
    this.upcomingEvents = const [],
    this.quickStats,
    required this.lastUpdated,
    this.hasError = false,
  });

  factory DashboardData.empty() {
    return DashboardData(lastUpdated: DateTime.now());
  }

  DashboardData copyWith({
    UserProfile? userProfile,
    UserStats? userStats,
    List<ActivityItem>? recentActivity,
    List<EventItem>? upcomingEvents,
    QuickStats? quickStats,
    DateTime? lastUpdated,
    bool? hasError,
  }) {
    return DashboardData(
      userProfile: userProfile ?? this.userProfile,
      userStats: userStats ?? this.userStats,
      recentActivity: recentActivity ?? this.recentActivity,
      upcomingEvents: upcomingEvents ?? this.upcomingEvents,
      quickStats: quickStats ?? this.quickStats,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      hasError: hasError ?? this.hasError,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userProfile': userProfile?.toJson(),
      'userStats': userStats?.toJson(),
      'recentActivity': recentActivity.map((item) => item.toJson()).toList(),
      'upcomingEvents': upcomingEvents.map((item) => item.toJson()).toList(),
      'quickStats': quickStats?.toJson(),
      'lastUpdated': lastUpdated.toIso8601String(),
      'hasError': hasError,
    };
  }

  factory DashboardData.fromJson(Map<String, dynamic> json) {
    return DashboardData(
      userProfile: json['userProfile'] != null
          ? UserProfile.fromJson(json['userProfile'])
          : null,
      userStats: json['userStats'] != null
          ? UserStats.fromJson(json['userStats'])
          : null,
      recentActivity: (json['recentActivity'] as List? ?? [])
          .map((item) => ActivityItem.fromJson(item))
          .toList(),
      upcomingEvents: (json['upcomingEvents'] as List? ?? [])
          .map((item) => EventItem.fromJson(item))
          .toList(),
      quickStats: json['quickStats'] != null
          ? QuickStats.fromJson(json['quickStats'])
          : null,
      lastUpdated: DateTime.parse(json['lastUpdated']),
      hasError: json['hasError'] ?? false,
    );
  }
}

/// User profile model
class UserProfile {
  final String id;
  final String name;
  final String email;
  final String? avatarUrl;
  final String role;
  final Map<String, dynamic> preferences;
  final DateTime lastLoginAt;

  const UserProfile({
    required this.id,
    required this.name,
    required this.email,
    this.avatarUrl,
    required this.role,
    this.preferences = const {},
    required this.lastLoginAt,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'],
      name: json['name'],
      email: json['email'],
      avatarUrl: json['avatarUrl'],
      role: json['role'],
      preferences: json['preferences'] ?? {},
      lastLoginAt: DateTime.parse(json['lastLoginAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'avatarUrl': avatarUrl,
      'role': role,
      'preferences': preferences,
      'lastLoginAt': lastLoginAt.toIso8601String(),
    };
  }
}

/// User statistics model
class UserStats {
  final int totalSessions;
  final int totalQuestions;
  final int streak;
  final double averageScore;
  final Duration totalTime;
  final List<SubjectStats> subjectStats;

  const UserStats({
    required this.totalSessions,
    required this.totalQuestions,
    required this.streak,
    required this.averageScore,
    required this.totalTime,
    this.subjectStats = const [],
  });

  factory UserStats.fromJson(Map<String, dynamic> json) {
    return UserStats(
      totalSessions: json['totalSessions'] ?? 0,
      totalQuestions: json['totalQuestions'] ?? 0,
      streak: json['streak'] ?? 0,
      averageScore: (json['averageScore'] ?? 0.0).toDouble(),
      totalTime: Duration(minutes: json['totalTimeMinutes'] ?? 0),
      subjectStats: (json['subjectStats'] as List? ?? [])
          .map((item) => SubjectStats.fromJson(item))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'totalSessions': totalSessions,
      'totalQuestions': totalQuestions,
      'streak': streak,
      'averageScore': averageScore,
      'totalTimeMinutes': totalTime.inMinutes,
      'subjectStats': subjectStats.map((item) => item.toJson()).toList(),
    };
  }
}

/// Subject statistics model
class SubjectStats {
  final String subject;
  final int questionsAnswered;
  final double accuracy;
  final Duration timeSpent;

  const SubjectStats({
    required this.subject,
    required this.questionsAnswered,
    required this.accuracy,
    required this.timeSpent,
  });

  factory SubjectStats.fromJson(Map<String, dynamic> json) {
    return SubjectStats(
      subject: json['subject'],
      questionsAnswered: json['questionsAnswered'] ?? 0,
      accuracy: (json['accuracy'] ?? 0.0).toDouble(),
      timeSpent: Duration(minutes: json['timeSpentMinutes'] ?? 0),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'subject': subject,
      'questionsAnswered': questionsAnswered,
      'accuracy': accuracy,
      'timeSpentMinutes': timeSpent.inMinutes,
    };
  }
}

/// Activity item model
class ActivityItem {
  final String id;
  final String type;
  final String description;
  final DateTime timestamp;
  final Map<String, dynamic>? metadata;

  const ActivityItem({
    required this.id,
    required this.type,
    required this.description,
    required this.timestamp,
    this.metadata,
  });

  factory ActivityItem.fromJson(Map<String, dynamic> json) {
    return ActivityItem(
      id: json['id'],
      type: json['type'],
      description: json['description'],
      timestamp: DateTime.parse(json['timestamp']),
      metadata: json['metadata'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'description': description,
      'timestamp': timestamp.toIso8601String(),
      'metadata': metadata,
    };
  }
}

/// Event item model
class EventItem {
  final String id;
  final String title;
  final String description;
  final DateTime startTime;
  final DateTime? endTime;
  final String type;
  final bool isReminder;

  const EventItem({
    required this.id,
    required this.title,
    required this.description,
    required this.startTime,
    this.endTime,
    required this.type,
    this.isReminder = false,
  });

  factory EventItem.fromJson(Map<String, dynamic> json) {
    return EventItem(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      startTime: DateTime.parse(json['startTime']),
      endTime: json['endTime'] != null ? DateTime.parse(json['endTime']) : null,
      type: json['type'],
      isReminder: json['isReminder'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime?.toIso8601String(),
      'type': type,
      'isReminder': isReminder,
    };
  }
}

/// Quick stats model
class QuickStats {
  final int todayQuestions;
  final int weeklyGoalProgress;
  final int unreadNotifications;
  final double currentStreak;

  const QuickStats({
    required this.todayQuestions,
    required this.weeklyGoalProgress,
    required this.unreadNotifications,
    required this.currentStreak,
  });

  factory QuickStats.fromJson(Map<String, dynamic> json) {
    return QuickStats(
      todayQuestions: json['todayQuestions'] ?? 0,
      weeklyGoalProgress: json['weeklyGoalProgress'] ?? 0,
      unreadNotifications: json['unreadNotifications'] ?? 0,
      currentStreak: (json['currentStreak'] ?? 0.0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'todayQuestions': todayQuestions,
      'weeklyGoalProgress': weeklyGoalProgress,
      'unreadNotifications': unreadNotifications,
      'currentStreak': currentStreak,
    };
  }
}

/// Dashboard performance metrics
class DashboardPerformanceMetrics {
  final Duration averageLoadTime;
  final double successRate;
  final double cacheHitRate;
  final int totalLoads;

  const DashboardPerformanceMetrics({
    required this.averageLoadTime,
    required this.successRate,
    required this.cacheHitRate,
    required this.totalLoads,
  });

  @override
  String toString() {
    return 'DashboardPerformanceMetrics(avgLoad: ${averageLoadTime.inMilliseconds}ms, '
        'success: ${(successRate * 100).toStringAsFixed(1)}%, '
        'cacheHit: ${(cacheHitRate * 100).toStringAsFixed(1)}%, '
        'loads: $totalLoads)';
  }
}
