import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'dart:io';
import 'dart:async';
import 'dart:math' as math;

class AudioPlayerWidget extends StatefulWidget {
  final File? audioFile;
  final String? audioUrl;
  final String? title;
  final String? subtitle;
  final bool showWaveform;
  final bool autoPlay;
  final Color? primaryColor;
  final Function()? onPlayComplete;
  final Function(Duration position)? onPositionChanged;

  const AudioPlayerWidget({
    super.key,
    this.audioFile,
    this.audioUrl,
    this.title,
    this.subtitle,
    this.showWaveform = false,
    this.autoPlay = false,
    this.primaryColor,
    this.onPlayComplete,
    this.onPositionChanged,
  }) : assert(audioFile != null || audioUrl != null,
            'Either audioFile or audioUrl must be provided');

  @override
  State<AudioPlayerWidget> createState() => _AudioPlayerWidgetState();
}

class _AudioPlayerWidgetState extends State<AudioPlayerWidget>
    with TickerProviderStateMixin {
  late AudioPlayer _audioPlayer;
  late AnimationController _playButtonController;
  late Animation<double> _playButtonAnimation;

  PlayerState _playerState = PlayerState.stopped;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;
  StreamSubscription? _durationSubscription;
  StreamSubscription? _positionSubscription;
  StreamSubscription? _playerCompleteSubscription;
  StreamSubscription? _playerStateSubscription;

  @override
  void initState() {
    super.initState();
    _initializePlayer();
    _setupAnimations();
  }

  void _setupAnimations() {
    _playButtonController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _playButtonAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _playButtonController,
      curve: Curves.easeInOut,
    ));
  }

  Future<void> _initializePlayer() async {
    _audioPlayer = AudioPlayer();

    _durationSubscription = _audioPlayer.onDurationChanged.listen((duration) {
      setState(() {
        _duration = duration;
      });
    });

    _positionSubscription = _audioPlayer.onPositionChanged.listen((position) {
      setState(() {
        _position = position;
      });
      widget.onPositionChanged?.call(position);
    });

    _playerCompleteSubscription = _audioPlayer.onPlayerComplete.listen((_) {
      setState(() {
        _playerState = PlayerState.stopped;
        _position = Duration.zero;
      });
      _playButtonController.reverse();
      widget.onPlayComplete?.call();
    });

    _playerStateSubscription =
        _audioPlayer.onPlayerStateChanged.listen((state) {
      setState(() {
        _playerState = state;
      });
    });

    if (widget.autoPlay) {
      _play();
    }
  }

  Future<void> _play() async {
    try {
      if (widget.audioFile != null) {
        await _audioPlayer.play(DeviceFileSource(widget.audioFile!.path));
      } else if (widget.audioUrl != null) {
        await _audioPlayer.play(UrlSource(widget.audioUrl!));
      }
      _playButtonController.forward();
    } catch (e) {
      _showErrorSnackBar('Failed to play audio: ${e.toString()}');
    }
  }

  Future<void> _pause() async {
    try {
      await _audioPlayer.pause();
      _playButtonController.reverse();
    } catch (e) {
      _showErrorSnackBar('Failed to pause audio: ${e.toString()}');
    }
  }

  Future<void> _stop() async {
    try {
      await _audioPlayer.stop();
      setState(() {
        _position = Duration.zero;
      });
      _playButtonController.reverse();
    } catch (e) {
      _showErrorSnackBar('Failed to stop audio: ${e.toString()}');
    }
  }

  Future<void> _seek(Duration position) async {
    try {
      await _audioPlayer.seek(position);
    } catch (e) {
      _showErrorSnackBar('Failed to seek: ${e.toString()}');
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _playButtonController.dispose();
    _durationSubscription?.cancel();
    _positionSubscription?.cancel();
    _playerCompleteSubscription?.cancel();
    _playerStateSubscription?.cancel();
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = widget.primaryColor ?? theme.primaryColor;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title and subtitle
          if (widget.title != null || widget.subtitle != null) ...[
            if (widget.title != null)
              Text(
                widget.title!,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            if (widget.subtitle != null)
              Text(
                widget.subtitle!,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.textTheme.bodyMedium?.color?.withOpacity(0.7),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            const SizedBox(height: 16),
          ],

          // Waveform or progress bar
          if (widget.showWaveform)
            _buildWaveform(primaryColor)
          else
            _buildProgressBar(primaryColor),

          const SizedBox(height: 16),

          // Controls
          Row(
            children: [
              // Play/Pause button
              AnimatedBuilder(
                animation: _playButtonAnimation,
                builder: (context, child) {
                  return GestureDetector(
                    onTap: () {
                      if (_playerState == PlayerState.playing) {
                        _pause();
                      } else {
                        _play();
                      }
                    },
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: primaryColor,
                        shape: BoxShape.circle,
                      ),
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 200),
                        child: Icon(
                          _playerState == PlayerState.playing
                              ? Icons.pause
                              : Icons.play_arrow,
                          key: ValueKey(_playerState),
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                    ),
                  );
                },
              ),

              const SizedBox(width: 12),

              // Stop button
              IconButton(
                onPressed: _playerState != PlayerState.stopped ? _stop : null,
                icon: Icon(
                  Icons.stop,
                  color: _playerState != PlayerState.stopped
                      ? theme.iconTheme.color
                      : theme.disabledColor,
                ),
              ),

              const Spacer(),

              // Time display
              Text(
                '${_formatDuration(_position)} / ${_formatDuration(_duration)}',
                style: theme.textTheme.bodySmall?.copyWith(
                  fontFamily: 'monospace',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBar(Color primaryColor) {
    return Column(
      children: [
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            trackHeight: 4,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
            overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
            activeTrackColor: primaryColor,
            inactiveTrackColor: primaryColor.withOpacity(0.3),
            thumbColor: primaryColor,
            overlayColor: primaryColor.withOpacity(0.2),
          ),
          child: Slider(
            value: _duration.inMilliseconds > 0
                ? _position.inMilliseconds / _duration.inMilliseconds
                : 0.0,
            onChanged: (value) {
              final position = Duration(
                milliseconds: (value * _duration.inMilliseconds).round(),
              );
              _seek(position);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildWaveform(Color primaryColor) {
    // This is a simplified waveform visualization
    // In a real implementation, you would extract audio waveform data
    return Container(
      height: 60,
      child: CustomPaint(
        painter: SimpleWaveformPainter(
          progress: _duration.inMilliseconds > 0
              ? _position.inMilliseconds / _duration.inMilliseconds
              : 0.0,
          color: primaryColor,
          isPlaying: _playerState == PlayerState.playing,
        ),
        size: Size.infinite,
      ),
    );
  }
}

class SimpleWaveformPainter extends CustomPainter {
  final double progress;
  final Color color;
  final bool isPlaying;

  SimpleWaveformPainter({
    required this.progress,
    required this.color,
    required this.isPlaying,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    final barCount = (size.width / 4).floor();
    final barWidth = 2.0;
    final spacing = 2.0;
    final centerY = size.height / 2;

    for (int i = 0; i < barCount; i++) {
      final x = i * (barWidth + spacing);
      final normalizedPosition = i / barCount;

      // Generate pseudo-random height for waveform bars
      final height =
          (centerY * 0.8) * (0.3 + 0.7 * (1 + math.sin(i * 0.5)).abs());

      // Color bars based on playback progress
      if (normalizedPosition <= progress) {
        paint.color = color;
      } else {
        paint.color = color.withOpacity(0.3);
      }

      canvas.drawLine(
        Offset(x, centerY - height / 2),
        Offset(x, centerY + height / 2),
        paint,
      );
    }

    // Draw progress indicator
    if (isPlaying) {
      final progressX = progress * size.width;
      paint
        ..color = color
        ..strokeWidth = 1;

      canvas.drawLine(
        Offset(progressX, 0),
        Offset(progressX, size.height),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
