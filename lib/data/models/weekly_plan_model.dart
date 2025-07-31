import '../../domain/entities/weekly_plan.dart';

class LessonActivityModel extends LessonActivity {
  const LessonActivityModel({
    required super.id,
    required super.title,
    required super.description,
    required super.type,
    required super.subject,
    required super.grade,
    required super.duration,
    super.materials,
    super.objectives,
    required super.createdAt,
    super.modifiedAt,
    super.generatedFrom,
    super.tags,
    super.colorCode,
  });

  factory LessonActivityModel.fromEntity(LessonActivity entity) {
    return LessonActivityModel(
      id: entity.id,
      title: entity.title,
      description: entity.description,
      type: entity.type,
      subject: entity.subject,
      grade: entity.grade,
      duration: entity.duration,
      materials: entity.materials,
      objectives: entity.objectives,
      createdAt: entity.createdAt,
      modifiedAt: entity.modifiedAt,
      generatedFrom: entity.generatedFrom,
      tags: entity.tags,
      colorCode: entity.colorCode,
    );
  }

  factory LessonActivityModel.fromMap(Map<String, dynamic> map) {
    return LessonActivityModel(
      id: map['id'] as String,
      title: map['title'] as String,
      description: map['description'] as String,
      type: ActivityType.values.firstWhere(
        (e) => e.toString() == map['type'],
        orElse: () => ActivityType.lesson,
      ),
      subject: SubjectCategory.values.firstWhere(
        (e) => e.toString() == map['subject'],
        orElse: () => SubjectCategory.english,
      ),
      grade: Grade.values.firstWhere(
        (e) => e.toString() == map['grade'],
        orElse: () => Grade.grade1,
      ),
      duration: Duration(minutes: map['duration_minutes'] as int),
      materials: map['materials'] as String?,
      objectives: map['objectives'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
      modifiedAt: map['modified_at'] != null
          ? DateTime.parse(map['modified_at'] as String)
          : null,
      generatedFrom: map['generated_from'] as String?,
      tags: map['tags'] != null
          ? (map['tags'] as String)
              .split(',')
              .where((tag) => tag.isNotEmpty)
              .toList()
          : [],
      colorCode: map['color_code'] as int?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'type': type.toString(),
      'subject': subject.toString(),
      'grade': grade.toString(),
      'duration_minutes': duration.inMinutes,
      'materials': materials,
      'objectives': objectives,
      'created_at': createdAt.toIso8601String(),
      'modified_at': modifiedAt?.toIso8601String(),
      'generated_from': generatedFrom,
      'tags': tags.join(','),
      'color_code': colorCode,
    };
  }

  @override
  LessonActivityModel copyWith({
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
    return LessonActivityModel(
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
}

class DayPlanModel extends DayPlan {
  const DayPlanModel({
    required super.date,
    required super.activities,
    super.notes,
    required super.totalDuration,
  });

  factory DayPlanModel.fromEntity(DayPlan entity) {
    return DayPlanModel(
      date: entity.date,
      activities: entity.activities,
      notes: entity.notes,
      totalDuration: entity.totalDuration,
    );
  }

  factory DayPlanModel.fromMap(Map<String, dynamic> map) {
    return DayPlanModel(
      date: DateTime.parse(map['date'] as String),
      activities: [], // Activities will be loaded separately
      notes: map['notes'] as String?,
      totalDuration: Duration(minutes: map['total_duration_minutes'] as int),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'date': date.toIso8601String().split('T')[0],
      'notes': notes,
      'total_duration_minutes': totalDuration.inMinutes,
    };
  }

  @override
  DayPlanModel copyWith({
    DateTime? date,
    List<LessonActivity>? activities,
    String? notes,
    Duration? totalDuration,
  }) {
    return DayPlanModel(
      date: date ?? this.date,
      activities: activities ?? this.activities,
      notes: notes ?? this.notes,
      totalDuration: totalDuration ?? this.totalDuration,
    );
  }

  // Helper property for database operations
  String get id => date.toIso8601String().split('T')[0];
}

class WeeklyPlanModel extends WeeklyPlan {
  const WeeklyPlanModel({
    required super.id,
    required super.weekStart,
    required super.title,
    super.description,
    required super.dayPlans,
    required super.targetGrades,
    required super.createdAt,
    super.modifiedAt,
    super.isTemplate,
    super.templateCategory,
  });

  factory WeeklyPlanModel.fromEntity(WeeklyPlan entity) {
    return WeeklyPlanModel(
      id: entity.id,
      weekStart: entity.weekStart,
      title: entity.title,
      description: entity.description,
      dayPlans: entity.dayPlans,
      targetGrades: entity.targetGrades,
      createdAt: entity.createdAt,
      modifiedAt: entity.modifiedAt,
      isTemplate: entity.isTemplate,
      templateCategory: entity.templateCategory,
    );
  }

  factory WeeklyPlanModel.fromMap(Map<String, dynamic> map) {
    return WeeklyPlanModel(
      id: map['id'] as String,
      weekStart: DateTime.parse(map['week_start'] as String),
      title: map['title'] as String,
      description: map['description'] as String?,
      dayPlans: [], // Day plans will be loaded separately
      targetGrades: (map['target_grades'] as String)
          .split(',')
          .map((grade) => Grade.values.firstWhere(
                (e) => e.toString() == grade,
                orElse: () => Grade.grade1,
              ))
          .toList(),
      createdAt: DateTime.parse(map['created_at'] as String),
      modifiedAt: map['modified_at'] != null
          ? DateTime.parse(map['modified_at'] as String)
          : null,
      isTemplate: (map['is_template'] as int) == 1,
      templateCategory: map['template_category'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'week_start': weekStart.toIso8601String().split('T')[0],
      'title': title,
      'description': description,
      'target_grades': targetGrades.map((grade) => grade.toString()).join(','),
      'created_at': createdAt.toIso8601String(),
      'modified_at': modifiedAt?.toIso8601String(),
      'is_template': isTemplate ? 1 : 0,
      'template_category': templateCategory,
    };
  }

  @override
  WeeklyPlanModel copyWith({
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
    return WeeklyPlanModel(
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
}

class ActivitySuggestionModel extends ActivitySuggestion {
  const ActivitySuggestionModel({
    required super.id,
    required super.title,
    required super.description,
    required super.type,
    required super.subject,
    required super.grade,
    required super.estimatedDuration,
    required super.keywords,
    required super.relevanceScore,
    required super.source,
  });

  factory ActivitySuggestionModel.fromEntity(ActivitySuggestion entity) {
    return ActivitySuggestionModel(
      id: entity.id,
      title: entity.title,
      description: entity.description,
      type: entity.type,
      subject: entity.subject,
      grade: entity.grade,
      estimatedDuration: entity.estimatedDuration,
      keywords: entity.keywords,
      relevanceScore: entity.relevanceScore,
      source: entity.source,
    );
  }

  factory ActivitySuggestionModel.fromMap(Map<String, dynamic> map) {
    return ActivitySuggestionModel(
      id: map['id'] as String,
      title: map['title'] as String,
      description: map['description'] as String,
      type: ActivityType.values.firstWhere(
        (e) => e.toString() == map['type'],
        orElse: () => ActivityType.lesson,
      ),
      subject: SubjectCategory.values.firstWhere(
        (e) => e.toString() == map['subject'],
        orElse: () => SubjectCategory.english,
      ),
      grade: Grade.values.firstWhere(
        (e) => e.toString() == map['grade'],
        orElse: () => Grade.grade1,
      ),
      estimatedDuration:
          Duration(minutes: map['estimated_duration_minutes'] as int),
      keywords: (map['keywords'] as String).split(','),
      relevanceScore: (map['relevance_score'] as num).toDouble(),
      source: map['source'] as String,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'type': type.toString(),
      'subject': subject.toString(),
      'grade': grade.toString(),
      'estimated_duration_minutes': estimatedDuration.inMinutes,
      'keywords': keywords.join(','),
      'relevance_score': relevanceScore,
      'source': source,
    };
  }
}
