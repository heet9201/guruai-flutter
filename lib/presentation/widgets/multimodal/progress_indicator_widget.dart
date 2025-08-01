import 'package:flutter/material.dart';
import 'dart:math' as math;

enum ProgressIndicatorType {
  circular,
  linear,
  wave,
  pulse,
  dots,
}

class ProgressIndicatorWidget extends StatefulWidget {
  final ProgressIndicatorType type;
  final double? value; // null for indeterminate progress
  final String? label;
  final String? subtitle;
  final Color? color;
  final Color? backgroundColor;
  final double size;
  final double strokeWidth;
  final bool showPercentage;
  final TextStyle? labelStyle;
  final TextStyle? subtitleStyle;
  final Duration animationDuration;

  const ProgressIndicatorWidget({
    super.key,
    this.type = ProgressIndicatorType.circular,
    this.value,
    this.label,
    this.subtitle,
    this.color,
    this.backgroundColor,
    this.size = 60,
    this.strokeWidth = 4,
    this.showPercentage = true,
    this.labelStyle,
    this.subtitleStyle,
    this.animationDuration = const Duration(milliseconds: 300),
  });

  @override
  State<ProgressIndicatorWidget> createState() =>
      _ProgressIndicatorWidgetState();
}

class _ProgressIndicatorWidgetState extends State<ProgressIndicatorWidget>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late AnimationController _pulseController;
  late Animation<double> _animation;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
  }

  void _setupAnimations() {
    _controller = AnimationController(
      duration: widget.animationDuration,
      vsync: this,
    );

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _animation = Tween<double>(
      begin: 0,
      end: widget.value ?? 1,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));

    _pulseAnimation = Tween<double>(
      begin: 0.8,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    if (widget.value == null) {
      _controller.repeat();
    } else {
      _controller.forward();
    }

    if (widget.type == ProgressIndicatorType.pulse) {
      _pulseController.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(ProgressIndicatorWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.value != widget.value) {
      _animation = Tween<double>(
        begin: _animation.value,
        end: widget.value ?? 1,
      ).animate(CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ));

      if (widget.value == null) {
        _controller.repeat();
      } else {
        _controller.forward();
      }
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
    final theme = Theme.of(context);
    final primaryColor = widget.color ?? theme.primaryColor;
    final bgColor =
        widget.backgroundColor ?? theme.colorScheme.surface.withOpacity(0.3);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildProgressIndicator(primaryColor, bgColor),
        if (widget.label != null || widget.subtitle != null) ...[
          const SizedBox(height: 12),
          _buildLabels(theme),
        ],
      ],
    );
  }

  Widget _buildProgressIndicator(Color primaryColor, Color backgroundColor) {
    switch (widget.type) {
      case ProgressIndicatorType.circular:
        return _buildCircularIndicator(primaryColor, backgroundColor);
      case ProgressIndicatorType.linear:
        return _buildLinearIndicator(primaryColor, backgroundColor);
      case ProgressIndicatorType.wave:
        return _buildWaveIndicator(primaryColor);
      case ProgressIndicatorType.pulse:
        return _buildPulseIndicator(primaryColor);
      case ProgressIndicatorType.dots:
        return _buildDotsIndicator(primaryColor);
    }
  }

  Widget _buildCircularIndicator(Color primaryColor, Color backgroundColor) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Background circle
          CustomPaint(
            size: Size(widget.size, widget.size),
            painter: CircularProgressPainter(
              progress: 1.0,
              color: backgroundColor,
              strokeWidth: widget.strokeWidth,
            ),
          ),
          // Progress circle
          AnimatedBuilder(
            animation: _animation,
            builder: (context, child) {
              return CustomPaint(
                size: Size(widget.size, widget.size),
                painter: CircularProgressPainter(
                  progress: widget.value ?? _animation.value,
                  color: primaryColor,
                  strokeWidth: widget.strokeWidth,
                  isIndeterminate: widget.value == null,
                ),
              );
            },
          ),
          // Percentage text
          if (widget.showPercentage && widget.value != null)
            Text(
              '${(widget.value! * 100).round()}%',
              style: TextStyle(
                fontSize: widget.size * 0.15,
                fontWeight: FontWeight.bold,
                color: primaryColor,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildLinearIndicator(Color primaryColor, Color backgroundColor) {
    return Container(
      width: widget.size * 3, // Make linear indicators wider
      height: widget.strokeWidth,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(widget.strokeWidth / 2),
      ),
      child: AnimatedBuilder(
        animation: _animation,
        builder: (context, child) {
          return LinearProgressPaint(
            progress: widget.value ?? _animation.value,
            color: primaryColor,
            isIndeterminate: widget.value == null,
          );
        },
      ),
    );
  }

  Widget _buildWaveIndicator(Color primaryColor) {
    return SizedBox(
      width: widget.size,
      height: widget.size * 0.6,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return CustomPaint(
            painter: WaveProgressPainter(
              progress: _controller.value,
              color: primaryColor,
            ),
            size: Size(widget.size, widget.size * 0.6),
          );
        },
      ),
    );
  }

  Widget _buildPulseIndicator(Color primaryColor) {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _pulseAnimation.value,
          child: Container(
            width: widget.size,
            height: widget.size,
            decoration: BoxDecoration(
              color: primaryColor.withOpacity(0.6),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Container(
                width: widget.size * 0.6,
                height: widget.size * 0.6,
                decoration: BoxDecoration(
                  color: primaryColor,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDotsIndicator(Color primaryColor) {
    return SizedBox(
      width: widget.size,
      height: widget.size * 0.3,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(3, (index) {
              final delay = index * 0.2;
              final animationValue = (_controller.value + delay) % 1.0;
              final scale = 0.5 + 0.5 * math.sin(animationValue * 2 * math.pi);

              return Transform.scale(
                scale: scale,
                child: Container(
                  width: widget.size * 0.2,
                  height: widget.size * 0.2,
                  decoration: BoxDecoration(
                    color: primaryColor,
                    shape: BoxShape.circle,
                  ),
                ),
              );
            }),
          );
        },
      ),
    );
  }

  Widget _buildLabels(ThemeData theme) {
    return Column(
      children: [
        if (widget.label != null)
          Text(
            widget.label!,
            style: widget.labelStyle ??
                theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
            textAlign: TextAlign.center,
          ),
        if (widget.subtitle != null) ...[
          const SizedBox(height: 4),
          Text(
            widget.subtitle!,
            style: widget.subtitleStyle ??
                theme.textTheme.bodySmall?.copyWith(
                  color: theme.textTheme.bodySmall?.color?.withOpacity(0.7),
                ),
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );
  }
}

class CircularProgressPainter extends CustomPainter {
  final double progress;
  final Color color;
  final double strokeWidth;
  final bool isIndeterminate;

  CircularProgressPainter({
    required this.progress,
    required this.color,
    required this.strokeWidth,
    this.isIndeterminate = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    if (isIndeterminate) {
      // Draw animated arc for indeterminate progress
      final startAngle = progress * 2 * math.pi;
      const sweepAngle = math.pi;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        false,
        paint,
      );
    } else {
      // Draw progress arc
      const startAngle = -math.pi / 2;
      final sweepAngle = progress * 2 * math.pi;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        false,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class LinearProgressPaint extends StatelessWidget {
  final double progress;
  final Color color;
  final bool isIndeterminate;

  const LinearProgressPaint({
    super.key,
    required this.progress,
    required this.color,
    this.isIndeterminate = false,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (isIndeterminate) {
          // Animated sliding indicator
          final indicatorWidth = constraints.maxWidth * 0.3;
          final position = progress * (constraints.maxWidth + indicatorWidth) -
              indicatorWidth;

          return Stack(
            children: [
              Positioned(
                left: position,
                child: Container(
                  width: indicatorWidth,
                  height: constraints.maxHeight,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius:
                        BorderRadius.circular(constraints.maxHeight / 2),
                  ),
                ),
              ),
            ],
          );
        } else {
          // Fixed progress indicator
          return Align(
            alignment: Alignment.centerLeft,
            child: Container(
              width: constraints.maxWidth * progress,
              height: constraints.maxHeight,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(constraints.maxHeight / 2),
              ),
            ),
          );
        }
      },
    );
  }
}

class WaveProgressPainter extends CustomPainter {
  final double progress;
  final Color color;

  WaveProgressPainter({
    required this.progress,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path();
    final waveHeight = size.height * 0.3;
    final waveLength = size.width / 2;
    final phase = progress * 2 * math.pi;

    path.moveTo(0, size.height / 2);

    for (double x = 0; x <= size.width; x += 2) {
      final y = size.height / 2 +
          waveHeight * math.sin((x / waveLength) * 2 * math.pi + phase);
      path.lineTo(x, y);
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
