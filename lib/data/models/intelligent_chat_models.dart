import '../../domain/entities/chat_message.dart';

/// Model for intelligent chat response - Enhanced to match API response
class IntelligentChatResponse {
  final String content;
  final String messageId;
  final DateTime timestamp;
  final List<ChatSuggestion> suggestions;
  final List<RelatedTopic> relatedTopics;
  final List<StudyRecommendation> studyRecommendations;
  final IntelligentChatAnalytics analytics;
  final String? sessionId;
  final Map<String, dynamic> metadata;

  const IntelligentChatResponse({
    required this.content,
    required this.messageId,
    required this.timestamp,
    this.suggestions = const [],
    this.relatedTopics = const [],
    this.studyRecommendations = const [],
    required this.analytics,
    this.sessionId,
    this.metadata = const {},
  });

  factory IntelligentChatResponse.fromJson(Map<String, dynamic> json) {
    // Handle the actual API response structure from the testing report
    return IntelligentChatResponse(
      content: json['content'] ?? '',
      messageId: json['message_id'] ?? '',
      timestamp:
          DateTime.parse(json['timestamp'] ?? DateTime.now().toIso8601String()),
      suggestions: (json['suggestions'] as List<dynamic>?)
              ?.map((s) => ChatSuggestion.fromJson(s))
              .toList() ??
          [],
      relatedTopics: (json['related_topics'] as List<dynamic>?)
              ?.map((t) => RelatedTopic.fromJson(t))
              .toList() ??
          [],
      studyRecommendations: (json['study_recommendations'] as List<dynamic>?)
              ?.map((r) => StudyRecommendation.fromJson(r))
              .toList() ??
          [],
      analytics: IntelligentChatAnalytics.fromJson(json['analytics'] ?? {}),
      sessionId: json['session_id'],
      metadata: Map<String, dynamic>.from(json['metadata'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'content': content,
      'message_id': messageId,
      'timestamp': timestamp.toIso8601String(),
      'suggestions': suggestions.map((s) => s.toJson()).toList(),
      'related_topics': relatedTopics.map((t) => t.toJson()).toList(),
      'study_recommendations':
          studyRecommendations.map((r) => r.toJson()).toList(),
      'analytics': analytics.toJson(),
      'session_id': sessionId,
      'metadata': metadata,
    };
  }
}

/// Model for related topics from API response
class RelatedTopic {
  final String id;
  final String title;
  final String description;
  final String subject;
  final List<String> grades;
  final String difficulty;
  final List<String> keywords;

  const RelatedTopic({
    required this.id,
    required this.title,
    required this.description,
    required this.subject,
    this.grades = const [],
    required this.difficulty,
    this.keywords = const [],
  });

  factory RelatedTopic.fromJson(Map<String, dynamic> json) {
    return RelatedTopic(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      subject: json['subject'] ?? '',
      grades: List<String>.from(json['grades'] ?? []),
      difficulty: json['difficulty'] ?? 'beginner',
      keywords: List<String>.from(json['keywords'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'subject': subject,
      'grades': grades,
      'difficulty': difficulty,
      'keywords': keywords,
    };
  }
}

/// Model for study recommendations from API response
class StudyRecommendation {
  final String id;
  final String title;
  final String description;
  final String actionType;
  final Map<String, dynamic> actionData;
  final String reasoning;
  final int priority;

  const StudyRecommendation({
    required this.id,
    required this.title,
    required this.description,
    required this.actionType,
    this.actionData = const {},
    required this.reasoning,
    this.priority = 1,
  });

  factory StudyRecommendation.fromJson(Map<String, dynamic> json) {
    return StudyRecommendation(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      actionType: json['action_type'] ?? '',
      actionData: Map<String, dynamic>.from(json['action_data'] ?? {}),
      reasoning: json['reasoning'] ?? '',
      priority: json['priority'] ?? 1,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'action_type': actionType,
      'action_data': actionData,
      'reasoning': reasoning,
      'priority': priority,
    };
  }
}

/// Model for intelligent chat analytics from API response
class IntelligentChatAnalytics {
  final double processingTime;
  final double confidenceScore;
  final bool educationalFocus;
  final UserContext? userContext;

  const IntelligentChatAnalytics({
    required this.processingTime,
    required this.confidenceScore,
    required this.educationalFocus,
    this.userContext,
  });

  factory IntelligentChatAnalytics.fromJson(Map<String, dynamic> json) {
    return IntelligentChatAnalytics(
      processingTime: (json['processing_time'] ?? 0.0).toDouble(),
      confidenceScore: (json['confidence_score'] ?? 0.0).toDouble(),
      educationalFocus: json['educational_focus'] ?? false,
      userContext: json['user_context'] != null
          ? UserContext.fromJson(json['user_context'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'processing_time': processingTime,
      'confidence_score': confidenceScore,
      'educational_focus': educationalFocus,
      'user_context': userContext?.toJson(),
    };
  }
}

/// Model for user context from API response
class UserContext {
  final String userId;
  final UserProfile? profile;
  final UserPreferences? preferences;
  final List<RecentActivity> recentActivities;
  final List<CurrentTask> currentTasks;

  const UserContext({
    required this.userId,
    this.profile,
    this.preferences,
    this.recentActivities = const [],
    this.currentTasks = const [],
  });

  factory UserContext.fromJson(Map<String, dynamic> json) {
    return UserContext(
      userId: json['user_id'] ?? '',
      profile: json['profile'] != null
          ? UserProfile.fromJson(json['profile'])
          : null,
      preferences: json['preferences'] != null
          ? UserPreferences.fromJson(json['preferences'])
          : null,
      recentActivities: (json['recent_activities'] as List<dynamic>?)
              ?.map((a) => RecentActivity.fromJson(a))
              .toList() ??
          [],
      currentTasks: (json['current_tasks'] as List<dynamic>?)
              ?.map((t) => CurrentTask.fromJson(t))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'profile': profile?.toJson(),
      'preferences': preferences?.toJson(),
      'recent_activities': recentActivities.map((a) => a.toJson()).toList(),
      'current_tasks': currentTasks.map((t) => t.toJson()).toList(),
    };
  }
}

/// Model for user profile from API response
class UserProfile {
  final List<String> teachingSubjects;
  final List<String> gradeLevels;

  const UserProfile({
    this.teachingSubjects = const [],
    this.gradeLevels = const [],
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      teachingSubjects: List<String>.from(json['teaching_subjects'] ?? []),
      gradeLevels: List<String>.from(json['grade_levels'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'teaching_subjects': teachingSubjects,
      'grade_levels': gradeLevels,
    };
  }
}

/// Model for user preferences from API response
class UserPreferences {
  final String learningStyle;
  final String difficultyLevel;

  const UserPreferences({
    required this.learningStyle,
    required this.difficultyLevel,
  });

  factory UserPreferences.fromJson(Map<String, dynamic> json) {
    return UserPreferences(
      learningStyle: json['learning_style'] ?? 'visual',
      difficultyLevel: json['difficulty_level'] ?? 'intermediate',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'learning_style': learningStyle,
      'difficulty_level': difficultyLevel,
    };
  }
}

/// Model for recent activity from API response
class RecentActivity {
  final String type;
  final String subject;

  const RecentActivity({
    required this.type,
    required this.subject,
  });

  factory RecentActivity.fromJson(Map<String, dynamic> json) {
    return RecentActivity(
      type: json['type'] ?? '',
      subject: json['subject'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'subject': subject,
    };
  }
}

/// Model for current task from API response
class CurrentTask {
  final String task;
  final String priority;

  const CurrentTask({
    required this.task,
    required this.priority,
  });

  factory CurrentTask.fromJson(Map<String, dynamic> json) {
    return CurrentTask(
      task: json['task'] ?? '',
      priority: json['priority'] ?? 'medium',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'task': task,
      'priority': priority,
    };
  }
}

/// Model for chat sessions - Enhanced to match API response
class ChatSession {
  final String id;
  final String title;
  final String sessionType; // Changed from 'type' to match API
  final String userId;
  final DateTime createdAt;
  final DateTime lastActivityAt; // Changed from updatedAt to match API
  final Map<String, dynamic> context;
  final int messageCount;
  final List<String> topicTags;
  final SessionSettings? settings;
  final String status;
  final bool isActive;
  final DateTime? lastMessageAt;
  final Map<String, dynamic>? metadata;

  const ChatSession({
    required this.id,
    required this.title,
    required this.sessionType,
    required this.userId,
    required this.createdAt,
    required this.lastActivityAt,
    required this.context,
    this.messageCount = 0,
    this.topicTags = const [],
    this.settings,
    this.status = 'active',
    this.isActive = true,
    this.lastMessageAt,
    this.metadata,
  });

  factory ChatSession.fromJson(Map<String, dynamic> json) {
    return ChatSession(
      id: json['id'] ?? json['session_id'] ?? '',
      title: json['title'] ?? 'Chat Session',
      sessionType: json['session_type'] ?? json['type'] ?? 'general',
      userId: json['user_id'] ?? '',
      createdAt: DateTime.parse(
          json['created_at'] ?? DateTime.now().toIso8601String()),
      lastActivityAt: DateTime.parse(json['last_activity_at'] ??
          json['updated_at'] ??
          DateTime.now().toIso8601String()),
      context: Map<String, dynamic>.from(json['context'] ?? {}),
      messageCount: json['message_count'] ?? 0,
      topicTags: List<String>.from(json['topic_tags'] ?? []),
      settings: json['settings'] != null
          ? SessionSettings.fromJson(json['settings'])
          : null,
      status: json['status'] ?? 'active',
      isActive: json['is_active'] ?? true,
      lastMessageAt: json['last_message_at'] != null
          ? DateTime.parse(json['last_message_at'])
          : null,
      metadata: json['metadata'] != null
          ? Map<String, dynamic>.from(json['metadata'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'session_type': sessionType,
      'user_id': userId,
      'created_at': createdAt.toIso8601String(),
      'last_activity_at': lastActivityAt.toIso8601String(),
      'context': context,
      'message_count': messageCount,
      'topic_tags': topicTags,
      'settings': settings?.toJson(),
      'status': status,
      'is_active': isActive,
      'last_message_at': lastMessageAt?.toIso8601String(),
      'metadata': metadata,
    };
  }

  ChatSession copyWith({
    String? id,
    String? title,
    String? sessionType,
    String? userId,
    DateTime? createdAt,
    DateTime? lastActivityAt,
    Map<String, dynamic>? context,
    int? messageCount,
    List<String>? topicTags,
    SessionSettings? settings,
    String? status,
    bool? isActive,
    DateTime? lastMessageAt,
    Map<String, dynamic>? metadata,
  }) {
    return ChatSession(
      id: id ?? this.id,
      title: title ?? this.title,
      sessionType: sessionType ?? this.sessionType,
      userId: userId ?? this.userId,
      createdAt: createdAt ?? this.createdAt,
      lastActivityAt: lastActivityAt ?? this.lastActivityAt,
      context: context ?? this.context,
      messageCount: messageCount ?? this.messageCount,
      topicTags: topicTags ?? this.topicTags,
      settings: settings ?? this.settings,
      status: status ?? this.status,
      isActive: isActive ?? this.isActive,
      lastMessageAt: lastMessageAt ?? this.lastMessageAt,
      metadata: metadata ?? this.metadata,
    );
  }
}

/// Model for session settings from API response
class SessionSettings {
  final bool enableSuggestions;
  final bool enableTopicTracking;
  final bool enablePersonalization;
  final int maxHistoryContext;
  final double creativityLevel;

  const SessionSettings({
    this.enableSuggestions = true,
    this.enableTopicTracking = true,
    this.enablePersonalization = true,
    this.maxHistoryContext = 20,
    this.creativityLevel = 0.7,
  });

  factory SessionSettings.fromJson(Map<String, dynamic> json) {
    return SessionSettings(
      enableSuggestions: json['enable_suggestions'] ?? true,
      enableTopicTracking: json['enable_topic_tracking'] ?? true,
      enablePersonalization: json['enable_personalization'] ?? true,
      maxHistoryContext: json['max_history_context'] ?? 20,
      creativityLevel: (json['creativity_level'] ?? 0.7).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'enable_suggestions': enableSuggestions,
      'enable_topic_tracking': enableTopicTracking,
      'enable_personalization': enablePersonalization,
      'max_history_context': maxHistoryContext,
      'creativity_level': creativityLevel,
    };
  }
}

/// Model for chat suggestions - Enhanced to match API response
class ChatSuggestion {
  final String id;
  final String type;
  final String content;
  final Map<String, dynamic> metadata;
  final int priority;
  final String? category;
  final double? relevanceScore;
  final String? icon;
  final String? description;

  const ChatSuggestion({
    required this.id,
    required this.type,
    required this.content,
    this.metadata = const {},
    this.priority = 1,
    this.category,
    this.relevanceScore,
    this.icon,
    this.description,
  });

  factory ChatSuggestion.fromJson(Map<String, dynamic> json) {
    return ChatSuggestion(
      id: json['id'] ?? '',
      type: json['type'] ?? 'general',
      content: json['content'] ?? json['text'] ?? json['suggestion'] ?? '',
      metadata: Map<String, dynamic>.from(json['metadata'] ?? {}),
      priority: json['priority'] ?? 1,
      category: json['category'],
      relevanceScore: json['relevance_score']?.toDouble(),
      icon: json['icon'],
      description: json['description'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'content': content,
      'metadata': metadata,
      'priority': priority,
      'category': category,
      'relevance_score': relevanceScore,
      'icon': icon,
      'description': description,
    };
  }

  // Helper getters for different suggestion types
  bool get isFollowUpQuestion => type == 'follow_up_question';
  bool get isStudySuggestion => type == 'study_suggestion';
  bool get isExplorationPrompt => type == 'exploration_prompt';
}

/// Model for personalized suggestions response from API
class PersonalizedSuggestions {
  final Map<String, List<ChatSuggestion>> suggestions;
  final int total;

  const PersonalizedSuggestions({
    this.suggestions = const {},
    this.total = 0,
  });

  factory PersonalizedSuggestions.fromJson(Map<String, dynamic> json) {
    final suggestionsData = json['suggestions'] ?? {};
    final Map<String, List<ChatSuggestion>> parsedSuggestions = {};

    suggestionsData.forEach((key, value) {
      if (value is List) {
        parsedSuggestions[key] =
            value.map((item) => ChatSuggestion.fromJson(item)).toList();
      }
    });

    return PersonalizedSuggestions(
      suggestions: parsedSuggestions,
      total: json['total'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> suggestionsJson = {};
    suggestions.forEach((key, value) {
      suggestionsJson[key] = value.map((s) => s.toJson()).toList();
    });

    return {
      'suggestions': suggestionsJson,
      'total': total,
    };
  }

  // Helper getters for accessing different types of suggestions
  List<ChatSuggestion> get studySuggestions =>
      suggestions['study_suggestion'] ?? [];

  List<ChatSuggestion> get followUpQuestions =>
      suggestions['follow_up_question'] ?? [];

  List<ChatSuggestion> get explorationPrompts =>
      suggestions['exploration_prompt'] ?? [];

  List<ChatSuggestion> get allSuggestions {
    final List<ChatSuggestion> all = [];
    suggestions.values.forEach((list) => all.addAll(list));
    return all..sort((a, b) => a.priority.compareTo(b.priority));
  }
}

/// Model for conversation analysis
class ConversationAnalysis {
  final String sessionId;
  final SentimentAnalysis sentiment;
  final TopicExtraction topics;
  final IntentRecognition intent;
  final List<String> keyInsights;
  final double engagementScore;
  final Map<String, dynamic> learningProgress;
  final List<String> recommendations;
  final DateTime analyzedAt;

  const ConversationAnalysis({
    required this.sessionId,
    required this.sentiment,
    required this.topics,
    required this.intent,
    this.keyInsights = const [],
    this.engagementScore = 0.0,
    this.learningProgress = const {},
    this.recommendations = const [],
    required this.analyzedAt,
  });

  factory ConversationAnalysis.fromJson(Map<String, dynamic> json) {
    return ConversationAnalysis(
      sessionId: json['session_id'] ?? '',
      sentiment: SentimentAnalysis.fromJson(json['sentiment'] ?? {}),
      topics: TopicExtraction.fromJson(json['topics'] ?? {}),
      intent: IntentRecognition.fromJson(json['intent'] ?? {}),
      keyInsights: List<String>.from(json['key_insights'] ?? []),
      engagementScore: (json['engagement_score'] ?? 0.0).toDouble(),
      learningProgress:
          Map<String, dynamic>.from(json['learning_progress'] ?? {}),
      recommendations: List<String>.from(json['recommendations'] ?? []),
      analyzedAt: DateTime.parse(
          json['analyzed_at'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'session_id': sessionId,
      'sentiment': sentiment.toJson(),
      'topics': topics.toJson(),
      'intent': intent.toJson(),
      'key_insights': keyInsights,
      'engagement_score': engagementScore,
      'learning_progress': learningProgress,
      'recommendations': recommendations,
      'analyzed_at': analyzedAt.toIso8601String(),
    };
  }
}

/// Model for sentiment analysis
class SentimentAnalysis {
  final String text;
  final String sentiment;
  final double confidence;
  final Map<String, double> scores;
  final List<String> emotions;
  final String context;

  const SentimentAnalysis({
    required this.text,
    required this.sentiment,
    required this.confidence,
    this.scores = const {},
    this.emotions = const [],
    this.context = 'educational_chat',
  });

  factory SentimentAnalysis.fromJson(Map<String, dynamic> json) {
    return SentimentAnalysis(
      text: json['text'] ?? '',
      sentiment: json['sentiment'] ?? 'neutral',
      confidence: (json['confidence'] ?? 0.0).toDouble(),
      scores: Map<String, double>.from(
        json['scores']?.map((k, v) => MapEntry(k, v.toDouble())) ?? {},
      ),
      emotions: List<String>.from(json['emotions'] ?? []),
      context: json['context'] ?? 'educational_chat',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'text': text,
      'sentiment': sentiment,
      'confidence': confidence,
      'scores': scores,
      'emotions': emotions,
      'context': context,
    };
  }
}

/// Model for topic extraction
class TopicExtraction {
  final List<String> messages;
  final List<String> subjects;
  final List<String> concepts;
  final List<String> keywords;
  final Map<String, double> topicScores;
  final List<String> relatedTopics;

  const TopicExtraction({
    this.messages = const [],
    this.subjects = const [],
    this.concepts = const [],
    this.keywords = const [],
    this.topicScores = const {},
    this.relatedTopics = const [],
  });

  factory TopicExtraction.fromJson(Map<String, dynamic> json) {
    return TopicExtraction(
      messages: List<String>.from(json['messages'] ?? []),
      subjects: List<String>.from(json['subjects'] ?? []),
      concepts: List<String>.from(json['concepts'] ?? []),
      keywords: List<String>.from(json['keywords'] ?? []),
      topicScores: Map<String, double>.from(
        json['topic_scores']?.map((k, v) => MapEntry(k, v.toDouble())) ?? {},
      ),
      relatedTopics: List<String>.from(json['related_topics'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'messages': messages,
      'subjects': subjects,
      'concepts': concepts,
      'keywords': keywords,
      'topic_scores': topicScores,
      'related_topics': relatedTopics,
    };
  }
}

/// Model for intent recognition
class IntentRecognition {
  final String message;
  final String intent;
  final double confidence;
  final List<String> possibleIntents;
  final Map<String, dynamic> entities;
  final Map<String, double> intentScores;

  const IntentRecognition({
    required this.message,
    required this.intent,
    required this.confidence,
    this.possibleIntents = const [],
    this.entities = const {},
    this.intentScores = const {},
  });

  factory IntentRecognition.fromJson(Map<String, dynamic> json) {
    return IntentRecognition(
      message: json['message'] ?? '',
      intent: json['intent'] ?? 'unknown',
      confidence: (json['confidence'] ?? 0.0).toDouble(),
      possibleIntents: List<String>.from(json['possible_intents'] ?? []),
      entities: Map<String, dynamic>.from(json['entities'] ?? {}),
      intentScores: Map<String, double>.from(
        json['intent_scores']?.map((k, v) => MapEntry(k, v.toDouble())) ?? {},
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'message': message,
      'intent': intent,
      'confidence': confidence,
      'possible_intents': possibleIntents,
      'entities': entities,
      'intent_scores': intentScores,
    };
  }
}

/// Model for conversation summary
class ConversationSummary {
  final String sessionId;
  final String summary;
  final List<String> keyTopics;
  final List<String> actionItems;
  final List<String> learningOutcomes;
  final int messageCount;
  final Duration duration;
  final DateTime createdAt;

  const ConversationSummary({
    required this.sessionId,
    required this.summary,
    this.keyTopics = const [],
    this.actionItems = const [],
    this.learningOutcomes = const [],
    this.messageCount = 0,
    this.duration = Duration.zero,
    required this.createdAt,
  });

  factory ConversationSummary.fromJson(Map<String, dynamic> json) {
    return ConversationSummary(
      sessionId: json['session_id'] ?? '',
      summary: json['summary'] ?? '',
      keyTopics: List<String>.from(json['key_topics'] ?? []),
      actionItems: List<String>.from(json['action_items'] ?? []),
      learningOutcomes: List<String>.from(json['learning_outcomes'] ?? []),
      messageCount: json['message_count'] ?? 0,
      duration: Duration(seconds: json['duration_seconds'] ?? 0),
      createdAt: DateTime.parse(
          json['created_at'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'session_id': sessionId,
      'summary': summary,
      'key_topics': keyTopics,
      'action_items': actionItems,
      'learning_outcomes': learningOutcomes,
      'message_count': messageCount,
      'duration_seconds': duration.inSeconds,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

/// Extended ChatMessageModel for intelligent chat features
class ChatMessageModel extends ChatMessage {
  final String? sessionId;
  final String? responseId;
  final Map<String, dynamic>? metadata;
  final double? confidence;
  final List<ChatSuggestion>? suggestions;

  const ChatMessageModel({
    required super.id,
    required super.text,
    required super.isUser,
    required super.timestamp,
    super.type = MessageType.text,
    super.status = MessageStatus.sent,
    super.voiceFilePath,
    super.voiceDuration,
    super.isFavorite = false,
    super.isSavedAsFaq = false,
    super.language,
    this.sessionId,
    this.responseId,
    this.metadata,
    this.confidence,
    this.suggestions,
  });

  factory ChatMessageModel.fromJson(Map<String, dynamic> json) {
    return ChatMessageModel(
      id: json['id'] ?? json['message_id'] ?? '',
      text: json['text'] ?? json['content'] ?? '',
      isUser: json['isUser'] ?? json['is_user'] ?? false,
      timestamp: DateTime.parse(json['timestamp'] ??
          json['created_at'] ??
          DateTime.now().toIso8601String()),
      type: MessageType.values.firstWhere(
        (e) => e.toString() == 'MessageType.${json['type']}',
        orElse: () => MessageType.text,
      ),
      status: MessageStatus.values.firstWhere(
        (e) => e.toString() == 'MessageStatus.${json['status']}',
        orElse: () => MessageStatus.sent,
      ),
      voiceFilePath: json['voiceFilePath'] ?? json['voice_file_path'],
      voiceDuration:
          json['voiceDuration'] != null || json['voice_duration'] != null
              ? Duration(
                  milliseconds:
                      json['voiceDuration'] ?? json['voice_duration'] ?? 0)
              : null,
      isFavorite: json['isFavorite'] ?? json['is_favorite'] ?? false,
      isSavedAsFaq: json['isSavedAsFaq'] ?? json['is_saved_as_faq'] ?? false,
      language: json['language'],
      sessionId: json['session_id'],
      responseId: json['response_id'],
      metadata: json['metadata'] != null
          ? Map<String, dynamic>.from(json['metadata'])
          : null,
      confidence: json['confidence']?.toDouble(),
      suggestions: json['suggestions'] != null
          ? List<ChatSuggestion>.from(
              json['suggestions'].map((s) => ChatSuggestion.fromJson(s)),
            )
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'text': text,
      'isUser': isUser,
      'timestamp': timestamp.toIso8601String(),
      'type': type.toString().split('.').last,
      'status': status.toString().split('.').last,
      'voiceFilePath': voiceFilePath,
      'voiceDuration': voiceDuration?.inMilliseconds,
      'isFavorite': isFavorite,
      'isSavedAsFaq': isSavedAsFaq,
      'language': language,
      'session_id': sessionId,
      'response_id': responseId,
      'metadata': metadata,
      'confidence': confidence,
      'suggestions': suggestions?.map((s) => s.toJson()).toList(),
    };
  }

  ChatMessageModel copyWith({
    String? id,
    String? text,
    bool? isUser,
    DateTime? timestamp,
    MessageType? type,
    MessageStatus? status,
    String? voiceFilePath,
    Duration? voiceDuration,
    bool? isFavorite,
    bool? isSavedAsFaq,
    String? language,
    String? sessionId,
    String? responseId,
    Map<String, dynamic>? metadata,
    double? confidence,
    List<ChatSuggestion>? suggestions,
  }) {
    return ChatMessageModel(
      id: id ?? this.id,
      text: text ?? this.text,
      isUser: isUser ?? this.isUser,
      timestamp: timestamp ?? this.timestamp,
      type: type ?? this.type,
      status: status ?? this.status,
      voiceFilePath: voiceFilePath ?? this.voiceFilePath,
      voiceDuration: voiceDuration ?? this.voiceDuration,
      isFavorite: isFavorite ?? this.isFavorite,
      isSavedAsFaq: isSavedAsFaq ?? this.isSavedAsFaq,
      language: language ?? this.language,
      sessionId: sessionId ?? this.sessionId,
      responseId: responseId ?? this.responseId,
      metadata: metadata ?? this.metadata,
      confidence: confidence ?? this.confidence,
      suggestions: suggestions ?? this.suggestions,
    );
  }
}
