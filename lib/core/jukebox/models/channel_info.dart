import 'package:flutter/material.dart';

/// Difficulty tier based on note density.
enum Difficulty { easy, medium, hard, extreme }

/// Analysis of a single MIDI channel's content within a song.
class ChannelInfo {
  final int channel;
  final int programNumber;
  final String instrumentName;
  final int noteCount;
  final int minNote;
  final int maxNote;
  final double noteDensity; // notes per second
  final bool isDrums;

  const ChannelInfo({
    required this.channel,
    required this.programNumber,
    required this.instrumentName,
    required this.noteCount,
    required this.minNote,
    required this.maxNote,
    required this.noteDensity,
    required this.isDrums,
  });

  Difficulty get difficulty =>
      noteDensity < 2
          ? Difficulty.easy
          : noteDensity < 5
              ? Difficulty.medium
              : noteDensity < 10
                  ? Difficulty.hard
                  : Difficulty.extreme;

  Color get difficultyColor => switch (difficulty) {
        Difficulty.easy => const Color(0xFF22C55E),
        Difficulty.medium => const Color(0xFFEAB308),
        Difficulty.hard => const Color(0xFFF97316),
        Difficulty.extreme => const Color(0xFFEF4444),
      };
}
