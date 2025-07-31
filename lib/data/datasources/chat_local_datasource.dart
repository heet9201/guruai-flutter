import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/chat_models.dart';
import '../../domain/entities/chat_message.dart';

abstract class ChatLocalDataSource {
  Future<List<ChatSessionModel>> getChatSessions();
  Future<ChatSessionModel?> getChatSession(String sessionId);
  Future<void> saveChatSession(ChatSessionModel session);
  Future<void> deleteChatSession(String sessionId);
  Future<void> saveMessage(ChatMessageModel message, String sessionId);
  Future<void> updateMessage(ChatMessageModel message);
  Future<void> deleteMessage(String messageId);
  Future<List<ChatMessageModel>> searchMessages(String query);
  Future<List<ChatMessageModel>> getFaqMessages();
  Future<void> saveAsFaq(ChatMessageModel message);
  Future<String> exportChatHistory(String sessionId);
  Future<List<ChatMessageModel>> getOfflineQueue();
  Future<void> addToOfflineQueue(ChatMessageModel message);
  Future<void> removeFromOfflineQueue(String messageId);
  Future<List<QuickSuggestionModel>> getQuickSuggestions(String category);
}

class ChatLocalDataSourceImpl implements ChatLocalDataSource {
  static const String _offlineQueueKey = 'offline_queue';

  Database? _database;

  Future<Database> get database async {
    _database ??= await _initDB();
    return _database!;
  }

  Future<Database> _initDB() async {
    String path = join(await getDatabasesPath(), 'chat_database.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE chat_sessions(
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        created_at TEXT NOT NULL,
        last_message_at TEXT NOT NULL,
        language TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE chat_messages(
        id TEXT PRIMARY KEY,
        session_id TEXT NOT NULL,
        text TEXT NOT NULL,
        is_user INTEGER NOT NULL,
        timestamp TEXT NOT NULL,
        type TEXT NOT NULL,
        status TEXT NOT NULL,
        voice_file_path TEXT,
        voice_duration INTEGER,
        is_favorite INTEGER DEFAULT 0,
        is_saved_as_faq INTEGER DEFAULT 0,
        language TEXT,
        FOREIGN KEY(session_id) REFERENCES chat_sessions(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE offline_queue(
        id TEXT PRIMARY KEY,
        message_data TEXT NOT NULL,
        created_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE quick_suggestions(
        id TEXT PRIMARY KEY,
        text TEXT NOT NULL,
        category TEXT NOT NULL,
        translations TEXT NOT NULL
      )
    ''');

    // Insert default quick suggestions
    await _insertDefaultSuggestions(db);
  }

  Future<void> _insertDefaultSuggestions(Database db) async {
    final suggestions = [
      QuickSuggestionModel(
        id: '1',
        text: 'How do I create a lesson plan?',
        category: 'lesson_planning',
        translations: {
          'en': 'How do I create a lesson plan?',
          'hi': 'मैं एक पाठ योजना कैसे बनाऊं?',
          'te': 'నేను పాఠ ప్రణాళికను ఎలా సృష్టించాలి?',
        },
      ),
      QuickSuggestionModel(
        id: '2',
        text: 'Generate a quiz for Grade 5 Math',
        category: 'assessment',
        translations: {
          'en': 'Generate a quiz for Grade 5 Math',
          'hi': 'कक्षा 5 गणित के लिए एक प्रश्नोत्तरी बनाएं',
          'te': 'గ్రేడ్ 5 మ్యాథ్ కోసం క్విజ్ను రూపొందించండి',
        },
      ),
      QuickSuggestionModel(
        id: '3',
        text: 'Create a story for teaching moral values',
        category: 'content_creation',
        translations: {
          'en': 'Create a story for teaching moral values',
          'hi': 'नैतिक मूल्य सिखाने के लिए एक कहानी बनाएं',
          'te': 'నైతిక విలువలను బోధించడానికి కథను రూపొందించండి',
        },
      ),
      QuickSuggestionModel(
        id: '4',
        text: 'Explain photosynthesis in simple terms',
        category: 'science',
        translations: {
          'en': 'Explain photosynthesis in simple terms',
          'hi': 'प्रकाश संश्लेषण को सरल शब्दों में समझाएं',
          'te': 'కిరణజన్య సంయోగాన్ని సరళమైన పదాలలో వివరించండి',
        },
      ),
    ];

    for (final suggestion in suggestions) {
      await db.insert('quick_suggestions', {
        'id': suggestion.id,
        'text': suggestion.text,
        'category': suggestion.category,
        'translations': jsonEncode(suggestion.translations),
      });
    }
  }

  @override
  Future<List<ChatSessionModel>> getChatSessions() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'chat_sessions',
      orderBy: 'last_message_at DESC',
    );

    List<ChatSessionModel> sessions = [];
    for (var map in maps) {
      final messages = await _getMessagesForSession(map['id']);
      sessions.add(ChatSessionModel(
        id: map['id'],
        title: map['title'],
        createdAt: DateTime.parse(map['created_at']),
        lastMessageAt: DateTime.parse(map['last_message_at']),
        messages: messages,
        language: map['language'],
      ));
    }
    return sessions;
  }

  Future<List<ChatMessageModel>> _getMessagesForSession(
      String sessionId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'chat_messages',
      where: 'session_id = ?',
      whereArgs: [sessionId],
      orderBy: 'timestamp ASC',
    );

    return maps.map((map) => _mapToMessage(map)).toList();
  }

  ChatMessageModel _mapToMessage(Map<String, dynamic> map) {
    return ChatMessageModel(
      id: map['id'],
      text: map['text'],
      isUser: map['is_user'] == 1,
      timestamp: DateTime.parse(map['timestamp']),
      type: MessageType.values.firstWhere(
        (e) => e.toString() == 'MessageType.${map['type']}',
        orElse: () => MessageType.text,
      ),
      status: MessageStatus.values.firstWhere(
        (e) => e.toString() == 'MessageStatus.${map['status']}',
        orElse: () => MessageStatus.sent,
      ),
      voiceFilePath: map['voice_file_path'],
      voiceDuration: map['voice_duration'] != null
          ? Duration(milliseconds: map['voice_duration'])
          : null,
      isFavorite: map['is_favorite'] == 1,
      isSavedAsFaq: map['is_saved_as_faq'] == 1,
      language: map['language'],
    );
  }

  @override
  Future<ChatSessionModel?> getChatSession(String sessionId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'chat_sessions',
      where: 'id = ?',
      whereArgs: [sessionId],
    );

    if (maps.isEmpty) return null;

    final messages = await _getMessagesForSession(sessionId);
    return ChatSessionModel(
      id: maps.first['id'],
      title: maps.first['title'],
      createdAt: DateTime.parse(maps.first['created_at']),
      lastMessageAt: DateTime.parse(maps.first['last_message_at']),
      messages: messages,
      language: maps.first['language'],
    );
  }

  @override
  Future<void> saveChatSession(ChatSessionModel session) async {
    final db = await database;
    await db.insert(
      'chat_sessions',
      {
        'id': session.id,
        'title': session.title,
        'created_at': session.createdAt.toIso8601String(),
        'last_message_at': session.lastMessageAt.toIso8601String(),
        'language': session.language,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  @override
  Future<void> deleteChatSession(String sessionId) async {
    final db = await database;
    await db.delete(
      'chat_sessions',
      where: 'id = ?',
      whereArgs: [sessionId],
    );
  }

  @override
  Future<void> saveMessage(ChatMessageModel message, String sessionId) async {
    final db = await database;
    await db.insert(
      'chat_messages',
      {
        'id': message.id,
        'session_id': sessionId,
        'text': message.text,
        'is_user': message.isUser ? 1 : 0,
        'timestamp': message.timestamp.toIso8601String(),
        'type': message.type.toString().split('.').last,
        'status': message.status.toString().split('.').last,
        'voice_file_path': message.voiceFilePath,
        'voice_duration': message.voiceDuration?.inMilliseconds,
        'is_favorite': message.isFavorite ? 1 : 0,
        'is_saved_as_faq': message.isSavedAsFaq ? 1 : 0,
        'language': message.language,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  @override
  Future<void> updateMessage(ChatMessageModel message) async {
    final db = await database;
    await db.update(
      'chat_messages',
      {
        'text': message.text,
        'status': message.status.toString().split('.').last,
        'voice_file_path': message.voiceFilePath,
        'voice_duration': message.voiceDuration?.inMilliseconds,
        'is_favorite': message.isFavorite ? 1 : 0,
        'is_saved_as_faq': message.isSavedAsFaq ? 1 : 0,
      },
      where: 'id = ?',
      whereArgs: [message.id],
    );
  }

  @override
  Future<void> deleteMessage(String messageId) async {
    final db = await database;
    await db.delete(
      'chat_messages',
      where: 'id = ?',
      whereArgs: [messageId],
    );
  }

  @override
  Future<List<ChatMessageModel>> searchMessages(String query) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'chat_messages',
      where: 'text LIKE ?',
      whereArgs: ['%$query%'],
      orderBy: 'timestamp DESC',
    );

    return maps.map((map) => _mapToMessage(map)).toList();
  }

  @override
  Future<List<ChatMessageModel>> getFaqMessages() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'chat_messages',
      where: 'is_saved_as_faq = ?',
      whereArgs: [1],
      orderBy: 'timestamp DESC',
    );

    return maps.map((map) => _mapToMessage(map)).toList();
  }

  @override
  Future<void> saveAsFaq(ChatMessageModel message) async {
    final updatedMessage = message.copyWith(isSavedAsFaq: true);
    await updateMessage(updatedMessage);
  }

  @override
  Future<String> exportChatHistory(String sessionId) async {
    final session = await getChatSession(sessionId);
    if (session == null) return '';

    final buffer = StringBuffer();
    buffer.writeln('Chat Session: ${session.title}');
    buffer.writeln('Created: ${session.createdAt}');
    buffer.writeln('Language: ${session.language}');
    buffer.writeln('---');

    for (final message in session.messages) {
      final sender = message.isUser ? 'User' : 'AI';
      buffer.writeln('[$sender] ${message.timestamp}: ${message.text}');
    }

    return buffer.toString();
  }

  @override
  Future<List<ChatMessageModel>> getOfflineQueue() async {
    final prefs = await SharedPreferences.getInstance();
    final queueJson = prefs.getStringList(_offlineQueueKey) ?? [];

    return queueJson
        .map((json) => ChatMessageModel.fromJson(jsonDecode(json)))
        .toList();
  }

  @override
  Future<void> addToOfflineQueue(ChatMessageModel message) async {
    final prefs = await SharedPreferences.getInstance();
    final queue = await getOfflineQueue();
    queue.add(message);

    final queueJson = queue.map((msg) => jsonEncode(msg.toJson())).toList();
    await prefs.setStringList(_offlineQueueKey, queueJson);
  }

  @override
  Future<void> removeFromOfflineQueue(String messageId) async {
    final prefs = await SharedPreferences.getInstance();
    final queue = await getOfflineQueue();
    queue.removeWhere((msg) => msg.id == messageId);

    final queueJson = queue.map((msg) => jsonEncode(msg.toJson())).toList();
    await prefs.setStringList(_offlineQueueKey, queueJson);
  }

  @override
  Future<List<QuickSuggestionModel>> getQuickSuggestions(
      String category) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'quick_suggestions',
      where: category.isNotEmpty ? 'category = ?' : null,
      whereArgs: category.isNotEmpty ? [category] : null,
    );

    return maps
        .map((map) => QuickSuggestionModel(
              id: map['id'],
              text: map['text'],
              category: map['category'],
              translations:
                  Map<String, String>.from(jsonDecode(map['translations'])),
            ))
        .toList();
  }
}
