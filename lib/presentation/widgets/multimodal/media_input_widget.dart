import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';

enum MediaInputType {
  camera,
  gallery,
  file,
  audio,
  voice,
}

class MediaInputWidget extends StatefulWidget {
  final Function(File file, MediaInputType type)? onFileSelected;
  final Function(String text)? onTextInput;
  final List<MediaInputType> enabledTypes;
  final String? placeholder;
  final bool showTextInput;
  final EdgeInsetsGeometry? padding;
  final Color? backgroundColor;
  final BorderRadius? borderRadius;

  const MediaInputWidget({
    super.key,
    this.onFileSelected,
    this.onTextInput,
    this.enabledTypes = const [
      MediaInputType.camera,
      MediaInputType.gallery,
      MediaInputType.file,
      MediaInputType.voice,
    ],
    this.placeholder,
    this.showTextInput = true,
    this.padding,
    this.backgroundColor,
    this.borderRadius,
  });

  @override
  State<MediaInputWidget> createState() => _MediaInputWidgetState();
}

class _MediaInputWidgetState extends State<MediaInputWidget>
    with TickerProviderStateMixin {
  final TextEditingController _textController = TextEditingController();
  final ImagePicker _imagePicker = ImagePicker();
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    ));
  }

  @override
  void dispose() {
    _textController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<bool> _requestPermission(Permission permission) async {
    final status = await permission.request();
    return status.isGranted;
  }

  Future<void> _showPermissionRationale(
    String title,
    String message,
    Permission permission,
  ) async {
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              final granted = await _requestPermission(permission);
              if (!granted) {
                await openAppSettings();
              }
            },
            child: const Text('Grant Permission'),
          ),
        ],
      ),
    );
  }

  Future<void> _captureFromCamera() async {
    final hasPermission = await _requestPermission(Permission.camera);

    if (!hasPermission) {
      await _showPermissionRationale(
        'Camera Permission Required',
        'This app needs camera access to capture textbook pages and images for learning assistance.',
        Permission.camera,
      );
      return;
    }

    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
        maxWidth: 1920,
        maxHeight: 1080,
      );

      if (image != null) {
        final file = File(image.path);
        widget.onFileSelected?.call(file, MediaInputType.camera);
        _toggleExpansion();
      }
    } catch (e) {
      _showErrorSnackBar('Failed to capture image: ${e.toString()}');
    }
  }

  Future<void> _selectFromGallery() async {
    final hasPermission = await _requestPermission(Permission.photos);

    if (!hasPermission) {
      await _showPermissionRationale(
        'Photo Library Permission Required',
        'This app needs access to your photo library to select images for analysis.',
        Permission.photos,
      );
      return;
    }

    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 1920,
        maxHeight: 1080,
      );

      if (image != null) {
        final file = File(image.path);
        widget.onFileSelected?.call(file, MediaInputType.gallery);
        _toggleExpansion();
      }
    } catch (e) {
      _showErrorSnackBar('Failed to select image: ${e.toString()}');
    }
  }

  Future<void> _pickFile() async {
    final hasPermission = await _requestPermission(Permission.storage);

    if (!hasPermission) {
      await _showPermissionRationale(
        'Storage Permission Required',
        'This app needs storage access to select documents and files.',
        Permission.storage,
      );
      return;
    }

    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx', 'txt', 'jpg', 'jpeg', 'png'],
        allowMultiple: false,
      );

      if (result != null && result.files.isNotEmpty) {
        final file = File(result.files.first.path!);
        widget.onFileSelected?.call(file, MediaInputType.file);
        _toggleExpansion();
      }
    } catch (e) {
      _showErrorSnackBar('Failed to pick file: ${e.toString()}');
    }
  }

  Future<void> _startVoiceRecording() async {
    final hasPermission = await _requestPermission(Permission.microphone);

    if (!hasPermission) {
      await _showPermissionRationale(
        'Microphone Permission Required',
        'This app needs microphone access for voice commands and audio recordings.',
        Permission.microphone,
      );
      return;
    }

    // Navigate to voice recorder widget or show voice recorder dialog
    _showVoiceRecorderDialog();
  }

  void _showVoiceRecorderDialog() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.mic,
                size: 64,
                color: Colors.red,
              ),
              const SizedBox(height: 16),
              const Text(
                'Voice Recording',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Tap to start recording your voice command or reading',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.of(context).pop();
                      // TODO: Implement actual voice recording
                    },
                    icon: const Icon(Icons.mic),
                    label: const Text('Record'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _toggleExpansion() {
    setState(() {
      _isExpanded = !_isExpanded;
    });

    if (_isExpanded) {
      _animationController.forward();
    } else {
      _animationController.reverse();
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        action: SnackBarAction(
          label: 'Dismiss',
          textColor: Colors.white,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: widget.padding ?? const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: widget.backgroundColor ?? Theme.of(context).cardColor,
        borderRadius: widget.borderRadius ?? BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).dividerColor,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (widget.showTextInput) ...[
            TextField(
              controller: _textController,
              decoration: InputDecoration(
                hintText: widget.placeholder ?? 'Type your message...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                suffixIcon: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      onPressed: _toggleExpansion,
                      icon: AnimatedRotation(
                        turns: _isExpanded ? 0.5 : 0,
                        duration: const Duration(milliseconds: 300),
                        child: const Icon(Icons.expand_more),
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        if (_textController.text.isNotEmpty) {
                          widget.onTextInput?.call(_textController.text);
                          _textController.clear();
                        }
                      },
                      icon: const Icon(Icons.send),
                    ),
                  ],
                ),
              ),
              maxLines: null,
              textInputAction: TextInputAction.newline,
              onSubmitted: (text) {
                if (text.isNotEmpty) {
                  widget.onTextInput?.call(text);
                  _textController.clear();
                }
              },
            ),
            const SizedBox(height: 12),
          ],
          ScaleTransition(
            scale: _scaleAnimation,
            child: _isExpanded
                ? _buildMediaInputOptions()
                : const SizedBox.shrink(),
          ),
          if (!widget.showTextInput) _buildMediaInputOptions(),
        ],
      ),
    );
  }

  Widget _buildMediaInputOptions() {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        if (widget.enabledTypes.contains(MediaInputType.camera))
          _buildMediaButton(
            icon: Icons.camera_alt,
            label: 'Camera',
            onTap: _captureFromCamera,
            color: Colors.blue,
          ),
        if (widget.enabledTypes.contains(MediaInputType.gallery))
          _buildMediaButton(
            icon: Icons.photo_library,
            label: 'Gallery',
            onTap: _selectFromGallery,
            color: Colors.green,
          ),
        if (widget.enabledTypes.contains(MediaInputType.file))
          _buildMediaButton(
            icon: Icons.attach_file,
            label: 'File',
            onTap: _pickFile,
            color: Colors.orange,
          ),
        if (widget.enabledTypes.contains(MediaInputType.voice))
          _buildMediaButton(
            icon: Icons.mic,
            label: 'Voice',
            onTap: _startVoiceRecording,
            color: Colors.red,
          ),
      ],
    );
  }

  Widget _buildMediaButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required Color color,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 20,
              color: color,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
