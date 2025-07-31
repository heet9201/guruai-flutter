import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';
import '../../domain/usecases/chat_usecases.dart';
import '../../data/repositories/chat_repository_impl.dart';
import '../../data/datasources/chat_local_datasource.dart';
import '../bloc/chat_bloc.dart';
import '../bloc/chat_event.dart';
import '../bloc/chat_state.dart';
import '../widgets/chat/message_bubble.dart';
import '../widgets/chat/typing_indicator.dart';
import '../widgets/chat/voice_recording_widget.dart';
import '../widgets/chat/quick_suggestions_widget.dart';
import '../widgets/chat/chat_input_widget.dart';
import '../widgets/chat/language_selector_widget.dart';
import '../widgets/chat/message_search_widget.dart';

class EnhancedQAChatScreen extends StatefulWidget {
  const EnhancedQAChatScreen({super.key});

  @override
  State<EnhancedQAChatScreen> createState() => _EnhancedQAChatScreenState();
}

class _EnhancedQAChatScreenState extends State<EnhancedQAChatScreen>
    with TickerProviderStateMixin {
  final ScrollController _scrollController = ScrollController();
  late String _currentSessionId;
  bool _showSearch = false;
  bool _showLanguageSelector = true;

  @override
  void initState() {
    super.initState();
    _currentSessionId = const Uuid().v4();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
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
    return BlocProvider(
      create: (context) {
        final localDataSource = ChatLocalDataSourceImpl();
        final repository = ChatRepositoryImpl(localDataSource: localDataSource);

        return ChatBloc(
          sendMessageUseCase: SendMessageUseCase(repository),
          getChatSessionUseCase: GetChatSessionUseCase(repository),
          searchMessagesUseCase: SearchMessagesUseCase(repository),
          saveAsFaqUseCase: SaveAsFaqUseCase(repository),
          exportChatHistoryUseCase: ExportChatHistoryUseCase(repository),
          getQuickSuggestionsUseCase: GetQuickSuggestionsUseCase(repository),
          processOfflineQueueUseCase: ProcessOfflineQueueUseCase(repository),
        )..add(LoadChatSession(_currentSessionId));
      },
      child: Scaffold(
        appBar: _buildAppBar(context),
        body: BlocConsumer<ChatBloc, ChatState>(
          listener: (context, state) {
            if (state is ChatLoaded) {
              _scrollToBottom();
            } else if (state is ChatError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(state.message)),
              );
            } else if (state is ExportSuccess) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Chat exported: ${state.exportPath}')),
              );
            } else if (state is OfflineQueueProcessed) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                    content: Text('${state.processedCount} messages sent')),
              );
            }
          },
          builder: (context, state) {
            if (state is ChatInitial || state is ChatLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (state is ChatError) {
              return _buildErrorWidget(context, state);
            }

            if (state is VoiceRecordingState) {
              return _buildVoiceRecordingView(context, state);
            }

            if (state is ChatLoaded) {
              return _buildChatView(context, state);
            }

            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      title: const Text('AI Teaching Assistant'),
      actions: [
        IconButton(
          onPressed: () {
            setState(() {
              _showSearch = !_showSearch;
            });
          },
          icon: Icon(_showSearch ? Icons.close : Icons.search),
          tooltip: _showSearch ? 'Close search' : 'Search messages',
        ),
        PopupMenuButton<String>(
          onSelected: (value) {
            switch (value) {
              case 'export':
                context.read<ChatBloc>().add(ExportChatHistory());
                break;
              case 'clear':
                _showClearChatDialog(context);
                break;
              case 'faq':
                _showFaqMessages(context);
                break;
              case 'language':
                setState(() {
                  _showLanguageSelector = !_showLanguageSelector;
                });
                break;
            }
          },
          itemBuilder: (BuildContext context) => [
            const PopupMenuItem<String>(
              value: 'language',
              child: ListTile(
                leading: Icon(Icons.translate),
                title: Text('Toggle Language Selector'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
            const PopupMenuItem<String>(
              value: 'faq',
              child: ListTile(
                leading: Icon(Icons.bookmark),
                title: Text('Saved FAQs'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
            const PopupMenuItem<String>(
              value: 'export',
              child: ListTile(
                leading: Icon(Icons.download),
                title: Text('Export Chat'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
            const PopupMenuItem<String>(
              value: 'clear',
              child: ListTile(
                leading: Icon(Icons.clear_all),
                title: Text('Clear Chat'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildChatView(BuildContext context, ChatLoaded state) {
    return Column(
      children: [
        // Language selector
        if (_showLanguageSelector && !_showSearch)
          LanguageSelectorWidget(
            currentLanguage: state.currentLanguage,
            onLanguageChanged: (language) {
              context.read<ChatBloc>().add(ChangeLanguage(language));
            },
          ),

        // Quick suggestions
        if (!_showSearch && state.quickSuggestions.isNotEmpty)
          QuickSuggestionsWidget(
            suggestions: state.quickSuggestions,
            currentLanguage: state.currentLanguage,
            onSuggestionTap: (suggestion) {
              context.read<ChatBloc>().add(SendMessage(text: suggestion));
            },
          ),

        // Search or messages
        Expanded(
          child: _showSearch
              ? MessageSearchWidget(
                  onSearch: (query) {
                    context.read<ChatBloc>().add(SearchMessages(query));
                  },
                  searchResults: state.searchResults,
                  currentLanguage: state.currentLanguage,
                  onPlayVoice: (path) {
                    context.read<ChatBloc>().add(PlayVoiceMessage(path));
                  },
                  onPlayTts: (text) {
                    context.read<ChatBloc>().add(
                          PlayTextToSpeech(text, state.currentLanguage),
                        );
                  },
                  onToggleFavorite: (messageId) {
                    context
                        .read<ChatBloc>()
                        .add(ToggleMessageFavorite(messageId));
                  },
                  onSaveAsFaq: (messageId) {
                    context.read<ChatBloc>().add(SaveMessageAsFaq(messageId));
                  },
                )
              : _buildMessagesList(context, state),
        ),

        // Input area
        if (!_showSearch)
          ChatInputWidget(
            onSendMessage: (text) {
              context.read<ChatBloc>().add(SendMessage(text: text));
            },
            onStartVoiceRecording: () {
              context.read<ChatBloc>().add(StartVoiceRecording());
            },
            onStopVoiceRecording: () {
              context.read<ChatBloc>().add(StopVoiceRecording());
            },
            onCancelVoiceRecording: () {
              context.read<ChatBloc>().add(StopVoiceRecording());
            },
            isRecording: state.isRecording,
            isTyping: state.isTyping,
            isConnected: state.isConnected,
          ),
      ],
    );
  }

  Widget _buildMessagesList(BuildContext context, ChatLoaded state) {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: state.session.messages.length + (state.isTyping ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == state.session.messages.length && state.isTyping) {
          return const TypingIndicator();
        }

        final message = state.session.messages[index];
        return MessageBubble(
          message: message,
          currentLanguage: state.currentLanguage,
          onPlayVoice: (path) {
            context.read<ChatBloc>().add(PlayVoiceMessage(path));
          },
          onPlayTts: (text) {
            context.read<ChatBloc>().add(
                  PlayTextToSpeech(text, state.currentLanguage),
                );
          },
          onToggleFavorite: (messageId) {
            context.read<ChatBloc>().add(ToggleMessageFavorite(messageId));
          },
          onSaveAsFaq: (messageId) {
            context.read<ChatBloc>().add(SaveMessageAsFaq(messageId));
          },
          isPlayingVoice: state.isPlayingVoice,
          isPlayingTts: state.isPlayingTts,
        );
      },
    );
  }

  Widget _buildVoiceRecordingView(
      BuildContext context, VoiceRecordingState state) {
    return Column(
      children: [
        Expanded(
          child: Center(
            child: VoiceRecordingWidget(
              isRecording: state.isRecording,
              duration: state.recordingDuration,
              waveformData: state.waveformData,
              onStop: () {
                context.read<ChatBloc>().add(StopVoiceRecording());
              },
              onCancel: () {
                context.read<ChatBloc>().add(StopVoiceRecording());
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildErrorWidget(BuildContext context, ChatError state) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: theme.colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              'Something went wrong',
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              state.message,
              style: theme.textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                context
                    .read<ChatBloc>()
                    .add(LoadChatSession(_currentSessionId));
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  void _showClearChatDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Clear Chat'),
          content: const Text(
              'Are you sure you want to clear all messages? This action cannot be undone.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                context.read<ChatBloc>().add(ClearChat());
              },
              child: const Text('Clear'),
            ),
          ],
        );
      },
    );
  }

  void _showFaqMessages(BuildContext context) {
    // TODO: Implement FAQ messages screen
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('FAQ feature coming soon!')),
    );
  }
}
