import 'dart:ui' as ui;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:provider/provider.dart';

import '../../../../core/l10n/l10n_extensions.dart';
import '../../../../core/theme/theme_extensions.dart';
import '../models/canvas_layer.dart';
import '../models/paint_stroke.dart';
import '../providers/canvas_notifier.dart';

/// The painting widget: source image + paint overlay (CustomPaint) + gesture handling + cursor preview.
class CanvasPaintSurface extends StatefulWidget {
  const CanvasPaintSurface({super.key});

  @override
  State<CanvasPaintSurface> createState() => _CanvasPaintSurfaceState();
}

class _CanvasPaintSurfaceState extends State<CanvasPaintSurface> {
  Rect _imageRect = Rect.zero;

  @override
  Widget build(BuildContext context) {
    final notifier = context.watch<CanvasNotifier>();
    final session = notifier.session;
    if (session == null) return const SizedBox.shrink();

    return LayoutBuilder(
      builder: (context, constraints) {
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

        return Listener(
          onPointerSignal: (event) {
            if (event is PointerScrollEvent) {
              _onPointerSignal(event, notifier);
            }
          },
          child: MouseRegion(
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

                  // Paint overlay — per-layer compositing
                  Positioned.fill(
                    child: CustomPaint(
                      painter: _CanvasPaintOverlayPainter(
                        layers: session.layers,
                        activeLayerId: session.activeLayerId,
                        activeStroke: notifier.activeStroke,
                        imageRect: _imageRect,
                      ),
                    ),
                  ),

                  // Cursor preview
                  Positioned.fill(
                    child: _CanvasCursorPreview(
                      brushRadius: notifier.brushRadius,
                      tool: notifier.tool,
                      brushColor: notifier.brushColorAsColor,
                      imageRect: _imageRect,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _onPointerSignal(PointerScrollEvent event, CanvasNotifier notifier) {
    final keyboard = HardwareKeyboard.instance;
    final ctrlHeld = keyboard.isControlPressed || keyboard.isMetaPressed;
    final altHeld = keyboard.isAltPressed;

    if (ctrlHeld) {
      // Ctrl + scroll: adjust brush size
      final delta = event.scrollDelta.dy > 0 ? -0.003 : 0.003;
      notifier.setBrushRadius(notifier.brushRadius + delta);
    } else if (altHeld) {
      // Alt + scroll: adjust opacity
      final delta = event.scrollDelta.dy > 0 ? -0.05 : 0.05;
      notifier.setBrushOpacity(notifier.brushOpacity + delta);
    }
  }

  void _onPanStart(DragStartDetails details, CanvasNotifier notifier) {
    final normalized = _toNormalized(details.localPosition);
    if (normalized == null) return;

    if (notifier.tool == CanvasTool.eyedropper) {
      _samplePixel(normalized, notifier);
    } else if (notifier.tool == CanvasTool.fill) {
      notifier.applyFill(normalized);
    } else if (notifier.tool == CanvasTool.text) {
      _showTextDialog(normalized, notifier);
    } else {
      notifier.beginStroke(normalized);
    }
  }

  void _onPanUpdate(DragUpdateDetails details, CanvasNotifier notifier) {
    final normalized = _toNormalized(details.localPosition);
    if (normalized != null) {
      notifier.addStrokePoint(normalized);
    }
  }

  Offset? _toNormalized(Offset localPosition) {
    if (_imageRect.width <= 0 || _imageRect.height <= 0) return null;
    final x = (localPosition.dx - _imageRect.left) / _imageRect.width;
    final y = (localPosition.dy - _imageRect.top) / _imageRect.height;
    return Offset(x.clamp(0.0, 1.0), y.clamp(0.0, 1.0));
  }

  void _showTextDialog(Offset position, CanvasNotifier notifier) {
    final t = context.t;
    final l = context.l;
    final textController = TextEditingController();
    double fontSize = 0.05;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            final previewColor = Color(notifier.brushColor)
                .withValues(alpha: notifier.brushOpacity);
            return AlertDialog(
              backgroundColor: t.surfaceHigh,
              title: Text(
                l.canvasText,
                style: TextStyle(
                  color: t.textSecondary,
                  fontSize: t.fontSize(10),
                  letterSpacing: 2,
                ),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: textController,
                    autofocus: true,
                    maxLines: null,
                    style: TextStyle(color: t.textPrimary, fontSize: t.fontSize(10)),
                    decoration: InputDecoration(
                      hintText: l.canvasTextHint,
                      hintStyle: TextStyle(color: t.textMinimal),
                      enabledBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: t.borderSubtle),
                      ),
                      focusedBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: t.accentEdit),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Text(
                        l.canvasTextSize,
                        style: TextStyle(
                          color: t.textDisabled,
                          fontSize: t.fontSize(8),
                          letterSpacing: 1,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: SliderTheme(
                          data: SliderTheme.of(ctx).copyWith(
                            activeTrackColor: t.textDisabled,
                            inactiveTrackColor: t.textMinimal,
                            thumbColor: t.textPrimary,
                            trackHeight: 2,
                            thumbShape: const RoundSliderThumbShape(
                                enabledThumbRadius: 6),
                            overlayShape: const RoundSliderOverlayShape(
                                overlayRadius: 12),
                          ),
                          child: Slider(
                            value: fontSize,
                            min: 0.01,
                            max: 0.20,
                            onChanged: (v) => setDialogState(() => fontSize = v),
                          ),
                        ),
                      ),
                      SizedBox(
                        width: 40,
                        child: Text(
                          '${(fontSize * 100).round()}%',
                          style: TextStyle(
                            color: t.textTertiary,
                            fontSize: t.fontSize(8),
                          ),
                          textAlign: TextAlign.right,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Sample',
                    style: TextStyle(
                      color: previewColor,
                      fontSize: 20,
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: Text(
                    l.commonCancel.toUpperCase(),
                    style: TextStyle(
                      color: t.textDisabled,
                      fontSize: t.fontSize(9),
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    final text = textController.text.trim();
                    if (text.isNotEmpty) {
                      notifier.addTextStroke(
                        position: position,
                        text: text,
                        fontSize: fontSize,
                      );
                    }
                    Navigator.pop(ctx);
                  },
                  child: Text(
                    l.canvasTextPlace,
                    style: TextStyle(
                      color: t.accentEdit,
                      fontSize: t.fontSize(9),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _samplePixel(Offset normalized, CanvasNotifier notifier) {
    final session = notifier.session;
    if (session == null) return;

    try {
      final decoded = img.decodeImage(session.sourceImageBytes);
      if (decoded == null) return;

      final px = (normalized.dx * (decoded.width - 1)).round().clamp(0, decoded.width - 1);
      final py = (normalized.dy * (decoded.height - 1)).round().clamp(0, decoded.height - 1);
      final pixel = decoded.getPixel(px, py);

      final r = pixel.r.toInt().clamp(0, 255);
      final g = pixel.g.toInt().clamp(0, 255);
      final b = pixel.b.toInt().clamp(0, 255);
      final colorValue = (0xFF << 24) | (r << 16) | (g << 8) | b;

      notifier.pickColorFromCanvas(colorValue);
    } catch (_) {
      // Silently fail if decoding fails
    }
  }
}

/// Paints smooth anti-aliased strokes per-layer with blend mode + opacity compositing.
class _CanvasPaintOverlayPainter extends CustomPainter {
  final List<CanvasLayer> layers;
  final String activeLayerId;
  final PaintStroke? activeStroke;
  final Rect imageRect;

  _CanvasPaintOverlayPainter({
    required this.layers,
    required this.activeLayerId,
    this.activeStroke,
    required this.imageRect,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (imageRect.isEmpty) return;

    // Iterate layers bottom-to-top
    for (final layer in layers) {
      if (!layer.visible) continue;

      final layerStrokes = [
        ...layer.strokes,
        if (layer.id == activeLayerId && activeStroke != null) activeStroke!,
      ];
      if (layerStrokes.isEmpty) continue;

      // Save layer with blend mode and opacity
      canvas.saveLayer(
        null,
        Paint()
          ..blendMode = layer.blendMode.toFlutterBlendMode()
          ..color = Color.fromARGB(
              (layer.opacity * 255).round(), 255, 255, 255),
      );

      for (final stroke in layerStrokes) {
        _drawStroke(canvas, stroke);
      }

      canvas.restore();
    }
  }

  void _drawStroke(Canvas canvas, PaintStroke stroke) {
    if (stroke.isErase) {
      final erasePaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..strokeWidth = stroke.radius * 2 * imageRect.width
        ..isAntiAlias = true
        ..blendMode = ui.BlendMode.dstOut
        ..color = const Color(0xFFFFFFFF);

      final path = stroke.smooth ? _buildSmoothPath(stroke) : _buildPath(stroke);
      canvas.drawPath(path, erasePaint);
    } else {
      final strokeColor =
          Color(stroke.colorValue).withValues(alpha: stroke.opacity);
      final paintBrush = Paint()
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..strokeWidth = stroke.radius * 2 * imageRect.width
        ..isAntiAlias = true
        ..color = strokeColor;

      switch (stroke.strokeType) {
        case StrokeType.fill:
          final fillPaint = Paint()
            ..color = strokeColor
            ..style = PaintingStyle.fill;
          canvas.drawRect(imageRect, fillPaint);

        case StrokeType.line:
          if (stroke.points.length >= 2) {
            final p1 = _toScreen(stroke.points.first);
            final p2 = _toScreen(stroke.points.last);
            canvas.drawLine(p1, p2, paintBrush);
          } else if (stroke.points.length == 1) {
            final p = _toScreen(stroke.points.first);
            canvas.drawLine(p, Offset(p.dx + 0.1, p.dy + 0.1), paintBrush);
          }

        case StrokeType.rectangle:
          if (stroke.points.length >= 2) {
            final p1 = _toScreen(stroke.points.first);
            final p2 = _toScreen(stroke.points.last);
            canvas.drawRect(Rect.fromPoints(p1, p2), paintBrush);
          }

        case StrokeType.circle:
          if (stroke.points.length >= 2) {
            final p1 = _toScreen(stroke.points.first);
            final p2 = _toScreen(stroke.points.last);
            canvas.drawOval(Rect.fromPoints(p1, p2), paintBrush);
          }

        case StrokeType.text:
          if (stroke.text != null && stroke.points.isNotEmpty) {
            final pos = _toScreen(stroke.points.first);
            final textFontSize =
                (stroke.fontSize ?? 0.05) * imageRect.height;
            final textPainter = TextPainter(
              text: TextSpan(
                text: stroke.text,
                style: TextStyle(
                  color: strokeColor,
                  fontSize: textFontSize,
                ),
              ),
              textDirection: TextDirection.ltr,
            )..layout();
            textPainter.paint(canvas, pos);
          }

        case StrokeType.freehand:
          final path = stroke.smooth ? _buildSmoothPath(stroke) : _buildPath(stroke);
          canvas.drawPath(path, paintBrush);
      }
    }
  }

  Path _buildPath(PaintStroke stroke) {
    final path = Path();
    if (stroke.points.isEmpty) return path;

    final first = _toScreen(stroke.points.first);
    path.moveTo(first.dx, first.dy);

    if (stroke.points.length == 1) {
      // Single dot: draw a tiny line so stroke cap renders
      path.lineTo(first.dx + 0.1, first.dy + 0.1);
    } else {
      for (int i = 1; i < stroke.points.length; i++) {
        final p = _toScreen(stroke.points[i]);
        path.lineTo(p.dx, p.dy);
      }
    }

    return path;
  }

  Path _buildSmoothPath(PaintStroke stroke) {
    final path = Path();
    if (stroke.points.isEmpty) return path;

    final pts = stroke.points.map(_toScreen).toList();
    path.moveTo(pts.first.dx, pts.first.dy);

    if (pts.length == 1) {
      path.lineTo(pts.first.dx + 0.1, pts.first.dy + 0.1);
    } else if (pts.length == 2) {
      path.lineTo(pts[1].dx, pts[1].dy);
    } else {
      // Quadratic bezier through midpoints for C1 continuity
      for (int i = 0; i < pts.length - 1; i++) {
        final current = pts[i];
        final next = pts[i + 1];
        final midX = (current.dx + next.dx) / 2;
        final midY = (current.dy + next.dy) / 2;

        if (i == 0) {
          path.quadraticBezierTo(current.dx, current.dy, midX, midY);
        } else {
          path.quadraticBezierTo(current.dx, current.dy, midX, midY);
        }
      }
      path.lineTo(pts.last.dx, pts.last.dy);
    }

    return path;
  }

  Offset _toScreen(Offset normalized) {
    return Offset(
      imageRect.left + normalized.dx * imageRect.width,
      imageRect.top + normalized.dy * imageRect.height,
    );
  }

  @override
  bool shouldRepaint(_CanvasPaintOverlayPainter oldDelegate) => true;
}

/// Shows a circular brush outline following the mouse position.
class _CanvasCursorPreview extends StatefulWidget {
  final double brushRadius;
  final CanvasTool tool;
  final Color brushColor;
  final Rect imageRect;

  const _CanvasCursorPreview({
    required this.brushRadius,
    required this.tool,
    required this.brushColor,
    required this.imageRect,
  });

  @override
  State<_CanvasCursorPreview> createState() => _CanvasCursorPreviewState();
}

class _CanvasCursorPreviewState extends State<_CanvasCursorPreview> {
  Offset? _mousePosition;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      hitTestBehavior: HitTestBehavior.translucent,
      onHover: (event) => setState(() => _mousePosition = event.localPosition),
      onExit: (_) => setState(() => _mousePosition = null),
      child: CustomPaint(
        painter: _CanvasCursorPainter(
          position: _mousePosition,
          radius: widget.brushRadius * widget.imageRect.width,
          tool: widget.tool,
          brushColor: widget.brushColor,
        ),
      ),
    );
  }
}

class _CanvasCursorPainter extends CustomPainter {
  final Offset? position;
  final double radius;
  final CanvasTool tool;
  final Color brushColor;

  _CanvasCursorPainter({
    this.position,
    required this.radius,
    required this.tool,
    required this.brushColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (position == null) return;

    if (tool == CanvasTool.eyedropper || tool == CanvasTool.fill || tool == CanvasTool.text) {
      // Eyedropper / Fill: crosshair only (no circle outline)
      final crossPaint = Paint()
        ..color = Colors.white
        ..strokeWidth = 1.5;
      const len = 8.0;
      canvas.drawLine(
        Offset(position!.dx - len, position!.dy),
        Offset(position!.dx + len, position!.dy),
        crossPaint,
      );
      canvas.drawLine(
        Offset(position!.dx, position!.dy - len),
        Offset(position!.dx, position!.dy + len),
        crossPaint,
      );
      // Dark outline for visibility
      final outlinePaint = Paint()
        ..color = Colors.black54
        ..strokeWidth = 0.5;
      canvas.drawLine(
        Offset(position!.dx - len, position!.dy),
        Offset(position!.dx + len, position!.dy),
        outlinePaint,
      );
      canvas.drawLine(
        Offset(position!.dx, position!.dy - len),
        Offset(position!.dx, position!.dy + len),
        outlinePaint,
      );
      return;
    }

    if (radius <= 0) return;

    final outlinePaint = Paint()
      ..color = tool == CanvasTool.erase
          ? Colors.white70
          : brushColor.withValues(alpha: 0.7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    canvas.drawCircle(position!, radius, outlinePaint);

    // Small crosshair at center
    final crossPaint = Paint()
      ..color = Colors.white54
      ..strokeWidth = 0.5;
    canvas.drawLine(
      Offset(position!.dx - 4, position!.dy),
      Offset(position!.dx + 4, position!.dy),
      crossPaint,
    );
    canvas.drawLine(
      Offset(position!.dx, position!.dy - 4),
      Offset(position!.dx, position!.dy + 4),
      crossPaint,
    );
  }

  @override
  bool shouldRepaint(_CanvasCursorPainter oldDelegate) =>
      position != oldDelegate.position ||
      radius != oldDelegate.radius ||
      tool != oldDelegate.tool ||
      brushColor != oldDelegate.brushColor;
}
