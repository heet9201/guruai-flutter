import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/responsive_layout.dart';

/// Quick Action Grid - Optimized for 3-tap workflow
class QuickActionGrid extends StatelessWidget {
  final String languageCode;
  final bool isDarkMode;
  final Animation<double> animation;

  const QuickActionGrid({
    super.key,
    required this.languageCode,
    required this.isDarkMode,
    required this.animation,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        return GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: ResponsiveLayout.isMobile(context) ? 2 : 3,
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          childAspectRatio: 1.1,
          children: [
            _buildActionCard(
              context: context,
              icon: Icons.auto_stories,
              title: _getCreateStoryTitle(languageCode),
              subtitle: _getCreateStorySubtitle(languageCode),
              color: SahayakColors.ochre,
              delay: 0,
              onTap: () => _createStory(context),
            ),
            _buildActionCard(
              context: context,
              icon: Icons.assignment,
              title: _getCreateWorksheetTitle(languageCode),
              subtitle: _getCreateWorksheetSubtitle(languageCode),
              color: SahayakColors.deepTeal,
              delay: 100,
              onTap: () => _createWorksheet(context),
            ),
            _buildActionCard(
              context: context,
              icon: Icons.quiz,
              title: _getQuickQuizTitle(languageCode),
              subtitle: _getQuickQuizSubtitle(languageCode),
              color: SahayakColors.burntSienna,
              delay: 200,
              onTap: () => _createQuiz(context),
            ),
            _buildActionCard(
              context: context,
              icon: Icons.school,
              title: _getLessonPlanTitle(languageCode),
              subtitle: _getLessonPlanSubtitle(languageCode),
              color: SahayakColors.forestGreen,
              delay: 300,
              onTap: () => _createLessonPlan(context),
            ),
            _buildActionCard(
              context: context,
              icon: Icons.chat,
              title: _getAskQuestionTitle(languageCode),
              subtitle: _getAskQuestionSubtitle(languageCode),
              color: SahayakColors.clayOrange,
              delay: 400,
              onTap: () => _askQuestion(context),
            ),
            _buildActionCard(
              context: context,
              icon: Icons.draw,
              title: _getVisualAidTitle(languageCode),
              subtitle: _getVisualAidSubtitle(languageCode),
              color: SahayakColors.deepTeal,
              delay: 500,
              onTap: () => _createVisualAid(context),
            ),
          ],
        );
      },
    );
  }

  Widget _buildActionCard({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required int delay,
    required VoidCallback onTap,
  }) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: animation.value),
      duration: Duration(milliseconds: 300 + delay),
      curve: Curves.easeOutBack,
      builder: (context, animValue, child) {
        // Ensure animValue is properly constrained to prevent opacity assertion errors
        final safeAnimValue = animValue.clamp(0.0, 1.0);
        return Transform.scale(
          scale: safeAnimValue,
          child: Transform.translate(
            offset: Offset(0, (1 - safeAnimValue) * 20),
            child: Opacity(
              opacity: safeAnimValue,
              child: Material(
                borderRadius: BorderRadius.circular(20),
                elevation: 0,
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: onTap,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          color.withOpacity(isDarkMode ? 0.15 : 0.1),
                          color.withOpacity(isDarkMode ? 0.1 : 0.05),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: color.withOpacity(0.3),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: isDarkMode
                              ? Colors.black.withOpacity(0.2)
                              : color.withOpacity(0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16), // Reduced padding
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min, // Use minimum space
                        children: [
                          Container(
                            padding:
                                const EdgeInsets.all(12), // Reduced padding
                            decoration: BoxDecoration(
                              color: color.withOpacity(0.2),
                              borderRadius:
                                  BorderRadius.circular(12), // Slightly smaller
                            ),
                            child: Icon(
                              icon,
                              size: 28, // Reduced icon size
                              color: color,
                            ),
                          ),
                          const SizedBox(height: 8), // Reduced spacing
                          Flexible(
                            // Make text flexible
                            child: Text(
                              title,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleSmall // Changed from titleMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: isDarkMode
                                        ? SahayakColors.chalkWhite
                                        : SahayakColors.charcoal,
                                  ),
                              textAlign: TextAlign.center,
                              maxLines: 2, // Allow max 2 lines
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(height: 2), // Reduced spacing
                          Flexible(
                            // Make subtitle flexible
                            child: Text(
                              subtitle,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    fontSize: 11, // Slightly smaller font
                                    color: isDarkMode
                                        ? SahayakColors.chalkWhite
                                            .withOpacity(0.7)
                                        : SahayakColors.charcoal
                                            .withOpacity(0.6),
                                  ),
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // Action handlers
  void _createStory(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_getCreatingStoryMessage(languageCode)),
        backgroundColor: SahayakColors.ochre,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _createWorksheet(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_getCreatingWorksheetMessage(languageCode)),
        backgroundColor: SahayakColors.deepTeal,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _createQuiz(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_getCreatingQuizMessage(languageCode)),
        backgroundColor: SahayakColors.burntSienna,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _createLessonPlan(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_getCreatingLessonPlanMessage(languageCode)),
        backgroundColor: SahayakColors.forestGreen,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _askQuestion(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_getOpeningChatMessage(languageCode)),
        backgroundColor: SahayakColors.clayOrange,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _createVisualAid(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_getCreatingVisualAidMessage(languageCode)),
        backgroundColor: SahayakColors.deepTeal,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // Localization methods
  String _getCreateStoryTitle(String languageCode) {
    switch (languageCode) {
      case 'hi':
        return 'कहानी बनाएं';
      case 'mr':
        return 'कथा तयार करा';
      default:
        return 'Create Story';
    }
  }

  String _getCreateStorySubtitle(String languageCode) {
    switch (languageCode) {
      case 'hi':
        return 'शिक्षाप्रद कहानी';
      case 'mr':
        return 'शैक्षणिक कथा';
      default:
        return 'Educational story';
    }
  }

  String _getCreateWorksheetTitle(String languageCode) {
    switch (languageCode) {
      case 'hi':
        return 'वर्कशीट बनाएं';
      case 'mr':
        return 'वर्कशीट तयार करा';
      default:
        return 'Create Worksheet';
    }
  }

  String _getCreateWorksheetSubtitle(String languageCode) {
    switch (languageCode) {
      case 'hi':
        return 'अभ्यास पत्रक';
      case 'mr':
        return 'सराव पत्रक';
      default:
        return 'Practice exercises';
    }
  }

  String _getQuickQuizTitle(String languageCode) {
    switch (languageCode) {
      case 'hi':
        return 'तुरंत प्रश्नोत्तरी';
      case 'mr':
        return 'त्वरित प्रश्नमंजुषा';
      default:
        return 'Quick Quiz';
    }
  }

  String _getQuickQuizSubtitle(String languageCode) {
    switch (languageCode) {
      case 'hi':
        return '5 मिनट में';
      case 'mr':
        return '5 मिनिटात';
      default:
        return 'In 5 minutes';
    }
  }

  String _getLessonPlanTitle(String languageCode) {
    switch (languageCode) {
      case 'hi':
        return 'पाठ योजना';
      case 'mr':
        return 'धडा योजना';
      default:
        return 'Lesson Plan';
    }
  }

  String _getLessonPlanSubtitle(String languageCode) {
    switch (languageCode) {
      case 'hi':
        return 'विस्तृत योजना';
      case 'mr':
        return 'तपशीलवार योजना';
      default:
        return 'Detailed plan';
    }
  }

  String _getAskQuestionTitle(String languageCode) {
    switch (languageCode) {
      case 'hi':
        return 'प्रश्न पूछें';
      case 'mr':
        return 'प्रश्न विचारा';
      default:
        return 'Ask Question';
    }
  }

  String _getAskQuestionSubtitle(String languageCode) {
    switch (languageCode) {
      case 'hi':
        return 'AI सहायक से';
      case 'mr':
        return 'AI सहाय्यकाकडून';
      default:
        return 'AI assistant';
    }
  }

  String _getVisualAidTitle(String languageCode) {
    switch (languageCode) {
      case 'hi':
        return 'दृश्य सहायता';
      case 'mr':
        return 'दृश्य साधन';
      default:
        return 'Visual Aid';
    }
  }

  String _getVisualAidSubtitle(String languageCode) {
    switch (languageCode) {
      case 'hi':
        return 'चित्र और आरेख';
      case 'mr':
        return 'चित्र आणि आकृती';
      default:
        return 'Images & diagrams';
    }
  }

  // Message methods
  String _getCreatingStoryMessage(String languageCode) {
    switch (languageCode) {
      case 'hi':
        return 'कहानी बनाई जा रही है...';
      case 'mr':
        return 'कथा तयार केली जात आहे...';
      default:
        return 'Creating story...';
    }
  }

  String _getCreatingWorksheetMessage(String languageCode) {
    switch (languageCode) {
      case 'hi':
        return 'वर्कशीट तैयार की जा रही है...';
      case 'mr':
        return 'वर्कशीट तयार केली जात आहे...';
      default:
        return 'Creating worksheet...';
    }
  }

  String _getCreatingQuizMessage(String languageCode) {
    switch (languageCode) {
      case 'hi':
        return 'प्रश्नोत्तरी तैयार की जा रही है...';
      case 'mr':
        return 'प्रश्नमंजुषा तयार केली जात आहे...';
      default:
        return 'Creating quiz...';
    }
  }

  String _getCreatingLessonPlanMessage(String languageCode) {
    switch (languageCode) {
      case 'hi':
        return 'पाठ योजना तैयार की जा रही है...';
      case 'mr':
        return 'धडा योजना तयार केली जात आहे...';
      default:
        return 'Creating lesson plan...';
    }
  }

  String _getOpeningChatMessage(String languageCode) {
    switch (languageCode) {
      case 'hi':
        return 'चैट खोली जा रही है...';
      case 'mr':
        return 'चॅट उघडली जात आहे...';
      default:
        return 'Opening chat...';
    }
  }

  String _getCreatingVisualAidMessage(String languageCode) {
    switch (languageCode) {
      case 'hi':
        return 'दृश्य सहायता बनाई जा रही है...';
      case 'mr':
        return 'दृश्य साधन तयार केले जात आहे...';
      default:
        return 'Creating visual aid...';
    }
  }
}
