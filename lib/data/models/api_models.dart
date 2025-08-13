// API Response Models
class ApiResponse<T> {
  final bool success;
  final T? data;
  final String? message;
  final String? error;
  final int? code;
  final Map<String, dynamic>? details;

  ApiResponse({
    required this.success,
    this.data,
    this.message,
    this.error,
    this.code,
    this.details,
  });

  factory ApiResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>)? fromJsonT,
  ) {
    return ApiResponse<T>(
      success: json['success'] ?? false,
      data: json['data'] != null && fromJsonT != null
          ? fromJsonT(json['data'])
          : json['data'],
      message: json['message'],
      error: json['error'],
      code: json['code'],
      details: json['details'],
    );
  }

  bool get isSuccess => success && error == null;
  bool get isError => !success || error != null;
}

// Authentication Models
class LoginRequest {
  final String email;
  final String password;
  final String deviceId;

  LoginRequest({
    required this.email,
    required this.password,
    required this.deviceId,
  });

  Map<String, dynamic> toJson() => {
        'email': email,
        'password': password,
        'deviceId': deviceId,
      };
}

class RegisterRequest {
  final String email;
  final String password;
  final String firstName;
  final String lastName;
  final String? phoneNumber;
  final String? grade;
  final String? subject;
  final String deviceId;

  RegisterRequest({
    required this.email,
    required this.password,
    required this.firstName,
    required this.lastName,
    this.phoneNumber,
    this.grade,
    this.subject,
    required this.deviceId,
  });

  Map<String, dynamic> toJson() => {
        'email': email,
        'password': password,
        'firstName': firstName,
        'lastName': lastName,
        'phoneNumber': phoneNumber,
        'grade': grade,
        'subject': subject,
        'deviceId': deviceId,
      };
}

class AuthResponse {
  final String token;
  final String refreshToken;
  final UserModel user;

  AuthResponse({
    required this.token,
    required this.refreshToken,
    required this.user,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      token: json['token'],
      refreshToken: json['refreshToken'],
      user: UserModel.fromJson(json['user']),
    );
  }
}

class UserModel {
  final String id;
  final String email;
  final String firstName;
  final String lastName;
  final String? phoneNumber;
  final String role;
  final List<String>? grades;
  final List<String>? subjects;
  final String? school;
  final bool emailVerified;
  final String? language;
  final String? profileImage;
  final DateTime? createdAt;
  final DateTime? lastLoginAt;

  UserModel({
    required this.id,
    required this.email,
    required this.firstName,
    required this.lastName,
    this.phoneNumber,
    required this.role,
    this.grades,
    this.subjects,
    this.school,
    required this.emailVerified,
    this.language,
    this.profileImage,
    this.createdAt,
    this.lastLoginAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    // Handle the case where API returns 'name' field instead of firstName/lastName
    String firstName = '';
    String lastName = '';

    if (json['name'] != null) {
      final nameParts = (json['name'] as String).split(' ');
      firstName = nameParts.isNotEmpty ? nameParts.first : '';
      lastName = nameParts.length > 1 ? nameParts.sublist(1).join(' ') : '';
    } else {
      firstName = json['firstName'] ?? '';
      lastName = json['lastName'] ?? '';
    }

    return UserModel(
      id: json['id'],
      email: json['email'],
      firstName: firstName,
      lastName: lastName,
      phoneNumber: json['phoneNumber'],
      role: json['role'],
      grades: json['grades'] != null ? List<String>.from(json['grades']) : null,
      subjects:
          json['subjects'] != null ? List<String>.from(json['subjects']) : null,
      school: json['school'],
      emailVerified: json['email_verified'] ?? json['emailVerified'] ?? false,
      language: json['language'],
      profileImage: json['profileImage'],
      createdAt:
          json['createdAt'] != null ? DateTime.parse(json['createdAt']) : null,
      lastLoginAt: json['lastLoginAt'] != null
          ? DateTime.parse(json['lastLoginAt'])
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'email': email,
        'firstName': firstName,
        'lastName': lastName,
        'phoneNumber': phoneNumber,
        'role': role,
        'grades': grades,
        'subjects': subjects,
        'school': school,
        'emailVerified': emailVerified,
        'language': language,
        'profileImage': profileImage,
        'createdAt': createdAt?.toIso8601String(),
        'lastLoginAt': lastLoginAt?.toIso8601String(),
      };

  String get fullName => '$firstName $lastName';
}

// AI Chat Models
class ChatRequest {
  final String message;
  final String? userId;
  final Map<String, dynamic>? context;
  final int maxTokens;
  final double temperature;
  final String? conversationId;

  ChatRequest({
    required this.message,
    this.userId,
    this.context,
    this.maxTokens = 1000,
    this.temperature = 0.7,
    this.conversationId,
  });

  Map<String, dynamic> toJson() => {
        'message': message,
        if (userId != null) 'user_id': userId,
        'context': context ??
            {'conversation_id': conversationId, 'previous_messages': []},
        'max_tokens': maxTokens,
        'temperature': temperature,
        if (conversationId != null) 'conversation_id': conversationId,
      };
}

class ChatResponse {
  final String response;
  final String? conversationId;
  final String? userId;
  final String status;
  final UsageInfo? usage;
  final List<String>? suggestions;

  ChatResponse({
    required this.response,
    this.conversationId,
    this.userId,
    this.status = 'success',
    this.usage,
    this.suggestions,
  });

  factory ChatResponse.fromJson(Map<String, dynamic> json) {
    return ChatResponse(
      response: json['response'] ?? '',
      conversationId: json['conversation_id'],
      userId: json['user_id'],
      status: json['status'] ?? 'success',
      usage: json['usage'] != null ? UsageInfo.fromJson(json['usage']) : null,
      suggestions: json['suggestions']?.cast<String>(),
    );
  }
}

class UsageInfo {
  final int promptTokens;
  final int completionTokens;
  final int totalTokens;

  UsageInfo({
    required this.promptTokens,
    required this.completionTokens,
    required this.totalTokens,
  });

  factory UsageInfo.fromJson(Map<String, dynamic> json) {
    return UsageInfo(
      promptTokens: json['prompt_tokens'],
      completionTokens: json['completion_tokens'],
      totalTokens: json['total_tokens'],
    );
  }
}

// Content Generation Models
class ContentGenerationRequest {
  final String contentType;
  final String subject;
  final String grade;
  final String topic;
  final String? length;
  final String? difficulty;
  final String? language;
  final Map<String, dynamic>? culturalContext;
  final List<String>? learningObjectives;

  ContentGenerationRequest({
    required this.contentType,
    required this.subject,
    required this.grade,
    required this.topic,
    this.length,
    this.difficulty,
    this.language,
    this.culturalContext,
    this.learningObjectives,
  });

  Map<String, dynamic> toJson() => {
        'content_type': contentType,
        'subject': subject,
        'grade': grade,
        'topic': topic,
        'length': length,
        'difficulty': difficulty,
        'language': language,
        'cultural_context': culturalContext,
        'learning_objectives': learningObjectives,
      };
}

class GeneratedContent {
  final String id;
  final String type;
  final String title;
  final Map<String, dynamic> content;
  final ContentMetadata metadata;
  final DateTime createdAt;

  GeneratedContent({
    required this.id,
    required this.type,
    required this.title,
    required this.content,
    required this.metadata,
    required this.createdAt,
  });

  factory GeneratedContent.fromJson(Map<String, dynamic> json) {
    return GeneratedContent(
      id: json['id'],
      type: json['type'],
      title: json['title'],
      content: json['content'],
      metadata: ContentMetadata.fromJson(json['metadata']),
      createdAt: DateTime.parse(json['created_at'] ?? json['createdAt']),
    );
  }
}

class ContentMetadata {
  final String grade;
  final String subject;
  final int estimatedTime;
  final String difficulty;
  final int? wordCount;
  final List<String>? keywords;

  ContentMetadata({
    required this.grade,
    required this.subject,
    required this.estimatedTime,
    required this.difficulty,
    this.wordCount,
    this.keywords,
  });

  factory ContentMetadata.fromJson(Map<String, dynamic> json) {
    return ContentMetadata(
      grade: json['grade'],
      subject: json['subject'],
      estimatedTime: json['estimated_time'],
      difficulty: json['difficulty'],
      wordCount: json['word_count'],
      keywords: json['keywords']?.cast<String>(),
    );
  }
}

// Weekly Planning Models
class WeeklyPlanRequest {
  final String title;
  final String? description;
  final String weekStart;
  final List<String> targetGrades;
  final List<String> subjects;
  final List<DayPlanRequest> dayPlans;

  WeeklyPlanRequest({
    required this.title,
    this.description,
    required this.weekStart,
    required this.targetGrades,
    required this.subjects,
    required this.dayPlans,
  });

  Map<String, dynamic> toJson() => {
        'title': title,
        'description': description,
        'week_start': weekStart,
        'target_grades': targetGrades,
        'subjects': subjects,
        'day_plans': dayPlans.map((e) => e.toJson()).toList(),
      };
}

class DayPlanRequest {
  final String day;
  final List<ActivityRequest> activities;

  DayPlanRequest({
    required this.day,
    required this.activities,
  });

  Map<String, dynamic> toJson() => {
        'day': day,
        'activities': activities.map((e) => e.toJson()).toList(),
      };
}

class ActivityRequest {
  final String title;
  final String description;
  final String startTime;
  final String endTime;
  final String activityType;
  final String subject;
  final List<String>? materials;
  final List<String>? objectives;

  ActivityRequest({
    required this.title,
    required this.description,
    required this.startTime,
    required this.endTime,
    required this.activityType,
    required this.subject,
    this.materials,
    this.objectives,
  });

  Map<String, dynamic> toJson() => {
        'title': title,
        'description': description,
        'start_time': startTime,
        'end_time': endTime,
        'activity_type': activityType,
        'subject': subject,
        'materials': materials,
        'objectives': objectives,
      };
}

class WeeklyPlanResponse {
  final String id;
  final String title;
  final String? description;
  final DateTime weekStart;
  final List<String> targetGrades;
  final List<String> subjects;
  final List<DayPlanResponse> dayPlans;
  final DateTime createdAt;
  final DateTime? modifiedAt;

  WeeklyPlanResponse({
    required this.id,
    required this.title,
    this.description,
    required this.weekStart,
    required this.targetGrades,
    required this.subjects,
    required this.dayPlans,
    required this.createdAt,
    this.modifiedAt,
  });

  factory WeeklyPlanResponse.fromJson(Map<String, dynamic> json) {
    return WeeklyPlanResponse(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      weekStart: DateTime.parse(json['week_start']),
      targetGrades: json['target_grades'].cast<String>(),
      subjects: json['subjects'].cast<String>(),
      dayPlans: (json['day_plans'] as List)
          .map((e) => DayPlanResponse.fromJson(e))
          .toList(),
      createdAt: DateTime.parse(json['created_at']),
      modifiedAt: json['modified_at'] != null
          ? DateTime.parse(json['modified_at'])
          : null,
    );
  }
}

class DayPlanResponse {
  final String day;
  final List<ActivityResponse> activities;

  DayPlanResponse({
    required this.day,
    required this.activities,
  });

  factory DayPlanResponse.fromJson(Map<String, dynamic> json) {
    return DayPlanResponse(
      day: json['day'],
      activities: (json['activities'] as List)
          .map((e) => ActivityResponse.fromJson(e))
          .toList(),
    );
  }
}

class ActivityResponse {
  final String id;
  final String title;
  final String description;
  final String startTime;
  final String endTime;
  final String activityType;
  final String subject;
  final List<String>? materials;
  final List<String>? objectives;

  ActivityResponse({
    required this.id,
    required this.title,
    required this.description,
    required this.startTime,
    required this.endTime,
    required this.activityType,
    required this.subject,
    this.materials,
    this.objectives,
  });

  factory ActivityResponse.fromJson(Map<String, dynamic> json) {
    return ActivityResponse(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      startTime: json['start_time'],
      endTime: json['end_time'],
      activityType: json['activity_type'],
      subject: json['subject'],
      materials: json['materials']?.cast<String>(),
      objectives: json['objectives']?.cast<String>(),
    );
  }
}

// Dashboard Models
class DashboardOverview {
  final WeeklyStats weeklyStats;
  final List<RecentActivity> recentActivities;
  final List<Recommendation> recommendations;

  DashboardOverview({
    required this.weeklyStats,
    required this.recentActivities,
    required this.recommendations,
  });

  factory DashboardOverview.fromJson(Map<String, dynamic> json) {
    return DashboardOverview(
      weeklyStats: WeeklyStats.fromJson(json['weeklyStats']),
      recentActivities: (json['recentActivities'] as List)
          .map((e) => RecentActivity.fromJson(e))
          .toList(),
      recommendations: (json['recommendations'] as List)
          .map((e) => Recommendation.fromJson(e))
          .toList(),
    );
  }
}

class WeeklyStats {
  final int totalChats;
  final int contentGenerated;
  final int lessonsPrepared;
  final int timeSpent;

  WeeklyStats({
    required this.totalChats,
    required this.contentGenerated,
    required this.lessonsPrepared,
    required this.timeSpent,
  });

  factory WeeklyStats.fromJson(Map<String, dynamic> json) {
    return WeeklyStats(
      totalChats: json['totalChats'],
      contentGenerated: json['contentGenerated'],
      lessonsPrepared: json['lessonsPrepared'],
      timeSpent: json['timeSpent'],
    );
  }
}

class RecentActivity {
  final String id;
  final String type;
  final String title;
  final DateTime timestamp;

  RecentActivity({
    required this.id,
    required this.type,
    required this.title,
    required this.timestamp,
  });

  factory RecentActivity.fromJson(Map<String, dynamic> json) {
    return RecentActivity(
      id: json['id'],
      type: json['type'],
      title: json['title'],
      timestamp: DateTime.parse(json['timestamp']),
    );
  }
}

class Recommendation {
  final String id;
  final String title;
  final String description;
  final String actionUrl;
  final String priority;

  Recommendation({
    required this.id,
    required this.title,
    required this.description,
    required this.actionUrl,
    required this.priority,
  });

  factory Recommendation.fromJson(Map<String, dynamic> json) {
    return Recommendation(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      actionUrl: json['actionUrl'],
      priority: json['priority'],
    );
  }
}

// Performance Insights Models
class PerformanceInsights {
  final List<InsightItem> insights;
  final int productivityScore;
  final String period;
  final DateTime generatedAt;
  final String status;

  PerformanceInsights({
    required this.insights,
    required this.productivityScore,
    required this.period,
    required this.generatedAt,
    required this.status,
  });

  factory PerformanceInsights.fromJson(Map<String, dynamic> json) {
    return PerformanceInsights(
      insights: (json['insights'] as List)
          .map((e) => InsightItem.fromJson(e))
          .toList(),
      productivityScore: json['productivityScore'] ?? 0,
      period: json['period'] ?? 'week',
      generatedAt: DateTime.parse(json['generatedAt']),
      status: json['status'] ?? 'success',
    );
  }
}

class InsightItem {
  final String title;
  final String message;
  final String type;
  final String level;
  final String action;
  final bool actionable;

  InsightItem({
    required this.title,
    required this.message,
    required this.type,
    required this.level,
    required this.action,
    required this.actionable,
  });

  factory InsightItem.fromJson(Map<String, dynamic> json) {
    return InsightItem(
      title: json['title'] ?? '',
      message: json['message'] ?? '',
      type: json['type'] ?? '',
      level: json['level'] ?? '',
      action: json['action'] ?? '',
      actionable: json['actionable'] ?? false,
    );
  }
}

// File Management Models
class FileUploadResponse {
  final String id;
  final String filename;
  final String fileType;
  final int fileSize;
  final String accessLevel;
  final DateTime uploadDate;
  final String scanStatus;
  final String downloadUrl;
  final String? thumbnailUrl;
  final List<String>? tags;
  final String? description;

  FileUploadResponse({
    required this.id,
    required this.filename,
    required this.fileType,
    required this.fileSize,
    required this.accessLevel,
    required this.uploadDate,
    required this.scanStatus,
    required this.downloadUrl,
    this.thumbnailUrl,
    this.tags,
    this.description,
  });

  factory FileUploadResponse.fromJson(Map<String, dynamic> json) {
    return FileUploadResponse(
      id: json['id'],
      filename: json['filename'],
      fileType: json['file_type'],
      fileSize: json['file_size'],
      accessLevel: json['access_level'],
      uploadDate: DateTime.parse(json['upload_date']),
      scanStatus: json['scan_status'],
      downloadUrl: json['download_url'],
      thumbnailUrl: json['thumbnail_url'],
      tags: json['tags']?.cast<String>(),
      description: json['description'],
    );
  }
}

// Speech Services Models
class SpeechToTextRequest {
  final String audioData;
  final String language;
  final String encoding;

  SpeechToTextRequest({
    required this.audioData,
    required this.language,
    required this.encoding,
  });

  Map<String, dynamic> toJson() => {
        'audio_data': audioData,
        'language': language,
        'encoding': encoding,
      };
}

class SpeechToTextResponse {
  final String text;
  final String language;
  final double confidence;
  final List<TranscriptAlternative>? alternatives;

  SpeechToTextResponse({
    required this.text,
    required this.language,
    required this.confidence,
    this.alternatives,
  });

  factory SpeechToTextResponse.fromJson(Map<String, dynamic> json) {
    return SpeechToTextResponse(
      text: json['text'],
      language: json['language'],
      confidence: json['confidence'].toDouble(),
      alternatives: json['alternatives'] != null
          ? (json['alternatives'] as List)
              .map((e) => TranscriptAlternative.fromJson(e))
              .toList()
          : null,
    );
  }
}

class TranscriptAlternative {
  final String transcript;
  final double confidence;

  TranscriptAlternative({
    required this.transcript,
    required this.confidence,
  });

  factory TranscriptAlternative.fromJson(Map<String, dynamic> json) {
    return TranscriptAlternative(
      transcript: json['transcript'],
      confidence: json['confidence'].toDouble(),
    );
  }
}

class TextToSpeechRequest {
  final String text;
  final String language;
  final String voice;
  final double? speed;
  final double? pitch;

  TextToSpeechRequest({
    required this.text,
    required this.language,
    required this.voice,
    this.speed,
    this.pitch,
  });

  Map<String, dynamic> toJson() => {
        'text': text,
        'language': language,
        'voice': voice,
        'speed': speed,
        'pitch': pitch,
      };
}

class TextToSpeechResponse {
  final String audioData;
  final String audioFormat;
  final String language;
  final String voice;

  TextToSpeechResponse({
    required this.audioData,
    required this.audioFormat,
    required this.language,
    required this.voice,
  });

  factory TextToSpeechResponse.fromJson(Map<String, dynamic> json) {
    return TextToSpeechResponse(
      audioData: json['audio_data'],
      audioFormat: json['audio_format'],
      language: json['language'],
      voice: json['voice'],
    );
  }
}

// Error Models
class ApiError implements Exception {
  final String message;
  final int? statusCode;
  final String? errorCode;
  final Map<String, dynamic>? details;

  ApiError({
    required this.message,
    this.statusCode,
    this.errorCode,
    this.details,
  });

  factory ApiError.fromJson(Map<String, dynamic> json) {
    return ApiError(
      message: json['error'] ?? json['message'] ?? 'Unknown error',
      statusCode: json['code'],
      errorCode: json['error_code'],
      details: json['details'],
    );
  }

  @override
  String toString() => 'ApiError: $message';
}
