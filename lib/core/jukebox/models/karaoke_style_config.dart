import 'package:flutter/material.dart' show Color;
import '../../services/preferences_service.dart';

/// Encapsulates karaoke display styling preferences.
class KaraokeStyleConfig {
  final PreferencesService _prefs;

  Color? highlightColor;
  Color? upcomingColor;
  Color? nextLineColor;
  String? fontFamily;
  double fontScale;
  bool showMiniLyric;
  bool showKaraokeInPanel;

  KaraokeStyleConfig({required PreferencesService prefs})
      : _prefs = prefs,
        fontScale = prefs.jukeboxKaraokeFontScale,
        showMiniLyric = prefs.jukeboxShowMiniLyric,
        showKaraokeInPanel = prefs.jukeboxShowKaraokeInPanel,
        fontFamily = prefs.jukeboxKaraokeFontFamily {
    final hlColor = prefs.jukeboxKaraokeHighlightColor;
    if (hlColor != null) highlightColor = Color(hlColor);
    final upColor = prefs.jukeboxKaraokeUpcomingColor;
    if (upColor != null) upcomingColor = Color(upColor);
    final nlColor = prefs.jukeboxKaraokeNextLineColor;
    if (nlColor != null) nextLineColor = Color(nlColor);
  }

  void setHighlightColor(Color? color) {
    highlightColor = color;
    _prefs.setJukeboxKaraokeHighlightColor(color?.toARGB32());
  }

  void setUpcomingColor(Color? color) {
    upcomingColor = color;
    _prefs.setJukeboxKaraokeUpcomingColor(color?.toARGB32());
  }

  void setNextLineColor(Color? color) {
    nextLineColor = color;
    _prefs.setJukeboxKaraokeNextLineColor(color?.toARGB32());
  }

  void setFontFamily(String? family) {
    fontFamily = family;
    _prefs.setJukeboxKaraokeFontFamily(family);
  }

  void setFontScale(double scale) {
    fontScale = scale.clamp(0.5, 2.0);
    _prefs.setJukeboxKaraokeFontScale(fontScale);
  }

  void toggleMiniLyric() {
    showMiniLyric = !showMiniLyric;
    _prefs.setJukeboxShowMiniLyric(showMiniLyric);
  }

  void toggleKaraokeInPanel() {
    showKaraokeInPanel = !showKaraokeInPanel;
    _prefs.setJukeboxShowKaraokeInPanel(showKaraokeInPanel);
  }

  void reset() {
    highlightColor = null;
    upcomingColor = null;
    nextLineColor = null;
    fontFamily = null;
    fontScale = 1.0;
    _prefs.setJukeboxKaraokeHighlightColor(null);
    _prefs.setJukeboxKaraokeUpcomingColor(null);
    _prefs.setJukeboxKaraokeNextLineColor(null);
    _prefs.setJukeboxVisualizerColor(null);
    _prefs.setJukeboxKaraokeFontFamily(null);
    _prefs.setJukeboxKaraokeFontScale(1.0);
  }
}
