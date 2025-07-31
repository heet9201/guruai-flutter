import '../entities/weekly_plan.dart';

abstract class WeeklyPlanRepository {
  // Weekly Plan CRUD operations
  Future<List<WeeklyPlan>> getWeeklyPlans();
  Future<WeeklyPlan?> getWeeklyPlan(String id);
  Future<WeeklyPlan?> getWeeklyPlanByDate(DateTime weekStart);
  Future<String> saveWeeklyPlan(WeeklyPlan plan);
  Future<void> updateWeeklyPlan(WeeklyPlan plan);
  Future<void> deleteWeeklyPlan(String id);

  // Activity operations
  Future<List<LessonActivity>> getActivities();
  Future<LessonActivity?> getActivity(String id);
  Future<String> saveActivity(LessonActivity activity);
  Future<void> updateActivity(LessonActivity activity);
  Future<void> deleteActivity(String id);

  // Search and filtering
  Future<List<WeeklyPlan>> searchWeeklyPlans(String query);
  Future<List<LessonActivity>> searchActivities(String query);
  Future<List<LessonActivity>> getActivitiesBySubject(SubjectCategory subject);
  Future<List<LessonActivity>> getActivitiesByGrade(Grade grade);
  Future<List<LessonActivity>> getActivitiesByType(ActivityType type);

  // Templates
  Future<List<WeeklyPlan>> getTemplates();
  Future<WeeklyPlan> createTemplateFromPlan(WeeklyPlan plan, String category);

  // AI Suggestions
  Future<List<ActivitySuggestion>> getActivitySuggestions({
    SubjectCategory? subject,
    Grade? grade,
    ActivityType? type,
    String? context,
  });

  // Auto-fill week plan
  Future<WeeklyPlan> generateWeekPlan({
    required DateTime weekStart,
    required List<Grade> targetGrades,
    List<SubjectCategory>? preferredSubjects,
    int? hoursPerDay,
    String? theme,
  });

  // Export and sharing
  Future<String> exportWeeklyPlanToPdf(WeeklyPlan plan);
  Future<String> shareWeeklyPlan(WeeklyPlan plan);

  // Calendar integration
  Future<void> syncWithDeviceCalendar(WeeklyPlan plan);
  Future<void> exportToCalendar(WeeklyPlan plan);

  // Duplication and copying
  Future<WeeklyPlan> duplicateWeeklyPlan(String planId, DateTime newWeekStart);
  Future<LessonActivity> duplicateActivity(String activityId);
  Future<void> copyActivityToGrades(
      String activityId, List<Grade> targetGrades);
}
