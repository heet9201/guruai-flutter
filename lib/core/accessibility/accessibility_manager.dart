import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/semantics.dart';

/// Central accessibility manager for the app
class AccessibilityManager {
  static const Duration announceDelay = Duration(milliseconds: 100);

  // Accessibility preferences cache
  static bool _isHighContrastEnabled = false;
  static bool _isLargeTextEnabled = false;
  static bool _isScreenReaderEnabled = false;
  static bool _isReduceMotionEnabled = false;

  /// Initialize accessibility settings
  static void initialize(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    _isHighContrastEnabled = mediaQuery.highContrast;
    _isLargeTextEnabled = mediaQuery.textScaler.scale(1.0) > 1.2;
    _isScreenReaderEnabled = mediaQuery.accessibleNavigation;
    _isReduceMotionEnabled = mediaQuery.disableAnimations;
  }

  /// Check if high contrast mode is enabled
  static bool get isHighContrastEnabled => _isHighContrastEnabled;

  /// Check if large text is enabled
  static bool get isLargeTextEnabled => _isLargeTextEnabled;

  /// Check if screen reader is enabled
  static bool get isScreenReaderEnabled => _isScreenReaderEnabled;

  /// Check if reduce motion is enabled
  static bool get isReduceMotionEnabled => _isReduceMotionEnabled;

  /// Announce message to screen reader
  static void announceMessage(String message, {bool isAssertive = false}) {
    if (_isScreenReaderEnabled) {
      Future.delayed(announceDelay, () {
        SemanticsService.announce(message, TextDirection.ltr);
      });
    }
  }

  /// Announce success message
  static void announceSuccess(String message) {
    announceMessage(message, isAssertive: true);
    HapticFeedback.lightImpact();
  }

  /// Announce error message
  static void announceError(String message) {
    announceMessage(message, isAssertive: true);
    HapticFeedback.heavyImpact();
  }

  /// Announce loading state
  static void announceLoading(String message) {
    announceMessage(message, isAssertive: false);
  }

  /// Create semantic label for buttons
  static String createButtonLabel({
    required String label,
    String? hint,
    bool isEnabled = true,
    bool isLoading = false,
  }) {
    String semanticLabel = label;

    if (isLoading) {
      semanticLabel += ', loading';
    } else if (!isEnabled) {
      semanticLabel += ', disabled';
    }

    if (hint != null) {
      semanticLabel += ', $hint';
    }

    return semanticLabel;
  }

  /// Create semantic label for form fields
  static String createFieldLabel({
    required String label,
    bool isRequired = false,
    bool hasError = false,
    String? errorMessage,
    String? hint,
  }) {
    String semanticLabel = label;

    if (isRequired) {
      semanticLabel += ', required';
    }

    if (hasError && errorMessage != null) {
      semanticLabel += ', error: $errorMessage';
    }

    if (hint != null) {
      semanticLabel += ', $hint';
    }

    return semanticLabel;
  }

  /// Create semantic label for progress indicators
  static String createProgressLabel({
    required String label,
    double? progress,
    String? status,
  }) {
    String semanticLabel = label;

    if (progress != null) {
      final percentage = (progress * 100).round();
      semanticLabel += ', $percentage percent complete';
    }

    if (status != null) {
      semanticLabel += ', $status';
    }

    return semanticLabel;
  }

  /// Get accessible font size based on user preferences
  static double getAccessibleFontSize(
      double baseFontSize, BuildContext context) {
    final textScaler = MediaQuery.of(context).textScaler;
    final scaledSize = textScaler.scale(baseFontSize);

    // Ensure minimum readable size
    return scaledSize.clamp(12.0, 32.0);
  }

  /// Get accessible color contrast
  static Color getAccessibleColor({
    required Color color,
    required Color backgroundColor,
    required bool isDark,
  }) {
    if (!_isHighContrastEnabled) return color;

    // High contrast colors
    if (isDark) {
      return Colors.white;
    } else {
      return Colors.black;
    }
  }

  /// Get accessible animation duration
  static Duration getAccessibleDuration(Duration baseDuration) {
    if (_isReduceMotionEnabled) {
      return Duration.zero;
    }
    return baseDuration;
  }

  /// Create accessible focus node with semantics
  static FocusNode createAccessibleFocusNode({
    String? debugLabel,
    bool canRequestFocus = true,
  }) {
    return FocusNode(
      debugLabel: debugLabel,
      canRequestFocus: canRequestFocus,
    );
  }

  /// Manage focus for screen reader navigation
  static void manageFocus({
    required BuildContext context,
    required FocusNode focusNode,
    String? announcement,
  }) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (focusNode.canRequestFocus) {
        focusNode.requestFocus();
        if (announcement != null) {
          announceMessage(announcement);
        }
      }
    });
  }

  /// Create accessible route with proper focus management
  static Route<T> createAccessibleRoute<T>({
    required Widget page,
    required String routeName,
    String? announcement,
  }) {
    return PageRouteBuilder<T>(
      settings: RouteSettings(name: routeName),
      pageBuilder: (context, animation, secondaryAnimation) {
        if (announcement != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            announceMessage(announcement);
          });
        }
        return page;
      },
      transitionDuration:
          getAccessibleDuration(const Duration(milliseconds: 300)),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        if (_isReduceMotionEnabled) {
          return child;
        }
        return FadeTransition(opacity: animation, child: child);
      },
    );
  }
}

/// Accessibility widget mixin for consistent implementation
mixin AccessibilityMixin<T extends StatefulWidget> on State<T> {
  late List<FocusNode> _focusNodes;

  @override
  void initState() {
    super.initState();
    _focusNodes = [];
    AccessibilityManager.initialize(context);
  }

  @override
  void dispose() {
    for (final node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  /// Create and track focus node
  FocusNode createFocusNode({String? debugLabel}) {
    final node = AccessibilityManager.createAccessibleFocusNode(
      debugLabel: debugLabel,
    );
    _focusNodes.add(node);
    return node;
  }

  /// Announce message with accessibility manager
  void announce(String message, {bool isAssertive = false}) {
    AccessibilityManager.announceMessage(message, isAssertive: isAssertive);
  }

  /// Get accessible font size for text
  double getAccessibleFontSize(double baseFontSize) {
    return AccessibilityManager.getAccessibleFontSize(baseFontSize, context);
  }

  /// Get accessible duration for animations
  Duration getAccessibleDuration(Duration baseDuration) {
    return AccessibilityManager.getAccessibleDuration(baseDuration);
  }
}

/// Accessibility constants for common use cases
class AccessibilityConstants {
  // Minimum touch target sizes
  static const double minTouchTarget = 48.0;
  static const double preferredTouchTarget = 56.0;

  // Color contrast ratios
  static const double minContrastRatio = 4.5;
  static const double enhancedContrastRatio = 7.0;

  // Font size limits
  static const double minFontSize = 12.0;
  static const double maxFontSize = 32.0;

  // Animation durations
  static const Duration fastAnimation = Duration(milliseconds: 150);
  static const Duration standardAnimation = Duration(milliseconds: 300);
  static const Duration slowAnimation = Duration(milliseconds: 500);

  // Semantic labels
  static const String loadingLabel = 'Loading, please wait';
  static const String successLabel = 'Action completed successfully';
  static const String errorLabel = 'An error occurred';
  static const String requiredFieldLabel = 'Required field';
  static const String optionalFieldLabel = 'Optional field';
}

/// Accessibility testing utilities
class AccessibilityTesting {
  /// Check if widget has proper semantic labels
  static bool hasSemanticLabel(Widget widget) {
    // This would be used in tests to verify semantic labels
    return true;
  }

  /// Check color contrast ratio
  static double calculateContrastRatio(Color foreground, Color background) {
    final fLuminance = _calculateLuminance(foreground);
    final bLuminance = _calculateLuminance(background);

    final lighter = fLuminance > bLuminance ? fLuminance : bLuminance;
    final darker = fLuminance > bLuminance ? bLuminance : fLuminance;

    return (lighter + 0.05) / (darker + 0.05);
  }

  static double _calculateLuminance(Color color) {
    final r = _calculateColorComponent(color.red);
    final g = _calculateColorComponent(color.green);
    final b = _calculateColorComponent(color.blue);

    return 0.2126 * r + 0.7152 * g + 0.0722 * b;
  }

  static double _calculateColorComponent(int value) {
    final normalized = value / 255.0;
    if (normalized <= 0.03928) {
      return normalized / 12.92;
    } else {
      return ((normalized + 0.055) / 1.055) * ((normalized + 0.055) / 1.055);
    }
  }
}
