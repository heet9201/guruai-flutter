import '../datasources/api_service.dart';
import '../models/intelligent_chat_models.dart' as IntelligentModels;
import '../models/chat_models.dart';
import 'intelligent_chat_service_final.dart';

/// Lazy Chat Service that implements optimal session management
/// - Only creates sessions when user actually sends a message
/// - Maintains session references for better UX
/// - Implements smart session continuation
class LazyChatService {
  final IntelligentChatService _intelligentChatService;

  // Session state management
  String? _pendingSessionId;
  String? _lastKnownSessionId;
  bool _isSessionCreationInProgress = false;

  // Message queue for when session is being created
  final List<String> _messageQueue = [];

  LazyChatService({ApiClient? apiClient})
      : _intelligentChatService = IntelligentChatService(apiClient: apiClient);

  /// Initialize the service and load last session reference (if any)
  Future<void> initialize() async {
    try {
      print('🚀 LazyChatService: Initializing...');
      await _loadLastSessionReference();
      print(
          '✅ LazyChatService: Initialized with last session: $_lastKnownSessionId');
    } catch (e) {
      print('⚠️ LazyChatService: Initialization warning: $e');
    }
  }

  /// Load the last session ID from storage without creating a session
  Future<void> _loadLastSessionReference() async {
    try {
      // Try to get the last session from local storage
      final sessions = await _intelligentChatService.getUserSessions(limit: 1);
      if (sessions.isNotEmpty) {
        _lastKnownSessionId = sessions.first.id;
        print('📝 Found last session reference: $_lastKnownSessionId');
      }
    } catch (e) {
      print('⚠️ Could not load last session reference: $e');
    }
  }

  /// Get existing sessions without creating new ones
  Future<List<IntelligentModels.ChatSession>> getUserSessions(
      {int limit = 50}) async {
    return await _intelligentChatService.getUserSessions(limit: limit);
  }

  /// Get session messages only if session exists
  Future<List<ChatMessageModel>> getSessionMessages({
    required String sessionId,
    int page = 1,
    int limit = 50,
  }) async {
    return await _intelligentChatService.getSessionMessages(
      sessionId: sessionId,
      page: page,
      limit: limit,
    );
  }

  /// Smart session management - only create when needed
  Future<IntelligentModels.ChatSession> _ensureSession({
    String? messagePreview,
    Map<String, dynamic>? context,
  }) async {
    // If session creation is already in progress, wait for it
    if (_isSessionCreationInProgress) {
      print('⏳ Session creation in progress, waiting...');
      // Poll until session is ready
      while (_isSessionCreationInProgress) {
        await Future.delayed(const Duration(milliseconds: 100));
      }
      if (_pendingSessionId != null) {
        // Try to find the session in user sessions
        final sessions =
            await _intelligentChatService.getUserSessions(limit: 100);
        final session = sessions.firstWhere((s) => s.id == _pendingSessionId);
        return session;
      }
    }

    // If we already have a pending session, validate it still exists
    if (_pendingSessionId != null) {
      try {
        final sessions =
            await _intelligentChatService.getUserSessions(limit: 100);
        final session = sessions.firstWhere((s) => s.id == _pendingSessionId);
        return session;
      } catch (e) {
        print('⚠️ Pending session not found, will create new one');
        _pendingSessionId = null;
      }
    }

    _isSessionCreationInProgress = true;

    try {
      print('🔄 Creating session lazily for first message...');

      IntelligentModels.ChatSession session;

      // Try to continue from last known session if it exists
      if (_lastKnownSessionId != null) {
        try {
          session = await _intelligentChatService.continueSession(
            lastSessionId: _lastKnownSessionId,
            messagePreview: messagePreview,
            context: context ??
                {
                  'lazy_creation': true,
                  'triggered_by': 'user_message',
                  'timestamp': DateTime.now().toIso8601String(),
                },
          );
          print('✅ Continued from last session: ${session.id}');
        } catch (e) {
          print('⚠️ Could not continue last session, creating new one: $e');
          session = await _intelligentChatService.createNewSession(
            title: _generateSessionTitle(messagePreview),
            sessionType: 'educational_chat',
            context: context,
          );
          print('✅ Created new session: ${session.id}');
        }
      } else {
        // Create completely new session
        session = await _intelligentChatService.createNewSession(
          title: _generateSessionTitle(messagePreview),
          sessionType: 'educational_chat',
          context: context ??
              {
                'lazy_creation': true,
                'triggered_by': 'user_message',
                'timestamp': DateTime.now().toIso8601String(),
              },
        );
        print('✅ Created fresh session: ${session.id}');
      }

      _pendingSessionId = session.id;
      _lastKnownSessionId = session.id;

      return session;
    } finally {
      _isSessionCreationInProgress = false;
    }
  }

  /// Generate intelligent session title based on first message
  String _generateSessionTitle(String? messagePreview) {
    if (messagePreview == null || messagePreview.isEmpty) {
      final now = DateTime.now();
      return 'Chat ${now.day}/${now.month} ${now.hour}:${now.minute.toString().padLeft(2, '0')}';
    }

    // Extract key words for title
    final words = messagePreview.split(' ').take(4).join(' ');
    return words.length > 30 ? '${words.substring(0, 30)}...' : words;
  }

  /// Send message with lazy session creation
  Future<IntelligentModels.IntelligentChatResponse> sendMessage({
    required String message,
    Map<String, dynamic>? context,
    int maxTokens = 1000,
    double temperature = 0.7,
  }) async {
    try {
      print('💬 LazyChatService: Sending message (lazy session mode)');

      // Ensure we have a session (create only if needed)
      final session = await _ensureSession(
        messagePreview: message,
        context: context,
      );

      print('📤 Sending message to session: ${session.id}');

      // Send the actual message using intelligent chat
      final response = await _intelligentChatService.sendIntelligentMessage(
        message: message,
        sessionId: session.id,
        messageContext: context,
      );

      print('✅ Message sent successfully');
      return response;
    } catch (e) {
      print('❌ Error sending message: $e');
      rethrow;
    }
  }

  /// Switch to an existing session without creating new ones
  Future<IntelligentModels.ChatSession> switchToSession(
      String sessionId) async {
    try {
      print('🔄 Switching to existing session: $sessionId');

      // Find the session in user sessions
      final sessions =
          await _intelligentChatService.getUserSessions(limit: 100);
      final session = sessions.firstWhere(
        (s) => s.id == sessionId,
        orElse: () => throw Exception('Session not found'),
      );

      _pendingSessionId = sessionId;
      _lastKnownSessionId = sessionId;

      print('✅ Switched to session: ${session.title}');
      return session;
    } catch (e) {
      print('❌ Error switching to session: $e');
      rethrow;
    }
  }

  /// Create a new session explicitly (when user wants to start fresh)
  Future<IntelligentModels.ChatSession> createNewSessionExplicitly({
    String? title,
    String sessionType = 'educational_chat',
    Map<String, dynamic>? context,
  }) async {
    try {
      print('🆕 Creating new session explicitly...');

      final session = await _intelligentChatService.createNewSession(
        title:
            title ?? 'New Chat ${DateTime.now().day}/${DateTime.now().month}',
        sessionType: sessionType,
        context: context ??
            {
              'explicit_creation': true,
              'user_initiated': true,
              'timestamp': DateTime.now().toIso8601String(),
            },
      );

      _pendingSessionId = session.id;
      _lastKnownSessionId = session.id;

      print('✅ New session created: ${session.id}');
      return session;
    } catch (e) {
      print('❌ Error creating new session: $e');
      rethrow;
    }
  }

  /// Get current session info without creating one
  String? get currentSessionId => _pendingSessionId;
  String? get lastKnownSessionId => _lastKnownSessionId;
  bool get hasActiveSession => _pendingSessionId != null;

  /// Clear session state (for logout, etc.)
  void clearSessionState() {
    print('🧹 Clearing session state');
    _pendingSessionId = null;
    _lastKnownSessionId = null;
    _messageQueue.clear();
    _isSessionCreationInProgress = false;
  }

  /// Get user context
  Future<IntelligentModels.UserContext?> getUserContext() async {
    return await _intelligentChatService.getUserContext();
  }

  /// Get personalized suggestions
  Future<IntelligentModels.PersonalizedSuggestions> getPersonalizedSuggestions({
    String? sessionId,
    String? currentMessage,
  }) async {
    return await _intelligentChatService.getPersonalizedSuggestions(
      sessionId: sessionId,
      currentMessage: currentMessage,
    );
  }

  /// Generate summary without creating session
  Future<String> generateSummary(String text) async {
    // Since generateSummary is not available, we'll use the intelligent chat for this
    final response = await _intelligentChatService.sendIntelligentMessage(
      message: 'Please provide a concise summary of the following text: $text',
    );
    return response.content;
  }
}
