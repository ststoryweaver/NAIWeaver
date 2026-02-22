import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Resolves all application paths from a single base directory.
///
/// In debug mode (flutter run), uses the project root (detected by pubspec.yaml).
/// In release mode, uses the platform's application support directory.
class PathService {
  final String baseDir;
  String? outputDirOverride;

  PathService(this.baseDir);

  String get outputDir => outputDirOverride ?? p.join(baseDir, 'output');
  String get wildcardDir => p.join(baseDir, 'wildcards');
  String get tagFilePath => p.join(baseDir, 'Tags', 'high-frequency-tags-list.json');
  String get presetsFilePath => p.join(baseDir, 'presets.json');
  String get stylesFilePath => p.join(baseDir, 'prompt_styles.json');
  String get examplesDir => p.join(baseDir, 'Tags', 'Examples');
  String get referenceLibraryFilePath => p.join(baseDir, 'reference_library.json');
  String get canvasSessionDir => p.join(baseDir, 'canvas_sessions');
  String get mlModelsDir => p.join(baseDir, 'ml_models');
  String get soundfontsDir => p.join(baseDir, 'soundfonts');
  String get customSongsDir => p.join(baseDir, 'custom_songs');
  String get customSongsJsonPath => p.join(baseDir, 'custom_songs.json');

  static Future<PathService> initialize() async {
    if (kIsWeb) return PathService('');
    // In debug mode, the working directory is the project root
    if (kDebugMode) {
      final currentDir = Directory.current.path;
      if (await File(p.join(currentDir, 'pubspec.yaml')).exists()) {
        return PathService(currentDir);
      }
    }

    // Release mode: use platform-appropriate app support directory
    final appSupport = await getApplicationSupportDirectory();
    return PathService(appSupport.path);
  }

  /// Ensures all required directories exist.
  Future<void> ensureDirectories() async {
    if (kIsWeb) return;
    await Directory(outputDir).create(recursive: true);
    await Directory(wildcardDir).create(recursive: true);
    await Directory(p.dirname(tagFilePath)).create(recursive: true);
    await Directory(canvasSessionDir).create(recursive: true);
    await Directory(mlModelsDir).create(recursive: true);
    await Directory(soundfontsDir).create(recursive: true);
    await Directory(customSongsDir).create(recursive: true);
  }

  /// Copies bundled assets to app support directory if they don't already exist.
  Future<void> seedAssets() async {
    if (kIsWeb) return;
    await _copyAssetIfMissing('prompt_styles.json', stylesFilePath);
    await _copyAssetIfMissing('Tags/high-frequency-tags-list.json', tagFilePath);
  }

  Future<void> _copyAssetIfMissing(String assetPath, String targetPath) async {
    final file = File(targetPath);
    if (!await file.exists()) {
      try {
        final data = await rootBundle.loadString(assetPath);
        await file.writeAsString(data);
      } catch (e) {
        debugPrint('Could not seed asset $assetPath: $e');
      }
    }
  }
}
