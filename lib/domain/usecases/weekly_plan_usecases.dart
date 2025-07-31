import '../entities/weekly_plan.dart';
import '../repositories/weekly_plan_repository.dart';

// Weekly Plan Use Cases
class GetWeeklyPlansUseCase {
  final WeeklyPlanRepository repository;

  GetWeeklyPlansUseCase(this.repository);

  Future<List<WeeklyPlan>> execute() async {
    return await repository.getWeeklyPlans();
  }
}

class GetWeeklyPlanByDateUseCase {
  final WeeklyPlanRepository repository;

  GetWeeklyPlanByDateUseCase(this.repository);

  Future<WeeklyPlan?> execute(DateTime weekStart) async {
    return await repository.getWeeklyPlanByDate(weekStart);
  }
}

class SaveWeeklyPlanUseCase {
  final WeeklyPlanRepository repository;

  SaveWeeklyPlanUseCase(this.repository);

  Future<String> execute(WeeklyPlan plan) async {
    return await repository.saveWeeklyPlan(plan);
  }
}

class UpdateWeeklyPlanUseCase {
  final WeeklyPlanRepository repository;

  UpdateWeeklyPlanUseCase(this.repository);

  Future<void> execute(WeeklyPlan plan) async {
    await repository.updateWeeklyPlan(plan);
  }
}

class DeleteWeeklyPlanUseCase {
  final WeeklyPlanRepository repository;

  DeleteWeeklyPlanUseCase(this.repository);

  Future<void> execute(String id) async {
    await repository.deleteWeeklyPlan(id);
  }
}

// Activity Use Cases
class GetActivitiesUseCase {
  final WeeklyPlanRepository repository;

  GetActivitiesUseCase(this.repository);

  Future<List<LessonActivity>> execute() async {
    return await repository.getActivities();
  }
}

class SaveActivityUseCase {
  final WeeklyPlanRepository repository;

  SaveActivityUseCase(this.repository);

  Future<String> execute(LessonActivity activity) async {
    return await repository.saveActivity(activity);
  }
}

class UpdateActivityUseCase {
  final WeeklyPlanRepository repository;

  UpdateActivityUseCase(this.repository);

  Future<void> execute(LessonActivity activity) async {
    await repository.updateActivity(activity);
  }
}

class DeleteActivityUseCase {
  final WeeklyPlanRepository repository;

  DeleteActivityUseCase(this.repository);

  Future<void> execute(String id) async {
    await repository.deleteActivity(id);
  }
}

// Search Use Cases
class SearchWeeklyPlansUseCase {
  final WeeklyPlanRepository repository;

  SearchWeeklyPlansUseCase(this.repository);

  Future<List<WeeklyPlan>> execute(String query) async {
    return await repository.searchWeeklyPlans(query);
  }
}

class SearchActivitiesUseCase {
  final WeeklyPlanRepository repository;

  SearchActivitiesUseCase(this.repository);

  Future<List<LessonActivity>> execute(String query) async {
    return await repository.searchActivities(query);
  }
}

class GetActivitiesByFilterUseCase {
  final WeeklyPlanRepository repository;

  GetActivitiesByFilterUseCase(this.repository);

  Future<List<LessonActivity>> executeBySubject(SubjectCategory subject) async {
    return await repository.getActivitiesBySubject(subject);
  }

  Future<List<LessonActivity>> executeByGrade(Grade grade) async {
    return await repository.getActivitiesByGrade(grade);
  }

  Future<List<LessonActivity>> executeByType(ActivityType type) async {
    return await repository.getActivitiesByType(type);
  }
}

// AI and Suggestions Use Cases
class GetActivitySuggestionsUseCase {
  final WeeklyPlanRepository repository;

  GetActivitySuggestionsUseCase(this.repository);

  Future<List<ActivitySuggestion>> execute({
    SubjectCategory? subject,
    Grade? grade,
    ActivityType? type,
    String? context,
  }) async {
    return await repository.getActivitySuggestions(
      subject: subject,
      grade: grade,
      type: type,
      context: context,
    );
  }
}

class GenerateWeekPlanUseCase {
  final WeeklyPlanRepository repository;

  GenerateWeekPlanUseCase(this.repository);

  Future<WeeklyPlan> execute({
    required DateTime weekStart,
    required List<Grade> targetGrades,
    List<SubjectCategory>? preferredSubjects,
    int? hoursPerDay,
    String? theme,
  }) async {
    return await repository.generateWeekPlan(
      weekStart: weekStart,
      targetGrades: targetGrades,
      preferredSubjects: preferredSubjects,
      hoursPerDay: hoursPerDay,
      theme: theme,
    );
  }
}

// Template Use Cases
class GetTemplatesUseCase {
  final WeeklyPlanRepository repository;

  GetTemplatesUseCase(this.repository);

  Future<List<WeeklyPlan>> execute() async {
    return await repository.getTemplates();
  }
}

class CreateTemplateFromPlanUseCase {
  final WeeklyPlanRepository repository;

  CreateTemplateFromPlanUseCase(this.repository);

  Future<WeeklyPlan> execute(WeeklyPlan plan, String category) async {
    return await repository.createTemplateFromPlan(plan, category);
  }
}

// Export and Sharing Use Cases
class ExportWeeklyPlanToPdfUseCase {
  final WeeklyPlanRepository repository;

  ExportWeeklyPlanToPdfUseCase(this.repository);

  Future<String> execute(WeeklyPlan plan) async {
    return await repository.exportWeeklyPlanToPdf(plan);
  }
}

class ShareWeeklyPlanUseCase {
  final WeeklyPlanRepository repository;

  ShareWeeklyPlanUseCase(this.repository);

  Future<String> execute(WeeklyPlan plan) async {
    return await repository.shareWeeklyPlan(plan);
  }
}

// Calendar Integration Use Cases
class SyncWithDeviceCalendarUseCase {
  final WeeklyPlanRepository repository;

  SyncWithDeviceCalendarUseCase(this.repository);

  Future<void> execute(WeeklyPlan plan) async {
    await repository.syncWithDeviceCalendar(plan);
  }
}

class ExportToCalendarUseCase {
  final WeeklyPlanRepository repository;

  ExportToCalendarUseCase(this.repository);

  Future<void> execute(WeeklyPlan plan) async {
    await repository.exportToCalendar(plan);
  }
}

// Duplication Use Cases
class DuplicateWeeklyPlanUseCase {
  final WeeklyPlanRepository repository;

  DuplicateWeeklyPlanUseCase(this.repository);

  Future<WeeklyPlan> execute(String planId, DateTime newWeekStart) async {
    return await repository.duplicateWeeklyPlan(planId, newWeekStart);
  }
}

class DuplicateActivityUseCase {
  final WeeklyPlanRepository repository;

  DuplicateActivityUseCase(this.repository);

  Future<LessonActivity> execute(String activityId) async {
    return await repository.duplicateActivity(activityId);
  }
}

class CopyActivityToGradesUseCase {
  final WeeklyPlanRepository repository;

  CopyActivityToGradesUseCase(this.repository);

  Future<void> execute(String activityId, List<Grade> targetGrades) async {
    await repository.copyActivityToGrades(activityId, targetGrades);
  }
}
