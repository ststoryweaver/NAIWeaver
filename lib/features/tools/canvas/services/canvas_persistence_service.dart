import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;

import '../models/canvas_layer.dart';
import '../models/canvas_session.dart';
import '../models/paint_stroke.dart';

/// Auto-save: writes layers.json + source.png to disk, restores sessions.
/// Debounced (500ms). Silently disabled on web.
/// Migrates Phase 1 strokes.json format to layers.json on restore.
class CanvasPersistenceService {
  final String sessionDir;
  Timer? _saveTimer;

  CanvasPersistenceService({required this.sessionDir});

  String get _sourcePath => p.join(sessionDir, 'source.png');
  String get _layersPath => p.join(sessionDir, 'layers.json');
  String get _sessionPath => p.join(sessionDir, 'session.json');
  // Phase 1 legacy path
  String get _strokesPath => p.join(sessionDir, 'strokes.json');

  /// Save session to disk with 500ms debounce.
  void scheduleSave(CanvasSession session) {
    if (kIsWeb) return;
    _saveTimer?.cancel();
    _saveTimer = Timer(const Duration(milliseconds: 500), () {
      _save(session);
    });
  }

  Future<void> _save(CanvasSession session) async {
    try {
      final dir = Directory(sessionDir);
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }

      // Write source image (only if not already saved)
      final sourceFile = File(_sourcePath);
      if (!await sourceFile.exists()) {
        await sourceFile.writeAsBytes(session.sourceImageBytes);
      }

      // Write layers
      final layersData = {
        'layers': session.layers.map((l) => l.toJson()).toList(),
        'activeLayerId': session.activeLayerId,
      };
      await File(_layersPath).writeAsString(jsonEncode(layersData));

      // Write image layer sidecars
      for (final layer in session.layers) {
        if (layer.isImageLayer && layer.imageBytes != null) {
          final imgFile = File(p.join(sessionDir, 'layer_${layer.id}.png'));
          if (!await imgFile.exists()) {
            await imgFile.writeAsBytes(layer.imageBytes!);
          }
        }
      }

      // Write session metadata
      final meta = {
        'sessionId': session.sessionId,
        'sourceWidth': session.sourceWidth,
        'sourceHeight': session.sourceHeight,
      };
      await File(_sessionPath).writeAsString(jsonEncode(meta));

      // Clean up legacy strokes.json if it exists
      final legacyFile = File(_strokesPath);
      if (await legacyFile.exists()) {
        await legacyFile.delete();
      }
    } catch (e) {
      debugPrint('Canvas auto-save failed: $e');
    }
  }

  /// Check if a persisted session exists.
  Future<bool> hasPersistedSession() async {
    if (kIsWeb) return false;
    return await File(_sourcePath).exists() &&
           await File(_sessionPath).exists();
  }

  /// Restore a persisted session. Handles both layers.json and legacy strokes.json.
  Future<CanvasSession?> restore() async {
    if (kIsWeb) return null;
    try {
      final sourceBytes = await File(_sourcePath).readAsBytes();
      final metaJson = jsonDecode(await File(_sessionPath).readAsString())
          as Map<String, dynamic>;

      final sourceWidth = metaJson['sourceWidth'] as int;
      final sourceHeight = metaJson['sourceHeight'] as int;
      final sessionId = metaJson['sessionId'] as String? ?? '';

      // Try layers.json first (Phase 2 format)
      final layersFile = File(_layersPath);
      if (await layersFile.exists()) {
        final layersData = jsonDecode(await layersFile.readAsString())
            as Map<String, dynamic>;
        final layerJsonList = layersData['layers'] as List;
        final layers = <CanvasLayer>[];
        for (final j in layerJsonList) {
          final map = j as Map<String, dynamic>;
          Uint8List? imgBytes;
          if (map['hasImage'] == true) {
            final imgFile = File(p.join(sessionDir, 'layer_${map['id']}.png'));
            if (await imgFile.exists()) {
              imgBytes = await imgFile.readAsBytes();
            }
          }
          layers.add(CanvasLayer.fromJson(map, imageBytes: imgBytes));
        }
        final activeLayerId =
            layersData['activeLayerId'] as String? ?? layers.first.id;

        return CanvasSession(
          sourceImageBytes: sourceBytes,
          sourceWidth: sourceWidth,
          sourceHeight: sourceHeight,
          layers: layers,
          activeLayerId: activeLayerId,
          sessionId: sessionId,
        );
      }

      // Fallback: migrate Phase 1 strokes.json to single layer
      final strokesFile = File(_strokesPath);
      List<PaintStroke> strokes = [];
      if (await strokesFile.exists()) {
        final strokesJson =
            jsonDecode(await strokesFile.readAsString()) as List;
        strokes = strokesJson
            .map((j) => PaintStroke.fromJson(j as Map<String, dynamic>))
            .toList();
      }

      const defaultLayerId = 'layer_1';
      final layer = CanvasLayer(
        id: defaultLayerId,
        name: 'Layer 1',
        strokes: strokes,
      );

      return CanvasSession(
        sourceImageBytes: sourceBytes,
        sourceWidth: sourceWidth,
        sourceHeight: sourceHeight,
        layers: [layer],
        activeLayerId: defaultLayerId,
        sessionId: sessionId,
      );
    } catch (e) {
      debugPrint('Canvas session restore failed: $e');
      return null;
    }
  }

  /// Delete persisted session files.
  Future<void> cleanup() async {
    if (kIsWeb) return;
    _saveTimer?.cancel();
    try {
      final dir = Directory(sessionDir);
      if (await dir.exists()) {
        await dir.delete(recursive: true);
      }
    } catch (e) {
      debugPrint('Canvas session cleanup failed: $e');
    }
  }

  void dispose() {
    _saveTimer?.cancel();
  }
}
