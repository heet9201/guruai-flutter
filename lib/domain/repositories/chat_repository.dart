import '../entities/chat_message.dart';

abstract class ChatRepository {
  Future<List<ChatSession>> getChatSessions();
  Future<ChatSession?> getChatSession(String sessionId);
  Future<void> saveChatSession(ChatSession session);
  Future<void> deleteChatSession(String sessionId);
  Future<void> saveMessage(ChatMessage message, String sessionId);
  Future<void> updateMessage(ChatMessage message);
  Future<void> deleteMessage(String messageId);
  Future<List<ChatMessage>> searchMessages(String query);
  Future<List<ChatMessage>> getFaqMessages();
  Future<void> saveAsFaq(ChatMessage message);
  Future<String> exportChatHistory(String sessionId);
  Future<List<ChatMessage>> getOfflineQueue();
  Future<void> addToOfflineQueue(ChatMessage message);
  Future<void> removeFromOfflineQueue(String messageId);
  Future<List<QuickSuggestion>> getQuickSuggestions(String category);
}
