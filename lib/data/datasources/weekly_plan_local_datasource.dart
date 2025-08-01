import 'package:sqflite/sqflite.dart';
import '../../domain/entities/weekly_plan.dart';
import '../models/weekly_plan_model.dart';

abstract class WeeklyPlanLocalDataSource {
  // Weekly Plan methods
  Future<List<WeeklyPlanModel>> getWeeklyPlans();
  Future<WeeklyPlanModel?> getWeeklyPlan(String id);
  Future<WeeklyPlanModel?> getWeeklyPlanByDate(DateTime weekStart);
  Future<String> saveWeeklyPlan(WeeklyPlanModel plan);
  Future<void> updateWeeklyPlan(WeeklyPlanModel plan);
  Future<void> deleteWeeklyPlan(String id);
  Future<List<WeeklyPlanModel>> getTemplates();
  Future<List<WeeklyPlanModel>> searchWeeklyPlans(String query);

  // Activity methods
  Future<List<LessonActivityModel>> getActivities();
  Future<LessonActivityModel?> getActivity(String id);
  Future<String> saveActivity(LessonActivityModel activity);
  Future<void> updateActivity(LessonActivityModel activity);
  Future<void> deleteActivity(String activityId);
  Future<List<LessonActivityModel>> searchActivities(String query);
  Future<List<LessonActivityModel>> getActivitiesBySubject(String subject);
  Future<List<LessonActivityModel>> getActivitiesByGrade(String grade);
  Future<List<LessonActivityModel>> getActivitiesByType(String type);

  // Day Plan methods
  Future<List<DayPlan>> getDayPlansForWeek(String weeklyPlanId);
  Future<void> saveDayPlan(String weeklyPlanId, DayPlan dayPlan);

  // Activity suggestions methods
  Future<List<LessonActivity>> getActivitiesForDay(String dayPlanId);
  Future<List<LessonActivity>> getActivitySuggestions(
      String subject, String grade);
  Future<void> saveActivitySuggestion(LessonActivity activity);
  Future<void> deleteActivitySuggestion(String activityId);
}

class WeeklyPlanLocalDataSourceImpl implements WeeklyPlanLocalDataSource {
  final Database database;

  WeeklyPlanLocalDataSourceImpl(this.database);

  @override
  Future<List<WeeklyPlanModel>> getWeeklyPlans() async {
    final maps = await database.query(
      'weekly_plans',
      orderBy: 'created_at DESC',
    );

    final plans = <WeeklyPlanModel>[];
    for (final map in maps) {
      final plan = WeeklyPlanModel.fromMap(map);
      final dayPlans = await getDayPlansForWeek(plan.id);
      plans.add(plan.copyWith(dayPlans: dayPlans));
    }

    return plans;
  }

  @override
  Future<WeeklyPlanModel?> getWeeklyPlan(String id) async {
    final maps = await database.query(
      'weekly_plans',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isEmpty) return null;

    final plan = WeeklyPlanModel.fromMap(maps.first);
    final dayPlans = await getDayPlansForWeek(id);
    return plan.copyWith(dayPlans: dayPlans);
  }

  @override
  Future<WeeklyPlanModel?> getWeeklyPlanByDate(DateTime weekStart) async {
    final weekStartStr = weekStart.toIso8601String().split('T')[0];
    final maps = await database.query(
      'weekly_plans',
      where: 'week_start = ?',
      whereArgs: [weekStartStr],
    );

    if (maps.isEmpty) return null;

    final plan = WeeklyPlanModel.fromMap(maps.first);
    final dayPlans = await getDayPlansForWeek(plan.id);
    return plan.copyWith(dayPlans: dayPlans);
  }

  @override
  Future<String> saveWeeklyPlan(WeeklyPlanModel plan) async {
    await database.insert(
      'weekly_plans',
      plan.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    // Save day plans
    for (final dayPlan in plan.dayPlans) {
      await saveDayPlan(plan.id, dayPlan);
    }

    return plan.id;
  }

  @override
  Future<void> updateWeeklyPlan(WeeklyPlanModel plan) async {
    await database.update(
      'weekly_plans',
      plan.toMap(),
      where: 'id = ?',
      whereArgs: [plan.id],
    );

    // Delete existing day plans and recreate them
    await database.delete(
      'day_plans',
      where: 'weekly_plan_id = ?',
      whereArgs: [plan.id],
    );

    for (final dayPlan in plan.dayPlans) {
      await saveDayPlan(plan.id, dayPlan);
    }
  }

  @override
  Future<void> deleteWeeklyPlan(String id) async {
    // SQLite will cascade delete day plans and activities
    await database.delete(
      'weekly_plans',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  @override
  Future<List<WeeklyPlanModel>> getTemplates() async {
    final maps = await database.query(
      'weekly_plans',
      where: 'is_template = ?',
      whereArgs: [1],
      orderBy: 'template_category, title',
    );

    final plans = <WeeklyPlanModel>[];
    for (final map in maps) {
      final plan = WeeklyPlanModel.fromMap(map);
      final dayPlans = await getDayPlansForWeek(plan.id);
      plans.add(plan.copyWith(dayPlans: dayPlans));
    }

    return plans;
  }

  @override
  Future<List<WeeklyPlanModel>> searchWeeklyPlans(String query) async {
    final maps = await database.rawQuery('''
      SELECT * FROM weekly_plans 
      WHERE title LIKE ? OR description LIKE ?
      ORDER BY created_at DESC
    ''', ['%$query%', '%$query%']);

    final plans = <WeeklyPlanModel>[];
    for (final map in maps) {
      final plan = WeeklyPlanModel.fromMap(map);
      final dayPlans = await getDayPlansForWeek(plan.id);
      plans.add(plan.copyWith(dayPlans: dayPlans));
    }

    return plans;
  }

  @override
  Future<List<DayPlan>> getDayPlansForWeek(String weeklyPlanId) async {
    final maps = await database.query(
      'day_plans',
      where: 'weekly_plan_id = ?',
      whereArgs: [weeklyPlanId],
      orderBy: 'date ASC',
    );

    final dayPlans = <DayPlan>[];
    for (final map in maps) {
      final dayPlanModel = DayPlanModel.fromMap(map);
      final activities = await _getActivitiesForDay(dayPlanModel.id);

      final dayPlan = DayPlan(
        date: dayPlanModel.date,
        activities: activities,
        notes: dayPlanModel.notes,
        totalDuration: dayPlanModel.totalDuration,
      );
      dayPlans.add(dayPlan);
    }

    return dayPlans;
  }

  @override
  Future<void> saveDayPlan(String weeklyPlanId, DayPlan dayPlan) async {
    final dayPlanModel = DayPlanModel.fromEntity(dayPlan);

    await database.insert(
      'day_plans',
      {
        'id': dayPlanModel.id,
        'weekly_plan_id': weeklyPlanId,
        ...dayPlanModel.toMap(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    // Save activities
    for (final activity in dayPlan.activities) {
      await saveActivity(LessonActivityModel.fromEntity(activity));
      await _linkActivityToDayPlan(dayPlanModel.id, activity.id);
    }
  }

  @override
  Future<String> saveActivity(LessonActivityModel activity) async {
    await database.insert(
      'activities',
      activity.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    return activity.id;
  }

  @override
  Future<void> deleteActivity(String activityId) async {
    await database.delete(
      'activities',
      where: 'id = ?',
      whereArgs: [activityId],
    );
  }

  @override
  Future<List<LessonActivity>> getActivitiesForDay(String dayPlanId) async {
    return await _getActivitiesForDay(dayPlanId);
  }

  @override
  Future<List<LessonActivity>> getActivitySuggestions(
      String subject, String grade) async {
    final maps = await database.query(
      'activities',
      where: 'subject = ? AND grade = ?',
      whereArgs: [subject, grade],
      orderBy: 'created_at DESC',
      limit: 20,
    );

    return maps.map((map) => LessonActivityModel.fromMap(map)).toList();
  }

  @override
  Future<void> saveActivitySuggestion(LessonActivity activity) async {
    final activityModel = LessonActivityModel.fromEntity(activity);
    await saveActivity(activityModel);
  }

  @override
  Future<void> deleteActivitySuggestion(String activityId) async {
    await deleteActivity(activityId);
  }

  // Additional activity methods required by repository
  @override
  Future<List<LessonActivityModel>> getActivities() async {
    final maps = await database.query(
      'activities',
      orderBy: 'created_at DESC',
    );

    return maps.map((map) => LessonActivityModel.fromMap(map)).toList();
  }

  @override
  Future<LessonActivityModel?> getActivity(String id) async {
    final maps = await database.query(
      'activities',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isEmpty) return null;
    return LessonActivityModel.fromMap(maps.first);
  }

  @override
  Future<void> updateActivity(LessonActivityModel activity) async {
    await database.update(
      'activities',
      activity.toMap(),
      where: 'id = ?',
      whereArgs: [activity.id],
    );
  }

  @override
  Future<List<LessonActivityModel>> searchActivities(String query) async {
    final maps = await database.rawQuery('''
      SELECT * FROM activities 
      WHERE title LIKE ? OR description LIKE ?
      ORDER BY created_at DESC
    ''', ['%$query%', '%$query%']);

    return maps.map((map) => LessonActivityModel.fromMap(map)).toList();
  }

  @override
  Future<List<LessonActivityModel>> getActivitiesBySubject(
      String subject) async {
    final maps = await database.query(
      'activities',
      where: 'subject = ?',
      whereArgs: [subject],
      orderBy: 'created_at DESC',
    );

    return maps.map((map) => LessonActivityModel.fromMap(map)).toList();
  }

  @override
  Future<List<LessonActivityModel>> getActivitiesByGrade(String grade) async {
    final maps = await database.query(
      'activities',
      where: 'grade = ?',
      whereArgs: [grade],
      orderBy: 'created_at DESC',
    );

    return maps.map((map) => LessonActivityModel.fromMap(map)).toList();
  }

  @override
  Future<List<LessonActivityModel>> getActivitiesByType(String type) async {
    final maps = await database.query(
      'activities',
      where: 'type = ?',
      whereArgs: [type],
      orderBy: 'created_at DESC',
    );

    return maps.map((map) => LessonActivityModel.fromMap(map)).toList();
  }

  // Private helper methods
  Future<void> _linkActivityToDayPlan(
      String dayPlanId, String activityId) async {
    await database.insert(
      'day_plan_activities',
      {
        'day_plan_id': dayPlanId,
        'activity_id': activityId,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<LessonActivity>> _getActivitiesForDay(String dayPlanId) async {
    final maps = await database.rawQuery('''
      SELECT a.* FROM activities a
      INNER JOIN day_plan_activities dpa ON a.id = dpa.activity_id
      WHERE dpa.day_plan_id = ?
      ORDER BY a.created_at ASC
    ''', [dayPlanId]);

    return maps.map((map) => LessonActivityModel.fromMap(map)).toList();
  }

  // Database initialization
  static Future<void> createTables(Database db) async {
    await db.execute('''
      CREATE TABLE weekly_plans (
        id TEXT PRIMARY KEY,
        week_start TEXT NOT NULL,
        title TEXT NOT NULL,
        description TEXT,
        target_grades TEXT NOT NULL,
        created_at TEXT NOT NULL,
        modified_at TEXT,
        is_template INTEGER NOT NULL DEFAULT 0,
        template_category TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE day_plans (
        id TEXT PRIMARY KEY,
        weekly_plan_id TEXT NOT NULL,
        date TEXT NOT NULL,
        notes TEXT,
        total_duration_minutes INTEGER NOT NULL,
        FOREIGN KEY (weekly_plan_id) REFERENCES weekly_plans (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE activities (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        description TEXT NOT NULL,
        type TEXT NOT NULL,
        subject TEXT NOT NULL,
        grade TEXT NOT NULL,
        duration_minutes INTEGER NOT NULL,
        materials TEXT,
        objectives TEXT,
        created_at TEXT NOT NULL,
        modified_at TEXT,
        generated_from TEXT,
        tags TEXT,
        color_code INTEGER
      )
    ''');

    await db.execute('''
      CREATE TABLE day_plan_activities (
        day_plan_id TEXT NOT NULL,
        activity_id TEXT NOT NULL,
        PRIMARY KEY (day_plan_id, activity_id),
        FOREIGN KEY (day_plan_id) REFERENCES day_plans (id) ON DELETE CASCADE,
        FOREIGN KEY (activity_id) REFERENCES activities (id) ON DELETE CASCADE
      )
    ''');

    // Create indexes for better performance
    await db.execute(
        'CREATE INDEX idx_weekly_plans_week_start ON weekly_plans (week_start)');
    await db.execute(
        'CREATE INDEX idx_weekly_plans_is_template ON weekly_plans (is_template)');
    await db
        .execute('CREATE INDEX idx_activities_subject ON activities (subject)');
    await db.execute('CREATE INDEX idx_activities_grade ON activities (grade)');
    await db.execute('CREATE INDEX idx_activities_type ON activities (type)');
    await db.execute(
        'CREATE INDEX idx_day_plans_weekly_plan_id ON day_plans (weekly_plan_id)');
  }
}
