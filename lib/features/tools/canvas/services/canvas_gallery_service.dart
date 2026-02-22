import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;

import '../models/canvas_layer.dart';
import '../models/canvas_session.dart';

/// Manages saving/loading canvas session sidecar files alongside gallery PNGs.
///
/// For each canvas save, these files are written:
/// - `Canvas_<timestamp>.png` — the flattened composite (visible in gallery)
/// - `Canvas_<timestamp>.canvas.json` — serialized session (layers, history)
/// - `Canvas_<timestamp>.canvas.src` — original source image bytes
/// - `Canvas_<timestamp>.canvas.layer_<id>.png` — image layer sidecar (per image layer)
class CanvasGalleryService {
  CanvasGalleryService._();

  static final _fmt = DateFormat('yyyyMMdd_HHmmssSSS');

  /// Save a flattened canvas image plus sidecar files to the gallery directory.
  /// Returns the saved PNG [File] for gallery registration.
  static Future<File> saveToGallery(
    CanvasSession session,
    Uint8List flattenedBytes,
    String outputDir,
  ) async {
    final name = 'Canvas_${_fmt.format(DateTime.now())}';
    final pngFile = File('$outputDir/$name.png');
    final jsonFile = File('$outputDir/$name.canvas.json');
    final srcFile = File('$outputDir/$name.canvas.src');

    final futures = <Future>[
      pngFile.writeAsBytes(flattenedBytes),
      jsonFile.writeAsString(json.encode(session.toJson())),
      srcFile.writeAsBytes(session.sourceImageBytes),
    ];

    // Write image layer sidecars
    for (final layer in session.layers) {
      if (layer.isImageLayer && layer.imageBytes != null) {
        final imgFile = File('$outputDir/$name.canvas.layer_${layer.id}.png');
        futures.add(imgFile.writeAsBytes(layer.imageBytes!));
      }
    }

    await Future.wait(futures);
    return pngFile;
  }

  /// Load a full [CanvasSession] from sidecar files next to the given PNG path.
  /// Returns null if sidecars don't exist.
  static Future<CanvasSession?> loadSession(String pngPath) async {
    final base = _sidecarBase(pngPath);
    if (base == null) return null;

    final jsonFile = File('$base.canvas.json');
    final srcFile = File('$base.canvas.src');

    if (!await jsonFile.exists() || !await srcFile.exists()) return null;

    try {
      final jsonStr = await jsonFile.readAsString();
      final sourceBytes = await srcFile.readAsBytes();
      final map = json.decode(jsonStr) as Map<String, dynamic>;

      // Reconstruct layers with image bytes from sidecars
      final layerJsonList = map['layers'] as List? ?? [];
      final dir = p.dirname(pngPath);
      final baseName = p.basenameWithoutExtension(pngPath);
      final layers = <CanvasLayer>[];
      for (final j in layerJsonList) {
        final layerMap = j as Map<String, dynamic>;
        Uint8List? imgBytes;
        if (layerMap['hasImage'] == true) {
          final imgFile = File('$dir/$baseName.canvas.layer_${layerMap['id']}.png');
          if (await imgFile.exists()) {
            imgBytes = await imgFile.readAsBytes();
          }
        }
        layers.add(CanvasLayer.fromJson(layerMap, imageBytes: imgBytes));
      }

      return CanvasSession(
        sourceImageBytes: sourceBytes,
        sessionId: map['sessionId'] as String,
        sourceWidth: map['sourceWidth'] as int,
        sourceHeight: map['sourceHeight'] as int,
        activeLayerId: map['activeLayerId'] as String,
        layers: layers,
        history: [], // History is not restored for gallery round-trips
        historyIndex: 0,
      );
    } catch (e) {
      debugPrint('CanvasGalleryService.loadSession error: $e');
      return null;
    }
  }

  /// Check whether sidecar files exist for a given gallery PNG.
  static bool hasCanvasState(String pngPath) {
    final base = _sidecarBase(pngPath);
    if (base == null) return false;
    return File('$base.canvas.json').existsSync();
  }

  /// Delete sidecar files alongside the given PNG (if they exist).
  static Future<void> deleteSidecars(String pngPath) async {
    final base = _sidecarBase(pngPath);
    if (base == null) return;

    final dir = p.dirname(pngPath);
    final baseName = p.basenameWithoutExtension(pngPath);

    final jsonFile = File('$base.canvas.json');
    final srcFile = File('$base.canvas.src');

    final futures = <Future>[
      if (await jsonFile.exists()) jsonFile.delete(),
      if (await srcFile.exists()) srcFile.delete(),
    ];

    // Delete any image layer sidecars matching the pattern
    try {
      final directory = Directory(dir);
      final prefix = '$baseName.canvas.layer_';
      await for (final entity in directory.list()) {
        if (entity is File && p.basename(entity.path).startsWith(prefix)) {
          futures.add(entity.delete());
        }
      }
    } catch (_) {
      // Directory listing failed; non-critical
    }

    await Future.wait(futures);
  }

  /// Derive the base path (without extension) from a PNG path.
  /// Returns null if the path doesn't end in `.png`.
  static String? _sidecarBase(String pngPath) {
    if (!pngPath.toLowerCase().endsWith('.png')) return null;
    return pngPath.substring(0, pngPath.length - 4);
  }
}
