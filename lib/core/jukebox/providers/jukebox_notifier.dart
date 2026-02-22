import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter/material.dart' show Color;
import '../models/jukebox_song.dart';
import '../models/jukebox_soundfont.dart';
import '../models/karaoke_style_config.dart';
import '../models/visualizer_config.dart';
import '../jukebox_registry.dart';
import '../midi_sequencer.dart';
import '../synth/midi_synthesizer.dart';
import '../services/custom_song_service.dart';
import '../services/soundfont_manager.dart';
import '../../services/download_manager.dart';
import '../../services/preferences_service.dart';

enum RepeatMode { off, all, one }

class JukeboxNotifier extends ChangeNotifier {
  final PreferencesService _prefs;

  late MidiSynthesizer _synth;
  late MidiSequencer _sequencer;
  bool _synthReady = false;
  Timer? _positionTimer;
  Timer? _idleTimer;

  // Delegates
  late final KaraokeStyleConfig karaokeStyle;
  late final VisualizerConfig visualizer;
  late final CustomSongService _customSongService;
  late final SoundFontManager _sfManager;

  // Playback state
  JukeboxSong? _currentSong;
  JukeboxSong? get currentSong => _currentSong;

  bool _isPlaying = false;
  bool get isPlaying => _isPlaying;

  Duration _position = Duration.zero;
  Duration get position => _position;

  Duration _duration = Duration.zero;
  Duration get duration => _duration;

  double _volume = 0.4;
  double get volume => _volume;
  bool _muted = false;
  bool get isMuted => _muted;

  // Playlist
  List<JukeboxSong> _queue = [];
  List<JukeboxSong> get queue => _queue;
  int _queueIndex = -1;

  bool _shuffle = false;
  bool get shuffle => _shuffle;

  RepeatMode _repeatMode = RepeatMode.off;
  RepeatMode get repeatMode => _repeatMode;

  // SoundFont (delegated)
  JukeboxSoundFont get activeSoundFont => _sfManager.active;

  // Karaoke
  String? _currentLyric;
  String? get currentLyric => _currentLyric;
  List<LyricLine> get lyrics => _sequencer.lyrics;

  // Karaoke style (delegated)
  Color? get karaokeHighlightColor => karaokeStyle.highlightColor;
  Color? get karaokeUpcomingColor => karaokeStyle.upcomingColor;
  Color? get karaokeNextLineColor => karaokeStyle.nextLineColor;
  String? get karaokeFontFamily => karaokeStyle.fontFamily;
  double get karaokeFontScale => karaokeStyle.fontScale;
  bool get showMiniLyric => karaokeStyle.showMiniLyric;
  bool get showKaraokeInPanel => karaokeStyle.showKaraokeInPanel;

  // Visualizer (delegated)
  Color? get visualizerColor => visualizer.color;
  VisualizerStyle get visualizerStyle => visualizer.style;
  double get vizIntensity => visualizer.intensity;
  double get vizSpeed => visualizer.speed;
  double get vizDensity => visualizer.density;

  // Note activity for visualizer (0.0–1.0, decays over time)
  double _noteActivity = 0.0;
  double get noteActivity => _noteActivity;

  // Custom imported songs (delegated)
  List<JukeboxSong> get customSongs => _customSongService.songs;
  List<JukeboxSong> get allSongs => [...JukeboxRegistry.allSongs, ..._customSongService.songs];

  bool get synthAvailable => _synthReady;

  JukeboxNotifier({
    required String soundfontsDir,
    required String customSongsDir,
    required String customSongsJsonPath,
    required PreferencesService prefs,
  })  : _prefs = prefs {
    _synth = MidiSynthesizer.create();
    _sequencer = MidiSequencer(_synth);

    // Initialize delegates
    karaokeStyle = KaraokeStyleConfig(prefs: prefs);
    visualizer = VisualizerConfig(prefs: prefs);
    _customSongService = CustomSongService(
      customSongsDir: customSongsDir,
      customSongsJsonPath: customSongsJsonPath,
    );
    _sfManager = SoundFontManager(
      soundfontsDir: soundfontsDir,
      prefs: prefs,
    );

    // Restore preferences
    _volume = _prefs.jukeboxVolume;
    _shuffle = _prefs.jukeboxShuffle;
    final repeatStr = _prefs.jukeboxRepeat;
    _repeatMode = RepeatMode.values.firstWhere(
      (m) => m.name == repeatStr,
      orElse: () => RepeatMode.off,
    );

    _sequencer.onLyric = _onLyricEvent;
    _sequencer.onNoteOn = _onNoteOnEvent;
  }

  Future<void> initialize() async {
    await _customSongService.load();
    await _sfManager.scanDownloaded();
    await _synth.initialize();
    _synthReady = _synth.isAvailable;
    if (_synthReady) {
      // Apply saved volume (or mute) before loading soundfont to prevent boot pop
      final intVol = (_muted ? 0 : _volume * 127).round();
      for (int ch = 0; ch < 16; ch++) {
        _synth.controlChange(ch, 7, intVol);
      }
      // If the persisted soundfont is no longer available, fall back to default
      _sfManager.ensureAvailable();
      await _sfManager.loadInto(_synth);
    }
    notifyListeners();
  }

  // ─────────────────────────────────────────
  // SoundFont Management (delegated)
  // ─────────────────────────────────────────

  DownloadState sfDownloadState(String id) {
    return _sfManager.downloadState(id);
  }

  bool isSoundFontAvailable(JukeboxSoundFont sf) {
    return _sfManager.isAvailable(sf);
  }

  Future<void> downloadSoundFont(JukeboxSoundFont sf) async {
    await _sfManager.download(sf, onNotify: notifyListeners);
  }

  void cancelSoundFontDownload(String id) {
    _sfManager.cancelDownload(id);
  }

  Future<void> deleteSoundFont(JukeboxSoundFont sf) async {
    final needsReload = await _sfManager.delete(sf);
    if (needsReload && _synthReady) {
      await _sfManager.loadInto(_synth);
    }
    notifyListeners();
  }

  // ─────────────────────────────────────────
  // Playback
  // ─────────────────────────────────────────

  Future<void> playSong(JukeboxSong song) async {
    _cancelIdleTimer();

    try {
      final Uint8List bytes;
      if (song.filePath != null) {
        bytes = await File(song.filePath!).readAsBytes();
      } else {
        final data = await rootBundle.load(song.assetPath!);
        bytes = data.buffer.asUint8List();
      }
      await _sequencer.load(bytes);
    } catch (e) {
      debugPrint('Jukebox: Failed to load song ${song.id}: $e');
      return;
    }

    _currentSong = song;
    _duration = _sequencer.duration;
    _isPlaying = true;
    _sequencer.play();
    _startPositionUpdates();
    notifyListeners();
  }

  Future<void> playQueue(List<JukeboxSong> songs, {bool shuffleQueue = false}) async {
    if (songs.isEmpty) return;

    _queue = List.of(songs);
    if (shuffleQueue || _shuffle) {
      _queue.shuffle(Random());
    }
    _queueIndex = 0;
    await playSong(_queue[0]);
  }

  void pause() {
    if (!_isPlaying) return;
    _sequencer.pause();
    _isPlaying = false;
    _stopPositionUpdates();
    notifyListeners();
  }

  void resume() {
    if (_isPlaying) return;
    if (_currentSong == null) return;
    _cancelIdleTimer();
    _sequencer.play();
    _isPlaying = true;
    _startPositionUpdates();
    notifyListeners();
  }

  void stop() {
    _sequencer.stop();
    _isPlaying = false;
    _position = Duration.zero;
    _currentSong = null;
    _currentLyric = null;
    _noteActivity = 0.0;
    _stopPositionUpdates();
    _startIdleTimer();
    notifyListeners();
  }

  Future<void> next() async {
    if (_queue.isEmpty) {
      stop();
      return;
    }

    if (_repeatMode == RepeatMode.one) {
      // Replay current
      if (_currentSong != null) {
        await playSong(_currentSong!);
      }
      return;
    }

    _queueIndex++;
    if (_queueIndex >= _queue.length) {
      if (_repeatMode == RepeatMode.all) {
        _queueIndex = 0;
        if (_shuffle) _queue.shuffle(Random());
      } else {
        stop();
        return;
      }
    }
    await playSong(_queue[_queueIndex]);
  }

  Future<void> previous() async {
    if (_queue.isEmpty) return;

    // If more than 3 seconds in, restart current song
    if (_position.inSeconds > 3 && _currentSong != null) {
      await playSong(_currentSong!);
      return;
    }

    _queueIndex--;
    if (_queueIndex < 0) {
      _queueIndex = _repeatMode == RepeatMode.all ? _queue.length - 1 : 0;
    }
    await playSong(_queue[_queueIndex]);
  }

  void seek(Duration target) {
    _sequencer.seek(target);
    _position = target;
    notifyListeners();
  }

  void setVolume(double value) {
    _volume = value.clamp(0.0, 1.0);
    _muted = false;
    // Volume is applied via CC7 on all channels
    final intVol = (_volume * 127).round();
    for (int ch = 0; ch < 16; ch++) {
      _synth.controlChange(ch, 7, intVol);
    }
    _prefs.setJukeboxVolume(_volume);
    notifyListeners();
  }

  void toggleMute() {
    _muted = !_muted;
    final intVol = _muted ? 0 : (_volume * 127).round();
    for (int ch = 0; ch < 16; ch++) {
      _synth.controlChange(ch, 7, intVol);
    }
    notifyListeners();
  }

  Future<void> setSoundFont(JukeboxSoundFont sf) async {
    if (!_sfManager.isAvailable(sf)) return;
    _sfManager.setActive(sf);

    final wasPlaying = _isPlaying;

    // 1. Pause sequencer to stop MIDI event dispatch during the swap.
    //    pause() cancels the 2ms timer AND calls allNotesOff().
    if (_sequencer.isPlaying) {
      _sequencer.pause();
    } else {
      _synth.allNotesOff();
    }
    _stopPositionUpdates();

    // 2. Capture position while paused (sequencer returns pauseOffset).
    final pos = _sequencer.position;

    // 3. Load the new soundfont (async — no events fire because timer is cancelled).
    await _sfManager.loadInto(_synth);

    // 4. Seek to current position — replays program changes & CCs so all
    //    channels have correct instruments for the new soundfont.
    if (_currentSong != null) {
      _sequencer.seek(pos);
    }

    // 5. Restore user volume (must come AFTER seek, which replays CC 7 from the MIDI).
    final intVol = (_muted ? 0 : _volume * 127).round();
    for (int ch = 0; ch < 16; ch++) {
      _synth.controlChange(ch, 7, intVol);
    }

    // 6. Resume if was playing.
    if (wasPlaying && _currentSong != null) {
      _sequencer.play();
      _isPlaying = true;
      _startPositionUpdates();
    } else {
      _isPlaying = false;
    }

    notifyListeners();
  }

  void setRepeatMode(RepeatMode mode) {
    _repeatMode = mode;
    _prefs.setJukeboxRepeat(mode.name);
    notifyListeners();
  }

  void cycleRepeatMode() {
    switch (_repeatMode) {
      case RepeatMode.off:
        setRepeatMode(RepeatMode.all);
      case RepeatMode.all:
        setRepeatMode(RepeatMode.one);
      case RepeatMode.one:
        setRepeatMode(RepeatMode.off);
    }
  }

  void toggleShuffle() {
    _shuffle = !_shuffle;
    _prefs.setJukeboxShuffle(_shuffle);
    if (_shuffle && _queue.isNotEmpty) {
      // Shuffle remaining items in queue
      final current = _queueIndex >= 0 && _queueIndex < _queue.length
          ? _queue[_queueIndex]
          : null;
      _queue.shuffle(Random());
      if (current != null) {
        _queue.remove(current);
        _queue.insert(0, current);
        _queueIndex = 0;
      }
    }
    notifyListeners();
  }

  void addToQueue(JukeboxSong song) {
    _queue.add(song);
    notifyListeners();
  }

  void removeFromQueue(int index) {
    if (index < 0 || index >= _queue.length) return;
    if (index == _queueIndex) {
      next();
      return;
    }
    _queue.removeAt(index);
    if (index < _queueIndex) _queueIndex--;
    notifyListeners();
  }

  void reorderQueue(int oldIndex, int newIndex) {
    if (oldIndex < newIndex) newIndex--;
    final item = _queue.removeAt(oldIndex);
    _queue.insert(newIndex, item);
    // Update current index
    if (oldIndex == _queueIndex) {
      _queueIndex = newIndex;
    } else if (oldIndex < _queueIndex && newIndex >= _queueIndex) {
      _queueIndex--;
    } else if (oldIndex > _queueIndex && newIndex <= _queueIndex) {
      _queueIndex++;
    }
    notifyListeners();
  }

  // ─────────────────────────────────────────
  // Internal
  // ─────────────────────────────────────────

  void _onLyricEvent(String syllable, Duration timestamp) {
    _currentLyric = syllable;
    notifyListeners();
  }

  void _onNoteOnEvent(int channel, int note, int velocity) {
    _noteActivity = (_noteActivity + velocity / 127.0 * 0.3).clamp(0.0, 1.0);
  }

  void _startPositionUpdates() {
    _positionTimer?.cancel();
    _positionTimer = Timer.periodic(const Duration(milliseconds: 200), (_) {
      if (_sequencer.isPlaying) {
        _position = _sequencer.position;

        // Decay note activity for visualizer
        if (_noteActivity > 0) {
          _noteActivity = (_noteActivity - 0.05).clamp(0.0, 1.0);
        }

        notifyListeners();

        // Check if song ended
        if (_sequencer.isStopped && _isPlaying) {
          _isPlaying = false;
          next();
        }
      }
    });
  }

  void _stopPositionUpdates() {
    _positionTimer?.cancel();
  }

  void _startIdleTimer() {
    _idleTimer?.cancel();
    _idleTimer = Timer(const Duration(seconds: 60), () {
      // Unload soundfont after 60s idle to free memory
      debugPrint('Jukebox: Idle timeout, resources remain loaded');
    });
  }

  void _cancelIdleTimer() {
    _idleTimer?.cancel();
  }

  // ─────────────────────────────────────────
  // Karaoke Style (delegated)
  // ─────────────────────────────────────────

  void setKaraokeHighlightColor(Color? color) {
    karaokeStyle.setHighlightColor(color);
    notifyListeners();
  }

  void setKaraokeUpcomingColor(Color? color) {
    karaokeStyle.setUpcomingColor(color);
    notifyListeners();
  }

  void setKaraokeNextLineColor(Color? color) {
    karaokeStyle.setNextLineColor(color);
    notifyListeners();
  }

  void setKaraokeFontFamily(String? family) {
    karaokeStyle.setFontFamily(family);
    notifyListeners();
  }

  void setKaraokeFontScale(double scale) {
    karaokeStyle.setFontScale(scale);
    notifyListeners();
  }

  void toggleMiniLyric() {
    karaokeStyle.toggleMiniLyric();
    notifyListeners();
  }

  void setVisualizerColor(Color? color) {
    visualizer.setColor(color);
    notifyListeners();
  }

  void toggleKaraokeInPanel() {
    karaokeStyle.toggleKaraokeInPanel();
    notifyListeners();
  }

  // ─────────────────────────────────────────
  // Visualizer Style (delegated)
  // ─────────────────────────────────────────

  void setVisualizerStyle(VisualizerStyle style) {
    visualizer.setStyle(style);
    notifyListeners();
  }

  void setVizIntensity(double value) {
    visualizer.setIntensity(value);
    notifyListeners();
  }

  void setVizSpeed(double value) {
    visualizer.setSpeed(value);
    notifyListeners();
  }

  void setVizDensity(double value) {
    visualizer.setDensity(value);
    notifyListeners();
  }

  // ─────────────────────────────────────────
  // Custom Song Import / Delete (delegated)
  // ─────────────────────────────────────────

  Future<JukeboxSong> importSong(String pickedFilePath) async {
    final song = await _customSongService.importSong(pickedFilePath);
    notifyListeners();
    return song;
  }

  Future<void> deleteCustomSong(String songId) async {
    // Stop if currently playing
    if (_currentSong?.id == songId) {
      stop();
    }

    // Remove from queue
    _queue.removeWhere((s) => s.id == songId);

    await _customSongService.deleteSong(songId);
    notifyListeners();
  }

  void resetKaraokeStyle() {
    karaokeStyle.reset();
    visualizer.setColor(null);
    notifyListeners();
  }

  @override
  void dispose() {
    _positionTimer?.cancel();
    _idleTimer?.cancel();
    _sfManager.disposeDownloads();
    _sequencer.dispose();
    _synth.dispose();
    super.dispose();
  }
}
