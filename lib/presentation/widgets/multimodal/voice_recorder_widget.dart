import 'package:flutter/material.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'dart:async';
import 'dart:math' as math;

class VoiceRecorderWidget extends StatefulWidget {
  final Function(File audioFile, Duration duration)? onRecordingComplete;
  final Function(String text)? onTranscriptionComplete;
  final Duration? maxDuration;
  final bool showWaveform;
  final bool enableTranscription;
  final Color? primaryColor;
  final double? height;

  const VoiceRecorderWidget({
    super.key,
    this.onRecordingComplete,
    this.onTranscriptionComplete,
    this.maxDuration = const Duration(minutes: 5),
    this.showWaveform = true,
    this.enableTranscription = true,
    this.primaryColor,
    this.height = 200,
  });

  @override
  State<VoiceRecorderWidget> createState() => _VoiceRecorderWidgetState();
}

class _VoiceRecorderWidgetState extends State<VoiceRecorderWidget>
    with TickerProviderStateMixin {
  late FlutterSoundRecorder _recorder;
  late AnimationController _pulseController;
  late AnimationController _waveController;
  late Animation<double> _pulseAnimation;

  bool _isRecording = false;
  bool _isPaused = false;
  bool _isInitialized = false;
  Duration _recordingDuration = Duration.zero;
  Timer? _timer;
  String? _currentRecordingPath;

  // Waveform data
  List<double> _waveformData = [];
  final int _maxWaveformBars = 50;

  @override
  void initState() {
    super.initState();
    _initializeRecorder();
    _setupAnimations();
  }

  void _setupAnimations() {
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _waveController = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));
  }

  Future<void> _initializeRecorder() async {
    _recorder = FlutterSoundRecorder();

    try {
      await _recorder.openRecorder();
      setState(() {
        _isInitialized = true;
      });
    } catch (e) {
      print('Failed to initialize recorder: $e');
    }
  }

  Future<bool> _requestMicrophonePermission() async {
    final permission = await Permission.microphone.request();
    return permission.isGranted;
  }

  Future<void> _startRecording() async {
    if (!_isInitialized) {
      await _initializeRecorder();
    }

    final hasPermission = await _requestMicrophonePermission();
    if (!hasPermission) {
      _showPermissionDialog();
      return;
    }

    try {
      final directory = await getTemporaryDirectory();
      _currentRecordingPath =
          '${directory.path}/recording_${DateTime.now().millisecondsSinceEpoch}.aac';

      await _recorder.startRecorder(
        toFile: _currentRecordingPath,
        codec: Codec.aacADTS,
      );

      setState(() {
        _isRecording = true;
        _recordingDuration = Duration.zero;
      });

      _pulseController.repeat(reverse: true);
      _startTimer();
      _startWaveformSimulation();
    } catch (e) {
      print('Failed to start recording: $e');
    }
  }

  Future<void> _stopRecording() async {
    try {
      final path = await _recorder.stopRecorder();

      setState(() {
        _isRecording = false;
        _isPaused = false;
      });

      _pulseController.stop();
      _timer?.cancel();

      if (path != null && _currentRecordingPath != null) {
        final file = File(_currentRecordingPath!);
        if (await file.exists()) {
          widget.onRecordingComplete?.call(file, _recordingDuration);

          if (widget.enableTranscription) {
            _performTranscription(file);
          }
        }
      }

      _resetRecording();
    } catch (e) {
      print('Failed to stop recording: $e');
    }
  }

  Future<void> _pauseRecording() async {
    try {
      await _recorder.pauseRecorder();
      setState(() {
        _isPaused = true;
      });
      _pulseController.stop();
      _timer?.cancel();
    } catch (e) {
      print('Failed to pause recording: $e');
    }
  }

  Future<void> _resumeRecording() async {
    try {
      await _recorder.resumeRecorder();
      setState(() {
        _isPaused = false;
      });
      _pulseController.repeat(reverse: true);
      _startTimer();
    } catch (e) {
      print('Failed to resume recording: $e');
    }
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (_isRecording && !_isPaused) {
        setState(() {
          _recordingDuration = Duration(milliseconds: timer.tick * 100);
        });

        if (widget.maxDuration != null &&
            _recordingDuration >= widget.maxDuration!) {
          _stopRecording();
        }
      }
    });
  }

  void _startWaveformSimulation() {
    Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (_isRecording && !_isPaused) {
        setState(() {
          // Simulate waveform data
          final amplitude = 0.3 + (math.Random().nextDouble() * 0.7);
          _waveformData.add(amplitude);

          if (_waveformData.length > _maxWaveformBars) {
            _waveformData.removeAt(0);
          }
        });
      } else {
        timer.cancel();
      }
    });
  }

  void _resetRecording() {
    setState(() {
      _recordingDuration = Duration.zero;
      _waveformData.clear();
      _currentRecordingPath = null;
    });
  }

  Future<void> _performTranscription(File audioFile) async {
    // TODO: Implement actual speech-to-text transcription
    // This is a placeholder for the transcription functionality

    // Simulate transcription delay
    await Future.delayed(const Duration(seconds: 2));

    // Mock transcription result
    const mockTranscription =
        "This is a sample transcription of the recorded audio.";
    widget.onTranscriptionComplete?.call(mockTranscription);
  }

  void _showPermissionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Microphone Permission Required'),
        content: const Text(
          'This app needs microphone access to record audio. Please grant permission in the app settings.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              openAppSettings();
            },
            child: const Text('Settings'),
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    final milliseconds = (duration.inMilliseconds % 1000) ~/ 10;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}.${milliseconds.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _waveController.dispose();
    _timer?.cancel();
    _recorder.closeRecorder();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = widget.primaryColor ?? theme.primaryColor;

    return Container(
      height: widget.height,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          // Status indicator
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: _isRecording
                          ? (_isPaused ? Colors.orange : Colors.red)
                          : Colors.grey,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _isRecording
                        ? (_isPaused ? 'Paused' : 'Recording')
                        : 'Ready',
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      color: theme.textTheme.bodyLarge?.color,
                    ),
                  ),
                ],
              ),
              Text(
                _formatDuration(_recordingDuration),
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: primaryColor,
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Waveform visualization
          if (widget.showWaveform) ...[
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: _buildWaveform(primaryColor),
              ),
            ),
            const SizedBox(height: 20),
          ],

          // Control buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // Delete/Reset button
              if (_isRecording || _currentRecordingPath != null)
                _buildControlButton(
                  icon: Icons.delete,
                  color: Colors.red,
                  onPressed: () {
                    if (_isRecording) {
                      _stopRecording();
                    }
                    _resetRecording();
                  },
                ),

              // Pause/Resume button
              if (_isRecording)
                _buildControlButton(
                  icon: _isPaused ? Icons.play_arrow : Icons.pause,
                  color: Colors.orange,
                  onPressed: _isPaused ? _resumeRecording : _pauseRecording,
                ),

              // Record/Stop button
              AnimatedBuilder(
                animation: _pulseAnimation,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _isRecording ? _pulseAnimation.value : 1.0,
                    child: _buildControlButton(
                      icon: _isRecording ? Icons.stop : Icons.mic,
                      color: _isRecording ? Colors.red : primaryColor,
                      onPressed:
                          _isRecording ? _stopRecording : _startRecording,
                      size: 64,
                    ),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWaveform(Color color) {
    return CustomPaint(
      painter: WaveformPainter(
        waveformData: _waveformData,
        color: color,
        isRecording: _isRecording && !_isPaused,
      ),
      size: Size.infinite,
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
    double size = 48,
  }) {
    return Material(
      color: color.withOpacity(0.1),
      borderRadius: BorderRadius.circular(size / 2),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(size / 2),
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            border: Border.all(color: color, width: 2),
            borderRadius: BorderRadius.circular(size / 2),
          ),
          child: Icon(
            icon,
            color: color,
            size: size * 0.5,
          ),
        ),
      ),
    );
  }
}

class WaveformPainter extends CustomPainter {
  final List<double> waveformData;
  final Color color;
  final bool isRecording;

  WaveformPainter({
    required this.waveformData,
    required this.color,
    required this.isRecording,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (waveformData.isEmpty) return;

    final paint = Paint()
      ..color = color.withOpacity(0.7)
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    final barWidth = size.width / waveformData.length;
    final centerY = size.height / 2;

    for (int i = 0; i < waveformData.length; i++) {
      final barHeight = waveformData[i] * size.height * 0.8;
      final x = i * barWidth + barWidth / 2;

      // Add gradient effect for active recording
      if (isRecording && i >= waveformData.length - 5) {
        paint.color = color;
      } else {
        paint.color = color.withOpacity(0.5);
      }

      canvas.drawLine(
        Offset(x, centerY - barHeight / 2),
        Offset(x, centerY + barHeight / 2),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
