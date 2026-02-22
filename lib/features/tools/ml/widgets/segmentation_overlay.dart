import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/ml/ml_notifier.dart';
import '../../../../core/theme/theme_extensions.dart';

/// Interactive segmentation overlay using SAM (Segment Anything Model).
/// Users tap to add positive/negative points, the model generates masks in real-time.
class SegmentationOverlay extends StatefulWidget {
  final Uint8List sourceImage;
  final void Function(Uint8List resultImage) onSave;
  final VoidCallback onDiscard;
  final void Function(Uint8List resultImage)? onSendToCanvas;

  const SegmentationOverlay({
    super.key,
    required this.sourceImage,
    required this.onSave,
    required this.onDiscard,
    this.onSendToCanvas,
  });

  @override
  State<SegmentationOverlay> createState() => _SegmentationOverlayState();
}

class _SegmentationOverlayState extends State<SegmentationOverlay> {
  final List<_SegPoint> _points = [];
  bool _isEncoding = false;
  bool _isDecoding = false;
  Uint8List? _resultPreview;
  Float32List? _previousMaskLogits;
  List<int>? _previousMaskShape;
  String? _error;

  // Mode: positive adds to selection, negative subtracts
  bool _addMode = true;

  @override
  void initState() {
    super.initState();
    _encodeImage();
  }

  Future<void> _encodeImage() async {
    setState(() {
      _isEncoding = true;
      _error = null;
    });
    final ml = context.read<MLNotifier>();
    await ml.encodeImageForSegmentation(widget.sourceImage);
    if (!mounted) return;
    setState(() {
      _isEncoding = false;
      if (!ml.hasEncodedImage) {
        _error = ml.processingError ??
            'Failed to encode image — check that segmentation models are downloaded';
      }
    });
  }

  Future<void> _runSegmentation() async {
    if (_points.isEmpty) return;

    final ml = context.read<MLNotifier>();
    if (!ml.hasEncodedImage) {
      setState(() {
        _error = 'Image not encoded — try re-opening the segment tool';
      });
      return;
    }

    setState(() {
      _isDecoding = true;
      _error = null;
    });

    final positivePoints = _points
        .where((p) => p.isPositive)
        .map((p) => p.offset)
        .toList();
    final negativePoints = _points
        .where((p) => !p.isPositive)
        .map((p) => p.offset)
        .toList();

    final result = await ml.segmentAtPoints(
      positivePoints: positivePoints,
      negativePoints: negativePoints,
      previousMaskLogits: _previousMaskLogits,
      previousMaskShape: _previousMaskShape,
    );

    if (mounted && result != null) {
      setState(() {
        _resultPreview = result.resultImage;
        _previousMaskLogits = result.lowResMask;
        _previousMaskShape = result.lowResMaskShape;
        _isDecoding = false;
        _error = null;
      });
    } else if (mounted) {
      setState(() {
        _isDecoding = false;
        _error = 'Segmentation failed — try different points';
      });
    }
  }

  void _addPoint(Offset normalizedPoint) {
    setState(() {
      _points.add(_SegPoint(offset: normalizedPoint, isPositive: _addMode));
    });
    _runSegmentation();
  }

  void _undoLastPoint() {
    if (_points.isEmpty) return;
    setState(() {
      _points.removeLast();
      if (_points.isEmpty) {
        _resultPreview = null;
        _previousMaskLogits = null;
        _previousMaskShape = null;
      }
    });
    if (_points.isNotEmpty) {
      _previousMaskLogits = null; // Reset logits on undo
      _previousMaskShape = null;
      _runSegmentation();
    }
  }

  void _clearPoints() {
    setState(() {
      _points.clear();
      _resultPreview = null;
      _previousMaskLogits = null;
      _previousMaskShape = null;
    });
  }

  @override
  void dispose() {
    context.read<MLNotifier>().clearSegmentation();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t;

    return Column(
      children: [
        // Preview area
        Expanded(
          child: Container(
            color: t.background,
            child: _isEncoding
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(
                            strokeWidth: 2, color: t.accentEdit),
                        const SizedBox(height: 16),
                        Text(
                          'Encoding image...',
                          style: TextStyle(
                            color: t.textTertiary,
                            fontSize: t.fontSize(10),
                          ),
                        ),
                      ],
                    ),
                  )
                // Encoding failed — show centered error instead of useless image
                : (!context.read<MLNotifier>().hasEncodedImage && _error != null)
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.error_outline,
                                  size: 48,
                                  color: t.accentDanger),
                              const SizedBox(height: 16),
                              Text(
                                _error!,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: t.accentDanger,
                                  fontSize: t.fontSize(10),
                                ),
                              ),
                              const SizedBox(height: 24),
                              TextButton(
                                onPressed: widget.onDiscard,
                                child: Text(
                                  'BACK',
                                  style: TextStyle(
                                    color: t.textTertiary,
                                    fontSize: t.fontSize(9),
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                : LayoutBuilder(
                    builder: (context, constraints) {
                      final ml = context.read<MLNotifier>();
                      final showHint = ml.hasEncodedImage &&
                          _points.isEmpty &&
                          _resultPreview == null;

                      return GestureDetector(
                        onTapUp: (details) {
                          // Compute normalized coordinates within the image
                          final imageSize = _computeImageRect(
                              constraints.biggest, widget.sourceImage);
                          if (imageSize == null) return;

                          final localPoint = details.localPosition;
                          final nx = (localPoint.dx - imageSize.left) /
                              imageSize.width;
                          final ny = (localPoint.dy - imageSize.top) /
                              imageSize.height;

                          if (nx >= 0 && nx <= 1 && ny >= 0 && ny <= 1) {
                            _addPoint(Offset(nx, ny));
                          }
                        },
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            // Checkerboard background
                            CustomPaint(
                              painter: _CheckerboardPainter(),
                              size: Size.infinite,
                            ),
                            // Source image with mask overlay
                            Center(
                              child: FittedBox(
                                child: Stack(
                                  children: [
                                    Image.memory(
                                      _resultPreview ?? widget.sourceImage,
                                      gaplessPlayback: true,
                                    ),
                                    // Point markers
                                    if (_points.isNotEmpty)
                                      Positioned.fill(
                                        child: LayoutBuilder(
                                          builder: (ctx, c) =>
                                              CustomPaint(
                                                painter: _PointsPainter(
                                                  points: _points,
                                                  size: c.biggest,
                                                ),
                                              ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                            // Loading overlay
                            if (_isDecoding)
                              Container(
                                color: Colors.black26,
                                child: Center(
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: t.accentEdit,
                                  ),
                                ),
                              ),
                            // Instructional hint
                            if (showHint)
                              Center(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: Colors.black54,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    'Tap on the image to select a region',
                                    style: TextStyle(
                                      color: t.textMinimal,
                                      fontSize: t.fontSize(9),
                                    ),
                                  ),
                                ),
                              ),
                            // Error banner
                            if (_error != null)
                              Positioned(
                                bottom: 8,
                                left: 8,
                                right: 8,
                                child: Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: t.accentDanger.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(
                                        color: t.accentDanger
                                            .withValues(alpha: 0.4)),
                                  ),
                                  child: Text(
                                    _error!,
                                    style: TextStyle(
                                      color: t.accentDanger,
                                      fontSize: t.fontSize(9),
                                    ),
                                    maxLines: 3,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ),
        // Toolbar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: t.surfaceHigh,
            border: Border(top: BorderSide(color: t.borderSubtle)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Mode toggle + undo + clear
              Row(
                children: [
                  // Add / Remove mode toggle
                  _ModeButton(
                    icon: Icons.add_circle_outline,
                    label: 'ADD',
                    isActive: _addMode,
                    onTap: () => setState(() => _addMode = true),
                    color: Colors.green,
                    t: t,
                  ),
                  const SizedBox(width: 8),
                  _ModeButton(
                    icon: Icons.remove_circle_outline,
                    label: 'REMOVE',
                    isActive: !_addMode,
                    onTap: () => setState(() => _addMode = false),
                    color: Colors.red,
                    t: t,
                  ),
                  const SizedBox(width: 16),
                  Container(width: 1, height: 24, color: t.borderSubtle),
                  const SizedBox(width: 16),
                  // Undo
                  IconButton(
                    icon: Icon(Icons.undo, size: 18, color: t.textTertiary),
                    onPressed: _points.isNotEmpty ? _undoLastPoint : null,
                    tooltip: 'Undo last point',
                    splashRadius: 16,
                  ),
                  // Clear
                  IconButton(
                    icon:
                        Icon(Icons.clear_all, size: 18, color: t.textTertiary),
                    onPressed: _points.isNotEmpty ? _clearPoints : null,
                    tooltip: 'Clear all points',
                    splashRadius: 16,
                  ),
                  const Spacer(),
                  // Point count
                  Text(
                    '${_points.length} point${_points.length == 1 ? '' : 's'}',
                    style: TextStyle(
                      color: t.textMinimal,
                      fontSize: t.fontSize(8),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // Action buttons
              Row(
                children: [
                  // Discard
                  TextButton(
                    onPressed: widget.onDiscard,
                    child: Text(
                      'DISCARD',
                      style: TextStyle(
                        color: t.textDisabled,
                        fontSize: t.fontSize(9),
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                  const Spacer(),
                  // Send to Canvas
                  if (widget.onSendToCanvas != null && _resultPreview != null)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: OutlinedButton(
                        onPressed: () =>
                            widget.onSendToCanvas!(_resultPreview!),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: t.accentEdit,
                          side: BorderSide(color: t.accentEdit),
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          textStyle: TextStyle(
                            fontSize: t.fontSize(9),
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1,
                          ),
                        ),
                        child: const Text('CANVAS'),
                      ),
                    ),
                  // Save
                  ElevatedButton(
                    onPressed: _resultPreview != null
                        ? () => widget.onSave(_resultPreview!)
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: t.accentEdit,
                      foregroundColor: t.textPrimary,
                      disabledBackgroundColor: t.surfaceHigh,
                      disabledForegroundColor: t.textMinimal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      textStyle: TextStyle(
                        fontSize: t.fontSize(9),
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                      ),
                    ),
                    child: const Text('SAVE'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Rect? _computeImageRect(Size containerSize, Uint8List imageBytes) {
    // We rely on FittedBox centering the image — approximate the image rect
    // by decoding the image dimensions or using the container ratio
    final ml = context.read<MLNotifier>();
    final embeddings = ml.samEmbeddings;
    if (embeddings == null) return null;

    final imgW = embeddings.originalWidth.toDouble();
    final imgH = embeddings.originalHeight.toDouble();
    final containerRatio = containerSize.width / containerSize.height;
    final imageRatio = imgW / imgH;

    double displayW, displayH;
    if (imageRatio > containerRatio) {
      displayW = containerSize.width;
      displayH = containerSize.width / imageRatio;
    } else {
      displayH = containerSize.height;
      displayW = containerSize.height * imageRatio;
    }

    final offsetX = (containerSize.width - displayW) / 2;
    final offsetY = (containerSize.height - displayH) / 2;
    return Rect.fromLTWH(offsetX, offsetY, displayW, displayH);
  }
}

class _SegPoint {
  final Offset offset; // normalized 0-1
  final bool isPositive;

  const _SegPoint({required this.offset, required this.isPositive});
}

class _ModeButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;
  final Color color;
  final dynamic t;

  const _ModeButton({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
    required this.color,
    required this.t,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isActive ? color.withValues(alpha: 0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: isActive ? color : Colors.transparent,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: isActive ? color : t.textTertiary),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                color: isActive ? color : t.textTertiary,
                fontSize: t.fontSize(8),
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PointsPainter extends CustomPainter {
  final List<_SegPoint> points;
  final Size size;

  _PointsPainter({required this.points, required this.size});

  @override
  void paint(Canvas canvas, Size canvasSize) {
    for (final pt in points) {
      final x = pt.offset.dx * size.width;
      final y = pt.offset.dy * size.height;

      // Outer ring
      final ringPaint = Paint()
        ..color = pt.isPositive ? Colors.green : Colors.red
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;
      canvas.drawCircle(Offset(x, y), 8, ringPaint);

      // Inner dot
      final dotPaint = Paint()
        ..color = pt.isPositive ? Colors.green : Colors.red
        ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(x, y), 3, dotPaint);

      // White outline for visibility
      final outlinePaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1;
      canvas.drawCircle(Offset(x, y), 9, outlinePaint);
    }
  }

  @override
  bool shouldRepaint(_PointsPainter old) =>
      old.points.length != points.length || old.size != size;
}

class _CheckerboardPainter extends CustomPainter {
  static const _cellSize = 12.0;
  static const _lightColor = Color(0xFF3A3A3A);
  static const _darkColor = Color(0xFF2A2A2A);

  @override
  void paint(Canvas canvas, Size size) {
    final lightPaint = Paint()..color = _lightColor;
    final darkPaint = Paint()..color = _darkColor;

    for (double y = 0; y < size.height; y += _cellSize) {
      for (double x = 0; x < size.width; x += _cellSize) {
        final col = (x / _cellSize).floor();
        final row = (y / _cellSize).floor();
        final paint = (col + row) % 2 == 0 ? lightPaint : darkPaint;
        canvas.drawRect(
          Rect.fromLTWH(x, y, _cellSize, _cellSize),
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
