import 'dart:convert';
import 'dart:typed_data';

/// Image and generation record travel together, including across queued writes.
class CascadePreview {
  final Uint8List bytes;
  final Map<String, dynamic>? metadata;

  CascadePreview(Uint8List bytes, {Map<String, dynamic>? metadata})
    : bytes = Uint8List.fromList(bytes),
      metadata = metadata == null
          ? null
          : jsonDecode(jsonEncode(metadata)) as Map<String, dynamic>;
}

/// Keys are library cascade names and stable beat IDs, never beat positions.
/// Callers serialize operations, including preference changes and cleanup.
abstract class CascadePreviewStore {
  Future<void> saveBeat(
    String cascadeName,
    String beatId,
    CascadePreview preview,
  );
  Future<void> deleteBeat(String cascadeName, String beatId);
  Future<Map<String, CascadePreview>> load(String cascadeName);
  Future<void> retainBeats(String cascadeName, Set<String> beatIds);
  Future<void> deleteCascade(String cascadeName);
}

class MemoryCascadePreviewStore implements CascadePreviewStore {
  final Map<String, Map<String, CascadePreview>> _data = {};

  @override
  Future<void> saveBeat(String name, String id, CascadePreview preview) async {
    _data.putIfAbsent(name, () => {})[id] = preview;
  }

  @override
  Future<void> deleteBeat(String name, String id) async {
    _data[name]?.remove(id);
  }

  @override
  Future<Map<String, CascadePreview>> load(String name) async =>
      Map.of(_data[name] ?? <String, CascadePreview>{});

  @override
  Future<void> retainBeats(String name, Set<String> ids) async {
    _data[name]?.removeWhere((id, _) => !ids.contains(id));
  }

  @override
  Future<void> deleteCascade(String name) async {
    _data.remove(name);
  }
}
