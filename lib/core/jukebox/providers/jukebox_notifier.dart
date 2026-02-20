import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter/material.dart' show Color;
import 'package:path/path.dart' as p;
import '../models/jukebox_song.dart';
import '../models/jukebox_soundfont.dart';
import '../jukebox_registry.dart';
import '../midi_sequencer.dart';
import '../synth/midi_synthesizer.dart';
import '../services/soundfont_storage_service.dart';
import '../services/soundfont_download_service.dart';
import '../../services/preferences_service.dart';

enum RepeatMode { off, all, one }

enum SoundFontDownloadStatus { idle, downloading, completed, error }

class SoundFontDownloadState {
  final SoundFontDownloadStatus status;
  final double progress;
  final String? errorMessage;

  const SoundFontDownloadState({
    this.status = SoundFontDownloadStatus.idle,
    this.progress = 0.0,
    this.errorMessage,
  });
}

class JukeboxNotifier extends ChangeNotifier {
  final String soundfontsDir;
  final PreferencesService _prefs;

  late MidiSynthesizer _synth;
  late MidiSequencer _sequencer;
  bool _synthReady = false;
  Timer? _positionTimer;
  Timer? _idleTimer;

  // Playback state
  JukeboxSong? _currentSong;
  JukeboxSong? get currentSong => _currentSong;

  bool _isPlaying = false;
  bool get isPlaying => _isPlaying;

  Duration _position = Duration.zero;
  Duration get position => _position;

  Duration _duration = Duration.zero;
  Duration get duration => _duration;

  double _volume = 0.7;
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

  // SoundFont
  JukeboxSoundFont _activeSoundFont = JukeboxRegistry.defaultSoundFont;
  JukeboxSoundFont get activeSoundFont => _activeSoundFont;

  // SoundFont download state
  final Map<String, SoundFontDownloadState> _sfDownloadStates = {};
  final Map<String, CancelToken> _sfCancelTokens = {};
  final Set<String> _downloadedSoundFonts = {};

  // Karaoke
  String? _currentLyric;
  String? get currentLyric => _currentLyric;
  List<LyricLine> get lyrics => _sequencer.lyrics;

  // Karaoke style (nullable = use theme default)
  Color? _karaokeHighlightColor;
  Color? get karaokeHighlightColor => _karaokeHighlightColor;
  Color? _karaokeUpcomingColor;
  Color? get karaokeUpcomingColor => _karaokeUpcomingColor;
  Color? _karaokeNextLineColor;
  Color? get karaokeNextLineColor => _karaokeNextLineColor;
  String? _karaokeFontFamily;
  String? get karaokeFontFamily => _karaokeFontFamily;
  double _karaokeFontScale = 1.0;
  double get karaokeFontScale => _karaokeFontScale;
  bool _showMiniLyric = true;
  bool get showMiniLyric => _showMiniLyric;
  bool _showKaraokeInPanel = true;
  bool get showKaraokeInPanel => _showKaraokeInPanel;

  // Note activity for visualizer (0.0–1.0, decays over time)
  double _noteActivity = 0.0;
  double get noteActivity => _noteActivity;

  bool get synthAvailable => _synthReady;

  JukeboxNotifier({
    required this.soundfontsDir,
    required PreferencesService prefs,
  }) : _prefs = prefs {
    _synth = MidiSynthesizer.create();
    _sequencer = MidiSequencer(_synth);

    // Restore preferences
    _volume = _prefs.jukeboxVolume;
    _shuffle = _prefs.jukeboxShuffle;
    final repeatStr = _prefs.jukeboxRepeat;
    _repeatMode = RepeatMode.values.firstWhere(
      (m) => m.name == repeatStr,
      orElse: () => RepeatMode.off,
    );
    final sfId = _prefs.jukeboxSoundFontId;
    if (sfId != null) {
      _activeSoundFont = JukeboxRegistry.findSoundFontById(sfId) ?? JukeboxRegistry.defaultSoundFont;
    }

    _sequencer.onLyric = _onLyricEvent;
    _sequencer.onNoteOn = _onNoteOnEvent;

    // Restore karaoke preferences
    final hlColor = _prefs.jukeboxKaraokeHighlightColor;
    if (hlColor != null) _karaokeHighlightColor = Color(hlColor);
    final upColor = _prefs.jukeboxKaraokeUpcomingColor;
    if (upColor != null) _karaokeUpcomingColor = Color(upColor);
    final nlColor = _prefs.jukeboxKaraokeNextLineColor;
    if (nlColor != null) _karaokeNextLineColor = Color(nlColor);
    _karaokeFontFamily = _prefs.jukeboxKaraokeFontFamily;
    _karaokeFontScale = _prefs.jukeboxKaraokeFontScale;
    _showMiniLyric = _prefs.jukeboxShowMiniLyric;
    _showKaraokeInPanel = _prefs.jukeboxShowKaraokeInPanel;
  }

  Future<void> initialize() async {
    await _scanDownloadedSoundFonts();
    await _synth.initialize();
    _synthReady = _synth.isAvailable;
    if (_synthReady) {
      // If the persisted soundfont is no longer available, fall back to default
      if (!isSoundFontAvailable(_activeSoundFont)) {
        _activeSoundFont = JukeboxRegistry.defaultSoundFont;
        _prefs.setJukeboxSoundFontId(_activeSoundFont.id);
      }
      await _ensureSoundFontLoaded();
    }
    notifyListeners();
  }

  Future<void> _ensureSoundFontLoaded() async {
    final sf = _activeSoundFont;
    final diskFilename = sf.filename ?? p.basename(sf.assetPath ?? '');
    if (diskFilename.isEmpty) return;

    final sfPath = p.join(soundfontsDir, diskFilename);
    final sfFile = File(sfPath);

    if (!await sfFile.exists()) {
      // Only bundled soundfonts can be extracted from assets
      if (sf.isBundled) {
        try {
          final data = await rootBundle.load(sf.assetPath!);
          await sfFile.writeAsBytes(data.buffer.asUint8List());
          debugPrint('Jukebox: Extracted soundfont to $sfPath');
        } catch (e) {
          debugPrint('Jukebox: Failed to extract soundfont: $e');
          return;
        }
      } else {
        debugPrint('Jukebox: Downloaded soundfont not on disk: $sfPath');
        return;
      }
    }

    await _synth.loadSoundFont(sfPath);
  }

  // ─────────────────────────────────────────
  // SoundFont Download Management
  // ─────────────────────────────────────────

  SoundFontDownloadState sfDownloadState(String id) {
    return _sfDownloadStates[id] ?? const SoundFontDownloadState();
  }

  bool isSoundFontAvailable(JukeboxSoundFont sf) {
    return sf.isBundled || _downloadedSoundFonts.contains(sf.id);
  }

  Set<String> get downloadedSoundFontIds => Set.unmodifiable(_downloadedSoundFonts);

  Future<void> _scanDownloadedSoundFonts() async {
    for (final sf in JukeboxRegistry.allSoundFonts) {
      if (sf.filename != null &&
          await SoundFontStorageService.isDownloaded(soundfontsDir, sf)) {
        _downloadedSoundFonts.add(sf.id);
      }
    }
  }

  Future<void> downloadSoundFont(JukeboxSoundFont sf) async {
    if (!sf.isDownloadable) return;
    if (_sfCancelTokens.containsKey(sf.id)) return; // already downloading

    final cancelToken = CancelToken();
    _sfCancelTokens[sf.id] = cancelToken;
    _sfDownloadStates[sf.id] = const SoundFontDownloadState(
      status: SoundFontDownloadStatus.downloading,
    );
    notifyListeners();

    final result = await SoundFontDownloadService.download(
      soundfontsDir: soundfontsDir,
      sf: sf,
      cancelToken: cancelToken,
      onProgress: (received, total) {
        _sfDownloadStates[sf.id] = SoundFontDownloadState(
          status: SoundFontDownloadStatus.downloading,
          progress: total > 0 ? received / total : 0.0,
        );
        notifyListeners();
      },
    );

    _sfCancelTokens.remove(sf.id);

    switch (result) {
      case SoundFontDownloadResult.success:
        _downloadedSoundFonts.add(sf.id);
        _sfDownloadStates[sf.id] = const SoundFontDownloadState(
          status: SoundFontDownloadStatus.completed,
        );
      case SoundFontDownloadResult.cancelled:
        _sfDownloadStates[sf.id] = const SoundFontDownloadState(
          status: SoundFontDownloadStatus.idle,
        );
      case SoundFontDownloadResult.hashMismatch:
        _sfDownloadStates[sf.id] = const SoundFontDownloadState(
          status: SoundFontDownloadStatus.error,
          errorMessage: 'Hash verification failed',
        );
      case SoundFontDownloadResult.error:
        _sfDownloadStates[sf.id] = const SoundFontDownloadState(
          status: SoundFontDownloadStatus.error,
          errorMessage: 'Download failed',
        );
    }

    notifyListeners();
  }

  void cancelSoundFontDownload(String id) {
    _sfCancelTokens[id]?.cancel();
    _sfCancelTokens.remove(id);
  }

  Future<void> deleteSoundFont(JukeboxSoundFont sf) async {
    await SoundFontStorageService.delete(soundfontsDir, sf);
    await SoundFontStorageService.deletePartial(soundfontsDir, sf);
    _downloadedSoundFonts.remove(sf.id);
    _sfDownloadStates.remove(sf.id);

    // Fall back to default if the active soundfont was deleted
    if (_activeSoundFont.id == sf.id) {
      _activeSoundFont = JukeboxRegistry.defaultSoundFont;
      _prefs.setJukeboxSoundFontId(_activeSoundFont.id);
      if (_synthReady) await _ensureSoundFontLoaded();
    }

    notifyListeners();
  }

  // ─────────────────────────────────────────
  // Playback
  // ─────────────────────────────────────────

  Future<void> playSong(JukeboxSong song) async {
    _cancelIdleTimer();

    try {
      final data = await rootBundle.load(song.assetPath);
      await _sequencer.load(data.buffer.asUint8List());
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
    if (!isSoundFontAvailable(sf)) return;
    _activeSoundFont = sf;
    _prefs.setJukeboxSoundFontId(sf.id);
    await _ensureSoundFontLoaded();
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
  // Karaoke Style
  // ─────────────────────────────────────────

  void setKaraokeHighlightColor(Color? color) {
    _karaokeHighlightColor = color;
    _prefs.setJukeboxKaraokeHighlightColor(color?.toARGB32());
    notifyListeners();
  }

  void setKaraokeUpcomingColor(Color? color) {
    _karaokeUpcomingColor = color;
    _prefs.setJukeboxKaraokeUpcomingColor(color?.toARGB32());
    notifyListeners();
  }

  void setKaraokeNextLineColor(Color? color) {
    _karaokeNextLineColor = color;
    _prefs.setJukeboxKaraokeNextLineColor(color?.toARGB32());
    notifyListeners();
  }

  void setKaraokeFontFamily(String? family) {
    _karaokeFontFamily = family;
    _prefs.setJukeboxKaraokeFontFamily(family);
    notifyListeners();
  }

  void setKaraokeFontScale(double scale) {
    _karaokeFontScale = scale.clamp(0.5, 2.0);
    _prefs.setJukeboxKaraokeFontScale(_karaokeFontScale);
    notifyListeners();
  }

  void toggleMiniLyric() {
    _showMiniLyric = !_showMiniLyric;
    _prefs.setJukeboxShowMiniLyric(_showMiniLyric);
    notifyListeners();
  }

  void toggleKaraokeInPanel() {
    _showKaraokeInPanel = !_showKaraokeInPanel;
    _prefs.setJukeboxShowKaraokeInPanel(_showKaraokeInPanel);
    notifyListeners();
  }

  void resetKaraokeStyle() {
    _karaokeHighlightColor = null;
    _karaokeUpcomingColor = null;
    _karaokeNextLineColor = null;
    _karaokeFontFamily = null;
    _karaokeFontScale = 1.0;
    _prefs.setJukeboxKaraokeHighlightColor(null);
    _prefs.setJukeboxKaraokeUpcomingColor(null);
    _prefs.setJukeboxKaraokeNextLineColor(null);
    _prefs.setJukeboxKaraokeFontFamily(null);
    _prefs.setJukeboxKaraokeFontScale(1.0);
    notifyListeners();
  }

  @override
  void dispose() {
    _positionTimer?.cancel();
    _idleTimer?.cancel();
    for (final token in _sfCancelTokens.values) {
      token.cancel();
    }
    _sfCancelTokens.clear();
    _sequencer.dispose();
    _synth.dispose();
    super.dispose();
  }
}
