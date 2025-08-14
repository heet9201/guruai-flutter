import '../datasources/api_service.dart';
import '../models/api_models.dart';
import '../models/chat_models.dart' as chat_models;
import '../models/intelligent_chat_models.dart';

/// Service for intelligent chat functionality with enhanced AI features
class IntelligentChatService {
  final ApiClient _apiClient;

  IntelligentChatService({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient();

  /// Send an intelligent message and get AI response with enhanced features
  Future<IntelligentChatResponse> sendIntelligentMessage({
    required String message,
    String? sessionId,
    Map<String, dynamic>? messageContext,
  }) async {
    try {
      print('🤖 Sending intelligent message: $message');
      print('🔗 Session ID: $sessionId');

      final requestData = {
        'message': message,
        if (sessionId != null) 'session_id': sessionId,
        if (messageContext != null) 'context': messageContext,
        'include_suggestions': true,
        'include_recommendations': true,
        'include_analytics': true,
      };

      final response = await _apiClient.post<Map<String, dynamic>>(
        '/chat/intelligent',
        data: requestData,
        fromJson: (json) => json,
      );

      if (response.isSuccess && response.data != null) {
        final intelligentResponse =
            IntelligentChatResponse.fromJson(response.data!);
        print(
            '✅ Intelligent response received with ${intelligentResponse.suggestions.length} suggestions');
        return intelligentResponse;
      } else {
        throw ApiError(
            message: response.error ?? 'Failed to send intelligent message');
      }
    } catch (e) {
      print('❌ Send intelligent message error: $e');
      throw ApiError(message: 'Failed to send message: $e');
    }
  }

  /// Get personalized suggestions based on user context and chat history
  Future<PersonalizedSuggestions> getPersonalizedSuggestions({
    String? sessionId,
    String? currentMessage,
  }) async {
    try {
      final requestData = {
        if (sessionId != null) 'session_id': sessionId,
        if (currentMessage != null) 'current_message': currentMessage,
      };

      print('💡 Getting personalized suggestions: $requestData');

      final response = await _apiClient.post<Map<String, dynamic>>(
        '/chat/suggestions',
        data: requestData,
        fromJson: (json) => json,
      );

      if (response.isSuccess && response.data != null) {
        final suggestions = PersonalizedSuggestions.fromJson(response.data!);
        print(
            '✅ Got personalized suggestions: ${suggestions.total} suggestions');
        return suggestions;
      } else {
        throw ApiError(message: response.error ?? 'Failed to get suggestions');
      }
    } catch (e) {
      print('❌ Get suggestions error: $e');
      throw ApiError(message: 'Failed to get suggestions: $e');
    }
  }

  /// Get typing suggestions as user types
  Future<List<String>> getTypingSuggestions({
    required String partialMessage,
    String? sessionId,
  }) async {
    try {
      if (partialMessage.length < 2) return [];

      print('⌨️ Getting typing suggestions for: $partialMessage');

      final requestData = {
        'partial_message': partialMessage,
        if (sessionId != null) 'session_id': sessionId,
      };

      final response = await _apiClient.post<Map<String, dynamic>>(
        '/chat/typing-suggestions',
        data: requestData,
        fromJson: (json) => json,
      );

      if (response.isSuccess && response.data != null) {
        final suggestionsData = response.data!['suggestions'] ?? [];
        final suggestions = List<String>.from(suggestionsData);
        print('✅ Got ${suggestions.length} typing suggestions');
        return suggestions;
      } else {
        return [];
      }
    } catch (e) {
      print('❌ Get typing suggestions error: $e');
      return [];
    }
  }

  /// Get user sessions list
  Future<List<ChatSession>> getUserSessions({
    int page = 1,
    int limit = 20,
  }) async {
    try {
      print('📋 Getting user sessions (page: $page, limit: $limit)');

      final response = await _apiClient.get<Map<String, dynamic>>(
        '/chat/sessions?page=$page&limit=$limit',
        fromJson: (json) => json,
      );

      if (response.isSuccess && response.data != null) {
        final sessionsData =
            response.data!['data'] ?? response.data!['sessions'] ?? [];
        final sessions = List<ChatSession>.from(
          sessionsData.map((session) => ChatSession.fromJson(session)),
        );
        print('✅ Got ${sessions.length} sessions');
        return sessions;
      } else {
        throw ApiError(message: response.error ?? 'Failed to get sessions');
      }
    } catch (e) {
      print('❌ Get sessions error: $e');
      throw ApiError(message: 'Failed to get sessions: $e');
    }
  }

  /// Get session message history
  Future<List<chat_models.ChatMessageModel>> getSessionMessages({
    required String sessionId,
    int page = 1,
    int limit = 50,
  }) async {
    try {
      print(
          '📜 Getting session messages: $sessionId (page: $page, limit: $limit)');

      final response = await _apiClient.get<Map<String, dynamic>>(
        '/chat/sessions/$sessionId/messages?page=$page&limit=$limit',
        fromJson: (json) => json,
      );

      if (response.isSuccess && response.data != null) {
        // Handle the nested response structure from API
        final responseData = response.data!;
        final dataSection = responseData['data'] as Map<String, dynamic>?;

        List<dynamic> messagesData;
        if (dataSection != null && dataSection.containsKey('messages')) {
          // New API format: data.messages
          messagesData = dataSection['messages'] as List<dynamic>? ?? [];
        } else {
          // Fallback for other formats
          messagesData = responseData['messages'] as List<dynamic>? ??
              responseData['data'] as List<dynamic>? ??
              [];
        }

        final messages = messagesData
            .map((messageJson) {
              try {
                return chat_models.ChatMessageModel.fromJson(
                    messageJson as Map<String, dynamic>);
              } catch (e) {
                print('⚠️ Error parsing message: $e');
                print('Message data: $messageJson');
                return null;
              }
            })
            .where((message) => message != null)
            .cast<chat_models.ChatMessageModel>()
            .toList();

        print(
            '✅ Got ${messages.length} messages from ${messagesData.length} raw messages');
        return messages;
      } else {
        throw ApiError(message: response.error ?? 'Failed to get messages');
      }
    } catch (e) {
      print('❌ Get messages error: $e');
      throw ApiError(message: 'Failed to get messages: $e');
    }
  }

  /// Get user context for personalization
  Future<UserContext?> getUserContext() async {
    try {
      print('👤 Getting user context');

      final response = await _apiClient.get<Map<String, dynamic>>(
        '/chat/user/context',
        fromJson: (json) => json,
      );

      if (response.isSuccess && response.data != null) {
        final userContext = UserContext.fromJson(response.data!);
        print(
            '✅ Got user context: ${userContext.preferences != null ? "with preferences" : "no preferences"}');
        return userContext;
      } else {
        return null;
      }
    } catch (e) {
      print('❌ Get user context error: $e');
      return null;
    }
  }

  /// Create a new chat session
  Future<ChatSession> createSession({
    String? title,
    Map<String, dynamic>? settings,
    Map<String, dynamic>? context,
  }) async {
    try {
      print('🆕 Creating new session: $title');

      final requestData = {
        if (title != null) 'title': title,
        if (settings != null) 'settings': settings,
        if (context != null) 'context': context,
      };

      final response = await _apiClient.post<Map<String, dynamic>>(
        '/chat/sessions',
        data: requestData,
        fromJson: (json) => json,
      );

      if (response.isSuccess && response.data != null) {
        final session = ChatSession.fromJson(response.data!);
        print('✅ Created session: ${session.id}');
        return session;
      } else {
        throw ApiError(message: response.error ?? 'Failed to create session');
      }
    } catch (e) {
      print('❌ Create session error: $e');
      throw ApiError(message: 'Failed to create session: $e');
    }
  }

  /// Continue or create a session (smart session management)
  Future<ChatSession> continueSession({
    String? lastSessionId,
    String? messagePreview,
    Map<String, dynamic>? context,
  }) async {
    try {
      print('🔄 Continue or create session. Last ID: $lastSessionId');

      final requestData = {
        if (lastSessionId != null) 'last_session_id': lastSessionId,
        if (messagePreview != null) 'message_preview': messagePreview,
        if (context != null) 'context': context,
      };

      final response = await _apiClient.post<Map<String, dynamic>>(
        '/chat/sessions/continue',
        data: requestData,
        fromJson: (json) => json,
      );

      if (response.isSuccess && response.data != null) {
        final session = ChatSession.fromJson(response.data!);
        print('✅ Session continued/created: ${session.id}');
        return session;
      } else {
        throw ApiError(message: response.error ?? 'Failed to continue session');
      }
    } catch (e) {
      print('❌ Continue session error: $e');
      throw ApiError(message: 'Failed to continue session: $e');
    }
  }

  /// Update session settings
  Future<ChatSession> updateSessionSettings({
    required String sessionId,
    required Map<String, dynamic> settings,
  }) async {
    try {
      print('⚙️ Updating session settings: $sessionId');

      final response = await _apiClient.put<Map<String, dynamic>>(
        '/chat/sessions/$sessionId/settings',
        data: {'settings': settings},
        fromJson: (json) => json,
      );

      if (response.isSuccess && response.data != null) {
        final session = ChatSession.fromJson(response.data!);
        print('✅ Updated session settings');
        return session;
      } else {
        throw ApiError(message: response.error ?? 'Failed to update settings');
      }
    } catch (e) {
      print('❌ Update settings error: $e');
      throw ApiError(message: 'Failed to update settings: $e');
    }
  }

  /// Delete a session
  Future<bool> deleteSession(String sessionId) async {
    try {
      print('🗑️ Deleting session: $sessionId');

      final response = await _apiClient.delete<Map<String, dynamic>>(
        '/chat/sessions/$sessionId',
        fromJson: (json) => json,
      );

      if (response.isSuccess) {
        print('✅ Session deleted');
        return true;
      } else {
        throw ApiError(message: response.error ?? 'Failed to delete session');
      }
    } catch (e) {
      print('❌ Delete session error: $e');
      return false;
    }
  }

  /// Update user preferences
  Future<bool> updateUserPreferences({
    required Map<String, dynamic> preferences,
  }) async {
    try {
      print('⚙️ Updating user preferences: $preferences');

      final response = await _apiClient.put<Map<String, dynamic>>(
        '/chat/user/preferences',
        data: {'preferences': preferences},
        fromJson: (json) => json,
      );

      if (response.isSuccess) {
        print('✅ User preferences updated');
        return true;
      } else {
        throw ApiError(
            message: response.error ?? 'Failed to update preferences');
      }
    } catch (e) {
      print('❌ Update preferences error: $e');
      return false;
    }
  }

  /// Get session analytics
  Future<Map<String, dynamic>> getSessionAnalytics({
    required String sessionId,
  }) async {
    try {
      print('📊 Getting session analytics: $sessionId');

      final response = await _apiClient.get<Map<String, dynamic>>(
        '/chat/sessions/$sessionId/analytics',
        fromJson: (json) => json,
      );

      if (response.isSuccess && response.data != null) {
        print('✅ Got session analytics');
        return response.data!;
      } else {
        throw ApiError(message: response.error ?? 'Failed to get analytics');
      }
    } catch (e) {
      print('❌ Get analytics error: $e');
      throw ApiError(message: 'Failed to get analytics: $e');
    }
  }

  /// Get conversation insights
  Future<Map<String, dynamic>> getConversationInsights({
    required String sessionId,
  }) async {
    try {
      print('🔍 Getting conversation insights: $sessionId');

      final response = await _apiClient.get<Map<String, dynamic>>(
        '/chat/sessions/$sessionId/insights',
        fromJson: (json) => json,
      );

      if (response.isSuccess && response.data != null) {
        print('✅ Got conversation insights');
        return response.data!;
      } else {
        throw ApiError(message: response.error ?? 'Failed to get insights');
      }
    } catch (e) {
      print('❌ Get insights error: $e');
      throw ApiError(message: 'Failed to get insights: $e');
    }
  }
}
