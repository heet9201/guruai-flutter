import '../../domain/entities/chat_message.dart';

class ChatMessageModel extends ChatMessage {
  const ChatMessageModel({
    required super.id,
    required super.text,
    required super.isUser,
    required super.timestamp,
    super.type = MessageType.text,
    super.status = MessageStatus.sent,
    super.voiceFilePath,
    super.voiceDuration,
    super.isFavorite = false,
    super.isSavedAsFaq = false,
    super.language,
  });

  factory ChatMessageModel.fromJson(Map<String, dynamic> json) {
    return ChatMessageModel(
      id: json['id'],
      text: json['text'],
      isUser: json['isUser'],
      timestamp: DateTime.parse(json['timestamp']),
      type: MessageType.values.firstWhere(
        (e) => e.toString() == 'MessageType.${json['type']}',
        orElse: () => MessageType.text,
      ),
      status: MessageStatus.values.firstWhere(
        (e) => e.toString() == 'MessageStatus.${json['status']}',
        orElse: () => MessageStatus.sent,
      ),
      voiceFilePath: json['voiceFilePath'],
      voiceDuration: json['voiceDuration'] != null
          ? Duration(milliseconds: json['voiceDuration'])
          : null,
      isFavorite: json['isFavorite'] ?? false,
      isSavedAsFaq: json['isSavedAsFaq'] ?? false,
      language: json['language'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'text': text,
      'isUser': isUser,
      'timestamp': timestamp.toIso8601String(),
      'type': type.toString().split('.').last,
      'status': status.toString().split('.').last,
      'voiceFilePath': voiceFilePath,
      'voiceDuration': voiceDuration?.inMilliseconds,
      'isFavorite': isFavorite,
      'isSavedAsFaq': isSavedAsFaq,
      'language': language,
    };
  }

  ChatMessageModel copyWith({
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
    return ChatMessageModel(
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
}

class ChatSessionModel extends ChatSession {
  const ChatSessionModel({
    required super.id,
    required super.title,
    required super.createdAt,
    required super.lastMessageAt,
    required super.messages,
    required super.language,
  });

  factory ChatSessionModel.fromJson(Map<String, dynamic> json) {
    return ChatSessionModel(
      id: json['id'],
      title: json['title'],
      createdAt: DateTime.parse(json['createdAt']),
      lastMessageAt: DateTime.parse(json['lastMessageAt']),
      messages: (json['messages'] as List)
          .map((msg) => ChatMessageModel.fromJson(msg))
          .toList(),
      language: json['language'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'createdAt': createdAt.toIso8601String(),
      'lastMessageAt': lastMessageAt.toIso8601String(),
      'messages':
          messages.map((msg) => (msg as ChatMessageModel).toJson()).toList(),
      'language': language,
    };
  }
}

class QuickSuggestionModel extends QuickSuggestion {
  const QuickSuggestionModel({
    required super.id,
    required super.text,
    required super.category,
    required super.translations,
  });

  factory QuickSuggestionModel.fromJson(Map<String, dynamic> json) {
    return QuickSuggestionModel(
      id: json['id'],
      text: json['text'],
      category: json['category'],
      translations: Map<String, String>.from(json['translations']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'text': text,
      'category': category,
      'translations': translations,
    };
  }
}
