import 'package:equatable/equatable.dart';

enum MessageType { text, voice, image }

enum MessageStatus { sending, sent, delivered, read, error }

class ChatMessage extends Equatable {
  final String id;
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final MessageType type;
  final MessageStatus status;
  final String? voiceFilePath;
  final Duration? voiceDuration;
  final bool isFavorite;
  final bool isSavedAsFaq;
  final String? language;

  const ChatMessage({
    required this.id,
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.type = MessageType.text,
    this.status = MessageStatus.sent,
    this.voiceFilePath,
    this.voiceDuration,
    this.isFavorite = false,
    this.isSavedAsFaq = false,
    this.language,
  });

  ChatMessage copyWith({
    String? id,
    String? text,
    bool? isUser,
    DateTime? timestamp,
    MessageType? type,
    MessageStatus? status,
    String? voiceFilePath,
    Duration? voiceDuration,
    bool? isFavorite,
    bool? isSavedAsFaq,
    String? language,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      text: text ?? this.text,
      isUser: isUser ?? this.isUser,
      timestamp: timestamp ?? this.timestamp,
      type: type ?? this.type,
      status: status ?? this.status,
      voiceFilePath: voiceFilePath ?? this.voiceFilePath,
      voiceDuration: voiceDuration ?? this.voiceDuration,
      isFavorite: isFavorite ?? this.isFavorite,
      isSavedAsFaq: isSavedAsFaq ?? this.isSavedAsFaq,
      language: language ?? this.language,
    );
  }

  @override
  List<Object?> get props => [
        id,
        text,
        isUser,
        timestamp,
        type,
        status,
        voiceFilePath,
        voiceDuration,
        isFavorite,
        isSavedAsFaq,
        language,
      ];
}

class QuickSuggestion extends Equatable {
  final String id;
  final String text;
  final String category;
  final Map<String, String> translations;

  const QuickSuggestion({
    required this.id,
    required this.text,
    required this.category,
    required this.translations,
  });

  String getTranslation(String languageCode) {
    return translations[languageCode] ?? text;
  }

  @override
  List<Object?> get props => [id, text, category, translations];
}

class ChatSession extends Equatable {
  final String id;
  final String title;
  final DateTime createdAt;
  final DateTime lastMessageAt;
  final List<ChatMessage> messages;
  final String language;

  const ChatSession({
    required this.id,
    required this.title,
    required this.createdAt,
    required this.lastMessageAt,
    required this.messages,
    required this.language,
  });

  ChatSession copyWith({
    String? id,
    String? title,
    DateTime? createdAt,
    DateTime? lastMessageAt,
    List<ChatMessage>? messages,
    String? language,
  }) {
    return ChatSession(
      id: id ?? this.id,
      title: title ?? this.title,
      createdAt: createdAt ?? this.createdAt,
      lastMessageAt: lastMessageAt ?? this.lastMessageAt,
      messages: messages ?? this.messages,
      language: language ?? this.language,
    );
  }

  @override
  List<Object?> get props => [
        id,
        title,
        createdAt,
        lastMessageAt,
        messages,
        language,
      ];
}
