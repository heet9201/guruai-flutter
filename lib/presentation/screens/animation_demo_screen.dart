import 'package:flutter/material.dart';
import '../../core/animations/animation_manager.dart';
import '../../core/animations/loading_animations.dart';
import '../../core/animations/button_animations.dart';
import '../../core/animations/gesture_animations.dart';
import '../../core/animations/lottie_animations.dart';
import '../../core/accessibility/accessibility_manager.dart';
import '../../core/accessibility/accessible_widgets.dart';

/// Demo screen showcasing all animations and micro-interactions
class AnimationDemoScreen extends StatefulWidget {
  const AnimationDemoScreen({super.key});

  @override
  State<AnimationDemoScreen> createState() => _AnimationDemoScreenState();
}

class _AnimationDemoScreenState extends State<AnimationDemoScreen>
    with TickerProviderStateMixin, AccessibilityMixin {
  bool _isLoading = false;
  bool _showSwipeIndicator = false;
  int _currentGrade = 5;

  late AnimationController _fabController;
  bool _fabVisible = true;

  @override
  void initState() {
    super.initState();
    _fabController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fabController.forward();
  }

  @override
  void dispose() {
    _fabController.dispose();
    super.dispose();
  }

  void _simulateAIGeneration() async {
    setState(() => _isLoading = true);

    // Announce loading state
    announce('Starting AI content generation');

    // Simulate AI processing
    await Future.delayed(const Duration(seconds: 3));

    setState(() => _isLoading = false);

    // Show success animation
    AnimationManager.showSuccessAnimation(
      context,
      message: 'Content Generated!',
    );

    // Announce completion
    announce('Content generation completed successfully');
  }

  void _switchGrade(bool isNext) {
    setState(() {
      if (isNext && _currentGrade < 12) {
        _currentGrade++;
      } else if (!isNext && _currentGrade > 1) {
        _currentGrade--;
      }
    });

    AnimationManager.triggerHaptic(HapticType.medium);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Switched to Grade $_currentGrade'),
        duration: const Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _toggleFAB() {
    setState(() => _fabVisible = !_fabVisible);
  }

  Future<void> _onRefresh() async {
    AnimationManager.triggerHaptic(HapticType.light);
    await Future.delayed(const Duration(seconds: 2));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Animation Demo'),
        elevation: 0,
        backgroundColor: Theme.of(context).colorScheme.surface,
        foregroundColor: Theme.of(context).colorScheme.onSurface,
        actions: [
          Semantics(
            label: 'Show gesture instructions',
            hint: 'Double tap to view available gestures',
            child: IconButton(
              icon: const Icon(Icons.info_outline),
              onPressed: () => AnimationManager.showSwipeInstruction(context),
              tooltip: 'Show gesture instructions',
            ),
          ),
        ],
      ),
      body: GradeSwitchGestureDetector(
        onSwipeLeft: () => _switchGrade(false),
        onSwipeRight: () => _switchGrade(true),
        child: AnimatedRefreshIndicator(
          onRefresh: _onRefresh,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Grade indicator
                Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 12),
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Theme.of(context).primaryColor.withOpacity(0.3),
                      ),
                    ),
                    child: Text(
                      'Grade $_currentGrade',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: Theme.of(context).primaryColor,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Swipe instruction
                if (_showSwipeIndicator) const SwipeIndicator(isVisible: true),

                const SizedBox(height: 24),

                // Loading states section
                AnimationManager.createAnimatedCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'AI Loading States',
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                      ),
                      const SizedBox(height: 16),
                      if (_isLoading) ...[
                        AILoadingAnimation(
                          isLoading: true,
                          message: 'Generating amazing content...',
                        ),
                        const SizedBox(height: 16),
                      ],
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          AnimationManager.createAnimatedButton(
                            onPressed: _simulateAIGeneration,
                            backgroundColor: Theme.of(context).primaryColor,
                            child: const Text(
                              'Generate Content',
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                          AnimationManager.createAnimatedButton(
                            onPressed: () => setState(() =>
                                _showSwipeIndicator = !_showSwipeIndicator),
                            backgroundColor: Colors.orange,
                            child: Text(
                              _showSwipeIndicator ? 'Hide Swipe' : 'Show Swipe',
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Animation types showcase
                AnimationManager.createStaggeredList(
                  children: [
                    _buildAnimationCard(
                      'Thinking Animation',
                      LoadingAnimationPresets.getLoadingAnimation(
                        LoadingAnimationType.thinking,
                        size: 40,
                      ),
                    ),
                    _buildAnimationCard(
                      'Processing Animation',
                      LoadingAnimationPresets.getLoadingAnimation(
                        LoadingAnimationType.processing,
                        size: 40,
                      ),
                    ),
                    _buildAnimationCard(
                      'Generating Animation',
                      LoadingAnimationPresets.getLoadingAnimation(
                        LoadingAnimationType.generating,
                        size: 40,
                      ),
                    ),
                    _buildAnimationCard(
                      'Upload Animation',
                      LoadingAnimationPresets.getLoadingAnimation(
                        LoadingAnimationType.uploading,
                        size: 40,
                      ),
                    ),
                    _buildAnimationCard(
                      'Download Animation',
                      LoadingAnimationPresets.getLoadingAnimation(
                        LoadingAnimationType.downloading,
                        size: 40,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Button animations
                AnimationManager.createAnimatedCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Interactive Elements',
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                      ),
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          AnimationManager.createAnimatedButton(
                            onPressed: () => AnimationManager.triggerHaptic(
                                HapticType.light),
                            backgroundColor: Colors.blue,
                            child: const Text(
                              'Light Haptic',
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                          AnimationManager.createAnimatedButton(
                            onPressed: () => AnimationManager.triggerHaptic(
                                HapticType.medium),
                            backgroundColor: Colors.green,
                            child: const Text(
                              'Medium Haptic',
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                          AnimationManager.createAnimatedButton(
                            onPressed: () => AnimationManager.triggerHaptic(
                                HapticType.heavy),
                            backgroundColor: Colors.red,
                            child: const Text(
                              'Heavy Haptic',
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                          AnimationManager.createAnimatedButton(
                            onPressed: _toggleFAB,
                            backgroundColor: Colors.purple,
                            child: Text(
                              _fabVisible ? 'Hide FAB' : 'Show FAB',
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Gesture instructions
                AnimationManager.createAnimatedCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Gesture Controls',
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                          '• Two-finger swipe left/right to change grades'),
                      const Text('• Pull down to refresh'),
                      const Text('• Tap cards for hover effects'),
                      const Text('• Long press for haptic feedback'),
                    ],
                  ),
                ),

                const SizedBox(height: 100), // Space for FAB
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: AnimationManager.createAnimatedFAB(
        onPressed: () {
          AnimationManager.showSuccessAnimation(
            context,
            message: 'FAB Pressed!',
          );
        },
        icon: Icons.add,
        label: 'Create',
        isVisible: _fabVisible,
      ),
    );
  }

  Widget _buildAnimationCard(String title, Widget animation) {
    return AnimationManager.createAnimatedCard(
      onTap: () => AnimationManager.triggerHaptic(HapticType.selection),
      child: Row(
        children: [
          SizedBox(
            width: 60,
            height: 60,
            child: Center(child: animation),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              title,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
