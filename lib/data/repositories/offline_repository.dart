import 'dart:async';
import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import '../../domain/entities/weekly_plan.dart';
import '../datasources/database_helper.dart';

enum CacheCategory {
  aiResponses,
  userContent,
  lessonPlans,
  faqs,
  quickSuggestions,
  weeklyPlans,
}

class OfflineRepository {
  static OfflineRepository? _instance;
  static OfflineRepository get instance => _instance ??= OfflineRepository._();

  OfflineRepository._();

  Database get _database => DatabaseHelper.instance.database as Database;

  // Cache size limits (in MB)
  static const int maxCacheSizeMB = 100;
  static const int maxAiResponsesPerCategory = 10;
  static const int maxUserContentItems = 50;
  static const int maxLessonPlans = 20;
  static const int maxFaqs = 100;

  /// Initialize offline database tables
  Future<void> initializeOfflineDatabase() async {
    final db = await DatabaseHelper.instance.database;

    await _createOfflineTables(db);
    await _createIndexes(db);
  }

  Future<void> _createOfflineTables(Database db) async {
    // Cached AI responses table
    await db.execute('''
      CREATE TABLE IF NOT EXISTS cached_ai_responses (
        id TEXT PRIMARY KEY,
        category TEXT NOT NULL,
        query TEXT NOT NULL,
        response TEXT NOT NULL,
        language_code TEXT NOT NULL,
        cached_at INTEGER NOT NULL,
        access_count INTEGER DEFAULT 0,
        last_accessed INTEGER NOT NULL,
        size_bytes INTEGER NOT NULL
      )
    ''');

    // Offline queue table for actions to sync
    await db.execute('''
      CREATE TABLE IF NOT EXISTS offline_queue (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        action_type TEXT NOT NULL,
        data TEXT NOT NULL,
        created_at INTEGER NOT NULL,
        retry_count INTEGER DEFAULT 0,
        priority INTEGER DEFAULT 0
      )
    ''');

    // Cached user content table
    await db.execute('''
      CREATE TABLE IF NOT EXISTS cached_user_content (
        id TEXT PRIMARY KEY,
        type TEXT NOT NULL,
        title TEXT NOT NULL,
        content TEXT NOT NULL,
        metadata TEXT,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL,
        size_bytes INTEGER NOT NULL,
        is_synced INTEGER DEFAULT 0
      )
    ''');

    // Cached lesson plans table
    await db.execute('''
      CREATE TABLE IF NOT EXISTS cached_lesson_plans (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        subject TEXT NOT NULL,
        grade_level TEXT NOT NULL,
        content TEXT NOT NULL,
        objectives TEXT,
        materials TEXT,
        duration_minutes INTEGER,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL,
        size_bytes INTEGER NOT NULL,
        is_synced INTEGER DEFAULT 0
      )
    ''');

    // Cached FAQs table
    await db.execute('''
      CREATE TABLE IF NOT EXISTS cached_faqs (
        id TEXT PRIMARY KEY,
        question TEXT NOT NULL,
        answer TEXT NOT NULL,
        category TEXT NOT NULL,
        language_code TEXT NOT NULL,
        created_at INTEGER NOT NULL,
        access_count INTEGER DEFAULT 0,
        last_accessed INTEGER NOT NULL,
        size_bytes INTEGER NOT NULL
      )
    ''');

    // Cache metadata table for storage management
    await db.execute('''
      CREATE TABLE IF NOT EXISTS cache_metadata (
        table_name TEXT PRIMARY KEY,
        total_size_bytes INTEGER DEFAULT 0,
        item_count INTEGER DEFAULT 0,
        last_cleanup INTEGER DEFAULT 0
      )
    ''');

    // Sync status table
    await db.execute('''
      CREATE TABLE IF NOT EXISTS sync_status (
        id INTEGER PRIMARY KEY,
        last_sync_timestamp INTEGER DEFAULT 0,
        last_successful_sync INTEGER DEFAULT 0,
        pending_sync_count INTEGER DEFAULT 0,
        sync_in_progress INTEGER DEFAULT 0
      )
    ''');
  }

  Future<void> _createIndexes(Database db) async {
    await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_ai_responses_category ON cached_ai_responses(category)');
    await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_ai_responses_language ON cached_ai_responses(language_code)');
    await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_ai_responses_cached_at ON cached_ai_responses(cached_at)');
    await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_offline_queue_created_at ON offline_queue(created_at)');
    await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_offline_queue_priority ON offline_queue(priority DESC)');
    await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_user_content_type ON cached_user_content(type)');
    await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_lesson_plans_subject ON cached_lesson_plans(subject)');
    await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_faqs_category ON cached_faqs(category)');
  }

  /// Cache AI response
  Future<void> cacheAiResponse({
    required String id,
    required String category,
    required String query,
    required String response,
    required String languageCode,
  }) async {
    final db = await DatabaseHelper.instance.database;
    final now = DateTime.now().millisecondsSinceEpoch;
    final sizeBytes = utf8.encode(response).length;

    await db.insert(
      'cached_ai_responses',
      {
        'id': id,
        'category': category,
        'query': query,
        'response': response,
        'language_code': languageCode,
        'cached_at': now,
        'last_accessed': now,
        'size_bytes': sizeBytes,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    await _maintainCacheLimits(CacheCategory.aiResponses);
    await _updateCacheMetadata('cached_ai_responses');
  }

  /// Get cached AI responses by category
  Future<List<Map<String, dynamic>>> getCachedAiResponses({
    required String category,
    String? languageCode,
    int limit = 10,
  }) async {
    final db = await DatabaseHelper.instance.database;
    final now = DateTime.now().millisecondsSinceEpoch;

    String whereClause = 'category = ?';
    List<dynamic> whereArgs = [category];

    if (languageCode != null) {
      whereClause += ' AND language_code = ?';
      whereArgs.add(languageCode);
    }

    final results = await db.query(
      'cached_ai_responses',
      where: whereClause,
      whereArgs: whereArgs,
      orderBy: 'last_accessed DESC, cached_at DESC',
      limit: limit,
    );

    // Update access count and last accessed time
    for (final result in results) {
      await db.update(
        'cached_ai_responses',
        {
          'access_count': (result['access_count'] as int) + 1,
          'last_accessed': now,
        },
        where: 'id = ?',
        whereArgs: [result['id']],
      );
    }

    return results;
  }

  /// Add action to offline queue
  Future<void> addToOfflineQueue({
    required String actionType,
    required Map<String, dynamic> data,
    int priority = 0,
  }) async {
    final db = await DatabaseHelper.instance.database;
    final now = DateTime.now().millisecondsSinceEpoch;

    await db.insert('offline_queue', {
      'action_type': actionType,
      'data': jsonEncode(data),
      'created_at': now,
      'priority': priority,
    });

    await _updateSyncStatus();
  }

  /// Get pending offline actions
  Future<List<Map<String, dynamic>>> getPendingOfflineActions() async {
    final db = await DatabaseHelper.instance.database;

    return await db.query(
      'offline_queue',
      orderBy: 'priority DESC, created_at ASC',
    );
  }

  /// Remove action from offline queue
  Future<void> removeFromOfflineQueue(int id) async {
    final db = await DatabaseHelper.instance.database;

    await db.delete(
      'offline_queue',
      where: 'id = ?',
      whereArgs: [id],
    );

    await _updateSyncStatus();
  }

  /// Cache user content
  Future<void> cacheUserContent({
    required String id,
    required String type,
    required String title,
    required String content,
    Map<String, dynamic>? metadata,
  }) async {
    final db = await DatabaseHelper.instance.database;
    final now = DateTime.now().millisecondsSinceEpoch;
    final sizeBytes = utf8.encode(content).length;

    await db.insert(
      'cached_user_content',
      {
        'id': id,
        'type': type,
        'title': title,
        'content': content,
        'metadata': metadata != null ? jsonEncode(metadata) : null,
        'created_at': now,
        'updated_at': now,
        'size_bytes': sizeBytes,
        'is_synced': 0,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    await _maintainCacheLimits(CacheCategory.userContent);
    await _updateCacheMetadata('cached_user_content');
  }

  /// Get cached user content
  Future<List<Map<String, dynamic>>> getCachedUserContent({
    String? type,
    int limit = 50,
  }) async {
    final db = await DatabaseHelper.instance.database;

    String? whereClause;
    List<dynamic>? whereArgs;

    if (type != null) {
      whereClause = 'type = ?';
      whereArgs = [type];
    }

    return await db.query(
      'cached_user_content',
      where: whereClause,
      whereArgs: whereArgs,
      orderBy: 'updated_at DESC',
      limit: limit,
    );
  }

  /// Cache lesson plan
  Future<void> cacheLessonPlan(WeeklyPlan plan) async {
    final db = await DatabaseHelper.instance.database;
    final now = DateTime.now().millisecondsSinceEpoch;
    final content = jsonEncode({
      'id': plan.id,
      'title': plan.title,
      'description': plan.description,
      'weekStart': plan.weekStart.toIso8601String(),
      'dayPlans': plan.dayPlans
          .map((day) => {
                'date': day.date.toIso8601String(),
                'activities': day.activities
                    .map((activity) => {
                          'id': activity.id,
                          'title': activity.title,
                          'description': activity.description,
                          'type': activity.type.toString(),
                          'subject': activity.subject.toString(),
                          'grade': activity.grade.toString(),
                          'duration': activity.duration.inMinutes,
                          'materials': activity.materials,
                          'objectives': activity.objectives,
                        })
                    .toList(),
              })
          .toList(),
      'targetGrades': plan.targetGrades.map((g) => g.toString()).toList(),
      'isTemplate': plan.isTemplate,
      'templateCategory': plan.templateCategory,
    });
    final sizeBytes = utf8.encode(content).length;

    // Get primary subject from activities
    final subjects =
        plan.allActivities.map((a) => a.subject.toString()).toSet();
    final primarySubject = subjects.isNotEmpty ? subjects.first : 'General';

    // Get primary grade level
    final primaryGrade = plan.targetGrades.isNotEmpty
        ? plan.targetGrades.first.toString()
        : 'Unknown';

    await db.insert(
      'cached_lesson_plans',
      {
        'id': plan.id,
        'title': plan.title,
        'subject': primarySubject,
        'grade_level': primaryGrade,
        'content': content,
        'objectives': plan.allActivities
            .map((a) => a.objectives)
            .where((o) => o != null)
            .join(', '),
        'materials': plan.allActivities
            .map((a) => a.materials)
            .where((m) => m != null)
            .join(', '),
        'duration_minutes': plan.totalWeekDuration.inMinutes,
        'created_at': plan.createdAt.millisecondsSinceEpoch,
        'updated_at': now,
        'size_bytes': sizeBytes,
        'is_synced': 0,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    await _maintainCacheLimits(CacheCategory.lessonPlans);
    await _updateCacheMetadata('cached_lesson_plans');
  }

  /// Get cached lesson plans
  Future<List<Map<String, dynamic>>> getCachedLessonPlans({
    String? subject,
    String? gradeLevel,
    int limit = 20,
  }) async {
    final db = await DatabaseHelper.instance.database;

    String whereClause = '1=1';
    List<dynamic> whereArgs = [];

    if (subject != null) {
      whereClause += ' AND subject = ?';
      whereArgs.add(subject);
    }

    if (gradeLevel != null) {
      whereClause += ' AND grade_level = ?';
      whereArgs.add(gradeLevel);
    }

    return await db.query(
      'cached_lesson_plans',
      where: whereClause,
      whereArgs: whereArgs.isNotEmpty ? whereArgs : null,
      orderBy: 'updated_at DESC',
      limit: limit,
    );
  }

  /// Cache FAQ
  Future<void> cacheFaq({
    required String id,
    required String question,
    required String answer,
    required String category,
    required String languageCode,
  }) async {
    final db = await DatabaseHelper.instance.database;
    final now = DateTime.now().millisecondsSinceEpoch;
    final sizeBytes = utf8.encode(question + answer).length;

    await db.insert(
      'cached_faqs',
      {
        'id': id,
        'question': question,
        'answer': answer,
        'category': category,
        'language_code': languageCode,
        'created_at': now,
        'last_accessed': now,
        'size_bytes': sizeBytes,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    await _maintainCacheLimits(CacheCategory.faqs);
    await _updateCacheMetadata('cached_faqs');
  }

  /// Search cached FAQs
  Future<List<Map<String, dynamic>>> searchCachedFaqs({
    required String query,
    String? category,
    String? languageCode,
    int limit = 10,
  }) async {
    final db = await DatabaseHelper.instance.database;
    final now = DateTime.now().millisecondsSinceEpoch;

    String whereClause = '(question LIKE ? OR answer LIKE ?)';
    List<dynamic> whereArgs = ['%$query%', '%$query%'];

    if (category != null) {
      whereClause += ' AND category = ?';
      whereArgs.add(category);
    }

    if (languageCode != null) {
      whereClause += ' AND language_code = ?';
      whereArgs.add(languageCode);
    }

    final results = await db.query(
      'cached_faqs',
      where: whereClause,
      whereArgs: whereArgs,
      orderBy: 'last_accessed DESC, created_at DESC',
      limit: limit,
    );

    // Update access count and last accessed time
    for (final result in results) {
      await db.update(
        'cached_faqs',
        {
          'access_count': (result['access_count'] as int) + 1,
          'last_accessed': now,
        },
        where: 'id = ?',
        whereArgs: [result['id']],
      );
    }

    return results;
  }

  /// Get cache statistics
  Future<Map<String, dynamic>> getCacheStatistics() async {
    final db = await DatabaseHelper.instance.database;

    final aiResponsesCount = Sqflite.firstIntValue(
          await db.rawQuery('SELECT COUNT(*) FROM cached_ai_responses'),
        ) ??
        0;

    final userContentCount = Sqflite.firstIntValue(
          await db.rawQuery('SELECT COUNT(*) FROM cached_user_content'),
        ) ??
        0;

    final lessonPlansCount = Sqflite.firstIntValue(
          await db.rawQuery('SELECT COUNT(*) FROM cached_lesson_plans'),
        ) ??
        0;

    final faqsCount = Sqflite.firstIntValue(
          await db.rawQuery('SELECT COUNT(*) FROM cached_faqs'),
        ) ??
        0;

    final queueCount = Sqflite.firstIntValue(
          await db.rawQuery('SELECT COUNT(*) FROM offline_queue'),
        ) ??
        0;

    // Calculate total cache size
    final totalSize = await _calculateTotalCacheSize();

    return {
      'aiResponsesCount': aiResponsesCount,
      'userContentCount': userContentCount,
      'lessonPlansCount': lessonPlansCount,
      'faqsCount': faqsCount,
      'queueCount': queueCount,
      'totalSizeMB': totalSize / (1024 * 1024),
      'maxSizeMB': maxCacheSizeMB,
      'cacheUsagePercent': (totalSize / (maxCacheSizeMB * 1024 * 1024)) * 100,
    };
  }

  /// Clean up old cache entries
  Future<void> cleanupCache() async {
    final db = await DatabaseHelper.instance.database;
    final now = DateTime.now().millisecondsSinceEpoch;
    final thirtyDaysAgo = now - (30 * 24 * 60 * 60 * 1000); // 30 days

    // Remove old AI responses that haven't been accessed recently
    await db.delete(
      'cached_ai_responses',
      where: 'last_accessed < ? AND access_count < 2',
      whereArgs: [thirtyDaysAgo],
    );

    // Remove old unsynced user content (older than 7 days)
    final sevenDaysAgo = now - (7 * 24 * 60 * 60 * 1000);
    await db.delete(
      'cached_user_content',
      where: 'updated_at < ? AND is_synced = 0',
      whereArgs: [sevenDaysAgo],
    );

    // Update cache metadata
    await _updateAllCacheMetadata();

    // Update cleanup timestamp
    await db.insert(
      'cache_metadata',
      {
        'table_name': 'last_cleanup',
        'last_cleanup': now,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Maintain cache limits for specific category
  Future<void> _maintainCacheLimits(CacheCategory category) async {
    final db = await DatabaseHelper.instance.database;

    switch (category) {
      case CacheCategory.aiResponses:
        // Keep only the most recent and frequently accessed responses per category
        final categories = await db.rawQuery(
          'SELECT DISTINCT category FROM cached_ai_responses',
        );

        for (final categoryData in categories) {
          final categoryName = categoryData['category'] as String;
          final responses = await db.query(
            'cached_ai_responses',
            where: 'category = ?',
            whereArgs: [categoryName],
            orderBy: 'access_count DESC, last_accessed DESC',
          );

          if (responses.length > maxAiResponsesPerCategory) {
            final toDelete = responses.skip(maxAiResponsesPerCategory);
            for (final response in toDelete) {
              await db.delete(
                'cached_ai_responses',
                where: 'id = ?',
                whereArgs: [response['id']],
              );
            }
          }
        }
        break;

      case CacheCategory.userContent:
        final content = await db.query(
          'cached_user_content',
          orderBy: 'updated_at DESC',
        );

        if (content.length > maxUserContentItems) {
          final toDelete = content.skip(maxUserContentItems);
          for (final item in toDelete) {
            await db.delete(
              'cached_user_content',
              where: 'id = ?',
              whereArgs: [item['id']],
            );
          }
        }
        break;

      case CacheCategory.lessonPlans:
        final plans = await db.query(
          'cached_lesson_plans',
          orderBy: 'updated_at DESC',
        );

        if (plans.length > maxLessonPlans) {
          final toDelete = plans.skip(maxLessonPlans);
          for (final plan in toDelete) {
            await db.delete(
              'cached_lesson_plans',
              where: 'id = ?',
              whereArgs: [plan['id']],
            );
          }
        }
        break;

      case CacheCategory.faqs:
        final faqs = await db.query(
          'cached_faqs',
          orderBy: 'access_count DESC, last_accessed DESC',
        );

        if (faqs.length > maxFaqs) {
          final toDelete = faqs.skip(maxFaqs);
          for (final faq in toDelete) {
            await db.delete(
              'cached_faqs',
              where: 'id = ?',
              whereArgs: [faq['id']],
            );
          }
        }
        break;

      case CacheCategory.quickSuggestions:
      case CacheCategory.weeklyPlans:
        // These are handled differently based on app requirements
        break;
    }
  }

  /// Update cache metadata for a specific table
  Future<void> _updateCacheMetadata(String tableName) async {
    final db = await DatabaseHelper.instance.database;

    final count = Sqflite.firstIntValue(
          await db.rawQuery('SELECT COUNT(*) FROM $tableName'),
        ) ??
        0;

    final sizeResult = await db.rawQuery(
      'SELECT SUM(size_bytes) as total_size FROM $tableName',
    );
    final totalSize = sizeResult.first['total_size'] as int? ?? 0;

    await db.insert(
      'cache_metadata',
      {
        'table_name': tableName,
        'total_size_bytes': totalSize,
        'item_count': count,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Update all cache metadata
  Future<void> _updateAllCacheMetadata() async {
    final tables = [
      'cached_ai_responses',
      'cached_user_content',
      'cached_lesson_plans',
      'cached_faqs',
    ];

    for (final table in tables) {
      await _updateCacheMetadata(table);
    }
  }

  /// Calculate total cache size
  Future<int> _calculateTotalCacheSize() async {
    final db = await DatabaseHelper.instance.database;

    final result = await db.rawQuery('''
      SELECT 
        (SELECT COALESCE(SUM(size_bytes), 0) FROM cached_ai_responses) +
        (SELECT COALESCE(SUM(size_bytes), 0) FROM cached_user_content) +
        (SELECT COALESCE(SUM(size_bytes), 0) FROM cached_lesson_plans) +
        (SELECT COALESCE(SUM(size_bytes), 0) FROM cached_faqs) as total_size
    ''');

    return result.first['total_size'] as int? ?? 0;
  }

  /// Update sync status
  Future<void> _updateSyncStatus() async {
    final db = await DatabaseHelper.instance.database;
    final now = DateTime.now().millisecondsSinceEpoch;

    final queueCount = Sqflite.firstIntValue(
          await db.rawQuery('SELECT COUNT(*) FROM offline_queue'),
        ) ??
        0;

    await db.insert(
      'sync_status',
      {
        'id': 1,
        'last_sync_timestamp': now,
        'pending_sync_count': queueCount,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Get sync status
  Future<Map<String, dynamic>?> getSyncStatus() async {
    final db = await DatabaseHelper.instance.database;

    final result = await db.query(
      'sync_status',
      where: 'id = ?',
      whereArgs: [1],
      limit: 1,
    );

    return result.isNotEmpty ? result.first : null;
  }

  /// Mark sync as in progress
  Future<void> setSyncInProgress(bool inProgress) async {
    final db = await DatabaseHelper.instance.database;

    await db.update(
      'sync_status',
      {'sync_in_progress': inProgress ? 1 : 0},
      where: 'id = ?',
      whereArgs: [1],
    );
  }

  /// Clear all cache
  Future<void> clearAllCache() async {
    final db = await DatabaseHelper.instance.database;

    await db.delete('cached_ai_responses');
    await db.delete('cached_user_content');
    await db.delete('cached_lesson_plans');
    await db.delete('cached_faqs');
    await db.delete('cache_metadata');

    await _updateAllCacheMetadata();
  }
}
