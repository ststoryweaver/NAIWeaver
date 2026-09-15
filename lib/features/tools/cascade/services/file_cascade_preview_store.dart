import 'dart:io';
import 'dart:typed_data';

import 'package:path/path.dart' as p;

import 'cascade_preview_store.dart';

/// Writes one file per beat under `[rootDir]/[urlencoded name]/beat_N.bin`.
class FileCascadePreviewStore implements CascadePreviewStore {
  FileCascadePreviewStore(this.rootDir);

  final String rootDir;

  static final _beatFile = RegExp(r'^beat_(\d+)\.bin$');

  String _key(String cascadeName) => Uri.encodeComponent(cascadeName);

  Directory _cascadeDir(String cascadeName) =>
      Directory(p.join(rootDir, _key(cascadeName)));

  File _beatPath(String cascadeName, int index) =>
      File(p.join(_cascadeDir(cascadeName).path, 'beat_$index.bin'));

  @override
  Future<void> saveBeat(String cascadeName, int index, Uint8List bytes) async {
    final dir = _cascadeDir(cascadeName);
    await dir.create(recursive: true);
    await _beatPath(cascadeName, index).writeAsBytes(bytes, flush: true);
  }

  @override
  Future<void> deleteBeat(String cascadeName, int index) async {
    final file = _beatPath(cascadeName, index);
    if (await file.exists()) {
      await file.delete();
    }
  }

  @override
  Future<Map<int, Uint8List>> load(String cascadeName) async {
    final dir = _cascadeDir(cascadeName);
    if (!await dir.exists()) return {};
    final out = <int, Uint8List>{};
    await for (final entity in dir.list()) {
      if (entity is! File) continue;
      final match = _beatFile.firstMatch(p.basename(entity.path));
      if (match == null) continue;
      final index = int.parse(match.group(1)!);
      out[index] = Uint8List.fromList(await entity.readAsBytes());
    }
    return out;
  }

  @override
  Future<void> replaceAll(
    String cascadeName,
    Map<int, Uint8List> images,
  ) async {
    final dir = _cascadeDir(cascadeName);
    if (await dir.exists()) {
      await for (final entity in dir.list()) {
        if (entity is File && _beatFile.hasMatch(p.basename(entity.path))) {
          await entity.delete();
        }
      }
    }
    if (images.isEmpty) return;
    await dir.create(recursive: true);
    for (final entry in images.entries) {
      await File(
        p.join(dir.path, 'beat_${entry.key}.bin'),
      ).writeAsBytes(entry.value, flush: true);
    }
  }

  @override
  Future<void> deleteCascade(String cascadeName) async {
    final dir = _cascadeDir(cascadeName);
    if (await dir.exists()) {
      await dir.delete(recursive: true);
    }
  }
}
