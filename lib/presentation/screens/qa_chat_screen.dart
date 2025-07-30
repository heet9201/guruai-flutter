import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/theme/responsive_layout.dart';
import '../bloc/app_bloc.dart';
import '../bloc/app_state.dart';

class QAChatScreen extends StatefulWidget {
  const QAChatScreen({super.key});

  @override
  State<QAChatScreen> createState() => _QAChatScreenState();
}

class _QAChatScreenState extends State<QAChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];
  bool _isTyping = false;

  @override
  void initState() {
    super.initState();
    _initializeChat();
  }

  void _initializeChat() {
    // Add welcome message
    _messages.add(ChatMessage(
      text: 'Hello! I\'m your AI teaching assistant. How can I help you today?',
      isUser: false,
      timestamp: DateTime.now(),
    ));
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendMessage(String languageCode) {
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

    _scrollToBottom();

    // Simulate AI response
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _messages.add(ChatMessage(
            text: _generateAIResponse(text, languageCode),
            isUser: false,
            timestamp: DateTime.now(),
          ));
          _isTyping = false;
        });
        _scrollToBottom();
      }
    });
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
                  color: Theme.of(context).colorScheme.surface,
                  border: Border(
                    bottom: BorderSide(
                      color: Theme.of(context)
                          .colorScheme
                          .outline
                          .withOpacity(0.2),
                    ),
                  ),
                ),
                child: SafeArea(
                  bottom: false,
                  child: Row(
                    children: [
                      CircleAvatar(
                        backgroundColor:
                            Theme.of(context).colorScheme.primaryContainer,
                        child: Icon(
                          Icons.smart_toy,
                          color:
                              Theme.of(context).colorScheme.onPrimaryContainer,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _getAIAssistantTitle(languageCode),
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                            Text(
                              _getOnlineStatus(languageCode),
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color: Colors.green,
                                  ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => _showChatInfo(context, languageCode),
                        icon: const Icon(Icons.info_outline),
                        tooltip: _getInfoTooltip(languageCode),
                      ),
                    ],
                  ),
                ),
              ),

              // Chat messages
              Expanded(
                child: ListView.builder(
                  controller: _scrollController,
                  padding: EdgeInsets.all(
                      ResponsiveLayout.getHorizontalPadding(context)),
                  itemCount: _messages.length + (_isTyping ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index == _messages.length && _isTyping) {
                      return _buildTypingIndicator();
                    }
                    return _buildMessageBubble(_messages[index]);
                  },
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
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment:
            message.isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!message.isUser) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: Theme.of(context).colorScheme.primaryContainer,
              child: Icon(
                Icons.smart_toy,
                size: 16,
                color: Theme.of(context).colorScheme.onPrimaryContainer,
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
              decoration: BoxDecoration(
                color: message.isUser
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(20).copyWith(
                  bottomRight: message.isUser ? const Radius.circular(4) : null,
                  bottomLeft: !message.isUser ? const Radius.circular(4) : null,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message.text,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: message.isUser
                              ? Theme.of(context).colorScheme.onPrimary
                              : Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatTime(message.timestamp),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: message.isUser
                              ? Theme.of(context)
                                  .colorScheme
                                  .onPrimary
                                  .withOpacity(0.7)
                              : Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant
                                  .withOpacity(0.7),
                        ),
                  ),
                ],
              ),
            ),
          ),
          if (message.isUser) ...[
            const SizedBox(width: 8),
            CircleAvatar(
              radius: 16,
              backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
              child: Icon(
                Icons.person,
                size: 16,
                color: Theme.of(context).colorScheme.onSecondaryContainer,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: Theme.of(context).colorScheme.primaryContainer,
            child: Icon(
              Icons.smart_toy,
              size: 16,
              color: Theme.of(context).colorScheme.onPrimaryContainer,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(20).copyWith(
                bottomLeft: const Radius.circular(4),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (int i = 0; i < 3; i++) ...[
                  AnimatedContainer(
                    duration: Duration(milliseconds: 600 + (i * 200)),
                    curve: Curves.easeInOut,
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      shape: BoxShape.circle,
                    ),
                  ),
                  if (i < 2) const SizedBox(width: 4),
                ],
              ],
            ),
          ),
        ],
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
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            // Quick action buttons
            IconButton(
              onPressed: () => _showQuickActions(context, languageCode),
              icon: const Icon(Icons.add),
              tooltip: _getQuickActionsTooltip(languageCode),
            ),

            // Message text field
            Expanded(
              child: TextField(
                controller: _messageController,
                decoration: InputDecoration(
                  hintText: _getMessageHint(languageCode),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor:
                      Theme.of(context).colorScheme.surfaceContainerHighest,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
                maxLines: null,
                textCapitalization: TextCapitalization.sentences,
                onSubmitted: (_) => _sendMessage(languageCode),
              ),
            ),

            const SizedBox(width: 8),

            // Send button
            IconButton(
              onPressed: _isTyping ? null : () => _sendMessage(languageCode),
              icon: Icon(
                _isTyping ? Icons.hourglass_empty : Icons.send,
              ),
              tooltip: _getSendTooltip(languageCode),
              style: IconButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Theme.of(context).colorScheme.onPrimary,
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
      builder: (context) => _QuickActionsSheet(languageCode: languageCode),
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
