import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import '../models/img2img_session.dart';

class MaskEncoder {
  /// Renders mask strokes to a black/white PNG at [width] x [height].
  /// White pixels = regenerate, black pixels = preserve.
  /// Returns base64-encoded PNG string.
  static Future<String> renderMaskBase64({
    required List<MaskStroke> strokes,
    required int width,
    required int height,
  }) async {
    final result = await compute(_renderMask, _MaskRenderParams(
      strokes: strokes,
      width: width,
      height: height,
    ));
    return result;
  }

  /// Saves a debug copy of the mask PNG to [outputPath].
  /// Call after [renderMaskBase64] with the same base64 result.
  static Future<void> debugSaveMask(String maskBase64, String outputPath) async {
    final bytes = base64Decode(maskBase64);
    final file = File(outputPath);
    await file.writeAsBytes(bytes);
    debugPrint('[MaskEncoder] Debug mask saved to $outputPath');
  }
}

class _MaskRenderParams {
  final List<MaskStroke> strokes;
  final int width;
  final int height;

  _MaskRenderParams({
    required this.strokes,
    required this.width,
    required this.height,
  });
}

String _renderMask(_MaskRenderParams params) {
  // 1. Render mask at full resolution with simple brush strokes
  final image = img.Image(width: params.width, height: params.height, numChannels: 4);
  img.fill(image, color: img.ColorRgba8(0, 0, 0, 0));

  final white = img.ColorRgba8(255, 255, 255, 255);
  final black = img.ColorRgba8(0, 0, 0, 0);

  for (final stroke in params.strokes) {
    final color = stroke.isErase ? black : white;
    final r = (stroke.radius * params.width).round().clamp(1, params.width);

    for (final point in stroke.points) {
      final cx = (point.dx * params.width).round();
      final cy = (point.dy * params.height).round();
      img.fillRect(image,
        x1: cx - r, y1: cy - r, x2: cx + r - 1, y2: cy + r - 1,
        color: color);
    }

    // Interpolate between consecutive points
    for (int i = 0; i < stroke.points.length - 1; i++) {
      final x1 = (stroke.points[i].dx * params.width).round();
      final y1 = (stroke.points[i].dy * params.height).round();
      final x2 = (stroke.points[i + 1].dx * params.width).round();
      final y2 = (stroke.points[i + 1].dy * params.height).round();
      final dx = x2 - x1;
      final dy = y2 - y1;
      final steps = [dx.abs(), dy.abs(), 1].reduce((a, b) => a > b ? a : b);
      for (int s = 1; s <= steps; s++) {
        final t = s / steps;
        final ix = (x1 + dx * t).round();
        final iy = (y1 + dy * t).round();
        img.fillRect(image,
          x1: ix - r, y1: iy - r, x2: ix + r - 1, y2: iy + r - 1,
          color: color);
      }
    }
  }

  // 2. Quantize to 8×8 grid via latent-space bottleneck.
  //    Matches ComfyUI resize_to_naimask for V4: downsample to latent dims
  //    then upsample back with nearest-neighbor. Every 8×8 block becomes
  //    uniformly white or black — no partial-coverage edge artifacts.
  final latentW = ((params.width + 63) ~/ 64) * 8;
  final latentH = ((params.height + 63) ~/ 64) * 8;
  final down = img.copyResize(image,
      width: latentW, height: latentH,
      interpolation: img.Interpolation.nearest);
  final quantized = img.copyResize(down,
      width: latentW * 8, height: latentH * 8,
      interpolation: img.Interpolation.nearest);

  final pngBytes = img.encodePng(quantized);
  return base64Encode(pngBytes);
}
