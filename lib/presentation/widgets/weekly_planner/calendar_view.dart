import 'package:flutter/material.dart';
import '../../../domain/entities/weekly_plan.dart';

class CalendarView extends StatefulWidget {
  final WeeklyPlan? currentPlan;
  final DateTime currentWeekStart;
  final String? selectedActivityId;
  final LessonActivity? draggedActivity;
  final String viewType;
  final Map<String, int> colorScheme;
  final Function(LessonActivity) onActivityTap;
  final Function(LessonActivity, DateTime) onActivityDrop;
  final Function(DateTime) onDayTap;
  final Function(LessonActivity) onActivityEdit;
  final Function(LessonActivity) onActivityDuplicate;
  final Function(LessonActivity) onActivityDelete;

  const CalendarView({
    super.key,
    this.currentPlan,
    required this.currentWeekStart,
    this.selectedActivityId,
    this.draggedActivity,
    required this.viewType,
    required this.colorScheme,
    required this.onActivityTap,
    required this.onActivityDrop,
    required this.onDayTap,
    required this.onActivityEdit,
    required this.onActivityDuplicate,
    required this.onActivityDelete,
  });

  @override
  State<CalendarView> createState() => _CalendarViewState();
}

class _CalendarViewState extends State<CalendarView> {
  final PageController _pageController = PageController();

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    switch (widget.viewType) {
      case 'day':
        return _buildDayView();
      case 'month':
        return _buildMonthView();
      default:
        return _buildWeekView();
    }
  }

  Widget _buildWeekView() {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      margin: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildWeekHeader(),
          const Divider(height: 1),
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              onPageChanged: (index) {
                // Handle week navigation via swipe
                final newWeekStart = widget.currentWeekStart
                    .add(Duration(days: (index - 50) * 7));
                // Note: In a real implementation, you'd call a callback here
              },
              itemBuilder: (context, index) {
                final weekOffset = index - 50; // Center on current week
                final weekStart =
                    widget.currentWeekStart.add(Duration(days: weekOffset * 7));
                return _buildWeekContent(weekStart);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeekHeader() {
    final dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        children: [
          const SizedBox(width: 80), // Time column width
          ...dayNames.take(5).map((day) => Expanded(
                child: Center(
                  child: Text(
                    day,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildWeekContent(DateTime weekStart) {
    return Row(
      children: [
        _buildTimeColumn(),
        ...List.generate(5, (index) {
          final date = weekStart.add(Duration(days: index));
          return Expanded(
            child: _buildDayColumn(date),
          );
        }),
      ],
    );
  }

  Widget _buildTimeColumn() {
    return Container(
      width: 80,
      padding: const EdgeInsets.only(right: 8),
      child: Column(
        children: List.generate(10, (index) {
          final hour = 8 + index; // 8 AM to 5 PM
          return Container(
            height: 60,
            alignment: Alignment.topRight,
            child: Text(
              '${hour.toString().padLeft(2, '0')}:00',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildDayColumn(DateTime date) {
    final dayPlan = _getDayPlan(date);
    final activities = dayPlan?.activities ?? [];
    final isToday = _isToday(date);

    return DragTarget<LessonActivity>(
      onAcceptWithDetails: (details) {
        widget.onActivityDrop(details.data, date);
      },
      builder: (context, candidateData, rejectedData) {
        return Container(
          decoration: BoxDecoration(
            border: Border(
              right: BorderSide(
                color: Theme.of(context).dividerColor,
                width: 0.5,
              ),
            ),
            color: candidateData.isNotEmpty
                ? Theme.of(context)
                    .colorScheme
                    .primaryContainer
                    .withOpacity(0.3)
                : null,
          ),
          child: Column(
            children: [
              // Date header
              Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: isToday ? Theme.of(context).colorScheme.primary : null,
                  borderRadius: isToday ? BorderRadius.circular(8) : null,
                ),
                child: Center(
                  child: Text(
                    '${date.day}',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: isToday
                              ? Theme.of(context).colorScheme.onPrimary
                              : null,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ),
              ),

              // Activities
              Expanded(
                child: ListView.builder(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                  itemCount: activities.length,
                  itemBuilder: (context, index) {
                    final activity = activities[index];
                    return _buildActivityCard(activity, date);
                  },
                ),
              ),

              // Add activity button
              Padding(
                padding: const EdgeInsets.all(4),
                child: InkWell(
                  onTap: () => widget.onDayTap(date),
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    height: 32,
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: Theme.of(context).colorScheme.outline,
                        style: BorderStyle.solid,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.add,
                      size: 16,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildActivityCard(LessonActivity activity, DateTime date) {
    final isSelected = activity.id == widget.selectedActivityId;
    final isDragged = widget.draggedActivity?.id == activity.id;
    final color =
        Color(widget.colorScheme[activity.subject.toString()] ?? 0xFF6B73FF);

    return Draggable<LessonActivity>(
      data: activity,
      feedback: Material(
        elevation: 8,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: 200,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            activity.title,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
      childWhenDragging: Opacity(
        opacity: 0.3,
        child: _buildActivityCardContent(activity, color, isSelected),
      ),
      child: Visibility(
        visible: !isDragged,
        child: GestureDetector(
          onTap: () => widget.onActivityTap(activity),
          onLongPress: () => _showActivityContextMenu(context, activity),
          child: _buildActivityCardContent(activity, color, isSelected),
        ),
      ),
    );
  }

  Widget _buildActivityCardContent(
      LessonActivity activity, Color color, bool isSelected) {
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.9),
        borderRadius: BorderRadius.circular(6),
        border: isSelected
            ? Border.all(
                color: Theme.of(context).colorScheme.primary,
                width: 2,
              )
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            activity.title,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w500,
              fontSize: 12,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            '${activity.duration.inMinutes}min',
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  void _showActivityContextMenu(BuildContext context, LessonActivity activity) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('Edit Activity'),
              onTap: () {
                Navigator.of(context).pop();
                widget.onActivityEdit(activity);
              },
            ),
            ListTile(
              leading: const Icon(Icons.copy),
              title: const Text('Duplicate'),
              onTap: () {
                Navigator.of(context).pop();
                widget.onActivityDuplicate(activity);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('Delete', style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.of(context).pop();
                widget.onActivityDelete(activity);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDayView() {
    final today = widget.currentWeekStart;
    return _buildDetailedDayView(today);
  }

  Widget _buildDetailedDayView(DateTime date) {
    final dayPlan = _getDayPlan(date);
    final activities = dayPlan?.activities ?? [];

    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _formatDate(date),
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.builder(
              itemCount: activities.length,
              itemBuilder: (context, index) {
                final activity = activities[index];
                return Card(
                  child: ListTile(
                    leading: Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: Color(
                            widget.colorScheme[activity.subject.toString()] ??
                                0xFF6B73FF),
                        shape: BoxShape.circle,
                      ),
                    ),
                    title: Text(activity.title),
                    subtitle: Text(
                        '${activity.duration.inMinutes} minutes • ${_getSubjectName(activity.subject)}'),
                    trailing: PopupMenuButton(
                      itemBuilder: (context) => [
                        PopupMenuItem(
                          child: const Text('Edit'),
                          onTap: () => widget.onActivityEdit(activity),
                        ),
                        PopupMenuItem(
                          child: const Text('Duplicate'),
                          onTap: () => widget.onActivityDuplicate(activity),
                        ),
                        PopupMenuItem(
                          child: const Text('Delete'),
                          onTap: () => widget.onActivityDelete(activity),
                        ),
                      ],
                    ),
                    onTap: () => widget.onActivityTap(activity),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthView() {
    // Simplified month view - in a real app, you'd implement a full calendar
    return Container(
      padding: const EdgeInsets.all(16),
      child: const Center(
        child: Text('Month view coming soon...'),
      ),
    );
  }

  DayPlan? _getDayPlan(DateTime date) {
    if (widget.currentPlan == null) return null;

    try {
      return widget.currentPlan!.dayPlans.firstWhere(
        (dayPlan) => _isSameDay(dayPlan.date, date),
      );
    } catch (e) {
      return null;
    }
  }

  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return _isSameDay(date, now);
  }

  String _formatDate(DateTime date) {
    const monthNames = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December'
    ];
    const dayNames = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday'
    ];

    return '${dayNames[date.weekday - 1]}, ${monthNames[date.month - 1]} ${date.day}';
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
}
