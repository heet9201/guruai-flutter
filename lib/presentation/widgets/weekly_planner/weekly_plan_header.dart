import 'package:flutter/material.dart';
import '../../../domain/entities/weekly_plan.dart';

class WeeklyPlanHeader extends StatelessWidget {
  final WeeklyPlan? currentPlan;
  final DateTime currentWeekStart;
  final VoidCallback onPreviousWeek;
  final VoidCallback onNextWeek;
  final VoidCallback onToday;
  final VoidCallback onToggleSidebar;
  final Function(String) onViewChange;
  final String currentView;
  final bool isSidebarOpen;

  const WeeklyPlanHeader({
    super.key,
    this.currentPlan,
    required this.currentWeekStart,
    required this.onPreviousWeek,
    required this.onNextWeek,
    required this.onToday,
    required this.onToggleSidebar,
    required this.onViewChange,
    required this.currentView,
    required this.isSidebarOpen,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Column(
            children: [
              Row(
                children: [
                  // Back button
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.arrow_back),
                  ),

                  // Title and week info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Weekly Planner',
                          style:
                              Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                        ),
                        Text(
                          _formatWeekRange(currentWeekStart),
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant,
                                  ),
                        ),
                      ],
                    ),
                  ),

                  // View switcher
                  SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(value: 'week', label: Text('Week')),
                      ButtonSegment(value: 'day', label: Text('Day')),
                    ],
                    selected: {currentView},
                    onSelectionChanged: (Set<String> selection) {
                      onViewChange(selection.first);
                    },
                    style: SegmentedButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                    ),
                  ),

                  const SizedBox(width: 8),

                  // Sidebar toggle
                  IconButton(
                    onPressed: onToggleSidebar,
                    icon: Icon(
                      isSidebarOpen ? Icons.menu_open : Icons.menu,
                    ),
                    tooltip: isSidebarOpen ? 'Hide Sidebar' : 'Show Sidebar',
                  ),

                  // More options
                  PopupMenuButton<String>(
                    onSelected: (value) => _handleMenuAction(context, value),
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'export_pdf',
                        child: Row(
                          children: [
                            Icon(Icons.picture_as_pdf),
                            SizedBox(width: 8),
                            Text('Export to PDF'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'share',
                        child: Row(
                          children: [
                            Icon(Icons.share),
                            SizedBox(width: 8),
                            Text('Share Plan'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'sync_calendar',
                        child: Row(
                          children: [
                            Icon(Icons.calendar_today),
                            SizedBox(width: 8),
                            Text('Sync to Calendar'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'template',
                        child: Row(
                          children: [
                            Icon(Icons.save),
                            SizedBox(width: 8),
                            Text('Save as Template'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'duplicate',
                        child: Row(
                          children: [
                            Icon(Icons.copy),
                            SizedBox(width: 8),
                            Text('Duplicate Week'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 8),

              // Week navigation
              Row(
                children: [
                  IconButton(
                    onPressed: onPreviousWeek,
                    icon: const Icon(Icons.chevron_left),
                    tooltip: 'Previous Week',
                  ),
                  Expanded(
                    child: Center(
                      child: TextButton(
                        onPressed: onToday,
                        child: Text(
                          _getWeekTitle(currentWeekStart),
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w500,
                                  ),
                        ),
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: onNextWeek,
                    icon: const Icon(Icons.chevron_right),
                    tooltip: 'Next Week',
                  ),
                ],
              ),

              // Plan info if exists
              if (currentPlan != null) ...[
                const SizedBox(height: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.school,
                        size: 16,
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          currentPlan!.title,
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onPrimaryContainer,
                                    fontWeight: FontWeight.w500,
                                  ),
                        ),
                      ),
                      _buildPlanStats(context),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlanStats(BuildContext context) {
    if (currentPlan == null) return const SizedBox.shrink();

    final totalActivities = currentPlan!.allActivities.length;
    final totalDuration = currentPlan!.totalWeekDuration;
    final subjects = currentPlan!.subjectDistribution.length;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildStatChip(
          context,
          Icons.assignment,
          '$totalActivities',
          'Activities',
        ),
        const SizedBox(width: 8),
        _buildStatChip(
          context,
          Icons.schedule,
          '${totalDuration.inHours}h',
          'Duration',
        ),
        const SizedBox(width: 8),
        _buildStatChip(
          context,
          Icons.subject,
          '$subjects',
          'Subjects',
        ),
      ],
    );
  }

  Widget _buildStatChip(
    BuildContext context,
    IconData icon,
    String value,
    String label,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface.withOpacity(0.8),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 12,
            color: Theme.of(context).colorScheme.onSurface,
          ),
          const SizedBox(width: 4),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                value,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      fontSize: 10,
                    ),
              ),
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontSize: 8,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _handleMenuAction(BuildContext context, String action) {
    if (currentPlan == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No plan available for this action'),
        ),
      );
      return;
    }

    switch (action) {
      case 'export_pdf':
        _showExportDialog(context);
        break;
      case 'share':
        _showShareDialog(context);
        break;
      case 'sync_calendar':
        _showCalendarSyncDialog(context);
        break;
      case 'template':
        _showSaveTemplateDialog(context);
        break;
      case 'duplicate':
        _showDuplicateDialog(context);
        break;
    }
  }

  void _showExportDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Export to PDF'),
        content: const Text('Export this weekly plan as a PDF file?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              // Trigger export
              // context.read<WeeklyPlannerBloc>().add(ExportWeekToPdf(currentPlan!));
            },
            child: const Text('Export'),
          ),
        ],
      ),
    );
  }

  void _showShareDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Share Weekly Plan'),
        content: const Text('Share this weekly plan with others?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              // Trigger share
              // context.read<WeeklyPlannerBloc>().add(ShareWeekPlan(currentPlan!));
            },
            child: const Text('Share'),
          ),
        ],
      ),
    );
  }

  void _showCalendarSyncDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sync to Calendar'),
        content: const Text(
            'Add all activities from this week to your device calendar?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              // Trigger calendar sync
              // context.read<WeeklyPlannerBloc>().add(SyncWithCalendar(currentPlan!));
            },
            child: const Text('Sync'),
          ),
        ],
      ),
    );
  }

  void _showSaveTemplateDialog(BuildContext context) {
    String templateName = '';
    String category = 'General';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Save as Template'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              decoration: const InputDecoration(
                labelText: 'Template Name',
                hintText: 'Enter template name',
              ),
              onChanged: (value) => templateName = value,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: category,
              decoration: const InputDecoration(
                labelText: 'Category',
              ),
              items: const [
                DropdownMenuItem(value: 'General', child: Text('General')),
                DropdownMenuItem(value: 'Math', child: Text('Math')),
                DropdownMenuItem(value: 'Science', child: Text('Science')),
                DropdownMenuItem(value: 'English', child: Text('English')),
                DropdownMenuItem(value: 'History', child: Text('History')),
              ],
              onChanged: (value) => category = value ?? 'General',
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (templateName.isNotEmpty) {
                Navigator.of(context).pop();
                // Create template
                final template = currentPlan!.copyWith(
                  title: templateName,
                  isTemplate: true,
                  templateCategory: category,
                );
                // context.read<WeeklyPlannerBloc>().add(CreateTemplateFromPlan(template, category));
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showDuplicateDialog(BuildContext context) {
    DateTime? selectedDate;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Duplicate Weekly Plan'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Select the week to copy this plan to:'),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: currentWeekStart.add(const Duration(days: 7)),
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );
                  if (date != null) {
                    setState(() {
                      selectedDate = _getWeekStart(date);
                    });
                  }
                },
                child: Text(
                  selectedDate != null
                      ? _formatWeekRange(selectedDate!)
                      : 'Select Date',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: selectedDate != null
                  ? () {
                      Navigator.of(context).pop();
                      // Duplicate plan
                      // context.read<WeeklyPlannerBloc>().add(
                      //   DuplicateWeekPlan(currentPlan!.id, selectedDate!),
                      // );
                    }
                  : null,
              child: const Text('Duplicate'),
            ),
          ],
        ),
      ),
    );
  }

  String _formatWeekRange(DateTime weekStart) {
    final weekEnd = weekStart.add(const Duration(days: 6));
    return '${weekStart.day}/${weekStart.month} - ${weekEnd.day}/${weekEnd.month}';
  }

  String _getWeekTitle(DateTime weekStart) {
    final now = DateTime.now();
    final currentWeek = _getWeekStart(now);

    if (_isSameWeek(weekStart, currentWeek)) {
      return 'This Week';
    } else if (_isSameWeek(
        weekStart, currentWeek.add(const Duration(days: 7)))) {
      return 'Next Week';
    } else if (_isSameWeek(
        weekStart, currentWeek.subtract(const Duration(days: 7)))) {
      return 'Last Week';
    } else {
      return _formatWeekRange(weekStart);
    }
  }

  DateTime _getWeekStart(DateTime date) {
    final weekday = date.weekday;
    return date.subtract(Duration(days: weekday - 1));
  }

  bool _isSameWeek(DateTime date1, DateTime date2) {
    final week1Start = _getWeekStart(date1);
    final week2Start = _getWeekStart(date2);
    return week1Start.isAtSameMomentAs(week2Start);
  }
}
