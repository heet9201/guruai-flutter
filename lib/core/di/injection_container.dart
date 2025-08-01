import 'package:get_it/get_it.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

// Domain
import '../../domain/repositories/weekly_plan_repository.dart';

// Data
import '../../data/repositories/weekly_plan_repository_impl.dart';
import '../../data/datasources/weekly_plan_local_datasource.dart';

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

  // TODO: Register use cases when they are implemented
  // BLoC
  // sl.registerFactory(() => WeeklyPlannerBloc(repository: sl()));
}

Future<Database> _initDatabase() async {
  String path = join(await getDatabasesPath(), 'weekly_planner.db');

  return await openDatabase(
    path,
    version: 1,
    onCreate: (db, version) async {
      // Use the database schema from WeeklyPlanLocalDataSource
      await WeeklyPlanLocalDataSourceImpl.createTables(db);
    },
  );
}
