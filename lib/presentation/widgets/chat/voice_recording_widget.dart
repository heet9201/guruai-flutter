import 'package:flutter/material.dart';
import 'dart:math';

class VoiceRecordingWidget extends StatefulWidget {
  final bool isRecording;
  final Duration duration;
  final List<double> waveformData;
  final VoidCallback? onStop;
  final VoidCallback? onCancel;

  const VoiceRecordingWidget({
    super.key,
    required this.isRecording,
    required this.duration,
    this.waveformData = const [],
    this.onStop,
    this.onCancel,
  });

  @override
  State<VoiceRecordingWidget> createState() => _VoiceRecordingWidgetState();
}

class _VoiceRecordingWidgetState extends State<VoiceRecordingWidget>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _waveController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _waveController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    if (widget.isRecording) {
      _pulseController.repeat(reverse: true);
      _waveController.repeat();
    }
  }

  @override
  void didUpdateWidget(VoiceRecordingWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isRecording && !oldWidget.isRecording) {
      _pulseController.repeat(reverse: true);
      _waveController.repeat();
    } else if (!widget.isRecording && oldWidget.isRecording) {
      _pulseController.stop();
      _waveController.stop();
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _waveController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      height: 120,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              AnimatedBuilder(
                animation: _pulseAnimation,
                builder: (context, child) {
                  return Transform.scale(
                    scale: widget.isRecording ? _pulseAnimation.value : 1.0,
                    child: Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                        boxShadow: widget.isRecording
                            ? [
                                BoxShadow(
                                  color: Colors.red.withOpacity(0.3),
                                  blurRadius: 10,
                                  spreadRadius: 5,
                                ),
                              ]
                            : null,
                      ),
                      child: const Icon(
                        Icons.mic,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.isRecording ? 'Recording...' : 'Tap to record',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: widget.isRecording
                            ? Colors.red
                            : theme.colorScheme.onSurface,
                      ),
                    ),
                    Text(
                      _formatDuration(widget.duration),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              if (widget.isRecording) ...[
                IconButton(
                  onPressed: widget.onCancel,
                  icon: const Icon(Icons.close, color: Colors.grey),
                ),
                IconButton(
                  onPressed: widget.onStop,
                  icon: const Icon(Icons.send, color: Colors.blue),
                ),
              ],
            ],
          ),
          const SizedBox(height: 12),
          _buildWaveform(context),
        ],
      ),
    );
  }

  Widget _buildWaveform(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      height: 30,
      child: widget.waveformData.isNotEmpty
          ? CustomPaint(
              size: const Size(double.infinity, 30),
              painter: WaveformPainter(
                waveformData: widget.waveformData,
                color:
                    widget.isRecording ? Colors.red : theme.colorScheme.primary,
                isAnimating: widget.isRecording,
                animationValue: _waveController.value,
              ),
            )
          : _buildStaticWaveform(context),
    );
  }

  Widget _buildStaticWaveform(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(20, (index) {
        final height =
            widget.isRecording ? 4.0 + Random().nextDouble() * 20 : 8.0;

        return AnimatedContainer(
          duration: const Duration(milliseconds: 100),
          width: 2,
          height: height,
          margin: const EdgeInsets.symmetric(horizontal: 1),
          decoration: BoxDecoration(
            color: widget.isRecording
                ? Colors.red.withOpacity(0.7)
                : theme.colorScheme.surfaceVariant,
            borderRadius: BorderRadius.circular(1),
          ),
        );
      }),
    );
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
}

class WaveformPainter extends CustomPainter {
  final List<double> waveformData;
  final Color color;
  final bool isAnimating;
  final double animationValue;

  WaveformPainter({
    required this.waveformData,
    required this.color,
    required this.isAnimating,
    required this.animationValue,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2.0
      ..style = PaintingStyle.fill;

    final barWidth = size.width / waveformData.length;

    for (int i = 0; i < waveformData.length; i++) {
      final barHeight = waveformData[i] * size.height;
      final opacity = isAnimating
          ? (0.3 + 0.7 * sin(animationValue * 2 * pi + i * 0.5)).abs()
          : 1.0;

      paint.color = color.withOpacity(opacity);

      final rect = Rect.fromLTWH(
        i * barWidth,
        (size.height - barHeight) / 2,
        barWidth - 1,
        barHeight,
      );

      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(1)),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(WaveformPainter oldDelegate) {
    return oldDelegate.waveformData != waveformData ||
        oldDelegate.isAnimating != isAnimating ||
        oldDelegate.animationValue != animationValue;
  }
}
