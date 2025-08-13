import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../../core/theme/responsive_layout.dart';
import '../../core/services/service_locator.dart';
import '../bloc/app_bloc.dart';
import '../bloc/app_state.dart';

class QAChatScreen extends StatefulWidget {
  const QAChatScreen({super.key});

  @override
  State<QAChatScreen> createState() => _QAChatScreenState();
}

class _QAChatScreenState extends State<QAChatScreen>
    with TickerProviderStateMixin {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];
  bool _isTyping = false;
  late AnimationController _typingAnimationController;
  late AnimationController _messageAnimationController;
  final FocusNode _textFieldFocusNode = FocusNode();
  static const String _cacheKey = 'qa_chat_messages';

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadCachedMessages();
    _initializeChat();
  }

  void _initializeAnimations() {
    _typingAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _messageAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _typingAnimationController.repeat();
  }

  Future<void> _loadCachedMessages() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedData = prefs.getString(_cacheKey);
      if (cachedData != null) {
        final List<dynamic> messagesList = jsonDecode(cachedData);
        setState(() {
          _messages.clear();
          _messages.addAll(
            messagesList
                .map((msg) => ChatMessage(
                      text: msg['text'] ?? '',
                      isUser: msg['isUser'] ?? false,
                      timestamp: DateTime.parse(
                          msg['timestamp'] ?? DateTime.now().toIso8601String()),
                    ))
                .toList(),
          );
        });
      }
    } catch (e) {
      print('Error loading cached messages: $e');
    }
  }

  Future<void> _saveCachedMessages() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final messagesData = _messages
          .map((msg) => {
                'text': msg.text,
                'isUser': msg.isUser,
                'timestamp': msg.timestamp.toIso8601String(),
              })
          .toList();
      await prefs.setString(_cacheKey, jsonEncode(messagesData));
    } catch (e) {
      print('Error saving cached messages: $e');
    }
  }

  void _initializeChat() {
    // Add welcome message only if no cached messages
    if (_messages.isEmpty) {
      _messages.add(ChatMessage(
        text:
            'Hello! I\'m your AI teaching assistant. How can I help you today?',
        isUser: false,
        timestamp: DateTime.now(),
      ));
      _saveCachedMessages();
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _typingAnimationController.dispose();
    _messageAnimationController.dispose();
    _textFieldFocusNode.dispose();
    super.dispose();
  }

  void _sendMessage(String languageCode) async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _messages.add(ChatMessage(
        text: text,
        isUser: true,
        timestamp: DateTime.now(),
      ));
      _messageController.clear();
      _isTyping = true;
    });

    // Save messages to cache
    _saveCachedMessages();
    _scrollToBottom();

    try {
      // Use the real chat service
      final chatService = ServiceLocator.chatService;
      final chatResponse = await chatService.sendMessage(
        message: text,
        conversationId:
            'qa_conversation_${DateTime.now().millisecondsSinceEpoch}',
        maxTokens: 1000,
        temperature: 0.7,
      );

      if (mounted) {
        setState(() {
          _messages.add(ChatMessage(
            text: chatResponse.response,
            isUser: false,
            timestamp: DateTime.now(),
          ));
          _isTyping = false;
        });

        // Save updated messages to cache
        _saveCachedMessages();
        _scrollToBottom();

        // Trigger message animation
        _messageAnimationController.forward().then((_) {
          _messageAnimationController.reset();
        });
      }
    } catch (e) {
      print('Error sending message: $e');
      // Fallback to demo response if API fails
      if (mounted) {
        setState(() {
          _messages.add(ChatMessage(
            text: _generateAIResponse(text, languageCode),
            isUser: false,
            timestamp: DateTime.now(),
          ));
          _isTyping = false;
        });

        // Save updated messages to cache
        _saveCachedMessages();
        _scrollToBottom();

        // Trigger message animation
        _messageAnimationController.forward().then((_) {
          _messageAnimationController.reset();
        });
      }
    }
  }

  String _generateAIResponse(String userMessage, String languageCode) {
    // Simple response generation based on keywords
    final message = userMessage.toLowerCase();

    if (message.contains('lesson') || message.contains('plan')) {
      return _getLessonPlanResponse(languageCode);
    } else if (message.contains('story') || message.contains('narrative')) {
      return _getStoryResponse(languageCode);
    } else if (message.contains('quiz') || message.contains('test')) {
      return _getQuizResponse(languageCode);
    } else if (message.contains('math') || message.contains('mathematics')) {
      return _getMathResponse(languageCode);
    } else if (message.contains('science')) {
      return _getScienceResponse(languageCode);
    } else {
      return _getGeneralResponse(languageCode);
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AppBloc, AppState>(
      builder: (context, state) {
        final languageCode = state is AppLoaded ? state.languageCode : 'en';

        return Scaffold(
          body: Column(
            children: [
              // Chat header
              Container(
                padding: EdgeInsets.all(
                    ResponsiveLayout.getHorizontalPadding(context)),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Theme.of(context).colorScheme.primary.withOpacity(0.1),
                      Theme.of(context).colorScheme.surface,
                    ],
                  ),
                  border: Border(
                    bottom: BorderSide(
                      color: Theme.of(context)
                          .colorScheme
                          .outline
                          .withOpacity(0.2),
                    ),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: SafeArea(
                  bottom: false,
                  child: Row(
                    children: [
                      Hero(
                        tag: 'header_ai_avatar',
                        child: Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Theme.of(context)
                                    .colorScheme
                                    .primary
                                    .withOpacity(0.3),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: CircleAvatar(
                            radius: 24,
                            backgroundColor:
                                Theme.of(context).colorScheme.primaryContainer,
                            child: Icon(
                              Icons.smart_toy,
                              size: 28,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onPrimaryContainer,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _getAIAssistantTitle(languageCode),
                              style: Theme.of(context)
                                  .textTheme
                                  .titleLarge
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color:
                                        Theme.of(context).colorScheme.onSurface,
                                  ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color: Colors.green,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.green.withOpacity(0.5),
                                        blurRadius: 4,
                                        spreadRadius: 1,
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  _getOnlineStatus(languageCode),
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.copyWith(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSurface
                                            .withOpacity(0.7),
                                        fontWeight: FontWeight.w500,
                                      ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Row(
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              color: Theme.of(context)
                                  .colorScheme
                                  .surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: IconButton(
                              onPressed: () => _clearChat(),
                              icon: Icon(
                                Icons.refresh_rounded,
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                              tooltip: 'Clear Chat',
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            decoration: BoxDecoration(
                              color: Theme.of(context)
                                  .colorScheme
                                  .surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: IconButton(
                              onPressed: () =>
                                  _showChatInfo(context, languageCode),
                              icon: Icon(
                                Icons.info_outline_rounded,
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                              tooltip: _getInfoTooltip(languageCode),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // Chat messages
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Theme.of(context).colorScheme.surface,
                        Theme.of(context).colorScheme.surface.withOpacity(0.95),
                      ],
                    ),
                  ),
                  child: ListView.builder(
                    controller: _scrollController,
                    padding: EdgeInsets.all(
                        ResponsiveLayout.getHorizontalPadding(context)),
                    itemCount: _messages.length + (_isTyping ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == _messages.length && _isTyping) {
                        return _buildTypingIndicator();
                      }
                      return TweenAnimationBuilder<double>(
                        duration: Duration(milliseconds: 300 + (index * 50)),
                        tween: Tween(begin: 0.0, end: 1.0),
                        curve: Curves.easeOutBack,
                        builder: (context, value, child) {
                          return Transform.translate(
                            offset: Offset(0, 20 * (1 - value)),
                            child: Opacity(
                              opacity: value,
                              child: child,
                            ),
                          );
                        },
                        child: _buildMessageBubble(_messages[index]),
                      );
                    },
                  ),
                ),
              ),

              // Message input
              _buildMessageInput(context, languageCode),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      padding: const EdgeInsets.only(bottom: 16),
      child: SlideTransition(
        position: Tween<Offset>(
          begin: message.isUser ? const Offset(0.3, 0) : const Offset(-0.3, 0),
          end: Offset.zero,
        ).animate(CurvedAnimation(
          parent: _messageAnimationController,
          curve: Curves.elasticOut,
        )),
        child: Row(
          mainAxisAlignment:
              message.isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!message.isUser) ...[
              Hero(
                tag: 'ai_avatar',
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Theme.of(context)
                            .colorScheme
                            .primary
                            .withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: CircleAvatar(
                    radius: 18,
                    backgroundColor:
                        Theme.of(context).colorScheme.primaryContainer,
                    child: Icon(
                      Icons.smart_toy,
                      size: 18,
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
            ],
            Flexible(
              child: Container(
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.75,
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: message.isUser
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(20).copyWith(
                    bottomRight:
                        message.isUser ? const Radius.circular(6) : null,
                    bottomLeft:
                        !message.isUser ? const Radius.circular(6) : null,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      message.text,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: message.isUser
                                ? Theme.of(context).colorScheme.onPrimary
                                : Theme.of(context).colorScheme.onSurface,
                            height: 1.4,
                          ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          message.isUser ? Icons.done_all : Icons.auto_awesome,
                          size: 12,
                          color: message.isUser
                              ? Theme.of(context)
                                  .colorScheme
                                  .onPrimary
                                  .withOpacity(0.7)
                              : Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withOpacity(0.7),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _formatTime(message.timestamp),
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: message.isUser
                                        ? Theme.of(context)
                                            .colorScheme
                                            .onPrimary
                                            .withOpacity(0.7)
                                        : Theme.of(context)
                                            .colorScheme
                                            .onSurface
                                            .withOpacity(0.7),
                                    fontSize: 11,
                                  ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            if (message.isUser) ...[
              const SizedBox(width: 12),
              Hero(
                tag: 'user_avatar',
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Theme.of(context)
                            .colorScheme
                            .secondary
                            .withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: CircleAvatar(
                    radius: 18,
                    backgroundColor:
                        Theme.of(context).colorScheme.secondaryContainer,
                    child: Icon(
                      Icons.person,
                      size: 18,
                      color: Theme.of(context).colorScheme.onSecondaryContainer,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return AnimatedOpacity(
      opacity: _isTyping ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 300),
      child: Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Row(
          children: [
            Hero(
              tag: 'typing_ai_avatar',
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Theme.of(context)
                          .colorScheme
                          .primary
                          .withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: CircleAvatar(
                  radius: 18,
                  backgroundColor:
                      Theme.of(context).colorScheme.primaryContainer,
                  child: Icon(
                    Icons.smart_toy,
                    size: 18,
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(20).copyWith(
                  bottomLeft: const Radius.circular(6),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (int i = 0; i < 3; i++) ...[
                    AnimatedBuilder(
                      animation: _typingAnimationController,
                      builder: (context, child) {
                        final double value =
                            (_typingAnimationController.value - (i * 0.2)) %
                                1.0;
                        final double opacity =
                            value < 0.5 ? value * 2 : (1 - value) * 2;
                        final double scale = 0.6 + (opacity * 0.4);

                        return Transform.scale(
                          scale: scale,
                          child: Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withOpacity(opacity),
                              shape: BoxShape.circle,
                            ),
                          ),
                        );
                      },
                    ),
                    if (i < 2) const SizedBox(width: 4),
                  ],
                  const SizedBox(width: 8),
                  Text(
                    'AI is thinking...',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withOpacity(0.6),
                          fontStyle: FontStyle.italic,
                        ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageInput(BuildContext context, String languageCode) {
    return Container(
      padding: EdgeInsets.all(ResponsiveLayout.getHorizontalPadding(context)),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            // Quick action buttons
            Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                shape: BoxShape.circle,
              ),
              child: IconButton(
                onPressed: () => _showQuickActions(context, languageCode),
                icon: Icon(
                  Icons.add,
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                ),
                tooltip: _getQuickActionsTooltip(languageCode),
              ),
            ),

            const SizedBox(width: 12),

            // Message text field
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: TextField(
                  controller: _messageController,
                  focusNode: _textFieldFocusNode,
                  decoration: InputDecoration(
                    hintText: _getMessageHint(languageCode),
                    hintStyle: TextStyle(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withOpacity(0.5),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor:
                        Theme.of(context).colorScheme.surfaceContainerHighest,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 14,
                    ),
                    suffixIcon: _isTyping
                        ? Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Theme.of(context).colorScheme.primary,
                                ),
                              ),
                            ),
                          )
                        : null,
                  ),
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontSize: 16,
                  ),
                  maxLines: null,
                  textCapitalization: TextCapitalization.sentences,
                  onSubmitted: (_) => _sendMessage(languageCode),
                  onChanged: (text) {
                    // Add some interactivity
                    setState(() {});
                  },
                ),
              ),
            ),

            const SizedBox(width: 12),

            // Send button
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              decoration: BoxDecoration(
                color: _messageController.text.trim().isEmpty
                    ? Theme.of(context).colorScheme.outline.withOpacity(0.3)
                    : Theme.of(context).colorScheme.primary,
                shape: BoxShape.circle,
                boxShadow: _messageController.text.trim().isEmpty
                    ? []
                    : [
                        BoxShadow(
                          color: Theme.of(context)
                              .colorScheme
                              .primary
                              .withOpacity(0.4),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
              ),
              child: IconButton(
                onPressed: _isTyping || _messageController.text.trim().isEmpty
                    ? null
                    : () => _sendMessage(languageCode),
                icon: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: Icon(
                    _isTyping ? Icons.hourglass_empty : Icons.send_rounded,
                    key: ValueKey(_isTyping),
                    color: _messageController.text.trim().isEmpty
                        ? Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withOpacity(0.5)
                        : Theme.of(context).colorScheme.onPrimary,
                  ),
                ),
                tooltip: _getSendTooltip(languageCode),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showQuickActions(BuildContext context, String languageCode) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _QuickActionsSheet(languageCode: languageCode),
    );
  }

  void _clearChat() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Chat'),
        content: const Text(
            'Are you sure you want to clear all messages? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                _messages.clear();
                _initializeChat();
              });
              Navigator.pop(context);
            },
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }

  void _showChatInfo(BuildContext context, String languageCode) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(_getChatInfoTitle(languageCode)),
        content: Text(_getChatInfoContent(languageCode)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(_getOkLabel(languageCode)),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  // AI Response generation methods
  String _getLessonPlanResponse(String languageCode) {
    switch (languageCode) {
      case 'hi':
        return 'मैं आपकी पाठ योजना बनाने में मदद कर सकता हूं। कृपया विषय, आयु समूह और सीखने के उद्देश्य बताएं।';
      default:
        return 'I can help you create a lesson plan. Please tell me the subject, age group, and learning objectives.';
    }
  }

  String _getStoryResponse(String languageCode) {
    switch (languageCode) {
      case 'hi':
        return 'कहानी बनाना बेहतरीन आइडिया है! आप किस विषय पर कहानी चाहते हैं? मैं शैक्षिक कहानियां बना सकता हूं।';
      default:
        return 'Creating a story is a great idea! What subject would you like the story about? I can create educational stories.';
    }
  }

  String _getQuizResponse(String languageCode) {
    switch (languageCode) {
      case 'hi':
        return 'प्रश्नोत्तरी बनाने के लिए मुझे विषय और कक्षा का स्तर बताएं। मैं विभिन्न प्रकार के प्रश्न बना सकता हूं।';
      default:
        return 'To create a quiz, tell me the subject and grade level. I can create various types of questions.';
    }
  }

  String _getMathResponse(String languageCode) {
    switch (languageCode) {
      case 'hi':
        return 'गणित एक रोचक विषय है! मैं गणित की समस्याओं, अवधारणाओं और गतिविधियों में आपकी मदद कर सकता हूं।';
      default:
        return 'Math is fascinating! I can help with math problems, concepts, and activities.';
    }
  }

  String _getScienceResponse(String languageCode) {
    switch (languageCode) {
      case 'hi':
        return 'विज्ञान के बारे में पूछना बेहतरीन है! मैं प्रयोग, अवधारणाओं और मजेदार तथ्यों के साथ मदद कर सकता हूं।';
      default:
        return 'Great question about science! I can help with experiments, concepts, and fun facts.';
    }
  }

  String _getGeneralResponse(String languageCode) {
    switch (languageCode) {
      case 'hi':
        return 'यह दिलचस्प प्रश्न है! मैं शिक्षण सामग्री, पाठ योजना, और छात्र गतिविधियों में आपकी मदद कर सकता हूं।';
      default:
        return 'That\'s an interesting question! I can help with teaching materials, lesson plans, and student activities.';
    }
  }

  // Localization methods
  String _getAIAssistantTitle(String languageCode) {
    switch (languageCode) {
      case 'hi':
        return 'AI सहायक';
      case 'mr':
        return 'AI सहाय्यक';
      case 'ta':
        return 'AI உதவியாளர்';
      default:
        return 'AI Assistant';
    }
  }

  String _getOnlineStatus(String languageCode) {
    switch (languageCode) {
      case 'hi':
        return 'ऑनलाइन';
      case 'mr':
        return 'ऑनलाइन';
      case 'ta':
        return 'ஆன்லைன்';
      default:
        return 'Online';
    }
  }

  String _getInfoTooltip(String languageCode) {
    switch (languageCode) {
      case 'hi':
        return 'चैट जानकारी';
      case 'mr':
        return 'चॅट माहिती';
      case 'ta':
        return 'அரட்டை தகவல்';
      default:
        return 'Chat info';
    }
  }

  String _getMessageHint(String languageCode) {
    switch (languageCode) {
      case 'hi':
        return 'कुछ पूछें...';
      case 'mr':
        return 'काहीतरी विचारा...';
      case 'ta':
        return 'ஏதாவது கேளுங்கள்...';
      default:
        return 'Ask something...';
    }
  }

  String _getQuickActionsTooltip(String languageCode) {
    switch (languageCode) {
      case 'hi':
        return 'त्वरित कार्य';
      case 'mr':
        return 'त्वरित कृती';
      case 'ta':
        return 'விரைவு செயல்கள்';
      default:
        return 'Quick actions';
    }
  }

  String _getSendTooltip(String languageCode) {
    switch (languageCode) {
      case 'hi':
        return 'भेजें';
      case 'mr':
        return 'पाठवा';
      case 'ta':
        return 'அனுப்பு';
      default:
        return 'Send';
    }
  }

  String _getChatInfoTitle(String languageCode) {
    switch (languageCode) {
      case 'hi':
        return 'AI सहायक के बारे में';
      case 'mr':
        return 'AI सहाय्यकाबद्दल';
      case 'ta':
        return 'AI உதவியாளரைப் பற்றி';
      default:
        return 'About AI Assistant';
    }
  }

  String _getChatInfoContent(String languageCode) {
    switch (languageCode) {
      case 'hi':
        return 'यह AI आपकी शिक्षण यात्रा में मदद करने के लिए डिज़ाइन किया गया है। आप पाठ योजना, कहानियां, प्रश्नोत्तरी और अन्य शैक्षिक सामग्री बनाने के लिए प्रश्न पूछ सकते हैं।';
      default:
        return 'This AI is designed to help with your teaching journey. You can ask questions to create lesson plans, stories, quizzes, and other educational content.';
    }
  }

  String _getOkLabel(String languageCode) {
    switch (languageCode) {
      case 'hi':
        return 'ठीक है';
      case 'mr':
        return 'ठीक आहे';
      case 'ta':
        return 'சரி';
      default:
        return 'OK';
    }
  }
}

class _QuickActionsSheet extends StatelessWidget {
  final String languageCode;

  const _QuickActionsSheet({required this.languageCode});

  @override
  Widget build(BuildContext context) {
    final quickActions = [
      {
        'icon': Icons.auto_stories,
        'title': _getCreateStoryTitle(languageCode),
        'action': 'Create a story about ',
      },
      {
        'icon': Icons.quiz,
        'title': _getCreateQuizTitle(languageCode),
        'action': 'Create a quiz about ',
      },
      {
        'icon': Icons.school,
        'title': _getCreateLessonTitle(languageCode),
        'action': 'Help me plan a lesson about ',
      },
      {
        'icon': Icons.assignment,
        'title': _getCreateWorksheetTitle(languageCode),
        'action': 'Create a worksheet for ',
      },
      {
        'icon': Icons.help,
        'title': _getExplainConceptTitle(languageCode),
        'action': 'Explain the concept of ',
      },
      {
        'icon': Icons.lightbulb,
        'title': _getTeachingTipsTitle(languageCode),
        'action': 'Give me teaching tips for ',
      },
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _getQuickActionsTitle(languageCode),
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 16),
          ...quickActions.map((action) {
            return ListTile(
              leading: Icon(action['icon'] as IconData),
              title: Text(action['title'] as String),
              onTap: () {
                Navigator.pop(context);
                // Add action to message input
              },
            );
          }),
        ],
      ),
    );
  }

  String _getQuickActionsTitle(String languageCode) {
    switch (languageCode) {
      case 'hi':
        return 'त्वरित कार्य';
      default:
        return 'Quick Actions';
    }
  }

  String _getCreateStoryTitle(String languageCode) {
    switch (languageCode) {
      case 'hi':
        return 'कहानी बनाएं';
      default:
        return 'Create Story';
    }
  }

  String _getCreateQuizTitle(String languageCode) {
    switch (languageCode) {
      case 'hi':
        return 'प्रश्नोत्तरी बनाएं';
      default:
        return 'Create Quiz';
    }
  }

  String _getCreateLessonTitle(String languageCode) {
    switch (languageCode) {
      case 'hi':
        return 'पाठ योजना बनाएं';
      default:
        return 'Create Lesson Plan';
    }
  }

  String _getCreateWorksheetTitle(String languageCode) {
    switch (languageCode) {
      case 'hi':
        return 'कार्यपत्रक बनाएं';
      default:
        return 'Create Worksheet';
    }
  }

  String _getExplainConceptTitle(String languageCode) {
    switch (languageCode) {
      case 'hi':
        return 'अवधारणा समझाएं';
      default:
        return 'Explain Concept';
    }
  }

  String _getTeachingTipsTitle(String languageCode) {
    switch (languageCode) {
      case 'hi':
        return 'शिक्षण सुझाव';
      default:
        return 'Teaching Tips';
    }
  }
}

class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;

  ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
  });
}
