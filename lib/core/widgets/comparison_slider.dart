import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../theme/theme_extensions.dart';
import '../theme/vision_tokens.dart';

/// A reusable before/after comparison slider with zoom/pan support.
///
/// Draws two images side by side with a draggable vertical divider.
/// Supports pinch-to-zoom and pan via [InteractiveViewer].
class ComparisonSlider extends StatefulWidget {
  final Uint8List beforeBytes;
  final Uint8List afterBytes;
  final double initialPosition;
  final String? beforeLabel;
  final String? afterLabel;

  const ComparisonSlider({
    super.key,
    required this.beforeBytes,
    required this.afterBytes,
    this.initialPosition = 0.5,
    this.beforeLabel,
    this.afterLabel,
  });

  @override
  State<ComparisonSlider> createState() => _ComparisonSliderState();
}

class _ComparisonSliderState extends State<ComparisonSlider> {
  late double _sliderPosition;
  final TransformationController _transformController =
      TransformationController();
  final GlobalKey _viewportKey = GlobalKey();
  ui.Image? _beforeImage;
  ui.Image? _afterImage;
  bool _loading = true;
  bool _initialTransformSet = false;

  @override
  void initState() {
    super.initState();
    _sliderPosition = widget.initialPosition;
    _transformController.addListener(_onTransformChanged);
    _decodeImages();
  }

  @override
  void didUpdateWidget(ComparisonSlider oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.beforeBytes != widget.beforeBytes ||
        oldWidget.afterBytes != widget.afterBytes) {
      _initialTransformSet = false;
      _decodeImages();
    }
  }

  @override
  void dispose() {
    _transformController.removeListener(_onTransformChanged);
    _transformController.dispose();
    _beforeImage?.dispose();
    _afterImage?.dispose();
    super.dispose();
  }

  void _onTransformChanged() {
    setState(() {});
  }

  Future<void> _decodeImages() async {
    setState(() => _loading = true);
    final before = await _decodeImage(widget.beforeBytes);
    final after = await _decodeImage(widget.afterBytes);
    if (mounted) {
      _beforeImage?.dispose();
      _afterImage?.dispose();
      setState(() {
        _beforeImage = before;
        _afterImage = after;
        _loading = false;
      });
    }
  }

  Future<ui.Image> _decodeImage(Uint8List bytes) async {
    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    return frame.image;
  }

  void _updateSliderFromGlobal(
      Offset globalPosition, BoxConstraints constraints) {
    final renderBox =
        _viewportKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return;
    final local = renderBox.globalToLocal(globalPosition);
    setState(() {
      _sliderPosition =
          (local.dx / constraints.maxWidth).clamp(0.0, 1.0);
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t;

    if (_loading) {
      return Center(child: CircularProgressIndicator(color: t.accent));
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        return _buildBody(constraints, t);
      },
    );
  }

  Widget _buildBody(BoxConstraints constraints, VisionTokens t) {
    final afterW = _afterImage!.width.toDouble();
    final afterH = _afterImage!.height.toDouble();

    // Use the larger dimensions as the canvas size
    final canvasW = max(afterW, _beforeImage!.width.toDouble());
    final canvasH = max(afterH, _beforeImage!.height.toDouble());

    // Fit-to-screen: compute initial transform once.
    // Remove listener temporarily to avoid setState during build.
    if (!_initialTransformSet) {
      _initialTransformSet = true;
      final scaleX = constraints.maxWidth / canvasW;
      final scaleY = constraints.maxHeight / canvasH;
      final scale = min(scaleX, scaleY);
      final dx = (constraints.maxWidth - canvasW * scale) / 2;
      final dy = (constraints.maxHeight - canvasH * scale) / 2;
      _transformController.removeListener(_onTransformChanged);
      _transformController.value =
          Matrix4.translationValues(dx, dy, 0) *
              Matrix4.diagonal3Values(scale, scale, 1);
      _transformController.addListener(_onTransformChanged);
    }

    // Convert screen-space slider to content-space fraction
    final inverse = _transformController.value.clone()..invert();
    final screenX = _sliderPosition * constraints.maxWidth;
    final contentX =
        MatrixUtils.transformPoint(inverse, Offset(screenX, 0)).dx;
    final contentFraction = (contentX / canvasW).clamp(0.0, 1.0);

    // Narrow slider hit area centered on handle
    final sliderScreenX = _sliderPosition * constraints.maxWidth;
    const handleWidth = 60.0;

    return Stack(
      key: _viewportKey,
      children: [
        // Interactive viewer with both images
        InteractiveViewer(
          transformationController: _transformController,
          maxScale: 16.0,
          minScale: 0.1,
          constrained: false,
          child: SizedBox(
            width: canvasW,
            height: canvasH,
            child: CustomPaint(
              painter: _ComparisonPainter(
                before: _beforeImage!,
                after: _afterImage!,
                sliderFraction: contentFraction,
                canvasSize: Size(canvasW, canvasH),
              ),
              size: Size(canvasW, canvasH),
            ),
          ),
        ),
        // Slider line visual (no hit testing)
        Positioned.fill(
          child: IgnorePointer(
            child: CustomPaint(
              painter: _SliderLinePainter(
                fraction: _sliderPosition,
                color: t.accent,
              ),
            ),
          ),
        ),
        // Slider drag handle (narrow hit area around the line)
        Positioned(
          left: sliderScreenX - handleWidth / 2,
          top: 0,
          bottom: 0,
          width: handleWidth,
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onHorizontalDragStart: (details) {
              _updateSliderFromGlobal(details.globalPosition, constraints);
            },
            onHorizontalDragUpdate: (details) {
              _updateSliderFromGlobal(details.globalPosition, constraints);
            },
          ),
        ),
        // Labels
        if (widget.beforeLabel != null)
          Positioned(
            left: 8,
            bottom: 8,
            child: _buildLabel(widget.beforeLabel!, t),
          ),
        if (widget.afterLabel != null)
          Positioned(
            right: 8,
            bottom: 8,
            child: _buildLabel(widget.afterLabel!, t),
          ),
      ],
    );
  }

  Widget _buildLabel(String text, VisionTokens t) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(2),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: Colors.white70,
          fontSize: t.fontSize(10),
          fontWeight: FontWeight.bold,
          letterSpacing: 2,
        ),
      ),
    );
  }
}

class _ComparisonPainter extends CustomPainter {
  final ui.Image before;
  final ui.Image after;
  final double sliderFraction;
  final Size canvasSize;

  _ComparisonPainter({
    required this.before,
    required this.after,
    required this.sliderFraction,
    required this.canvasSize,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..filterQuality = FilterQuality.none;

    final afterSrc = Rect.fromLTWH(
        0, 0, after.width.toDouble(), after.height.toDouble());
    final afterDst = Rect.fromLTWH(0, 0, size.width, size.height);

    // Draw after as the full background (right side)
    canvas.drawImageRect(after, afterSrc, afterDst, paint);

    // Clip left side for before
    final splitX = size.width * sliderFraction;
    canvas.save();
    canvas.clipRect(Rect.fromLTWH(0, 0, splitX, size.height));

    final beforeSrc = Rect.fromLTWH(
        0, 0, before.width.toDouble(), before.height.toDouble());
    final beforeDst = Rect.fromLTWH(0, 0, size.width, size.height);
    canvas.drawImageRect(before, beforeSrc, beforeDst, paint);

    canvas.restore();
  }

  @override
  bool shouldRepaint(_ComparisonPainter oldDelegate) {
    return oldDelegate.sliderFraction != sliderFraction;
  }
}

class _SliderLinePainter extends CustomPainter {
  final double fraction;
  final Color color;

  _SliderLinePainter({required this.fraction, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final x = size.width * fraction;

    // Vertical line
    final linePaint = Paint()
      ..color = color.withValues(alpha: 0.8)
      ..strokeWidth = 2.0;
    canvas.drawLine(Offset(x, 0), Offset(x, size.height), linePaint);

    // Circular handle
    final handlePaint = Paint()..color = color;
    final outlinePaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.4)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;
    final center = Offset(x, size.height / 2);
    canvas.drawCircle(center, 14, handlePaint);
    canvas.drawCircle(center, 14, outlinePaint);

    // Arrow icons on handle
    final arrowPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;
    // Left arrow
    canvas.drawLine(
        Offset(x - 5, center.dy), Offset(x - 2, center.dy - 4), arrowPaint);
    canvas.drawLine(
        Offset(x - 5, center.dy), Offset(x - 2, center.dy + 4), arrowPaint);
    // Right arrow
    canvas.drawLine(
        Offset(x + 5, center.dy), Offset(x + 2, center.dy - 4), arrowPaint);
    canvas.drawLine(
        Offset(x + 5, center.dy), Offset(x + 2, center.dy + 4), arrowPaint);
  }

  @override
  bool shouldRepaint(_SliderLinePainter oldDelegate) {
    return oldDelegate.fraction != fraction;
  }
}
