import 'package:flutter/material.dart' show Color;
import 'jukebox_song.dart';
import '../../services/preferences_service.dart';

/// Encapsulates visualizer state and preferences.
class VisualizerConfig {
  final PreferencesService _prefs;

  Color? color;
  VisualizerStyle style;
  double intensity;
  double speed;
  double density;

  VisualizerConfig({required PreferencesService prefs})
      : _prefs = prefs,
        intensity = prefs.jukeboxVizIntensity,
        speed = prefs.jukeboxVizSpeed,
        density = prefs.jukeboxVizDensity,
        style = VisualizerStyle.values.firstWhere(
          (s) => s.name == prefs.jukeboxVisualizerStyle,
          orElse: () => VisualizerStyle.particles,
        ) {
    final vizColor = prefs.jukeboxVisualizerColor;
    if (vizColor != null) color = Color(vizColor);
  }

  void setColor(Color? c) {
    color = c;
    _prefs.setJukeboxVisualizerColor(c?.toARGB32());
  }

  void setStyle(VisualizerStyle s) {
    style = s;
    _prefs.setJukeboxVisualizerStyle(s.name);
  }

  void setIntensity(double v) {
    intensity = v.clamp(0.0, 1.0);
    _prefs.setJukeboxVizIntensity(intensity);
  }

  void setSpeed(double v) {
    speed = v.clamp(0.0, 1.0);
    _prefs.setJukeboxVizSpeed(speed);
  }

  void setDensity(double v) {
    density = v.clamp(0.0, 1.0);
    _prefs.setJukeboxVizDensity(density);
  }
}
