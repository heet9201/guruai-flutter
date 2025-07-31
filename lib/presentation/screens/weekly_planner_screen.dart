import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';
import '../../core/theme/responsive_layout.dart';
import '../../domain/entities/weekly_plan.dart';
import '../bloc/weekly_planner_bloc.dart';
import '../bloc/weekly_planner_event.dart';
import '../bloc/weekly_planner_state.dart';
import '../widgets/weekly_planner/calendar_view.dart';
import '../widgets/weekly_planner/activity_suggestions_sidebar.dart';
import '../widgets/weekly_planner/week_navigation_bar.dart';
import '../widgets/weekly_planner/activity_editor_dialog.dart';
import '../widgets/weekly_planner/weekly_plan_header.dart';

class WeeklyPlannerScreen extends StatefulWidget {
  const WeeklyPlannerScreen({super.key});

  @override
  State<WeeklyPlannerScreen> createState() => _WeeklyPlannerScreenState();
}

class _WeeklyPlannerScreenState extends State<WeeklyPlannerScreen>
    with TickerProviderStateMixin {
  late AnimationController _sidebarAnimationController;
  late Animation<double> _sidebarAnimation;

  @override
  void initState() {
    super.initState();
    _setupAnimations();

    // Load the weekly planner
    context.read<WeeklyPlannerBloc>().add(LoadWeeklyPlanner());
  }

  void _setupAnimations() {
    _sidebarAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _sidebarAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _sidebarAnimationController,
      curve: Curves.easeInOut,
    ));

    _sidebarAnimationController.forward();
  }

  @override
  void dispose() {
    _sidebarAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocConsumer<WeeklyPlannerBloc, WeeklyPlannerState>(
        listener: (context, state) {
          if (state is WeeklyPlannerError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Theme.of(context).colorScheme.error,
              ),
            );
          } else if (state is WeekPlanExported) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(_getExportSuccessMessage(state.exportType)),
                backgroundColor: Theme.of(context).colorScheme.primary,
              ),
            );
          } else if (state is ActivityCreated) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Activity added successfully!'),
              ),
            );
          }

          // Handle sidebar animation
          if (state is WeeklyPlannerLoaded) {
            if (state.isSidebarOpen) {
              _sidebarAnimationController.forward();
            } else {
              _sidebarAnimationController.reverse();
            }
          }
        },
        builder: (context, state) {
          if (state is WeeklyPlannerLoading) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (state is WeeklyPlannerLoaded) {
            return _buildLoadedView(context, state);
          }

          if (state is WeeklyPlanGenerating) {
            return _buildGeneratingView(context, state);
          }

          return const Center(
            child: Text('Something went wrong'),
          );
        },
      ),
      floatingActionButton: BlocBuilder<WeeklyPlannerBloc, WeeklyPlannerState>(
        builder: (context, state) {
          if (state is! WeeklyPlannerLoaded) return const SizedBox.shrink();

          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              FloatingActionButton(
                heroTag: 'add_activity',
                onPressed: () => _showActivityEditor(context, state),
                tooltip: 'Add Activity',
                child: const Icon(Icons.add),
              ),
              const SizedBox(height: 16),
              FloatingActionButton.extended(
                heroTag: 'auto_fill',
                onPressed: () => _showAutoFillDialog(context, state),
                icon: const Icon(Icons.auto_awesome),
                label: const Text('Auto-Fill'),
                backgroundColor: Theme.of(context).colorScheme.secondary,
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildLoadedView(BuildContext context, WeeklyPlannerLoaded state) {
    return Column(
      children: [
        // Header with week navigation and controls
        WeeklyPlanHeader(
          currentPlan: state.currentPlan,
          currentWeekStart: state.currentWeekStart,
          onPreviousWeek: () =>
              context.read<WeeklyPlannerBloc>().add(GoToPreviousWeek()),
          onNextWeek: () =>
              context.read<WeeklyPlannerBloc>().add(GoToNextWeek()),
          onToday: () =>
              context.read<WeeklyPlannerBloc>().add(GoToCurrentWeek()),
          onToggleSidebar: () =>
              context.read<WeeklyPlannerBloc>().add(ToggleSidebar()),
          onViewChange: (viewType) =>
              context.read<WeeklyPlannerBloc>().add(ChangeView(viewType)),
          currentView: state.currentView,
          isSidebarOpen: state.isSidebarOpen,
        ),

        // Week navigation bar
        WeekNavigationBar(
          currentWeekStart: state.currentWeekStart,
          onWeekChanged: (weekStart) =>
              context.read<WeeklyPlannerBloc>().add(ChangeWeek(weekStart)),
        ),

        // Main content area
        Expanded(
          child: Row(
            children: [
              // Calendar view
              Expanded(
                flex: state.isSidebarOpen ? 7 : 10,
                child: CalendarView(
                  currentPlan: state.currentPlan,
                  currentWeekStart: state.currentWeekStart,
                  selectedActivityId: state.selectedActivityId,
                  draggedActivity: state.draggedActivity,
                  viewType: state.currentView,
                  colorScheme: state.colorScheme,
                  onActivityTap: (activity) =>
                      _onActivityTap(context, activity),
                  onActivityDrop: (activity, date) =>
                      _onActivityDrop(context, activity, date),
                  onDayTap: (date) => _onDayTap(context, state, date),
                  onActivityEdit: (activity) =>
                      _showActivityEditor(context, state, activity: activity),
                  onActivityDuplicate: (activity) =>
                      _onActivityDuplicate(context, activity),
                  onActivityDelete: (activity) =>
                      _onActivityDelete(context, activity),
                ),
              ),

              // Sidebar with suggestions
              if (state.isSidebarOpen)
                AnimatedBuilder(
                  animation: _sidebarAnimation,
                  builder: (context, child) {
                    return SizedBox(
                      width: 350 * _sidebarAnimation.value,
                      child: _sidebarAnimation.value > 0.5
                          ? ActivitySuggestionsSidebar(
                              suggestions: state.suggestions,
                              filteredActivities: state.filteredActivities,
                              templates: state.templates,
                              onSuggestionApplied: (suggestion, date) =>
                                  _onSuggestionApplied(
                                      context, suggestion, date),
                              onTemplateApplied: (template) =>
                                  _onTemplateApplied(context, state, template),
                              onFilterChanged: (subject, grade, type) =>
                                  _onFilterChanged(
                                      context, subject, grade, type),
                              onSearchChanged: (query) =>
                                  _onSearchChanged(context, query),
                              currentFilters: {
                                'subject': state.filterSubject,
                                'grade': state.filterGrade,
                                'type': state.filterType,
                              },
                            )
                          : const SizedBox.shrink(),
                    );
                  },
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildGeneratingView(
      BuildContext context, WeeklyPlanGenerating state) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            value: state.progress,
          ),
          const SizedBox(height: 24),
          Text(
            state.message,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          Text(
            '${(state.progress * 100).toInt()}% Complete',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ],
      ),
    );
  }

  void _onActivityTap(BuildContext context, LessonActivity activity) {
    context.read<WeeklyPlannerBloc>().add(SelectActivity(activity.id));
    _showActivityDetails(context, activity);
  }

  void _onActivityDrop(
      BuildContext context, LessonActivity activity, DateTime date) {
    context.read<WeeklyPlannerBloc>().add(DropActivity(date));
  }

  void _onDayTap(
      BuildContext context, WeeklyPlannerLoaded state, DateTime date) {
    if (state.currentPlan == null) {
      _showCreatePlanDialog(context, state, date);
    } else {
      _showActivityEditor(context, state, targetDate: date);
    }
  }

  void _onActivityDuplicate(BuildContext context, LessonActivity activity) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Duplicate Activity'),
        content: const Text('Would you like to duplicate this activity?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              context
                  .read<WeeklyPlannerBloc>()
                  .add(DuplicateActivity(activity.id));
            },
            child: const Text('Duplicate'),
          ),
        ],
      ),
    );
  }

  void _onActivityDelete(BuildContext context, LessonActivity activity) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Activity'),
        content: Text('Are you sure you want to delete "${activity.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              context
                  .read<WeeklyPlannerBloc>()
                  .add(DeleteActivity(activity.id));
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _onSuggestionApplied(
      BuildContext context, ActivitySuggestion suggestion, DateTime date) {
    context.read<WeeklyPlannerBloc>().add(ApplySuggestion(suggestion, date));
  }

  void _onTemplateApplied(
      BuildContext context, WeeklyPlannerLoaded state, WeeklyPlan template) {
    context
        .read<WeeklyPlannerBloc>()
        .add(ApplyTemplate(template, state.currentWeekStart));
  }

  void _onFilterChanged(BuildContext context, SubjectCategory? subject,
      Grade? grade, ActivityType? type) {
    context.read<WeeklyPlannerBloc>().add(FilterActivities(
          subject: subject,
          grade: grade,
          type: type,
        ));
  }

  void _onSearchChanged(BuildContext context, String query) {
    if (query.isNotEmpty) {
      context.read<WeeklyPlannerBloc>().add(SearchActivities(query));
    } else {
      context.read<WeeklyPlannerBloc>().add(FilterActivities());
    }
  }

  void _showActivityEditor(
    BuildContext context,
    WeeklyPlannerLoaded state, {
    LessonActivity? activity,
    DateTime? targetDate,
  }) {
    showDialog(
      context: context,
      builder: (context) => ActivityEditorDialog(
        activity: activity,
        targetDate: targetDate ?? state.currentWeekStart,
        onSave: (newActivity, date) {
          if (activity != null) {
            context.read<WeeklyPlannerBloc>().add(UpdateActivity(newActivity));
          } else {
            context
                .read<WeeklyPlannerBloc>()
                .add(AddActivity(date, newActivity));
          }
        },
      ),
    );
  }

  void _showActivityDetails(BuildContext context, LessonActivity activity) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        builder: (context, scrollController) => _buildActivityDetailsSheet(
          context,
          activity,
          scrollController,
        ),
      ),
    );
  }

  Widget _buildActivityDetailsSheet(
    BuildContext context,
    LessonActivity activity,
    ScrollController scrollController,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        children: [
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(top: 8),
            decoration: BoxDecoration(
              color: Theme.of(context).dividerColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Expanded(
            child: ListView(
              controller: scrollController,
              padding: const EdgeInsets.all(24),
              children: [
                Row(
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: Color(activity.colorCode ?? 0xFF6B73FF),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        activity.title,
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        _showActivityEditor(
                          context,
                          context.read<WeeklyPlannerBloc>().state
                              as WeeklyPlannerLoaded,
                          activity: activity,
                        );
                      },
                      icon: const Icon(Icons.edit),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildDetailRow(
                    context, 'Subject', _getSubjectName(activity.subject)),
                _buildDetailRow(
                    context, 'Grade', _getGradeName(activity.grade)),
                _buildDetailRow(
                    context, 'Type', _getActivityTypeName(activity.type)),
                _buildDetailRow(context, 'Duration',
                    '${activity.duration.inMinutes} minutes'),
                const SizedBox(height: 24),
                Text(
                  'Description',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Text(activity.description),
                if (activity.objectives != null) ...[
                  const SizedBox(height: 24),
                  Text(
                    'Objectives',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(activity.objectives!),
                ],
                if (activity.materials != null) ...[
                  const SizedBox(height: 24),
                  Text(
                    'Materials',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(activity.materials!),
                ],
                if (activity.tags.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  Text(
                    'Tags',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: activity.tags
                        .map((tag) => Chip(
                              label: Text(tag),
                              backgroundColor:
                                  Theme.of(context).colorScheme.surfaceVariant,
                            ))
                        .toList(),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w500,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  void _showCreatePlanDialog(
    BuildContext context,
    WeeklyPlannerLoaded state,
    DateTime date,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create Weekly Plan'),
        content: const Text(
          'No plan exists for this week. Would you like to create one?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              context.read<WeeklyPlannerBloc>().add(CreateNewWeekPlan(
                    state.currentWeekStart,
                    'Week Plan - ${_formatWeekRange(state.currentWeekStart)}',
                    [Grade.grade1, Grade.grade2], // Default grades
                  ));
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  void _showAutoFillDialog(BuildContext context, WeeklyPlannerLoaded state) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Auto-Fill Week'),
        content: const Text(
          'This will automatically generate a full week plan with AI-suggested activities. Continue?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              context.read<WeeklyPlannerBloc>().add(GenerateWeekPlan(
                    state.currentWeekStart,
                    [Grade.grade1, Grade.grade2, Grade.grade3],
                    preferredSubjects: [
                      SubjectCategory.math,
                      SubjectCategory.science,
                      SubjectCategory.english,
                    ],
                    hoursPerDay: 6,
                  ));
            },
            child: const Text('Generate'),
          ),
        ],
      ),
    );
  }

  String _getExportSuccessMessage(String exportType) {
    switch (exportType) {
      case 'pdf':
        return 'Weekly plan exported to PDF successfully!';
      case 'share':
        return 'Weekly plan shared successfully!';
      case 'calendar':
        return 'Weekly plan synced to calendar successfully!';
      default:
        return 'Export completed successfully!';
    }
  }

  String _formatWeekRange(DateTime weekStart) {
    final weekEnd = weekStart.add(const Duration(days: 6));
    return '${weekStart.day}/${weekStart.month} - ${weekEnd.day}/${weekEnd.month}';
  }

  String _getSubjectName(SubjectCategory subject) {
    return subject
        .toString()
        .split('.')
        .last
        .replaceAllMapped(
          RegExp(r'([A-Z])'),
          (match) => ' ${match.group(0)}',
        )
        .trim();
  }

  String _getGradeName(Grade grade) {
    return grade.toString().split('.').last.replaceAll('grade', 'Grade ');
  }

  String _getActivityTypeName(ActivityType type) {
    return type
        .toString()
        .split('.')
        .last
        .replaceAllMapped(
          RegExp(r'([A-Z])'),
          (match) => ' ${match.group(0)}',
        )
        .trim();
  }
}
