import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/models/chat_models.dart';
import '../../data/models/intelligent_chat_models.dart' as IntelligentModels;
import '../../data/services/lazy_chat_service.dart';
import '../../core/services/service_locator.dart';

/// Optimized Chat Screen with lazy session management
/// - Only creates sessions when user sends first message
/// - Maintains session references for better UX
/// - Implements optimal session handling
class OptimizedLazyChatScreen extends StatefulWidget {
  final String? initialMessage;
  final String? sessionId;

  const OptimizedLazyChatScreen({
    super.key,
    this.initialMessage,
    this.sessionId,
  });

  @override
  State<OptimizedLazyChatScreen> createState() =>
      _OptimizedLazyChatScreenState();
}

class _OptimizedLazyChatScreenState extends State<OptimizedLazyChatScreen>
    with TickerProviderStateMixin {
  // Services
  late final LazyChatService _lazyChatService;

  // Controllers
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _textFieldFocusNode = FocusNode();

  // State variables
  final List<ChatMessageModel> _messages = [];
  bool _isLoading = false;
  bool _isTyping = false;
  bool _isInitialized = false;
  String? _currentSessionId;
  List<IntelligentModels.ChatSession> _availableSessions = [];
  IntelligentModels.UserContext? _userContext;
  IntelligentModels.PersonalizedSuggestions? _suggestions;

  // Session management
  bool _hasSessionBeenCreated = false;
  static const String _lastSessionKey = 'lazy_chat_last_session';

  @override
  void initState() {
    super.initState();
    _initializeLazyChat();
    _messageController.addListener(_onMessageChanged);
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _textFieldFocusNode.dispose();
    super.dispose();
  }

  /// Initialize the chat screen without creating sessions
  Future<void> _initializeLazyChat() async {
    try {
      print('🚀 OptimizedLazyChatScreen: Initializing lazy chat...');

      // Initialize the lazy chat service
      _lazyChatService = LazyChatService(apiClient: ServiceLocator.apiClient);
      await _lazyChatService.initialize();

      // Load available sessions (but don't create new ones)
      await _loadAvailableSessions();

      // Load user context
      await _loadUserContext();

      // If a specific session was requested, switch to it
      if (widget.sessionId != null) {
        await _switchToExistingSession(widget.sessionId!);
      } else {
        // Check if we should restore last session (but don't create it)
        await _checkForLastSession();
      }

      // Add initial message if provided
      if (widget.initialMessage != null) {
        _messageController.text = widget.initialMessage!;
      }

      setState(() {
        _isInitialized = true;
      });

      // Show welcome message only if no session is loaded
      if (_messages.isEmpty && !_hasSessionBeenCreated) {
        _addWelcomeMessage();
      }

      print('✅ Lazy chat initialized successfully');
    } catch (e) {
      print('❌ Error initializing lazy chat: $e');
      setState(() {
        _isInitialized = true;
      });
      _addWelcomeMessage();
    }
  }

  /// Load available sessions without creating new ones (sorted by latest activity)
  Future<void> _loadAvailableSessions() async {
    try {
      print('📋 Loading available sessions...');
      final sessions = await _lazyChatService.getUserSessions(limit: 20);

      // Sort sessions by latest activity (most recent first)
      sessions.sort((a, b) => b.lastActivityAt.compareTo(a.lastActivityAt));

      setState(() {
        _availableSessions = sessions;
      });
      print(
          '✅ Loaded ${sessions.length} available sessions (sorted by latest activity)');
    } catch (e) {
      print('⚠️ Could not load sessions: $e');
    }
  }

  /// Load user context
  Future<void> _loadUserContext() async {
    try {
      final context = await _lazyChatService.getUserContext();
      setState(() {
        _userContext = context;
      });
    } catch (e) {
      print('⚠️ Could not load user context: $e');
    }
  }

  /// Check for last session but don't restore it automatically
  Future<void> _checkForLastSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastSessionId = prefs.getString(_lastSessionKey);

      if (lastSessionId != null && _availableSessions.isNotEmpty) {
        final lastSession =
            _availableSessions.where((s) => s.id == lastSessionId).firstOrNull;
        if (lastSession != null) {
          print(
              '💡 Found last session: ${lastSession.title} (not auto-loading)');
          // Just show it as an option, don't load automatically
        }
      }
    } catch (e) {
      print('⚠️ Could not check last session: $e');
    }
  }

  /// Switch to an existing session
  Future<void> _switchToExistingSession(String sessionId) async {
    try {
      print('🔄 Switching to existing session: $sessionId');
      setState(() {
        _isLoading = true;
      });

      final session = await _lazyChatService.switchToSession(sessionId);

      setState(() {
        _currentSessionId = session.id;
        _hasSessionBeenCreated = true;
        _messages.clear();
      });

      // Load messages for this session
      await _loadSessionMessages(sessionId);

      // Save as last session
      await _saveLastSession(sessionId);

      print('✅ Switched to session: ${session.title}');
    } catch (e) {
      print('❌ Error switching to session: $e');
      _showErrorSnackBar('Failed to switch to session');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// Load messages for a session
  Future<void> _loadSessionMessages(String sessionId) async {
    try {
      final messages = await _lazyChatService.getSessionMessages(
        sessionId: sessionId,
        limit: 50,
      );

      setState(() {
        _messages.clear();
        _messages.addAll(messages);
      });

      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToBottom();
      });
    } catch (e) {
      print('⚠️ Could not load session messages: $e');
    }
  }

  /// Send message with lazy session creation
  Future<void> _sendMessage() async {
    final messageText = _messageController.text.trim();
    if (messageText.isEmpty || _isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      print('💬 Sending message with lazy session management');

      // Add user message to UI immediately
      final userMessage = ChatMessageModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        text: messageText,
        isUser: true,
        timestamp: DateTime.now(),
      );

      setState(() {
        _messages.add(userMessage);
        _messageController.clear();
      });

      _scrollToBottom();

      // This is where the lazy session creation happens
      // The session will only be created now, when the user actually sends a message
      final response = await _lazyChatService.sendMessage(
        message: messageText,
        context: {
          'first_message': !_hasSessionBeenCreated,
          'session_context': 'optimized_lazy_chat',
          'timestamp': DateTime.now().toIso8601String(),
        },
      );

      // Mark that session has been created
      if (!_hasSessionBeenCreated) {
        setState(() {
          _hasSessionBeenCreated = true;
          _currentSessionId = _lazyChatService.currentSessionId;
        });

        // Save the new session as last session
        if (_currentSessionId != null) {
          await _saveLastSession(_currentSessionId!);
        }

        // Refresh sessions list
        await _loadAvailableSessions();

        print('✅ Session created lazily: $_currentSessionId');
      }

      // Add AI response
      final aiMessage = ChatMessageModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        text: response.content,
        isUser: false,
        timestamp: DateTime.now(),
      );

      setState(() {
        _messages.add(aiMessage);
      });

      _scrollToBottom();

      // Load personalized suggestions
      await _loadPersonalizedSuggestions();
    } catch (e) {
      print('❌ Error sending message: $e');
      _showErrorSnackBar('Failed to send message: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// Load personalized suggestions
  Future<void> _loadPersonalizedSuggestions() async {
    try {
      if (_currentSessionId != null) {
        final suggestions = await _lazyChatService.getPersonalizedSuggestions(
          sessionId: _currentSessionId,
        );
        setState(() {
          _suggestions = suggestions;
        });
      }
    } catch (e) {
      print('⚠️ Could not load suggestions: $e');
    }
  }

  /// Save last session
  Future<void> _saveLastSession(String sessionId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_lastSessionKey, sessionId);
    } catch (e) {
      print('⚠️ Could not save last session: $e');
    }
  }

  /// Create new session explicitly
  Future<void> _createNewSession() async {
    try {
      setState(() {
        _isLoading = true;
      });

      final session = await _lazyChatService.createNewSessionExplicitly(
        title: 'New Chat ${DateTime.now().day}/${DateTime.now().month}',
      );

      setState(() {
        _currentSessionId = session.id;
        _hasSessionBeenCreated = true;
        _messages.clear();
      });

      await _saveLastSession(session.id);
      await _loadAvailableSessions();

      _addWelcomeMessage();

      print('✅ New session created explicitly: ${session.id}');
    } catch (e) {
      print('❌ Error creating new session: $e');
      _showErrorSnackBar('Failed to create new session');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _onMessageChanged() {
    // Optional: Add typing indicators or suggestions here
  }

  void _addWelcomeMessage() {
    final welcomeMessage = ChatMessageModel(
      id: 'welcome_${DateTime.now().millisecondsSinceEpoch}',
      text:
          '👋 Hello! I\'m your AI teaching assistant. Send me a message to start our conversation!',
      isUser: false,
      timestamp: DateTime.now(),
    );

    setState(() {
      _messages.add(welcomeMessage);
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToBottom();
    });
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  void _showErrorSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
          action: SnackBarAction(
            label: 'Dismiss',
            textColor: Colors.white,
            onPressed: () {
              ScaffoldMessenger.of(context).hideCurrentSnackBar();
            },
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_currentSessionId != null
            ? 'Chat • Active Session'
            : 'AI Assistant'),
        actions: [
          // Always show sessions dialog if there are available sessions
          if (_availableSessions.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.chat_bubble_outline),
              onPressed: _showSessionsDialog,
              tooltip: 'Chat History',
            ),
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            onPressed: _createNewSession,
            tooltip: 'New Chat',
          ),
        ],
      ),
      body: !_isInitialized
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Session status and history
                if (_currentSessionId == null && _availableSessions.isNotEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    color: Theme.of(context).primaryColor.withOpacity(0.1),
                    child: Row(
                      children: [
                        Icon(
                          Icons.history,
                          size: 16,
                          color: Theme.of(context).primaryColor,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'You have ${_availableSessions.length} previous conversation${_availableSessions.length > 1 ? 's' : ''}. Tap 💬 to view history.',
                            style: TextStyle(
                              color: Theme.of(context).primaryColor,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: _showSessionsDialog,
                          child: Text(
                            'View History',
                            style: TextStyle(
                              color: Theme.of(context).primaryColor,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                else if (_currentSessionId == null)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    color: Theme.of(context).primaryColor.withOpacity(0.1),
                    child: Row(
                      children: [
                        Icon(
                          Icons.chat,
                          size: 16,
                          color: Theme.of(context).primaryColor,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Start a new conversation! Type your message below.',
                            style: TextStyle(
                              color: Theme.of(context).primaryColor,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                // Messages list
                Expanded(
                  child: ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final message = _messages[index];
                      return _buildMessageBubble(message);
                    },
                  ),
                ),

                // Loading indicator
                if (_isLoading)
                  const Padding(
                    padding: EdgeInsets.all(8.0),
                    child: CircularProgressIndicator(),
                  ),

                // Message input
                _buildMessageInput(),
              ],
            ),
    );
  }

  Widget _buildMessageBubble(ChatMessageModel message) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Align(
        alignment:
            message.isUser ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.8,
          ),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: message.isUser
                ? Theme.of(context).primaryColor
                : Colors.grey[200],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            message.text,
            style: TextStyle(
              color: message.isUser ? Colors.white : Colors.black87,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        border: Border(
          top: BorderSide(color: Colors.grey[300]!),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              focusNode: _textFieldFocusNode,
              maxLines: null,
              decoration: InputDecoration(
                hintText: _currentSessionId != null
                    ? 'Type your message...'
                    : 'Start a new conversation...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
              onSubmitted: (_) => _sendMessage(),
            ),
          ),
          const SizedBox(width: 8),
          FloatingActionButton(
            onPressed: _sendMessage,
            mini: true,
            child: const Icon(Icons.send),
          ),
        ],
      ),
    );
  }

  void _showSessionsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.history),
            const SizedBox(width: 8),
            const Expanded(child: Text('Chat History')),
            Text(
              '${_availableSessions.length}',
              style:
                  const TextStyle(fontSize: 12, fontWeight: FontWeight.normal),
            ),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          height: MediaQuery.of(context).size.height * 0.5,
          child: _availableSessions.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.chat_bubble_outline,
                          size: 48, color: Colors.grey),
                      SizedBox(height: 16),
                      Text(
                        'No previous conversations',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  shrinkWrap: true,
                  itemCount: _availableSessions.length,
                  itemBuilder: (context, index) {
                    final session = _availableSessions[index];
                    final isCurrentSession = session.id == _currentSessionId;

                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      elevation: isCurrentSession ? 3 : 1,
                      color: isCurrentSession
                          ? Theme.of(context).primaryColor.withOpacity(0.1)
                          : null,
                      child: ListTile(
                        title: Text(
                          session.title,
                          style: TextStyle(
                            fontWeight: isCurrentSession
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${_formatDate(session.lastActivityAt)}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                            if (session.messageCount > 0)
                              Text(
                                '${session.messageCount} messages',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey[500],
                                ),
                              ),
                          ],
                        ),
                        leading: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: isCurrentSession
                                ? Theme.of(context).primaryColor
                                : Colors.grey[300],
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Icon(
                            isCurrentSession
                                ? Icons.chat
                                : Icons.chat_bubble_outline,
                            color: isCurrentSession
                                ? Colors.white
                                : Colors.grey[600],
                            size: 20,
                          ),
                        ),
                        trailing: isCurrentSession
                            ? Icon(
                                Icons.check_circle,
                                color: Theme.of(context).primaryColor,
                                size: 20,
                              )
                            : const Icon(
                                Icons.arrow_forward_ios,
                                size: 16,
                                color: Colors.grey,
                              ),
                        onTap: isCurrentSession
                            ? null
                            : () {
                                Navigator.pop(context);
                                _switchToExistingSession(session.id);
                              },
                      ),
                    );
                  },
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          if (_availableSessions.isNotEmpty)
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                _createNewSession();
              },
              icon: const Icon(Icons.add, size: 16),
              label: const Text('New Chat'),
            ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inMinutes < 1) {
      return 'Just now';
    } else if (diff.inMinutes < 60) {
      return '${diff.inMinutes}m ago';
    } else if (diff.inHours < 24) {
      return '${diff.inHours}h ago';
    } else if (diff.inDays == 1) {
      return 'Yesterday';
    } else if (diff.inDays < 7) {
      return '${diff.inDays} days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}
