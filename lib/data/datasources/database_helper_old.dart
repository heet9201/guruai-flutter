import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../../core/constants/app_constants.dart';

class DatabaseHelper {
  static Database? _database;
  static final DatabaseHelper instance = DatabaseHelper._init();

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final databasesPath = await getDatabasesPath();
    final path = join(databasesPath, AppConstants.databaseName);

    return await openDatabase(
      path,
      version: AppConstants.databaseVersion,
      onCreate: _createDatabase,
      onUpgrade: _upgradeDatabase,
    );
  }

  Future<void> _createDatabase(Database db, int version) async {
    // Create basic tables
    await db.execute('''
      CREATE TABLE IF NOT EXISTS users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        email TEXT UNIQUE NOT NULL,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS conversations (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        title TEXT NOT NULL,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS messages (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        conversation_id INTEGER NOT NULL,
        content TEXT NOT NULL,
        is_user_message INTEGER NOT NULL DEFAULT 0,
        created_at TEXT NOT NULL,
        FOREIGN KEY (conversation_id) REFERENCES conversations (id) ON DELETE CASCADE
      )
    ''');

    // Initialize offline repository tables
    await _createOfflineTables(db);
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

    // Create indexes for better performance
    await _createIndexes(db);
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

  Future<void> _upgradeDatabase(
      Database db, int oldVersion, int newVersion) async {
    // Handle database upgrades here
    if (oldVersion < 2) {
      // Add new columns or tables for version 2
      await _createOfflineTables(db);
    }
  }

  Future<void> close() async {
    final db = await instance.database;
    await db.close();
    _database = null;
  }

  Future<void> deleteDatabase() async {
    final databasesPath = await getDatabasesPath();
    final path = join(databasesPath, AppConstants.databaseName);
    await databaseFactory.deleteDatabase(path);
    _database = null;
  }
}
