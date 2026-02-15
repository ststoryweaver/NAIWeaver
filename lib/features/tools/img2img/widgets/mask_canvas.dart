import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/img2img_session.dart';
import '../providers/img2img_notifier.dart';

/// The core painting widget: source image + mask overlay + gesture handling.
class MaskCanvas extends StatefulWidget {
  const MaskCanvas({super.key});

  @override
  State<MaskCanvas> createState() => _MaskCanvasState();
}

class _MaskCanvasState extends State<MaskCanvas> {
  /// The actual rect where the image is rendered (after BoxFit.contain).
  Rect _imageRect = Rect.zero;

  @override
  Widget build(BuildContext context) {
    final notifier = context.watch<Img2ImgNotifier>();
    final session = notifier.session;
    if (session == null) return const SizedBox.shrink();

    return LayoutBuilder(
      builder: (context, constraints) {
        // Calculate the fitted image rect
        final containerSize = Size(constraints.maxWidth, constraints.maxHeight);
        final imageAspect = session.sourceWidth / session.sourceHeight;
        final containerAspect = containerSize.width / containerSize.height;

        double renderWidth, renderHeight;
        if (imageAspect > containerAspect) {
          renderWidth = containerSize.width;
          renderHeight = containerSize.width / imageAspect;
        } else {
          renderHeight = containerSize.height;
          renderWidth = containerSize.height * imageAspect;
        }

        final offsetX = (containerSize.width - renderWidth) / 2;
        final offsetY = (containerSize.height - renderHeight) / 2;
        _imageRect = Rect.fromLTWH(offsetX, offsetY, renderWidth, renderHeight);

        return MouseRegion(
          cursor: SystemMouseCursors.none,
          child: GestureDetector(
            onPanStart: (details) => _onPanStart(details, notifier),
            onPanUpdate: (details) => _onPanUpdate(details, notifier),
            onPanEnd: (_) => notifier.endStroke(),
            child: Stack(
              children: [
                // Source image
                Positioned.fill(
                  child: FittedBox(
                    fit: BoxFit.contain,
                    child: Image.memory(
                      session.sourceImageBytes,
                      width: session.sourceWidth.toDouble(),
                      height: session.sourceHeight.toDouble(),
                      gaplessPlayback: true,
                    ),
                  ),
                ),

                // Mask overlay
                Positioned.fill(
                  child: CustomPaint(
                    painter: _MaskOverlayPainter(
                      strokes: session.maskStrokes,
                      activeStroke: notifier.activeStroke,
                      imageRect: _imageRect,
                      sourceWidth: session.sourceWidth,
                      sourceHeight: session.sourceHeight,
                    ),
                  ),
                ),

                // Cursor preview
                Positioned.fill(
                  child: _CursorPreview(
                    brushRadius: notifier.brushRadius,
                    isErase: notifier.isEraseMode,
                    imageRect: _imageRect,
                    sourceWidth: session.sourceWidth,
                    sourceHeight: session.sourceHeight,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _onPanStart(DragStartDetails details, Img2ImgNotifier notifier) {
    final normalized = _toNormalized(details.localPosition);
    if (normalized != null) {
      notifier.beginStroke(normalized);
    }
  }

  void _onPanUpdate(DragUpdateDetails details, Img2ImgNotifier notifier) {
    final normalized = _toNormalized(details.localPosition);
    if (normalized != null) {
      notifier.addStrokePoint(normalized);
    }
  }

  Offset? _toNormalized(Offset localPosition) {
    if (_imageRect.width <= 0 || _imageRect.height <= 0) return null;

    final x = (localPosition.dx - _imageRect.left) / _imageRect.width;
    final y = (localPosition.dy - _imageRect.top) / _imageRect.height;

    // Clamp to 0-1
    return Offset(x.clamp(0.0, 1.0), y.clamp(0.0, 1.0));
  }
}

/// Paints the mask strokes as a semi-transparent overlay, grid-snapped to 8px.
class _MaskOverlayPainter extends CustomPainter {
  final List<MaskStroke> strokes;
  final MaskStroke? activeStroke;
  final Rect imageRect;
  final int sourceWidth;
  final int sourceHeight;

  _MaskOverlayPainter({
    required this.strokes,
    this.activeStroke,
    required this.imageRect,
    required this.sourceWidth,
    required this.sourceHeight,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (imageRect.isEmpty) return;

    // Paint committed strokes
    for (final stroke in strokes) {
      _paintStroke(canvas, stroke);
    }

    // Paint active (in-progress) stroke
    if (activeStroke != null) {
      _paintStroke(canvas, activeStroke!);
    }
  }

  void _paintStroke(Canvas canvas, MaskStroke stroke) {
    final layerAlpha = stroke.isErase ? 32 : 48;
    final layerColor = stroke.isErase
        ? const Color(0xFF000000)
        : const Color(0xFFFF0066);

    canvas.saveLayer(
      null,
      Paint()..color = Color.fromARGB(layerAlpha, 0, 0, 0),
    );

    final paint = Paint()
      ..color = layerColor
      ..style = PaintingStyle.fill
      ..isAntiAlias = false;

    // Grid step in screen coordinates (8 source pixels)
    const grid = 8;
    final gridW = grid / sourceWidth * imageRect.width;
    final gridH = grid / sourceHeight * imageRect.height;

    // Snap brush radius UP to nearest grid cell (minimum 1 grid cell)
    final rawR = stroke.radius * imageRect.width;
    final r = ((rawR / gridW).ceil()).clamp(1, sourceWidth) * gridW;

    // Draw grid-aligned square at each sampled point
    for (final point in stroke.points) {
      final rawPx = imageRect.left + point.dx * imageRect.width;
      final rawPy = imageRect.top + point.dy * imageRect.height;
      final px = imageRect.left + ((rawPx - imageRect.left) / gridW).floor() * gridW;
      final py = imageRect.top + ((rawPy - imageRect.top) / gridH).floor() * gridH;
      canvas.drawRect(Rect.fromLTWH(px - r, py - r, r * 2, r * 2), paint);
    }

    // Interpolate between consecutive points
    for (int i = 0; i < stroke.points.length - 1; i++) {
      final p1 = stroke.points[i];
      final p2 = stroke.points[i + 1];
      final rawX1 = imageRect.left + p1.dx * imageRect.width;
      final rawY1 = imageRect.top + p1.dy * imageRect.height;
      final rawX2 = imageRect.left + p2.dx * imageRect.width;
      final rawY2 = imageRect.top + p2.dy * imageRect.height;
      final x1 = imageRect.left + ((rawX1 - imageRect.left) / gridW).floor() * gridW;
      final y1 = imageRect.top + ((rawY1 - imageRect.top) / gridH).floor() * gridH;
      final x2 = imageRect.left + ((rawX2 - imageRect.left) / gridW).floor() * gridW;
      final y2 = imageRect.top + ((rawY2 - imageRect.top) / gridH).floor() * gridH;
      final dx = x2 - x1;
      final dy = y2 - y1;
      final steps = [dx.abs(), dy.abs(), 1.0].reduce((a, b) => a > b ? a : b).ceil();
      for (int s = 1; s < steps; s++) {
        final t = s / steps;
        final rawIx = x1 + dx * t;
        final rawIy = y1 + dy * t;
        final ix = imageRect.left + ((rawIx - imageRect.left) / gridW).floor() * gridW;
        final iy = imageRect.top + ((rawIy - imageRect.top) / gridH).floor() * gridH;
        canvas.drawRect(Rect.fromLTWH(ix - r, iy - r, r * 2, r * 2), paint);
      }
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(_MaskOverlayPainter oldDelegate) => true;
}

/// Shows a grid-snapped square cursor that follows the mouse position.
class _CursorPreview extends StatefulWidget {
  final double brushRadius;
  final bool isErase;
  final Rect imageRect;
  final int sourceWidth;
  final int sourceHeight;

  const _CursorPreview({
    required this.brushRadius,
    required this.isErase,
    required this.imageRect,
    required this.sourceWidth,
    required this.sourceHeight,
  });

  @override
  State<_CursorPreview> createState() => _CursorPreviewState();
}

class _CursorPreviewState extends State<_CursorPreview> {
  Offset? _mousePosition;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      hitTestBehavior: HitTestBehavior.translucent,
      onHover: (event) => setState(() => _mousePosition = event.localPosition),
      onExit: (_) => setState(() => _mousePosition = null),
      child: CustomPaint(
        painter: _CursorPainter(
          position: _mousePosition,
          rawRadius: widget.brushRadius * widget.imageRect.width,
          isErase: widget.isErase,
          imageRect: widget.imageRect,
          sourceWidth: widget.sourceWidth,
          sourceHeight: widget.sourceHeight,
        ),
      ),
    );
  }
}

class _CursorPainter extends CustomPainter {
  final Offset? position;
  final double rawRadius;
  final bool isErase;
  final Rect imageRect;
  final int sourceWidth;
  final int sourceHeight;

  _CursorPainter({
    this.position,
    required this.rawRadius,
    required this.isErase,
    required this.imageRect,
    required this.sourceWidth,
    required this.sourceHeight,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (position == null || rawRadius <= 0 || imageRect.isEmpty) return;

    const grid = 8;
    final gridW = grid / sourceWidth * imageRect.width;
    final gridH = grid / sourceHeight * imageRect.height;

    // Snap brush radius UP to nearest grid cell
    final r = ((rawRadius / gridW).ceil()).clamp(1, sourceWidth) * gridW;

    // Snap cursor position to grid
    final rawPx = position!.dx;
    final rawPy = position!.dy;
    final px = imageRect.left + ((rawPx - imageRect.left) / gridW).floor() * gridW;
    final py = imageRect.top + ((rawPy - imageRect.top) / gridH).floor() * gridH;

    final paint = Paint()
      ..color = isErase ? Colors.white70 : const Color(0xAAFF0066)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    canvas.drawRect(Rect.fromLTWH(px - r, py - r, r * 2, r * 2), paint);

    // Small crosshair at snapped center
    final crossPaint = Paint()
      ..color = Colors.white54
      ..strokeWidth = 0.5;
    canvas.drawLine(Offset(px - 4, py), Offset(px + 4, py), crossPaint);
    canvas.drawLine(Offset(px, py - 4), Offset(px, py + 4), crossPaint);
  }

  @override
  bool shouldRepaint(_CursorPainter oldDelegate) =>
      position != oldDelegate.position ||
      rawRadius != oldDelegate.rawRadius ||
      isErase != oldDelegate.isErase;
}
