import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;

class ReferenceImageProcessor {
  /// Target dimensions for director reference images.
  static const List<(int, int)> _targets = [
    (1024, 1536), // portrait
    (1536, 1024), // landscape
    (1472, 1472), // square
  ];

  /// Process a source image for use as a director reference.
  /// Picks the best target dimension, resizes maintaining aspect ratio,
  /// pads with black to exact target, encodes PNG, returns (processedBytes, base64).
  static Future<(Uint8List, String)> processImage(Uint8List sourceBytes) {
    return compute(_processInIsolate, sourceBytes);
  }

  /// Process a source image for vibe transfer — resized to standard reference dims.
  static Future<(Uint8List, String)> processVibeImage(Uint8List sourceBytes) {
    return compute(_processInIsolate, sourceBytes);
  }
}

(Uint8List, String) _processInIsolate(Uint8List sourceBytes) {
  final decoded = img.decodeImage(sourceBytes);
  if (decoded == null) throw Exception('Failed to decode reference image');

  final srcAspect = decoded.width / decoded.height;

  // Find best matching target by aspect ratio distance
  double bestDist = double.infinity;
  (int, int) bestTarget = ReferenceImageProcessor._targets[0];
  for (final t in ReferenceImageProcessor._targets) {
    final targetAspect = t.$1 / t.$2;
    final dist = (srcAspect - targetAspect).abs();
    if (dist < bestDist) {
      bestDist = dist;
      bestTarget = t;
    }
  }

  final targetW = bestTarget.$1;
  final targetH = bestTarget.$2;

  // Resize maintaining aspect ratio to fit within target
  final scaleW = targetW / decoded.width;
  final scaleH = targetH / decoded.height;
  final scale = scaleW < scaleH ? scaleW : scaleH;

  final resizedW = (decoded.width * scale).round();
  final resizedH = (decoded.height * scale).round();

  final resized = img.copyResize(decoded, width: resizedW, height: resizedH);

  // Create black canvas at exact target size and composite
  final canvas = img.Image(width: targetW, height: targetH);
  img.fill(canvas, color: img.ColorRgb8(0, 0, 0));

  final offsetX = (targetW - resizedW) ~/ 2;
  final offsetY = (targetH - resizedH) ~/ 2;
  img.compositeImage(canvas, resized, dstX: offsetX, dstY: offsetY);

  final pngBytes = Uint8List.fromList(img.encodePng(canvas));
  final b64 = base64Encode(pngBytes);
  return (pngBytes, b64);
}

