import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../core/services/service_locator.dart';

// Message Model for UI
class ChatMessage extends Equatable {
  final String id;
  final String content;
  final bool isUser;
  final DateTime timestamp;
  final String? conversationId;
  final bool isLoading;
  final List<String>? suggestions;

  const ChatMessage({
    required this.id,
    required this.content,
    required this.isUser,
    required this.timestamp,
    this.conversationId,
    this.isLoading = false,
    this.suggestions,
  });

  ChatMessage copyWith({
    String? id,
    String? content,
    bool? isUser,
    DateTime? timestamp,
    String? conversationId,
    bool? isLoading,
    List<String>? suggestions,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      content: content ?? this.content,
      isUser: isUser ?? this.isUser,
      timestamp: timestamp ?? this.timestamp,
      conversationId: conversationId ?? this.conversationId,
      isLoading: isLoading ?? this.isLoading,
      suggestions: suggestions ?? this.suggestions,
    );
  }

  @override
  List<Object?> get props => [
        id,
        content,
        isUser,
        timestamp,
        conversationId,
        isLoading,
        suggestions,
      ];
}

// Events
abstract class ChatEvent extends Equatable {
  const ChatEvent();

  @override
  List<Object?> get props => [];
}

class ChatStarted extends ChatEvent {
  final String? conversationId;

  const ChatStarted({this.conversationId});

  @override
  List<Object?> get props => [conversationId];
}

class ChatMessageSent extends ChatEvent {
  final String message;
  final Map<String, dynamic>? context;

  const ChatMessageSent({
    required this.message,
    this.context,
  });

  @override
  List<Object?> get props => [message, context];
}

class ChatImageAnalyzed extends ChatEvent {
  final String imageData;
  final String prompt;
  final String imageFormat;

  const ChatImageAnalyzed({
    required this.imageData,
    required this.prompt,
    this.imageFormat = 'jpeg',
  });

  @override
  List<Object?> get props => [imageData, prompt, imageFormat];
}

class ChatSummaryGenerated extends ChatEvent {
  final String text;

  const ChatSummaryGenerated({required this.text});

  @override
  List<Object?> get props => [text];
}

class ChatCleared extends ChatEvent {}

class ChatTypingStarted extends ChatEvent {}

class ChatTypingStopped extends ChatEvent {}

class ChatWebSocketMessageReceived extends ChatEvent {
  final Map<String, dynamic> data;

  const ChatWebSocketMessageReceived({required this.data});

  @override
  List<Object?> get props => [data];
}

// States
abstract class ChatState extends Equatable {
  const ChatState();

  @override
  List<Object?> get props => [];
}

class ChatInitial extends ChatState {}

class ChatLoaded extends ChatState {
  final List<ChatMessage> messages;
  final String? conversationId;
  final bool isTyping;
  final bool isLoading;

  const ChatLoaded({
    required this.messages,
    this.conversationId,
    this.isTyping = false,
    this.isLoading = false,
  });

  ChatLoaded copyWith({
    List<ChatMessage>? messages,
    String? conversationId,
    bool? isTyping,
    bool? isLoading,
  }) {
    return ChatLoaded(
      messages: messages ?? this.messages,
      conversationId: conversationId ?? this.conversationId,
      isTyping: isTyping ?? this.isTyping,
      isLoading: isLoading ?? this.isLoading,
    );
  }

  @override
  List<Object?> get props => [messages, conversationId, isTyping, isLoading];
}

class ChatError extends ChatState {
  final String message;

  const ChatError({required this.message});

  @override
  List<Object?> get props => [message];
}

// BLoC
class ChatBloc extends Bloc<ChatEvent, ChatState> {
  String? _currentConversationId;

  ChatBloc() : super(ChatInitial()) {
    on<ChatStarted>(_onChatStarted);
    on<ChatMessageSent>(_onChatMessageSent);
    on<ChatImageAnalyzed>(_onChatImageAnalyzed);
    on<ChatSummaryGenerated>(_onChatSummaryGenerated);
    on<ChatCleared>(_onChatCleared);
    on<ChatTypingStarted>(_onChatTypingStarted);
    on<ChatTypingStopped>(_onChatTypingStopped);
    on<ChatWebSocketMessageReceived>(_onChatWebSocketMessageReceived);

    // Set up WebSocket message listener
    ServiceLocator.webSocketService.onNewMessage = _handleWebSocketMessage;
  }

  void _handleWebSocketMessage(Map<String, dynamic> data) {
    add(ChatWebSocketMessageReceived(data: data));
  }

  Future<void> _onChatWebSocketMessageReceived(
    ChatWebSocketMessageReceived event,
    Emitter<ChatState> emit,
  ) async {
    if (event.data['type'] == 'ai_response' && state is ChatLoaded) {
      final currentState = state as ChatLoaded;
      final aiMessage = ChatMessage(
        id: event.data['id'] ??
            DateTime.now().millisecondsSinceEpoch.toString(),
        content: event.data['message'] ?? '',
        isUser: false,
        timestamp: DateTime.now(),
        conversationId: _currentConversationId,
        suggestions: event.data['suggestions']?.cast<String>(),
      );

      final updatedMessages = [...currentState.messages, aiMessage];
      emit(currentState.copyWith(
        messages: updatedMessages,
        isLoading: false,
      ));
    }
  }

  Future<void> _onChatStarted(
    ChatStarted event,
    Emitter<ChatState> emit,
  ) async {
    _currentConversationId = event.conversationId;
    emit(const ChatLoaded(messages: []));

    // Join WebSocket room for real-time chat
    if (ServiceLocator.webSocketService.isConnected) {
      final roomId = _currentConversationId ??
          'general_chat_${DateTime.now().millisecondsSinceEpoch}';
      ServiceLocator.webSocketService.joinChatRoom(roomId);
    }
  }

  Future<void> _onChatMessageSent(
    ChatMessageSent event,
    Emitter<ChatState> emit,
  ) async {
    if (state is! ChatLoaded) return;

    final currentState = state as ChatLoaded;

    // Add user message
    final userMessage = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      content: event.message,
      isUser: true,
      timestamp: DateTime.now(),
      conversationId: _currentConversationId,
    );

    // Add loading message for AI response
    final loadingMessage = ChatMessage(
      id: '${DateTime.now().millisecondsSinceEpoch}_loading',
      content: 'AI is thinking...',
      isUser: false,
      timestamp: DateTime.now(),
      conversationId: _currentConversationId,
      isLoading: true,
    );

    final updatedMessages = [
      ...currentState.messages,
      userMessage,
      loadingMessage,
    ];

    emit(currentState.copyWith(
      messages: updatedMessages,
      isLoading: true,
    ));

    try {
      // Send message via WebSocket for real-time response
      if (ServiceLocator.webSocketService.isConnected) {
        final roomId = _currentConversationId ??
            'general_chat_${DateTime.now().millisecondsSinceEpoch}';
        ServiceLocator.webSocketService.sendMessage(
          roomId: roomId,
          message: event.message,
          metadata: event.context,
        );
      } else {
        // Fallback to HTTP API
        final chatResponse = await ServiceLocator.chatService.sendMessage(
          message: event.message,
          conversationId: _currentConversationId,
          context: event.context,
        );

        _currentConversationId = chatResponse.conversationId;

        final aiMessage = ChatMessage(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          content: chatResponse.response,
          isUser: false,
          timestamp: DateTime.now(),
          conversationId: _currentConversationId,
          suggestions: chatResponse.suggestions,
        );

        // Remove loading message and add AI response
        final finalMessages = updatedMessages
            .where((msg) => !msg.isLoading)
            .toList()
          ..add(aiMessage);

        emit(currentState.copyWith(
          messages: finalMessages,
          conversationId: _currentConversationId,
          isLoading: false,
        ));
      }
    } catch (e) {
      emit(ChatError(message: e.toString()));
    }
  }

  Future<void> _onChatImageAnalyzed(
    ChatImageAnalyzed event,
    Emitter<ChatState> emit,
  ) async {
    if (state is! ChatLoaded) return;

    final currentState = state as ChatLoaded;

    // Add user message with image
    final userMessage = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      content: '📷 Image: ${event.prompt}',
      isUser: true,
      timestamp: DateTime.now(),
      conversationId: _currentConversationId,
    );

    // Add loading message
    final loadingMessage = ChatMessage(
      id: '${DateTime.now().millisecondsSinceEpoch}_loading',
      content: 'Analyzing image...',
      isUser: false,
      timestamp: DateTime.now(),
      conversationId: _currentConversationId,
      isLoading: true,
    );

    final updatedMessages = [
      ...currentState.messages,
      userMessage,
      loadingMessage,
    ];

    emit(currentState.copyWith(
      messages: updatedMessages,
      isLoading: true,
    ));

    try {
      final chatResponse = await ServiceLocator.chatService.analyzeImage(
        imageData: event.imageData,
        prompt: event.prompt,
        imageFormat: event.imageFormat,
      );

      _currentConversationId = chatResponse.conversationId;

      final aiMessage = ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        content: chatResponse.response,
        isUser: false,
        timestamp: DateTime.now(),
        conversationId: _currentConversationId,
        suggestions: chatResponse.suggestions,
      );

      // Remove loading message and add AI response
      final finalMessages = updatedMessages
          .where((msg) => !msg.isLoading)
          .toList()
        ..add(aiMessage);

      emit(currentState.copyWith(
        messages: finalMessages,
        conversationId: _currentConversationId,
        isLoading: false,
      ));
    } catch (e) {
      emit(ChatError(message: e.toString()));
    }
  }

  Future<void> _onChatSummaryGenerated(
    ChatSummaryGenerated event,
    Emitter<ChatState> emit,
  ) async {
    if (state is! ChatLoaded) return;

    final currentState = state as ChatLoaded;

    try {
      final summary =
          await ServiceLocator.chatService.generateSummary(event.text);

      final summaryMessage = ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        content: '📝 Summary: $summary',
        isUser: false,
        timestamp: DateTime.now(),
        conversationId: _currentConversationId,
      );

      final updatedMessages = [...currentState.messages, summaryMessage];

      emit(currentState.copyWith(messages: updatedMessages));
    } catch (e) {
      emit(ChatError(message: e.toString()));
    }
  }

  Future<void> _onChatCleared(
    ChatCleared event,
    Emitter<ChatState> emit,
  ) async {
    _currentConversationId = null;
    emit(const ChatLoaded(messages: []));
  }

  Future<void> _onChatTypingStarted(
    ChatTypingStarted event,
    Emitter<ChatState> emit,
  ) async {
    if (state is ChatLoaded) {
      final currentState = state as ChatLoaded;
      emit(currentState.copyWith(isTyping: true));

      // Send typing indicator via WebSocket
      if (ServiceLocator.webSocketService.isConnected &&
          _currentConversationId != null) {
        ServiceLocator.webSocketService.sendTypingIndicator(
          roomId: _currentConversationId!,
          isTyping: true,
        );
      }
    }
  }

  Future<void> _onChatTypingStopped(
    ChatTypingStopped event,
    Emitter<ChatState> emit,
  ) async {
    if (state is ChatLoaded) {
      final currentState = state as ChatLoaded;
      emit(currentState.copyWith(isTyping: false));

      // Send typing indicator via WebSocket
      if (ServiceLocator.webSocketService.isConnected &&
          _currentConversationId != null) {
        ServiceLocator.webSocketService.sendTypingIndicator(
          roomId: _currentConversationId!,
          isTyping: false,
        );
      }
    }
  }

  @override
  Future<void> close() {
    ServiceLocator.webSocketService.onNewMessage = null;
    return super.close();
  }
}
