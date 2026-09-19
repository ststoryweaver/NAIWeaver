import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../../core/utils/canvas_zoom_math.dart';
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

  /// Viewport size of the canvas area, needed to clamp wheel zoom.
  Size _viewportSize = Size.zero;

  // Zoom & pan
  final TransformationController _zoomController = TransformationController();
  final FocusNode _keyboardFocusNode = FocusNode();
  bool _spaceHeld = false;
  bool _middleMouseHeld = false;
  final Set<int> _pointers = {};
  bool _multiPointerGesture = false;
  final GlobalKey<_CursorPreviewState> _cursorKey = GlobalKey<_CursorPreviewState>();

  // Committed-stroke raster cache
  ui.Image? _committedMaskCache;
  String? _committedCacheKey;
  int _committedCachedStrokeCount = 0;

  // Active-stroke incremental raster cache
  ui.Image? _activeStrokeCache;
  int _activeCachedPointCount = 0;
  Object? _activeCachedStrokeId;

  Img2ImgNotifier? _notifierRef;

  @override
  void initState() {
    super.initState();
    HardwareKeyboard.instance.addHandler(_handleGlobalKey);
  }

  bool _handleGlobalKey(KeyEvent event) {
    if (event is! KeyDownEvent) return false;
    if (!mounted) return false;
    final ctrl = HardwareKeyboard.instance.isControlPressed ||
        HardwareKeyboard.instance.isMetaPressed;
    if (ctrl && event.logicalKey == LogicalKeyboardKey.keyZ) {
      _notifierRef?.undoLastStroke();
      return true;
    }
    return false;
  }

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(_handleGlobalKey);
    _activeStrokeCache?.dispose();
    _committedMaskCache?.dispose();
    _zoomController.dispose();
    _keyboardFocusNode.dispose();
    super.dispose();
  }

  String _buildCacheKey(
    List<MaskStroke> strokes, Rect imageRect,
    int sourceWidth, int sourceHeight, int maskColor, double maskOpacity,
    bool maskShowBorder, MaskPattern maskPattern, bool brushRound,
  ) {
    return '${identityHashCode(strokes)}:${strokes.length}:$maskColor:$maskOpacity:$maskShowBorder'
        ':$maskPattern:$brushRound:$imageRect:$sourceWidth:$sourceHeight';
  }

  void _rasterizeCommittedStrokes({
    required List<MaskStroke> strokes,
    required Rect imageRect,
    required int sourceWidth,
    required int sourceHeight,
    required int maskColor,
    required double maskOpacity,
    required bool maskShowBorder,
    required MaskPattern maskPattern,
    required bool brushRound,
    required String cacheKey,
  }) {
    if (strokes.isEmpty || imageRect.isEmpty) {
      _committedMaskCache?.dispose();
      _committedMaskCache = null;
      _committedCacheKey = cacheKey;
      _committedCachedStrokeCount = 0;
      return;
    }

    final width = imageRect.right.ceil() + imageRect.left.ceil();
    final height = imageRect.bottom.ceil() + imageRect.top.ceil();
    if (width <= 0 || height <= 0) return;

    // Check if we can do an incremental update (only new strokes appended,
    // same visual settings). If so, draw the old cache + only the new strokes.
    final canIncrement = _committedMaskCache != null &&
        _committedCachedStrokeCount > 0 &&
        _committedCachedStrokeCount < strokes.length;

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder, Offset.zero & Size(width.toDouble(), height.toDouble()));

    if (canIncrement) {
      // Draw old committed cache as base
      canvas.drawImage(_committedMaskCache!, Offset.zero, Paint());
      // Only render strokes beyond what the cache already covers
      final newStrokes = strokes.sublist(_committedCachedStrokeCount);
      _drawStrokeList(canvas, newStrokes, imageRect, sourceWidth, sourceHeight,
          maskColor, maskOpacity, maskShowBorder, maskPattern, brushRound);
    } else {
      // Full re-render (first time, undo, settings change, etc.)
      _drawStrokeList(canvas, strokes, imageRect, sourceWidth, sourceHeight,
          maskColor, maskOpacity, maskShowBorder, maskPattern, brushRound);
    }

    final strokeCount = strokes.length;
    final picture = recorder.endRecording();
    picture.toImage(width, height).then((image) {
      picture.dispose();
      if (!mounted) {
        image.dispose();
        return;
      }
      setState(() {
        _committedMaskCache?.dispose();
        _committedMaskCache = image;
        _committedCacheKey = cacheKey;
        _committedCachedStrokeCount = strokeCount;
      });
    });
  }

  /// Render a list of strokes onto the canvas with full compositing.
  void _drawStrokeList(
    Canvas canvas, List<MaskStroke> strokes, Rect imageRect,
    int sourceWidth, int sourceHeight, int maskColor, double maskOpacity,
    bool maskShowBorder, MaskPattern maskPattern, bool brushRound,
  ) {
    final paintStrokes = strokes.where((s) => !s.isErase).toList();
    if (paintStrokes.isNotEmpty) {
      canvas.saveLayer(
        null,
        Paint()..color = Color.fromARGB((maskOpacity * 255).round(), 0, 0, 0),
      );
      final brush = Paint()
        ..color = Color(maskColor)
        ..style = PaintingStyle.fill
        ..isAntiAlias = false;
      for (final stroke in paintStrokes) {
        _drawStrokeGeometryImpl(canvas, stroke, brush, imageRect, sourceWidth, sourceHeight, brushRound);
      }
      if (maskPattern != MaskPattern.solid) {
        _drawPatternImpl(canvas, paintStrokes, imageRect, maskPattern);
      }
      canvas.restore();

      if (maskShowBorder) {
        final borderBrush = Paint()
          ..color = Color(maskColor).withValues(alpha: 0.8)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5
          ..isAntiAlias = true;
        for (final stroke in paintStrokes) {
          _drawStrokeBorderImpl(canvas, stroke, borderBrush, imageRect, sourceWidth, sourceHeight);
        }
      }
    }

    final eraseStrokes = strokes.where((s) => s.isErase).toList();
    if (eraseStrokes.isNotEmpty) {
      canvas.saveLayer(
        null,
        Paint()..color = Color.fromARGB((maskOpacity * 0.66 * 255).round(), 0, 0, 0),
      );
      final brush = Paint()
        ..color = const Color(0xFF000000)
        ..style = PaintingStyle.fill
        ..isAntiAlias = false;
      for (final stroke in eraseStrokes) {
        _drawStrokeGeometryImpl(canvas, stroke, brush, imageRect, sourceWidth, sourceHeight, brushRound);
      }
      canvas.restore();
    }
  }

  /// Incrementally rasterize the active stroke: reuse the previous cache and
  /// only draw the newly added points (and their interpolation segments).
  void _updateActiveStrokeCache({
    required MaskStroke stroke,
    required Rect imageRect,
    required int sourceWidth,
    required int sourceHeight,
    required int maskColor,
    required double maskOpacity,
    required MaskPattern maskPattern,
    required bool brushRound,
  }) {
    final width = imageRect.right.ceil() + imageRect.left.ceil();
    final height = imageRect.bottom.ceil() + imageRect.top.ceil();
    if (width <= 0 || height <= 0) return;

    final strokeId = identityHashCode(stroke);
    final prevCount = (strokeId == _activeCachedStrokeId) ? _activeCachedPointCount : 0;
    final totalPoints = stroke.points.length;
    if (totalPoints <= prevCount && _activeStrokeCache != null && strokeId == _activeCachedStrokeId) return;

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder, Offset.zero & Size(width.toDouble(), height.toDouble()));

    // Draw previous cache as base
    if (_activeStrokeCache != null && prevCount > 0 && strokeId == _activeCachedStrokeId) {
      canvas.drawImage(_activeStrokeCache!, Offset.zero, Paint());
    }

    // Only draw the new points
    final newStartIdx = (strokeId == _activeCachedStrokeId) ? prevCount : 0;

    if (!stroke.isErase) {
      canvas.saveLayer(null, Paint()..color = Color.fromARGB((maskOpacity * 255).round(), 0, 0, 0));
      final brush = Paint()
        ..color = Color(maskColor)
        ..style = PaintingStyle.fill
        ..isAntiAlias = false;
      _drawStrokePointsRange(canvas, stroke, brush, imageRect, sourceWidth, sourceHeight, brushRound, newStartIdx, totalPoints);
      if (maskPattern != MaskPattern.solid) {
        _drawPatternImpl(canvas, [stroke], imageRect, maskPattern);
      }
      canvas.restore();
    } else {
      canvas.saveLayer(null, Paint()..color = Color.fromARGB((maskOpacity * 0.66 * 255).round(), 0, 0, 0));
      final brush = Paint()
        ..color = const Color(0xFF000000)
        ..style = PaintingStyle.fill
        ..isAntiAlias = false;
      _drawStrokePointsRange(canvas, stroke, brush, imageRect, sourceWidth, sourceHeight, brushRound, newStartIdx, totalPoints);
      canvas.restore();
    }

    final picture = recorder.endRecording();
    picture.toImage(width, height).then((image) {
      picture.dispose();
      if (!mounted) {
        image.dispose();
        return;
      }
      setState(() {
        _activeStrokeCache?.dispose();
        _activeStrokeCache = image;
        _activeCachedPointCount = totalPoints;
        _activeCachedStrokeId = strokeId;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final notifier = context.watch<Img2ImgNotifier>();
    _notifierRef = notifier;
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
        _viewportSize = containerSize;

        // Manage committed-stroke raster cache
        final committedCacheKey = _buildCacheKey(
          session.maskStrokes, _imageRect,
          session.sourceWidth, session.sourceHeight,
          notifier.maskColor, notifier.maskOpacity,
          notifier.maskShowBorder, notifier.maskPattern, notifier.maskBrushRound,
        );
        if (committedCacheKey != _committedCacheKey) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            _rasterizeCommittedStrokes(
              strokes: session.maskStrokes,
              imageRect: _imageRect,
              sourceWidth: session.sourceWidth,
              sourceHeight: session.sourceHeight,
              maskColor: notifier.maskColor,
              maskOpacity: notifier.maskOpacity,
              maskShowBorder: notifier.maskShowBorder,
              maskPattern: notifier.maskPattern,
              brushRound: notifier.maskBrushRound,
              cacheKey: committedCacheKey,
            );
          });
        }

        // Manage active-stroke incremental cache
        final active = notifier.activeStroke;
        if (active != null && active.points.isNotEmpty) {
          final activeId = identityHashCode(active);
          final cachedCount = (activeId == _activeCachedStrokeId) ? _activeCachedPointCount : 0;
          if (active.points.length > cachedCount || activeId != _activeCachedStrokeId) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!mounted) return;
              _updateActiveStrokeCache(
                stroke: active,
                imageRect: _imageRect,
                sourceWidth: session.sourceWidth,
                sourceHeight: session.sourceHeight,
                maskColor: notifier.maskColor,
                maskOpacity: notifier.maskOpacity,
                maskPattern: notifier.maskPattern,
                brushRound: notifier.maskBrushRound,
              );
            });
          }
        } else if (active == null && _activeStrokeCache != null) {
          // Stroke was committed or cancelled — clear active cache immediately
          // (no setState needed; the committed cache rebuild will trigger a repaint)
          _activeStrokeCache?.dispose();
          _activeStrokeCache = null;
          _activeCachedPointCount = 0;
          _activeCachedStrokeId = null;
        }

        final isPanMode = _spaceHeld || _middleMouseHeld;

        return KeyboardListener(
          focusNode: _keyboardFocusNode,
          autofocus: true,
          onKeyEvent: (event) {
            if (event.logicalKey == LogicalKeyboardKey.space) {
              setState(() => _spaceHeld = event is KeyDownEvent);
              return;
            }
            if (event is! KeyDownEvent) return;
            final ctrl = HardwareKeyboard.instance.isControlPressed ||
                HardwareKeyboard.instance.isMetaPressed;
            if (ctrl && event.logicalKey == LogicalKeyboardKey.keyZ) {
              notifier.undoLastStroke();
            }
          },
          child: Listener(
            // Scale gestures end/restart whenever the pointer count changes.
            // Cancel before the recognizer can commit that partial stroke, and
            // keep painting disabled until a fresh contact sequence begins.
            onPointerDown: (event) {
              if (_pointers.isEmpty) _multiPointerGesture = false;
              _pointers.add(event.pointer);
              if (_pointers.length > 1) {
                _multiPointerGesture = true;
                _strokeActive = false;
                notifier.cancelStroke();
              }
              if (event.buttons & kMiddleMouseButton != 0) {
                setState(() => _middleMouseHeld = true);
              }
            },
            onPointerUp: (event) {
              _pointers.remove(event.pointer);
              if (_middleMouseHeld) setState(() => _middleMouseHeld = false);
            },
            onPointerCancel: (event) {
              _pointers.remove(event.pointer);
              _strokeActive = false;
              notifier.cancelStroke();
              if (_middleMouseHeld) setState(() => _middleMouseHeld = false);
            },
            onPointerSignal: (event) {
              if (event is PointerScrollEvent) {
                _onPointerSignal(event, notifier);
              }
            },
            child: MouseRegion(
              cursor: isPanMode
                  ? SystemMouseCursors.grab
                  : SystemMouseCursors.none,
              // Drive the brush-preview overlay on plain hover. The overlay lives
              // inside the viewer's child, which is wrapped in IgnorePointer
              // (so the scale recognizer owns all pointer input) — that also
              // swallows hover, so the overlay can't track the mouse itself.
              // We feed it from out here instead.
              onHover: (event) => _updateCursorPreview(event.localPosition),
              onExit: (_) => _cursorKey.currentState?.updatePosition(null),
              child: InteractiveViewer(
                transformationController: _zoomController,
                // Brushing and pinch-zoom both run through InteractiveViewer's own
                // scale recognizer via onInteraction* below — there is no competing
                // child gesture detector, so there is no gesture-arena fight.
                //
                // Why this matters: InteractiveViewer's ScaleGestureRecognizer claims
                // pointers eagerly and wins the arena over any child PanGestureRecognizer.
                // The previous design put drawing on a child GestureDetector and tried to
                // hand the pinch to the viewer by flipping `scaleEnabled` only once a
                // second finger arrived — but the arena resolves in the same frame the
                // second pointer lands, before that rebuild, so scale was still disabled
                // when it needed to win and pinch-zoom never engaged on mobile.
                //
                // Now: scale is always enabled. A single-pointer interaction maps to a
                // pan, which is ignored while painting (panEnabled is false unless the
                // user is in space/middle-mouse pan mode) — but onInteractionUpdate still
                // fires, giving us the focal point to paint with. Two pointers engage the
                // real pinch-zoom; the in-progress one-finger stroke is discarded so it
                // isn't left behind.
                panEnabled: isPanMode,
                scaleEnabled: true,
                onInteractionStart: (details) =>
                    _onInteractionStart(details, notifier, isPanMode),
                onInteractionUpdate: (details) =>
                    _onInteractionUpdate(details, notifier, isPanMode),
                onInteractionEnd: (details) =>
                    _onInteractionEnd(details, notifier),
                boundaryMargin: EdgeInsets.zero,
                minScale: kCanvasMinScale,
                maxScale: kCanvasMaxScale,
                // InteractiveViewer's own Listener sees the same wheel
                // PointerSignalEvents as the handler above (both are in the
                // hit path), so it would apply a second zoom per tick. An
                // infinite scaleFactor turns its wheel response into a no-op
                // while leaving pinch-zoom untouched.
                scaleFactor: double.infinity,
                child: IgnorePointer(
                  ignoring: true,
                  child: SizedBox(
                    width: containerSize.width,
                    height: containerSize.height,
                    child: Stack(
                      children: [
                        // Source image
                        Positioned.fill(
                          child: RepaintBoundary(
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
                        ),

                        // Mask overlay
                        Positioned.fill(
                          child: CustomPaint(
                            painter: _MaskOverlayPainter(
                              strokes: session.maskStrokes,
                              activeStroke: notifier.activeStroke,
                              committedCache: _committedMaskCache,
                              committedCacheValid: committedCacheKey == _committedCacheKey,
                              committedCachedStrokeCount: _committedCachedStrokeCount,
                              activeStrokeCache: _activeStrokeCache,
                              activeStrokeCacheValid: active != null && identityHashCode(active) == _activeCachedStrokeId && _activeCachedPointCount > 0,
                              imageRect: _imageRect,
                              sourceWidth: session.sourceWidth,
                              sourceHeight: session.sourceHeight,
                              maskColor: notifier.maskColor,
                              maskOpacity: notifier.maskOpacity,
                              maskShowBorder: notifier.maskShowBorder,
                              maskPattern: notifier.maskPattern,
                              brushRound: notifier.maskBrushRound,
                            ),
                          ),
                        ),

                        // Cursor preview
                        Positioned.fill(
                          child: _CursorPreview(
                            key: _cursorKey,
                            brushRadius: notifier.brushRadius,
                            isErase: notifier.isEraseMode,
                            imageRect: _imageRect,
                            sourceWidth: session.sourceWidth,
                            sourceHeight: session.sourceHeight,
                            maskColor: notifier.maskColor,
                            zoomController: _zoomController,
                            brushRound: notifier.maskBrushRound,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _onPointerSignal(PointerScrollEvent event, Img2ImgNotifier notifier) {
    final keyboard = HardwareKeyboard.instance;
    final ctrlHeld = keyboard.isControlPressed || keyboard.isMetaPressed;

    if (ctrlHeld) {
      // Ctrl + scroll: adjust brush size
      final delta = event.scrollDelta.dy > 0 ? -0.005 : 0.005;
      notifier.setBrushRadius(notifier.brushRadius + delta);
    } else {
      // Plain scroll: cursor-anchored zoom, clamped to [fit, 16x] so
      // zooming out converges on the centered fit view (#18). The old
      // matrix math anchored in the child's coordinate space, so the
      // anchor drifted once zoomed, and nothing bounded scale or pan.
      _zoomController.value = wheelZoomMatrix(
        current: _zoomController.value,
        focalViewport: event.localPosition,
        zoomIn: event.scrollDelta.dy < 0,
        viewportSize: _viewportSize,
      );
    }
  }

  // Whether the current interaction is a single-finger brush stroke (vs. a
  // pinch-zoom or a pan-mode drag). Set in _onInteractionStart, cleared on end.
  bool _strokeActive = false;

  // Wheel/trackpad signals make InteractiveViewer synthesize a
  // start/update/end triple with pointerCount 0 — real gestures always report
  // at least one pointer. Without this guard, every wheel tick over the canvas
  // painted a dot at the cursor.
  bool _ignoreSyntheticInteraction = false;

  void _onInteractionStart(
      ScaleStartDetails details, Img2ImgNotifier notifier, bool isPanMode) {
    if (details.pointerCount == 0) {
      _ignoreSyntheticInteraction = true;
      return;
    }
    // Two-plus fingers, or an explicit pan-mode drag: hand the gesture to the
    // viewer (zoom/pan). Don't start a brush stroke.
    if (details.pointerCount >= 2) _multiPointerGesture = true;
    if (isPanMode || _multiPointerGesture) {
      _strokeActive = false;
      notifier.cancelStroke();
      return;
    }
    final normalized = _toScene(details.localFocalPoint);
    if (normalized != null) {
      _strokeActive = true;
      notifier.beginStroke(normalized);
      _updateCursorPreview(details.localFocalPoint);
    }
  }

  void _onInteractionUpdate(
      ScaleUpdateDetails details, Img2ImgNotifier notifier, bool isPanMode) {
    if (_ignoreSyntheticInteraction) return;
    // A second finger landed mid-stroke → this became a pinch. Abandon the
    // partial one-finger stroke and let the viewer scale.
    if (details.pointerCount >= 2) {
      _multiPointerGesture = true;
      if (_strokeActive) {
        _strokeActive = false;
        notifier.cancelStroke();
      }
      return;
    }
    if (!_strokeActive || isPanMode || _multiPointerGesture) return;
    final normalized = _toScene(details.localFocalPoint);
    if (normalized != null) {
      notifier.addStrokePoint(normalized);
    }
    _updateCursorPreview(details.localFocalPoint);
  }

  void _onInteractionEnd(ScaleEndDetails details, Img2ImgNotifier notifier) {
    if (_ignoreSyntheticInteraction) {
      _ignoreSyntheticInteraction = false;
      return;
    }
    if (_strokeActive) {
      _strokeActive = false;
      if (_multiPointerGesture || details.pointerCount > 0) {
        notifier.cancelStroke();
      } else {
        notifier.endStroke();
      }
    }
  }

  /// Maps a focal point reported by InteractiveViewer (in the viewport's
  /// untransformed coordinate space) into the child's scene coordinates via the
  /// inverse zoom transform, then normalizes against the rendered image rect.
  Offset? _toScene(Offset viewportPoint) {
    if (_imageRect.width <= 0 || _imageRect.height <= 0) return null;
    final scenePoint = _zoomController.toScene(viewportPoint);
    final x = (scenePoint.dx - _imageRect.left) / _imageRect.width;
    final y = (scenePoint.dy - _imageRect.top) / _imageRect.height;
    return Offset(x.clamp(0.0, 1.0), y.clamp(0.0, 1.0));
  }

  /// Pushes the cursor-preview position. [viewportPoint] is in the viewport's
  /// untransformed space (as reported by InteractiveViewer / the outer
  /// MouseRegion); the preview overlay lives *inside* the viewer's transformed
  /// child, so it must be drawn in scene space — convert before handing it over.
  void _updateCursorPreview(Offset viewportPoint) {
    _cursorKey.currentState?.updatePosition(_zoomController.toScene(viewportPoint));
  }
}

// ---------------------------------------------------------------------------
// Top-level drawing helpers (shared by rasterizer + painter)
// ---------------------------------------------------------------------------

/// Grid-snap and brush parameters derived from a stroke + imageRect.
class _BrushParams {
  final double gridW, gridH, r;
  final int rCells;
  final double limitSq; // (rCells + 0.5)^2 — used for round brush check
  final Rect imageRect;
  final bool brushRound;

  _BrushParams({
    required this.gridW, required this.gridH, required this.r,
    required this.rCells, required this.limitSq, required this.imageRect,
    required this.brushRound,
  });

  factory _BrushParams.from(MaskStroke stroke, Rect imageRect, int sourceWidth, int sourceHeight, bool brushRound) {
    const grid = 8;
    final gridW = grid / sourceWidth * imageRect.width;
    final gridH = grid / sourceHeight * imageRect.height;
    final rawR = stroke.radius * imageRect.width;
    final rCells = ((rawR / gridW).ceil()).clamp(1, sourceWidth);
    final r = rCells * gridW;
    final limit = rCells + 0.5;
    return _BrushParams(gridW: gridW, gridH: gridH, r: r, rCells: rCells, limitSq: limit * limit, imageRect: imageRect, brushRound: brushRound);
  }
}

void _drawBrushAt(Canvas canvas, double cx, double cy, Paint paint, _BrushParams p) {
  final px = p.imageRect.left + ((cx - p.imageRect.left) / p.gridW).floor() * p.gridW;
  final py = p.imageRect.top + ((cy - p.imageRect.top) / p.gridH).floor() * p.gridH;

  if (!p.brushRound) {
    canvas.drawRect(Rect.fromLTWH(px - p.r, py - p.r, p.r * 2, p.r * 2), paint);
    return;
  }

  for (int gx = -p.rCells; gx <= p.rCells; gx++) {
    for (int gy = -p.rCells; gy <= p.rCells; gy++) {
      if (gx * gx + gy * gy <= p.limitSq) {
        canvas.drawRect(
          Rect.fromLTWH(px + gx * p.gridW, py + gy * p.gridH, p.gridW, p.gridH),
          paint,
        );
      }
    }
  }
}

void _drawPointAndInterp(Canvas canvas, MaskStroke stroke, Paint paint, _BrushParams p, int i) {
  final point = stroke.points[i];
  final rawPx = p.imageRect.left + point.dx * p.imageRect.width;
  final rawPy = p.imageRect.top + point.dy * p.imageRect.height;
  _drawBrushAt(canvas, rawPx, rawPy, paint, p);

  // Interpolate from previous point to this one
  if (i > 0) {
    final prev = stroke.points[i - 1];
    final rawX1 = p.imageRect.left + prev.dx * p.imageRect.width;
    final rawY1 = p.imageRect.top + prev.dy * p.imageRect.height;
    final x1 = p.imageRect.left + ((rawX1 - p.imageRect.left) / p.gridW).floor() * p.gridW;
    final y1 = p.imageRect.top + ((rawY1 - p.imageRect.top) / p.gridH).floor() * p.gridH;
    final x2 = p.imageRect.left + ((rawPx - p.imageRect.left) / p.gridW).floor() * p.gridW;
    final y2 = p.imageRect.top + ((rawPy - p.imageRect.top) / p.gridH).floor() * p.gridH;
    final dx = x2 - x1;
    final dy = y2 - y1;
    final steps = [dx.abs(), dy.abs(), 1.0].reduce((a, b) => a > b ? a : b).ceil();
    for (int s = 1; s < steps; s++) {
      final t = s / steps;
      _drawBrushAt(canvas, x1 + dx * t, y1 + dy * t, paint, p);
    }
  }
}

void _drawStrokeGeometryImpl(
  Canvas canvas, MaskStroke stroke, Paint paint,
  Rect imageRect, int sourceWidth, int sourceHeight, bool brushRound,
) {
  final p = _BrushParams.from(stroke, imageRect, sourceWidth, sourceHeight, brushRound);
  for (int i = 0; i < stroke.points.length; i++) {
    _drawPointAndInterp(canvas, stroke, paint, p, i);
  }
}

/// Draw only points in range [startIdx, endIdx) and their interpolation segments.
void _drawStrokePointsRange(
  Canvas canvas, MaskStroke stroke, Paint paint,
  Rect imageRect, int sourceWidth, int sourceHeight, bool brushRound,
  int startIdx, int endIdx,
) {
  final p = _BrushParams.from(stroke, imageRect, sourceWidth, sourceHeight, brushRound);
  final start = startIdx.clamp(0, stroke.points.length);
  final end = endIdx.clamp(start, stroke.points.length);
  // Always start from at least max(start, 0) — but include interpolation from start-1 if start > 0
  final drawFrom = start > 0 ? start : 0;
  for (int i = drawFrom; i < end; i++) {
    _drawPointAndInterp(canvas, stroke, paint, p, i);
  }
}

void _drawPatternImpl(
  Canvas canvas, List<MaskStroke> paintStrokes,
  Rect imageRect, MaskPattern maskPattern,
) {
  canvas.saveLayer(null, Paint()..blendMode = BlendMode.dstIn);
  final patternPaint = Paint()
    ..color = Colors.white
    ..strokeWidth = 1.0
    ..style = PaintingStyle.stroke;

  const spacing = 6.0;
  final maxDim = math.max(imageRect.width, imageRect.height) * 2;

  for (double offset = -maxDim; offset < maxDim; offset += spacing) {
    canvas.drawLine(
      Offset(imageRect.left + offset, imageRect.top),
      Offset(imageRect.left + offset + maxDim, imageRect.top + maxDim),
      patternPaint,
    );
  }

  if (maskPattern == MaskPattern.crosshatch) {
    for (double offset = -maxDim; offset < maxDim; offset += spacing) {
      canvas.drawLine(
        Offset(imageRect.right - offset, imageRect.top),
        Offset(imageRect.right - offset - maxDim, imageRect.top + maxDim),
        patternPaint,
      );
    }
  }

  canvas.restore();
}

void _drawStrokeBorderImpl(
  Canvas canvas, MaskStroke stroke, Paint paint,
  Rect imageRect, int sourceWidth, int sourceHeight,
) {
  const grid = 8;
  final gridW = grid / sourceWidth * imageRect.width;
  final gridH = grid / sourceHeight * imageRect.height;
  final rawR = stroke.radius * imageRect.width;
  final r = ((rawR / gridW).ceil()).clamp(1, sourceWidth) * gridW;

  for (final point in stroke.points) {
    final rawPx = imageRect.left + point.dx * imageRect.width;
    final rawPy = imageRect.top + point.dy * imageRect.height;
    final px = imageRect.left + ((rawPx - imageRect.left) / gridW).floor() * gridW;
    final py = imageRect.top + ((rawPy - imageRect.top) / gridH).floor() * gridH;
    canvas.drawRect(Rect.fromLTWH(px - r, py - r, r * 2, r * 2), paint);
  }
}

/// Paints the mask strokes as a semi-transparent overlay, grid-snapped to 8px.
///
/// When a [committedCache] bitmap is available and [committedCacheValid], it is
/// drawn with a single `drawImage` call instead of replaying all committed
/// stroke geometry. Only the [activeStroke] is rendered live.
class _MaskOverlayPainter extends CustomPainter {
  final List<MaskStroke> strokes;
  final MaskStroke? activeStroke;
  final ui.Image? committedCache;
  final bool committedCacheValid;
  final int committedCachedStrokeCount;
  final ui.Image? activeStrokeCache;
  final bool activeStrokeCacheValid;
  final Rect imageRect;
  final int sourceWidth;
  final int sourceHeight;
  final int maskColor;
  final double maskOpacity;
  final bool maskShowBorder;
  final MaskPattern maskPattern;
  final bool brushRound;

  _MaskOverlayPainter({
    required this.strokes,
    this.activeStroke,
    this.committedCache,
    this.committedCacheValid = false,
    this.committedCachedStrokeCount = 0,
    this.activeStrokeCache,
    this.activeStrokeCacheValid = false,
    required this.imageRect,
    required this.sourceWidth,
    required this.sourceHeight,
    this.maskColor = 0xFFFF0066,
    this.maskOpacity = 0.19,
    this.maskShowBorder = false,
    this.maskPattern = MaskPattern.solid,
    this.brushRound = true,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (imageRect.isEmpty) return;

    // --- Phase 1: Committed strokes ---
    if (committedCache != null && committedCacheValid) {
      // Cache is fully up-to-date
      canvas.drawImage(committedCache!, Offset.zero, Paint());
    } else if (committedCache != null && committedCachedStrokeCount > 0 && strokes.isNotEmpty) {
      // Cache is stale but covers some strokes — draw cache + only the delta
      canvas.drawImage(committedCache!, Offset.zero, Paint());
      if (committedCachedStrokeCount < strokes.length) {
        _drawStrokesDirect(canvas, strokes.sublist(committedCachedStrokeCount));
      }
    } else if (strokes.isNotEmpty) {
      // No cache at all — full fallback (first frame only)
      _drawStrokesDirect(canvas, strokes);
    }

    // --- Phase 2: Active stroke ---
    if (activeStroke != null) {
      if (activeStrokeCache != null && activeStrokeCacheValid) {
        canvas.drawImage(activeStrokeCache!, Offset.zero, Paint());
      } else {
        _drawSingleStrokeLive(canvas, activeStroke!);
      }
    }
  }

  /// Draws a list of strokes directly (the old rendering path, used as fallback).
  void _drawStrokesDirect(Canvas canvas, List<MaskStroke> strokeList) {
    final paintStrokes = strokeList.where((s) => !s.isErase).toList();
    if (paintStrokes.isNotEmpty) {
      canvas.saveLayer(
        null,
        Paint()..color = Color.fromARGB((maskOpacity * 255).round(), 0, 0, 0),
      );
      final brush = Paint()
        ..color = Color(maskColor)
        ..style = PaintingStyle.fill
        ..isAntiAlias = false;
      for (final stroke in paintStrokes) {
        _drawStrokeGeometryImpl(canvas, stroke, brush, imageRect, sourceWidth, sourceHeight, brushRound);
      }
      if (maskPattern != MaskPattern.solid) {
        _drawPatternImpl(canvas, paintStrokes, imageRect, maskPattern);
      }
      canvas.restore();

      if (maskShowBorder) {
        final borderBrush = Paint()
          ..color = Color(maskColor).withValues(alpha: 0.8)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5
          ..isAntiAlias = true;
        for (final stroke in paintStrokes) {
          _drawStrokeBorderImpl(canvas, stroke, borderBrush, imageRect, sourceWidth, sourceHeight);
        }
      }
    }

    final eraseStrokes = strokeList.where((s) => s.isErase).toList();
    if (eraseStrokes.isNotEmpty) {
      canvas.saveLayer(
        null,
        Paint()..color = Color.fromARGB((maskOpacity * 0.66 * 255).round(), 0, 0, 0),
      );
      final brush = Paint()
        ..color = const Color(0xFF000000)
        ..style = PaintingStyle.fill
        ..isAntiAlias = false;
      for (final stroke in eraseStrokes) {
        _drawStrokeGeometryImpl(canvas, stroke, brush, imageRect, sourceWidth, sourceHeight, brushRound);
      }
      canvas.restore();
    }
  }

  /// Draws a single stroke with full compositing (used for the active stroke).
  void _drawSingleStrokeLive(Canvas canvas, MaskStroke stroke) {
    if (!stroke.isErase) {
      canvas.saveLayer(
        null,
        Paint()..color = Color.fromARGB((maskOpacity * 255).round(), 0, 0, 0),
      );
      final brush = Paint()
        ..color = Color(maskColor)
        ..style = PaintingStyle.fill
        ..isAntiAlias = false;
      _drawStrokeGeometryImpl(canvas, stroke, brush, imageRect, sourceWidth, sourceHeight, brushRound);
      if (maskPattern != MaskPattern.solid) {
        _drawPatternImpl(canvas, [stroke], imageRect, maskPattern);
      }
      canvas.restore();

      if (maskShowBorder) {
        final borderBrush = Paint()
          ..color = Color(maskColor).withValues(alpha: 0.8)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5
          ..isAntiAlias = true;
        _drawStrokeBorderImpl(canvas, stroke, borderBrush, imageRect, sourceWidth, sourceHeight);
      }
    } else {
      canvas.saveLayer(
        null,
        Paint()..color = Color.fromARGB((maskOpacity * 0.66 * 255).round(), 0, 0, 0),
      );
      final brush = Paint()
        ..color = const Color(0xFF000000)
        ..style = PaintingStyle.fill
        ..isAntiAlias = false;
      _drawStrokeGeometryImpl(canvas, stroke, brush, imageRect, sourceWidth, sourceHeight, brushRound);
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_MaskOverlayPainter oldDelegate) =>
      strokes != oldDelegate.strokes ||
      activeStroke != oldDelegate.activeStroke ||
      committedCache != oldDelegate.committedCache ||
      committedCacheValid != oldDelegate.committedCacheValid ||
      committedCachedStrokeCount != oldDelegate.committedCachedStrokeCount ||
      activeStrokeCache != oldDelegate.activeStrokeCache ||
      activeStrokeCacheValid != oldDelegate.activeStrokeCacheValid ||
      imageRect != oldDelegate.imageRect ||
      sourceWidth != oldDelegate.sourceWidth ||
      sourceHeight != oldDelegate.sourceHeight ||
      maskColor != oldDelegate.maskColor ||
      maskOpacity != oldDelegate.maskOpacity ||
      maskShowBorder != oldDelegate.maskShowBorder ||
      maskPattern != oldDelegate.maskPattern ||
      brushRound != oldDelegate.brushRound;
}

/// Shows a grid-snapped square cursor that follows the mouse position.
class _CursorPreview extends StatefulWidget {
  final double brushRadius;
  final bool isErase;
  final Rect imageRect;
  final int sourceWidth;
  final int sourceHeight;
  final int maskColor;
  final TransformationController zoomController;
  final bool brushRound;

  const _CursorPreview({
    super.key,
    required this.brushRadius,
    required this.isErase,
    required this.imageRect,
    required this.sourceWidth,
    required this.sourceHeight,
    required this.zoomController,
    this.maskColor = 0xFFFF0066,
    this.brushRound = true,
  });

  @override
  State<_CursorPreview> createState() => _CursorPreviewState();
}

class _CursorPreviewState extends State<_CursorPreview> {
  Offset? _mousePosition;

  /// Sets the preview position in the overlay's (scene) coordinate space, or
  /// null to hide it. Driven externally by [_MaskCanvasState] — this widget sits
  /// behind an IgnorePointer and so can't track the pointer itself.
  void updatePosition(Offset? position) {
    if (!mounted) return;
    setState(() => _mousePosition = position);
  }

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _CursorPainter(
        position: _mousePosition,
        rawRadius: widget.brushRadius * widget.imageRect.width,
        isErase: widget.isErase,
        imageRect: widget.imageRect,
        sourceWidth: widget.sourceWidth,
        sourceHeight: widget.sourceHeight,
        maskColor: widget.maskColor,
        brushRound: widget.brushRound,
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
  final int maskColor;
  final bool brushRound;

  _CursorPainter({
    this.position,
    required this.rawRadius,
    required this.isErase,
    required this.imageRect,
    required this.sourceWidth,
    required this.sourceHeight,
    this.maskColor = 0xFFFF0066,
    this.brushRound = true,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (position == null || rawRadius <= 0 || imageRect.isEmpty) return;

    const grid = 8;
    final gridW = grid / sourceWidth * imageRect.width;
    final gridH = grid / sourceHeight * imageRect.height;

    // Snap brush radius UP to nearest grid cell
    final rCells = ((rawRadius / gridW).ceil()).clamp(1, sourceWidth);
    final r = rCells * gridW;

    // Snap cursor position to grid
    final rawPx = position!.dx;
    final rawPy = position!.dy;
    final px = imageRect.left + ((rawPx - imageRect.left) / gridW).floor() * gridW;
    final py = imageRect.top + ((rawPy - imageRect.top) / gridH).floor() * gridH;

    final paint = Paint()
      ..color = isErase ? Colors.white70 : Color(maskColor).withValues(alpha: 0.67)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    if (brushRound) {
      // Draw circle outline for round brush
      canvas.drawCircle(Offset(px, py), r, paint);
    } else {
      canvas.drawRect(Rect.fromLTWH(px - r, py - r, r * 2, r * 2), paint);
    }

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
      isErase != oldDelegate.isErase ||
      brushRound != oldDelegate.brushRound;
}
