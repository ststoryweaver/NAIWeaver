import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;

import '../../../../core/utils/image_utils.dart';
import 'cascade_preview_store.dart';

/// Each hashed beat file is an atomic image + metadata record. Display names
/// never become path components. The v2 namespace is separate from legacy bins.
class FileCascadePreviewStore implements CascadePreviewStore {
  FileCascadePreviewStore(this.rootDir);
  final String rootDir;
  static final _recordFile = RegExp(r'^[a-f0-9]{64}\.json$');
  static final _legacyFile = RegExp(r'^beat_(\d+)\.bin$');
  static int _tempSequence = 0;

  String _hash(String value) => sha256.convert(utf8.encode(value)).toString();

  Future<Directory> _directory(String name, {bool create = false}) async {
    final root = p.normalize(p.absolute(rootDir));
    final namespace = p.join(root, '.v2');
    final target = p.join(namespace, _hash(name));
    if (!p.isWithin(root, target)) {
      throw StateError('Invalid preview directory');
    }
    // Refuse links/junctions in either storage component, including reads.
    for (final path in [namespace, target]) {
      final type = await FileSystemEntity.type(path, followLinks: false);
      if (type != FileSystemEntityType.notFound &&
          type != FileSystemEntityType.directory) {
        throw FileSystemException('Unsafe preview directory', path);
      }
    }
    final dir = Directory(target);
    if (create) await dir.create(recursive: true);
    if (await dir.exists()) {
      final resolvedRoot = await Directory(root).resolveSymbolicLinks();
      final resolvedTarget = await dir.resolveSymbolicLinks();
      if (!p.isWithin(resolvedRoot, resolvedTarget)) {
        throw FileSystemException('Preview directory escapes storage', target);
      }
    }
    return dir;
  }

  /// Only existing, exact-name legacy children are eligible for migration.
  /// Never resolve dot names or recursively remove legacy directories.
  Future<Directory?> _legacyDirectory(String name) async {
    final key = Uri.encodeComponent(name);
    if (key.isEmpty ||
        key == '.' ||
        key == '..' ||
        key == '.v2' ||
        key.endsWith('.')) {
      return null;
    }
    final root = Directory(p.normalize(p.absolute(rootDir)));
    if (!await root.exists()) return null;
    await for (final entity in root.list(followLinks: false)) {
      if (entity is Directory &&
          p.basename(entity.path) == key &&
          p.isWithin(
            await root.resolveSymbolicLinks(),
            await entity.resolveSymbolicLinks(),
          )) {
        return entity;
      }
    }
    return null;
  }

  @override
  Future<void> saveBeat(String name, String id, CascadePreview preview) async {
    final dir = await _directory(name, create: true);
    final target = File(p.join(dir.path, '${_hash(id)}.json'));
    final temporary = File('${target.path}.$pid.${_tempSequence++}.tmp');
    try {
      await temporary.writeAsString(
        jsonEncode({
          'version': 1,
          'beatId': id,
          'bytes': base64Encode(preview.bytes),
          'checksum': sha256.convert(preview.bytes).toString(),
          'metadata': preview.metadata,
        }),
        flush: true,
      );
      // Same-directory rename publishes the complete record at once. Never
      // delete the old image before the replacement is durably written.
      await temporary.rename(target.path);
    } finally {
      if (await temporary.exists()) await temporary.delete();
    }
  }

  @override
  Future<void> deleteBeat(String name, String id) async {
    final dir = await _directory(name);
    final file = File(p.join(dir.path, '${_hash(id)}.json'));
    if (await file.exists()) await file.delete();
    final match = RegExp(r'^legacy_(\d+)$').firstMatch(id);
    final legacy = match == null ? null : await _legacyDirectory(name);
    if (legacy != null) {
      final old = File(p.join(legacy.path, 'beat_${match!.group(1)}.bin'));
      if (await old.exists()) await old.delete();
    }
  }

  @override
  Future<Map<String, CascadePreview>> load(String name) async {
    final result = <String, CascadePreview>{};
    final dir = await _directory(name);
    if (await dir.exists()) {
      await for (final entity in dir.list(followLinks: false)) {
        if (entity is! File || !_recordFile.hasMatch(p.basename(entity.path))) {
          continue;
        }
        try {
          final record =
              jsonDecode(await entity.readAsString()) as Map<String, dynamic>;
          final id = record['beatId'] as String;
          final bytes = base64Decode(record['bytes'] as String);
          if (record['version'] != 1 ||
              p.basename(entity.path) != '${_hash(id)}.json' ||
              record['checksum'] != sha256.convert(bytes).toString()) {
            throw const FormatException('Invalid preview record');
          }
          result[id] = CascadePreview(
            bytes,
            metadata: record['metadata'] as Map<String, dynamic>?,
          );
        } catch (e) {
          // One truncated/corrupt record must not prevent other beats opening.
          debugPrint('Skipping unreadable cascade preview: $e');
        }
      }
    }
    final legacy = await _legacyDirectory(name);
    if (legacy != null) {
      await for (final entity in legacy.list(followLinks: false)) {
        if (entity is! File) continue;
        final match = _legacyFile.firstMatch(p.basename(entity.path));
        if (match == null) continue;
        final id = 'legacy_${match.group(1)}';
        if (result.containsKey(id)) continue;
        try {
          final bytes = await entity.readAsBytes();
          Map<String, dynamic>? metadata;
          final comment = extractMetadata(bytes)?['Comment'];
          if (comment != null) {
            try {
              metadata = jsonDecode(comment) as Map<String, dynamic>;
            } catch (_) {}
          }
          final preview = CascadePreview(bytes, metadata: metadata);
          result[id] = preview;
          await saveBeat(name, id, preview);
          await entity.delete(); // only after the new record is committed
        } catch (e) {
          debugPrint('Could not migrate cascade preview: $e');
        }
      }
    }
    return result;
  }

  @override
  Future<void> retainBeats(String name, Set<String> ids) async {
    final dir = await _directory(name);
    final keep = ids.map((id) => '${_hash(id)}.json').toSet();
    if (await dir.exists()) {
      await for (final entity in dir.list(followLinks: false)) {
        if (entity is File &&
            _recordFile.hasMatch(p.basename(entity.path)) &&
            !keep.contains(p.basename(entity.path))) {
          await entity.delete();
        }
      }
    }
    final legacy = await _legacyDirectory(name);
    if (legacy != null) {
      await for (final entity in legacy.list(followLinks: false)) {
        if (entity is! File) continue;
        final match = _legacyFile.firstMatch(p.basename(entity.path));
        if (match != null && !ids.contains('legacy_${match.group(1)}')) {
          await entity.delete();
        }
      }
    }
  }

  @override
  Future<void> deleteCascade(String name) async {
    await retainBeats(name, {});
    final dir = await _directory(name);
    // Deliberately non-recursive: unrelated files/children must survive.
    if (await dir.exists() && await dir.list().isEmpty) await dir.delete();
    final legacy = await _legacyDirectory(name);
    if (legacy != null && await legacy.list().isEmpty) await legacy.delete();
  }
}
