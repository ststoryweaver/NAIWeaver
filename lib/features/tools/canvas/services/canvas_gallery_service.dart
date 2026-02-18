import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';

import '../models/canvas_session.dart';

/// Manages saving/loading canvas session sidecar files alongside gallery PNGs.
///
/// For each canvas save, three files are written:
/// - `Canvas_<timestamp>.png` — the flattened composite (visible in gallery)
/// - `Canvas_<timestamp>.canvas.json` — serialized session (layers, history)
/// - `Canvas_<timestamp>.canvas.src` — original source image bytes
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

    await Future.wait([
      pngFile.writeAsBytes(flattenedBytes),
      jsonFile.writeAsString(json.encode(session.toJson())),
      srcFile.writeAsBytes(session.sourceImageBytes),
    ]);

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
      return CanvasSession.fromJson(map, sourceBytes);
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

    final jsonFile = File('$base.canvas.json');
    final srcFile = File('$base.canvas.src');

    await Future.wait([
      if (await jsonFile.exists()) jsonFile.delete(),
      if (await srcFile.exists()) srcFile.delete(),
    ]);
  }

  /// Derive the base path (without extension) from a PNG path.
  /// Returns null if the path doesn't end in `.png`.
  static String? _sidecarBase(String pngPath) {
    if (!pngPath.toLowerCase().endsWith('.png')) return null;
    return pngPath.substring(0, pngPath.length - 4);
  }
}
