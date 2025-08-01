import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math' as math;

/// Lottie animation wrapper with enhanced controls
class LottieLoadingWidget extends StatefulWidget {
  final String animationPath;
  final double? width;
  final double? height;
  final bool repeat;
  final bool autoPlay;
  final Duration? duration;
  final AnimationController? controller;
  final VoidCallback? onComplete;

  const LottieLoadingWidget({
    super.key,
    required this.animationPath,
    this.width,
    this.height,
    this.repeat = true,
    this.autoPlay = true,
    this.duration,
    this.controller,
    this.onComplete,
  });

  @override
  State<LottieLoadingWidget> createState() => _LottieLoadingWidgetState();
}

class _LottieLoadingWidgetState extends State<LottieLoadingWidget>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();

    _controller = widget.controller ??
        AnimationController(
          duration: widget.duration ?? const Duration(seconds: 2),
          vsync: this,
        );

    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(_controller);

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        widget.onComplete?.call();
        if (widget.repeat) {
          _controller.repeat();
        }
      }
    });

    if (widget.autoPlay) {
      _controller.forward();
    }
  }

  @override
  void dispose() {
    if (widget.controller == null) {
      _controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Since we don't have lottie dependency, create a custom loading animation
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return SizedBox(
          width: widget.width ?? 100,
          height: widget.height ?? 100,
          child: CustomPaint(
            painter: LoadingAnimationPainter(_animation.value),
          ),
        );
      },
    );
  }
}

/// Custom painter for loading animation (replacing Lottie for now)
class LoadingAnimationPainter extends CustomPainter {
  final double progress;

  LoadingAnimationPainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 3;

    // Draw rotating circles
    final paint = Paint()
      ..color = Colors.blue.withOpacity(0.8)
      ..style = PaintingStyle.fill;

    for (int i = 0; i < 8; i++) {
      final angle = (i * 45 + progress * 360) * (3.14159 / 180);
      final x = center.dx + radius * 0.6 * cos(angle);
      final y = center.dy + radius * 0.6 * sin(angle);

      final opacity = (sin(progress * 6.28 + i * 0.78) + 1) / 2;
      paint.color = Colors.blue.withOpacity(opacity * 0.8);

      canvas.drawCircle(Offset(x, y), 4, paint);
    }
  }

  @override
  bool shouldRepaint(LoadingAnimationPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }

  double cos(double angle) => math.cos(angle);
  double sin(double angle) => math.sin(angle);
}

/// Animation presets for different loading states
enum LoadingAnimationType {
  thinking,
  processing,
  generating,
  uploading,
  downloading,
  success,
  error,
}

class LoadingAnimationPresets {
  static Widget getLoadingAnimation(
    LoadingAnimationType type, {
    double? size,
    Color? color,
  }) {
    switch (type) {
      case LoadingAnimationType.thinking:
        return ThinkingAnimation(size: size, color: color);
      case LoadingAnimationType.processing:
        return ProcessingAnimation(size: size, color: color);
      case LoadingAnimationType.generating:
        return GeneratingAnimation(size: size, color: color);
      case LoadingAnimationType.uploading:
        return UploadAnimation(size: size, color: color);
      case LoadingAnimationType.downloading:
        return DownloadAnimation(size: size, color: color);
      case LoadingAnimationType.success:
        return SuccessCheckAnimation(size: size, color: color);
      case LoadingAnimationType.error:
        return ErrorAnimation(size: size, color: color);
    }
  }
}

/// Thinking animation with brain icon
class ThinkingAnimation extends StatefulWidget {
  final double? size;
  final Color? color;

  const ThinkingAnimation({super.key, this.size, this.color});

  @override
  State<ThinkingAnimation> createState() => _ThinkingAnimationState();
}

class _ThinkingAnimationState extends State<ThinkingAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _pulseAnimation;
  late Animation<double> _rotationAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    _rotationAnimation =
        Tween<double>(begin: 0.0, end: 1.0).animate(_controller);

    _controller.repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = widget.size ?? 50.0;
    final color = widget.color ?? Theme.of(context).primaryColor;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.scale(
          scale: _pulseAnimation.value,
          child: Transform.rotate(
            angle: _rotationAnimation.value * 0.1,
            child: Icon(
              Icons.psychology,
              size: size,
              color: color,
            ),
          ),
        );
      },
    );
  }
}

/// Processing animation with gears
class ProcessingAnimation extends StatefulWidget {
  final double? size;
  final Color? color;

  const ProcessingAnimation({super.key, this.size, this.color});

  @override
  State<ProcessingAnimation> createState() => _ProcessingAnimationState();
}

class _ProcessingAnimationState extends State<ProcessingAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    );

    _controller.repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = widget.size ?? 50.0;
    final color = widget.color ?? Theme.of(context).primaryColor;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.rotate(
          angle: _controller.value * 2 * math.pi,
          child: Icon(
            Icons.settings,
            size: size,
            color: color,
          ),
        );
      },
    );
  }
}

/// Generating animation with sparkles
class GeneratingAnimation extends StatefulWidget {
  final double? size;
  final Color? color;

  const GeneratingAnimation({super.key, this.size, this.color});

  @override
  State<GeneratingAnimation> createState() => _GeneratingAnimationState();
}

class _GeneratingAnimationState extends State<GeneratingAnimation>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late AnimationController _sparkleController;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _sparkleController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _controller.repeat(reverse: true);
    _sparkleController.repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    _sparkleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = widget.size ?? 50.0;
    final color = widget.color ?? Theme.of(context).primaryColor;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return SizedBox(
          width: size,
          height: size,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Transform.scale(
                scale: 0.8 + _controller.value * 0.4,
                child: Icon(
                  Icons.auto_awesome,
                  size: size * 0.6,
                  color: color,
                ),
              ),
              AnimatedBuilder(
                animation: _sparkleController,
                builder: (context, child) {
                  return CustomPaint(
                    size: Size(size, size),
                    painter: SparklePainter(_sparkleController.value, color),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Upload animation with arrow
class UploadAnimation extends StatefulWidget {
  final double? size;
  final Color? color;

  const UploadAnimation({super.key, this.size, this.color});

  @override
  State<UploadAnimation> createState() => _UploadAnimationState();
}

class _UploadAnimationState extends State<UploadAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _moveAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _moveAnimation = Tween<double>(begin: 0.0, end: -10.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    _controller.repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = widget.size ?? 50.0;
    final color = widget.color ?? Theme.of(context).primaryColor;

    return AnimatedBuilder(
      animation: _moveAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _moveAnimation.value),
          child: Icon(
            Icons.cloud_upload,
            size: size,
            color: color,
          ),
        );
      },
    );
  }
}

/// Download animation with arrow
class DownloadAnimation extends StatefulWidget {
  final double? size;
  final Color? color;

  const DownloadAnimation({super.key, this.size, this.color});

  @override
  State<DownloadAnimation> createState() => _DownloadAnimationState();
}

class _DownloadAnimationState extends State<DownloadAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _moveAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _moveAnimation = Tween<double>(begin: 0.0, end: 10.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    _controller.repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = widget.size ?? 50.0;
    final color = widget.color ?? Theme.of(context).primaryColor;

    return AnimatedBuilder(
      animation: _moveAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _moveAnimation.value),
          child: Icon(
            Icons.cloud_download,
            size: size,
            color: color,
          ),
        );
      },
    );
  }
}

/// Error animation with shake effect
class ErrorAnimation extends StatefulWidget {
  final double? size;
  final Color? color;

  const ErrorAnimation({super.key, this.size, this.color});

  @override
  State<ErrorAnimation> createState() => _ErrorAnimationState();
}

class _ErrorAnimationState extends State<ErrorAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _shakeAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _shakeAnimation = Tween<double>(begin: -5.0, end: 5.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticIn),
    );

    _controller.repeat(reverse: true);

    // Stop after a few shakes
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        _controller.stop();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = widget.size ?? 50.0;
    final color = widget.color ?? Colors.red;

    return AnimatedBuilder(
      animation: _shakeAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(_shakeAnimation.value, 0),
          child: Icon(
            Icons.error,
            size: size,
            color: color,
          ),
        );
      },
    );
  }
}

/// Success animation with checkmark
class SuccessCheckAnimation extends StatefulWidget {
  final double? size;
  final Color? color;

  const SuccessCheckAnimation({super.key, this.size, this.color});

  @override
  State<SuccessCheckAnimation> createState() => _SuccessCheckAnimationState();
}

class _SuccessCheckAnimationState extends State<SuccessCheckAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = widget.size ?? 50.0;
    final color = widget.color ?? Colors.green;

    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Icon(
            Icons.check_circle,
            size: size,
            color: color,
          ),
        );
      },
    );
  }
}

/// Custom painter for sparkles
class SparklePainter extends CustomPainter {
  final double progress;
  final Color color;

  SparklePainter(this.progress, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withOpacity(0.6)
      ..style = PaintingStyle.fill;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Draw sparkles around the center
    for (int i = 0; i < 6; i++) {
      final angle = (i * 60 + progress * 360) * (math.pi / 180);
      final sparkleRadius = radius * 0.8;
      final x = center.dx + sparkleRadius * math.cos(angle);
      final y = center.dy + sparkleRadius * math.sin(angle);

      final sparkleSize = 2 + 2 * math.sin(progress * 6.28 + i);
      canvas.drawCircle(Offset(x, y), sparkleSize, paint);
    }
  }

  @override
  bool shouldRepaint(SparklePainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
