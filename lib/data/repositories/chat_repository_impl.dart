import '../../domain/entities/chat_message.dart';
import '../../domain/repositories/chat_repository.dart';
import '../datasources/chat_local_datasource.dart';
import '../models/chat_models.dart';

class ChatRepositoryImpl implements ChatRepository {
  final ChatLocalDataSource localDataSource;

  ChatRepositoryImpl({required this.localDataSource});

  @override
  Future<List<ChatSession>> getChatSessions() async {
    final sessions = await localDataSource.getChatSessions();
    return sessions.cast<ChatSession>();
  }

  @override
  Future<ChatSession?> getChatSession(String sessionId) async {
    return await localDataSource.getChatSession(sessionId);
  }

  @override
  Future<void> saveChatSession(ChatSession session) async {
    final sessionModel = ChatSessionModel(
      id: session.id,
      title: session.title,
      createdAt: session.createdAt,
      lastMessageAt: session.lastMessageAt,
      messages: session.messages.cast<ChatMessageModel>(),
      language: session.language,
    );
    await localDataSource.saveChatSession(sessionModel);
  }

  @override
  Future<void> deleteChatSession(String sessionId) async {
    await localDataSource.deleteChatSession(sessionId);
  }

  @override
  Future<void> saveMessage(ChatMessage message, String sessionId) async {
    final messageModel = ChatMessageModel(
      id: message.id,
      text: message.text,
      isUser: message.isUser,
      timestamp: message.timestamp,
      type: message.type,
      status: message.status,
      voiceFilePath: message.voiceFilePath,
      voiceDuration: message.voiceDuration,
      isFavorite: message.isFavorite,
      isSavedAsFaq: message.isSavedAsFaq,
      language: message.language,
    );
    await localDataSource.saveMessage(messageModel, sessionId);
  }

  @override
  Future<void> updateMessage(ChatMessage message) async {
    final messageModel = ChatMessageModel(
      id: message.id,
      text: message.text,
      isUser: message.isUser,
      timestamp: message.timestamp,
      type: message.type,
      status: message.status,
      voiceFilePath: message.voiceFilePath,
      voiceDuration: message.voiceDuration,
      isFavorite: message.isFavorite,
      isSavedAsFaq: message.isSavedAsFaq,
      language: message.language,
    );
    await localDataSource.updateMessage(messageModel);
  }

  @override
  Future<void> deleteMessage(String messageId) async {
    await localDataSource.deleteMessage(messageId);
  }

  @override
  Future<List<ChatMessage>> searchMessages(String query) async {
    final messages = await localDataSource.searchMessages(query);
    return messages.cast<ChatMessage>();
  }

  @override
  Future<List<ChatMessage>> getFaqMessages() async {
    final messages = await localDataSource.getFaqMessages();
    return messages.cast<ChatMessage>();
  }

  @override
  Future<void> saveAsFaq(ChatMessage message) async {
    final messageModel = ChatMessageModel(
      id: message.id,
      text: message.text,
      isUser: message.isUser,
      timestamp: message.timestamp,
      type: message.type,
      status: message.status,
      voiceFilePath: message.voiceFilePath,
      voiceDuration: message.voiceDuration,
      isFavorite: message.isFavorite,
      isSavedAsFaq: message.isSavedAsFaq,
      language: message.language,
    );
    await localDataSource.saveAsFaq(messageModel);
  }

  @override
  Future<String> exportChatHistory(String sessionId) async {
    return await localDataSource.exportChatHistory(sessionId);
  }

  @override
  Future<List<ChatMessage>> getOfflineQueue() async {
    final messages = await localDataSource.getOfflineQueue();
    return messages.cast<ChatMessage>();
  }

  @override
  Future<void> addToOfflineQueue(ChatMessage message) async {
    final messageModel = ChatMessageModel(
      id: message.id,
      text: message.text,
      isUser: message.isUser,
      timestamp: message.timestamp,
      type: message.type,
      status: message.status,
      voiceFilePath: message.voiceFilePath,
      voiceDuration: message.voiceDuration,
      isFavorite: message.isFavorite,
      isSavedAsFaq: message.isSavedAsFaq,
      language: message.language,
    );
    await localDataSource.addToOfflineQueue(messageModel);
  }

  @override
  Future<void> removeFromOfflineQueue(String messageId) async {
    await localDataSource.removeFromOfflineQueue(messageId);
  }

  @override
  Future<List<QuickSuggestion>> getQuickSuggestions(String category) async {
    final suggestions = await localDataSource.getQuickSuggestions(category);
    return suggestions.cast<QuickSuggestion>();
  }
}
