import 'package:flutter/material.dart';

/// Pre-processed note with duration, for rendering as a falling rectangle.
class NoteBlock {
  final int note; // MIDI note 0-127
  final int channel; // MIDI channel 0-15
  final int velocity; // 0-127
  final int startMicros; // Absolute start time in microseconds
  final int endMicros; // Absolute end time (from paired noteOff)
  final int colorIndex; // Pre-assigned color lane (0-11, based on pitch class)

  const NoteBlock({
    required this.note,
    required this.channel,
    required this.velocity,
    required this.startMicros,
    required this.endMicros,
    required this.colorIndex,
  });

  int get durationMicros => endMicros - startMicros;

  /// Rainbow palette by pitch class: C=0 through B=11.
  static const pitchClassColors = [
    Color(0xFFEF4444), // C  - red
    Color(0xFFEA580C), // C# - red-orange
    Color(0xFFF97316), // D  - orange
    Color(0xFFEAB308), // D# - gold
    Color(0xFFFACC15), // E  - yellow
    Color(0xFF22C55E), // F  - green
    Color(0xFF14B8A6), // F# - teal
    Color(0xFF06B6D4), // G  - cyan
    Color(0xFF3B82F6), // G# - blue
    Color(0xFF6366F1), // A  - indigo
    Color(0xFFA855F7), // A# - purple
    Color(0xFFEC4899), // B  - magenta
  ];

  Color get color => pitchClassColors[colorIndex];
}
