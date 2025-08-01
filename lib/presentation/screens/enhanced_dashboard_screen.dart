import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/theme/responsive_layout.dart';
import '../../core/theme/app_colors.dart';
import '../bloc/app_bloc.dart';
import '../bloc/app_state.dart';
import '../widgets/enhanced_cards.dart';
import '../widgets/quick_action_grid.dart';
import '../widgets/recent_activities_widget.dart';
import '../widgets/progress_dashboard.dart';

/// Enhanced Dashboard Screen with warm earth tones and teacher-centric design
class EnhancedDashboardScreen extends StatefulWidget {
  const EnhancedDashboardScreen({super.key});

  @override
  State<EnhancedDashboardScreen> createState() =>
      _EnhancedDashboardScreenState();
}

class _EnhancedDashboardScreenState extends State<EnhancedDashboardScreen>
    with TickerProviderStateMixin {
  bool _isLoading = false;
  late AnimationController _welcomeAnimationController;
  late AnimationController _cardsAnimationController;
  late Animation<double> _welcomeSlideAnimation;
  late Animation<double> _cardsStaggerAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
  }

  void _initializeAnimations() {
    _welcomeAnimationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _cardsAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _welcomeSlideAnimation = Tween<double>(
      begin: -50.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _welcomeAnimationController,
      curve: Curves.easeOutCubic,
    ));

    _cardsStaggerAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _cardsAnimationController,
      curve: Curves.easeOutBack,
    ));

    // Start animations
    _welcomeAnimationController.forward();
    Future.delayed(const Duration(milliseconds: 300), () {
      _cardsAnimationController.forward();
    });
  }

  @override
  void dispose() {
    _welcomeAnimationController.dispose();
    _cardsAnimationController.dispose();
    super.dispose();
  }

  Future<void> _onRefresh() async {
    setState(() {
      _isLoading = true;
    });

    // Simulate refresh with gentle loading
    await Future.delayed(const Duration(milliseconds: 1500));

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
        final isDarkMode = state is AppLoaded ? state.isDarkMode : false;

        return Scaffold(
          backgroundColor: isDarkMode
              ? SahayakColors.darkBackground
              : SahayakColors.lightBackground,
          body: SafeArea(
            child: RefreshIndicator(
              onRefresh: _onRefresh,
              color: SahayakColors.deepTeal,
              backgroundColor: isDarkMode
                  ? SahayakColors.darkSurface
                  : SahayakColors.lightSurface,
              child: CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  // Custom App Bar with gentle animations
                  _buildAnimatedAppBar(context, languageCode, isDarkMode),

                  // Welcome section with teacher greeting
                  _buildWelcomeSection(context, languageCode, isDarkMode),

                  // Today's overview with quick stats
                  _buildTodayOverview(context, languageCode, isDarkMode),

                  // Quick actions grid - 3 taps or less workflow
                  _buildQuickActionsGrid(context, languageCode, isDarkMode),

                  // Recent activities with progress
                  _buildRecentActivities(context, languageCode, isDarkMode),

                  // Insights and recommendations
                  _buildInsightsSection(context, languageCode, isDarkMode),

                  // Bottom padding for FAB
                  const SliverToBoxAdapter(
                    child: SizedBox(height: 100),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildAnimatedAppBar(
      BuildContext context, String languageCode, bool isDarkMode) {
    return SliverAppBar(
      expandedHeight: 120,
      floating: true,
      pinned: false,
      snap: true,
      backgroundColor: Colors.transparent,
      elevation: 0,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDarkMode
                  ? [
                      SahayakColors.darkBackground,
                      SahayakColors.darkSurface.withOpacity(0.8),
                    ]
                  : [
                      SahayakColors.lightBackground,
                      SahayakColors.warmIvory.withOpacity(0.8),
                    ],
            ),
          ),
        ),
      ),
      title: AnimatedBuilder(
        animation: _welcomeSlideAnimation,
        builder: (context, child) {
          return Transform.translate(
            offset: Offset(_welcomeSlideAnimation.value, 0),
            child: Text(
              _getGreeting(languageCode),
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: isDarkMode
                        ? SahayakColors.chalkWhite
                        : SahayakColors.charcoal,
                  ),
            ),
          );
        },
      ),
      actions: [
        // Notification bell with indicator
        IconButton(
          icon: Stack(
            children: [
              Icon(
                Icons.notifications_outlined,
                color: isDarkMode
                    ? SahayakColors.chalkWhite
                    : SahayakColors.charcoal,
                size: 28,
              ),
              Positioned(
                right: 4,
                top: 4,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: SahayakColors.deepTeal,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ],
          ),
          onPressed: () => _showNotifications(context),
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildWelcomeSection(
      BuildContext context, String languageCode, bool isDarkMode) {
    return SliverToBoxAdapter(
      child: AnimatedBuilder(
        animation: _welcomeSlideAnimation,
        builder: (context, child) {
          return Transform.translate(
            offset: Offset(0, _welcomeSlideAnimation.value),
            child: Container(
              margin: ResponsiveLayout.getScreenPadding(context),
              padding: const EdgeInsets.all(24),
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
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: isDarkMode
                        ? Colors.black.withOpacity(0.3)
                        : SahayakColors.charcoal.withOpacity(0.1),
                    blurRadius: 15,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: SahayakColors.ochre.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Icon(
                          Icons.school_outlined,
                          size: 32,
                          color: SahayakColors.ochre,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _getPersonalGreeting(languageCode),
                              style: Theme.of(context)
                                  .textTheme
                                  .headlineSmall
                                  ?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: isDarkMode
                                        ? SahayakColors.chalkWhite
                                        : SahayakColors.charcoal,
                                  ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _getMotivationalMessage(languageCode),
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyLarge
                                  ?.copyWith(
                                    color: isDarkMode
                                        ? SahayakColors.chalkWhite
                                            .withOpacity(0.8)
                                        : SahayakColors.charcoal
                                            .withOpacity(0.7),
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _buildQuickStats(context, languageCode, isDarkMode),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildQuickStats(
      BuildContext context, String languageCode, bool isDarkMode) {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            context,
            icon: Icons.today_outlined,
            value: "5",
            label: _getTodayClassesLabel(languageCode),
            color: SahayakColors.deepTeal,
            isDarkMode: isDarkMode,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            context,
            icon: Icons.assignment_outlined,
            value: "12",
            label: _getPendingTasksLabel(languageCode),
            color: SahayakColors.burntSienna,
            isDarkMode: isDarkMode,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            context,
            icon: Icons.trending_up_outlined,
            value: "89%",
            label: _getProgressLabel(languageCode),
            color: SahayakColors.forestGreen,
            isDarkMode: isDarkMode,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(
    BuildContext context, {
    required IconData icon,
    required String value,
    required String label,
    required Color color,
    required bool isDarkMode,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(isDarkMode ? 0.2 : 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: color,
            size: 24,
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: isDarkMode
                      ? SahayakColors.chalkWhite.withOpacity(0.8)
                      : SahayakColors.charcoal.withOpacity(0.7),
                ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildTodayOverview(
      BuildContext context, String languageCode, bool isDarkMode) {
    return SliverToBoxAdapter(
      child: Container(
        margin: ResponsiveLayout.getScreenPadding(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 24),
            Text(
              _getTodayOverviewTitle(languageCode),
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: isDarkMode
                        ? SahayakColors.chalkWhite
                        : SahayakColors.charcoal,
                  ),
            ),
            const SizedBox(height: 16),
            ProgressDashboard(
              languageCode: languageCode,
              isDarkMode: isDarkMode,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionsGrid(
      BuildContext context, String languageCode, bool isDarkMode) {
    return SliverToBoxAdapter(
      child: Container(
        margin: ResponsiveLayout.getScreenPadding(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 24),
            Text(
              _getQuickActionsTitle(languageCode),
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: isDarkMode
                        ? SahayakColors.chalkWhite
                        : SahayakColors.charcoal,
                  ),
            ),
            const SizedBox(height: 16),
            AnimatedBuilder(
              animation: _cardsStaggerAnimation,
              builder: (context, child) {
                return QuickActionGrid(
                  languageCode: languageCode,
                  isDarkMode: isDarkMode,
                  animation: _cardsStaggerAnimation,
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentActivities(
      BuildContext context, String languageCode, bool isDarkMode) {
    return SliverToBoxAdapter(
      child: Container(
        margin: ResponsiveLayout.getScreenPadding(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _getRecentActivitiesTitle(languageCode),
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: isDarkMode
                            ? SahayakColors.chalkWhite
                            : SahayakColors.charcoal,
                      ),
                ),
                TextButton.icon(
                  onPressed: () => _viewAllActivities(context),
                  icon: Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: SahayakColors.deepTeal,
                  ),
                  label: Text(
                    _getViewAllLabel(languageCode),
                    style: TextStyle(
                      color: SahayakColors.deepTeal,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            RecentActivitiesWidget(
              languageCode: languageCode,
              isDarkMode: isDarkMode,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInsightsSection(
      BuildContext context, String languageCode, bool isDarkMode) {
    return SliverToBoxAdapter(
      child: Container(
        margin: ResponsiveLayout.getScreenPadding(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 24),
            Text(
              _getInsightsTitle(languageCode),
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: isDarkMode
                        ? SahayakColors.chalkWhite
                        : SahayakColors.charcoal,
                  ),
            ),
            const SizedBox(height: 16),
            _buildInsightCard(
              context,
              icon: Icons.lightbulb_outline,
              title: _getInsightTipTitle(languageCode),
              description: _getInsightTipDescription(languageCode),
              color: SahayakColors.clayOrange,
              isDarkMode: isDarkMode,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInsightCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String description,
    required Color color,
    required bool isDarkMode,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.withOpacity(isDarkMode ? 0.15 : 0.1),
            color.withOpacity(isDarkMode ? 0.1 : 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: color,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: isDarkMode
                            ? SahayakColors.chalkWhite
                            : SahayakColors.charcoal,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: isDarkMode
                            ? SahayakColors.chalkWhite.withOpacity(0.8)
                            : SahayakColors.charcoal.withOpacity(0.7),
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showNotifications(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_getNotificationsMessage('en')),
        backgroundColor: SahayakColors.deepTeal,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _viewAllActivities(BuildContext context) {
    // Navigate to activities page
  }

  // Localization methods
  String _getGreeting(String languageCode) {
    switch (languageCode) {
      case 'hi':
        return 'नमस्ते शिक्षक जी';
      case 'mr':
        return 'नमस्कार शिक्षक';
      default:
        return 'Hello Teacher';
    }
  }

  String _getPersonalGreeting(String languageCode) {
    switch (languageCode) {
      case 'hi':
        return 'आपका दिन शुभ हो!';
      case 'mr':
        return 'तुमचा दिवस चांगला जावो!';
      default:
        return 'Have a wonderful day!';
    }
  }

  String _getMotivationalMessage(String languageCode) {
    switch (languageCode) {
      case 'hi':
        return 'आज भी नए सपने बुनते रहिए';
      case 'mr':
        return 'आज नवीन स्वप्ने रचूया';
      default:
        return 'Ready to inspire young minds today?';
    }
  }

  String _getTodayClassesLabel(String languageCode) {
    switch (languageCode) {
      case 'hi':
        return 'आज की कक्षाएं';
      case 'mr':
        return 'आजचे वर्ग';
      default:
        return 'Today\'s Classes';
    }
  }

  String _getPendingTasksLabel(String languageCode) {
    switch (languageCode) {
      case 'hi':
        return 'बाकी काम';
      case 'mr':
        return 'बाकी काम';
      default:
        return 'Pending Tasks';
    }
  }

  String _getProgressLabel(String languageCode) {
    switch (languageCode) {
      case 'hi':
        return 'प्रगति';
      case 'mr':
        return 'प्रगती';
      default:
        return 'Progress';
    }
  }

  String _getTodayOverviewTitle(String languageCode) {
    switch (languageCode) {
      case 'hi':
        return 'आज का अवलोकन';
      case 'mr':
        return 'आजचे अवलोकन';
      default:
        return 'Today\'s Overview';
    }
  }

  String _getQuickActionsTitle(String languageCode) {
    switch (languageCode) {
      case 'hi':
        return 'त्वरित कार्य';
      case 'mr':
        return 'द्रुत कार्ये';
      default:
        return 'Quick Actions';
    }
  }

  String _getRecentActivitiesTitle(String languageCode) {
    switch (languageCode) {
      case 'hi':
        return 'हाल की गतिविधियां';
      case 'mr':
        return 'अलीकडील क्रियाकलाप';
      default:
        return 'Recent Activities';
    }
  }

  String _getViewAllLabel(String languageCode) {
    switch (languageCode) {
      case 'hi':
        return 'सभी देखें';
      case 'mr':
        return 'सर्व पहा';
      default:
        return 'View All';
    }
  }

  String _getInsightsTitle(String languageCode) {
    switch (languageCode) {
      case 'hi':
        return 'सुझाव और अंतर्दृष्टि';
      case 'mr':
        return 'सूचना आणि अंतर्दृष्टी';
      default:
        return 'Insights & Tips';
    }
  }

  String _getInsightTipTitle(String languageCode) {
    switch (languageCode) {
      case 'hi':
        return 'आज का सुझाव';
      case 'mr':
        return 'आजची टीप';
      default:
        return 'Today\'s Tip';
    }
  }

  String _getInsightTipDescription(String languageCode) {
    switch (languageCode) {
      case 'hi':
        return 'कहानी सुनाते समय हाव-भाव का उपयोग करें, यह बच्चों की रुचि बढ़ाता है।';
      case 'mr':
        return 'कथा सांगताना हावभाव वापरा, यामुळे मुलांची आवड वाढते.';
      default:
        return 'Use gestures while storytelling - it increases children\'s engagement by 40%.';
    }
  }

  String _getNotificationsMessage(String languageCode) {
    switch (languageCode) {
      case 'hi':
        return 'सूचनाएं जल्द ही उपलब्ध होंगी';
      case 'mr':
        return 'सूचना लवकरच उपलब्ध होतील';
      default:
        return 'Notifications coming soon';
    }
  }
}
