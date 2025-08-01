import 'package:equatable/equatable.dart';
import '../../domain/entities/chat_message.dart';

abstract class ChatState extends Equatable {
  const ChatState();

  @override
  List<Object?> get props => [];
}

class ChatInitial extends ChatState {}

class ChatLoading extends ChatState {}

class ChatLoaded extends ChatState {
  final ChatSession session;
  final List<QuickSuggestion> quickSuggestions;
  final bool isTyping;
  final bool isRecording;
  final bool isPlayingVoice;
  final bool isPlayingTts;
  final List<ChatMessage> searchResults;
  final String currentLanguage;
  final bool isConnected;
  final List<ChatMessage> offlineQueue;
  final bool isOfflineMode;
  final bool lastResponseFromCache;

  const ChatLoaded({
    required this.session,
    this.quickSuggestions = const [],
    this.isTyping = false,
    this.isRecording = false,
    this.isPlayingVoice = false,
    this.isPlayingTts = false,
    this.searchResults = const [],
    this.currentLanguage = 'en',
    this.isConnected = true,
    this.offlineQueue = const [],
    this.isOfflineMode = false,
    this.lastResponseFromCache = false,
  });

  ChatLoaded copyWith({
    ChatSession? session,
    List<QuickSuggestion>? quickSuggestions,
    bool? isTyping,
    bool? isRecording,
    bool? isPlayingVoice,
    bool? isPlayingTts,
    List<ChatMessage>? searchResults,
    String? currentLanguage,
    bool? isConnected,
    List<ChatMessage>? offlineQueue,
    bool? isOfflineMode,
    bool? lastResponseFromCache,
  }) {
    return ChatLoaded(
      session: session ?? this.session,
      quickSuggestions: quickSuggestions ?? this.quickSuggestions,
      isTyping: isTyping ?? this.isTyping,
      isRecording: isRecording ?? this.isRecording,
      isPlayingVoice: isPlayingVoice ?? this.isPlayingVoice,
      isPlayingTts: isPlayingTts ?? this.isPlayingTts,
      searchResults: searchResults ?? this.searchResults,
      currentLanguage: currentLanguage ?? this.currentLanguage,
      isConnected: isConnected ?? this.isConnected,
      offlineQueue: offlineQueue ?? this.offlineQueue,
      isOfflineMode: isOfflineMode ?? this.isOfflineMode,
      lastResponseFromCache:
          lastResponseFromCache ?? this.lastResponseFromCache,
    );
  }

  @override
  List<Object?> get props => [
        session,
        quickSuggestions,
        isTyping,
        isRecording,
        isPlayingVoice,
        isPlayingTts,
        searchResults,
        currentLanguage,
        isConnected,
        offlineQueue,
        isOfflineMode,
        lastResponseFromCache,
      ];
}

class ChatError extends ChatState {
  final String message;

  const ChatError(this.message);

  @override
  List<Object?> get props => [message];
}

class VoiceRecordingState extends ChatState {
  final bool isRecording;
  final Duration recordingDuration;
  final List<double> waveformData;

  const VoiceRecordingState({
    required this.isRecording,
    required this.recordingDuration,
    this.waveformData = const [],
  });

  @override
  List<Object?> get props => [isRecording, recordingDuration, waveformData];
}

class MessageSent extends ChatState {
  final ChatMessage message;

  const MessageSent(this.message);

  @override
  List<Object?> get props => [message];
}

class ExportSuccess extends ChatState {
  final String exportPath;

  const ExportSuccess(this.exportPath);

  @override
  List<Object?> get props => [exportPath];
}

class OfflineQueueProcessed extends ChatState {
  final int processedCount;

  const OfflineQueueProcessed(this.processedCount);

  @override
  List<Object?> get props => [processedCount];
}
