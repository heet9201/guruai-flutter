import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import '../../domain/entities/weekly_plan.dart';
import '../models/weekly_plan_model.dart';

class WeeklyPlanLocalDataSource {
  final Database database;

  WeeklyPlanLocalDataSource(this.database);

  // Weekly Plans
  Future<List<WeeklyPlanModel>> getWeeklyPlans() async {
    final maps = await database.query(
      'weekly_plans',
      orderBy: 'created_at DESC',
    );

    final plans = <WeeklyPlanModel>[];
    for (final map in maps) {
      final plan = WeeklyPlanModel.fromMap(map);
      final dayPlans = await _getDayPlansForWeek(plan.id);
      plans.add(plan.copyWith(dayPlans: dayPlans));
    }

    return plans;
  }

  Future<WeeklyPlanModel?> getWeeklyPlan(String id) async {
    final maps = await database.query(
      'weekly_plans',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isEmpty) return null;

    final plan = WeeklyPlanModel.fromMap(maps.first);
    final dayPlans = await _getDayPlansForWeek(id);
    return plan.copyWith(dayPlans: dayPlans);
  }

  Future<WeeklyPlanModel?> getWeeklyPlanByDate(DateTime weekStart) async {
    final weekStartStr = weekStart.toIso8601String().split('T')[0];
    final maps = await database.query(
      'weekly_plans',
      where: 'week_start = ?',
      whereArgs: [weekStartStr],
    );

    if (maps.isEmpty) return null;

    final plan = WeeklyPlanModel.fromMap(maps.first);
    final dayPlans = await _getDayPlansForWeek(plan.id);
    return plan.copyWith(dayPlans: dayPlans);
  }

  Future<String> saveWeeklyPlan(WeeklyPlanModel plan) async {
    final planId = await database.insert(
      'weekly_plans',
      plan.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    // Save day plans
    for (final dayPlan in plan.dayPlans) {
      await _saveDayPlan(plan.id, dayPlan);
    }

    return plan.id;
  }

  Future<void> updateWeeklyPlan(WeeklyPlanModel plan) async {
    await database.update(
      'weekly_plans',
      plan.toMap(),
      where: 'id = ?',
      whereArgs: [plan.id],
    );

    // Update day plans
    await database.delete(
      'day_plans',
      where: 'weekly_plan_id = ?',
      whereArgs: [plan.id],
    );

    for (final dayPlan in plan.dayPlans) {
      await _saveDayPlan(plan.id, dayPlan);
    }
  }

  Future<void> deleteWeeklyPlan(String id) async {
    await database.delete(
      'weekly_plans',
      where: 'id = ?',
      whereArgs: [id],
    );

    await database.delete(
      'day_plans',
      where: 'weekly_plan_id = ?',
      whereArgs: [id],
    );
  }

  // Activities
  Future<List<LessonActivityModel>> getActivities() async {
    final maps = await database.query(
      'activities',
      orderBy: 'created_at DESC',
    );

    return maps.map((map) => LessonActivityModel.fromMap(map)).toList();
  }

  Future<LessonActivityModel?> getActivity(String id) async {
    final maps = await database.query(
      'activities',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isEmpty) return null;
    return LessonActivityModel.fromMap(maps.first);
  }

  Future<String> saveActivity(LessonActivityModel activity) async {
    await database.insert(
      'activities',
      activity.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    return activity.id;
  }

  Future<void> updateActivity(LessonActivityModel activity) async {
    await database.update(
      'activities',
      activity.toMap(),
      where: 'id = ?',
      whereArgs: [activity.id],
    );
  }

  Future<void> deleteActivity(String id) async {
    await database.delete(
      'activities',
      where: 'id = ?',
      whereArgs: [id],
    );

    // Remove from day plans
    await database.delete(
      'day_plan_activities',
      where: 'activity_id = ?',
      whereArgs: [id],
    );
  }

  // Search
  Future<List<WeeklyPlanModel>> searchWeeklyPlans(String query) async {
    final maps = await database.query(
      'weekly_plans',
      where: 'title LIKE ? OR description LIKE ?',
      whereArgs: ['%$query%', '%$query%'],
      orderBy: 'created_at DESC',
    );

    final plans = <WeeklyPlanModel>[];
    for (final map in maps) {
      final plan = WeeklyPlanModel.fromMap(map);
      final dayPlans = await _getDayPlansForWeek(plan.id);
      plans.add(plan.copyWith(dayPlans: dayPlans));
    }

    return plans;
  }

  Future<List<LessonActivityModel>> searchActivities(String query) async {
    final maps = await database.query(
      'activities',
      where: 'title LIKE ? OR description LIKE ? OR tags LIKE ?',
      whereArgs: ['%$query%', '%$query%', '%$query%'],
      orderBy: 'created_at DESC',
    );

    return maps.map((map) => LessonActivityModel.fromMap(map)).toList();
  }

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

  Future<List<LessonActivityModel>> getActivitiesByGrade(String grade) async {
    final maps = await database.query(
      'activities',
      where: 'grade = ?',
      whereArgs: [grade],
      orderBy: 'created_at DESC',
    );

    return maps.map((map) => LessonActivityModel.fromMap(map)).toList();
  }

  Future<List<LessonActivityModel>> getActivitiesByType(String type) async {
    final maps = await database.query(
      'activities',
      where: 'type = ?',
      whereArgs: [type],
      orderBy: 'created_at DESC',
    );

    return maps.map((map) => LessonActivityModel.fromMap(map)).toList();
  }

  // Templates
  Future<List<WeeklyPlanModel>> getTemplates() async {
    final maps = await database.query(
      'weekly_plans',
      where: 'is_template = ?',
      whereArgs: [1],
      orderBy: 'created_at DESC',
    );

    final plans = <WeeklyPlanModel>[];
    for (final map in maps) {
      final plan = WeeklyPlanModel.fromMap(map);
      final dayPlans = await _getDayPlansForWeek(plan.id);
      plans.add(plan.copyWith(dayPlans: dayPlans));
    }

    return plans;
  }

  // Helper methods
  Future<List<DayPlanModel>> _getDayPlansForWeek(String weeklyPlanId) async {
    final maps = await database.query(
      'day_plans',
      where: 'weekly_plan_id = ?',
      whereArgs: [weeklyPlanId],
      orderBy: 'date ASC',
    );

    final dayPlans = <DayPlanModel>[];
    for (final map in maps) {
      final dayPlan = DayPlanModel.fromMap(map);
      final activities = await _getActivitiesForDay(dayPlan.id);
      dayPlans.add(dayPlan.copyWith(activities: activities));
    }

    return dayPlans;
  }

  Future<void> _saveDayPlan(String weeklyPlanId, DayPlanModel dayPlan) async {
    final dayPlanId =
        '${weeklyPlanId}_${dayPlan.date.toIso8601String().split('T')[0]}';

    await database.insert(
      'day_plans',
      {
        'id': dayPlanId,
        'weekly_plan_id': weeklyPlanId,
        'date': dayPlan.date.toIso8601String().split('T')[0],
        'notes': dayPlan.notes,
        'total_duration_minutes': dayPlan.totalDuration.inMinutes,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    // Save activities for this day
    for (final activity in dayPlan.activities) {
      await saveActivity(activity);
      await database.insert(
        'day_plan_activities',
        {
          'day_plan_id': dayPlanId,
          'activity_id': activity.id,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
  }

  Future<List<LessonActivityModel>> _getActivitiesForDay(
      String dayPlanId) async {
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
