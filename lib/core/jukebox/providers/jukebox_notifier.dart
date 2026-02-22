import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter/material.dart' show Color;
import '../models/channel_info.dart';
import '../models/game_score.dart';
import '../models/jukebox_song.dart';
import '../models/jukebox_soundfont.dart';
import '../models/karaoke_style_config.dart';
import '../models/note_block.dart';
import '../models/visualizer_config.dart';
import '../jukebox_registry.dart';
import '../midi_sequencer.dart';
import '../synth/midi_synthesizer.dart';
import '../services/custom_song_service.dart';
import '../services/soundfont_manager.dart';
import '../../services/download_manager.dart';
import '../../services/preferences_service.dart';

enum RepeatMode { off, all, one }
enum GameLobbyScreen { hidden, songBrowser, songDetail }

class JukeboxNotifier extends ChangeNotifier {
  final PreferencesService _prefs;

  late MidiSynthesizer _synth;
  late MidiSequencer _sequencer;
  bool _synthReady = false;
  Timer? _positionTimer;

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

  // Game lobby state
  GameLobbyScreen _lobbyScreen = GameLobbyScreen.hidden;
  GameLobbyScreen get lobbyScreen => _lobbyScreen;

  JukeboxSong? _lobbySong;
  JukeboxSong? get lobbySong => _lobbySong;

  List<ChannelInfo>? _channelAnalysis;
  List<ChannelInfo>? get channelAnalysis => _channelAnalysis;

  int _countdown = 0;
  int get countdown => _countdown;
  Timer? _countdownTimer;

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
    _loadHighScores();
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
    _resetGameState();

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
    _sequencer.play();
    _isPlaying = true;
    _startPositionUpdates();
    notifyListeners();
  }

  void stop() {
    _resetGameState();
    _sequencer.stop();
    _isPlaying = false;
    _position = Duration.zero;
    _currentSong = null;
    _currentLyric = null;
    _noteActivity = 0.0;
    _stopPositionUpdates();
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

        // H2: Re-apply mute on target channel during game mode.
        // MIDI CC7 events in the file can un-mute the channel;
        // forcibly zero it every tick to keep it silent.
        if (_gameMode && !_watchMode) {
          _synth.controlChange(_targetChannel, 7, 0);
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

  // ─────────────────────────────────────────
  // Interactive Keyboard
  // ─────────────────────────────────────────

  static const int keyboardChannel = 15;

  int _keyboardProgram = 0;
  int get keyboardProgram => _keyboardProgram;

  bool _keyboardMode = false;
  bool get keyboardMode => _keyboardMode;

  void toggleKeyboardMode() {
    _keyboardMode = !_keyboardMode;
    if (_keyboardMode) {
      _synth.programChange(keyboardChannel, _keyboardProgram);
    } else {
      _resetGameState();
      _synth.allNotesOff();
    }
    notifyListeners();
  }

  void playNote(int note, int velocity) {
    if (!_synthReady) return;
    _synth.noteOn(keyboardChannel, note, velocity);
    _onNoteOnEvent(keyboardChannel, note, velocity);
  }

  void stopNote(int note) {
    if (!_synthReady) return;
    _synth.noteOff(keyboardChannel, note);
  }

  void setKeyboardInstrument(int program) {
    _keyboardProgram = program.clamp(0, 127);
    _synth.programChange(keyboardChannel, _keyboardProgram);
    notifyListeners();
  }

  /// Set the keyboard instrument dropdown to match a game channel's program.
  void _syncKeyboardToChannel(int channel) {
    if (_channelAnalysis == null) return;
    for (final info in _channelAnalysis!) {
      if (info.channel == channel) {
        _keyboardProgram = info.programNumber.clamp(0, 127);
        _synth.programChange(keyboardChannel, _keyboardProgram);
        break;
      }
    }
  }

  // ─────────────────────────────────────────
  // Falling Notes Game
  // ─────────────────────────────────────────

  bool _gameMode = false;
  bool get gameMode => _gameMode;

  bool _watchMode = true;
  bool get watchMode => _watchMode;

  GameScore? _currentScore;
  GameScore? get currentScore => _currentScore;

  List<NoteBlock>? _noteBlocks;
  List<NoteBlock>? get noteBlocks => _noteBlocks;

  int _targetChannel = 0;
  int get targetChannel => _targetChannel;

  List<HighScoreEntry> _highScores = [];
  List<HighScoreEntry> get highScores => _highScores;

  double get tempo => _sequencer.tempoMultiplier;

  void setTempo(double multiplier) {
    _sequencer.tempoMultiplier = multiplier;
    notifyListeners();
  }

  void startGame({int? channel, bool watchOnly = false}) {
    if (_currentSong == null) return;
    _targetChannel = channel ?? _detectMelodyChannel();
    _noteBlocks = _sequencer.buildNoteBlocks(filterChannel: _targetChannel);
    _watchMode = watchOnly;
    if (!watchOnly) {
      _currentScore = GameScore();
      // Mute the target channel so player provides it
      _synth.controlChange(_targetChannel, 7, 0);
    } else {
      _currentScore = null;
    }
    _gameMode = true;
    notifyListeners();
  }

  void endGame() {
    if (!_gameMode) return;
    _gameMode = false;
    // Restore target channel volume
    _synth.controlChange(_targetChannel, 7, (_volume * 127).round());
    if (_currentScore != null && _currentSong != null) {
      _saveHighScore();
    }
    _noteBlocks = null;
    _watchMode = true;
    _sequencer.tempoMultiplier = 1.0;
    notifyListeners();
  }

  void _resetGameState() {
    if (_gameMode) {
      _gameMode = false;
      // Restore target channel volume
      _synth.controlChange(_targetChannel, 7, (_volume * 127).round());
    }
    _noteBlocks = null;
    _currentScore = null;
    _watchMode = true;
    _sequencer.tempoMultiplier = 1.0;
    _countdownTimer?.cancel();
    _countdown = 0;
  }

  void onPlayerHit(int note, int deltaMs) {
    if (!_gameMode || _currentScore == null || _watchMode) return;
    final grade = GameScore.judge(deltaMs);
    _currentScore!.recordHit(grade);
    if (grade != HitGrade.miss) {
      _synth.noteOn(_targetChannel, note, 100);
    }
    notifyListeners();
  }

  void onPlayerMiss() {
    if (!_gameMode || _currentScore == null || _watchMode) return;
    _currentScore!.recordHit(HitGrade.miss);
    notifyListeners();
  }

  int _detectMelodyChannel() {
    final counts = <int, int>{};
    for (final e in _sequencer.events) {
      if (e.type == 0x90 && e.data2 > 0 && e.channel != 9) {
        counts[e.channel] = (counts[e.channel] ?? 0) + 1;
      }
    }
    if (counts.isEmpty) return 0;
    return counts.entries.reduce((a, b) => a.value > b.value ? a : b).key;
  }

  void _saveHighScore() {
    if (_currentScore == null || _currentSong == null) return;
    final entry = HighScoreEntry(
      songId: _currentSong!.id,
      channel: _targetChannel,
      score: _currentScore!.score,
      maxCombo: _currentScore!.maxCombo,
      rank: _currentScore!.rank,
      accuracy: _currentScore!.accuracy,
      date: DateTime.now(),
    );
    _highScores.add(entry);
    // Keep top 3 per song
    _highScores.sort((a, b) => b.score.compareTo(a.score));
    final songScores = _highScores.where((e) => e.songId == _currentSong!.id).toList();
    if (songScores.length > 3) {
      final toRemove = songScores.sublist(3);
      _highScores.removeWhere((e) => toRemove.contains(e));
    }
    _prefs.setJukeboxHighScores(HighScoreEntry.encodeList(_highScores));
  }

  void _loadHighScores() {
    _highScores = HighScoreEntry.decodeList(_prefs.jukeboxHighScores);
  }

  List<HighScoreEntry> highScoresForSong(String songId) {
    return _highScores.where((e) => e.songId == songId).toList()
      ..sort((a, b) => b.score.compareTo(a.score));
  }

  // ─────────────────────────────────────────
  // Game Lobby
  // ─────────────────────────────────────────

  void openGameBrowser() {
    _lobbyScreen = GameLobbyScreen.songBrowser;
    notifyListeners();
  }

  void closeGameBrowser() {
    _lobbyScreen = GameLobbyScreen.hidden;
    _lobbySong = null;
    _channelAnalysis = null;
    notifyListeners();
  }

  Future<void> selectGameSong(JukeboxSong song) async {
    _lobbySong = song;
    _lobbyScreen = GameLobbyScreen.songDetail;
    _channelAnalysis = null;
    notifyListeners();

    // Load the MIDI and analyze channels
    try {
      final Uint8List bytes;
      if (song.filePath != null) {
        bytes = await File(song.filePath!).readAsBytes();
      } else {
        final data = await rootBundle.load(song.assetPath!);
        bytes = data.buffer.asUint8List();
      }
      await _sequencer.load(bytes);
      _channelAnalysis = _sequencer.analyzeChannels();
      _currentSong = song;
      _duration = _sequencer.duration;
    } catch (e) {
      debugPrint('Jukebox: Failed to load game song ${song.id}: $e');
      _channelAnalysis = [];
    }
    notifyListeners();
  }

  void backToSongBrowser() {
    _lobbyScreen = GameLobbyScreen.songBrowser;
    notifyListeners();
  }

  void startGameFromLobby({required int channel, bool watchOnly = false}) {
    if (_lobbySong == null) return;
    _lobbyScreen = GameLobbyScreen.hidden;
    _targetChannel = channel;
    _noteBlocks = _sequencer.buildNoteBlocks(filterChannel: _targetChannel);
    _watchMode = watchOnly;
    if (!watchOnly) {
      _currentScore = GameScore();
      _synth.controlChange(_targetChannel, 7, 0);
    } else {
      _currentScore = null;
    }
    _gameMode = true;

    // Sync keyboard instrument dropdown with the game channel's instrument
    _syncKeyboardToChannel(channel);

    // Start playback from the beginning
    _sequencer.stop();
    _isPlaying = true;
    _sequencer.play();
    _startPositionUpdates();
    notifyListeners();
  }

  void startGameWithCountdown({required int channel, bool watchOnly = false}) {
    if (_lobbySong == null) return;
    _countdown = 3;
    _lobbyScreen = GameLobbyScreen.hidden;

    // Prepare game state but don't start playback yet
    _targetChannel = channel;
    _noteBlocks = _sequencer.buildNoteBlocks(filterChannel: _targetChannel);
    _watchMode = watchOnly;
    if (!watchOnly) {
      _currentScore = GameScore();
      _synth.controlChange(_targetChannel, 7, 0);
    } else {
      _currentScore = null;
    }
    _gameMode = true;

    // Sync keyboard instrument dropdown with the game channel's instrument
    _syncKeyboardToChannel(channel);
    notifyListeners();

    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _countdown--;
      if (_countdown <= 0) {
        timer.cancel();
        _countdownTimer = null;
        // Start playback
        _sequencer.stop();
        _isPlaying = true;
        _sequencer.play();
        _startPositionUpdates();
      }
      notifyListeners();
    });
  }

  (int, int)? noteRangeForChannel(int channel) {
    if (_channelAnalysis == null) return null;
    for (final info in _channelAnalysis!) {
      if (info.channel == channel) {
        return (info.minNote, info.maxNote);
      }
    }
    return null;
  }

  void returnToSongDetail() {
    _lobbyScreen = GameLobbyScreen.songDetail;
    notifyListeners();
  }

  @override
  void dispose() {
    _positionTimer?.cancel();
    _countdownTimer?.cancel();
    _sfManager.disposeDownloads();
    _sequencer.dispose();
    _synth.dispose();
    super.dispose();
  }
}
