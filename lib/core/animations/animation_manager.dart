import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'page_transitions.dart';
import 'loading_animations.dart';
import 'button_animations.dart';
import 'gesture_animations.dart';
import 'lottie_animations.dart';

/// Central animation manager for the app
class AnimationManager {
  static const Duration defaultDuration = Duration(milliseconds: 300);
  static const Duration fastDuration = Duration(milliseconds: 200);
  static const Duration slowDuration = Duration(milliseconds: 500);

  /// Get appropriate page transition based on direction
  static Route<T> createPageRoute<T>({
    required Widget page,
    SlideDirection direction = SlideDirection.rightToLeft,
    Duration? duration,
    RouteSettings? settings,
  }) {
    return SlidePageRoute<T>(
      child: page,
      direction: direction,
      duration: duration ?? defaultDuration,
      settings: settings,
    );
  }

  /// Create fade transition route
  static Route<T> createFadeRoute<T>({
    required Widget page,
    Duration? duration,
    RouteSettings? settings,
  }) {
    return FadeScalePageRoute<T>(
      child: page,
      duration: duration ?? defaultDuration,
      settings: settings,
    );
  }

  /// Create hero transition route
  static Route<T> createHeroRoute<T>({
    required Widget page,
    required String heroTag,
    RouteSettings? settings,
  }) {
    return SharedElementTransition.createRoute<T>(
      child: page,
      heroTag: heroTag,
      settings: settings,
    );
  }

  /// Trigger haptic feedback based on action type
  static void triggerHaptic(HapticType type) {
    switch (type) {
      case HapticType.light:
        HapticFeedback.lightImpact();
        break;
      case HapticType.medium:
        HapticFeedback.mediumImpact();
        break;
      case HapticType.heavy:
        HapticFeedback.heavyImpact();
        break;
      case HapticType.selection:
        HapticFeedback.selectionClick();
        break;
      case HapticType.vibrate:
        HapticFeedback.vibrate();
        break;
    }
  }

  /// Get loading animation widget
  static Widget getLoadingAnimation(
    LoadingAnimationType type, {
    double? size,
    Color? color,
    String? message,
  }) {
    switch (type) {
      case LoadingAnimationType.thinking:
      case LoadingAnimationType.processing:
      case LoadingAnimationType.generating:
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            LoadingAnimationPresets.getLoadingAnimation(type,
                size: size, color: color),
            if (message != null) ...[
              const SizedBox(height: 16),
              Text(
                message,
                style: TextStyle(color: color),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        );
      default:
        return LoadingAnimationPresets.getLoadingAnimation(type,
            size: size, color: color);
    }
  }

  /// Create animated list with staggered animation
  static Widget createStaggeredList({
    required List<Widget> children,
    Duration? staggerDelay,
    Duration? itemDuration,
    bool isVisible = true,
  }) {
    return StaggeredListAnimation(
      staggerDelay: staggerDelay ?? const Duration(milliseconds: 100),
      itemDuration: itemDuration ?? defaultDuration,
      isVisible: isVisible,
      children: children,
    );
  }

  /// Create animated button with effects
  static Widget createAnimatedButton({
    required Widget child,
    VoidCallback? onPressed,
    Color? backgroundColor,
    Color? hoverColor,
    EdgeInsetsGeometry? padding,
    BorderRadius? borderRadius,
    Duration? duration,
    bool enableHaptics = true,
  }) {
    return AnimatedButton(
      onPressed: onPressed,
      backgroundColor: backgroundColor,
      hoverColor: hoverColor,
      padding: padding,
      borderRadius: borderRadius,
      duration: duration ?? fastDuration,
      enableHaptics: enableHaptics,
      child: child,
    );
  }

  /// Create animated card with hover effects
  static Widget createAnimatedCard({
    required Widget child,
    VoidCallback? onTap,
    EdgeInsetsGeometry? margin,
    EdgeInsetsGeometry? padding,
    Color? color,
    double elevation = 2.0,
    BorderRadius? borderRadius,
  }) {
    return AnimatedCard(
      onTap: onTap,
      margin: margin,
      padding: padding,
      color: color,
      elevation: elevation,
      borderRadius: borderRadius,
      child: child,
    );
  }

  /// Create floating action button with reveal animation
  static Widget createAnimatedFAB({
    VoidCallback? onPressed,
    required IconData icon,
    String? label,
    bool isVisible = true,
    Duration? duration,
    Color? backgroundColor,
  }) {
    return AnimatedFAB(
      onPressed: onPressed,
      icon: icon,
      label: label,
      isVisible: isVisible,
      duration: duration ?? defaultDuration,
      backgroundColor: backgroundColor,
    );
  }

  /// Create scroll view with gesture enhancements
  static Widget createEnhancedScrollView({
    required Widget child,
    Future<void> Function()? onRefresh,
    VoidCallback? onSwipeLeft,
    VoidCallback? onSwipeRight,
    bool enableGradeSwitch = false,
    ScrollController? controller,
  }) {
    return EnhancedScrollView(
      onRefresh: onRefresh,
      onSwipeLeft: onSwipeLeft,
      onSwipeRight: onSwipeRight,
      enableGradeSwitch: enableGradeSwitch,
      controller: controller,
      child: child,
    );
  }

  /// Show success animation overlay
  static void showSuccessAnimation(
    BuildContext context, {
    String message = 'Success!',
    Duration? duration,
  }) {
    final overlay = Overlay.of(context);
    late OverlayEntry entry;

    entry = OverlayEntry(
      builder: (context) => Positioned.fill(
        child: Material(
          color: Colors.transparent,
          child: SuccessAnimation(
            isVisible: true,
            message: message,
            duration: duration ?? const Duration(milliseconds: 2000),
            onComplete: () => entry.remove(),
          ),
        ),
      ),
    );

    overlay.insert(entry);
  }

  /// Show loading overlay
  static OverlayEntry showLoadingOverlay(
    BuildContext context, {
    LoadingAnimationType type = LoadingAnimationType.processing,
    String? message,
    Color? color,
  }) {
    final overlay = Overlay.of(context);

    final entry = OverlayEntry(
      builder: (context) => Positioned.fill(
        child: Material(
          color: Colors.black.withOpacity(0.5),
          child: Center(
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: getLoadingAnimation(
                type,
                message: message,
                color: color,
              ),
            ),
          ),
        ),
      ),
    );

    overlay.insert(entry);
    return entry;
  }

  /// Show swipe instruction overlay
  static void showSwipeInstruction(BuildContext context) {
    final overlay = Overlay.of(context);
    late OverlayEntry entry;

    entry = OverlayEntry(
      builder: (context) => const Positioned(
        top: 100,
        left: 0,
        right: 0,
        child: Center(
          child: SwipeIndicator(
            isVisible: true,
            duration: Duration(seconds: 3),
          ),
        ),
      ),
    );

    overlay.insert(entry);

    // Auto-remove after duration
    Future.delayed(const Duration(seconds: 3), () {
      entry.remove();
    });
  }
}

/// Haptic feedback types
enum HapticType {
  light,
  medium,
  heavy,
  selection,
  vibrate,
}

/// Animation configuration class
class AnimationConfig {
  final Duration duration;
  final Curve curve;
  final bool enableHaptics;
  final HapticType hapticType;

  const AnimationConfig({
    this.duration = const Duration(milliseconds: 300),
    this.curve = Curves.easeInOut,
    this.enableHaptics = true,
    this.hapticType = HapticType.light,
  });

  static const AnimationConfig fast = AnimationConfig(
    duration: Duration(milliseconds: 200),
    curve: Curves.easeOut,
  );

  static const AnimationConfig slow = AnimationConfig(
    duration: Duration(milliseconds: 500),
    curve: Curves.easeInOut,
  );

  static const AnimationConfig elastic = AnimationConfig(
    duration: Duration(milliseconds: 600),
    curve: Curves.elasticOut,
  );

  static const AnimationConfig bounce = AnimationConfig(
    duration: Duration(milliseconds: 400),
    curve: Curves.bounceOut,
  );
}

/// Mixin for easy animation integration
mixin AnimationMixin<T extends StatefulWidget>
    on State<T>, TickerProviderStateMixin<T> {
  late AnimationController animationController;
  late Animation<double> fadeAnimation;
  late Animation<double> scaleAnimation;
  late Animation<Offset> slideAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
  }

  void _initializeAnimations() {
    animationController = AnimationController(
      duration: AnimationManager.defaultDuration,
      vsync: this,
    );

    fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: animationController, curve: Curves.easeOut),
    );

    scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: animationController, curve: Curves.elasticOut),
    );

    slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
      CurvedAnimation(parent: animationController, curve: Curves.easeOut),
    );
  }

  void startAnimation() {
    animationController.forward();
  }

  void reverseAnimation() {
    animationController.reverse();
  }

  void resetAnimation() {
    animationController.reset();
  }

  @override
  void dispose() {
    animationController.dispose();
    super.dispose();
  }
}
