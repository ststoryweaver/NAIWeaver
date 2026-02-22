import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'ml_model_entry.dart';
import 'ml_model_registry.dart';

class MLStorageStats {
  final int downloadedCount;
  final int diskUsageBytes;

  const MLStorageStats({
    required this.downloadedCount,
    required this.diskUsageBytes,
  });

  String get diskUsageLabel {
    if (diskUsageBytes >= 1024 * 1024 * 1024) {
      return '${(diskUsageBytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
    } else if (diskUsageBytes >= 1024 * 1024) {
      return '${(diskUsageBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    } else if (diskUsageBytes >= 1024) {
      return '${(diskUsageBytes / 1024).toStringAsFixed(1)} KB';
    }
    return '$diskUsageBytes B';
  }
}

class MLStorageService {
  static String modelPath(String mlModelsDir, MLModelEntry entry) {
    return p.join(mlModelsDir, entry.filename);
  }

  static String partialPath(String mlModelsDir, MLModelEntry entry) {
    return p.join(mlModelsDir, '${entry.filename}.part');
  }

  static Future<bool> isDownloaded(String mlModelsDir, MLModelEntry entry) {
    return File(modelPath(mlModelsDir, entry)).exists();
  }

  static Future<void> delete(String mlModelsDir, MLModelEntry entry) async {
    final file = File(modelPath(mlModelsDir, entry));
    if (await file.exists()) await file.delete();
  }

  static Future<void> deletePartial(String mlModelsDir, MLModelEntry entry) async {
    final file = File(partialPath(mlModelsDir, entry));
    if (await file.exists()) await file.delete();
  }

  static Future<MLStorageStats> getStats(String mlModelsDir) async {
    int count = 0;
    int bytes = 0;
    for (final entry in MLModelRegistry.all) {
      final file = File(modelPath(mlModelsDir, entry));
      if (await file.exists()) {
        count++;
        bytes += await file.length();
      }
    }
    return MLStorageStats(downloadedCount: count, diskUsageBytes: bytes);
  }

  /// Scan and delete `.part` files older than 24 hours.
  static Future<int> cleanupStalePartials(String mlModelsDir) async {
    final dir = Directory(mlModelsDir);
    if (!await dir.exists()) return 0;

    int cleaned = 0;
    final cutoff = DateTime.now().subtract(const Duration(hours: 24));

    await for (final entity in dir.list()) {
      if (entity is File && entity.path.endsWith('.part')) {
        try {
          final stat = await entity.stat();
          if (stat.modified.isBefore(cutoff)) {
            await entity.delete();
            cleaned++;
          }
        } catch (e) {
          debugPrint('MLStorageService.cleanupStalePartials: $e');
        }
      }
    }

    return cleaned;
  }
}
