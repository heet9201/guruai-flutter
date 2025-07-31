import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';
import '../../domain/entities/weekly_plan.dart';
import '../../domain/usecases/weekly_plan_usecases.dart';
import 'weekly_planner_event.dart';
import 'weekly_planner_state.dart';

class WeeklyPlannerBloc extends Bloc<WeeklyPlannerEvent, WeeklyPlannerState> {
  // Use Cases
  final GetWeeklyPlansUseCase getWeeklyPlansUseCase;
  final GetWeeklyPlanByDateUseCase getWeeklyPlanByDateUseCase;
  final SaveWeeklyPlanUseCase saveWeeklyPlanUseCase;
  final UpdateWeeklyPlanUseCase updateWeeklyPlanUseCase;
  final DeleteWeeklyPlanUseCase deleteWeeklyPlanUseCase;
  final GetActivitiesUseCase getActivitiesUseCase;
  final SaveActivityUseCase saveActivityUseCase;
  final UpdateActivityUseCase updateActivityUseCase;
  final DeleteActivityUseCase deleteActivityUseCase;
  final GetActivitySuggestionsUseCase getActivitySuggestionsUseCase;
  final GenerateWeekPlanUseCase generateWeekPlanUseCase;
  final GetTemplatesUseCase getTemplatesUseCase;
  final CreateTemplateFromPlanUseCase createTemplateFromPlanUseCase;
  final ExportWeeklyPlanToPdfUseCase exportWeeklyPlanToPdfUseCase;
  final ShareWeeklyPlanUseCase shareWeeklyPlanUseCase;
  final SyncWithDeviceCalendarUseCase syncWithDeviceCalendarUseCase;
  final DuplicateWeeklyPlanUseCase duplicateWeeklyPlanUseCase;
  final DuplicateActivityUseCase duplicateActivityUseCase;
  final CopyActivityToGradesUseCase copyActivityToGradesUseCase;
  final SearchWeeklyPlansUseCase searchWeeklyPlansUseCase;
  final SearchActivitiesUseCase searchActivitiesUseCase;
  final GetActivitiesByFilterUseCase getActivitiesByFilterUseCase;

  WeeklyPlannerBloc({
    required this.getWeeklyPlansUseCase,
    required this.getWeeklyPlanByDateUseCase,
    required this.saveWeeklyPlanUseCase,
    required this.updateWeeklyPlanUseCase,
    required this.deleteWeeklyPlanUseCase,
    required this.getActivitiesUseCase,
    required this.saveActivityUseCase,
    required this.updateActivityUseCase,
    required this.deleteActivityUseCase,
    required this.getActivitySuggestionsUseCase,
    required this.generateWeekPlanUseCase,
    required this.getTemplatesUseCase,
    required this.createTemplateFromPlanUseCase,
    required this.exportWeeklyPlanToPdfUseCase,
    required this.shareWeeklyPlanUseCase,
    required this.syncWithDeviceCalendarUseCase,
    required this.duplicateWeeklyPlanUseCase,
    required this.duplicateActivityUseCase,
    required this.copyActivityToGradesUseCase,
    required this.searchWeeklyPlansUseCase,
    required this.searchActivitiesUseCase,
    required this.getActivitiesByFilterUseCase,
  }) : super(WeeklyPlannerInitial()) {
    on<LoadWeeklyPlanner>(_onLoadWeeklyPlanner);
    on<ChangeWeek>(_onChangeWeek);
    on<GoToPreviousWeek>(_onGoToPreviousWeek);
    on<GoToNextWeek>(_onGoToNextWeek);
    on<GoToCurrentWeek>(_onGoToCurrentWeek);
    on<LoadWeekPlan>(_onLoadWeekPlan);
    on<CreateNewWeekPlan>(_onCreateNewWeekPlan);
    on<UpdateWeekPlan>(_onUpdateWeekPlan);
    on<DeleteWeekPlan>(_onDeleteWeekPlan);
    on<DuplicateWeekPlan>(_onDuplicateWeekPlan);
    on<AddActivity>(_onAddActivity);
    on<UpdateActivity>(_onUpdateActivity);
    on<DeleteActivity>(_onDeleteActivity);
    on<MoveActivity>(_onMoveActivity);
    on<DuplicateActivity>(_onDuplicateActivity);
    on<GenerateWeekPlan>(_onGenerateWeekPlan);
    on<LoadActivitySuggestions>(_onLoadActivitySuggestions);
    on<ApplySuggestion>(_onApplySuggestion);
    on<LoadTemplates>(_onLoadTemplates);
    on<CreateTemplateFromPlan>(_onCreateTemplateFromPlan);
    on<ApplyTemplate>(_onApplyTemplate);
    on<SearchPlans>(_onSearchPlans);
    on<SearchActivities>(_onSearchActivities);
    on<FilterActivities>(_onFilterActivities);
    on<ExportWeekToPdf>(_onExportWeekToPdf);
    on<ShareWeekPlan>(_onShareWeekPlan);
    on<SyncWithCalendar>(_onSyncWithCalendar);
    on<ToggleSidebar>(_onToggleSidebar);
    on<ChangeView>(_onChangeView);
    on<SelectActivity>(_onSelectActivity);
    on<StartDragActivity>(_onStartDragActivity);
    on<EndDragActivity>(_onEndDragActivity);
    on<DropActivity>(_onDropActivity);
  }

  DateTime _getWeekStart(DateTime date) {
    final weekday = date.weekday;
    return date.subtract(Duration(days: weekday - 1));
  }

  Map<String, int> _getDefaultColorScheme() {
    return {
      'SubjectCategory.math': 0xFF4CAF50,
      'SubjectCategory.science': 0xFF2196F3,
      'SubjectCategory.english': 0xFF9C27B0,
      'SubjectCategory.history': 0xFFFF9800,
      'SubjectCategory.geography': 0xFF8BC34A,
      'SubjectCategory.art': 0xFFE91E63,
      'SubjectCategory.music': 0xFF673AB7,
      'SubjectCategory.physicalEducation': 0xFFFF5722,
      'SubjectCategory.socialStudies': 0xFF795548,
      'SubjectCategory.computerScience': 0xFF607D8B,
    };
  }

  Future<void> _onLoadWeeklyPlanner(
      LoadWeeklyPlanner event, Emitter<WeeklyPlannerState> emit) async {
    try {
      emit(WeeklyPlannerLoading());

      final currentWeekStart = _getWeekStart(DateTime.now());
      final recentPlans = await getWeeklyPlansUseCase.execute();
      final templates = await getTemplatesUseCase.execute();
      final currentPlan =
          await getWeeklyPlanByDateUseCase.execute(currentWeekStart);

      emit(WeeklyPlannerLoaded(
        currentWeekStart: currentWeekStart,
        currentPlan: currentPlan,
        recentPlans: recentPlans,
        templates: templates,
        colorScheme: _getDefaultColorScheme(),
      ));
    } catch (e) {
      emit(
          WeeklyPlannerError('Failed to load weekly planner: ${e.toString()}'));
    }
  }

  Future<void> _onChangeWeek(
      ChangeWeek event, Emitter<WeeklyPlannerState> emit) async {
    if (state is! WeeklyPlannerLoaded) return;

    final currentState = state as WeeklyPlannerLoaded;

    try {
      final weekStart = _getWeekStart(event.weekStart);
      final plan = await getWeeklyPlanByDateUseCase.execute(weekStart);

      emit(currentState.copyWith(
        currentWeekStart: weekStart,
        currentPlan: plan,
      ));
    } catch (e) {
      emit(WeeklyPlannerError('Failed to change week: ${e.toString()}'));
    }
  }

  Future<void> _onGoToPreviousWeek(
      GoToPreviousWeek event, Emitter<WeeklyPlannerState> emit) async {
    if (state is! WeeklyPlannerLoaded) return;

    final currentState = state as WeeklyPlannerLoaded;
    final previousWeek =
        currentState.currentWeekStart.subtract(const Duration(days: 7));

    add(ChangeWeek(previousWeek));
  }

  Future<void> _onGoToNextWeek(
      GoToNextWeek event, Emitter<WeeklyPlannerState> emit) async {
    if (state is! WeeklyPlannerLoaded) return;

    final currentState = state as WeeklyPlannerLoaded;
    final nextWeek = currentState.currentWeekStart.add(const Duration(days: 7));

    add(ChangeWeek(nextWeek));
  }

  Future<void> _onGoToCurrentWeek(
      GoToCurrentWeek event, Emitter<WeeklyPlannerState> emit) async {
    final currentWeekStart = _getWeekStart(DateTime.now());
    add(ChangeWeek(currentWeekStart));
  }

  Future<void> _onLoadWeekPlan(
      LoadWeekPlan event, Emitter<WeeklyPlannerState> emit) async {
    if (state is! WeeklyPlannerLoaded) return;

    final currentState = state as WeeklyPlannerLoaded;

    try {
      final plan = await getWeeklyPlanByDateUseCase.execute(event.weekStart);
      emit(currentState.copyWith(currentPlan: plan));
    } catch (e) {
      emit(WeeklyPlannerError('Failed to load week plan: ${e.toString()}'));
    }
  }

  Future<void> _onCreateNewWeekPlan(
      CreateNewWeekPlan event, Emitter<WeeklyPlannerState> emit) async {
    if (state is! WeeklyPlannerLoaded) return;

    final currentState = state as WeeklyPlannerLoaded;

    try {
      final plan = WeeklyPlan(
        id: const Uuid().v4(),
        weekStart: event.weekStart,
        title: event.title,
        dayPlans: [],
        targetGrades: event.targetGrades,
        createdAt: DateTime.now(),
      );

      final planId = await saveWeeklyPlanUseCase.execute(plan);
      final savedPlan = plan.copyWith(id: planId);

      emit(currentState.copyWith(currentPlan: savedPlan));
    } catch (e) {
      emit(WeeklyPlannerError('Failed to create week plan: ${e.toString()}'));
    }
  }

  Future<void> _onUpdateWeekPlan(
      UpdateWeekPlan event, Emitter<WeeklyPlannerState> emit) async {
    if (state is! WeeklyPlannerLoaded) return;

    final currentState = state as WeeklyPlannerLoaded;

    try {
      await updateWeeklyPlanUseCase.execute(event.plan);
      emit(currentState.copyWith(currentPlan: event.plan));
    } catch (e) {
      emit(WeeklyPlannerError('Failed to update week plan: ${e.toString()}'));
    }
  }

  Future<void> _onDeleteWeekPlan(
      DeleteWeekPlan event, Emitter<WeeklyPlannerState> emit) async {
    if (state is! WeeklyPlannerLoaded) return;

    final currentState = state as WeeklyPlannerLoaded;

    try {
      await deleteWeeklyPlanUseCase.execute(event.planId);

      if (currentState.currentPlan?.id == event.planId) {
        emit(currentState.copyWith(currentPlan: null));
      }

      final updatedRecentPlans = currentState.recentPlans
          .where((plan) => plan.id != event.planId)
          .toList();

      emit(currentState.copyWith(recentPlans: updatedRecentPlans));
    } catch (e) {
      emit(WeeklyPlannerError('Failed to delete week plan: ${e.toString()}'));
    }
  }

  Future<void> _onDuplicateWeekPlan(
      DuplicateWeekPlan event, Emitter<WeeklyPlannerState> emit) async {
    if (state is! WeeklyPlannerLoaded) return;

    final currentState = state as WeeklyPlannerLoaded;

    try {
      final duplicatedPlan = await duplicateWeeklyPlanUseCase.execute(
        event.planId,
        event.newWeekStart,
      );

      final updatedRecentPlans = List<WeeklyPlan>.from(currentState.recentPlans)
        ..add(duplicatedPlan);

      emit(currentState.copyWith(recentPlans: updatedRecentPlans));
    } catch (e) {
      emit(
          WeeklyPlannerError('Failed to duplicate week plan: ${e.toString()}'));
    }
  }

  Future<void> _onAddActivity(
      AddActivity event, Emitter<WeeklyPlannerState> emit) async {
    if (state is! WeeklyPlannerLoaded) return;

    final currentState = state as WeeklyPlannerLoaded;

    try {
      // Save the activity
      await saveActivityUseCase.execute(event.activity);

      // Update the current plan
      if (currentState.currentPlan != null) {
        final updatedDayPlans =
            List<DayPlan>.from(currentState.currentPlan!.dayPlans);

        // Find or create the day plan for the target date
        final dayIndex = updatedDayPlans.indexWhere(
          (dayPlan) => currentState.isSameDay(dayPlan.date, event.date),
        );

        if (dayIndex >= 0) {
          // Update existing day plan
          final dayPlan = updatedDayPlans[dayIndex];
          final updatedActivities =
              List<LessonActivity>.from(dayPlan.activities)
                ..add(event.activity);

          updatedDayPlans[dayIndex] = dayPlan.copyWith(
            activities: updatedActivities,
            totalDuration: dayPlan.totalDuration + event.activity.duration,
          );
        } else {
          // Create new day plan
          updatedDayPlans.add(DayPlan(
            date: event.date,
            activities: [event.activity],
            totalDuration: event.activity.duration,
          ));
        }

        final updatedPlan = currentState.currentPlan!.copyWith(
          dayPlans: updatedDayPlans,
          modifiedAt: DateTime.now(),
        );

        await updateWeeklyPlanUseCase.execute(updatedPlan);
        emit(currentState.copyWith(currentPlan: updatedPlan));
      }

      emit(ActivityCreated(event.activity));
    } catch (e) {
      emit(WeeklyPlannerError('Failed to add activity: ${e.toString()}'));
    }
  }

  Future<void> _onUpdateActivity(
      UpdateActivity event, Emitter<WeeklyPlannerState> emit) async {
    if (state is! WeeklyPlannerLoaded) return;

    final currentState = state as WeeklyPlannerLoaded;

    try {
      await updateActivityUseCase.execute(event.activity);

      // Update in current plan if it exists
      if (currentState.currentPlan != null) {
        final updatedDayPlans =
            currentState.currentPlan!.dayPlans.map((dayPlan) {
          final updatedActivities = dayPlan.activities.map((activity) {
            return activity.id == event.activity.id ? event.activity : activity;
          }).toList();

          if (updatedActivities != dayPlan.activities) {
            final totalDuration = updatedActivities.fold<Duration>(
              Duration.zero,
              (total, activity) => total + activity.duration,
            );

            return dayPlan.copyWith(
              activities: updatedActivities,
              totalDuration: totalDuration,
            );
          }

          return dayPlan;
        }).toList();

        final updatedPlan = currentState.currentPlan!.copyWith(
          dayPlans: updatedDayPlans,
          modifiedAt: DateTime.now(),
        );

        await updateWeeklyPlanUseCase.execute(updatedPlan);
        emit(currentState.copyWith(currentPlan: updatedPlan));
      }

      emit(ActivityUpdated(event.activity));
    } catch (e) {
      emit(WeeklyPlannerError('Failed to update activity: ${e.toString()}'));
    }
  }

  Future<void> _onDeleteActivity(
      DeleteActivity event, Emitter<WeeklyPlannerState> emit) async {
    if (state is! WeeklyPlannerLoaded) return;

    final currentState = state as WeeklyPlannerLoaded;

    try {
      await deleteActivityUseCase.execute(event.activityId);

      // Update current plan if it exists
      if (currentState.currentPlan != null) {
        final updatedDayPlans =
            currentState.currentPlan!.dayPlans.map((dayPlan) {
          final updatedActivities = dayPlan.activities
              .where((activity) => activity.id != event.activityId)
              .toList();

          if (updatedActivities.length != dayPlan.activities.length) {
            final totalDuration = updatedActivities.fold<Duration>(
              Duration.zero,
              (total, activity) => total + activity.duration,
            );

            return dayPlan.copyWith(
              activities: updatedActivities,
              totalDuration: totalDuration,
            );
          }

          return dayPlan;
        }).toList();

        final updatedPlan = currentState.currentPlan!.copyWith(
          dayPlans: updatedDayPlans,
          modifiedAt: DateTime.now(),
        );

        await updateWeeklyPlanUseCase.execute(updatedPlan);
        emit(currentState.copyWith(currentPlan: updatedPlan));
      }

      emit(ActivityDeleted(event.activityId));
    } catch (e) {
      emit(WeeklyPlannerError('Failed to delete activity: ${e.toString()}'));
    }
  }

  Future<void> _onMoveActivity(
      MoveActivity event, Emitter<WeeklyPlannerState> emit) async {
    if (state is! WeeklyPlannerLoaded) return;

    final currentState = state as WeeklyPlannerLoaded;

    try {
      if (currentState.currentPlan == null) return;

      LessonActivity? activityToMove;
      final updatedDayPlans =
          List<DayPlan>.from(currentState.currentPlan!.dayPlans);

      // Find and remove the activity from the source date
      for (int i = 0; i < updatedDayPlans.length; i++) {
        final dayPlan = updatedDayPlans[i];
        if (currentState.isSameDay(dayPlan.date, event.fromDate)) {
          final activityIndex = dayPlan.activities.indexWhere(
            (activity) => activity.id == event.activityId,
          );

          if (activityIndex >= 0) {
            activityToMove = dayPlan.activities[activityIndex];
            final updatedActivities =
                List<LessonActivity>.from(dayPlan.activities)
                  ..removeAt(activityIndex);

            updatedDayPlans[i] = dayPlan.copyWith(
              activities: updatedActivities,
              totalDuration: dayPlan.totalDuration - activityToMove.duration,
            );
            break;
          }
        }
      }

      if (activityToMove == null) return;

      // Add the activity to the target date
      final targetDayIndex = updatedDayPlans.indexWhere(
        (dayPlan) => currentState.isSameDay(dayPlan.date, event.toDate),
      );

      if (targetDayIndex >= 0) {
        // Update existing day plan
        final targetDayPlan = updatedDayPlans[targetDayIndex];
        final updatedActivities =
            List<LessonActivity>.from(targetDayPlan.activities)
              ..add(activityToMove);

        updatedDayPlans[targetDayIndex] = targetDayPlan.copyWith(
          activities: updatedActivities,
          totalDuration: targetDayPlan.totalDuration + activityToMove.duration,
        );
      } else {
        // Create new day plan
        updatedDayPlans.add(DayPlan(
          date: event.toDate,
          activities: [activityToMove],
          totalDuration: activityToMove.duration,
        ));
      }

      final updatedPlan = currentState.currentPlan!.copyWith(
        dayPlans: updatedDayPlans,
        modifiedAt: DateTime.now(),
      );

      await updateWeeklyPlanUseCase.execute(updatedPlan);
      emit(currentState.copyWith(
        currentPlan: updatedPlan,
        clearDraggedActivity: true,
      ));
    } catch (e) {
      emit(WeeklyPlannerError('Failed to move activity: ${e.toString()}'));
    }
  }

  Future<void> _onDuplicateActivity(
      DuplicateActivity event, Emitter<WeeklyPlannerState> emit) async {
    if (state is! WeeklyPlannerLoaded) return;

    try {
      if (event.targetGrades != null && event.targetGrades!.isNotEmpty) {
        // Copy to multiple grades
        await copyActivityToGradesUseCase.execute(
          event.activityId,
          event.targetGrades!,
        );
      } else {
        // Simple duplication
        final duplicatedActivity =
            await duplicateActivityUseCase.execute(event.activityId);

        if (event.targetDate != null) {
          add(AddActivity(event.targetDate!, duplicatedActivity));
        }
      }
    } catch (e) {
      emit(WeeklyPlannerError('Failed to duplicate activity: ${e.toString()}'));
    }
  }

  Future<void> _onGenerateWeekPlan(
      GenerateWeekPlan event, Emitter<WeeklyPlannerState> emit) async {
    if (state is! WeeklyPlannerLoaded) return;

    final currentState = state as WeeklyPlannerLoaded;

    try {
      emit(WeeklyPlanGenerating('Generating week plan...', progress: 0.0));

      final generatedPlan = await generateWeekPlanUseCase.execute(
        weekStart: event.weekStart,
        targetGrades: event.targetGrades,
        preferredSubjects: event.preferredSubjects,
        hoursPerDay: event.hoursPerDay,
        theme: event.theme,
      );

      emit(WeeklyPlanGenerating('Saving generated plan...', progress: 0.8));

      await saveWeeklyPlanUseCase.execute(generatedPlan);

      emit(currentState.copyWith(
        currentPlan: generatedPlan,
        isGenerating: false,
      ));
    } catch (e) {
      emit(WeeklyPlannerError('Failed to generate week plan: ${e.toString()}'));
    }
  }

  Future<void> _onLoadActivitySuggestions(
      LoadActivitySuggestions event, Emitter<WeeklyPlannerState> emit) async {
    if (state is! WeeklyPlannerLoaded) return;

    final currentState = state as WeeklyPlannerLoaded;

    try {
      final suggestions = await getActivitySuggestionsUseCase.execute(
        subject: event.subject,
        grade: event.grade,
        type: event.type,
        context: event.context,
      );

      emit(currentState.copyWith(suggestions: suggestions));
    } catch (e) {
      emit(WeeklyPlannerError('Failed to load suggestions: ${e.toString()}'));
    }
  }

  Future<void> _onApplySuggestion(
      ApplySuggestion event, Emitter<WeeklyPlannerState> emit) async {
    try {
      final activity = event.suggestion.toActivity(
        customId: const Uuid().v4(),
        generatedFrom: 'ai_suggestion',
      );

      add(AddActivity(event.date, activity));
    } catch (e) {
      emit(WeeklyPlannerError('Failed to apply suggestion: ${e.toString()}'));
    }
  }

  Future<void> _onLoadTemplates(
      LoadTemplates event, Emitter<WeeklyPlannerState> emit) async {
    if (state is! WeeklyPlannerLoaded) return;

    final currentState = state as WeeklyPlannerLoaded;

    try {
      final templates = await getTemplatesUseCase.execute();
      emit(currentState.copyWith(templates: templates));
    } catch (e) {
      emit(WeeklyPlannerError('Failed to load templates: ${e.toString()}'));
    }
  }

  Future<void> _onCreateTemplateFromPlan(
      CreateTemplateFromPlan event, Emitter<WeeklyPlannerState> emit) async {
    if (state is! WeeklyPlannerLoaded) return;

    final currentState = state as WeeklyPlannerLoaded;

    try {
      final template = await createTemplateFromPlanUseCase.execute(
        event.plan,
        event.category,
      );

      final updatedTemplates = List<WeeklyPlan>.from(currentState.templates)
        ..add(template);

      emit(currentState.copyWith(templates: updatedTemplates));
      emit(TemplateCreated(template));
    } catch (e) {
      emit(WeeklyPlannerError('Failed to create template: ${e.toString()}'));
    }
  }

  Future<void> _onApplyTemplate(
      ApplyTemplate event, Emitter<WeeklyPlannerState> emit) async {
    if (state is! WeeklyPlannerLoaded) return;

    try {
      final appliedPlan = event.template.copyWith(
        id: const Uuid().v4(),
        weekStart: event.weekStart,
        isTemplate: false,
        templateCategory: null,
        createdAt: DateTime.now(),
        modifiedAt: null,
      );

      await saveWeeklyPlanUseCase.execute(appliedPlan);
      add(ChangeWeek(event.weekStart));
    } catch (e) {
      emit(WeeklyPlannerError('Failed to apply template: ${e.toString()}'));
    }
  }

  Future<void> _onSearchPlans(
      SearchPlans event, Emitter<WeeklyPlannerState> emit) async {
    if (state is! WeeklyPlannerLoaded) return;

    final currentState = state as WeeklyPlannerLoaded;

    try {
      final searchResults = await searchWeeklyPlansUseCase.execute(event.query);
      emit(currentState.copyWith(
        recentPlans: searchResults,
        searchQuery: event.query,
      ));
    } catch (e) {
      emit(WeeklyPlannerError('Failed to search plans: ${e.toString()}'));
    }
  }

  Future<void> _onSearchActivities(
      SearchActivities event, Emitter<WeeklyPlannerState> emit) async {
    if (state is! WeeklyPlannerLoaded) return;

    final currentState = state as WeeklyPlannerLoaded;

    try {
      final searchResults = await searchActivitiesUseCase.execute(event.query);
      emit(currentState.copyWith(
        filteredActivities: searchResults,
        searchQuery: event.query,
      ));
    } catch (e) {
      emit(WeeklyPlannerError('Failed to search activities: ${e.toString()}'));
    }
  }

  Future<void> _onFilterActivities(
      FilterActivities event, Emitter<WeeklyPlannerState> emit) async {
    if (state is! WeeklyPlannerLoaded) return;

    final currentState = state as WeeklyPlannerLoaded;

    try {
      List<LessonActivity> filteredActivities = [];

      if (event.subject != null) {
        filteredActivities =
            await getActivitiesByFilterUseCase.executeBySubject(event.subject!);
      } else if (event.grade != null) {
        filteredActivities =
            await getActivitiesByFilterUseCase.executeByGrade(event.grade!);
      } else if (event.type != null) {
        filteredActivities =
            await getActivitiesByFilterUseCase.executeByType(event.type!);
      } else {
        filteredActivities = await getActivitiesUseCase.execute();
      }

      emit(currentState.copyWith(
        filteredActivities: filteredActivities,
        filterSubject: event.subject,
        filterGrade: event.grade,
        filterType: event.type,
      ));
    } catch (e) {
      emit(WeeklyPlannerError('Failed to filter activities: ${e.toString()}'));
    }
  }

  Future<void> _onExportWeekToPdf(
      ExportWeekToPdf event, Emitter<WeeklyPlannerState> emit) async {
    try {
      final filePath = await exportWeeklyPlanToPdfUseCase.execute(event.plan);
      emit(WeekPlanExported(filePath, 'pdf'));
    } catch (e) {
      emit(WeeklyPlannerError('Failed to export to PDF: ${e.toString()}'));
    }
  }

  Future<void> _onShareWeekPlan(
      ShareWeekPlan event, Emitter<WeeklyPlannerState> emit) async {
    try {
      final shareContent = await shareWeeklyPlanUseCase.execute(event.plan);
      emit(WeekPlanExported(shareContent, 'share'));
    } catch (e) {
      emit(WeeklyPlannerError('Failed to share week plan: ${e.toString()}'));
    }
  }

  Future<void> _onSyncWithCalendar(
      SyncWithCalendar event, Emitter<WeeklyPlannerState> emit) async {
    try {
      await syncWithDeviceCalendarUseCase.execute(event.plan);
      emit(WeekPlanExported('calendar', 'calendar'));
    } catch (e) {
      emit(WeeklyPlannerError('Failed to sync with calendar: ${e.toString()}'));
    }
  }

  void _onToggleSidebar(ToggleSidebar event, Emitter<WeeklyPlannerState> emit) {
    if (state is! WeeklyPlannerLoaded) return;

    final currentState = state as WeeklyPlannerLoaded;
    emit(currentState.copyWith(isSidebarOpen: !currentState.isSidebarOpen));
  }

  void _onChangeView(ChangeView event, Emitter<WeeklyPlannerState> emit) {
    if (state is! WeeklyPlannerLoaded) return;

    final currentState = state as WeeklyPlannerLoaded;
    emit(currentState.copyWith(currentView: event.viewType));
  }

  void _onSelectActivity(
      SelectActivity event, Emitter<WeeklyPlannerState> emit) {
    if (state is! WeeklyPlannerLoaded) return;

    final currentState = state as WeeklyPlannerLoaded;
    emit(currentState.copyWith(selectedActivityId: event.activityId));
  }

  void _onStartDragActivity(
      StartDragActivity event, Emitter<WeeklyPlannerState> emit) {
    if (state is! WeeklyPlannerLoaded) return;

    final currentState = state as WeeklyPlannerLoaded;
    emit(currentState.copyWith(draggedActivity: event.activity));
  }

  void _onEndDragActivity(
      EndDragActivity event, Emitter<WeeklyPlannerState> emit) {
    if (state is! WeeklyPlannerLoaded) return;

    final currentState = state as WeeklyPlannerLoaded;
    emit(currentState.copyWith(clearDraggedActivity: true));
  }

  void _onDropActivity(DropActivity event, Emitter<WeeklyPlannerState> emit) {
    if (state is! WeeklyPlannerLoaded) return;

    final currentState = state as WeeklyPlannerLoaded;

    if (currentState.draggedActivity != null) {
      // Find the original date of the dragged activity
      DateTime? fromDate;

      for (final dayPlan in currentState.currentPlan?.dayPlans ?? []) {
        if (dayPlan.activities.any(
            (activity) => activity.id == currentState.draggedActivity!.id)) {
          fromDate = dayPlan.date;
          break;
        }
      }

      if (fromDate != null) {
        add(MoveActivity(
          currentState.draggedActivity!.id,
          fromDate,
          event.targetDate,
        ));
      }
    }
  }
}
