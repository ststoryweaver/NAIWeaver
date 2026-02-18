import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;

import '../models/canvas_layer.dart';
import '../models/paint_stroke.dart';

/// Data passed to the isolate for flattening.
class _FlattenPayload {
  final Uint8List sourceBytes;
  final int sourceWidth;
  final int sourceHeight;
  final List<Map<String, dynamic>> layersJson;
  final Map<String, Uint8List> textOverlays;

  _FlattenPayload({
    required this.sourceBytes,
    required this.sourceWidth,
    required this.sourceHeight,
    required this.layersJson,
    this.textOverlays = const {},
  });
}

/// Composites visible layers onto the source image using the `image` package.
/// Returns flattened PNG bytes.
class CanvasFlattenService {
  static Future<Uint8List> flatten({
    required Uint8List sourceBytes,
    required int sourceWidth,
    required int sourceHeight,
    required List<CanvasLayer> visibleLayers,
    Map<String, Uint8List> textOverlays = const {},
  }) {
    final payload = _FlattenPayload(
      sourceBytes: sourceBytes,
      sourceWidth: sourceWidth,
      sourceHeight: sourceHeight,
      layersJson: visibleLayers.map((l) => l.toJson()).toList(),
      textOverlays: textOverlays,
    );
    return compute(_flattenInIsolate, payload);
  }
}

Uint8List _flattenInIsolate(_FlattenPayload payload) {
  final source = img.decodeImage(payload.sourceBytes);
  if (source == null) return payload.sourceBytes;

  final result = img.Image.from(source);
  final layers = payload.layersJson.map((j) => CanvasLayer.fromJson(j)).toList();

  for (final layer in layers) {
    if (!layer.visible || layer.strokes.isEmpty) continue;

    // Create a transparent overlay for this layer
    final overlay = img.Image(
      width: payload.sourceWidth,
      height: payload.sourceHeight,
      numChannels: 4,
    );

    // Render all strokes onto the overlay
    for (final stroke in layer.strokes) {
      _renderStroke(overlay, stroke, payload.sourceWidth, payload.sourceHeight);
    }

    // Composite pre-rendered text overlay for this layer
    final textPng = payload.textOverlays[layer.id];
    if (textPng != null) {
      final textImage = img.decodePng(textPng);
      if (textImage != null) {
        img.compositeImage(overlay, textImage);
      }
    }

    // Apply layer opacity to the overlay
    if (layer.opacity < 1.0) {
      for (int y = 0; y < overlay.height; y++) {
        for (int x = 0; x < overlay.width; x++) {
          final p = overlay.getPixel(x, y);
          final a = p.a.toInt();
          if (a > 0) {
            overlay.setPixelRgba(
                x, y, p.r.toInt(), p.g.toInt(), p.b.toInt(),
                (a * layer.opacity).round().clamp(0, 255));
          }
        }
      }
    }

    // Composite layer onto result with blend mode
    if (layer.blendMode == CanvasBlendMode.normal) {
      img.compositeImage(result, overlay);
    } else {
      _compositeWithBlendMode(result, overlay, layer.blendMode);
    }
  }

  return Uint8List.fromList(img.encodePng(result));
}

void _renderStroke(
  img.Image overlay,
  PaintStroke stroke,
  int imgWidth,
  int imgHeight,
) {
  switch (stroke.strokeType) {
    case StrokeType.fill:
      _renderFillStroke(overlay, stroke, imgWidth, imgHeight);

    case StrokeType.freehand:
      final points = stroke.smooth
          ? _subdivideSmoothPoints(stroke.points)
          : stroke.points;
      _renderFreehandPoints(overlay, points, stroke, imgWidth, imgHeight);

    case StrokeType.line:
      // Line: 2 points, render as freehand between them
      _renderFreehandPoints(overlay, stroke.points, stroke, imgWidth, imgHeight);

    case StrokeType.rectangle:
      _renderRectangleStroke(overlay, stroke, imgWidth, imgHeight);

    case StrokeType.circle:
      _renderCircleStroke(overlay, stroke, imgWidth, imgHeight);

    case StrokeType.text:
      break; // text strokes are handled via pre-rendered PNG overlays
  }
}

/// Fill every pixel in the overlay with the stroke's color+opacity.
void _renderFillStroke(
  img.Image overlay,
  PaintStroke stroke,
  int imgWidth,
  int imgHeight,
) {
  final a = ((stroke.colorValue >> 24) & 0xFF);
  final red = (stroke.colorValue >> 16) & 0xFF;
  final green = (stroke.colorValue >> 8) & 0xFF;
  final blue = stroke.colorValue & 0xFF;
  final strokeAlpha = (a * stroke.opacity).round().clamp(0, 255);

  for (int y = 0; y < imgHeight; y++) {
    for (int x = 0; x < imgWidth; x++) {
      if (stroke.isErase) {
        overlay.setPixelRgba(x, y, 0, 0, 0, 0);
      } else {
        final existing = overlay.getPixel(x, y);
        final ea = existing.a.toInt();
        if (ea == 0) {
          overlay.setPixelRgba(x, y, red, green, blue, strokeAlpha);
        } else {
          final er = existing.r.toInt();
          final eg = existing.g.toInt();
          final eb = existing.b.toInt();
          final srcA = strokeAlpha / 255.0;
          final dstA = ea / 255.0;
          final outA = srcA + dstA * (1 - srcA);
          if (outA > 0) {
            final outR = ((red * srcA + er * dstA * (1 - srcA)) / outA)
                .round().clamp(0, 255);
            final outG = ((green * srcA + eg * dstA * (1 - srcA)) / outA)
                .round().clamp(0, 255);
            final outB = ((blue * srcA + eb * dstA * (1 - srcA)) / outA)
                .round().clamp(0, 255);
            overlay.setPixelRgba(
                x, y, outR, outG, outB, (outA * 255).round().clamp(0, 255));
          }
        }
      }
    }
  }
}

void _renderFreehandPoints(
  img.Image overlay,
  List<Offset> points,
  PaintStroke stroke,
  int imgWidth,
  int imgHeight,
) {
  final radiusPx = (stroke.radius * imgWidth).round();
  final r = math.max(radiusPx, 1);

  final a = ((stroke.colorValue >> 24) & 0xFF);
  final red = (stroke.colorValue >> 16) & 0xFF;
  final green = (stroke.colorValue >> 8) & 0xFF;
  final blue = stroke.colorValue & 0xFF;
  final strokeAlpha = (a * stroke.opacity).round().clamp(0, 255);

  for (int i = 0; i < points.length; i++) {
    _drawCircle(
      overlay,
      points[i].dx,
      points[i].dy,
      r,
      red,
      green,
      blue,
      strokeAlpha,
      stroke.isErase,
      imgWidth,
      imgHeight,
    );

    if (i < points.length - 1) {
      final p1 = points[i];
      final p2 = points[i + 1];
      final dx = (p2.dx - p1.dx) * imgWidth;
      final dy = (p2.dy - p1.dy) * imgHeight;
      final dist = math.sqrt(dx * dx + dy * dy);
      final steps = math.max(dist / math.max(r * 0.5, 1), 1).ceil();
      for (int s = 1; s < steps; s++) {
        final t = s / steps;
        final nx = p1.dx + (p2.dx - p1.dx) * t;
        final ny = p1.dy + (p2.dy - p1.dy) * t;
        _drawCircle(
          overlay, nx, ny, r, red, green, blue, strokeAlpha,
          stroke.isErase, imgWidth, imgHeight,
        );
      }
    }
  }
}

/// Subdivide points using quadratic bezier midpoint algorithm for smooth curves.
List<Offset> _subdivideSmoothPoints(List<Offset> points) {
  if (points.length <= 2) return points;

  const subdivisions = 8;
  final result = <Offset>[points.first];

  for (int i = 0; i < points.length - 1; i++) {
    final current = points[i];
    final next = points[i + 1];
    final midX = (current.dx + next.dx) / 2;
    final midY = (current.dy + next.dy) / 2;
    final mid = Offset(midX, midY);

    // Generate subdivisions between current control point and midpoint
    for (int s = 1; s <= subdivisions; s++) {
      final t = s / subdivisions;
      // Quadratic bezier: B(t) = (1-t)^2*P0 + 2(1-t)t*P1 + t^2*P2
      // P0 = previous mid (or current for first), P1 = current, P2 = mid
      final prevMid = i == 0
          ? current
          : Offset(
              (points[i - 1].dx + current.dx) / 2,
              (points[i - 1].dy + current.dy) / 2,
            );
      final omt = 1 - t;
      final bx = omt * omt * prevMid.dx + 2 * omt * t * current.dx + t * t * mid.dx;
      final by = omt * omt * prevMid.dy + 2 * omt * t * current.dy + t * t * mid.dy;
      result.add(Offset(bx, by));
    }
  }

  result.add(points.last);
  return result;
}

/// Render a rectangle as 4 edge line segments.
void _renderRectangleStroke(
  img.Image overlay,
  PaintStroke stroke,
  int imgWidth,
  int imgHeight,
) {
  if (stroke.points.length < 2) return;
  final p1 = stroke.points.first;
  final p2 = stroke.points.last;

  // 4 corners
  final tl = p1;
  final tr = Offset(p2.dx, p1.dy);
  final br = p2;
  final bl = Offset(p1.dx, p2.dy);

  // 4 edges as point pairs
  final edges = [
    [tl, tr],
    [tr, br],
    [br, bl],
    [bl, tl],
  ];

  for (final edge in edges) {
    _renderFreehandPoints(overlay, edge, stroke, imgWidth, imgHeight);
  }
}

/// Render a circle/ellipse as dense points along the perimeter.
void _renderCircleStroke(
  img.Image overlay,
  PaintStroke stroke,
  int imgWidth,
  int imgHeight,
) {
  if (stroke.points.length < 2) return;
  final p1 = stroke.points.first;
  final p2 = stroke.points.last;

  final cx = (p1.dx + p2.dx) / 2;
  final cy = (p1.dy + p2.dy) / 2;
  final rx = (p2.dx - p1.dx).abs() / 2;
  final ry = (p2.dy - p1.dy).abs() / 2;

  const segments = 72;
  final perimeterPoints = <Offset>[];
  for (int i = 0; i <= segments; i++) {
    final angle = 2 * math.pi * i / segments;
    perimeterPoints.add(Offset(
      cx + rx * math.cos(angle),
      cy + ry * math.sin(angle),
    ));
  }

  _renderFreehandPoints(overlay, perimeterPoints, stroke, imgWidth, imgHeight);
}

void _drawCircle(
  img.Image image,
  double nx,
  double ny,
  int radius,
  int red,
  int green,
  int blue,
  int alpha,
  bool isErase,
  int imgWidth,
  int imgHeight,
) {
  final cx = (nx * imgWidth).round();
  final cy = (ny * imgHeight).round();

  for (int dy = -radius; dy <= radius; dy++) {
    for (int dx = -radius; dx <= radius; dx++) {
      if (dx * dx + dy * dy > radius * radius) continue;
      final px = cx + dx;
      final py = cy + dy;
      if (px < 0 || px >= imgWidth || py < 0 || py >= imgHeight) continue;

      if (isErase) {
        image.setPixelRgba(px, py, 0, 0, 0, 0);
      } else {
        final existing = image.getPixel(px, py);
        final ea = existing.a.toInt();
        final er = existing.r.toInt();
        final eg = existing.g.toInt();
        final eb = existing.b.toInt();

        if (ea == 0) {
          image.setPixelRgba(px, py, red, green, blue, alpha);
        } else {
          final srcA = alpha / 255.0;
          final dstA = ea / 255.0;
          final outA = srcA + dstA * (1 - srcA);
          if (outA > 0) {
            final outR = ((red * srcA + er * dstA * (1 - srcA)) / outA)
                .round()
                .clamp(0, 255);
            final outG = ((green * srcA + eg * dstA * (1 - srcA)) / outA)
                .round()
                .clamp(0, 255);
            final outB = ((blue * srcA + eb * dstA * (1 - srcA)) / outA)
                .round()
                .clamp(0, 255);
            image.setPixelRgba(
                px, py, outR, outG, outB, (outA * 255).round().clamp(0, 255));
          }
        }
      }
    }
  }
}

/// Composite overlay onto result using a non-normal blend mode (pixel-by-pixel).
void _compositeWithBlendMode(
    img.Image dst, img.Image src, CanvasBlendMode mode) {
  for (int y = 0; y < dst.height && y < src.height; y++) {
    for (int x = 0; x < dst.width && x < src.width; x++) {
      final sp = src.getPixel(x, y);
      final srcA = sp.a.toInt();
      if (srcA == 0) continue;

      final dp = dst.getPixel(x, y);
      final dstR = dp.r.toInt();
      final dstG = dp.g.toInt();
      final dstB = dp.b.toInt();
      final dstA = dp.a.toInt();
      final srcR = sp.r.toInt();
      final srcG = sp.g.toInt();
      final srcB = sp.b.toInt();

      // Blend per-channel
      final blendR = _blendChannel(srcR, dstR, mode);
      final blendG = _blendChannel(srcG, dstG, mode);
      final blendB = _blendChannel(srcB, dstB, mode);

      // Apply source alpha to interpolate between dst and blended
      final sa = srcA / 255.0;
      final outR = (dstR + (blendR - dstR) * sa).round().clamp(0, 255);
      final outG = (dstG + (blendG - dstG) * sa).round().clamp(0, 255);
      final outB = (dstB + (blendB - dstB) * sa).round().clamp(0, 255);
      final outA = math.max(dstA, srcA);

      dst.setPixelRgba(x, y, outR, outG, outB, outA);
    }
  }
}

int _blendChannel(int src, int dst, CanvasBlendMode mode) {
  return switch (mode) {
    CanvasBlendMode.normal => src,
    CanvasBlendMode.multiply => (src * dst / 255).round().clamp(0, 255),
    CanvasBlendMode.screen =>
      (src + dst - src * dst / 255).round().clamp(0, 255),
    CanvasBlendMode.overlay => dst < 128
        ? (2 * src * dst / 255).round().clamp(0, 255)
        : (255 - 2 * (255 - src) * (255 - dst) / 255).round().clamp(0, 255),
    CanvasBlendMode.darken => math.min(src, dst),
    CanvasBlendMode.lighten => math.max(src, dst),
  };
}
