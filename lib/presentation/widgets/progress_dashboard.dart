import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

/// Progress Dashboard showing today's teaching activities and progress
class ProgressDashboard extends StatelessWidget {
  final String languageCode;
  final bool isDarkMode;

  const ProgressDashboard({
    super.key,
    required this.languageCode,
    required this.isDarkMode,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDarkMode
              ? [
                  SahayakColors.darkSurface,
                  SahayakColors.darkSurface.withOpacity(0.8),
                ]
              : [
                  SahayakColors.warmIvory,
                  SahayakColors.lightSurface,
                ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: isDarkMode
                ? Colors.black.withOpacity(0.2)
                : SahayakColors.charcoal.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.timeline,
                color: SahayakColors.deepTeal,
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                _getTodayProgressTitle(languageCode),
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: isDarkMode
                          ? SahayakColors.chalkWhite
                          : SahayakColors.charcoal,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Progress items
          _buildProgressItem(
            context,
            icon: Icons.schedule,
            title: _getScheduledClassesTitle(languageCode),
            completed: 3,
            total: 5,
            color: SahayakColors.ochre,
          ),
          const SizedBox(height: 16),

          _buildProgressItem(
            context,
            icon: Icons.assignment_turned_in,
            title: _getAssignmentsCheckedTitle(languageCode),
            completed: 8,
            total: 12,
            color: SahayakColors.forestGreen,
          ),
          const SizedBox(height: 16),

          _buildProgressItem(
            context,
            icon: Icons.quiz,
            title: _getQuizzesCreatedTitle(languageCode),
            completed: 2,
            total: 3,
            color: SahayakColors.burntSienna,
          ),
          const SizedBox(height: 20),

          // Weekly overview
          _buildWeeklyOverview(context),
        ],
      ),
    );
  }

  Widget _buildProgressItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required int completed,
    required int total,
    required Color color,
  }) {
    final progress = completed / total;

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            size: 20,
            color: color,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                          color: isDarkMode
                              ? SahayakColors.chalkWhite
                              : SahayakColors.charcoal,
                        ),
                  ),
                  Text(
                    '$completed/$total',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: color,
                        ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progress,
                  backgroundColor: isDarkMode
                      ? SahayakColors.charcoal.withOpacity(0.3)
                      : color.withOpacity(0.2),
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                  minHeight: 6,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildWeeklyOverview(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: SahayakColors.deepTeal.withOpacity(isDarkMode ? 0.15 : 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: SahayakColors.deepTeal.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: SahayakColors.deepTeal.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.trending_up,
              size: 20,
              color: SahayakColors.deepTeal,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _getWeeklyOverviewTitle(languageCode),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: isDarkMode
                            ? SahayakColors.chalkWhite
                            : SahayakColors.charcoal,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  _getWeeklyProgressMessage(languageCode),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: isDarkMode
                            ? SahayakColors.chalkWhite.withOpacity(0.8)
                            : SahayakColors.charcoal.withOpacity(0.7),
                      ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: SahayakColors.deepTeal,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '89%',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
            ),
          ),
        ],
      ),
    );
  }

  // Localization methods
  String _getTodayProgressTitle(String languageCode) {
    switch (languageCode) {
      case 'hi':
        return 'आज की प्रगति';
      case 'mr':
        return 'आजची प्रगती';
      default:
        return 'Today\'s Progress';
    }
  }

  String _getScheduledClassesTitle(String languageCode) {
    switch (languageCode) {
      case 'hi':
        return 'निर्धारित कक्षाएं';
      case 'mr':
        return 'निर्धारित वर्ग';
      default:
        return 'Scheduled Classes';
    }
  }

  String _getAssignmentsCheckedTitle(String languageCode) {
    switch (languageCode) {
      case 'hi':
        return 'जांचे गए कार्य';
      case 'mr':
        return 'तपासलेली कामे';
      default:
        return 'Assignments Checked';
    }
  }

  String _getQuizzesCreatedTitle(String languageCode) {
    switch (languageCode) {
      case 'hi':
        return 'बनाए गए प्रश्नोत्तरी';
      case 'mr':
        return 'तयार केलेली प्रश्नमंजुषा';
      default:
        return 'Quizzes Created';
    }
  }

  String _getWeeklyOverviewTitle(String languageCode) {
    switch (languageCode) {
      case 'hi':
        return 'साप्ताहिक अवलोकन';
      case 'mr':
        return 'साप्ताहिक अवलोकन';
      default:
        return 'Weekly Overview';
    }
  }

  String _getWeeklyProgressMessage(String languageCode) {
    switch (languageCode) {
      case 'hi':
        return 'आपकी साप्ताहिक लक्ष्य की प्रगति';
      case 'mr':
        return 'तुमच्या साप्ताहिक लक्ष्याची प्रगती';
      default:
        return 'Your weekly goals progress';
    }
  }
}
