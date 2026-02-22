import 'dart:collection';

/// Pure layout utility that maps MIDI notes to horizontal positions using
/// diatonic (piano-style) spacing. Both [FallingNotesView] and [PianoKeyboard]
/// share this class so note columns are guaranteed to align pixel-perfectly.
class PianoLayout {
  /// Position info for a single MIDI note.
  final Map<int, NotePosition> notePositions;

  /// All white keys in range, sorted ascending.
  final List<int> whiteKeys;

  /// All black keys in range, sorted ascending.
  final List<int> blackKeys;

  /// Width of each white key in pixels.
  final double whiteKeyWidth;

  /// Width of each black key in pixels.
  final double blackKeyWidth;

  /// Total keyboard width in pixels (whiteKeys.length * whiteKeyWidth).
  final double totalWidth;

  /// The lowest MIDI note (white-key-snapped).
  final int lowestNote;

  /// The highest MIDI note (white-key-snapped).
  final int highestNote;

  PianoLayout._({
    required this.notePositions,
    required this.whiteKeys,
    required this.blackKeys,
    required this.whiteKeyWidth,
    required this.blackKeyWidth,
    required this.totalWidth,
    required this.lowestNote,
    required this.highestNote,
  });

  static const _isBlackKey = [
    false, true, false, true, false, false,
    true, false, true, false, true, false,
  ];

  /// Whether a MIDI note number is a black key.
  static bool isBlack(int midiNote) => _isBlackKey[midiNote % 12];

  /// Build a layout for the given game note range and available pixel width.
  ///
  /// Boundaries are snapped outward to white keys (matching [PianoKeyboard]'s
  /// `_lowestNote` / `_highestNote` logic) and white-key width is clamped to
  /// 20–80 px.
  factory PianoLayout.fromRange({
    required int gameNoteMin,
    required int gameNoteMax,
    required double availableWidth,
  }) {
    // Expand by 2 then snap down/up to nearest white key.
    int low = gameNoteMin - 2;
    while (low > 0 && _isBlackKey[low % 12]) {
      low--;
    }
    low = low.clamp(0, 127);

    int high = gameNoteMax + 2;
    while (high < 127 && _isBlackKey[high % 12]) {
      high++;
    }
    high = high.clamp(0, 127);

    // Separate into white / black key lists.
    final whites = <int>[];
    final blacks = <int>[];
    for (int n = low; n <= high; n++) {
      if (_isBlackKey[n % 12]) {
        blacks.add(n);
      } else {
        whites.add(n);
      }
    }

    final whiteKeyWidth =
        whites.isEmpty ? 48.0 : (availableWidth / whites.length).clamp(20.0, 80.0);
    final blackKeyWidth = whiteKeyWidth * 0.70;
    final totalWidth = whites.length * whiteKeyWidth;

    // Build index lookup: white note -> sequential index.
    final whiteIndex = <int, int>{};
    for (int i = 0; i < whites.length; i++) {
      whiteIndex[whites[i]] = i;
    }

    final positions = <int, NotePosition>{};

    // White keys: evenly spaced.
    for (int i = 0; i < whites.length; i++) {
      final note = whites[i];
      positions[note] = NotePosition(
        centerX: i * whiteKeyWidth + whiteKeyWidth / 2,
        width: whiteKeyWidth,
      );
    }

    // Black keys: centered on the boundary between the lower white key and
    // the next white key (same formula as PianoKeyboard).
    for (final note in blacks) {
      final lowerWhite = note - 1;
      final lowerWhiteNote =
          _isBlackKey[lowerWhite % 12] ? lowerWhite - 1 : lowerWhite;
      final idx = whiteIndex[lowerWhiteNote];
      if (idx == null) continue;
      final xPos = (idx + 1) * whiteKeyWidth;
      positions[note] = NotePosition(
        centerX: xPos,
        width: blackKeyWidth,
      );
    }

    return PianoLayout._(
      notePositions: UnmodifiableMapView(positions),
      whiteKeys: List.unmodifiable(whites),
      blackKeys: List.unmodifiable(blacks),
      whiteKeyWidth: whiteKeyWidth,
      blackKeyWidth: blackKeyWidth,
      totalWidth: totalWidth,
      lowestNote: low,
      highestNote: high,
    );
  }

  /// Horizontal offset to center the keyboard within [containerWidth].
  /// Returns 0 when the keyboard is wider than the container.
  double centeringOffset(double containerWidth) {
    if (totalWidth >= containerWidth) return 0;
    return (containerWidth - totalWidth) / 2;
  }

  /// Look up the position of a single MIDI note, or `null` if out of range.
  NotePosition? positionOf(int midiNote) => notePositions[midiNote];
}

/// Horizontal center and width for a single piano key / note lane.
class NotePosition {
  /// Center X relative to the keyboard's left edge (0 = keyboard start).
  final double centerX;

  /// Visual width of the key / lane in pixels.
  final double width;

  const NotePosition({required this.centerX, required this.width});
}
