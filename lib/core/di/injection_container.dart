import 'package:get_it/get_it.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

// Domain
import '../../domain/repositories/weekly_plan_repository.dart';

// Data
import '../../data/repositories/weekly_plan_repository_impl.dart';
import '../../data/datasources/weekly_plan_local_datasource.dart';

// Presentation
import '../../presentation/bloc/weekly_planner_bloc.dart';

final sl = GetIt.instance;

Future<void> initializeDependencies() async {
  // Database
  final database = await _initDatabase();
  sl.registerLazySingleton<Database>(() => database);

  // Data sources
  sl.registerLazySingleton<WeeklyPlanLocalDataSource>(
    () => WeeklyPlanLocalDataSourceImpl(sl()),
  );

  // Repositories
  sl.registerLazySingleton<WeeklyPlanRepository>(
    () => WeeklyPlanRepositoryImpl(localDataSource: sl()),
  );

  // BLoC
  sl.registerFactory(() => WeeklyPlannerBloc(repository: sl()));
}

Future<Database> _initDatabase() async {
  String path = join(await getDatabasesPath(), 'weekly_planner.db');

  return await openDatabase(
    path,
    version: 1,
    onCreate: (db, version) async {
      // Create weekly_plans table
      await db.execute('''
        CREATE TABLE weekly_plans(
          id TEXT PRIMARY KEY,
          title TEXT NOT NULL,
          startDate TEXT NOT NULL,
          endDate TEXT NOT NULL,
          grade TEXT NOT NULL,
          subject TEXT,
          isTemplate INTEGER NOT NULL DEFAULT 0,
          createdAt TEXT NOT NULL,
          updatedAt TEXT NOT NULL
        )
      ''');

      // Create lesson_activities table
      await db.execute('''
        CREATE TABLE lesson_activities(
          id TEXT PRIMARY KEY,
          weeklyPlanId TEXT NOT NULL,
          title TEXT NOT NULL,
          description TEXT,
          activityType TEXT NOT NULL,
          subject TEXT NOT NULL,
          grade TEXT NOT NULL,
          date TEXT NOT NULL,
          startTime TEXT NOT NULL,
          endTime TEXT NOT NULL,
          estimatedDuration INTEGER NOT NULL,
          actualDuration INTEGER,
          materialsNeeded TEXT,
          notes TEXT,
          isCompleted INTEGER NOT NULL DEFAULT 0,
          colorCode TEXT,
          createdAt TEXT NOT NULL,
          updatedAt TEXT NOT NULL,
          FOREIGN KEY (weeklyPlanId) REFERENCES weekly_plans (id) ON DELETE CASCADE
        )
      ''');

      // Create activity_suggestions table
      await db.execute('''
        CREATE TABLE activity_suggestions(
          id TEXT PRIMARY KEY,
          title TEXT NOT NULL,
          description TEXT,
          activityType TEXT NOT NULL,
          subject TEXT NOT NULL,
          grade TEXT NOT NULL,
          estimatedDuration INTEGER NOT NULL,
          difficulty TEXT NOT NULL,
          materialsNeeded TEXT,
          tags TEXT,
          source TEXT,
          isBookmarked INTEGER NOT NULL DEFAULT 0,
          usageCount INTEGER NOT NULL DEFAULT 0,
          createdAt TEXT NOT NULL
        )
      ''');

      // Create indexes for better performance
      await db.execute(
          'CREATE INDEX idx_activities_weekly_plan ON lesson_activities(weeklyPlanId)');
      await db.execute(
          'CREATE INDEX idx_activities_date ON lesson_activities(date)');
      await db.execute(
          'CREATE INDEX idx_activities_grade ON lesson_activities(grade)');
      await db.execute(
          'CREATE INDEX idx_activities_subject ON lesson_activities(subject)');
      await db.execute(
          'CREATE INDEX idx_suggestions_grade ON activity_suggestions(grade)');
      await db.execute(
          'CREATE INDEX idx_suggestions_subject ON activity_suggestions(subject)');
      await db.execute(
          'CREATE INDEX idx_suggestions_type ON activity_suggestions(activityType)');
    },
  );
}
