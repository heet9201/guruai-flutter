import '../entities/chat_message.dart';
import '../repositories/chat_repository.dart';

class SendMessageUseCase {
  final ChatRepository repository;

  SendMessageUseCase(this.repository);

  Future<void> execute(ChatMessage message, String sessionId) async {
    await repository.saveMessage(message, sessionId);
  }
}

class GetChatSessionUseCase {
  final ChatRepository repository;

  GetChatSessionUseCase(this.repository);

  Future<ChatSession?> execute(String sessionId) async {
    return await repository.getChatSession(sessionId);
  }
}

class SearchMessagesUseCase {
  final ChatRepository repository;

  SearchMessagesUseCase(this.repository);

  Future<List<ChatMessage>> execute(String query) async {
    return await repository.searchMessages(query);
  }
}

class SaveAsFaqUseCase {
  final ChatRepository repository;

  SaveAsFaqUseCase(this.repository);

  Future<void> execute(ChatMessage message) async {
    await repository.saveAsFaq(message);
  }
}

class ExportChatHistoryUseCase {
  final ChatRepository repository;

  ExportChatHistoryUseCase(this.repository);

  Future<String> execute(String sessionId) async {
    return await repository.exportChatHistory(sessionId);
  }
}

class GetQuickSuggestionsUseCase {
  final ChatRepository repository;

  GetQuickSuggestionsUseCase(this.repository);

  Future<List<QuickSuggestion>> execute(String category) async {
    return await repository.getQuickSuggestions(category);
  }
}

class ProcessOfflineQueueUseCase {
  final ChatRepository repository;

  ProcessOfflineQueueUseCase(this.repository);

  Future<List<ChatMessage>> execute() async {
    return await repository.getOfflineQueue();
  }
}
