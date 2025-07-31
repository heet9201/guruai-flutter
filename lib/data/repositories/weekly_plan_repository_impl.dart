import 'dart:math';
import 'package:uuid/uuid.dart';
import '../../domain/entities/weekly_plan.dart';
import '../../domain/repositories/weekly_plan_repository.dart';
import '../datasources/weekly_plan_local_datasource.dart';
import '../models/weekly_plan_model.dart';

class WeeklyPlanRepositoryImpl implements WeeklyPlanRepository {
  final WeeklyPlanLocalDataSource localDataSource;

  WeeklyPlanRepositoryImpl({
    required this.localDataSource,
  });

  @override
  Future<List<WeeklyPlan>> getWeeklyPlans() async {
    final models = await localDataSource.getWeeklyPlans();
    return models.cast<WeeklyPlan>();
  }

  @override
  Future<WeeklyPlan?> getWeeklyPlan(String id) async {
    final model = await localDataSource.getWeeklyPlan(id);
    return model;
  }

  @override
  Future<WeeklyPlan?> getWeeklyPlanByDate(DateTime weekStart) async {
    final model = await localDataSource.getWeeklyPlanByDate(weekStart);
    return model;
  }

  @override
  Future<String> saveWeeklyPlan(WeeklyPlan plan) async {
    final model = WeeklyPlanModel.fromEntity(plan);
    return await localDataSource.saveWeeklyPlan(model);
  }

  @override
  Future<void> updateWeeklyPlan(WeeklyPlan plan) async {
    final model = WeeklyPlanModel.fromEntity(plan);
    await localDataSource.updateWeeklyPlan(model);
  }

  @override
  Future<void> deleteWeeklyPlan(String id) async {
    await localDataSource.deleteWeeklyPlan(id);
  }

  @override
  Future<List<LessonActivity>> getActivities() async {
    final models = await localDataSource.getActivities();
    return models.cast<LessonActivity>();
  }

  @override
  Future<LessonActivity?> getActivity(String id) async {
    final model = await localDataSource.getActivity(id);
    return model;
  }

  @override
  Future<String> saveActivity(LessonActivity activity) async {
    final model = LessonActivityModel.fromEntity(activity);
    return await localDataSource.saveActivity(model);
  }

  @override
  Future<void> updateActivity(LessonActivity activity) async {
    final model = LessonActivityModel.fromEntity(activity);
    await localDataSource.updateActivity(model);
  }

  @override
  Future<void> deleteActivity(String id) async {
    await localDataSource.deleteActivity(id);
  }

  @override
  Future<List<WeeklyPlan>> searchWeeklyPlans(String query) async {
    final models = await localDataSource.searchWeeklyPlans(query);
    return models.cast<WeeklyPlan>();
  }

  @override
  Future<List<LessonActivity>> searchActivities(String query) async {
    final models = await localDataSource.searchActivities(query);
    return models.cast<LessonActivity>();
  }

  @override
  Future<List<LessonActivity>> getActivitiesBySubject(
      SubjectCategory subject) async {
    final models =
        await localDataSource.getActivitiesBySubject(subject.toString());
    return models.cast<LessonActivity>();
  }

  @override
  Future<List<LessonActivity>> getActivitiesByGrade(Grade grade) async {
    final models = await localDataSource.getActivitiesByGrade(grade.toString());
    return models.cast<LessonActivity>();
  }

  @override
  Future<List<LessonActivity>> getActivitiesByType(ActivityType type) async {
    final models = await localDataSource.getActivitiesByType(type.toString());
    return models.cast<LessonActivity>();
  }

  @override
  Future<List<WeeklyPlan>> getTemplates() async {
    final models = await localDataSource.getTemplates();
    return models.cast<WeeklyPlan>();
  }

  @override
  Future<WeeklyPlan> createTemplateFromPlan(
      WeeklyPlan plan, String category) async {
    final template = plan.copyWith(
      id: const Uuid().v4(),
      isTemplate: true,
      templateCategory: category,
      createdAt: DateTime.now(),
      modifiedAt: null,
    );

    await saveWeeklyPlan(template);
    return template;
  }

  @override
  Future<List<ActivitySuggestion>> getActivitySuggestions({
    SubjectCategory? subject,
    Grade? grade,
    ActivityType? type,
    String? context,
  }) async {
    // Mock AI suggestions - In a real app, this would call an AI service
    return _generateMockSuggestions(
      subject: subject,
      grade: grade,
      type: type,
      context: context,
    );
  }

  @override
  Future<WeeklyPlan> generateWeekPlan({
    required DateTime weekStart,
    required List<Grade> targetGrades,
    List<SubjectCategory>? preferredSubjects,
    int? hoursPerDay,
    String? theme,
  }) async {
    // Mock AI generation - In a real app, this would call an AI service
    return _generateMockWeekPlan(
      weekStart: weekStart,
      targetGrades: targetGrades,
      preferredSubjects: preferredSubjects,
      hoursPerDay: hoursPerDay,
      theme: theme,
    );
  }

  @override
  Future<String> exportWeeklyPlanToPdf(WeeklyPlan plan) async {
    // Mock PDF export - In a real app, this would generate a PDF
    await Future.delayed(const Duration(seconds: 2));
    return '/mock/path/weekly_plan_${plan.id}.pdf';
  }

  @override
  Future<String> shareWeeklyPlan(WeeklyPlan plan) async {
    // Mock sharing - In a real app, this would use platform sharing
    final shareText = '''
Weekly Plan: ${plan.title}
Week of: ${_formatDate(plan.weekStart)}

${plan.dayPlans.map((day) => '''
${_getDayName(day.date)}: ${day.activities.length} activities
${day.activities.map((activity) => '  • ${activity.title}').join('\n')}
''').join('\n')}
    ''';

    return shareText;
  }

  @override
  Future<void> syncWithDeviceCalendar(WeeklyPlan plan) async {
    // Mock calendar sync - In a real app, this would use device_calendar plugin
    await Future.delayed(const Duration(seconds: 1));
    // Implementation would sync each activity as calendar events
  }

  @override
  Future<void> exportToCalendar(WeeklyPlan plan) async {
    // Mock calendar export
    await syncWithDeviceCalendar(plan);
  }

  @override
  Future<WeeklyPlan> duplicateWeeklyPlan(
      String planId, DateTime newWeekStart) async {
    final originalPlan = await getWeeklyPlan(planId);
    if (originalPlan == null) throw Exception('Plan not found');

    final duplicatedPlan = originalPlan.copyWith(
      id: const Uuid().v4(),
      weekStart: newWeekStart,
      title: '${originalPlan.title} (Copy)',
      createdAt: DateTime.now(),
      modifiedAt: null,
      isTemplate: false,
      templateCategory: null,
    );

    await saveWeeklyPlan(duplicatedPlan);
    return duplicatedPlan;
  }

  @override
  Future<LessonActivity> duplicateActivity(String activityId) async {
    final originalActivity = await getActivity(activityId);
    if (originalActivity == null) throw Exception('Activity not found');

    final duplicatedActivity = originalActivity.copyWith(
      id: const Uuid().v4(),
      title: '${originalActivity.title} (Copy)',
      createdAt: DateTime.now(),
      modifiedAt: null,
    );

    await saveActivity(duplicatedActivity);
    return duplicatedActivity;
  }

  @override
  Future<void> copyActivityToGrades(
      String activityId, List<Grade> targetGrades) async {
    final originalActivity = await getActivity(activityId);
    if (originalActivity == null) throw Exception('Activity not found');

    for (final grade in targetGrades) {
      if (grade != originalActivity.grade) {
        final copiedActivity = originalActivity.copyWith(
          id: const Uuid().v4(),
          grade: grade,
          title: '${originalActivity.title} (${_getGradeName(grade)})',
          createdAt: DateTime.now(),
          modifiedAt: null,
        );

        await saveActivity(copiedActivity);
      }
    }
  }

  // Helper methods for mock data generation
  List<ActivitySuggestion> _generateMockSuggestions({
    SubjectCategory? subject,
    Grade? grade,
    ActivityType? type,
    String? context,
  }) {
    final suggestions = <ActivitySuggestion>[];
    final random = Random();

    // Mock suggestions based on filters
    final subjects =
        subject != null ? [subject] : SubjectCategory.values.take(5);
    final grades = grade != null ? [grade] : Grade.values.take(5);
    final types = type != null ? [type] : ActivityType.values.take(5);

    for (int i = 0; i < 10; i++) {
      final selectedSubject =
          subjects.elementAt(random.nextInt(subjects.length));
      final selectedGrade = grades.elementAt(random.nextInt(grades.length));
      final selectedType = types.elementAt(random.nextInt(types.length));

      suggestions.add(ActivitySuggestion(
        id: const Uuid().v4(),
        title: _generateActivityTitle(selectedSubject, selectedType),
        description:
            _generateActivityDescription(selectedSubject, selectedType),
        type: selectedType,
        subject: selectedSubject,
        grade: selectedGrade,
        estimatedDuration: Duration(minutes: 30 + random.nextInt(60)),
        keywords: _generateKeywords(selectedSubject, selectedType),
        relevanceScore: 0.7 + random.nextDouble() * 0.3,
        source: 'ai_generated',
      ));
    }

    return suggestions;
  }

  WeeklyPlan _generateMockWeekPlan({
    required DateTime weekStart,
    required List<Grade> targetGrades,
    List<SubjectCategory>? preferredSubjects,
    int? hoursPerDay,
    String? theme,
  }) {
    final dayPlans = <DayPlan>[];
    final subjects =
        preferredSubjects ?? SubjectCategory.values.take(5).toList();
    final random = Random();

    // Generate plans for Monday to Friday
    for (int i = 0; i < 5; i++) {
      final date = weekStart.add(Duration(days: i));
      final activities = <LessonActivity>[];

      // Generate 3-5 activities per day
      final activityCount = 3 + random.nextInt(3);
      for (int j = 0; j < activityCount; j++) {
        final subject = subjects[j % subjects.length];
        final grade = targetGrades[random.nextInt(targetGrades.length)];
        final type =
            ActivityType.values[random.nextInt(ActivityType.values.length)];

        activities.add(LessonActivity(
          id: const Uuid().v4(),
          title: _generateActivityTitle(subject, type),
          description: _generateActivityDescription(subject, type),
          type: type,
          subject: subject,
          grade: grade,
          duration: Duration(minutes: 45 + random.nextInt(30)),
          createdAt: DateTime.now(),
          generatedFrom: 'ai_generated',
          tags: _generateKeywords(subject, type),
        ));
      }

      final totalDuration = activities.fold<Duration>(
        Duration.zero,
        (total, activity) => total + activity.duration,
      );

      dayPlans.add(DayPlan(
        date: date,
        activities: activities,
        totalDuration: totalDuration,
      ));
    }

    return WeeklyPlan(
      id: const Uuid().v4(),
      weekStart: weekStart,
      title: theme != null ? '$theme - Week Plan' : 'Generated Week Plan',
      description: 'Auto-generated weekly lesson plan',
      dayPlans: dayPlans,
      targetGrades: targetGrades,
      createdAt: DateTime.now(),
    );
  }

  String _generateActivityTitle(SubjectCategory subject, ActivityType type) {
    final subjectTitles = {
      SubjectCategory.math: [
        'Algebra Basics',
        'Geometry Shapes',
        'Fractions',
        'Multiplication Tables'
      ],
      SubjectCategory.science: [
        'Solar System',
        'Plant Life Cycle',
        'Simple Machines',
        'Weather Patterns'
      ],
      SubjectCategory.english: [
        'Reading Comprehension',
        'Creative Writing',
        'Grammar Rules',
        'Vocabulary Building'
      ],
      SubjectCategory.history: [
        'Ancient Civilizations',
        'World Wars',
        'Local History',
        'Historical Figures'
      ],
      SubjectCategory.art: [
        'Color Theory',
        'Drawing Techniques',
        'Art History',
        'Creative Expression'
      ],
    };

    final titles = subjectTitles[subject] ?? ['General Activity'];
    final random = Random();
    final baseTitle = titles[random.nextInt(titles.length)];

    final typePrefix = {
      ActivityType.lesson: 'Lesson:',
      ActivityType.quiz: 'Quiz:',
      ActivityType.project: 'Project:',
      ActivityType.discussion: 'Discussion:',
      ActivityType.practice: 'Practice:',
    };

    return '${typePrefix[type] ?? ''} $baseTitle';
  }

  String _generateActivityDescription(
      SubjectCategory subject, ActivityType type) {
    return 'A comprehensive ${type.toString().split('.').last} activity focused on ${subject.toString().split('.').last} concepts. This activity includes interactive elements and assessments to ensure student engagement and learning outcomes.';
  }

  List<String> _generateKeywords(SubjectCategory subject, ActivityType type) {
    final baseKeywords = [
      subject.toString().split('.').last,
      type.toString().split('.').last,
    ];

    final subjectKeywords = {
      SubjectCategory.math: ['numbers', 'calculation', 'problem-solving'],
      SubjectCategory.science: ['experiment', 'observation', 'hypothesis'],
      SubjectCategory.english: ['reading', 'writing', 'communication'],
      SubjectCategory.history: ['timeline', 'events', 'analysis'],
      SubjectCategory.art: ['creativity', 'expression', 'visual'],
    };

    return [...baseKeywords, ...subjectKeywords[subject] ?? []];
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  String _getDayName(DateTime date) {
    const dayNames = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday'
    ];
    return dayNames[date.weekday - 1];
  }

  String _getGradeName(Grade grade) {
    return grade.toString().split('.').last.replaceAll('grade', 'Grade ');
  }
}
