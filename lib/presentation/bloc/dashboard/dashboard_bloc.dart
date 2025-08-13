import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../core/services/service_locator.dart';
import '../../../data/models/api_models.dart';

// Events
abstract class DashboardEvent extends Equatable {
  const DashboardEvent();

  @override
  List<Object?> get props => [];
}

class DashboardStarted extends DashboardEvent {}

class DashboardRefresh extends DashboardEvent {}

class DashboardQuickActionTapped extends DashboardEvent {
  final String actionId;

  const DashboardQuickActionTapped({required this.actionId});

  @override
  List<Object?> get props => [actionId];
}

// States
abstract class DashboardState extends Equatable {
  const DashboardState();

  @override
  List<Object?> get props => [];
}

class DashboardInitial extends DashboardState {}

class DashboardLoading extends DashboardState {}

class DashboardLoaded extends DashboardState {
  final DashboardData data;
  final List<ActivityData> recentActivities;
  final List<InsightData> insights;
  final PerformanceInsights performanceData;

  const DashboardLoaded({
    required this.data,
    required this.recentActivities,
    required this.insights,
    required this.performanceData,
  });

  DashboardLoaded copyWith({
    DashboardData? data,
    List<ActivityData>? recentActivities,
    List<InsightData>? insights,
    PerformanceInsights? performanceData,
  }) {
    return DashboardLoaded(
      data: data ?? this.data,
      recentActivities: recentActivities ?? this.recentActivities,
      insights: insights ?? this.insights,
      performanceData: performanceData ?? this.performanceData,
    );
  }

  @override
  List<Object?> get props =>
      [data, recentActivities, insights, performanceData];
}

class DashboardError extends DashboardState {
  final String message;

  const DashboardError({required this.message});

  @override
  List<Object?> get props => [message];
}

// Models for Dashboard Data
class DashboardData extends Equatable {
  final int totalStudents;
  final int activeChats;
  final int contentGenerated;
  final int weeklyPlansCreated;
  final double progressPercentage;
  final List<String> quickActions;

  const DashboardData({
    required this.totalStudents,
    required this.activeChats,
    required this.contentGenerated,
    required this.weeklyPlansCreated,
    required this.progressPercentage,
    required this.quickActions,
  });

  factory DashboardData.fromJson(Map<String, dynamic> json) {
    return DashboardData(
      totalStudents: json['totalStudents'] ?? 0,
      activeChats: json['activeChats'] ?? 0,
      contentGenerated: json['contentGenerated'] ?? 0,
      weeklyPlansCreated: json['weeklyPlansCreated'] ?? 0,
      progressPercentage: (json['progressPercentage'] ?? 0.0).toDouble(),
      quickActions: List<String>.from(json['quickActions'] ?? []),
    );
  }

  @override
  List<Object?> get props => [
        totalStudents,
        activeChats,
        contentGenerated,
        weeklyPlansCreated,
        progressPercentage,
        quickActions,
      ];
}

class ActivityData extends Equatable {
  final String id;
  final String title;
  final String type;
  final DateTime timestamp;
  final String? description;
  final Map<String, dynamic>? metadata;

  const ActivityData({
    required this.id,
    required this.title,
    required this.type,
    required this.timestamp,
    this.description,
    this.metadata,
  });

  factory ActivityData.fromJson(Map<String, dynamic> json) {
    return ActivityData(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      type: json['type'] ?? '',
      timestamp:
          DateTime.parse(json['timestamp'] ?? DateTime.now().toIso8601String()),
      description: json['description'],
      metadata: json['metadata'],
    );
  }

  @override
  List<Object?> get props =>
      [id, title, type, timestamp, description, metadata];
}

class InsightData extends Equatable {
  final String id;
  final String title;
  final String description;
  final String type;
  final String? actionUrl;
  final Map<String, dynamic>? data;

  const InsightData({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    this.actionUrl,
    this.data,
  });

  factory InsightData.fromJson(Map<String, dynamic> json) {
    return InsightData(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      type: json['type'] ?? '',
      actionUrl: json['actionUrl'],
      data: json['data'],
    );
  }

  @override
  List<Object?> get props => [id, title, description, type, actionUrl, data];
}

// BLoC Implementation
class DashboardBloc extends Bloc<DashboardEvent, DashboardState> {
  DashboardBloc() : super(DashboardInitial()) {
    on<DashboardStarted>(_onDashboardStarted);
    on<DashboardRefresh>(_onDashboardRefresh);
    on<DashboardQuickActionTapped>(_onDashboardQuickActionTapped);
  }

  Future<void> _onDashboardStarted(
    DashboardStarted event,
    Emitter<DashboardState> emit,
  ) async {
    emit(DashboardLoading());

    try {
      // Load dashboard data in parallel
      final results = await Future.wait([
        ServiceLocator.dashboardService.getDashboardOverview(),
        ServiceLocator.dashboardService.getDashboardAnalytics(period: 'week'),
        ServiceLocator.dashboardService.getPerformanceInsights(),
      ]);

      final overviewResponse = results[0] as DashboardOverview;
      final analyticsResponse = results[1] as Map<String, dynamic>;
      final performanceInsights = results[2] as PerformanceInsights;

      // Convert dashboard overview to DashboardData
      final dashboardData = DashboardData(
        totalStudents: analyticsResponse['total_activities'] ?? 0,
        activeChats: overviewResponse.weeklyStats.totalChats,
        contentGenerated: overviewResponse.weeklyStats.contentGenerated,
        weeklyPlansCreated: overviewResponse.weeklyStats.lessonsPrepared,
        progressPercentage: (performanceInsights.productivityScore).toDouble(),
        quickActions: const [
          'chat',
          'content-generator',
          'lesson-planner',
          'math-generator'
        ],
      );

      // Convert recent activities from overview
      final recentActivities = overviewResponse.recentActivities
          .map((activity) => ActivityData(
                id: activity.id,
                title: activity.title,
                type: activity.type,
                timestamp: activity.timestamp,
              ))
          .toList();

      // Convert recommendations to insights
      final insights = overviewResponse.recommendations
          .map((rec) => InsightData(
                id: rec.id,
                title: rec.title,
                description: rec.description,
                type: rec.priority,
                actionUrl: rec.actionUrl,
              ))
          .toList();

      emit(DashboardLoaded(
        data: dashboardData,
        recentActivities: recentActivities,
        insights: insights,
        performanceData: performanceInsights,
      ));
    } catch (e) {
      emit(DashboardError(message: e.toString()));
    }
  }

  Future<void> _onDashboardRefresh(
    DashboardRefresh event,
    Emitter<DashboardState> emit,
  ) async {
    if (state is DashboardLoaded) {
      try {
        // Refresh dashboard data
        final results = await Future.wait([
          ServiceLocator.dashboardService.getDashboardOverview(),
          ServiceLocator.dashboardService.getDashboardAnalytics(period: 'week'),
          ServiceLocator.dashboardService.getPerformanceInsights(),
        ]);

        final overviewResponse = results[0] as DashboardOverview;
        final analyticsResponse = results[1] as Map<String, dynamic>;
        final performanceInsights = results[2] as PerformanceInsights;

        // Convert dashboard overview to DashboardData
        final dashboardData = DashboardData(
          totalStudents: analyticsResponse['total_activities'] ?? 0,
          activeChats: overviewResponse.weeklyStats.totalChats,
          contentGenerated: overviewResponse.weeklyStats.contentGenerated,
          weeklyPlansCreated: overviewResponse.weeklyStats.lessonsPrepared,
          progressPercentage:
              (performanceInsights.productivityScore).toDouble(),
          quickActions: const [
            'chat',
            'content-generator',
            'lesson-planner',
            'math-generator'
          ],
        );

        // Convert recent activities from overview
        final recentActivities = overviewResponse.recentActivities
            .map((activity) => ActivityData(
                  id: activity.id,
                  title: activity.title,
                  type: activity.type,
                  timestamp: activity.timestamp,
                ))
            .toList();

        // Convert recommendations to insights
        final insights = overviewResponse.recommendations
            .map((rec) => InsightData(
                  id: rec.id,
                  title: rec.title,
                  description: rec.description,
                  type: rec.priority,
                  actionUrl: rec.actionUrl,
                ))
            .toList();

        emit(DashboardLoaded(
          data: dashboardData,
          recentActivities: recentActivities,
          insights: insights,
          performanceData: performanceInsights,
        ));
      } catch (e) {
        // On error, emit error but keep data
        emit(DashboardError(message: e.toString()));
      }
    } else {
      // If not loaded, start fresh
      add(DashboardStarted());
    }
  }

  Future<void> _onDashboardQuickActionTapped(
    DashboardQuickActionTapped event,
    Emitter<DashboardState> emit,
  ) async {
    try {
      // Track the activity using the trackActivity method
      await ServiceLocator.dashboardService.trackActivity(
        activityType: 'quick_action',
        activityId: event.actionId,
        metadata: {'source': 'dashboard'},
      );
      // Optionally refresh dashboard to reflect the action
      add(DashboardRefresh());
    } catch (e) {
      // Silently fail for tracking actions
    }
  }
}
