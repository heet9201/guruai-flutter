import 'package:flutter/material.dart';
import '../widgets/offline/offline_ui_components.dart';
import '../bloc/chat_bloc.dart';
import '../bloc/chat_state.dart';
import '../bloc/chat_event.dart';
import '../../domain/entities/chat_message.dart';
import '../../core/services/network_connectivity_service.dart';
import '../../core/services/sync_service.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class EnhancedChatScreen extends StatefulWidget {
  const EnhancedChatScreen({super.key});

  @override
  State<EnhancedChatScreen> createState() => _EnhancedChatScreenState();
}

class _EnhancedChatScreenState extends State<EnhancedChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    // Load chat session on screen init
    context.read<ChatBloc>().add(const LoadChatSession('default'));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Teaching Assistant'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => _showOfflineSettings(context),
          ),
        ],
      ),
      body: Column(
        children: [
          // Network and sync status indicators
          const OfflineStatusWidget(compact: true),
          const SyncStatusWidget(compact: true),

          // Chat messages area
          Expanded(
            child: BlocBuilder<ChatBloc, ChatState>(
              builder: (context, state) {
                if (state is ChatLoading) {
                  return const OfflineAwareLoadingWidget(
                    message: 'Loading chat...',
                  );
                } else if (state is ChatLoaded) {
                  return _buildChatMessages(state);
                } else if (state is ChatError) {
                  return OfflineAwareLoadingWidget(
                    message: state.message,
                    onRetry: () => context.read<ChatBloc>().add(
                          const LoadChatSession('default'),
                        ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ),

          // Message input area
          _buildMessageInput(),
        ],
      ),
    );
  }

  Widget _buildChatMessages(ChatLoaded state) {
    return Column(
      children: [
        // Offline mode indicator
        if (state.isOfflineMode)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(8),
            color: Colors.orange.withOpacity(0.1),
            child: Row(
              children: [
                const Icon(Icons.cloud_off, color: Colors.orange, size: 16),
                const SizedBox(width: 8),
                Text(
                  'Working offline - limited features available',
                  style: TextStyle(
                    color: Colors.orange[800],
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),

        Expanded(
          child: ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.all(16),
            itemCount: state.session.messages.length,
            itemBuilder: (context, index) {
              final message = state.session.messages[index];
              return _buildMessageBubble(message, state);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildMessageBubble(ChatMessage message, ChatLoaded state) {
    final isUser = message.isUser;
    final isFromCache = !isUser && state.lastResponseFromCache;

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        constraints: const BoxConstraints(maxWidth: 280),
        child: Column(
          crossAxisAlignment:
              isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color:
                    isUser ? Theme.of(context).primaryColor : Colors.grey[200],
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                message.text,
                style: TextStyle(
                  color: isUser ? Colors.white : Colors.black87,
                  fontSize: 16,
                ),
              ),
            ),

            // Show offline badge for cached responses
            if (isFromCache && !isUser) ...[
              const SizedBox(height: 4),
              OfflineBadge(
                isOfflineContent: true,
                cacheTime: 'recently',
                onRefresh: () => _retryLastMessage(),
              ),
            ],

            // Message timestamp
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                _formatTimestamp(message.timestamp),
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ),
          ],
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
              decoration: InputDecoration(
                hintText: 'Type your message...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey[100],
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
              ),
              onSubmitted: (_) => _sendMessage(),
            ),
          ),
          const SizedBox(width: 8),

          // Voice recording button
          OfflineAwareButton(
            text: '',
            icon: Icons.mic,
            actionType: 'voice_recording',
            onPressed: () => _startVoiceRecording(),
            onOfflinePressed: () => _showOfflineVoiceDialog(),
          ),

          const SizedBox(width: 8),

          // Send button
          OfflineAwareButton(
            text: '',
            icon: Icons.send,
            actionType: 'send_message',
            onPressed: _sendMessage,
            onOfflinePressed: () => _sendOfflineMessage(),
          ),
        ],
      ),
    );
  }

  void _sendMessage() {
    final text = _messageController.text.trim();
    if (text.isNotEmpty) {
      context.read<ChatBloc>().add(SendMessage(text: text));
      _messageController.clear();
      _scrollToBottom();
    }
  }

  void _sendOfflineMessage() {
    final text = _messageController.text.trim();
    if (text.isNotEmpty) {
      // Show dialog explaining offline mode
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Offline Mode'),
          content: const Text(
            'Your message will be sent when you\'re back online. You may receive cached responses.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                context.read<ChatBloc>().add(SendMessage(text: text));
                _messageController.clear();
                _scrollToBottom();
              },
              child: const Text('Send Anyway'),
            ),
          ],
        ),
      );
    }
  }

  void _startVoiceRecording() {
    context.read<ChatBloc>().add(StartVoiceRecording());
  }

  void _showOfflineVoiceDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Voice Recording Unavailable'),
        content: const Text(
          'Voice recording requires an internet connection for speech-to-text processing.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _retryLastMessage() {
    // Retry getting fresh response for last user message
    final bloc = context.read<ChatBloc>();
    if (bloc.state is ChatLoaded) {
      final state = bloc.state as ChatLoaded;
      final userMessages =
          state.session.messages.where((m) => m.isUser).toList();
      if (userMessages.isNotEmpty) {
        final lastUserMessage = userMessages.last;
        bloc.add(SendMessage(text: lastUserMessage.text));
      }
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

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else {
      return '${timestamp.day}/${timestamp.month}';
    }
  }

  void _showOfflineSettings(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        builder: (context, scrollController) => Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Offline Settings',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  children: [
                    // Network status card
                    Card(
                      child: ListenableBuilder(
                        listenable: NetworkConnectivityService.instance,
                        builder: (context, child) {
                          final networkService =
                              NetworkConnectivityService.instance;
                          return ListTile(
                            leading: Icon(
                              Icons.wifi,
                              color: Color(networkService.getStatusColor()),
                            ),
                            title: const Text('Network Status'),
                            subtitle: Text(networkService.getStatusMessage()),
                            trailing: IconButton(
                              icon: const Icon(Icons.refresh),
                              onPressed: () =>
                                  networkService.refreshNetworkStatus(),
                            ),
                          );
                        },
                      ),
                    ),

                    // Sync settings card
                    Card(
                      child: ListenableBuilder(
                        listenable: SyncService.instance,
                        builder: (context, child) {
                          final syncService = SyncService.instance;
                          return ExpansionTile(
                            leading: const Icon(Icons.sync),
                            title: const Text('Sync Settings'),
                            children: [
                              SwitchListTile(
                                title: const Text('Auto Sync'),
                                subtitle: const Text(
                                    'Automatically sync when online'),
                                value: syncService.isAutoSyncEnabled,
                                onChanged: (value) =>
                                    syncService.setAutoSyncEnabled(value),
                              ),
                              SwitchListTile(
                                title: const Text('WiFi Only'),
                                subtitle:
                                    const Text('Only sync on WiFi connection'),
                                value: syncService.syncOnlyOnWifi,
                                onChanged: (value) =>
                                    syncService.setSyncOnlyOnWifi(value),
                              ),
                              ListTile(
                                title: const Text('Manual Sync'),
                                subtitle: const Text('Force sync now'),
                                trailing: ElevatedButton(
                                  onPressed: () => syncService.manualSync(),
                                  child: const Text('Sync'),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),

                    // Cache management
                    const CacheManagementWidget(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}
