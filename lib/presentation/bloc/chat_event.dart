import 'package:equatable/equatable.dart';
import '../../domain/entities/chat_message.dart';

abstract class ChatEvent extends Equatable {
  const ChatEvent();

  @override
  List<Object?> get props => [];
}

class LoadChatSession extends ChatEvent {
  final String sessionId;

  const LoadChatSession(this.sessionId);

  @override
  List<Object?> get props => [sessionId];
}

class SendMessage extends ChatEvent {
  final String text;
  final MessageType type;
  final String? voiceFilePath;
  final Duration? voiceDuration;

  const SendMessage({
    required this.text,
    this.type = MessageType.text,
    this.voiceFilePath,
    this.voiceDuration,
  });

  @override
  List<Object?> get props => [text, type, voiceFilePath, voiceDuration];
}

class StartVoiceRecording extends ChatEvent {}

class StopVoiceRecording extends ChatEvent {}

class PlayVoiceMessage extends ChatEvent {
  final String voiceFilePath;

  const PlayVoiceMessage(this.voiceFilePath);

  @override
  List<Object?> get props => [voiceFilePath];
}

class ToggleMessageFavorite extends ChatEvent {
  final String messageId;

  const ToggleMessageFavorite(this.messageId);

  @override
  List<Object?> get props => [messageId];
}

class SaveMessageAsFaq extends ChatEvent {
  final String messageId;

  const SaveMessageAsFaq(this.messageId);

  @override
  List<Object?> get props => [messageId];
}

class SearchMessages extends ChatEvent {
  final String query;

  const SearchMessages(this.query);

  @override
  List<Object?> get props => [query];
}

class ExportChatHistory extends ChatEvent {}

class LoadQuickSuggestions extends ChatEvent {
  final String category;

  const LoadQuickSuggestions(this.category);

  @override
  List<Object?> get props => [category];
}

class ChangeLanguage extends ChatEvent {
  final String languageCode;

  const ChangeLanguage(this.languageCode);

  @override
  List<Object?> get props => [languageCode];
}

class ClearChat extends ChatEvent {}

class ProcessOfflineQueue extends ChatEvent {}

class StartTyping extends ChatEvent {}

class StopTyping extends ChatEvent {}

class PlayTextToSpeech extends ChatEvent {
  final String text;
  final String languageCode;

  const PlayTextToSpeech(this.text, this.languageCode);

  @override
  List<Object?> get props => [text, languageCode];
}

class StopTextToSpeech extends ChatEvent {}
