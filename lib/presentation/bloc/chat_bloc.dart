import 'dart:async';
import 'dart:math';
import 'dart:io';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:uuid/uuid.dart';
import '../../domain/entities/chat_message.dart';
import '../../domain/usecases/chat_usecases.dart';
import 'chat_event.dart';
import 'chat_state.dart';

class ChatBloc extends Bloc<ChatEvent, ChatState> {
  final SendMessageUseCase sendMessageUseCase;
  final GetChatSessionUseCase getChatSessionUseCase;
  final SearchMessagesUseCase searchMessagesUseCase;
  final SaveAsFaqUseCase saveAsFaqUseCase;
  final ExportChatHistoryUseCase exportChatHistoryUseCase;
  final GetQuickSuggestionsUseCase getQuickSuggestionsUseCase;
  final ProcessOfflineQueueUseCase processOfflineQueueUseCase;

  late final FlutterTts _flutterTts;
  late final SpeechToText _speechToText;
  late final FlutterSoundRecorder _audioRecorder;
  late final StreamSubscription<List<ConnectivityResult>>
      _connectivitySubscription;

  String _currentSessionId = '';
  Timer? _typingTimer;
  Timer? _recordingTimer;
  bool _isConnected = true;
  bool _isRecorderInitialized = false;
  bool _isCurrentlyRecording = false;

  ChatBloc({
    required this.sendMessageUseCase,
    required this.getChatSessionUseCase,
    required this.searchMessagesUseCase,
    required this.saveAsFaqUseCase,
    required this.exportChatHistoryUseCase,
    required this.getQuickSuggestionsUseCase,
    required this.processOfflineQueueUseCase,
  }) : super(ChatInitial()) {
    _initializeServices();
    _setupConnectivityListener();

    on<LoadChatSession>(_onLoadChatSession);
    on<SendMessage>(_onSendMessage);
    on<StartVoiceRecording>(_onStartVoiceRecording);
    on<StopVoiceRecording>(_onStopVoiceRecording);
    on<PlayVoiceMessage>(_onPlayVoiceMessage);
    on<ToggleMessageFavorite>(_onToggleMessageFavorite);
    on<SaveMessageAsFaq>(_onSaveMessageAsFaq);
    on<SearchMessages>(_onSearchMessages);
    on<ExportChatHistory>(_onExportChatHistory);
    on<LoadQuickSuggestions>(_onLoadQuickSuggestions);
    on<ChangeLanguage>(_onChangeLanguage);
    on<ClearChat>(_onClearChat);
    on<ProcessOfflineQueue>(_onProcessOfflineQueue);
    on<StartTyping>(_onStartTyping);
    on<StopTyping>(_onStopTyping);
    on<PlayTextToSpeech>(_onPlayTextToSpeech);
    on<StopTextToSpeech>(_onStopTextToSpeech);
  }

  void _initializeServices() async {
    _flutterTts = FlutterTts();
    _speechToText = SpeechToText();
    _audioRecorder = FlutterSoundRecorder();

    // Initialize the recorder
    try {
      await _audioRecorder.openRecorder();
      _isRecorderInitialized = true;
    } catch (e) {
      print('Failed to initialize recorder: $e');
      _isRecorderInitialized = false;
    }

    _flutterTts.setCompletionHandler(() {
      // Note: emit can only be called within event handlers
      // Handle completion in the event handler instead
    });
  }

  void _setupConnectivityListener() {
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen(
      (List<ConnectivityResult> results) {
        _isConnected = !results.contains(ConnectivityResult.none);
        // Note: emit can only be called within event handlers
        if (_isConnected) {
          add(ProcessOfflineQueue());
        }
      },
    );
  }

  Future<void> _onLoadChatSession(
      LoadChatSession event, Emitter<ChatState> emit) async {
    try {
      emit(ChatLoading());

      _currentSessionId = event.sessionId;
      ChatSession? session =
          await getChatSessionUseCase.execute(event.sessionId);

      // Create new session if it doesn't exist
      session ??= ChatSession(
        id: event.sessionId,
        title: 'New Chat',
        createdAt: DateTime.now(),
        lastMessageAt: DateTime.now(),
        messages: [
          ChatMessage(
            id: const Uuid().v4(),
            text:
                'Hello! I\'m your AI teaching assistant. How can I help you today?',
            isUser: false,
            timestamp: DateTime.now(),
          ),
        ],
        language: 'en',
      );

      final quickSuggestions = await getQuickSuggestionsUseCase.execute('');
      final offlineQueue = await processOfflineQueueUseCase.execute();

      emit(ChatLoaded(
        session: session,
        quickSuggestions: quickSuggestions,
        currentLanguage: session.language,
        isConnected: _isConnected,
        offlineQueue: offlineQueue,
      ));
    } catch (e) {
      emit(ChatError('Failed to load chat session: ${e.toString()}'));
    }
  }

  Future<void> _onSendMessage(
      SendMessage event, Emitter<ChatState> emit) async {
    if (state is! ChatLoaded) return;

    final currentState = state as ChatLoaded;

    try {
      final userMessage = ChatMessage(
        id: const Uuid().v4(),
        text: event.text,
        isUser: true,
        timestamp: DateTime.now(),
        type: event.type,
        voiceFilePath: event.voiceFilePath,
        voiceDuration: event.voiceDuration,
        language: currentState.currentLanguage,
      );

      // Add user message to session
      final updatedMessages =
          List<ChatMessage>.from(currentState.session.messages)
            ..add(userMessage);

      final updatedSession = currentState.session.copyWith(
        messages: updatedMessages,
        lastMessageAt: DateTime.now(),
      );

      emit(currentState.copyWith(
        session: updatedSession,
        isTyping: true,
      ));

      // Save message locally
      if (_isConnected) {
        await sendMessageUseCase.execute(userMessage, _currentSessionId);
      } else {
        // Add to offline queue
        // await addToOfflineQueueUseCase.execute(userMessage);
      }

      // Simulate AI response
      await Future.delayed(const Duration(seconds: 2));

      final aiResponse = ChatMessage(
        id: const Uuid().v4(),
        text: _generateAIResponse(event.text, currentState.currentLanguage),
        isUser: false,
        timestamp: DateTime.now(),
        language: currentState.currentLanguage,
      );

      final finalMessages = List<ChatMessage>.from(updatedMessages)
        ..add(aiResponse);

      final finalSession = updatedSession.copyWith(
        messages: finalMessages,
        lastMessageAt: DateTime.now(),
      );

      if (_isConnected) {
        await sendMessageUseCase.execute(aiResponse, _currentSessionId);
      }

      emit(currentState.copyWith(
        session: finalSession,
        isTyping: false,
      ));
    } catch (e) {
      emit(ChatError('Failed to send message: ${e.toString()}'));
    }
  }

  String _generateAIResponse(String userMessage, String languageCode) {
    final message = userMessage.toLowerCase();

    if (message.contains('lesson') || message.contains('plan')) {
      return _getLessonPlanResponse(languageCode);
    } else if (message.contains('quiz') || message.contains('test')) {
      return _getQuizResponse(languageCode);
    } else if (message.contains('story')) {
      return _getStoryResponse(languageCode);
    } else {
      return _getGeneralResponse(languageCode);
    }
  }

  String _getLessonPlanResponse(String languageCode) {
    switch (languageCode) {
      case 'hi':
        return 'मैं आपके लिए एक पाठ योजना तैयार करने में मदद कर सकता हूं। कृपया बताएं कि यह किस विषय और कक्षा के लिए है?';
      case 'te':
        return 'నేను మీ కోసం పాఠ ప్రణాళికను తయారు చేయడంలో సహాయం చేయగలను. దయచేసి ఇది ఏ విషయం మరియు తరగతి కోసం అని చెప్పండి?';
      default:
        return 'I can help you create a lesson plan! Please tell me what subject and grade level you\'re planning for.';
    }
  }

  String _getQuizResponse(String languageCode) {
    switch (languageCode) {
      case 'hi':
        return 'मैं आपके लिए एक प्रश्नोत्तरी बना सकता हूं। कृपया विषय, कक्षा स्तर और प्रश्नों की संख्या बताएं।';
      case 'te':
        return 'నేను మీ కోసం క్విజ్ను రూపొందించగలను. దయచేసి విషయం, తరగతి స్థాయి మరియు ప్రశ్నల సంఖ్యను చెప్పండి.';
      default:
        return 'I can create a quiz for you! Please specify the subject, grade level, and number of questions you need.';
    }
  }

  String _getStoryResponse(String languageCode) {
    switch (languageCode) {
      case 'hi':
        return 'मैं आपके लिए एक शिक्षाप्रद कहानी बना सकता हूं। आप किस विषय या नैतिक मूल्य पर कहानी चाहते हैं?';
      case 'te':
        return 'నేను మీ కోసం ఒక విద్యాసంబంధమైన కథను రూపొందించగలను. మీరు ఏ విషయం లేదా నైతిక విలువపై కథ కావాలి?';
      default:
        return 'I can create an educational story for you! What topic or moral value would you like the story to focus on?';
    }
  }

  String _getGeneralResponse(String languageCode) {
    switch (languageCode) {
      case 'hi':
        return 'मैं आपकी शिक्षण आवश्यकताओं में मदद करने के लिए यहां हूं। कृपया बताएं कि आपको किस प्रकार की सहायता चाहिए?';
      case 'te':
        return 'నేను మీ బోధనా అవసరాలతో సహాయం చేయడానికి ఇక్కడ ఉన్నాను. దయచేసి మీకు ఏ రకమైన సహాయం కావాలో చెప్పండి?';
      default:
        return 'I\'m here to help with your teaching needs! Please let me know what kind of assistance you\'re looking for.';
    }
  }

  Future<void> _onStartVoiceRecording(
      StartVoiceRecording event, Emitter<ChatState> emit) async {
    if (state is! ChatLoaded) return;

    final currentState = state as ChatLoaded;

    try {
      // Check permissions
      final micPermission = await Permission.microphone.request();
      if (micPermission != PermissionStatus.granted) {
        emit(ChatError('Microphone permission denied'));
        return;
      }

      // Initialize speech recognition
      bool speechAvailable = await _speechToText.initialize();
      if (!speechAvailable) {
        emit(ChatError('Speech recognition not available'));
        return;
      }

      // Ensure recorder is initialized
      if (!_isRecorderInitialized) {
        await _audioRecorder.openRecorder();
        _isRecorderInitialized = true;
      }

      // Check if already recording
      if (_isCurrentlyRecording) {
        emit(ChatError('Recording is already in progress'));
        return;
      }

      // Get proper file path
      final directory = await getTemporaryDirectory();
      final fileName =
          'voice_recording_${DateTime.now().millisecondsSinceEpoch}.aac';
      final filePath = '${directory.path}/$fileName';

      // Start recording
      await _audioRecorder.startRecorder(
        toFile: filePath,
        codec: Codec.aacADTS,
      );

      _isCurrentlyRecording = true;
      emit(currentState.copyWith(isRecording: true));

      // Start recording timer for waveform visualization
      _recordingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (_isCurrentlyRecording) {
          // Update recording duration and waveform visualization
          final waveformData =
              List.generate(20, (index) => Random().nextDouble());
          emit(VoiceRecordingState(
            isRecording: true,
            recordingDuration: Duration(seconds: timer.tick),
            waveformData: waveformData,
          ));
        }
      });
    } catch (e) {
      _isCurrentlyRecording = false;
      emit(ChatError('Failed to start recording: ${e.toString()}'));
    }
  }

  Future<void> _onStopVoiceRecording(
      StopVoiceRecording event, Emitter<ChatState> emit) async {
    if (state is! ChatLoaded && state is! VoiceRecordingState) return;

    try {
      // Cancel recording timer first
      _recordingTimer?.cancel();

      // Check if we're actually recording
      if (!_isCurrentlyRecording) {
        emit(ChatError('No recording in progress'));
        return;
      }

      // Stop the recorder
      String? path;
      try {
        path = await _audioRecorder.stopRecorder();
        _isCurrentlyRecording = false;
      } catch (e) {
        _isCurrentlyRecording = false;
        emit(ChatError('Failed to stop recording: ${e.toString()}'));
        return;
      }

      if (path != null && path.isNotEmpty) {
        // Verify file exists
        final file = File(path);
        if (await file.exists()) {
          // Start speech recognition
          _speechToText.listen(
            onResult: (result) {
              if (result.finalResult && result.recognizedWords.isNotEmpty) {
                add(SendMessage(
                  text: result.recognizedWords,
                  type: MessageType.voice,
                  voiceFilePath: path,
                ));
              }
            },
          );
        } else {
          emit(ChatError('Recording file not found'));
          return;
        }
      } else {
        emit(ChatError('No recording path returned'));
        return;
      }

      // Update UI state
      if (state is ChatLoaded) {
        emit((state as ChatLoaded).copyWith(isRecording: false));
      } else {
        // Return to previous chat state
        emit(ChatLoading());
      }
    } catch (e) {
      _isCurrentlyRecording = false;
      _recordingTimer?.cancel();
      emit(ChatError('Failed to stop recording: ${e.toString()}'));
    }
  }

  Future<void> _onPlayVoiceMessage(
      PlayVoiceMessage event, Emitter<ChatState> emit) async {
    if (state is! ChatLoaded) return;

    final currentState = state as ChatLoaded;

    try {
      emit(currentState.copyWith(isPlayingVoice: true));

      // Simulate voice playback
      await Future.delayed(const Duration(seconds: 3));

      emit(currentState.copyWith(isPlayingVoice: false));
    } catch (e) {
      emit(ChatError('Failed to play voice message: ${e.toString()}'));
    }
  }

  Future<void> _onToggleMessageFavorite(
      ToggleMessageFavorite event, Emitter<ChatState> emit) async {
    if (state is! ChatLoaded) return;

    final currentState = state as ChatLoaded;

    try {
      final messages = currentState.session.messages.map((message) {
        if (message.id == event.messageId) {
          return message.copyWith(isFavorite: !message.isFavorite);
        }
        return message;
      }).toList();

      final updatedSession = currentState.session.copyWith(messages: messages);
      emit(currentState.copyWith(session: updatedSession));
    } catch (e) {
      emit(ChatError('Failed to toggle favorite: ${e.toString()}'));
    }
  }

  Future<void> _onSaveMessageAsFaq(
      SaveMessageAsFaq event, Emitter<ChatState> emit) async {
    if (state is! ChatLoaded) return;

    final currentState = state as ChatLoaded;

    try {
      final message = currentState.session.messages.firstWhere(
        (m) => m.id == event.messageId,
      );

      await saveAsFaqUseCase.execute(message);

      final messages = currentState.session.messages.map((m) {
        if (m.id == event.messageId) {
          return m.copyWith(isSavedAsFaq: true);
        }
        return m;
      }).toList();

      final updatedSession = currentState.session.copyWith(messages: messages);
      emit(currentState.copyWith(session: updatedSession));
    } catch (e) {
      emit(ChatError('Failed to save as FAQ: ${e.toString()}'));
    }
  }

  Future<void> _onSearchMessages(
      SearchMessages event, Emitter<ChatState> emit) async {
    if (state is! ChatLoaded) return;

    final currentState = state as ChatLoaded;

    try {
      final searchResults = await searchMessagesUseCase.execute(event.query);
      emit(currentState.copyWith(searchResults: searchResults));
    } catch (e) {
      emit(ChatError('Failed to search messages: ${e.toString()}'));
    }
  }

  Future<void> _onExportChatHistory(
      ExportChatHistory event, Emitter<ChatState> emit) async {
    try {
      final exportData =
          await exportChatHistoryUseCase.execute(_currentSessionId);
      emit(ExportSuccess(exportData));
    } catch (e) {
      emit(ChatError('Failed to export chat history: ${e.toString()}'));
    }
  }

  Future<void> _onLoadQuickSuggestions(
      LoadQuickSuggestions event, Emitter<ChatState> emit) async {
    if (state is! ChatLoaded) return;

    final currentState = state as ChatLoaded;

    try {
      final suggestions =
          await getQuickSuggestionsUseCase.execute(event.category);
      emit(currentState.copyWith(quickSuggestions: suggestions));
    } catch (e) {
      emit(ChatError('Failed to load suggestions: ${e.toString()}'));
    }
  }

  Future<void> _onChangeLanguage(
      ChangeLanguage event, Emitter<ChatState> emit) async {
    if (state is! ChatLoaded) return;

    final currentState = state as ChatLoaded;

    try {
      await _flutterTts.setLanguage(event.languageCode);
      emit(currentState.copyWith(currentLanguage: event.languageCode));
    } catch (e) {
      emit(ChatError('Failed to change language: ${e.toString()}'));
    }
  }

  Future<void> _onClearChat(ClearChat event, Emitter<ChatState> emit) async {
    if (state is! ChatLoaded) return;

    final currentState = state as ChatLoaded;

    try {
      final clearedSession = currentState.session.copyWith(
        messages: [
          ChatMessage(
            id: const Uuid().v4(),
            text:
                'Hello! I\'m your AI teaching assistant. How can I help you today?',
            isUser: false,
            timestamp: DateTime.now(),
          ),
        ],
      );

      emit(currentState.copyWith(session: clearedSession));
    } catch (e) {
      emit(ChatError('Failed to clear chat: ${e.toString()}'));
    }
  }

  Future<void> _onProcessOfflineQueue(
      ProcessOfflineQueue event, Emitter<ChatState> emit) async {
    if (state is! ChatLoaded) return;

    try {
      final offlineMessages = await processOfflineQueueUseCase.execute();

      // Process offline messages when connected
      if (_isConnected && offlineMessages.isNotEmpty) {
        for (final message in offlineMessages) {
          await sendMessageUseCase.execute(message, _currentSessionId);
        }

        emit(OfflineQueueProcessed(offlineMessages.length));
      }
    } catch (e) {
      emit(ChatError('Failed to process offline queue: ${e.toString()}'));
    }
  }

  void _onStartTyping(StartTyping event, Emitter<ChatState> emit) {
    if (state is! ChatLoaded) return;

    final currentState = state as ChatLoaded;
    emit(currentState.copyWith(isTyping: true));

    _typingTimer?.cancel();
    _typingTimer = Timer(const Duration(seconds: 3), () {
      add(StopTyping());
    });
  }

  void _onStopTyping(StopTyping event, Emitter<ChatState> emit) {
    if (state is! ChatLoaded) return;

    final currentState = state as ChatLoaded;
    emit(currentState.copyWith(isTyping: false));
    _typingTimer?.cancel();
  }

  Future<void> _onPlayTextToSpeech(
      PlayTextToSpeech event, Emitter<ChatState> emit) async {
    if (state is! ChatLoaded) return;

    final currentState = state as ChatLoaded;

    try {
      emit(currentState.copyWith(isPlayingTts: true));

      await _flutterTts.setLanguage(event.languageCode);
      await _flutterTts.speak(event.text);
    } catch (e) {
      emit(currentState.copyWith(isPlayingTts: false));
      emit(ChatError('Failed to play text-to-speech: ${e.toString()}'));
    }
  }

  Future<void> _onStopTextToSpeech(
      StopTextToSpeech event, Emitter<ChatState> emit) async {
    if (state is! ChatLoaded) return;

    final currentState = state as ChatLoaded;

    try {
      await _flutterTts.stop();
      emit(currentState.copyWith(isPlayingTts: false));
    } catch (e) {
      emit(ChatError('Failed to stop text-to-speech: ${e.toString()}'));
    }
  }

  @override
  Future<void> close() async {
    _typingTimer?.cancel();
    _recordingTimer?.cancel();
    _connectivitySubscription.cancel();
    _flutterTts.stop();
    _speechToText.stop();

    // Properly close the recorder
    if (_isRecorderInitialized) {
      try {
        if (_isCurrentlyRecording) {
          await _audioRecorder.stopRecorder();
        }
        await _audioRecorder.closeRecorder();
      } catch (e) {
        print('Error closing recorder: $e');
      }
    }

    return super.close();
  }
}
