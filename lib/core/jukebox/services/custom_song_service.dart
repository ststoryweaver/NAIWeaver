import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import '../models/jukebox_song.dart';

/// Manages custom song import, deletion, and persistence.
class CustomSongService {
  final String customSongsDir;
  final String _customSongsJsonPath;
  List<JukeboxSong> _songs = [];

  CustomSongService({required this.customSongsDir, required String customSongsJsonPath})
      : _customSongsJsonPath = customSongsJsonPath;

  List<JukeboxSong> get songs => _songs;

  Future<void> load() async {
    final file = File(_customSongsJsonPath);
    if (!await file.exists()) return;
    try {
      final raw = await file.readAsString();
      final list = jsonDecode(raw) as List;
      _songs = list.map((e) => JukeboxSong.fromJson(e as Map<String, dynamic>)).toList();
    } catch (e) {
      debugPrint('Jukebox: Failed to load custom songs: $e');
    }
  }

  Future<JukeboxSong> importSong(String pickedFilePath) async {
    final file = File(pickedFilePath);
    final ext = p.extension(pickedFilePath).toLowerCase();
    final baseName = p.basenameWithoutExtension(pickedFilePath);
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final destName = '${timestamp}_$baseName$ext';
    final destPath = p.join(customSongsDir, destName);

    await file.copy(destPath);

    final song = JukeboxSong(
      id: 'custom_$timestamp',
      title: baseName,
      category: SongCategory.custom,
      filePath: destPath,
      isKaraoke: ext == '.kar',
    );

    _songs.add(song);
    await _save();
    return song;
  }

  Future<void> deleteSong(String songId) async {
    final idx = _songs.indexWhere((s) => s.id == songId);
    if (idx == -1) return;

    final song = _songs[idx];
    if (song.filePath != null) {
      final f = File(song.filePath!);
      if (await f.exists()) await f.delete();
    }

    _songs.removeAt(idx);
    await _save();
  }

  Future<void> _save() async {
    final jsonList = _songs.map((s) => s.toJson()).toList();
    await File(_customSongsJsonPath).writeAsString(jsonEncode(jsonList));
  }
}
