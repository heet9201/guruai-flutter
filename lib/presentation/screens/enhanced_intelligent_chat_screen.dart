import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/models/chat_models.dart' as chat_models;
import '../../data/models/intelligent_chat_models.dart' as intelligent_models;
import '../../data/services/intelligent_chat_service_final.dart';
import '../../domain/entities/chat_message.dart';

/// Enhanced intelligent chat screen with comprehensive AI features
class EnhancedIntelligentChatScreen extends StatefulWidget {
  final String? initialMessage;

  const EnhancedIntelligentChatScreen({
    super.key,
    this.initialMessage,
  });

  @override
  State<EnhancedIntelligentChatScreen> createState() =>
      _EnhancedIntelligentChatScreenState();
}

class _EnhancedIntelligentChatScreenState
    extends State<EnhancedIntelligentChatScreen> with TickerProviderStateMixin {
  // Controllers and Services
  final IntelligentChatService _chatService = IntelligentChatService();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _textFieldFocusNode = FocusNode();

  // State variables
  final List<chat_models.ChatMessageModel> _messages = [];
  bool _isLoading = false;
  bool _isTyping = false;
  bool _isLoadingMoreMessages = false;
  bool _hasMoreMessages = true;
  List<String> _typingSuggestions = [];
  bool _showTypingSuggestions = false;

  // Session Management
  String? _currentSessionId;
  List<intelligent_models.ChatSession> _sessions = [];
  intelligent_models.ChatSession? _currentSession;
  intelligent_models.UserContext? _userContext;
  intelligent_models.PersonalizedSuggestions? _personalizedSuggestions;

  // Constants
  static const String _lastSessionKey = 'last_session_id';

  @override
  void initState() {
    super.initState();
    _initializeChat();
    _messageController.addListener(_onMessageChanged);
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _textFieldFocusNode.dispose();
    super.dispose();
  }

  Future<void> _initializeChat() async {
    await _loadUserContext();
    await _loadUserSessions();
    await _continueOrCreateSession();
    await _loadPersonalizedSuggestions();
  }

  Future<void> _loadUserContext() async {
    try {
      print('👤 Loading user context...');
      final context = await _chatService.getUserContext();
      setState(() {
        _userContext = context;
      });
    } catch (e) {
      print('Error loading user context: $e');
    }
  }

  Future<void> _loadUserSessions() async {
    try {
      print('📋 Loading user sessions...');
      final sessions = await _chatService.getUserSessions(limit: 50);
      setState(() {
        _sessions.clear();
        _sessions.addAll(sessions);
        if (_currentSessionId != null &&
            !_sessions.any((s) => s.id == _currentSessionId)) {
          print(
              '⚠️ Current session not found in sessions list, refreshing current session');
          _refreshCurrentSession();
        }
      });
      print('✅ Loaded ${sessions.length} sessions');
    } catch (e) {
      print('❌ Error loading sessions: $e');
      _showErrorSnackBar('Failed to load sessions: $e');
    }
  }

  Future<void> _refreshCurrentSession() async {
    if (_currentSessionId == null) return;

    try {
      final sessions = await _chatService.getUserSessions(limit: 50);
      final currentSession = sessions
          .where((session) => session.id == _currentSessionId)
          .firstOrNull;

      if (currentSession != null) {
        setState(() {
          _currentSession = currentSession;
        });
      }
    } catch (e) {
      print('❌ Error refreshing current session: $e');
    }
  }

  Future<void> _loadPersonalizedSuggestions() async {
    try {
      print('💡 Loading personalized suggestions...');
      final suggestions = await _chatService.getPersonalizedSuggestions(
        sessionId: _currentSessionId,
        currentMessage: _messages.isNotEmpty ? _messages.last.text : null,
      );

      setState(() {
        _personalizedSuggestions = suggestions;
      });
    } catch (e) {
      print('Error loading personalized suggestions: $e');
    }
  }

  Future<void> _continueOrCreateSession() async {
    try {
      print('🔄 Starting session continuation/creation');
      final prefs = await SharedPreferences.getInstance();
      final lastSessionId = prefs.getString(_lastSessionKey);

      intelligent_models.ChatSession session;

      try {
        session = await _chatService.continueSession(
          lastSessionId: lastSessionId,
          messagePreview: widget.initialMessage,
          context: {
            'app_context': 'flutter_app',
            'feature': 'enhanced_chat',
            'timestamp': DateTime.now().toIso8601String(),
          },
        );
        print('✅ Session obtained via continue API: ${session.id}');
      } catch (continueError) {
        print('⚠️ Continue session failed: $continueError');
        session = await _chatService.createNewSession(
          title: 'New Chat Session',
          sessionType: 'educational_chat',
        );
        print('✅ Created new session as fallback: ${session.id}');
      }

      setState(() {
        _currentSession = session;
        _currentSessionId = session.id;
      });

      await _saveLastSession(session.id);

      try {
        final messages = await _chatService.getSessionMessages(
          sessionId: session.id,
          page: 1,
          limit: 50,
        );
        setState(() {
          _messages.clear();
          _messages.addAll(messages);
        });
        print('✅ Loaded ${messages.length} messages from session');
      } catch (e) {
        print('⚠️ Could not load session messages: $e');
      }

      if (_messages.isEmpty) {
        _addWelcomeMessage();
      }

      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToBottom();
      });
    } catch (e) {
      print('❌ Error in session continuation: $e');

      try {
        final fallbackSession = await _chatService.createNewSession(
          title: 'Emergency Session',
          sessionType: 'general',
        );
        print('✅ Created fallback session: ${fallbackSession.id}');
        setState(() {
          _currentSession = fallbackSession;
          _currentSessionId = fallbackSession.id;
        });
      } catch (fallbackError) {
        print('❌ Fallback session creation failed: $fallbackError');
      }

      _addWelcomeMessage();
    }
  }

  Future<void> _createNewSession() async {
    try {
      print('🆕 Creating new session...');

      final session = await _chatService.createNewSession(
        title: 'New Chat - ${DateTime.now().day}/${DateTime.now().month}',
        sessionType: 'educational_chat',
        context: {
          'created_from': 'user_action',
          'timestamp': DateTime.now().toIso8601String(),
        },
        settings: {
          'enable_personalization': true,
          'enable_suggestions': true,
          'creativity_level': 0.7,
        },
      );

      setState(() {
        _currentSession = session;
        _currentSessionId = session.id;
        _messages.clear();
        _sessions.insert(0, session);
      });

      print('✅ New session created: ${session.id}');
      await _saveLastSession(session.id);
      _addWelcomeMessage();
    } catch (e) {
      print('❌ Failed to create session via API: $e');
      _showErrorSnackBar('Failed to create new session');
    }
  }

  void _addWelcomeMessage() {
    final welcomeMessage = chat_models.ChatMessageModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      text:
          "Hello! I'm your intelligent AI assistant. I can help you with personalized learning, create lesson plans, suggest activities, and provide contextual educational support. How can I assist you today?",
      isUser: false,
      timestamp: DateTime.now(),
      type: MessageType.text,
      status: MessageStatus.sent,
    );

    setState(() {
      _messages.add(welcomeMessage);
    });
  }

  Future<void> _sendMessage({String? messageText}) async {
    final text = messageText ?? _messageController.text.trim();
    if (text.isEmpty) return;

    try {
      print('📤 Sending message: $text');

      final userMessage = chat_models.ChatMessageModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        text: text,
        isUser: true,
        timestamp: DateTime.now(),
        type: MessageType.text,
        status: MessageStatus.sent,
      );

      setState(() {
        _messages.add(userMessage);
        _isTyping = true;
        _showTypingSuggestions = false;
        _typingSuggestions.clear();
      });

      _messageController.clear();
      _scrollToBottom();

      final messageContext = {
        'user_context': _userContext?.toJson(),
        'recent_messages':
            _messages.takeLast(5).map((m) => m.toJson()).toList(),
        'session_id': _currentSessionId,
        'timestamp': DateTime.now().toIso8601String(),
      };

      final intelligentResponse = await _chatService.sendIntelligentMessage(
        message: text,
        sessionId: _currentSessionId,
        messageContext: messageContext,
      );

      final aiMessage = chat_models.ChatMessageModel(
        id: intelligentResponse.messageId,
        text: intelligentResponse.content,
        isUser: false,
        timestamp: DateTime.now(),
        type: MessageType.text,
        status: MessageStatus.sent,
      );

      setState(() {
        _messages.add(aiMessage);
        _isTyping = false;
      });

      _scrollToBottom();
      await _loadPersonalizedSuggestions();
    } catch (e) {
      setState(() {
        _isTyping = false;
      });
      print('❌ Send message error: $e');
      _showErrorSnackBar('Failed to send message: $e');
    }
  }

  void _onMessageChanged() {
    final text = _messageController.text;
    if (text.length >= 2) {
      _getTypingSuggestions(text);
    } else {
      setState(() {
        _showTypingSuggestions = false;
        _typingSuggestions.clear();
      });
    }
  }

  Future<void> _getTypingSuggestions(String text) async {
    try {
      final suggestions = await _chatService.getTypingSuggestions(
        partialMessage: text,
        sessionId: _currentSessionId,
      );

      setState(() {
        _typingSuggestions = suggestions;
        _showTypingSuggestions = suggestions.isNotEmpty;
      });
    } catch (e) {
      print('Error getting typing suggestions: $e');
    }
  }

  Future<void> _saveLastSession(String sessionId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_lastSessionKey, sessionId);
    } catch (e) {
      print('Error saving last session: $e');
    }
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

  Future<void> _loadMoreMessages() async {
    if (_isLoadingMoreMessages ||
        !_hasMoreMessages ||
        _currentSessionId == null) return;

    try {
      setState(() {
        _isLoadingMoreMessages = true;
      });

      final currentPage = (_messages.length / 50).ceil() + 1;
      print('📜 Loading more messages, page: $currentPage');

      final moreMessages = await _chatService.getSessionMessages(
        sessionId: _currentSessionId!,
        page: currentPage,
        limit: 50,
      );

      setState(() {
        if (moreMessages.isNotEmpty) {
          _messages.insertAll(0, moreMessages.reversed);
          print('✅ Loaded ${moreMessages.length} more messages');
        } else {
          _hasMoreMessages = false;
          print('📭 No more messages to load');
        }
        _isLoadingMoreMessages = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingMoreMessages = false;
      });
      print('❌ Error loading more messages: $e');
    }
  }

  Future<void> _refreshMessages() async {
    if (_currentSessionId == null) return;

    try {
      final messages = await _chatService.getSessionMessages(
        sessionId: _currentSessionId!,
        page: 1,
        limit: 50,
      );

      setState(() {
        _messages.clear();
        _messages.addAll(messages);
        _hasMoreMessages = messages.length >= 50;
      });

      print('🔄 Refreshed ${messages.length} messages');
    } catch (e) {
      print('❌ Error refreshing messages: $e');
    }
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  // Helper method to get session type icon
  IconData _getSessionIcon(String? sessionType) {
    switch (sessionType?.toLowerCase()) {
      case 'general':
        return Icons.chat_bubble_outline;
      case 'academic':
      case 'education':
        return Icons.school;
      case 'technical':
      case 'coding':
        return Icons.code;
      case 'creative':
        return Icons.palette;
      case 'research':
        return Icons.search;
      case 'analysis':
        return Icons.analytics;
      default:
        return Icons.chat;
    }
  }

  void _showErrorSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error, color: Colors.white),
              const SizedBox(width: 8),
              Expanded(child: Text(message)),
            ],
          ),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Icon(Icons.psychology, color: theme.primaryColor),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _currentSession?.title ?? 'Intelligent Chat',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Row(
                    children: [
                      if (_currentSession != null)
                        Icon(
                          _getSessionIcon(_currentSession!.sessionType),
                          size: 12,
                          color: theme.colorScheme.onSurface.withOpacity(0.6),
                        ),
                      if (_currentSession != null) const SizedBox(width: 4),
                      Text(
                        _currentSession != null
                            ? '${_messages.length} messages'
                            : 'Ready to chat',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.history),
                onPressed: () => _showSessionsDrawer(),
                tooltip: 'Chat History (${_sessions.length} sessions)',
              ),
              if (_sessions.isNotEmpty)
                Positioned(
                  right: 6,
                  top: 6,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: theme.primaryColor,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 18,
                      minHeight: 18,
                    ),
                    child: Text(
                      _sessions.length > 99 ? '99+' : '${_sessions.length}',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            onPressed: _createNewSessionAndSwitch,
            tooltip: 'New Chat',
          ),
        ],
      ),
      body: Column(
        children: [
          if (_userContext != null) _buildUserContextBanner(),
          if (_personalizedSuggestions != null && _messages.isEmpty)
            _buildPersonalizedSuggestions(),
          Expanded(
            child: Stack(
              children: [
                Column(
                  children: [
                    Expanded(
                      child: ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.all(16),
                        itemCount:
                            _messages.length + (_isLoadingMoreMessages ? 1 : 0),
                        itemBuilder: (context, index) {
                          if (_isLoadingMoreMessages && index == 0) {
                            return const Center(
                              child: Padding(
                                padding: EdgeInsets.all(16),
                                child: CircularProgressIndicator(),
                              ),
                            );
                          }

                          final messageIndex =
                              _isLoadingMoreMessages ? index - 1 : index;
                          final message = _messages[messageIndex];

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: _buildMessageBubble(message),
                          );
                        },
                      ),
                    ),
                    if (_isTyping) _buildTypingIndicator(),
                  ],
                ),
                if (_isLoading)
                  Container(
                    color: Colors.black.withOpacity(0.3),
                    child: const Center(
                      child: CircularProgressIndicator(),
                    ),
                  ),
              ],
            ),
          ),
          if (_showTypingSuggestions && _typingSuggestions.isNotEmpty)
            _buildTypingSuggestions(),
          _buildInputArea(),
        ],
      ),
    );
  }

  Widget _buildUserContextBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor.withOpacity(0.1),
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).primaryColor.withOpacity(0.2),
          ),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.person,
            size: 16,
            color: Theme.of(context).primaryColor,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Personalized for ${_userContext?.preferences?.toJson()['name'] ?? 'You'} • ${_userContext?.preferences?.toJson()['subject'] ?? 'General Learning'}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).primaryColor,
                    fontWeight: FontWeight.w500,
                  ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPersonalizedSuggestions() {
    return Container(
      height: 120,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Suggested for you',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _personalizedSuggestions!.allSuggestions.length,
              itemBuilder: (context, index) {
                final suggestion =
                    _personalizedSuggestions!.allSuggestions[index];
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ActionChip(
                    label: Text(
                      suggestion.content,
                      style: const TextStyle(fontSize: 12),
                    ),
                    onPressed: () =>
                        _sendMessage(messageText: suggestion.content),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(chat_models.ChatMessageModel message) {
    final theme = Theme.of(context);
    final isUser = message.isUser;

    return Row(
      mainAxisAlignment:
          isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!isUser) ...[
          CircleAvatar(
            radius: 16,
            backgroundColor: theme.primaryColor,
            child: const Icon(
              Icons.psychology,
              size: 16,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 8),
        ],
        Flexible(
          child: Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.75,
            ),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isUser ? theme.primaryColor : theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(16),
              border: !isUser
                  ? Border.all(
                      color: theme.dividerColor,
                    )
                  : null,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  message.text,
                  style: TextStyle(
                    color: isUser
                        ? Colors.white
                        : theme.textTheme.bodyLarge?.color,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _formatTimestamp(message.timestamp),
                  style: TextStyle(
                    fontSize: 10,
                    color: isUser
                        ? Colors.white.withOpacity(0.7)
                        : theme.textTheme.bodySmall?.color,
                  ),
                ),
              ],
            ),
          ),
        ),
        if (isUser) ...[
          const SizedBox(width: 8),
          CircleAvatar(
            radius: 16,
            backgroundColor: theme.colorScheme.secondary,
            child: const Icon(
              Icons.person,
              size: 16,
              color: Colors.white,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildTypingIndicator() {
    return Row(
      children: [
        CircleAvatar(
          radius: 16,
          backgroundColor: Theme.of(context).primaryColor,
          child: const Icon(
            Icons.psychology,
            size: 16,
            color: Colors.white,
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Theme.of(context).dividerColor,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Theme.of(context).primaryColor,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'AI is thinking...',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTypingSuggestions() {
    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _typingSuggestions.length,
        itemBuilder: (context, index) {
          final suggestion = _typingSuggestions[index];
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ActionChip(
              label: Text(
                suggestion,
                style: const TextStyle(fontSize: 12),
              ),
              onPressed: () {
                _messageController.text = suggestion;
                setState(() {
                  _showTypingSuggestions = false;
                });
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        border: Border(
          top: BorderSide(
            color: Theme.of(context).dividerColor,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              focusNode: _textFieldFocusNode,
              decoration: InputDecoration(
                hintText: 'Ask me anything...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
              maxLines: null,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _sendMessage(),
            ),
          ),
          const SizedBox(width: 8),
          FloatingActionButton(
            mini: true,
            onPressed: _isTyping ? null : () => _sendMessage(),
            child: _isTyping
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Icon(Icons.send),
          ),
        ],
      ),
    );
  }

  void _showSessionsDrawer() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _buildSessionsBottomSheet(),
    );
  }

  Widget _buildSessionsBottomSheet() {
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.9,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.only(top: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Theme.of(context).dividerColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(
                      Icons.history,
                      color: Theme.of(context).primaryColor,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Chat Sessions',
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          Text(
                            '${_sessions.length} conversation${_sessions.length != 1 ? 's' : ''}',
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.color
                                          ?.withOpacity(0.7),
                                    ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () async {
                        Navigator.pop(context);
                        await _createNewSessionAndSwitch();
                      },
                      icon: Icon(
                        Icons.add_circle,
                        color: Theme.of(context).primaryColor,
                        size: 28,
                      ),
                      tooltip: 'New Chat',
                    ),
                  ],
                ),
              ),
              Expanded(
                child: _sessions.isEmpty
                    ? _buildEmptySessionsState()
                    : ListView.builder(
                        controller: scrollController,
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        itemCount: _sessions.length,
                        itemBuilder: (context, index) {
                          final session = _sessions[index];
                          final isCurrentSession =
                              session.id == _currentSessionId;
                          return _buildSessionTile(session, isCurrentSession);
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEmptySessionsState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.chat_bubble_outline,
            size: 64,
            color: Theme.of(context).dividerColor,
          ),
          const SizedBox(height: 16),
          Text(
            'No conversations yet',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.color
                      ?.withOpacity(0.7),
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Start a new conversation to see it here',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.color
                      ?.withOpacity(0.5),
                ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () async {
              Navigator.pop(context);
              await _createNewSessionAndSwitch();
            },
            icon: const Icon(Icons.add),
            label: const Text('Start New Chat'),
          ),
        ],
      ),
    );
  }

  Widget _buildSessionTile(
      intelligent_models.ChatSession session, bool isCurrentSession) {
    final messageCount = session.messageCount;
    final lastActivity = session.lastActivityAt;
    final timeDiff = DateTime.now().difference(lastActivity);
    String timeAgo;

    if (timeDiff.inDays > 0) {
      timeAgo = '${timeDiff.inDays}d ago';
    } else if (timeDiff.inHours > 0) {
      timeAgo = '${timeDiff.inHours}h ago';
    } else if (timeDiff.inMinutes > 0) {
      timeAgo = '${timeDiff.inMinutes}m ago';
    } else {
      timeAgo = 'Just now';
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: isCurrentSession
            ? Theme.of(context).primaryColor.withOpacity(0.1)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        border: isCurrentSession
            ? Border.all(color: Theme.of(context).primaryColor.withOpacity(0.3))
            : null,
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: isCurrentSession
                ? Theme.of(context).primaryColor
                : Theme.of(context).colorScheme.secondary,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Stack(
            children: [
              Center(
                child: Icon(
                  _getSessionIcon(session.sessionType),
                  color: Colors.white,
                  size: 24,
                ),
              ),
              if (messageCount > 0)
                Positioned(
                  right: 2,
                  top: 2,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 12,
                      minHeight: 12,
                    ),
                    child: Text(
                      messageCount > 99 ? '99+' : '$messageCount',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 8,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                session.title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: isCurrentSession
                          ? FontWeight.bold
                          : FontWeight.normal,
                      color: isCurrentSession
                          ? Theme.of(context).primaryColor
                          : null,
                    ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (isCurrentSession)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text(
                  'Active',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Row(
            children: [
              Icon(
                Icons.schedule,
                size: 12,
                color: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.color
                    ?.withOpacity(0.6),
              ),
              const SizedBox(width: 4),
              Text(
                timeAgo,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.color
                          ?.withOpacity(0.6),
                    ),
              ),
              const SizedBox(width: 12),
              Icon(
                Icons.chat_bubble_outline,
                size: 12,
                color: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.color
                    ?.withOpacity(0.6),
              ),
              const SizedBox(width: 4),
              Text(
                '$messageCount message${messageCount != 1 ? 's' : ''}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.color
                          ?.withOpacity(0.6),
                    ),
              ),
              const Spacer(),
              Text(
                _formatSessionType(session.sessionType),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).primaryColor.withOpacity(0.7),
                      fontWeight: FontWeight.w500,
                    ),
              ),
            ],
          ),
        ),
        onTap: () => _switchToSession(session),
      ),
    );
  }

  Future<void> _switchToSession(intelligent_models.ChatSession session) async {
    try {
      print('🔄 Switching to session: ${session.id} - ${session.title}');

      if (_currentSessionId == session.id) {
        print('Already on session ${session.id}, skipping switch');
        Navigator.pop(context);
        return;
      }

      setState(() {
        _isLoading = true;
        _currentSession = session;
        _currentSessionId = session.id;
        _messages.clear();
        _personalizedSuggestions = null;
        _typingSuggestions.clear();
        _showTypingSuggestions = false;
      });

      try {
        final messages = await _chatService.getSessionMessages(
          sessionId: session.id,
          page: 1,
          limit: 50,
        );

        setState(() {
          _messages.addAll(messages);
        });

        print('✅ Loaded ${messages.length} messages for session ${session.id}');
      } catch (messageError) {
        print('⚠️ Error loading messages for session: $messageError');
      }

      setState(() {
        _isLoading = false;
      });

      await _saveLastSession(session.id);

      if (_messages.isEmpty) {
        _addWelcomeMessage();
      }

      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToBottom();
      });

      try {
        await _loadPersonalizedSuggestions();
      } catch (suggestionsError) {
        print('⚠️ Error loading suggestions: $suggestionsError');
      }

      if (mounted) {
        Navigator.pop(context);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.swap_horiz, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text('Switched to "${session.title}"'),
                ),
              ],
            ),
            backgroundColor: Colors.blue,
            duration: const Duration(seconds: 2),
          ),
        );
      }

      print(
          '✅ Successfully switched to session with ${_messages.length} messages');
    } catch (e) {
      print('❌ Error switching to session: $e');
      setState(() {
        _isLoading = false;
      });
      _showErrorSnackBar('Failed to switch session: $e');
    }
  }

  Future<void> _createNewSessionAndSwitch() async {
    try {
      print('🆕 Creating new session from UI...');

      setState(() => _isLoading = true);

      final newSession = await _chatService.createNewSession(
        title: 'New Chat Session',
        sessionType: 'educational_chat',
        context: {
          'type': 'educational_chat',
          'created_from': 'flutter_ui',
          'features': ['ai_assistance', 'personalization', 'suggestions'],
          'timestamp': DateTime.now().toIso8601String(),
        },
        settings: {
          'ai_assistance_level': 'smart',
          'personalization': true,
          'suggestions_enabled': true,
          'enable_topic_tracking': true,
          'enable_personalization': true,
          'max_history_context': 20,
          'creativity_level': 0.7,
        },
      );

      setState(() {
        _sessions.insert(0, newSession);
        _currentSession = newSession;
        _currentSessionId = newSession.id;
        _messages.clear();
        _isLoading = false;
      });

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_lastSessionKey, newSession.id);

      await _loadPersonalizedSuggestions();

      print(
          '✅ Successfully created and switched to new session: ${newSession.id}');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white, size: 20),
                SizedBox(width: 8),
                Text('New chat session created'),
              ],
            ),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      print('❌ Failed to create new session: $e');
      _showErrorSnackBar('Failed to create new session: $e');
    }
  }

  String _formatSessionType(String type) {
    switch (type) {
      case 'educational_chat':
        return 'Learning';
      case 'subject_specific':
        return 'Subject';
      case 'general':
        return 'General';
      default:
        return 'Chat';
    }
  }
}

extension ListExtension<T> on List<T> {
  List<T> takeLast(int count) {
    if (count >= length) return this;
    return sublist(length - count);
  }
}

extension IterableExtension<T> on Iterable<T> {
  T? get firstOrNull {
    final iterator = this.iterator;
    if (iterator.moveNext()) {
      return iterator.current;
    }
    return null;
  }
}
