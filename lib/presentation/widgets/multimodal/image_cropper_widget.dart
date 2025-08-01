import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:io';
import 'dart:math' as math;
import 'dart:async';

class ImageCropperWidget extends StatefulWidget {
  final File imageFile;
  final Function(File croppedFile)? onCropComplete;
  final Function()? onCancel;
  final double? aspectRatio;
  final bool allowFreeform;
  final bool showGrid;
  final Color? overlayColor;

  const ImageCropperWidget({
    super.key,
    required this.imageFile,
    this.onCropComplete,
    this.onCancel,
    this.aspectRatio,
    this.allowFreeform = true,
    this.showGrid = true,
    this.overlayColor,
  });

  @override
  State<ImageCropperWidget> createState() => _ImageCropperWidgetState();
}

class _ImageCropperWidgetState extends State<ImageCropperWidget>
    with TickerProviderStateMixin {
  late TransformationController _transformationController;
  late AnimationController _rotationController;
  late Animation<double> _rotationAnimation;

  Rect _cropRect = Rect.zero;
  Size _imageSize = Size.zero;
  double _rotation = 0;
  double _brightness = 0;
  double _contrast = 1;
  double _saturation = 1;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _transformationController = TransformationController();
    _rotationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _rotationAnimation = Tween<double>(
      begin: 0,
      end: math.pi / 2,
    ).animate(CurvedAnimation(
      parent: _rotationController,
      curve: Curves.easeInOut,
    ));

    _loadImage();
  }

  @override
  void dispose() {
    _transformationController.dispose();
    _rotationController.dispose();
    super.dispose();
  }

  Future<void> _loadImage() async {
    final image = Image.file(widget.imageFile);
    final completer = Completer<Size>();

    image.image.resolve(const ImageConfiguration()).addListener(
      ImageStreamListener((info, _) {
        final size = Size(
          info.image.width.toDouble(),
          info.image.height.toDouble(),
        );
        completer.complete(size);
      }),
    );

    final size = await completer.future;
    setState(() {
      _imageSize = size;
      _initializeCropRect();
    });
  }

  void _initializeCropRect() {
    if (_imageSize == Size.zero) return;

    const margin = 50.0;
    final containerSize = Size(
      _imageSize.width - margin * 2,
      _imageSize.height - margin * 2,
    );

    double width, height;

    if (widget.aspectRatio != null) {
      if (containerSize.width / widget.aspectRatio! <= containerSize.height) {
        width = containerSize.width;
        height = width / widget.aspectRatio!;
      } else {
        height = containerSize.height;
        width = height * widget.aspectRatio!;
      }
    } else {
      width = containerSize.width * 0.8;
      height = containerSize.height * 0.8;
    }

    _cropRect = Rect.fromCenter(
      center: Offset(_imageSize.width / 2, _imageSize.height / 2),
      width: width,
      height: height,
    );
  }

  void _rotateCW() {
    setState(() {
      _rotation += math.pi / 2;
    });
    _rotationController.forward().then((_) {
      _rotationController.reset();
    });
  }

  void _rotateCCW() {
    setState(() {
      _rotation -= math.pi / 2;
    });
    _rotationController.forward().then((_) {
      _rotationController.reset();
    });
  }

  void _resetTransformations() {
    setState(() {
      _rotation = 0;
      _brightness = 0;
      _contrast = 1;
      _saturation = 1;
    });
    _transformationController.value = Matrix4.identity();
    _initializeCropRect();
  }

  Future<void> _cropImage() async {
    setState(() {
      _isProcessing = true;
    });

    try {
      // TODO: Implement actual image cropping logic
      // For now, we'll simulate the process
      await Future.delayed(const Duration(seconds: 1));

      // In a real implementation, you would:
      // 1. Apply rotation, brightness, contrast, saturation adjustments
      // 2. Crop the image based on _cropRect
      // 3. Save the processed image to a new file

      widget.onCropComplete?.call(widget.imageFile);
    } catch (e) {
      _showErrorDialog('Failed to crop image: ${e.toString()}');
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Crop Image'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: widget.onCancel,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _resetTransformations,
          ),
          TextButton(
            onPressed: _isProcessing ? null : _cropImage,
            child: _isProcessing
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Text(
                    'Done',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Image viewer with crop overlay
          Expanded(
            child: Container(
              width: double.infinity,
              child: Stack(
                children: [
                  // Image with transformations
                  Center(
                    child: AnimatedBuilder(
                      animation: _rotationAnimation,
                      builder: (context, child) {
                        return Transform.rotate(
                          angle: _rotation,
                          child: ColorFiltered(
                            colorFilter: ColorFilter.matrix(_getColorMatrix()),
                            child: InteractiveViewer(
                              transformationController:
                                  _transformationController,
                              minScale: 0.5,
                              maxScale: 3.0,
                              child: Image.file(
                                widget.imageFile,
                                fit: BoxFit.contain,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  // Crop overlay
                  if (_imageSize != Size.zero)
                    Positioned.fill(
                      child: CustomPaint(
                        painter: CropOverlayPainter(
                          cropRect: _cropRect,
                          imageSize: _imageSize,
                          showGrid: widget.showGrid,
                          overlayColor: widget.overlayColor ?? Colors.black54,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),

          // Control panel
          Container(
            color: Colors.grey[900],
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Rotation controls
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildControlButton(
                      icon: Icons.rotate_left,
                      label: 'Rotate Left',
                      onPressed: _rotateCCW,
                    ),
                    _buildControlButton(
                      icon: Icons.rotate_right,
                      label: 'Rotate Right',
                      onPressed: _rotateCW,
                    ),
                    _buildControlButton(
                      icon: Icons.crop,
                      label: 'Auto Crop',
                      onPressed: () {
                        // TODO: Implement auto crop detection
                      },
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Adjustment sliders
                _buildSlider(
                  label: 'Brightness',
                  value: _brightness,
                  min: -1.0,
                  max: 1.0,
                  onChanged: (value) {
                    setState(() {
                      _brightness = value;
                    });
                  },
                ),

                _buildSlider(
                  label: 'Contrast',
                  value: _contrast,
                  min: 0.0,
                  max: 2.0,
                  onChanged: (value) {
                    setState(() {
                      _contrast = value;
                    });
                  },
                ),

                _buildSlider(
                  label: 'Saturation',
                  value: _saturation,
                  min: 0.0,
                  max: 2.0,
                  onChanged: (value) {
                    setState(() {
                      _saturation = value;
                    });
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          onPressed: onPressed,
          icon: Icon(
            icon,
            color: Colors.white,
            size: 28,
          ),
          style: IconButton.styleFrom(
            backgroundColor: Colors.grey[800],
            padding: const EdgeInsets.all(12),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildSlider({
    required String label,
    required double value,
    required double min,
    required double max,
    required ValueChanged<double> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        Slider(
          value: value,
          min: min,
          max: max,
          onChanged: onChanged,
          activeColor: Theme.of(context).primaryColor,
          inactiveColor: Colors.grey[600],
        ),
      ],
    );
  }

  List<double> _getColorMatrix() {
    // Create a color transformation matrix
    final brightness = _brightness * 255;
    final contrast = _contrast;

    return [
      contrast,
      0,
      0,
      0,
      brightness,
      0,
      contrast,
      0,
      0,
      brightness,
      0,
      0,
      contrast,
      0,
      brightness,
      0,
      0,
      0,
      1,
      0,
    ];
  }
}

class CropOverlayPainter extends CustomPainter {
  final Rect cropRect;
  final Size imageSize;
  final bool showGrid;
  final Color overlayColor;

  CropOverlayPainter({
    required this.cropRect,
    required this.imageSize,
    required this.showGrid,
    required this.overlayColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();

    // Draw overlay
    paint.color = overlayColor;
    canvas.drawPath(
      Path.combine(
        PathOperation.difference,
        Path()..addRect(Rect.fromLTWH(0, 0, size.width, size.height)),
        Path()..addRect(cropRect),
      ),
      paint,
    );

    // Draw crop border
    paint
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawRect(cropRect, paint);

    // Draw grid lines
    if (showGrid) {
      paint
        ..color = Colors.white.withOpacity(0.5)
        ..strokeWidth = 1;

      // Vertical lines
      for (int i = 1; i < 3; i++) {
        final x = cropRect.left + (cropRect.width / 3) * i;
        canvas.drawLine(
          Offset(x, cropRect.top),
          Offset(x, cropRect.bottom),
          paint,
        );
      }

      // Horizontal lines
      for (int i = 1; i < 3; i++) {
        final y = cropRect.top + (cropRect.height / 3) * i;
        canvas.drawLine(
          Offset(cropRect.left, y),
          Offset(cropRect.right, y),
          paint,
        );
      }
    }

    // Draw corner handles
    paint
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    const handleSize = 20.0;
    final corners = [
      cropRect.topLeft,
      cropRect.topRight,
      cropRect.bottomLeft,
      cropRect.bottomRight,
    ];

    for (final corner in corners) {
      canvas.drawRect(
        Rect.fromCenter(
          center: corner,
          width: handleSize,
          height: handleSize,
        ),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
