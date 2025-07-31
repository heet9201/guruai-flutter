import 'package:equatable/equatable.dart';

enum ActivityType {
  lesson,
  assignment,
  quiz,
  project,
  presentation,
  fieldTrip,
  discussion,
  practice,
  review,
}

enum SubjectCategory {
  math,
  science,
  english,
  history,
  geography,
  art,
  music,
  physicalEducation,
  socialStudies,
  computerScience,
}

enum Grade {
  kindergarten,
  grade1,
  grade2,
  grade3,
  grade4,
  grade5,
  grade6,
  grade7,
  grade8,
  grade9,
  grade10,
  grade11,
  grade12,
}

class LessonActivity extends Equatable {
  final String id;
  final String title;
  final String description;
  final ActivityType type;
  final SubjectCategory subject;
  final Grade grade;
  final Duration duration;
  final String? materials;
  final String? objectives;
  final DateTime createdAt;
  final DateTime? modifiedAt;
  final String? generatedFrom; // Reference to AI-generated content
  final List<String> tags;
  final int? colorCode; // For custom color coding

  const LessonActivity({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    required this.subject,
    required this.grade,
    required this.duration,
    this.materials,
    this.objectives,
    required this.createdAt,
    this.modifiedAt,
    this.generatedFrom,
    this.tags = const [],
    this.colorCode,
  });

  LessonActivity copyWith({
    String? id,
    String? title,
    String? description,
    ActivityType? type,
    SubjectCategory? subject,
    Grade? grade,
    Duration? duration,
    String? materials,
    String? objectives,
    DateTime? createdAt,
    DateTime? modifiedAt,
    String? generatedFrom,
    List<String>? tags,
    int? colorCode,
  }) {
    return LessonActivity(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      type: type ?? this.type,
      subject: subject ?? this.subject,
      grade: grade ?? this.grade,
      duration: duration ?? this.duration,
      materials: materials ?? this.materials,
      objectives: objectives ?? this.objectives,
      createdAt: createdAt ?? this.createdAt,
      modifiedAt: modifiedAt ?? this.modifiedAt,
      generatedFrom: generatedFrom ?? this.generatedFrom,
      tags: tags ?? this.tags,
      colorCode: colorCode ?? this.colorCode,
    );
  }

  @override
  List<Object?> get props => [
        id,
        title,
        description,
        type,
        subject,
        grade,
        duration,
        materials,
        objectives,
        createdAt,
        modifiedAt,
        generatedFrom,
        tags,
        colorCode,
      ];
}

class DayPlan extends Equatable {
  final DateTime date;
  final List<LessonActivity> activities;
  final String? notes;
  final Duration totalDuration;

  const DayPlan({
    required this.date,
    required this.activities,
    this.notes,
    required this.totalDuration,
  });

  DayPlan copyWith({
    DateTime? date,
    List<LessonActivity>? activities,
    String? notes,
    Duration? totalDuration,
  }) {
    return DayPlan(
      date: date ?? this.date,
      activities: activities ?? this.activities,
      notes: notes ?? this.notes,
      totalDuration: totalDuration ?? this.totalDuration,
    );
  }

  @override
  List<Object?> get props => [date, activities, notes, totalDuration];
}

class WeeklyPlan extends Equatable {
  final String id;
  final DateTime weekStart; // Monday of the week
  final String title;
  final String? description;
  final List<DayPlan> dayPlans; // Monday to Friday
  final List<Grade> targetGrades;
  final DateTime createdAt;
  final DateTime? modifiedAt;
  final bool isTemplate;
  final String? templateCategory;

  const WeeklyPlan({
    required this.id,
    required this.weekStart,
    required this.title,
    this.description,
    required this.dayPlans,
    required this.targetGrades,
    required this.createdAt,
    this.modifiedAt,
    this.isTemplate = false,
    this.templateCategory,
  });

  WeeklyPlan copyWith({
    String? id,
    DateTime? weekStart,
    String? title,
    String? description,
    List<DayPlan>? dayPlans,
    List<Grade>? targetGrades,
    DateTime? createdAt,
    DateTime? modifiedAt,
    bool? isTemplate,
    String? templateCategory,
  }) {
    return WeeklyPlan(
      id: id ?? this.id,
      weekStart: weekStart ?? this.weekStart,
      title: title ?? this.title,
      description: description ?? this.description,
      dayPlans: dayPlans ?? this.dayPlans,
      targetGrades: targetGrades ?? this.targetGrades,
      createdAt: createdAt ?? this.createdAt,
      modifiedAt: modifiedAt ?? this.modifiedAt,
      isTemplate: isTemplate ?? this.isTemplate,
      templateCategory: templateCategory ?? this.templateCategory,
    );
  }

  // Helper methods
  Duration get totalWeekDuration {
    return dayPlans.fold(
      Duration.zero,
      (total, day) => total + day.totalDuration,
    );
  }

  List<LessonActivity> get allActivities {
    return dayPlans.expand((day) => day.activities).toList();
  }

  Map<SubjectCategory, int> get subjectDistribution {
    final distribution = <SubjectCategory, int>{};
    for (final activity in allActivities) {
      distribution[activity.subject] =
          (distribution[activity.subject] ?? 0) + 1;
    }
    return distribution;
  }

  @override
  List<Object?> get props => [
        id,
        weekStart,
        title,
        description,
        dayPlans,
        targetGrades,
        createdAt,
        modifiedAt,
        isTemplate,
        templateCategory,
      ];
}

// AI Suggestion for activities
class ActivitySuggestion extends Equatable {
  final String id;
  final String title;
  final String description;
  final ActivityType type;
  final SubjectCategory subject;
  final Grade grade;
  final Duration estimatedDuration;
  final List<String> keywords;
  final double relevanceScore;
  final String source; // 'ai_generated', 'template', 'user_created'

  const ActivitySuggestion({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    required this.subject,
    required this.grade,
    required this.estimatedDuration,
    required this.keywords,
    required this.relevanceScore,
    required this.source,
  });

  LessonActivity toActivity({
    String? customId,
    String? materials,
    String? objectives,
    String? generatedFrom,
    List<String>? tags,
    int? colorCode,
  }) {
    return LessonActivity(
      id: customId ?? id,
      title: title,
      description: description,
      type: type,
      subject: subject,
      grade: grade,
      duration: estimatedDuration,
      materials: materials,
      objectives: objectives,
      createdAt: DateTime.now(),
      generatedFrom: generatedFrom,
      tags: tags ?? keywords,
      colorCode: colorCode,
    );
  }

  @override
  List<Object?> get props => [
        id,
        title,
        description,
        type,
        subject,
        grade,
        estimatedDuration,
        keywords,
        relevanceScore,
        source,
      ];
}
