import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/theme/responsive_layout.dart';
import '../bloc/app_bloc.dart';
import '../bloc/app_state.dart';
import '../utils/app_navigator.dart';
import '../widgets/enhanced_instant_assist_fab_v2.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool _isLoading = false;
  final PageController _recommendationsController = PageController();

  @override
  void dispose() {
    _recommendationsController.dispose();
    super.dispose();
  }

  Future<void> _onRefresh() async {
    setState(() {
      _isLoading = true;
    });

    // Simulate refresh delay
    await Future.delayed(const Duration(seconds: 2));

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AppBloc, AppState>(
      builder: (context, state) {
        final languageCode = state is AppLoaded ? state.languageCode : 'en';

        return Scaffold(
          body: SafeArea(
            child: RefreshIndicator(
              onRefresh: _onRefresh,
              child: CustomScrollView(
                slivers: [
                  // Header Section
                  SliverToBoxAdapter(
                    child: _buildHeader(context, languageCode),
                  ),

                  // My Classes Section
                  SliverToBoxAdapter(
                    child: _buildMyClassesSection(context, languageCode),
                  ),

                  // Today's Recommendations Carousel
                  SliverToBoxAdapter(
                    child: _buildRecommendationsSection(context, languageCode),
                  ),

                  // Quick Stats Section
                  SliverToBoxAdapter(
                    child: _buildQuickStatsSection(context, languageCode),
                  ),

                  // Notifications Panel
                  SliverToBoxAdapter(
                    child: _buildNotificationsSection(context, languageCode),
                  ),

                  // Bottom padding
                  const SliverToBoxAdapter(
                    child: SizedBox(height: 100),
                  ),
                ],
              ),
            ),
          ),
          // Enhanced Instant Assist FAB
          floatingActionButton: EnhancedInstantAssistFAB(
            languageCode: languageCode,
            isOnline: true, // You can add connectivity detection here
          ),
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context, String languageCode) {
    final now = DateTime.now();
    final greeting = _getTimeBasedGreeting(languageCode);
    final teacherName = _getTeacherName(languageCode);
    final dateStr = _formatDate(now, languageCode);

    return Container(
      padding: EdgeInsets.all(ResponsiveLayout.getHorizontalPadding(context)),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Theme.of(context).colorScheme.primary.withOpacity(0.1),
            Theme.of(context).colorScheme.tertiary.withOpacity(0.05),
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      greeting,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      teacherName,
                      style:
                          Theme.of(context).textTheme.headlineMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.calendar_today,
                          size: 16,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          dateStr,
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant,
                                  ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              CircleAvatar(
                radius: 28,
                backgroundColor: Theme.of(context).colorScheme.primary,
                child: Icon(
                  Icons.person,
                  color: Theme.of(context).colorScheme.onPrimary,
                  size: 32,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildMyClassesSection(BuildContext context, String languageCode) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: ResponsiveLayout.getHorizontalPadding(context),
        vertical: 16,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _getMyClassesTitle(languageCode),
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 16),
          if (_isLoading)
            _buildLoadingState()
          else
            Column(
              children: [
                _buildClassCard(context, languageCode, 'Grade 3', 42, 0.75, 28),
                const SizedBox(height: 12),
                _buildClassCard(context, languageCode, 'Grade 4', 38, 0.60, 32),
                const SizedBox(height: 12),
                _buildClassCard(context, languageCode, 'Grade 5', 45, 0.85, 24),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildClassCard(BuildContext context, String languageCode,
      String grade, int studentCount, double progress, int recentActivity) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      grade,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _getStudentCountText(languageCode, studentCount),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    ),
                  ],
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color:
                        Theme.of(context).colorScheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _getRecentActivityText(languageCode, recentActivity),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.w500,
                        ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Progress Section
            Text(
              _getProgressTitle(languageCode),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: progress,
              backgroundColor:
                  Theme.of(context).colorScheme.surfaceContainerHighest,
              valueColor: AlwaysStoppedAnimation<Color>(
                Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${(progress * 100).toInt()}% ${_getCompleteText(languageCode)}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),

            const SizedBox(height: 16),

            // Quick Action Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _onGenerateStory(grade),
                    icon: const Icon(Icons.auto_stories, size: 16),
                    label: Text(_getGenerateStoryText(languageCode)),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _onAskQuestion(grade),
                    icon: const Icon(Icons.help_outline, size: 16),
                    label: Text(_getAskQuestionText(languageCode)),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecommendationsSection(
      BuildContext context, String languageCode) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: ResponsiveLayout.getHorizontalPadding(context),
            ),
            child: Text(
              _getTodaysRecommendationsTitle(languageCode),
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 160,
            child: PageView.builder(
              controller: _recommendationsController,
              padEnds: false,
              itemCount: _getRecommendations(languageCode).length,
              itemBuilder: (context, index) {
                final recommendation = _getRecommendations(languageCode)[index];
                return Container(
                  margin: EdgeInsets.only(
                    left: index == 0
                        ? ResponsiveLayout.getHorizontalPadding(context)
                        : 8,
                    right: index == _getRecommendations(languageCode).length - 1
                        ? ResponsiveLayout.getHorizontalPadding(context)
                        : 8,
                  ),
                  width: 280,
                  child: _buildRecommendationCard(context, recommendation),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendationCard(
      BuildContext context, Map<String, dynamic> recommendation) {
    return Card(
      elevation: 3,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              (recommendation['color'] as Color).withOpacity(0.1),
              (recommendation['color'] as Color).withOpacity(0.05),
            ],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    recommendation['icon'],
                    color: recommendation['color'],
                    size: 24,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      recommendation['title'],
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                recommendation['description'],
                style: Theme.of(context).textTheme.bodyMedium,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              const Spacer(),
              ElevatedButton(
                onPressed: () => _onRecommendationTap(recommendation),
                style: ElevatedButton.styleFrom(
                  backgroundColor: recommendation['color'],
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 32),
                ),
                child: Text(recommendation['actionText']),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickStatsSection(BuildContext context, String languageCode) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: ResponsiveLayout.getHorizontalPadding(context),
        vertical: 16,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _getQuickStatsTitle(languageCode),
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 16),
          ResponsiveLayout.buildResponsiveGrid(
            context: context,
            children: [
              _buildStatCard(
                context,
                Icons.auto_stories,
                '47',
                _getContentCreatedLabel(languageCode),
                Theme.of(context).colorScheme.primary,
              ),
              _buildStatCard(
                context,
                Icons.quiz,
                '23',
                _getQuizzesLabel(languageCode),
                Theme.of(context).colorScheme.secondary,
              ),
              _buildStatCard(
                context,
                Icons.chat,
                '156',
                _getQuestionsLabel(languageCode),
                Theme.of(context).colorScheme.tertiary,
              ),
              _buildStatCard(
                context,
                Icons.favorite,
                _getMostUsedFeature(languageCode),
                _getMostUsedLabel(languageCode),
                Colors.pink,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(BuildContext context, IconData icon, String value,
      String label, Color color) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: color,
              size: 32,
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationsSection(BuildContext context, String languageCode) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: ResponsiveLayout.getHorizontalPadding(context),
        vertical: 16,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _getNotificationsTitle(languageCode),
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 16),
          ..._getNotifications(languageCode).map(
              (notification) => _buildNotificationCard(context, notification)),
        ],
      ),
    );
  }

  Widget _buildNotificationCard(
      BuildContext context, Map<String, dynamic> notification) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: (notification['color'] as Color).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            notification['icon'],
            color: notification['color'],
          ),
        ),
        title: Text(
          notification['title'],
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(notification['message']),
            const SizedBox(height: 4),
            Text(
              notification['time'],
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ],
        ),
        trailing: notification['isNew']
            ? Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  shape: BoxShape.circle,
                ),
              )
            : null,
        onTap: () => _onNotificationTap(notification),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Column(
      children: List.generate(
          3,
          (index) => Container(
                margin: const EdgeInsets.only(bottom: 12),
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 60,
                              height: 20,
                              decoration: BoxDecoration(
                                color: Theme.of(context)
                                    .colorScheme
                                    .surfaceContainerHighest,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                            const Spacer(),
                            Container(
                              width: 80,
                              height: 16,
                              decoration: BoxDecoration(
                                color: Theme.of(context)
                                    .colorScheme
                                    .surfaceContainerHighest,
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Container(
                          width: double.infinity,
                          height: 4,
                          decoration: BoxDecoration(
                            color: Theme.of(context)
                                .colorScheme
                                .surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: Container(
                                height: 32,
                                decoration: BoxDecoration(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .surfaceContainerHighest,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Container(
                                height: 32,
                                decoration: BoxDecoration(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .surfaceContainerHighest,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              )),
    );
  }

  // Action handlers
  void _onGenerateStory(String grade) {
    // Navigate to content creation with story preset for specific grade
    print('Generate story for $grade');
  }

  void _onAskQuestion(String grade) {
    // Navigate to Q&A with grade context
    print('Ask question for $grade');
  }

  void _onRecommendationTap(Map<String, dynamic> recommendation) {
    // Handle recommendation action
    AppNavigator.navigateToRecommendation(context, recommendation);
  }

  void _onNotificationTap(Map<String, dynamic> notification) {
    // Handle notification tap
    print('Notification tapped: ${notification['title']}');
  }

  // Helper methods for localization and data
  String _getTimeBasedGreeting(String languageCode) {
    final hour = DateTime.now().hour;
    switch (languageCode) {
      case 'hi':
        if (hour < 12) return 'सुप्रभात';
        if (hour < 17) return 'नमस्कार';
        return 'शुभ संध्या';
      case 'mr':
        if (hour < 12) return 'सुप्रभात';
        if (hour < 17) return 'नमस्कार';
        return 'शुभ संध्या';
      case 'ta':
        if (hour < 12) return 'காலை வணக்கம்';
        if (hour < 17) return 'வணக்கம்';
        return 'மாலை வணக்கம்';
      case 'te':
        if (hour < 12) return 'శుభోదయం';
        if (hour < 17) return 'నమస్కారం';
        return 'శుభ సాయంత్రం';
      default:
        if (hour < 12) return 'Good morning';
        if (hour < 17) return 'Good afternoon';
        return 'Good evening';
    }
  }

  String _getTeacherName(String languageCode) {
    switch (languageCode) {
      case 'hi':
        return 'प्रिया शर्मा जी';
      case 'mr':
        return 'प्रिया शर्मा जी';
      case 'ta':
        return 'பிரியா ஷர்மா அம்மா';
      case 'te':
        return 'ప్రియా శర్మ గారు';
      default:
        return 'Teacher Priya';
    }
  }

  String _formatDate(DateTime date, String languageCode) {
    switch (languageCode) {
      case 'hi':
        return '${date.day} ${_getHindiMonth(date.month)} ${date.year}';
      case 'mr':
        return '${date.day} ${_getMarathiMonth(date.month)} ${date.year}';
      case 'ta':
        return '${date.day} ${_getTamilMonth(date.month)} ${date.year}';
      case 'te':
        return '${date.day} ${_getTeluguMonth(date.month)} ${date.year}';
      default:
        final months = [
          'Jan',
          'Feb',
          'Mar',
          'Apr',
          'May',
          'Jun',
          'Jul',
          'Aug',
          'Sep',
          'Oct',
          'Nov',
          'Dec'
        ];
        return '${months[date.month - 1]} ${date.day}, ${date.year}';
    }
  }

  String _getHindiMonth(int month) {
    const months = [
      'जनवरी',
      'फरवरी',
      'मार्च',
      'अप्रैल',
      'मई',
      'जून',
      'जुलाई',
      'अगस्त',
      'सितंबर',
      'अक्टूबर',
      'नवंबर',
      'दिसंबर'
    ];
    return months[month - 1];
  }

  String _getMarathiMonth(int month) {
    const months = [
      'जानेवारी',
      'फेब्रुवारी',
      'मार्च',
      'एप्रिल',
      'मे',
      'जून',
      'जुलै',
      'ऑगस्ट',
      'सप्टेंबर',
      'ऑक्टोबर',
      'नोव्हेंबर',
      'डिसेंबर'
    ];
    return months[month - 1];
  }

  String _getTamilMonth(int month) {
    const months = [
      'ஜனவரி',
      'பிப்ரவரி',
      'மார்ச்',
      'ஏப்ரல்',
      'மே',
      'ஜூன்',
      'ஜூலை',
      'ஆகஸ்ட்',
      'செப்டம்பர்',
      'அக்டோபர்',
      'நவம்பர்',
      'டிசம்பர்'
    ];
    return months[month - 1];
  }

  String _getTeluguMonth(int month) {
    const months = [
      'జనవరి',
      'ఫిబ్రవరి',
      'మార్చి',
      'ఏప్రిల్',
      'మే',
      'జూన్',
      'జులై',
      'ఆగస్టు',
      'సెప్టెంబర్',
      'అక్టోబర్',
      'నవంబర్',
      'డిసంబర్'
    ];
    return months[month - 1];
  }

  String _getMyClassesTitle(String languageCode) {
    switch (languageCode) {
      case 'hi':
        return 'मेरी कक्षाएं';
      case 'mr':
        return 'माझे वर्ग';
      case 'ta':
        return 'எனது வகுப்புகள்';
      case 'te':
        return 'నా తరగతులు';
      default:
        return 'My Classes';
    }
  }

  String _getStudentCountText(String languageCode, int count) {
    switch (languageCode) {
      case 'hi':
        return '$count छात्र';
      case 'mr':
        return '$count विद्यार्थी';
      case 'ta':
        return '$count மாணவர்கள்';
      case 'te':
        return '$count విద్యార్థులు';
      default:
        return '$count students';
    }
  }

  String _getRecentActivityText(String languageCode, int count) {
    switch (languageCode) {
      case 'hi':
        return '$count नई गतिविधि';
      case 'mr':
        return '$count नवीन क्रियाकलाप';
      case 'ta':
        return '$count புதிய செயல்பாடு';
      case 'te':
        return '$count కొత్త కార్యకలాపం';
      default:
        return '$count new activities';
    }
  }

  String _getProgressTitle(String languageCode) {
    switch (languageCode) {
      case 'hi':
        return 'पाठ्यक्रम प्रगति';
      case 'mr':
        return 'अभ्यासक्रम प्रगती';
      case 'ta':
        return 'பாடநெறி முன்னேற்றம்';
      case 'te':
        return 'పాఠ్యాంశ పురోగతి';
      default:
        return 'Course Progress';
    }
  }

  String _getCompleteText(String languageCode) {
    switch (languageCode) {
      case 'hi':
        return 'पूर्ण';
      case 'mr':
        return 'पूर्ण';
      case 'ta':
        return 'முடிந்தது';
      case 'te':
        return 'పూర్తయింది';
      default:
        return 'complete';
    }
  }

  String _getGenerateStoryText(String languageCode) {
    switch (languageCode) {
      case 'hi':
        return 'कहानी बनाएं';
      case 'mr':
        return 'कथा तयार करा';
      case 'ta':
        return 'கதை உருவாக்கு';
      case 'te':
        return 'కథ రూపొందించు';
      default:
        return 'Generate Story';
    }
  }

  String _getAskQuestionText(String languageCode) {
    switch (languageCode) {
      case 'hi':
        return 'प्रश्न पूछें';
      case 'mr':
        return 'प्रश्न विचारा';
      case 'ta':
        return 'கேள்வி கேள்';
      case 'te':
        return 'ప్రశ్న అడుగు';
      default:
        return 'Ask Question';
    }
  }

  String _getTodaysRecommendationsTitle(String languageCode) {
    switch (languageCode) {
      case 'hi':
        return 'आज की सिफारिशें';
      case 'mr':
        return 'आजच्या शिफारशी';
      case 'ta':
        return 'இன்றைய பரிந்துரைகள்';
      case 'te':
        return 'నేటి సిఫార్సులు';
      default:
        return "Today's Recommendations";
    }
  }

  List<Map<String, dynamic>> _getRecommendations(String languageCode) {
    return [
      {
        'icon': Icons.auto_stories,
        'title': languageCode == 'hi'
            ? 'दिवाली की कहानी'
            : languageCode == 'mr'
                ? 'दिवाळीची कथा'
                : languageCode == 'ta'
                    ? 'தீபாவளி கதை'
                    : languageCode == 'te'
                        ? 'దీపావళి కథ'
                        : 'Diwali Story',
        'description': languageCode == 'hi'
            ? 'त्योहार के लिए एक रोचक कहानी बनाएं'
            : languageCode == 'mr'
                ? 'सणासाठी एक मनोरंजक कथा तयार करा'
                : languageCode == 'ta'
                    ? 'பண்டிகைக்கான ஒரு சுவாரஸ்யமான கதை உருவாக்குங்கள்'
                    : languageCode == 'te'
                        ? 'పండుగ కోసం ఒక ఆసక్తికరమైన కథ రూపొందించండి'
                        : 'Create an engaging story for the festival',
        'actionText': languageCode == 'hi'
            ? 'बनाएं'
            : languageCode == 'mr'
                ? 'तयार करा'
                : languageCode == 'ta'
                    ? 'உருவாக்கு'
                    : languageCode == 'te'
                        ? 'రూపొందించు'
                        : 'Create',
        'color': Colors.orange,
      },
      {
        'icon': Icons.quiz,
        'title': languageCode == 'hi'
            ? 'गणित की प्रैक्टिस'
            : languageCode == 'mr'
                ? 'गणिताचा सराव'
                : languageCode == 'ta'
                    ? 'கணித பயிற்சி'
                    : languageCode == 'te'
                        ? 'గణిత అభ్యాసం'
                        : 'Math Practice',
        'description': languageCode == 'hi'
            ? 'ग्रेड 4 के लिए भिन्न संख्याओं की क्विज़'
            : languageCode == 'mr'
                ? 'इयत्ता ४ साठी भिन्न संख्यांची प्रश्नमंजुषा'
                : languageCode == 'ta'
                    ? 'வகுப்பு 4 க்கான பின்னங்கள் வினாடி வினா'
                    : languageCode == 'te'
                        ? 'తరగతి 4 కోసం భిన్నాల క్విజ్'
                        : 'Fractions quiz for Grade 4',
        'actionText': languageCode == 'hi'
            ? 'शुरू करें'
            : languageCode == 'mr'
                ? 'सुरू करा'
                : languageCode == 'ta'
                    ? 'தொடங்கு'
                    : languageCode == 'te'
                        ? 'ప్రారంభించు'
                        : 'Start',
        'color': Colors.blue,
      },
      {
        'icon': Icons.science,
        'title': languageCode == 'hi'
            ? 'प्रकाश और छाया'
            : languageCode == 'mr'
                ? 'प्रकाश आणि सावली'
                : languageCode == 'ta'
                    ? 'ஒளி மற்றும் நிழல்'
                    : languageCode == 'te'
                        ? 'కాంతి మరియు నీడ'
                        : 'Light and Shadow',
        'description': languageCode == 'hi'
            ? 'विज्ञान की इंटरैक्टिव गतिविधि'
            : languageCode == 'mr'
                ? 'विज्ञानाची परस्परसंवादी क्रियाकलाप'
                : languageCode == 'ta'
                    ? 'அறிவியல் ஊடாடும் செயல்பாடு'
                    : languageCode == 'te'
                        ? 'సైన్స్ ఇంటరాక్టివ్ కార్యకలాపం'
                        : 'Interactive science activity',
        'actionText': languageCode == 'hi'
            ? 'खोजें'
            : languageCode == 'mr'
                ? 'शोधा'
                : languageCode == 'ta'
                    ? 'ஆராய்'
                    : languageCode == 'te'
                        ? 'అన్వేషించు'
                        : 'Explore',
        'color': Colors.green,
      },
    ];
  }

  String _getQuickStatsTitle(String languageCode) {
    switch (languageCode) {
      case 'hi':
        return 'त्वरित आंकड़े';
      case 'mr':
        return 'त्वरित आकडेवारी';
      case 'ta':
        return 'விரைவு புள்ளிவிவரங்கள்';
      case 'te':
        return 'శీఘ్ర గణాంకాలు';
      default:
        return 'Quick Stats';
    }
  }

  String _getContentCreatedLabel(String languageCode) {
    switch (languageCode) {
      case 'hi':
        return 'सामग्री बनाई';
      case 'mr':
        return 'सामग्री तयार केली';
      case 'ta':
        return 'உள்ளடக்கம் உருவாக்கப்பட்டது';
      case 'te':
        return 'కంటెంట్ రూపొందించబడింది';
      default:
        return 'Content Created';
    }
  }

  String _getQuizzesLabel(String languageCode) {
    switch (languageCode) {
      case 'hi':
        return 'क्विज़ बनाए';
      case 'mr':
        return 'प्रश्नमंजुषा तयार केल्या';
      case 'ta':
        return 'வினாடி வினாக்கள் உருவாக்கப்பட்டன';
      case 'te':
        return 'క్విజ్‌లు రూపొందించబడ్డాయి';
      default:
        return 'Quizzes Created';
    }
  }

  String _getQuestionsLabel(String languageCode) {
    switch (languageCode) {
      case 'hi':
        return 'प्रश्न पूछे';
      case 'mr':
        return 'प्रश्न विचारले';
      case 'ta':
        return 'கேள்விகள் கேட்கப்பட்டன';
      case 'te':
        return 'ప్రశ్నలు అడిగారు';
      default:
        return 'Questions Asked';
    }
  }

  String _getMostUsedFeature(String languageCode) {
    switch (languageCode) {
      case 'hi':
        return 'कहानी';
      case 'mr':
        return 'कथा';
      case 'ta':
        return 'கதை';
      case 'te':
        return 'కథ';
      default:
        return 'Story';
    }
  }

  String _getMostUsedLabel(String languageCode) {
    switch (languageCode) {
      case 'hi':
        return 'सबसे ज्यादा उपयोग';
      case 'mr':
        return 'सर्वाधिक वापर';
      case 'ta':
        return 'அதிகம் பயன்படுத்தப்பட்டது';
      case 'te':
        return 'ఎక్కువగా ఉపయోగించబడింది';
      default:
        return 'Most Used Feature';
    }
  }

  String _getNotificationsTitle(String languageCode) {
    switch (languageCode) {
      case 'hi':
        return 'सूचनाएं';
      case 'mr':
        return 'सूचना';
      case 'ta':
        return 'அறிவிப்புகள்';
      case 'te':
        return 'నోటిఫికేషన్లు';
      default:
        return 'Notifications';
    }
  }

  List<Map<String, dynamic>> _getNotifications(String languageCode) {
    return [
      {
        'icon': Icons.auto_awesome,
        'title': languageCode == 'hi'
            ? 'AI अपडेट'
            : languageCode == 'mr'
                ? 'AI अपडेट'
                : languageCode == 'ta'
                    ? 'AI புதுப்பிப்பு'
                    : languageCode == 'te'
                        ? 'AI అప్‌డేట్'
                        : 'AI Update',
        'message': languageCode == 'hi'
            ? 'नई कहानी जेनरेशन सुविधा उपलब्ध है'
            : languageCode == 'mr'
                ? 'नवीन कथा निर्मिती सुविधा उपलब्ध आहे'
                : languageCode == 'ta'
                    ? 'புதிய கதை உருவாக்கும் அம்சம் கிடைக்கிறது'
                    : languageCode == 'te'
                        ? 'కొత్త కథ రూపొందింపు ఫీచర్ అందుబాటులో ఉంది'
                        : 'New story generation feature available',
        'time': '2m ago',
        'isNew': true,
        'color': Colors.purple,
      },
      {
        'icon': Icons.drafts,
        'title': languageCode == 'hi'
            ? 'सहेजा गया ड्राफ्ट'
            : languageCode == 'mr'
                ? 'साठवलेला मसुदा'
                : languageCode == 'ta'
                    ? 'சேமிக்கப்பட்ட வரைவு'
                    : languageCode == 'te'
                        ? 'సేవ్ చేసిన డ్రాఫ్ట్'
                        : 'Saved Draft',
        'message': languageCode == 'hi'
            ? '\"गणित की पहेली\" लेसन प्लान तैयार है'
            : languageCode == 'mr'
                ? '\"गणिताची कोडी\" धडा योजना तयार आहे'
                : languageCode == 'ta'
                    ? '\"கணித புதிர்\" பாட திட்டம் தயார்'
                    : languageCode == 'te'
                        ? '\"గణిత పజిల్\" పాఠ ప్రణాళిక సిద్ధం'
                        : '"Math Puzzle" lesson plan ready',
        'time': '1h ago',
        'isNew': false,
        'color': Colors.orange,
      },
      {
        'icon': Icons.announcement,
        'title': languageCode == 'hi'
            ? 'सिस्टम अपडेट'
            : languageCode == 'mr'
                ? 'सिस्टम अपडेट'
                : languageCode == 'ta'
                    ? 'அமைப்பு புதுப்பிப்பு'
                    : languageCode == 'te'
                        ? 'సిస్టమ్ అప్‌డేట్'
                        : 'System Update',
        'message': languageCode == 'hi'
            ? 'ऐप का नया वर्जन उपलब्ध है'
            : languageCode == 'mr'
                ? 'अॅपची नवीन आवृत्ती उपलब्ध आहे'
                : languageCode == 'ta'
                    ? 'ஆப்பின் புதிய பதிப்பு கிடைக்கிறது'
                    : languageCode == 'te'
                        ? 'యాప్ యొక్క కొత్త వెర్షన్ అందుబాటులో ఉంది'
                        : 'New app version available',
        'time': '3h ago',
        'isNew': false,
        'color': Colors.blue,
      },
    ];
  }
}
