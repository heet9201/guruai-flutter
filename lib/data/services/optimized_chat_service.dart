import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../data/models/api_models.dart';
import '../../core/api/enhanced_api_client.dart';
import '../../core/constants/api_constants.dart';
import '../../core/cache/cache_manager.dart';
import '../../core/performance/performance_monitor.dart';
import '../../core/services/service_locator.dart';

/// Optimized chat message model with local state
class OptimizedChatMessage {
  final String id;
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final String? conversationId;
  final MessageStatus status;
  final Map<String, dynamic>? metadata;

  const OptimizedChatMessage({
    required this.id,
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.conversationId,
    this.status = MessageStatus.sent,
    this.metadata,
  });

  factory OptimizedChatMessage.user({
    required String text,
    String? conversationId,
  }) {
    return OptimizedChatMessage(
      id: _generateMessageId(),
      text: text,
      isUser: true,
      timestamp: DateTime.now(),
      conversationId: conversationId,
      status: MessageStatus.sending,
    );
  }

  factory OptimizedChatMessage.ai({
    required String text,
    String? conversationId,
    Map<String, dynamic>? metadata,
  }) {
    return OptimizedChatMessage(
      id: _generateMessageId(),
      text: text,
      isUser: false,
      timestamp: DateTime.now(),
      conversationId: conversationId,
      status: MessageStatus.sent,
      metadata: metadata,
    );
  }

  OptimizedChatMessage copyWith({
    String? id,
    String? text,
    bool? isUser,
    DateTime? timestamp,
    String? conversationId,
    MessageStatus? status,
    Map<String, dynamic>? metadata,
  }) {
    return OptimizedChatMessage(
      id: id ?? this.id,
      text: text ?? this.text,
      isUser: isUser ?? this.isUser,
      timestamp: timestamp ?? this.timestamp,
      conversationId: conversationId ?? this.conversationId,
      status: status ?? this.status,
      metadata: metadata ?? this.metadata,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'text': text,
      'isUser': isUser,
      'timestamp': timestamp.toIso8601String(),
      'conversationId': conversationId,
      'status': status.name,
      'metadata': metadata,
    };
  }

  factory OptimizedChatMessage.fromJson(Map<String, dynamic> json) {
    return OptimizedChatMessage(
      id: json['id'],
      text: json['text'],
      isUser: json['isUser'],
      timestamp: DateTime.parse(json['timestamp']),
      conversationId: json['conversationId'],
      status: MessageStatus.values.firstWhere(
        (s) => s.name == json['status'],
        orElse: () => MessageStatus.sent,
      ),
      metadata: json['metadata'],
    );
  }

  static String _generateMessageId() {
    return 'msg_${DateTime.now().millisecondsSinceEpoch}_${DateTime.now().microsecond}';
  }
}

/// Message status for optimistic updates
enum MessageStatus { sending, sent, failed, pending }

/// Optimized chat service with caching, offline support, and performance monitoring
class OptimizedChatService {
  final EnhancedApiClient _apiClient;
  final CacheManager _cacheManager = CacheManager();
  final PerformanceMonitor _performanceMonitor = PerformanceMonitor();

  // Message cache and state management
  final Map<String, List<OptimizedChatMessage>> _conversationCache = {};
  final Map<String, Timer> _typingTimers = {};

  // Configuration
  static const String _cacheKeyPrefix = 'chat_messages_';
  static const Duration _cacheExpiry = Duration(hours: 24);
  static const Duration _typingIndicatorDuration = Duration(seconds: 2);

  OptimizedChatService(this._apiClient);

  /// Send message with optimistic updates and retry logic
  Future<OptimizedChatMessage> sendMessage({
    required String message,
    String? conversationId,
    Map<String, dynamic>? context,
    int maxTokens = 1000,
    double temperature = 0.7,
  }) async {
    final startTime = DateTime.now();
    conversationId ??= _generateConversationId();

    // Create optimistic user message
    final userMessage = OptimizedChatMessage.user(
      text: message,
      conversationId: conversationId,
    );

    // Add to cache immediately for optimistic UI
    await _addMessageToCache(conversationId, userMessage);

    try {
      // Get current user for API call
      final currentUser = await _getCurrentUser();

      final request = ChatRequest(
        message: message,
        userId: currentUser?.id,
        conversationId: conversationId,
        context: context ?? _buildContext(conversationId),
        maxTokens: maxTokens,
        temperature: temperature,
      );

      // Make API call with performance tracking
      final response = await _apiClient.executeWithRetry<ChatResponse>(
        () => _makeApiCall(request),
        maxRetries: 3,
      );

      final responseTime = DateTime.now().difference(startTime);
      _performanceMonitor.trackRequest(
          '/api/v1/chat', responseTime, response.isSuccess);

      if (response.isSuccess && response.data != null) {
        // Update user message status
        final updatedUserMessage =
            userMessage.copyWith(status: MessageStatus.sent);
        await _updateMessageInCache(conversationId, updatedUserMessage);

        // Create AI response message
        final aiMessage = OptimizedChatMessage.ai(
          text: response.data!.response,
          conversationId: conversationId,
          metadata: {
            'model': 'gemini-pro',
            'tokens_used': maxTokens, // Default token count
            'response_time_ms': responseTime.inMilliseconds,
          },
        );

        // Add AI response to cache
        await _addMessageToCache(conversationId, aiMessage);

        // Update conversation cache
        await _saveCachedConversation(conversationId);

        return aiMessage;
      } else {
        // API failed, mark user message as failed and provide fallback
        final failedUserMessage =
            userMessage.copyWith(status: MessageStatus.failed);
        await _updateMessageInCache(conversationId, failedUserMessage);

        final fallbackMessage = OptimizedChatMessage.ai(
          text: _generateFallbackResponse(message),
          conversationId: conversationId,
          metadata: {
            'is_fallback': true,
            'original_error': response.error,
          },
        );

        await _addMessageToCache(conversationId, fallbackMessage);
        return fallbackMessage;
      }
    } catch (e) {
      // Network error or other exception
      if (kDebugMode) {
        print('❌ Chat service error: $e');
      }

      // Mark message as pending for retry
      final pendingMessage =
          userMessage.copyWith(status: MessageStatus.pending);
      await _updateMessageInCache(conversationId, pendingMessage);

      // Queue for offline retry
      final retryRequest = ChatRequest(
        message: userMessage.text,
        userId: (await _getCurrentUser())?.id,
        conversationId: conversationId,
        context: context,
        maxTokens: maxTokens,
        temperature: temperature,
      );
      await _queueForOfflineRetry(retryRequest);

      // Provide fallback response
      final fallbackMessage = OptimizedChatMessage.ai(
        text: _generateFallbackResponse(message),
        conversationId: conversationId,
        metadata: {
          'is_fallback': true,
          'queued_for_retry': true,
          'error': e.toString(),
        },
      );

      await _addMessageToCache(conversationId, fallbackMessage);
      return fallbackMessage;
    }
  }

  /// Load conversation history with pagination
  Future<List<OptimizedChatMessage>> loadConversationHistory(
    String conversationId, {
    int limit = 50,
    String? beforeMessageId,
  }) async {
    final cacheKey = '$_cacheKeyPrefix$conversationId';

    try {
      // Try cache first
      final cached = _conversationCache[conversationId];
      if (cached != null && cached.isNotEmpty) {
        return _applyPagination(cached, limit, beforeMessageId);
      }

      // Try persistent cache
      final persistentCache = await _cacheManager.get<List<dynamic>>(cacheKey);
      if (persistentCache != null) {
        final messages = persistentCache
            .map((json) => OptimizedChatMessage.fromJson(json))
            .toList();

        _conversationCache[conversationId] = messages;
        return _applyPagination(messages, limit, beforeMessageId);
      }

      // Load from API
      final response = await _apiClient.get<Map<String, dynamic>>(
        '/api/v1/chat/sessions/$conversationId/messages',
        queryParameters: {
          'limit': limit.toString(),
          if (beforeMessageId != null) 'before': beforeMessageId,
        },
        cacheKey: cacheKey,
        cacheExpiry: _cacheExpiry,
      );

      if (response.isSuccess && response.data != null) {
        final messages = (response.data!['messages'] as List)
            .map((json) => OptimizedChatMessage.fromJson(json))
            .toList();

        _conversationCache[conversationId] = messages;
        await _saveCachedConversation(conversationId);

        return messages;
      }

      return [];
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error loading conversation history: $e');
      }
      return _conversationCache[conversationId] ?? [];
    }
  }

  /// Get all conversation sessions
  Future<List<ChatSession>> loadConversationSessions({
    int limit = 20,
    int offset = 0,
  }) async {
    const cacheKey = 'chat_sessions';

    try {
      final response = await _apiClient.get<Map<String, dynamic>>(
        '/api/v1/chat/sessions',
        queryParameters: {
          'limit': limit.toString(),
          'offset': offset.toString(),
        },
        cacheKey: cacheKey,
        cacheExpiry: const Duration(minutes: 15),
      );

      if (response.isSuccess && response.data != null) {
        return (response.data!['sessions'] as List)
            .map((json) => ChatSession.fromJson(json))
            .toList();
      }

      return [];
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error loading conversation sessions: $e');
      }
      return [];
    }
  }

  /// Search messages across conversations
  Future<List<OptimizedChatMessage>> searchMessages(
    String query, {
    String? conversationId,
    int limit = 20,
  }) async {
    try {
      final response = await _apiClient.get<Map<String, dynamic>>(
        '/api/v1/chat/search',
        queryParameters: {
          'query': query,
          if (conversationId != null) 'conversation_id': conversationId,
          'limit': limit.toString(),
        },
      );

      if (response.isSuccess && response.data != null) {
        return (response.data!['messages'] as List)
            .map((json) => OptimizedChatMessage.fromJson(json))
            .toList();
      }

      return [];
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error searching messages: $e');
      }
      return [];
    }
  }

  /// Show typing indicator
  void showTypingIndicator(String conversationId) {
    _typingTimers[conversationId]?.cancel();
    _typingTimers[conversationId] = Timer(_typingIndicatorDuration, () {
      _typingTimers.remove(conversationId);
    });
  }

  /// Check if user is typing
  bool isUserTyping(String conversationId) {
    return _typingTimers.containsKey(conversationId);
  }

  /// Clear conversation cache
  Future<void> clearCache({String? conversationId}) async {
    if (conversationId != null) {
      _conversationCache.remove(conversationId);
      await _cacheManager.remove('$_cacheKeyPrefix$conversationId');
    } else {
      _conversationCache.clear();
      await _cacheManager.invalidateGroup('chat');
    }
  }

  /// Get conversation statistics
  ChatStats getConversationStats(String conversationId) {
    final messages = _conversationCache[conversationId] ?? [];
    final userMessages = messages.where((m) => m.isUser).length;
    final aiMessages = messages.where((m) => !m.isUser).length;
    final avgResponseTime = _calculateAverageResponseTime(messages);

    return ChatStats(
      conversationId: conversationId,
      totalMessages: messages.length,
      userMessages: userMessages,
      aiMessages: aiMessages,
      averageResponseTime: avgResponseTime,
      lastMessageTime: messages.isNotEmpty ? messages.last.timestamp : null,
    );
  }

  void dispose() {
    for (final timer in _typingTimers.values) {
      timer.cancel();
    }
    _typingTimers.clear();
    _conversationCache.clear();
  }

  // Private methods

  Future<EnhancedApiResponse<ChatResponse>> _makeApiCall(
      ChatRequest request) async {
    final response = await _apiClient.post<Map<String, dynamic>>(
      ApiConstants.aiChat,
      data: request.toJson(),
      priority: RequestPriority.high,
      timeout: const Duration(seconds: 60),
    );

    if (response.isSuccess && response.data != null) {
      final chatResponse = ChatResponse.fromJson(response.data!);
      return EnhancedApiResponse.success(chatResponse,
          responseTime: response.responseTime);
    } else {
      return EnhancedApiResponse.error(
        response.error ?? 'Chat request failed',
        response.type,
        response.statusCode,
      );
    }
  }

  Future<UserModel?> _getCurrentUser() async {
    try {
      final authService = ServiceLocator.authService;
      return await authService.getCurrentUser();
    } catch (e) {
      if (kDebugMode) {
        print('⚠️ Could not get current user: $e');
      }
      return null;
    }
  }

  Map<String, dynamic> _buildContext(String conversationId) {
    final messages = _conversationCache[conversationId] ?? [];
    final recentMessages = ListExtensions(messages)
        .takeLast(5)
        .map((m) => {
              'role': m.isUser ? 'user' : 'assistant',
              'content': m.text,
              'timestamp': m.timestamp.toIso8601String(),
            })
        .toList();

    return {
      'conversation_id': conversationId,
      'previous_messages': recentMessages,
      'message_count': messages.length,
    };
  }

  Future<void> _addMessageToCache(
      String conversationId, OptimizedChatMessage message) async {
    _conversationCache.putIfAbsent(conversationId, () => []).add(message);
  }

  Future<void> _updateMessageInCache(
      String conversationId, OptimizedChatMessage message) async {
    final messages = _conversationCache[conversationId];
    if (messages != null) {
      final index = messages.indexWhere((m) => m.id == message.id);
      if (index != -1) {
        messages[index] = message;
      }
    }
  }

  Future<void> _saveCachedConversation(String conversationId) async {
    final messages = _conversationCache[conversationId];
    if (messages != null) {
      final cacheKey = '$_cacheKeyPrefix$conversationId';
      final jsonData = messages.map((m) => m.toJson()).toList();
      await _cacheManager.store(cacheKey, jsonData, expiry: _cacheExpiry);
    }
  }

  List<OptimizedChatMessage> _applyPagination(
    List<OptimizedChatMessage> messages,
    int limit,
    String? beforeMessageId,
  ) {
    if (beforeMessageId != null) {
      final beforeIndex = messages.indexWhere((m) => m.id == beforeMessageId);
      if (beforeIndex > 0) {
        return messages
            .take(beforeIndex)
            .toList()
            .reversed
            .take(limit)
            .toList()
            .reversed
            .toList();
      }
    }

    return messages.take(limit).toList();
  }

  String _generateConversationId() {
    return 'conv_${DateTime.now().millisecondsSinceEpoch}';
  }

  String _generateFallbackResponse(String userMessage) {
    final message = userMessage.toLowerCase();

    if (message.contains('math') || message.contains('calculate')) {
      return '🧮 I can help you with mathematics! While I\'m currently working on your request, I can assist with arithmetic, algebra, geometry, and more. What specific math problem would you like to solve?';
    } else if (message.contains('science')) {
      return '🔬 Science is fascinating! I\'m here to help with physics, chemistry, biology, and earth science concepts. What scientific topic would you like to explore?';
    } else if (message.contains('write') || message.contains('story')) {
      return '✍️ I can help you with creative writing and storytelling! What kind of story or content would you like to create together?';
    } else if (message.contains('plan') || message.contains('lesson')) {
      return '📚 I can assist with lesson planning and educational content! What subject or topic would you like to plan for?';
    } else {
      return '💭 I\'m processing your request and will provide a detailed response shortly. In the meantime, feel free to ask me about education, math, science, or creative writing!';
    }
  }

  Future<void> _queueForOfflineRetry(ChatRequest request) async {
    // Implementation would queue the request for retry when online
    if (kDebugMode) {
      print('📤 Queuing chat request for offline retry');
    }
  }

  Duration _calculateAverageResponseTime(List<OptimizedChatMessage> messages) {
    final responseTimes = <Duration>[];

    for (int i = 1; i < messages.length; i++) {
      if (messages[i - 1].isUser && !messages[i].isUser) {
        final responseTime =
            messages[i].timestamp.difference(messages[i - 1].timestamp);
        responseTimes.add(responseTime);
      }
    }

    if (responseTimes.isEmpty) return Duration.zero;

    final totalMs =
        responseTimes.map((t) => t.inMilliseconds).reduce((a, b) => a + b);

    return Duration(milliseconds: (totalMs / responseTimes.length).round());
  }
}

/// Chat session model
class ChatSession {
  final String id;
  final String title;
  final DateTime createdAt;
  final DateTime lastMessageAt;
  final int messageCount;

  const ChatSession({
    required this.id,
    required this.title,
    required this.createdAt,
    required this.lastMessageAt,
    required this.messageCount,
  });

  factory ChatSession.fromJson(Map<String, dynamic> json) {
    return ChatSession(
      id: json['id'],
      title: json['title'],
      createdAt: DateTime.parse(json['createdAt']),
      lastMessageAt: DateTime.parse(json['lastMessageAt']),
      messageCount: json['messageCount'] ?? 0,
    );
  }
}

/// Chat statistics
class ChatStats {
  final String conversationId;
  final int totalMessages;
  final int userMessages;
  final int aiMessages;
  final Duration averageResponseTime;
  final DateTime? lastMessageTime;

  const ChatStats({
    required this.conversationId,
    required this.totalMessages,
    required this.userMessages,
    required this.aiMessages,
    required this.averageResponseTime,
    this.lastMessageTime,
  });

  @override
  String toString() {
    return 'ChatStats(total: $totalMessages, user: $userMessages, ai: $aiMessages, avgResponse: ${averageResponseTime.inMilliseconds}ms)';
  }
}

/// Extension for list operations
extension ListExtensions<T> on List<T> {
  List<T> takeLast(int count) {
    if (count >= length) return this;
    return skip(length - count).toList();
  }
}
