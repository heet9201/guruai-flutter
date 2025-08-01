import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

/// Recent Activities Widget showing recent teaching activities
class RecentActivitiesWidget extends StatelessWidget {
  final String languageCode;
  final bool isDarkMode;

  const RecentActivitiesWidget({
    super.key,
    required this.languageCode,
    required this.isDarkMode,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildActivityItem(
          context,
          icon: Icons.auto_stories,
          title: _getStoryCreatedTitle(languageCode),
          subtitle: _getStoryCreatedSubtitle(languageCode),
          time: '2 ${_getHoursAgoLabel(languageCode)}',
          color: SahayakColors.ochre,
          isCompleted: true,
        ),
        const SizedBox(height: 12),
        _buildActivityItem(
          context,
          icon: Icons.assignment,
          title: _getWorksheetCreatedTitle(languageCode),
          subtitle: _getWorksheetCreatedSubtitle(languageCode),
          time: '4 ${_getHoursAgoLabel(languageCode)}',
          color: SahayakColors.deepTeal,
          isCompleted: true,
        ),
        const SizedBox(height: 12),
        _buildActivityItem(
          context,
          icon: Icons.quiz,
          title: _getQuizInProgressTitle(languageCode),
          subtitle: _getQuizInProgressSubtitle(languageCode),
          time: '30 ${_getMinutesAgoLabel(languageCode)}',
          color: SahayakColors.burntSienna,
          isCompleted: false,
        ),
        const SizedBox(height: 12),
        _buildActivityItem(
          context,
          icon: Icons.school,
          title: _getLessonPlanUpdatedTitle(languageCode),
          subtitle: _getLessonPlanUpdatedSubtitle(languageCode),
          time: '1 ${_getDayAgoLabel(languageCode)}',
          color: SahayakColors.forestGreen,
          isCompleted: true,
        ),
      ],
    );
  }

  Widget _buildActivityItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required String time,
    required Color color,
    required bool isCompleted,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDarkMode
            ? SahayakColors.darkSurface.withOpacity(0.5)
            : SahayakColors.lightSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDarkMode
              ? SahayakColors.chalkWhite.withOpacity(0.1)
              : SahayakColors.charcoal.withOpacity(0.1),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isDarkMode
                ? Colors.black.withOpacity(0.2)
                : SahayakColors.charcoal.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Activity icon with status indicator
          Stack(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(isDarkMode ? 0.2 : 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  size: 24,
                  color: color,
                ),
              ),
              if (isCompleted)
                Positioned(
                  right: 0,
                  top: 0,
                  child: Container(
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      color: SahayakColors.forestGreen,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isDarkMode
                            ? SahayakColors.darkSurface
                            : SahayakColors.lightSurface,
                        width: 2,
                      ),
                    ),
                    child: Icon(
                      Icons.check,
                      size: 10,
                      color: Colors.white,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 16),

          // Activity details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: isDarkMode
                            ? SahayakColors.chalkWhite
                            : SahayakColors.charcoal,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: isDarkMode
                            ? SahayakColors.chalkWhite.withOpacity(0.7)
                            : SahayakColors.charcoal.withOpacity(0.6),
                      ),
                ),
              ],
            ),
          ),

          // Time and status
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                time,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: isDarkMode
                          ? SahayakColors.chalkWhite.withOpacity(0.6)
                          : SahayakColors.charcoal.withOpacity(0.5),
                    ),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isCompleted
                      ? SahayakColors.forestGreen.withOpacity(0.1)
                      : SahayakColors.clayOrange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  isCompleted
                      ? _getCompletedLabel(languageCode)
                      : _getInProgressLabel(languageCode),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: isCompleted
                            ? SahayakColors.forestGreen
                            : SahayakColors.clayOrange,
                      ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Localization methods
  String _getStoryCreatedTitle(String languageCode) {
    switch (languageCode) {
      case 'hi':
        return 'गणित की कहानी बनाई';
      case 'mr':
        return 'गणिताची कथा तयार केली';
      default:
        return 'Math Story Created';
    }
  }

  String _getStoryCreatedSubtitle(String languageCode) {
    switch (languageCode) {
      case 'hi':
        return 'कक्षा 3 के लिए जोड़-घटाव';
      case 'mr':
        return 'वर्ग 3 साठी बेरीज-वजाबाकी';
      default:
        return 'Addition & Subtraction for Grade 3';
    }
  }

  String _getWorksheetCreatedTitle(String languageCode) {
    switch (languageCode) {
      case 'hi':
        return 'वर्कशीट तैयार की';
      case 'mr':
        return 'वर्कशीट तयार केली';
      default:
        return 'Worksheet Created';
    }
  }

  String _getWorksheetCreatedSubtitle(String languageCode) {
    switch (languageCode) {
      case 'hi':
        return 'अंग्रेजी व्याकरण अभ्यास';
      case 'mr':
        return 'इंग्रजी व्याकरण सराव';
      default:
        return 'English Grammar Practice';
    }
  }

  String _getQuizInProgressTitle(String languageCode) {
    switch (languageCode) {
      case 'hi':
        return 'प्रश्नोत्तरी तैयार हो रही';
      case 'mr':
        return 'प्रश्नमंजुषा तयार होत आहे';
      default:
        return 'Quiz In Progress';
    }
  }

  String _getQuizInProgressSubtitle(String languageCode) {
    switch (languageCode) {
      case 'hi':
        return 'विज्ञान - प्रकाश और ध्वनि';
      case 'mr':
        return 'विज्ञान - प्रकाश आणि ध्वनी';
      default:
        return 'Science - Light and Sound';
    }
  }

  String _getLessonPlanUpdatedTitle(String languageCode) {
    switch (languageCode) {
      case 'hi':
        return 'पाठ योजना अपडेट की';
      case 'mr':
        return 'धडा योजना अपडेट केली';
      default:
        return 'Lesson Plan Updated';
    }
  }

  String _getLessonPlanUpdatedSubtitle(String languageCode) {
    switch (languageCode) {
      case 'hi':
        return 'सामाजिक अध्ययन - अगले सप्ताह';
      case 'mr':
        return 'समाजशास्त्र - पुढील आठवडा';
      default:
        return 'Social Studies - Next Week';
    }
  }

  String _getHoursAgoLabel(String languageCode) {
    switch (languageCode) {
      case 'hi':
        return 'घंटे पहले';
      case 'mr':
        return 'तास आधी';
      default:
        return 'hours ago';
    }
  }

  String _getMinutesAgoLabel(String languageCode) {
    switch (languageCode) {
      case 'hi':
        return 'मिनट पहले';
      case 'mr':
        return 'मिनिट आधी';
      default:
        return 'minutes ago';
    }
  }

  String _getDayAgoLabel(String languageCode) {
    switch (languageCode) {
      case 'hi':
        return 'दिन पहले';
      case 'mr':
        return 'दिवस आधी';
      default:
        return 'day ago';
    }
  }

  String _getCompletedLabel(String languageCode) {
    switch (languageCode) {
      case 'hi':
        return 'पूर्ण';
      case 'mr':
        return 'पूर्ण';
      default:
        return 'Done';
    }
  }

  String _getInProgressLabel(String languageCode) {
    switch (languageCode) {
      case 'hi':
        return 'जारी';
      case 'mr':
        return 'सुरु';
      default:
        return 'Active';
    }
  }
}
