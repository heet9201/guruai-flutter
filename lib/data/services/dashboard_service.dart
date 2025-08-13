import '../models/api_models.dart';
import '../datasources/api_service.dart';
import '../../core/constants/api_constants.dart';

class DashboardService {
  final ApiClient _apiClient;

  DashboardService(this._apiClient);

  Future<DashboardOverview> getDashboardOverview() async {
    final response = await _apiClient.get<DashboardOverview>(
      ApiConstants.dashboardOverview,
      fromJson: (json) => DashboardOverview.fromJson(json),
    );

    if (response.isSuccess && response.data != null) {
      return response.data!;
    } else {
      throw ApiError(
          message: response.error ?? 'Failed to get dashboard overview');
    }
  }

  Future<Map<String, dynamic>> getDashboardAnalytics({
    String period = 'week',
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final queryParams = <String, dynamic>{
      'period': period,
    };

    if (startDate != null) {
      queryParams['startDate'] = startDate.toIso8601String().split('T')[0];
    }
    if (endDate != null) {
      queryParams['endDate'] = endDate.toIso8601String().split('T')[0];
    }

    final response = await _apiClient.get(
      ApiConstants.dashboardAnalytics,
      queryParameters: queryParams,
    );

    if (response.isSuccess && response.data != null) {
      return response.data;
    } else {
      throw ApiError(
          message: response.error ?? 'Failed to get dashboard analytics');
    }
  }

  Future<void> trackActivity({
    required String activityType,
    required String activityId,
    Map<String, dynamic>? metadata,
  }) async {
    final response = await _apiClient.post(
      ApiConstants.trackActivity,
      data: {
        'activity_type': activityType,
        'activity_id': activityId,
        'metadata': metadata,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );

    if (!response.isSuccess) {
      throw ApiError(message: response.error ?? 'Failed to track activity');
    }
  }

  Future<List<Recommendation>> refreshRecommendations() async {
    final response = await _apiClient.post(ApiConstants.refreshRecommendations);

    if (response.isSuccess && response.data != null) {
      final recommendationsList = response.data['recommendations'] as List;
      return recommendationsList
          .map((json) => Recommendation.fromJson(json))
          .toList();
    } else {
      throw ApiError(
          message: response.error ?? 'Failed to refresh recommendations');
    }
  }

  Future<PerformanceInsights> getPerformanceInsights({
    String period = 'week',
    List<String>? metrics,
  }) async {
    final queryParams = <String, dynamic>{
      'period': period,
    };

    if (metrics != null) {
      queryParams['metrics'] = metrics.join(',');
    }

    final response = await _apiClient.get<PerformanceInsights>(
      ApiConstants.performanceInsights,
      queryParameters: queryParams,
      fromJson: (json) => PerformanceInsights.fromJson(json),
    );

    if (response.isSuccess && response.data != null) {
      return response.data!;
    } else {
      throw ApiError(
          message: response.error ?? 'Failed to get performance insights');
    }
  }
}
