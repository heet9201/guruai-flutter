import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Animated loading states for AI content generation
class AILoadingAnimation extends StatefulWidget {
  final String message;
  final bool isLoading;
  final Duration duration;
  final Color? color;

  const AILoadingAnimation({
    super.key,
    this.message = 'Generating content...',
    required this.isLoading,
    this.duration = const Duration(milliseconds: 1500),
    this.color,
  });

  @override
  State<AILoadingAnimation> createState() => _AILoadingAnimationState();
}

class _AILoadingAnimationState extends State<AILoadingAnimation>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _dotsController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _dotsAnimation;

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      duration: widget.duration,
      vsync: this,
    );

    _dotsController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _dotsAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _dotsController, curve: Curves.easeInOut),
    );

    if (widget.isLoading) {
      _startAnimations();
    }
  }

  void _startAnimations() {
    _pulseController.repeat(reverse: true);
    _dotsController.repeat();
  }

  void _stopAnimations() {
    _pulseController.stop();
    _dotsController.stop();
  }

  @override
  void didUpdateWidget(AILoadingAnimation oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isLoading != oldWidget.isLoading) {
      if (widget.isLoading) {
        _startAnimations();
      } else {
        _stopAnimations();
      }
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _dotsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isLoading) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final color = widget.color ?? theme.primaryColor;

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Brain/AI icon with pulse animation
          AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _pulseAnimation.value,
                child: Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        color.withOpacity(0.3),
                        color.withOpacity(0.1),
                        Colors.transparent,
                      ],
                    ),
                  ),
                  child: Icon(
                    Icons.psychology,
                    size: 30,
                    color: color,
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 16),

          // Message with animated dots
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                widget.message,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w500,
                ),
              ),
              AnimatedBuilder(
                animation: _dotsAnimation,
                builder: (context, child) {
                  return Row(
                    mainAxisSize: MainAxisSize.min,
                    children: List.generate(3, (index) {
                      final delay = index * 0.33;
                      final progress =
                          (_dotsAnimation.value - delay).clamp(0.0, 1.0);
                      final opacity =
                          progress < 0.5 ? progress * 2 : (1.0 - progress) * 2;

                      return Opacity(
                        opacity: opacity,
                        child: Text(
                          '.',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: color,
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                          ),
                        ),
                      );
                    }),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Success animation for completed actions
class SuccessAnimation extends StatefulWidget {
  final bool isVisible;
  final String message;
  final Duration duration;
  final VoidCallback? onComplete;

  const SuccessAnimation({
    super.key,
    required this.isVisible,
    this.message = 'Success!',
    this.duration = const Duration(milliseconds: 2000),
    this.onComplete,
  });

  @override
  State<SuccessAnimation> createState() => _SuccessAnimationState();
}

class _SuccessAnimationState extends State<SuccessAnimation>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _checkAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.3, curve: Curves.elasticOut),
      ),
    );

    _checkAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.2, 0.5, curve: Curves.easeOut),
      ),
    );

    _fadeAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.7, 1.0, curve: Curves.easeOut),
      ),
    );

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        widget.onComplete?.call();
      }
    });

    if (widget.isVisible) {
      _controller.forward();
      HapticFeedback.heavyImpact();
    }
  }

  @override
  void didUpdateWidget(SuccessAnimation oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isVisible && !oldWidget.isVisible) {
      _controller.forward(from: 0.0);
      HapticFeedback.heavyImpact();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isVisible) return const SizedBox.shrink();

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return FadeTransition(
          opacity: _fadeAnimation,
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Success circle with checkmark
                ScaleTransition(
                  scale: _scaleAnimation,
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.green,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.green.withOpacity(0.3),
                          blurRadius: 20,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: AnimatedBuilder(
                      animation: _checkAnimation,
                      builder: (context, child) {
                        return CustomPaint(
                          painter: CheckmarkPainter(_checkAnimation.value),
                        );
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Success message
                Text(
                  widget.message,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.green,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Custom painter for animated checkmark
class CheckmarkPainter extends CustomPainter {
  final double progress;

  CheckmarkPainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..strokeWidth = 4.0
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final path = Path();

    // Draw checkmark
    final centerX = size.width / 2;
    final centerY = size.height / 2;

    // First line of checkmark
    final firstLineProgress = (progress * 2).clamp(0.0, 1.0);
    path.moveTo(centerX - 10, centerY);
    path.lineTo(
      centerX - 10 + (7 * firstLineProgress),
      centerY + (7 * firstLineProgress),
    );

    // Second line of checkmark
    if (progress > 0.5) {
      final secondLineProgress = ((progress - 0.5) * 2).clamp(0.0, 1.0);
      path.moveTo(centerX - 3, centerY + 7);
      path.lineTo(
        centerX - 3 + (13 * secondLineProgress),
        centerY + 7 - (13 * secondLineProgress),
      );
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CheckmarkPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

/// Staggered list animation
class StaggeredListAnimation extends StatefulWidget {
  final List<Widget> children;
  final Duration staggerDelay;
  final Duration itemDuration;
  final bool isVisible;

  const StaggeredListAnimation({
    super.key,
    required this.children,
    this.staggerDelay = const Duration(milliseconds: 100),
    this.itemDuration = const Duration(milliseconds: 400),
    this.isVisible = true,
  });

  @override
  State<StaggeredListAnimation> createState() => _StaggeredListAnimationState();
}

class _StaggeredListAnimationState extends State<StaggeredListAnimation>
    with TickerProviderStateMixin {
  late List<AnimationController> _controllers;
  late List<Animation<double>> _fadeAnimations;
  late List<Animation<Offset>> _slideAnimations;

  @override
  void initState() {
    super.initState();

    _controllers = List.generate(
      widget.children.length,
      (index) => AnimationController(
        duration: widget.itemDuration,
        vsync: this,
      ),
    );

    _fadeAnimations = _controllers
        .map(
          (controller) => Tween<double>(begin: 0.0, end: 1.0).animate(
            CurvedAnimation(parent: controller, curve: Curves.easeOut),
          ),
        )
        .toList();

    _slideAnimations = _controllers
        .map(
          (controller) =>
              Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero)
                  .animate(
            CurvedAnimation(parent: controller, curve: Curves.easeOut),
          ),
        )
        .toList();

    if (widget.isVisible) {
      _startAnimations();
    }
  }

  void _startAnimations() {
    for (int i = 0; i < _controllers.length; i++) {
      Future.delayed(widget.staggerDelay * i, () {
        if (mounted) {
          _controllers[i].forward();
        }
      });
    }
  }

  @override
  void didUpdateWidget(StaggeredListAnimation oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isVisible != oldWidget.isVisible) {
      if (widget.isVisible) {
        _startAnimations();
      } else {
        for (final controller in _controllers) {
          controller.reverse();
        }
      }
    }
  }

  @override
  void dispose() {
    for (final controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(widget.children.length, (index) {
        return AnimatedBuilder(
          animation: _controllers[index],
          builder: (context, child) {
            return FadeTransition(
              opacity: _fadeAnimations[index],
              child: SlideTransition(
                position: _slideAnimations[index],
                child: widget.children[index],
              ),
            );
          },
        );
      }),
    );
  }
}
