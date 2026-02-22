import 'package:shared_preferences/shared_preferences.dart';

class JukeboxPreferences {
  final SharedPreferences _prefs;

  JukeboxPreferences(this._prefs);

  // — Key constants —
  static const String _kVolume = 'jukebox_volume';
  static const String _kSoundFontId = 'jukebox_soundfont_id';
  static const String _kShuffle = 'jukebox_shuffle';
  static const String _kRepeat = 'jukebox_repeat';
  static const String _kSongDurations = 'jukebox_song_durations';
  static const String _kKaraokeHighlightColor = 'jukebox_karaoke_highlight_color';
  static const String _kKaraokeUpcomingColor = 'jukebox_karaoke_upcoming_color';
  static const String _kKaraokeNextLineColor = 'jukebox_karaoke_next_line_color';
  static const String _kKaraokeFontFamily = 'jukebox_karaoke_font_family';
  static const String _kKaraokeFontScale = 'jukebox_karaoke_font_scale';
  static const String _kShowMiniLyric = 'jukebox_show_mini_lyric';
  static const String _kShowKaraokeInPanel = 'jukebox_show_karaoke_in_panel';
  static const String _kVisualizerColor = 'jukebox_visualizer_color';
  static const String _kVisualizerStyle = 'jukebox_visualizer_style';
  static const String _kVizIntensity = 'jukebox_viz_intensity';
  static const String _kVizSpeed = 'jukebox_viz_speed';
  static const String _kVizDensity = 'jukebox_viz_density';
  static const String _kHighScores = 'jukebox_high_scores';

  // — Volume —

  double get volume => _prefs.getDouble(_kVolume) ?? 0.4;

  Future<void> setVolume(double value) async {
    await _prefs.setDouble(_kVolume, value);
  }

  // — SoundFont —

  String? get soundFontId => _prefs.getString(_kSoundFontId);

  Future<void> setSoundFontId(String? id) async {
    if (id == null) {
      await _prefs.remove(_kSoundFontId);
    } else {
      await _prefs.setString(_kSoundFontId, id);
    }
  }

  // — Shuffle —

  bool get shuffle => _prefs.getBool(_kShuffle) ?? false;

  Future<void> setShuffle(bool value) async {
    await _prefs.setBool(_kShuffle, value);
  }

  // — Repeat —

  String get repeat => _prefs.getString(_kRepeat) ?? 'off';

  Future<void> setRepeat(String value) async {
    await _prefs.setString(_kRepeat, value);
  }

  // — Song Durations —

  String get songDurations => _prefs.getString(_kSongDurations) ?? '';

  Future<void> setSongDurations(String value) async {
    await _prefs.setString(_kSongDurations, value);
  }

  // — Karaoke Highlight Color —

  int? get karaokeHighlightColor => _prefs.getInt(_kKaraokeHighlightColor);

  Future<void> setKaraokeHighlightColor(int? value) async {
    if (value == null) {
      await _prefs.remove(_kKaraokeHighlightColor);
    } else {
      await _prefs.setInt(_kKaraokeHighlightColor, value);
    }
  }

  // — Karaoke Upcoming Color —

  int? get karaokeUpcomingColor => _prefs.getInt(_kKaraokeUpcomingColor);

  Future<void> setKaraokeUpcomingColor(int? value) async {
    if (value == null) {
      await _prefs.remove(_kKaraokeUpcomingColor);
    } else {
      await _prefs.setInt(_kKaraokeUpcomingColor, value);
    }
  }

  // — Karaoke Next Line Color —

  int? get karaokeNextLineColor => _prefs.getInt(_kKaraokeNextLineColor);

  Future<void> setKaraokeNextLineColor(int? value) async {
    if (value == null) {
      await _prefs.remove(_kKaraokeNextLineColor);
    } else {
      await _prefs.setInt(_kKaraokeNextLineColor, value);
    }
  }

  // — Karaoke Font Family —

  String? get karaokeFontFamily => _prefs.getString(_kKaraokeFontFamily);

  Future<void> setKaraokeFontFamily(String? value) async {
    if (value == null) {
      await _prefs.remove(_kKaraokeFontFamily);
    } else {
      await _prefs.setString(_kKaraokeFontFamily, value);
    }
  }

  // — Karaoke Font Scale —

  double get karaokeFontScale => _prefs.getDouble(_kKaraokeFontScale) ?? 1.0;

  Future<void> setKaraokeFontScale(double value) async {
    await _prefs.setDouble(_kKaraokeFontScale, value);
  }

  // — Show Mini Lyric —

  bool get showMiniLyric => _prefs.getBool(_kShowMiniLyric) ?? true;

  Future<void> setShowMiniLyric(bool value) async {
    await _prefs.setBool(_kShowMiniLyric, value);
  }

  // — Show Karaoke In Panel —

  bool get showKaraokeInPanel => _prefs.getBool(_kShowKaraokeInPanel) ?? true;

  Future<void> setShowKaraokeInPanel(bool value) async {
    await _prefs.setBool(_kShowKaraokeInPanel, value);
  }

  // — Visualizer Color —

  int? get visualizerColor => _prefs.getInt(_kVisualizerColor);

  Future<void> setVisualizerColor(int? value) async {
    if (value == null) {
      await _prefs.remove(_kVisualizerColor);
    } else {
      await _prefs.setInt(_kVisualizerColor, value);
    }
  }

  // — Visualizer Style —

  String get visualizerStyle => _prefs.getString(_kVisualizerStyle) ?? 'particles';

  Future<void> setVisualizerStyle(String value) async {
    await _prefs.setString(_kVisualizerStyle, value);
  }

  // — Viz Intensity —

  double get vizIntensity => _prefs.getDouble(_kVizIntensity) ?? 0.5;

  Future<void> setVizIntensity(double value) async {
    await _prefs.setDouble(_kVizIntensity, value);
  }

  // — Viz Speed —

  double get vizSpeed => _prefs.getDouble(_kVizSpeed) ?? 0.5;

  Future<void> setVizSpeed(double value) async {
    await _prefs.setDouble(_kVizSpeed, value);
  }

  // — Viz Density —

  double get vizDensity => _prefs.getDouble(_kVizDensity) ?? 0.5;

  Future<void> setVizDensity(double value) async {
    await _prefs.setDouble(_kVizDensity, value);
  }

  // — High Scores —

  String get highScores => _prefs.getString(_kHighScores) ?? '';

  Future<void> setHighScores(String value) async {
    await _prefs.setString(_kHighScores, value);
  }
}
