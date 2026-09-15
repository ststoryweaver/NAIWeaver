import 'dart:typed_data';

/// Persists cascade beat preview bytes so they can be restored after a restart.
///
/// Keys are cascade names (library identity). Implementations must be safe to
/// call when persistence is toggled off — the notifier skips I/O in that case.
abstract class CascadePreviewStore {
  Future<void> saveBeat(String cascadeName, int index, Uint8List bytes);
  Future<void> deleteBeat(String cascadeName, int index);
  Future<Map<int, Uint8List>> load(String cascadeName);
  Future<void> replaceAll(String cascadeName, Map<int, Uint8List> images);
  Future<void> deleteCascade(String cascadeName);
}

/// In-memory store for tests.
class MemoryCascadePreviewStore implements CascadePreviewStore {
  final Map<String, Map<int, Uint8List>> _data = {};

  @override
  Future<void> saveBeat(String cascadeName, int index, Uint8List bytes) async {
    _data.putIfAbsent(cascadeName, () => {})[index] = bytes;
  }

  @override
  Future<void> deleteBeat(String cascadeName, int index) async {
    _data[cascadeName]?.remove(index);
  }

  @override
  Future<Map<int, Uint8List>> load(String cascadeName) async {
    final images = _data[cascadeName];
    if (images == null) return {};
    return Map<int, Uint8List>.from(images);
  }

  @override
  Future<void> replaceAll(
    String cascadeName,
    Map<int, Uint8List> images,
  ) async {
    _data[cascadeName] = Map<int, Uint8List>.from(images);
  }

  @override
  Future<void> deleteCascade(String cascadeName) async {
    _data.remove(cascadeName);
  }
}
