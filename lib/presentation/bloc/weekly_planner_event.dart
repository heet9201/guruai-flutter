import '../../domain/entities/weekly_plan.dart';

// Weekly Planner Events
abstract class WeeklyPlannerEvent {}

// Navigation Events
class LoadWeeklyPlanner extends WeeklyPlannerEvent {}

class ChangeWeek extends WeeklyPlannerEvent {
  final DateTime weekStart;
  ChangeWeek(this.weekStart);
}

class GoToPreviousWeek extends WeeklyPlannerEvent {}

class GoToNextWeek extends WeeklyPlannerEvent {}

class GoToCurrentWeek extends WeeklyPlannerEvent {}

// Plan Management Events
class LoadWeekPlan extends WeeklyPlannerEvent {
  final DateTime weekStart;
  LoadWeekPlan(this.weekStart);
}

class CreateNewWeekPlan extends WeeklyPlannerEvent {
  final DateTime weekStart;
  final String title;
  final List<Grade> targetGrades;
  CreateNewWeekPlan(this.weekStart, this.title, this.targetGrades);
}

class UpdateWeekPlan extends WeeklyPlannerEvent {
  final WeeklyPlan plan;
  UpdateWeekPlan(this.plan);
}

class DeleteWeekPlan extends WeeklyPlannerEvent {
  final String planId;
  DeleteWeekPlan(this.planId);
}

class DuplicateWeekPlan extends WeeklyPlannerEvent {
  final String planId;
  final DateTime newWeekStart;
  DuplicateWeekPlan(this.planId, this.newWeekStart);
}

// Activity Management Events
class AddActivity extends WeeklyPlannerEvent {
  final DateTime date;
  final LessonActivity activity;
  AddActivity(this.date, this.activity);
}

class UpdateActivity extends WeeklyPlannerEvent {
  final LessonActivity activity;
  UpdateActivity(this.activity);
}

class DeleteActivity extends WeeklyPlannerEvent {
  final String activityId;
  DeleteActivity(this.activityId);
}

class MoveActivity extends WeeklyPlannerEvent {
  final String activityId;
  final DateTime fromDate;
  final DateTime toDate;
  MoveActivity(this.activityId, this.fromDate, this.toDate);
}

class DuplicateActivity extends WeeklyPlannerEvent {
  final String activityId;
  final DateTime? targetDate;
  final List<Grade>? targetGrades;
  DuplicateActivity(this.activityId, {this.targetDate, this.targetGrades});
}

// AI and Auto-fill Events
class GenerateWeekPlan extends WeeklyPlannerEvent {
  final DateTime weekStart;
  final List<Grade> targetGrades;
  final List<SubjectCategory>? preferredSubjects;
  final int? hoursPerDay;
  final String? theme;
  GenerateWeekPlan(
    this.weekStart,
    this.targetGrades, {
    this.preferredSubjects,
    this.hoursPerDay,
    this.theme,
  });
}

class LoadActivitySuggestions extends WeeklyPlannerEvent {
  final SubjectCategory? subject;
  final Grade? grade;
  final ActivityType? type;
  final String? context;
  LoadActivitySuggestions({
    this.subject,
    this.grade,
    this.type,
    this.context,
  });
}

class ApplySuggestion extends WeeklyPlannerEvent {
  final ActivitySuggestion suggestion;
  final DateTime date;
  ApplySuggestion(this.suggestion, this.date);
}

// Template Events
class LoadTemplates extends WeeklyPlannerEvent {}

class CreateTemplateFromPlan extends WeeklyPlannerEvent {
  final WeeklyPlan plan;
  final String category;
  CreateTemplateFromPlan(this.plan, this.category);
}

class ApplyTemplate extends WeeklyPlannerEvent {
  final WeeklyPlan template;
  final DateTime weekStart;
  ApplyTemplate(this.template, this.weekStart);
}

// Search and Filter Events
class SearchPlans extends WeeklyPlannerEvent {
  final String query;
  SearchPlans(this.query);
}

class SearchActivities extends WeeklyPlannerEvent {
  final String query;
  SearchActivities(this.query);
}

class FilterActivities extends WeeklyPlannerEvent {
  final SubjectCategory? subject;
  final Grade? grade;
  final ActivityType? type;
  FilterActivities({this.subject, this.grade, this.type});
}

// Export and Share Events
class ExportWeekToPdf extends WeeklyPlannerEvent {
  final WeeklyPlan plan;
  ExportWeekToPdf(this.plan);
}

class ShareWeekPlan extends WeeklyPlannerEvent {
  final WeeklyPlan plan;
  ShareWeekPlan(this.plan);
}

class SyncWithCalendar extends WeeklyPlannerEvent {
  final WeeklyPlan plan;
  SyncWithCalendar(this.plan);
}

class ExportToCalendar extends WeeklyPlannerEvent {
  final WeeklyPlan plan;
  ExportToCalendar(this.plan);
}

// UI Events
class ToggleSidebar extends WeeklyPlannerEvent {}

class ChangeView extends WeeklyPlannerEvent {
  final String viewType; // 'week', 'day', 'month'
  ChangeView(this.viewType);
}

class SelectActivity extends WeeklyPlannerEvent {
  final String? activityId;
  SelectActivity(this.activityId);
}

class StartDragActivity extends WeeklyPlannerEvent {
  final LessonActivity activity;
  StartDragActivity(this.activity);
}

class EndDragActivity extends WeeklyPlannerEvent {}

class DropActivity extends WeeklyPlannerEvent {
  final DateTime targetDate;
  DropActivity(this.targetDate);
}
