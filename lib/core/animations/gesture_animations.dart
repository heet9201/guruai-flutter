import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Two-finger swipe gesture detector for grade switching
class GradeSwitchGestureDetector extends StatefulWidget {
  final Widget child;
  final VoidCallback? onSwipeLeft;
  final VoidCallback? onSwipeRight;
  final double threshold;
  final Duration hapticDelay;

  const GradeSwitchGestureDetector({
    super.key,
    required this.child,
    this.onSwipeLeft,
    this.onSwipeRight,
    this.threshold = 100.0,
    this.hapticDelay = const Duration(milliseconds: 100),
  });

  @override
  State<GradeSwitchGestureDetector> createState() =>
      _GradeSwitchGestureDetectorState();
}

class _GradeSwitchGestureDetectorState extends State<GradeSwitchGestureDetector>
    with SingleTickerProviderStateMixin {
  late AnimationController _feedbackController;
  late Animation<double> _feedbackAnimation;

  final Map<int, Offset> _pointers = {};
  bool _isProcessingGesture = false;
  Offset? _initialCenter;
  bool _hasTriggeredHaptic = false;

  @override
  void initState() {
    super.initState();

    _feedbackController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _feedbackAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _feedbackController, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _feedbackController.dispose();
    super.dispose();
  }

  void _onPointerDown(PointerDownEvent event) {
    _pointers[event.pointer] = event.position;

    if (_pointers.length == 2) {
      _initialCenter = _getCenterPoint();
      _isProcessingGesture = true;
      _hasTriggeredHaptic = false;
      _feedbackController.forward();
    }
  }

  void _onPointerMove(PointerMoveEvent event) {
    if (!_isProcessingGesture || _pointers.length != 2) return;

    _pointers[event.pointer] = event.position;

    if (_initialCenter != null) {
      final currentCenter = _getCenterPoint();
      final deltaX = currentCenter.dx - _initialCenter!.dx;

      // Trigger haptic feedback when threshold is reached
      if (!_hasTriggeredHaptic && deltaX.abs() > widget.threshold * 0.5) {
        HapticFeedback.selectionClick();
        _hasTriggeredHaptic = true;
      }
    }
  }

  void _onPointerUp(PointerUpEvent event) {
    _pointers.remove(event.pointer);

    if (_isProcessingGesture && _pointers.length < 2) {
      _processGesture();
      _isProcessingGesture = false;
      _initialCenter = null;
      _hasTriggeredHaptic = false;
      _feedbackController.reverse();
    }
  }

  void _processGesture() {
    if (_initialCenter == null || _pointers.isEmpty) return;

    final currentCenter = _getCenterPoint();
    final deltaX = currentCenter.dx - _initialCenter!.dx;

    if (deltaX.abs() > widget.threshold) {
      HapticFeedback.mediumImpact();

      if (deltaX > 0) {
        widget.onSwipeRight?.call();
      } else {
        widget.onSwipeLeft?.call();
      }
    }
  }

  Offset _getCenterPoint() {
    if (_pointers.length < 2) return Offset.zero;

    final positions = _pointers.values.toList();
    return Offset(
      (positions[0].dx + positions[1].dx) / 2,
      (positions[0].dy + positions[1].dy) / 2,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: _onPointerDown,
      onPointerMove: _onPointerMove,
      onPointerUp: _onPointerUp,
      child: AnimatedBuilder(
        animation: _feedbackAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _feedbackAnimation.value,
            child: widget.child,
          );
        },
      ),
    );
  }
}

/// Swipe indicator widget for visual feedback
class SwipeIndicator extends StatefulWidget {
  final bool isVisible;
  final String leftText;
  final String rightText;
  final Duration duration;

  const SwipeIndicator({
    super.key,
    required this.isVisible,
    this.leftText = 'Previous Grade',
    this.rightText = 'Next Grade',
    this.duration = const Duration(milliseconds: 2000),
  });

  @override
  State<SwipeIndicator> createState() => _SwipeIndicatorState();
}

class _SwipeIndicatorState extends State<SwipeIndicator>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late AnimationController _pulseController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _slideAnimation;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    _slideAnimation = Tween<double>(begin: -20.0, end: 0.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    if (widget.isVisible) {
      _showIndicator();
    }
  }

  void _showIndicator() {
    _controller.forward();
    _pulseController.repeat(reverse: true);

    // Auto-hide after duration
    Future.delayed(widget.duration, () {
      if (mounted) {
        _controller.reverse();
        _pulseController.stop();
      }
    });
  }

  @override
  void didUpdateWidget(SwipeIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isVisible != oldWidget.isVisible && widget.isVisible) {
      _showIndicator();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return FadeTransition(
          opacity: _fadeAnimation,
          child: Transform.translate(
            offset: Offset(0, _slideAnimation.value),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface.withOpacity(0.9),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: AnimatedBuilder(
                animation: _pulseAnimation,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _pulseAnimation.value,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.swipe,
                          size: 16,
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withOpacity(0.7),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Two-finger swipe to switch grades',
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurface
                                        .withOpacity(0.7),
                                  ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Gesture-enhanced scroll view with pull-to-refresh
class EnhancedScrollView extends StatefulWidget {
  final Widget child;
  final Future<void> Function()? onRefresh;
  final VoidCallback? onSwipeLeft;
  final VoidCallback? onSwipeRight;
  final bool enableGradeSwitch;
  final ScrollController? controller;

  const EnhancedScrollView({
    super.key,
    required this.child,
    this.onRefresh,
    this.onSwipeLeft,
    this.onSwipeRight,
    this.enableGradeSwitch = false,
    this.controller,
  });

  @override
  State<EnhancedScrollView> createState() => _EnhancedScrollViewState();
}

class _EnhancedScrollViewState extends State<EnhancedScrollView> {
  @override
  Widget build(BuildContext context) {
    Widget scrollView = widget.child;

    // Add pull-to-refresh if callback is provided
    if (widget.onRefresh != null) {
      scrollView = RefreshIndicator(
        onRefresh: widget.onRefresh!,
        displacement: 60,
        color: Theme.of(context).primaryColor,
        backgroundColor: Theme.of(context).colorScheme.surface,
        strokeWidth: 3,
        child: scrollView,
      );
    }

    // Add grade switching gestures if enabled
    if (widget.enableGradeSwitch) {
      scrollView = GradeSwitchGestureDetector(
        onSwipeLeft: widget.onSwipeLeft,
        onSwipeRight: widget.onSwipeRight,
        child: scrollView,
      );
    }

    return scrollView;
  }
}

/// Custom gesture detector for advanced interactions
class AdvancedGestureDetector extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onDoubleTap;
  final VoidCallback? onLongPress;
  final Function(DragUpdateDetails)? onPan;
  final VoidCallback? onPanStart;
  final VoidCallback? onPanEnd;
  final bool enableHaptics;

  const AdvancedGestureDetector({
    super.key,
    required this.child,
    this.onTap,
    this.onDoubleTap,
    this.onLongPress,
    this.onPan,
    this.onPanStart,
    this.onPanEnd,
    this.enableHaptics = true,
  });

  @override
  State<AdvancedGestureDetector> createState() =>
      _AdvancedGestureDetectorState();
}

class _AdvancedGestureDetectorState extends State<AdvancedGestureDetector>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    _controller.forward();
  }

  void _handleTapUp(TapUpDetails details) {
    _controller.reverse();
    if (widget.enableHaptics) {
      HapticFeedback.lightImpact();
    }
    widget.onTap?.call();
  }

  void _handleTapCancel() {
    _controller.reverse();
  }

  void _handleDoubleTap() {
    if (widget.enableHaptics) {
      HapticFeedback.selectionClick();
    }
    widget.onDoubleTap?.call();
  }

  void _handleLongPress() {
    if (widget.enableHaptics) {
      HapticFeedback.heavyImpact();
    }
    widget.onLongPress?.call();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: GestureDetector(
            onTapDown: _handleTapDown,
            onTapUp: _handleTapUp,
            onTapCancel: _handleTapCancel,
            onDoubleTap: widget.onDoubleTap != null ? _handleDoubleTap : null,
            onLongPress: widget.onLongPress != null ? _handleLongPress : null,
            onPanStart:
                widget.onPanStart != null ? (_) => widget.onPanStart!() : null,
            onPanUpdate: widget.onPan,
            onPanEnd:
                widget.onPanEnd != null ? (_) => widget.onPanEnd!() : null,
            child: widget.child,
          ),
        );
      },
    );
  }
}
