import '../models/api_models.dart';
import '../datasources/api_service.dart';
import '../../core/constants/api_constants.dart';

class ContentService {
  final ApiClient _apiClient;

  ContentService(this._apiClient);

  Future<GeneratedContent> generateContent({
    required String contentType,
    required String subject,
    required String grade,
    required String topic,
    String? length,
    String? difficulty,
    String? language,
    Map<String, dynamic>? culturalContext,
    List<String>? learningObjectives,
  }) async {
    final contentRequest = ContentGenerationRequest(
      contentType: contentType,
      subject: subject,
      grade: grade,
      topic: topic,
      length: length,
      difficulty: difficulty,
      language: language,
      culturalContext: culturalContext,
      learningObjectives: learningObjectives,
    );

    final response = await _apiClient.post<GeneratedContent>(
      ApiConstants.generateContent,
      data: contentRequest.toJson(),
      fromJson: (json) => GeneratedContent.fromJson(json),
    );

    if (response.isSuccess && response.data != null) {
      return response.data!;
    } else {
      throw ApiError(message: response.error ?? 'Failed to generate content');
    }
  }

  Future<List<GeneratedContent>> getContentHistory({
    int page = 1,
    int perPage = 20,
    String? contentType,
    String? subject,
    String? grade,
  }) async {
    final queryParams = <String, dynamic>{
      'page': page,
      'per_page': perPage,
    };

    if (contentType != null) queryParams['content_type'] = contentType;
    if (subject != null) queryParams['subject'] = subject;
    if (grade != null) queryParams['grade'] = grade;

    final response = await _apiClient.get(
      ApiConstants.contentHistory,
      queryParameters: queryParams,
    );

    if (response.isSuccess && response.data != null) {
      final contentList = response.data['content'] as List;
      return contentList
          .map((json) => GeneratedContent.fromJson(json))
          .toList();
    } else {
      throw ApiError(
          message: response.error ?? 'Failed to get content history');
    }
  }

  Future<GeneratedContent> getContentById(String contentId) async {
    final response = await _apiClient.get<GeneratedContent>(
      '${ApiConstants.contentById}/$contentId',
      fromJson: (json) => GeneratedContent.fromJson(json),
    );

    if (response.isSuccess && response.data != null) {
      return response.data!;
    } else {
      throw ApiError(message: response.error ?? 'Failed to get content');
    }
  }

  Future<String> exportContent({
    required String contentId,
    required String format, // pdf, docx, html
  }) async {
    final response = await _apiClient.post(
      '${ApiConstants.exportContent}/$contentId',
      data: {'format': format},
    );

    if (response.isSuccess && response.data != null) {
      return response.data['download_url'];
    } else {
      throw ApiError(message: response.error ?? 'Failed to export content');
    }
  }

  Future<List<GeneratedContent>> generateContentVariants({
    required String contentId,
    List<String>? difficultyLevels,
    List<String>? styles,
  }) async {
    final response = await _apiClient.post(
      '${ApiConstants.contentVariants}/$contentId',
      data: {
        'difficulty_levels': difficultyLevels,
        'styles': styles,
      },
    );

    if (response.isSuccess && response.data != null) {
      final variantsList = response.data['variants'] as List;
      return variantsList
          .map((json) => GeneratedContent.fromJson(json))
          .toList();
    } else {
      throw ApiError(message: response.error ?? 'Failed to generate variants');
    }
  }

  Future<List<Map<String, dynamic>>> getContentTemplates({
    String? contentType,
    String? subject,
    String? grade,
  }) async {
    final queryParams = <String, dynamic>{};
    if (contentType != null) queryParams['content_type'] = contentType;
    if (subject != null) queryParams['subject'] = subject;
    if (grade != null) queryParams['grade'] = grade;

    final response = await _apiClient.get(
      ApiConstants.contentTemplates,
      queryParameters: queryParams,
    );

    if (response.isSuccess && response.data != null) {
      return List<Map<String, dynamic>>.from(response.data['templates']);
    } else {
      throw ApiError(message: response.error ?? 'Failed to get templates');
    }
  }

  Future<List<Map<String, dynamic>>> getContentSuggestions({
    String? subject,
    String? grade,
    String? context,
  }) async {
    final queryParams = <String, dynamic>{};
    if (subject != null) queryParams['subject'] = subject;
    if (grade != null) queryParams['grade'] = grade;
    if (context != null) queryParams['context'] = context;

    final response = await _apiClient.get(
      ApiConstants.contentSuggestions,
      queryParameters: queryParams,
    );

    if (response.isSuccess && response.data != null) {
      return List<Map<String, dynamic>>.from(response.data['suggestions']);
    } else {
      throw ApiError(message: response.error ?? 'Failed to get suggestions');
    }
  }

  Future<Map<String, dynamic>> getContentStatistics() async {
    final response = await _apiClient.get(ApiConstants.contentStatistics);

    if (response.isSuccess && response.data != null) {
      return response.data;
    } else {
      throw ApiError(message: response.error ?? 'Failed to get statistics');
    }
  }
}
