import '../models/api_models.dart';
import '../datasources/api_service.dart';
import '../../core/constants/api_constants.dart';

class WeeklyPlanningService {
  final ApiClient _apiClient;

  WeeklyPlanningService(this._apiClient);

  Future<WeeklyPlanResponse> createWeeklyPlan({
    required String title,
    String? description,
    required DateTime weekStart,
    required List<String> targetGrades,
    required List<String> subjects,
    required List<DayPlanRequest> dayPlans,
  }) async {
    final planRequest = WeeklyPlanRequest(
      title: title,
      description: description,
      weekStart: weekStart.toIso8601String().split('T')[0],
      targetGrades: targetGrades,
      subjects: subjects,
      dayPlans: dayPlans,
    );

    final response = await _apiClient.post<WeeklyPlanResponse>(
      ApiConstants.weeklyPlans,
      data: planRequest.toJson(),
      fromJson: (json) => WeeklyPlanResponse.fromJson(json),
    );

    if (response.isSuccess && response.data != null) {
      return response.data!;
    } else {
      throw ApiError(message: response.error ?? 'Failed to create weekly plan');
    }
  }

  Future<List<WeeklyPlanResponse>> getWeeklyPlans({
    int page = 1,
    int perPage = 20,
    String? grade,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final queryParams = <String, dynamic>{
      'page': page,
      'per_page': perPage,
    };

    if (grade != null) queryParams['grade'] = grade;
    if (startDate != null) {
      queryParams['start_date'] = startDate.toIso8601String().split('T')[0];
    }
    if (endDate != null) {
      queryParams['end_date'] = endDate.toIso8601String().split('T')[0];
    }

    final response = await _apiClient.get(
      ApiConstants.weeklyPlans,
      queryParameters: queryParams,
    );

    if (response.isSuccess && response.data != null) {
      final plansList = response.data['plans'] as List;
      return plansList
          .map((json) => WeeklyPlanResponse.fromJson(json))
          .toList();
    } else {
      throw ApiError(message: response.error ?? 'Failed to get weekly plans');
    }
  }

  Future<WeeklyPlanResponse> getWeeklyPlan(String planId) async {
    final response = await _apiClient.get<WeeklyPlanResponse>(
      '${ApiConstants.weeklyPlans}/$planId',
      fromJson: (json) => WeeklyPlanResponse.fromJson(json),
    );

    if (response.isSuccess && response.data != null) {
      return response.data!;
    } else {
      throw ApiError(message: response.error ?? 'Failed to get weekly plan');
    }
  }

  Future<WeeklyPlanResponse> updateWeeklyPlan({
    required String planId,
    String? title,
    String? description,
    List<String>? targetGrades,
    List<String>? subjects,
    List<DayPlanRequest>? dayPlans,
  }) async {
    final updateData = <String, dynamic>{};
    if (title != null) updateData['title'] = title;
    if (description != null) updateData['description'] = description;
    if (targetGrades != null) updateData['target_grades'] = targetGrades;
    if (subjects != null) updateData['subjects'] = subjects;
    if (dayPlans != null) {
      updateData['day_plans'] = dayPlans.map((e) => e.toJson()).toList();
    }

    final response = await _apiClient.put<WeeklyPlanResponse>(
      '${ApiConstants.weeklyPlans}/$planId',
      data: updateData,
      fromJson: (json) => WeeklyPlanResponse.fromJson(json),
    );

    if (response.isSuccess && response.data != null) {
      return response.data!;
    } else {
      throw ApiError(message: response.error ?? 'Failed to update weekly plan');
    }
  }

  Future<void> deleteWeeklyPlan(String planId) async {
    final response =
        await _apiClient.delete('${ApiConstants.weeklyPlans}/$planId');

    if (!response.isSuccess) {
      throw ApiError(message: response.error ?? 'Failed to delete weekly plan');
    }
  }

  Future<List<Map<String, dynamic>>> getActivitySuggestions({
    String? subject,
    String? grade,
    String? topic,
    int? duration,
    String? activityType,
  }) async {
    final requestData = <String, dynamic>{};
    if (subject != null) requestData['subject'] = subject;
    if (grade != null) requestData['grade'] = grade;
    if (topic != null) requestData['topic'] = topic;
    if (duration != null) requestData['duration'] = duration;
    if (activityType != null) requestData['activity_type'] = activityType;

    final response = await _apiClient.post(
      ApiConstants.aiSuggestions,
      data: requestData,
    );

    if (response.isSuccess && response.data != null) {
      return List<Map<String, dynamic>>.from(response.data['suggestions']);
    } else {
      throw ApiError(
          message: response.error ?? 'Failed to get activity suggestions');
    }
  }

  Future<List<WeeklyPlanResponse>> getPlanTemplates({
    String? category,
    String? grade,
    String? subject,
  }) async {
    final queryParams = <String, dynamic>{};
    if (category != null) queryParams['category'] = category;
    if (grade != null) queryParams['grade'] = grade;
    if (subject != null) queryParams['subject'] = subject;

    final response = await _apiClient.get(
      ApiConstants.planTemplates,
      queryParameters: queryParams,
    );

    if (response.isSuccess && response.data != null) {
      final templatesList = response.data['templates'] as List;
      return templatesList
          .map((json) => WeeklyPlanResponse.fromJson(json))
          .toList();
    } else {
      throw ApiError(message: response.error ?? 'Failed to get plan templates');
    }
  }

  Future<WeeklyPlanResponse> copyWeeklyPlan(String planId) async {
    final response = await _apiClient.post<WeeklyPlanResponse>(
      '${ApiConstants.weeklyPlans}/$planId/copy',
      fromJson: (json) => WeeklyPlanResponse.fromJson(json),
    );

    if (response.isSuccess && response.data != null) {
      return response.data!;
    } else {
      throw ApiError(message: response.error ?? 'Failed to copy weekly plan');
    }
  }

  Future<String> exportWeeklyPlan({
    required String planId,
    required String format, // pdf, docx, html
  }) async {
    final response = await _apiClient.post(
      '${ApiConstants.exportPlan}/$planId',
      data: {'format': format},
    );

    if (response.isSuccess && response.data != null) {
      return response.data['download_url'];
    } else {
      throw ApiError(message: response.error ?? 'Failed to export weekly plan');
    }
  }

  Future<Map<String, dynamic>> optimizeSchedule({
    required String planId,
    List<String>? constraints,
    Map<String, dynamic>? preferences,
  }) async {
    final response = await _apiClient.post(
      '${ApiConstants.schedulingOptimization}/$planId',
      data: {
        'constraints': constraints,
        'preferences': preferences,
      },
    );

    if (response.isSuccess && response.data != null) {
      return response.data;
    } else {
      throw ApiError(message: response.error ?? 'Failed to optimize schedule');
    }
  }
}
