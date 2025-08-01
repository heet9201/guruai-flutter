import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/accessibility/enhanced_accessibility_manager.dart';
import '../core/theme/app_theme.dart';
import '../presentation/screens/enhanced_dashboard_screen.dart';
import '../presentation/screens/accessibility_settings_screen.dart';

class EnhancedSahayakApp extends StatefulWidget {
  const EnhancedSahayakApp({Key? key}) : super(key: key);

  @override
  State<EnhancedSahayakApp> createState() => _EnhancedSahayakAppState();
}

class _EnhancedSahayakAppState extends State<EnhancedSahayakApp> {
  late EnhancedAccessibilityManager _accessibilityManager;

  @override
  void initState() {
    super.initState();
    _accessibilityManager = EnhancedAccessibilityManager.instance;
    _accessibilityManager.addListener(_onAccessibilityChanged);

    // Initialize accessibility after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _accessibilityManager.initialize(context);
    });
  }

  @override
  void dispose() {
    _accessibilityManager.removeListener(_onAccessibilityChanged);
    super.dispose();
  }

  void _onAccessibilityChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sahayak - Your Teaching Assistant',
      debugShowCheckedModeBanner: false,

      // Theme configuration based on accessibility settings
      theme: AppTheme.lightTheme(),
      darkTheme: AppTheme.darkTheme(),
      themeMode: _getEffectiveThemeMode(),

      // Accessibility configuration
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(
            // Apply accessibility font scaling
            textScaler: TextScaler.linear(_accessibilityManager.fontScale),
          ),
          child: child ?? const SizedBox.shrink(),
        );
      },

      // Navigation
      home: const EnhancedMainScreen(),

      // Routes
      routes: {
        '/accessibility': (context) => const AccessibilitySettingsScreen(),
        '/dashboard': (context) => const EnhancedDashboardScreen(),
      },

      // Accessibility shortcuts
      shortcuts: _buildAccessibilityShortcuts(),
      actions: _buildAccessibilityActions(),
    );
  }

  ThemeMode _getEffectiveThemeMode() {
    if (_accessibilityManager.shouldOverrideSystemTheme()) {
      return _accessibilityManager.getEffectiveThemeMode();
    }
    return ThemeMode.system;
  }

  Map<ShortcutActivator, Intent> _buildAccessibilityShortcuts() {
    return {
      // Quick accessibility toggles
      const SingleActivator(LogicalKeyboardKey.f1, control: true):
          const ToggleHighContrastIntent(),
      const SingleActivator(LogicalKeyboardKey.f2, control: true):
          const ToggleBlackboardModeIntent(),
      const SingleActivator(LogicalKeyboardKey.f3, control: true):
          const ToggleTooltipsIntent(),

      // Font size adjustments
      const SingleActivator(LogicalKeyboardKey.equal, control: true):
          const IncreaseFontSizeIntent(),
      const SingleActivator(LogicalKeyboardKey.minus, control: true):
          const DecreaseFontSizeIntent(),
      const SingleActivator(LogicalKeyboardKey.digit0, control: true):
          const ResetFontSizeIntent(),
    };
  }

  Map<Type, Action<Intent>> _buildAccessibilityActions() {
    return {
      ToggleHighContrastIntent: CallbackAction<ToggleHighContrastIntent>(
        onInvoke: (_) {
          _accessibilityManager.toggleHighContrast();
          return null;
        },
      ),
      ToggleBlackboardModeIntent: CallbackAction<ToggleBlackboardModeIntent>(
        onInvoke: (_) {
          _accessibilityManager.toggleBlackboardMode();
          return null;
        },
      ),
      ToggleTooltipsIntent: CallbackAction<ToggleTooltipsIntent>(
        onInvoke: (_) {
          _accessibilityManager.toggleTooltips();
          return null;
        },
      ),
      IncreaseFontSizeIntent: CallbackAction<IncreaseFontSizeIntent>(
        onInvoke: (_) {
          final newScale =
              (_accessibilityManager.fontScale + 0.1).clamp(0.8, 2.0);
          _accessibilityManager.setFontScale(newScale);
          return null;
        },
      ),
      DecreaseFontSizeIntent: CallbackAction<DecreaseFontSizeIntent>(
        onInvoke: (_) {
          final newScale =
              (_accessibilityManager.fontScale - 0.1).clamp(0.8, 2.0);
          _accessibilityManager.setFontScale(newScale);
          return null;
        },
      ),
      ResetFontSizeIntent: CallbackAction<ResetFontSizeIntent>(
        onInvoke: (_) {
          _accessibilityManager.setFontScale(1.0);
          return null;
        },
      ),
    };
  }
}

// Custom Intents for accessibility shortcuts
class ToggleHighContrastIntent extends Intent {
  const ToggleHighContrastIntent();
}

class ToggleBlackboardModeIntent extends Intent {
  const ToggleBlackboardModeIntent();
}

class ToggleTooltipsIntent extends Intent {
  const ToggleTooltipsIntent();
}

class IncreaseFontSizeIntent extends Intent {
  const IncreaseFontSizeIntent();
}

class DecreaseFontSizeIntent extends Intent {
  const DecreaseFontSizeIntent();
}

class ResetFontSizeIntent extends Intent {
  const ResetFontSizeIntent();
}

class EnhancedMainScreen extends StatefulWidget {
  const EnhancedMainScreen({Key? key}) : super(key: key);

  @override
  State<EnhancedMainScreen> createState() => _EnhancedMainScreenState();
}

class _EnhancedMainScreenState extends State<EnhancedMainScreen> {
  int _currentIndex = 0;
  late PageController _pageController;
  late EnhancedAccessibilityManager _accessibilityManager;

  final List<Widget> _screens = [
    const EnhancedDashboardScreen(),
    const Center(child: Text('Lessons Screen')), // Placeholder
    const Center(child: Text('Students Screen')), // Placeholder
    const Center(child: Text('Resources Screen')), // Placeholder
    const AccessibilitySettingsScreen(),
  ];

  final List<NavigationDestination> _destinations = [
    const NavigationDestination(
      icon: Icon(Icons.dashboard_rounded),
      selectedIcon: Icon(Icons.dashboard_rounded),
      label: 'Dashboard',
    ),
    const NavigationDestination(
      icon: Icon(Icons.school_rounded),
      selectedIcon: Icon(Icons.school_rounded),
      label: 'Lessons',
    ),
    const NavigationDestination(
      icon: Icon(Icons.people_rounded),
      selectedIcon: Icon(Icons.people_rounded),
      label: 'Students',
    ),
    const NavigationDestination(
      icon: Icon(Icons.library_books_rounded),
      selectedIcon: Icon(Icons.library_books_rounded),
      label: 'Resources',
    ),
    const NavigationDestination(
      icon: Icon(Icons.accessibility_new_rounded),
      selectedIcon: Icon(Icons.accessibility_new_rounded),
      label: 'Settings',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _accessibilityManager = EnhancedAccessibilityManager.instance;
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onDestinationSelected(int index) {
    setState(() {
      _currentIndex = index;
    });

    _pageController.animateToPage(
      index,
      duration: _accessibilityManager.getAnimationDuration(
        const Duration(milliseconds: 300),
      ),
      curve: Curves.easeInOut,
    );

    // Announce navigation
    _accessibilityManager.announceMessage(
      'Navigated to ${_destinations[index].label}',
    );

    // Provide feedback
    _accessibilityManager.provideFeedback();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView(
        controller: _pageController,
        onPageChanged: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        children: _screens,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: _onDestinationSelected,
        destinations: _destinations.map((destination) {
          return NavigationDestination(
            icon: Transform.scale(
              scale: _accessibilityManager.iconScale,
              child: destination.icon,
            ),
            selectedIcon: Transform.scale(
              scale: _accessibilityManager.iconScale,
              child: destination.selectedIcon,
            ),
            label: destination.label,
          );
        }).toList(),
      ),
      floatingActionButton: _buildAccessibilityFAB(),
    );
  }

  Widget? _buildAccessibilityFAB() {
    // Show accessibility FAB on non-settings screens
    if (_currentIndex == 4) return null;

    return Semantics(
      label: 'Quick accessibility menu',
      child: FloatingActionButton(
        onPressed: _showAccessibilityMenu,
        child: Transform.scale(
          scale: _accessibilityManager.iconScale,
          child: const Icon(Icons.accessibility_new_rounded),
        ),
      ),
    );
  }

  void _showAccessibilityMenu() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) {
          return Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    Icon(
                      Icons.accessibility_new_rounded,
                      size: 28,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Quick Accessibility',
                      style:
                          Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close_rounded),
                      tooltip: 'Close menu',
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // Quick toggles
                Expanded(
                  child: ListView(
                    controller: scrollController,
                    children: [
                      _buildQuickToggle(
                        title: 'High Contrast',
                        subtitle: 'Enhance color contrast',
                        icon: Icons.contrast_rounded,
                        value: _accessibilityManager.highContrastMode,
                        onChanged: (_) =>
                            _accessibilityManager.toggleHighContrast(),
                      ),

                      _buildQuickToggle(
                        title: 'Dark Blackboard Mode',
                        subtitle: 'Teacher-friendly dark theme',
                        icon: Icons.school_rounded,
                        value: _accessibilityManager.blackboardMode,
                        onChanged: (_) =>
                            _accessibilityManager.toggleBlackboardMode(),
                      ),

                      _buildQuickToggle(
                        title: 'Tooltips',
                        subtitle: 'Show helpful hints',
                        icon: Icons.help_outline_rounded,
                        value: _accessibilityManager.tooltipsEnabled,
                        onChanged: (_) =>
                            _accessibilityManager.toggleTooltips(),
                      ),

                      _buildQuickToggle(
                        title: 'Sound Effects',
                        subtitle: 'Audio feedback',
                        icon: _accessibilityManager.soundEnabled
                            ? Icons.volume_up_rounded
                            : Icons.volume_off_rounded,
                        value: _accessibilityManager.soundEnabled,
                        onChanged: (_) => _accessibilityManager.toggleSound(),
                      ),

                      _buildQuickToggle(
                        title: 'Haptic Feedback',
                        subtitle: 'Touch vibrations',
                        icon: Icons.vibration_rounded,
                        value: _accessibilityManager.hapticEnabled,
                        onChanged: (_) => _accessibilityManager.toggleHaptic(),
                      ),

                      const SizedBox(height: 20),

                      // Full settings button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.pop(context);
                            setState(() {
                              _currentIndex = 4;
                            });
                            _pageController.animateToPage(
                              4,
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                            );
                          },
                          icon: const Icon(Icons.settings_rounded),
                          label: const Text('Full Accessibility Settings'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildQuickToggle({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return SwitchListTile.adaptive(
      title: Text(title),
      subtitle: Text(subtitle),
      value: value,
      onChanged: onChanged,
      secondary: Icon(
        icon,
        color: Theme.of(context).colorScheme.primary,
      ),
    );
  }
}
