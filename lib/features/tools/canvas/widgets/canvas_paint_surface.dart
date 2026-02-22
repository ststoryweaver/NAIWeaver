import 'dart:ui' as ui;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image/image.dart' as img;
import 'package:provider/provider.dart';

import '../../../../core/l10n/l10n_extensions.dart';
import '../../../../core/theme/theme_extensions.dart';
import '../models/canvas_layer.dart';
import '../models/paint_stroke.dart';
import '../providers/canvas_notifier.dart';

/// Build a [TextStyle] with an optional Google Fonts family.
TextStyle _buildFontStyle({
  required Color color,
  required double fontSize,
  String? fontFamily,
  double? letterSpacing,
}) {
  final base = TextStyle(
    color: color,
    fontSize: fontSize,
    letterSpacing: letterSpacing,
  );
  if (fontFamily == null) return base;
  try {
    return GoogleFonts.getFont(fontFamily, textStyle: base);
  } catch (_) {
    return base;
  }
}

/// The painting widget: source image + paint overlay (CustomPaint) + gesture handling + cursor preview + inline text editor.
class CanvasPaintSurface extends StatefulWidget {
  const CanvasPaintSurface({super.key});

  @override
  State<CanvasPaintSurface> createState() => _CanvasPaintSurfaceState();
}

class _CanvasPaintSurfaceState extends State<CanvasPaintSurface> {
  Rect _imageRect = Rect.zero;
  final TextEditingController _textController = TextEditingController();
  final FocusNode _textFocusNode = FocusNode();

  // Image layer cache
  final Map<String, ui.Image> _imageLayerCache = {};
  final Set<String> _decodingImages = {};

  void _ensureImageCached(CanvasLayer layer) {
    if (!layer.isImageLayer || layer.imageBytes == null) return;
    if (_imageLayerCache.containsKey(layer.id)) return;
    if (_decodingImages.contains(layer.id)) return;
    _decodingImages.add(layer.id);

    ui.decodeImageFromList(layer.imageBytes!, (result) {
      if (mounted) {
        setState(() {
          _imageLayerCache[layer.id] = result;
          _decodingImages.remove(layer.id);
        });
      }
    });
  }

  @override
  void dispose() {
    _textController.dispose();
    _textFocusNode.dispose();
    for (final img in _imageLayerCache.values) {
      img.dispose();
    }
    super.dispose();
  }

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

        // Ensure image layers are cached
        for (final layer in session.layers) {
          _ensureImageCached(layer);
        }

        // Build pending text stroke for live preview
        PaintStroke? pendingTextStroke;
        if (notifier.hasPendingText && notifier.pendingTextContent.isNotEmpty) {
          pendingTextStroke = PaintStroke(
            points: [notifier.pendingTextPosition!],
            radius: 0,
            colorValue: notifier.brushColor,
            opacity: notifier.brushOpacity,
            strokeType: StrokeType.text,
            text: notifier.pendingTextContent,
            fontSize: notifier.pendingTextFontSize,
            fontFamily: notifier.pendingTextFontFamily,
            letterSpacing: notifier.pendingTextLetterSpacing,
          );
        }

        return Stack(
          children: [
            Listener(
              onPointerSignal: (event) {
                if (event is PointerScrollEvent) {
                  _onPointerSignal(event, notifier);
                }
              },
              child: MouseRegion(
                cursor: SystemMouseCursors.none,
                child: GestureDetector(
                  onTapUp: (details) => _onTapUp(details, notifier),
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
                            filterQuality: FilterQuality.medium,
                          ),
                        ),
                      ),

                      // Paint overlay — per-layer compositing + pending text preview
                      Positioned.fill(
                        child: CustomPaint(
                          painter: _CanvasPaintOverlayPainter(
                            layers: session.layers,
                            activeLayerId: session.activeLayerId,
                            activeStroke: notifier.activeStroke,
                            pendingTextStroke: pendingTextStroke,
                            imageRect: _imageRect,
                            imageCache: _imageLayerCache,
                          ),
                        ),
                      ),

                      // Blinking text cursor
                      if (notifier.hasPendingText)
                        _BlinkingTextCursor(
                          normalizedPosition: notifier.pendingTextPosition!,
                          currentText: notifier.pendingTextContent,
                          fontSizeNormalized: notifier.pendingTextFontSize,
                          fontFamily: notifier.pendingTextFontFamily,
                          letterSpacing: notifier.pendingTextLetterSpacing,
                          imageRect: _imageRect,
                          color: notifier.brushColorAsColor,
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
            ),

            // Inline text editor — outside the canvas GestureDetector so
            // button taps are not stolen by the pan recognizer.
            if (notifier.hasPendingText)
              _buildInlineTextEditor(notifier),
          ],
        );
      },
    );
  }

  Widget _buildInlineTextEditor(CanvasNotifier notifier) {
    final t = context.t;
    final l = context.l;
    final pos = notifier.pendingTextPosition!;

    // Convert normalized position to screen position
    final screenX = _imageRect.left + pos.dx * _imageRect.width;
    final screenY = _imageRect.top + pos.dy * _imageRect.height;

    // Clamp so the editor doesn't overflow outside the image rect
    const editorWidth = 220.0;
    const editorHeight = 40.0;
    final clampedX = screenX.clamp(_imageRect.left, _imageRect.right - editorWidth);
    final keyboardTop = MediaQuery.of(context).size.height - MediaQuery.of(context).viewInsets.bottom;
    final maxY = (keyboardTop - editorHeight - 8).clamp(_imageRect.top, _imageRect.bottom - editorHeight);
    final clampedY = (screenY - editorHeight - 8).clamp(_imageRect.top, maxY);

    return Positioned(
      left: clampedX,
      top: clampedY,
      child: Material(
        elevation: 4,
        borderRadius: BorderRadius.circular(6),
        color: t.surfaceHigh,
        child: Container(
          width: editorWidth,
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: t.accentEdit, width: 1),
          ),
          child: Row(
            children: [
              Expanded(
                child: KeyboardListener(
                  focusNode: FocusNode(),
                  onKeyEvent: (event) {
                    if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.escape) {
                      notifier.cancelPendingText();
                      _textController.clear();
                    }
                  },
                  child: TextField(
                    controller: _textController,
                    focusNode: _textFocusNode,
                    autofocus: true,
                    style: TextStyle(color: t.textPrimary, fontSize: t.fontSize(9)),
                    decoration: InputDecoration(
                      hintText: l.canvasTextHint,
                      hintStyle: TextStyle(color: t.textMinimal, fontSize: t.fontSize(9)),
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(vertical: 6),
                      border: InputBorder.none,
                    ),
                    onChanged: notifier.updatePendingText,
                    onSubmitted: (_) {
                      notifier.commitPendingText();
                      _textController.clear();
                    },
                  ),
                ),
              ),
              // Confirm button
              GestureDetector(
                onTap: () {
                  notifier.commitPendingText();
                  _textController.clear();
                },
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: Icon(Icons.check, size: 16, color: t.accentEdit),
                ),
              ),
              // Cancel button
              GestureDetector(
                onTap: () {
                  notifier.cancelPendingText();
                  _textController.clear();
                },
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: Icon(Icons.close, size: 16, color: t.textDisabled),
                ),
              ),
            ],
          ),
        ),
      ),
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

  void _onTapUp(TapUpDetails details, CanvasNotifier notifier) {
    if (!_imageRect.contains(details.localPosition)) return;
    final normalized = _toNormalized(details.localPosition);
    if (normalized == null) return;

    if (notifier.tool == CanvasTool.eyedropper) {
      _samplePixel(normalized, notifier);
    } else if (notifier.tool == CanvasTool.fill) {
      notifier.applyFill(normalized);
    } else if (notifier.tool == CanvasTool.text) {
      if (notifier.hasPendingText) {
        notifier.commitPendingText();
        _textController.clear();
      }
      notifier.beginTextEditing(normalized);
      _textController.clear();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _textFocusNode.requestFocus();
      });
    }
  }

  void _onPanStart(DragStartDetails details, CanvasNotifier notifier) {
    if (!_imageRect.contains(details.localPosition)) return;
    final normalized = _toNormalized(details.localPosition);
    if (normalized == null) return;

    if (notifier.tool == CanvasTool.eyedropper) {
      _samplePixel(normalized, notifier);
    } else if (notifier.tool == CanvasTool.fill) {
      notifier.applyFill(normalized);
    } else if (notifier.tool == CanvasTool.text) {
      // If there's already a pending text, commit it first
      if (notifier.hasPendingText) {
        notifier.commitPendingText();
        _textController.clear();
      }
      notifier.beginTextEditing(normalized);
      _textController.clear();
      // Re-focus the text field after a frame
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _textFocusNode.requestFocus();
      });
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
/// Also renders image layers with transform.
class _CanvasPaintOverlayPainter extends CustomPainter {
  final List<CanvasLayer> layers;
  final String activeLayerId;
  final PaintStroke? activeStroke;
  final PaintStroke? pendingTextStroke;
  final Rect imageRect;
  final Map<String, ui.Image> imageCache;

  _CanvasPaintOverlayPainter({
    required this.layers,
    required this.activeLayerId,
    this.activeStroke,
    this.pendingTextStroke,
    required this.imageRect,
    this.imageCache = const {},
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (imageRect.isEmpty) return;

    // Clip all paint to image bounds
    canvas.save();
    canvas.clipRect(imageRect);

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

      // Draw image layer content first (if present)
      if (layer.isImageLayer) {
        final cached = imageCache[layer.id];
        if (cached != null) {
          canvas.save();
          final imgW = cached.width.toDouble();
          final imgH = cached.height.toDouble();
          // Compute destination rect based on normalized transform
          final scale = layer.imageScale * imageRect.width / imgW;
          final dx = imageRect.left + layer.imageX * imageRect.width;
          final dy = imageRect.top + layer.imageY * imageRect.height;
          canvas.translate(dx + imgW * scale / 2, dy + imgH * scale / 2);
          canvas.rotate(layer.imageRotation);
          canvas.translate(-imgW * scale / 2, -imgH * scale / 2);
          canvas.drawImageRect(
            cached,
            Rect.fromLTWH(0, 0, imgW, imgH),
            Rect.fromLTWH(0, 0, imgW * scale, imgH * scale),
            Paint(),
          );
          canvas.restore();
        }
      }

      for (final stroke in layerStrokes) {
        _drawStroke(canvas, stroke);
      }

      canvas.restore();
    }

    // Draw pending text preview on top of all layers
    if (pendingTextStroke != null) {
      _drawStroke(canvas, pendingTextStroke!);
    }

    canvas.restore();
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
            final textLetterSpacing =
                (stroke.letterSpacing ?? 0.0) * imageRect.height;
            final style = _buildFontStyle(
              color: strokeColor,
              fontSize: textFontSize,
              fontFamily: stroke.fontFamily,
              letterSpacing: textLetterSpacing,
            );
            final textPainter = TextPainter(
              text: TextSpan(text: stroke.text, style: style),
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
      // Eyedropper / Fill / Text: crosshair only (no circle outline)
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

/// A blinking vertical cursor line shown on the canvas at the text insertion point.
class _BlinkingTextCursor extends StatefulWidget {
  final Offset normalizedPosition;
  final String currentText;
  final double fontSizeNormalized;
  final String? fontFamily;
  final double letterSpacing;
  final Rect imageRect;
  final Color color;

  const _BlinkingTextCursor({
    required this.normalizedPosition,
    required this.currentText,
    required this.fontSizeNormalized,
    required this.fontFamily,
    required this.letterSpacing,
    required this.imageRect,
    required this.color,
  });

  @override
  State<_BlinkingTextCursor> createState() => _BlinkingTextCursorState();
}

class _BlinkingTextCursorState extends State<_BlinkingTextCursor>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 530),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final fontSize = widget.fontSizeNormalized * widget.imageRect.height;
    final letterSpacing = widget.letterSpacing * widget.imageRect.height;

    // Measure current text width to position cursor at end
    double textWidth = 0;
    if (widget.currentText.isNotEmpty) {
      final style = _buildFontStyle(
        color: widget.color,
        fontSize: fontSize,
        fontFamily: widget.fontFamily,
        letterSpacing: letterSpacing,
      );
      final textPainter = TextPainter(
        text: TextSpan(text: widget.currentText, style: style),
        textDirection: TextDirection.ltr,
      )..layout();
      textWidth = textPainter.width;
    }

    final screenX = widget.imageRect.left +
        widget.normalizedPosition.dx * widget.imageRect.width +
        textWidth;
    final screenY = widget.imageRect.top +
        widget.normalizedPosition.dy * widget.imageRect.height;

    final cursorHeight = fontSize.clamp(8.0, 200.0);

    return Positioned(
      left: screenX,
      top: screenY,
      child: IgnorePointer(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (_, _) => Opacity(
            opacity: _controller.value > 0.5 ? 1.0 : 0.0,
            child: Container(
              width: 2,
              height: cursorHeight,
              color: widget.color,
            ),
          ),
        ),
      ),
    );
  }
}
