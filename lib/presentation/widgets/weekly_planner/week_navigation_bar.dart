import 'package:flutter/material.dart';

class WeekNavigationBar extends StatefulWidget {
  final DateTime currentWeekStart;
  final Function(DateTime) onWeekChanged;

  const WeekNavigationBar({
    super.key,
    required this.currentWeekStart,
    required this.onWeekChanged,
  });

  @override
  State<WeekNavigationBar> createState() => _WeekNavigationBarState();
}

class _WeekNavigationBarState extends State<WeekNavigationBar> {
  late PageController _pageController;
  int _currentPageIndex = 50; // Start in the middle for infinite scroll

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _currentPageIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 80,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: PageView.builder(
        controller: _pageController,
        onPageChanged: (index) {
          _currentPageIndex = index;
          final weekOffset = index - 50;
          final newWeekStart =
              _getBaseWeekStart().add(Duration(days: weekOffset * 7));
          widget.onWeekChanged(newWeekStart);
        },
        itemBuilder: (context, index) {
          final weekOffset = index - 50;
          final weekStart =
              _getBaseWeekStart().add(Duration(days: weekOffset * 7));
          return _buildWeekItem(weekStart);
        },
      ),
    );
  }

  Widget _buildWeekItem(DateTime weekStart) {
    final isCurrentWeek = _isCurrentWeek(weekStart);
    final isSelected = _isSameWeek(weekStart, widget.currentWeekStart);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        children: List.generate(7, (index) {
          final date = weekStart.add(Duration(days: index));
          final isWeekday = index < 5; // Monday to Friday
          final isToday = _isToday(date);

          return Expanded(
            child: GestureDetector(
              onTap: isWeekday ? () => widget.onWeekChanged(weekStart) : null,
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 1),
                decoration: BoxDecoration(
                  color: _getDayColor(context, isSelected, isToday, isWeekday),
                  borderRadius: BorderRadius.circular(8),
                  border: isCurrentWeek && isToday
                      ? Border.all(
                          color: Theme.of(context).colorScheme.primary,
                          width: 2,
                        )
                      : null,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _getDayName(index),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: _getTextColor(
                                context, isSelected, isToday, isWeekday),
                            fontWeight: FontWeight.w500,
                          ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${date.day}',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            color: _getTextColor(
                                context, isSelected, isToday, isWeekday),
                            fontWeight:
                                isToday ? FontWeight.bold : FontWeight.w600,
                          ),
                    ),
                    if (isWeekday) ...[
                      const SizedBox(height: 2),
                      Container(
                        width: 4,
                        height: 4,
                        decoration: BoxDecoration(
                          color:
                              _getIndicatorColor(context, isSelected, isToday),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Color _getDayColor(
      BuildContext context, bool isSelected, bool isToday, bool isWeekday) {
    if (!isWeekday) {
      return Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3);
    }

    if (isSelected) {
      return Theme.of(context).colorScheme.primaryContainer;
    }

    if (isToday) {
      return Theme.of(context).colorScheme.primary.withOpacity(0.1);
    }

    return Colors.transparent;
  }

  Color _getTextColor(
      BuildContext context, bool isSelected, bool isToday, bool isWeekday) {
    if (!isWeekday) {
      return Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.5);
    }

    if (isSelected) {
      return Theme.of(context).colorScheme.onPrimaryContainer;
    }

    if (isToday) {
      return Theme.of(context).colorScheme.primary;
    }

    return Theme.of(context).colorScheme.onSurface;
  }

  Color _getIndicatorColor(
      BuildContext context, bool isSelected, bool isToday) {
    if (isSelected || isToday) {
      return Theme.of(context).colorScheme.primary;
    }

    return Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.3);
  }

  String _getDayName(int index) {
    const dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return dayNames[index];
  }

  DateTime _getBaseWeekStart() {
    final now = DateTime.now();
    final weekday = now.weekday;
    return now.subtract(Duration(days: weekday - 1));
  }

  bool _isCurrentWeek(DateTime weekStart) {
    final currentWeekStart = _getBaseWeekStart();
    return _isSameWeek(weekStart, currentWeekStart);
  }

  bool _isSameWeek(DateTime date1, DateTime date2) {
    final week1Start = _getWeekStart(date1);
    final week2Start = _getWeekStart(date2);
    return week1Start.isAtSameMomentAs(week2Start);
  }

  DateTime _getWeekStart(DateTime date) {
    final weekday = date.weekday;
    return DateTime(date.year, date.month, date.day - (weekday - 1));
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }
}
