import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:path/path.dart' as p;
import '../models/jukebox_soundfont.dart';
import '../jukebox_registry.dart';
import '../synth/midi_synthesizer.dart';
import '../../services/download_manager.dart';
import '../../services/preferences_service.dart';
import 'soundfont_storage_service.dart';
import 'soundfont_download_service.dart';

/// Manages soundfont loading, switching, download state, and cleanup.
class SoundFontManager {
  final String soundfontsDir;
  final PreferencesService _prefs;
  final DownloadManager _downloads = DownloadManager();

  JukeboxSoundFont _active;
  JukeboxSoundFont get active => _active;

  SoundFontManager({
    required this.soundfontsDir,
    required PreferencesService prefs,
  })  : _prefs = prefs,
        _active = _resolveInitialSoundFont(prefs);

  static JukeboxSoundFont _resolveInitialSoundFont(PreferencesService prefs) {
    final sfId = prefs.jukeboxSoundFontId;
    if (sfId != null) {
      return JukeboxRegistry.findSoundFontById(sfId) ?? JukeboxRegistry.defaultSoundFont;
    }
    return JukeboxRegistry.defaultSoundFont;
  }

  DownloadState downloadState(String id) => _downloads.state(id);
  bool isAvailable(JukeboxSoundFont sf) => sf.isBundled || _downloads.isCompleted(sf.id);

  Future<void> scanDownloaded() async {
    for (final sf in JukeboxRegistry.allSoundFonts) {
      if (sf.filename != null && await SoundFontStorageService.isDownloaded(soundfontsDir, sf)) {
        _downloads.markCompleted(sf.id);
      }
    }
  }

  /// Ensure the active soundfont falls back to default if unavailable.
  void ensureAvailable() {
    if (!isAvailable(_active)) {
      _active = JukeboxRegistry.defaultSoundFont;
      _prefs.setJukeboxSoundFontId(_active.id);
    }
  }

  /// Load the active soundfont into the synthesizer.
  Future<void> loadInto(MidiSynthesizer synth) async {
    final sf = _active;
    final diskFilename = sf.filename ?? p.basename(sf.assetPath ?? '');
    if (diskFilename.isEmpty) return;

    final sfPath = p.join(soundfontsDir, diskFilename);
    final sfFile = File(sfPath);

    if (!await sfFile.exists()) {
      if (sf.isBundled) {
        try {
          final data = await rootBundle.load(sf.assetPath!);
          await sfFile.writeAsBytes(data.buffer.asUint8List());
        } catch (e) {
          debugPrint('Jukebox: Failed to extract soundfont: $e');
          return;
        }
      } else {
        debugPrint('Jukebox: Downloaded soundfont not on disk: $sfPath');
        return;
      }
    }

    await synth.loadSoundFont(sfPath);
  }

  void setActive(JukeboxSoundFont sf) {
    if (!isAvailable(sf)) return;
    _active = sf;
    _prefs.setJukeboxSoundFontId(sf.id);
  }

  Future<void> download(JukeboxSoundFont sf, {required VoidCallback onNotify}) async {
    if (!sf.isDownloadable) return;
    await _downloads.download(
      id: sf.id,
      downloadFn: (cancelToken, onProgress) async {
        final result = await SoundFontDownloadService.download(
          soundfontsDir: soundfontsDir,
          sf: sf,
          cancelToken: cancelToken,
          onProgress: onProgress,
        );
        return switch (result) {
          SoundFontDownloadResult.success => DownloadResult.success,
          SoundFontDownloadResult.cancelled => DownloadResult.cancelled,
          SoundFontDownloadResult.hashMismatch => DownloadResult.hashMismatch,
          SoundFontDownloadResult.error => DownloadResult.error,
        };
      },
      onNotify: onNotify,
    );
  }

  void cancelDownload(String id) => _downloads.cancel(id);

  Future<bool> delete(JukeboxSoundFont sf) async {
    await SoundFontStorageService.delete(soundfontsDir, sf);
    await SoundFontStorageService.deletePartial(soundfontsDir, sf);
    _downloads.remove(sf.id);

    if (_active.id == sf.id) {
      _active = JukeboxRegistry.defaultSoundFont;
      _prefs.setJukeboxSoundFontId(_active.id);
      return true; // needs reload
    }
    return false;
  }

  void disposeDownloads() => _downloads.disposeDownloads();
}
