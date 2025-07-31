import 'package:equatable/equatable.dart';
import '../../domain/entities/weekly_plan.dart';

// Weekly Planner States
abstract class WeeklyPlannerState extends Equatable {
  const WeeklyPlannerState();

  @override
  List<Object?> get props => [];
}

class WeeklyPlannerInitial extends WeeklyPlannerState {}

class WeeklyPlannerLoading extends WeeklyPlannerState {}

class WeeklyPlannerLoaded extends WeeklyPlannerState {
  final DateTime currentWeekStart;
  final WeeklyPlan? currentPlan;
  final List<WeeklyPlan> recentPlans;
  final List<WeeklyPlan> templates;
  final List<ActivitySuggestion> suggestions;
  final String currentView; // 'week', 'day', 'month'
  final bool isSidebarOpen;
  final String? selectedActivityId;
  final LessonActivity? draggedActivity;
  final List<LessonActivity> filteredActivities;
  final SubjectCategory? filterSubject;
  final Grade? filterGrade;
  final ActivityType? filterType;
  final String searchQuery;
  final bool isGenerating;
  final Map<String, int> colorScheme; // Subject -> Color mapping

  const WeeklyPlannerLoaded({
    required this.currentWeekStart,
    this.currentPlan,
    this.recentPlans = const [],
    this.templates = const [],
    this.suggestions = const [],
    this.currentView = 'week',
    this.isSidebarOpen = true,
    this.selectedActivityId,
    this.draggedActivity,
    this.filteredActivities = const [],
    this.filterSubject,
    this.filterGrade,
    this.filterType,
    this.searchQuery = '',
    this.isGenerating = false,
    this.colorScheme = const {},
  });

  WeeklyPlannerLoaded copyWith({
    DateTime? currentWeekStart,
    WeeklyPlan? currentPlan,
    List<WeeklyPlan>? recentPlans,
    List<WeeklyPlan>? templates,
    List<ActivitySuggestion>? suggestions,
    String? currentView,
    bool? isSidebarOpen,
    String? selectedActivityId,
    LessonActivity? draggedActivity,
    List<LessonActivity>? filteredActivities,
    SubjectCategory? filterSubject,
    Grade? filterGrade,
    ActivityType? filterType,
    String? searchQuery,
    bool? isGenerating,
    Map<String, int>? colorScheme,
    bool clearSelectedActivity = false,
    bool clearDraggedActivity = false,
  }) {
    return WeeklyPlannerLoaded(
      currentWeekStart: currentWeekStart ?? this.currentWeekStart,
      currentPlan: currentPlan ?? this.currentPlan,
      recentPlans: recentPlans ?? this.recentPlans,
      templates: templates ?? this.templates,
      suggestions: suggestions ?? this.suggestions,
      currentView: currentView ?? this.currentView,
      isSidebarOpen: isSidebarOpen ?? this.isSidebarOpen,
      selectedActivityId: clearSelectedActivity
          ? null
          : (selectedActivityId ?? this.selectedActivityId),
      draggedActivity: clearDraggedActivity
          ? null
          : (draggedActivity ?? this.draggedActivity),
      filteredActivities: filteredActivities ?? this.filteredActivities,
      filterSubject: filterSubject ?? this.filterSubject,
      filterGrade: filterGrade ?? this.filterGrade,
      filterType: filterType ?? this.filterType,
      searchQuery: searchQuery ?? this.searchQuery,
      isGenerating: isGenerating ?? this.isGenerating,
      colorScheme: colorScheme ?? this.colorScheme,
    );
  }

  // Helper getters
  DateTime get weekEndDate => currentWeekStart.add(const Duration(days: 6));

  List<DateTime> get weekDates {
    return List.generate(
        7, (index) => currentWeekStart.add(Duration(days: index)));
  }

  List<DateTime> get workingDays {
    return weekDates.take(5).toList(); // Monday to Friday
  }

  DayPlan? getDayPlan(DateTime date) {
    if (currentPlan == null) return null;

    final dayDate = DateTime(date.year, date.month, date.day);
    return currentPlan!.dayPlans.firstWhere(
      (dayPlan) => isSameDay(dayPlan.date, dayDate),
      orElse: () => DayPlan(
        date: dayDate,
        activities: [],
        totalDuration: Duration.zero,
      ),
    );
  }

  bool isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  int getColorForSubject(SubjectCategory subject) {
    return colorScheme[subject.toString()] ?? 0xFF6B73FF;
  }

  @override
  List<Object?> get props => [
        currentWeekStart,
        currentPlan,
        recentPlans,
        templates,
        suggestions,
        currentView,
        isSidebarOpen,
        selectedActivityId,
        draggedActivity,
        filteredActivities,
        filterSubject,
        filterGrade,
        filterType,
        searchQuery,
        isGenerating,
        colorScheme,
      ];
}

class WeeklyPlannerError extends WeeklyPlannerState {
  final String message;

  const WeeklyPlannerError(this.message);

  @override
  List<Object> get props => [message];
}

class WeeklyPlanGenerating extends WeeklyPlannerState {
  final String message;
  final double progress; // 0.0 to 1.0

  const WeeklyPlanGenerating(this.message, {this.progress = 0.0});

  @override
  List<Object> get props => [message, progress];
}

class ActivityCreated extends WeeklyPlannerState {
  final LessonActivity activity;

  const ActivityCreated(this.activity);

  @override
  List<Object> get props => [activity];
}

class ActivityUpdated extends WeeklyPlannerState {
  final LessonActivity activity;

  const ActivityUpdated(this.activity);

  @override
  List<Object> get props => [activity];
}

class ActivityDeleted extends WeeklyPlannerState {
  final String activityId;

  const ActivityDeleted(this.activityId);

  @override
  List<Object> get props => [activityId];
}

class WeekPlanExported extends WeeklyPlannerState {
  final String filePath;
  final String exportType; // 'pdf', 'calendar', 'share'

  const WeekPlanExported(this.filePath, this.exportType);

  @override
  List<Object> get props => [filePath, exportType];
}

class TemplateCreated extends WeeklyPlannerState {
  final WeeklyPlan template;

  const TemplateCreated(this.template);

  @override
  List<Object> get props => [template];
}

class SuggestionsLoaded extends WeeklyPlannerState {
  final List<ActivitySuggestion> suggestions;
  final String context;

  const SuggestionsLoaded(this.suggestions, this.context);

  @override
  List<Object> get props => [suggestions, context];
}
