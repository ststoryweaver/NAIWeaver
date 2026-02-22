import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/note_block.dart';
import '../../theme/vision_tokens.dart';
import 'piano_layout.dart';

/// Scrollable multi-octave piano keyboard with dark theme and finger-glide.
///
/// Supports touch/mouse interaction and desktop keyboard mapping.
/// A-L row = white keys, W-P row = black keys, Z/X = octave shift.
///
/// In [gameMode], keys are sized to fit the song's note range with a
/// minimum 48px touch target. Scrolling is locked.
class PianoKeyboard extends StatefulWidget {
  final VisionTokens t;
  final int startOctave;
  final int octaveCount;
  final Set<int>? highlightedNotes;
  final void Function(int note)? onNoteOn;
  final void Function(int note)? onNoteOff;
  final double? height;

  /// Game-mode sizing: show only keys around the song's note range.
  final bool gameMode;
  final int? gameNoteMin;
  final int? gameNoteMax;

  const PianoKeyboard({
    super.key,
    required this.t,
    this.startOctave = 3,
    this.octaveCount = 5,
    this.highlightedNotes,
    this.onNoteOn,
    this.onNoteOff,
    this.height,
    this.gameMode = false,
    this.gameNoteMin,
    this.gameNoteMax,
  });

  @override
  State<PianoKeyboard> createState() => _PianoKeyboardState();
}

class _PianoKeyboardState extends State<PianoKeyboard> {
  final Set<int> _activeNotes = {};
  final Map<int, int> _pointerNotes = {}; // pointerId -> note
  int _currentOctave = 4;
  final FocusNode _focusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();

  // Desktop keyboard mapping
  static final _whiteKeyMap = {
    LogicalKeyboardKey.keyA: 0,
    LogicalKeyboardKey.keyS: 2,
    LogicalKeyboardKey.keyD: 4,
    LogicalKeyboardKey.keyF: 5,
    LogicalKeyboardKey.keyG: 7,
    LogicalKeyboardKey.keyH: 9,
    LogicalKeyboardKey.keyJ: 11,
    LogicalKeyboardKey.keyK: 12,
    LogicalKeyboardKey.keyL: 14,
  };

  static final _blackKeyMap = {
    LogicalKeyboardKey.keyW: 1,
    LogicalKeyboardKey.keyE: 3,
    LogicalKeyboardKey.keyT: 6,
    LogicalKeyboardKey.keyY: 8,
    LogicalKeyboardKey.keyU: 10,
    LogicalKeyboardKey.keyO: 13,
    LogicalKeyboardKey.keyP: 15,
  };

  final Set<LogicalKeyboardKey> _heldKeys = {};

  static const _isBlackKey = [
    false, true, false, true, false, false, true, false, true, false, true, false
  ];

  // Pre-computed key rects for hit-testing
  Map<int, Rect> _whiteKeyRects = {};
  Map<int, Rect> _blackKeyRects = {};

  // Computed layout values
  late List<int> _whiteKeys;
  late List<int> _blackKeys;
  late double _whiteKeyWidth;
  late double _blackKeyWidth;
  late double _keyboardHeight;
  late double _blackKeyHeight;
  late double _totalWidth;

  int get _lowestNote {
    if (widget.gameMode && widget.gameNoteMin != null) {
      // Expand 2 notes below the min, clamped to C boundary
      final expanded = widget.gameNoteMin! - 2;
      // Snap down to nearest white key
      int note = expanded;
      while (note > 0 && _isBlackKey[note % 12]) {
        note--;
      }
      return note.clamp(0, 127);
    }
    return widget.startOctave * 12;
  }

  int get _highestNote {
    if (widget.gameMode && widget.gameNoteMax != null) {
      final expanded = widget.gameNoteMax! + 2;
      int note = expanded;
      while (note < 127 && _isBlackKey[note % 12]) {
        note++;
      }
      return note.clamp(0, 127);
    }
    return (widget.startOctave + widget.octaveCount) * 12 - 1;
  }

  @override
  void initState() {
    super.initState();
    _currentOctave = widget.startOctave + 1;
  }

  @override
  void dispose() {
    for (final note in _activeNotes.toList()) {
      widget.onNoteOff?.call(note);
    }
    _activeNotes.clear();
    _focusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _noteOn(int note) {
    if (note < 0 || note > 127) return;
    if (_activeNotes.add(note)) {
      widget.onNoteOn?.call(note);
      setState(() {});
    }
  }

  void _noteOff(int note) {
    if (_activeNotes.remove(note)) {
      widget.onNoteOff?.call(note);
      setState(() {});
    }
  }

  int? _noteFromKey(LogicalKeyboardKey key) {
    final white = _whiteKeyMap[key];
    if (white != null) return _currentOctave * 12 + white;
    final black = _blackKeyMap[key];
    if (black != null) return _currentOctave * 12 + black;
    return null;
  }

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is KeyDownEvent) {
      if (event.logicalKey == LogicalKeyboardKey.keyZ) {
        setState(() => _currentOctave = (_currentOctave - 1).clamp(0, 8));
        return KeyEventResult.handled;
      }
      if (event.logicalKey == LogicalKeyboardKey.keyX) {
        setState(() => _currentOctave = (_currentOctave + 1).clamp(0, 8));
        return KeyEventResult.handled;
      }
    }

    final note = _noteFromKey(event.logicalKey);
    if (note == null) return KeyEventResult.ignored;

    if (event is KeyDownEvent && !_heldKeys.contains(event.logicalKey)) {
      _heldKeys.add(event.logicalKey);
      _noteOn(note);
      return KeyEventResult.handled;
    } else if (event is KeyUpEvent) {
      _heldKeys.remove(event.logicalKey);
      _noteOff(note);
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  // ─── Pointer glide support ───

  int? _noteFromPosition(Offset localPos) {
    // Check black keys first (they're on top)
    for (final entry in _blackKeyRects.entries) {
      if (entry.value.contains(localPos)) return entry.key;
    }
    for (final entry in _whiteKeyRects.entries) {
      if (entry.value.contains(localPos)) return entry.key;
    }
    return null;
  }

  void _handlePointerDown(PointerDownEvent event) {
    _focusNode.requestFocus();
    final note = _noteFromPosition(event.localPosition);
    if (note != null) {
      _pointerNotes[event.pointer] = note;
      _noteOn(note);
    }
  }

  void _handlePointerMove(PointerMoveEvent event) {
    final note = _noteFromPosition(event.localPosition);
    final prev = _pointerNotes[event.pointer];
    if (note != prev) {
      if (prev != null) _noteOff(prev);
      if (note != null) {
        _pointerNotes[event.pointer] = note;
        _noteOn(note);
      } else {
        _pointerNotes.remove(event.pointer);
      }
    }
  }

  void _handlePointerUp(PointerUpEvent event) {
    final note = _pointerNotes.remove(event.pointer);
    if (note != null) _noteOff(note);
  }

  void _handlePointerCancel(PointerCancelEvent event) {
    final note = _pointerNotes.remove(event.pointer);
    if (note != null) _noteOff(note);
  }

  // ─── Layout computation ───

  void _computeLayout(double availableWidth) {
    _keyboardHeight = widget.height ?? 160.0;
    _blackKeyHeight = _keyboardHeight * 0.6;

    if (widget.gameMode &&
        widget.gameNoteMin != null &&
        widget.gameNoteMax != null) {
      // Game mode: delegate to shared PianoLayout for identical math
      final layout = PianoLayout.fromRange(
        gameNoteMin: widget.gameNoteMin!,
        gameNoteMax: widget.gameNoteMax!,
        availableWidth: availableWidth,
      );

      _whiteKeys = List<int>.from(layout.whiteKeys);
      _blackKeys = List<int>.from(layout.blackKeys);
      _whiteKeyWidth = layout.whiteKeyWidth;
      _blackKeyWidth = layout.blackKeyWidth;
      _totalWidth = layout.totalWidth;

      // Build rect maps from layout positions
      _whiteKeyRects = {};
      _blackKeyRects = {};

      for (final note in _whiteKeys) {
        final pos = layout.positionOf(note)!;
        _whiteKeyRects[note] = Rect.fromLTWH(
          pos.centerX - pos.width / 2,
          0,
          pos.width,
          _keyboardHeight,
        );
      }

      for (final note in _blackKeys) {
        final pos = layout.positionOf(note);
        if (pos == null) continue;
        _blackKeyRects[note] = Rect.fromLTWH(
          pos.centerX - pos.width / 2,
          0,
          pos.width,
          _blackKeyHeight,
        );
      }
      return;
    }

    // Non-game mode: original fixed-size layout
    _whiteKeys = <int>[];
    _blackKeys = <int>[];
    final low = _lowestNote;
    final high = _highestNote;
    for (int note = low; note <= high; note++) {
      if (_isBlackKey[note % 12]) {
        _blackKeys.add(note);
      } else {
        _whiteKeys.add(note);
      }
    }

    _whiteKeyWidth = 40.0;
    _blackKeyWidth = 28.0;
    _totalWidth = _whiteKeys.length * _whiteKeyWidth;

    // Build rect maps for hit-testing
    _whiteKeyRects = {};
    _blackKeyRects = {};

    final whiteKeyIndex = <int, int>{};
    for (int i = 0; i < _whiteKeys.length; i++) {
      final note = _whiteKeys[i];
      whiteKeyIndex[note] = i;
      _whiteKeyRects[note] = Rect.fromLTWH(
        i * _whiteKeyWidth,
        0,
        _whiteKeyWidth,
        _keyboardHeight,
      );
    }

    for (final note in _blackKeys) {
      final lowerWhite = note - 1;
      final lowerWhiteNote =
          _isBlackKey[lowerWhite % 12] ? lowerWhite - 1 : lowerWhite;
      final idx = whiteKeyIndex[lowerWhiteNote];
      if (idx == null) continue;
      final xPos = (idx + 1) * _whiteKeyWidth - _blackKeyWidth / 2;
      _blackKeyRects[note] = Rect.fromLTWH(xPos, 0, _blackKeyWidth, _blackKeyHeight);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.t;

    return Focus(
      focusNode: _focusNode,
      onKeyEvent: _handleKeyEvent,
      autofocus: true,
      child: GestureDetector(
        onTap: () => _focusNode.requestFocus(),
        child: SizedBox(
          height: widget.height ?? 160.0,
          child: LayoutBuilder(builder: (context, constraints) {
            _computeLayout(constraints.maxWidth);

            final keyboardStack = Stack(
              children: [
                ..._buildWhiteKeys(t),
                ..._buildBlackKeys(t),
              ],
            );

            final content = SizedBox(
              width: _totalWidth,
              height: _keyboardHeight,
              child: Listener(
                onPointerDown: _handlePointerDown,
                onPointerMove: _handlePointerMove,
                onPointerUp: _handlePointerUp,
                onPointerCancel: _handlePointerCancel,
                behavior: HitTestBehavior.opaque,
                child: keyboardStack,
              ),
            );

            if (widget.gameMode) {
              // No scrolling in game mode — center the keys
              if (_totalWidth <= constraints.maxWidth) {
                return Center(child: content);
              }
              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const ClampingScrollPhysics(),
                child: content,
              );
            }

            return SingleChildScrollView(
              controller: _scrollController,
              scrollDirection: Axis.horizontal,
              child: content,
            );
          }),
        ),
      ),
    );
  }

  List<Widget> _buildWhiteKeys(VisionTokens t) {
    return List.generate(_whiteKeys.length, (i) {
      final note = _whiteKeys[i];
      final isActive = _activeNotes.contains(note);
      final isHighlighted = widget.highlightedNotes?.contains(note) ?? false;

      Color keyColor;
      if (isActive) {
        keyColor = t.accentEdit;
      } else if (isHighlighted) {
        keyColor = NoteBlock.pitchClassColors[note % 12].withValues(alpha: 0.35);
      } else {
        // Dark theme: faint accent-tinted wash
        keyColor = t.accent.withValues(alpha: 0.07);
      }

      return Positioned(
        left: i * _whiteKeyWidth,
        top: 0,
        width: _whiteKeyWidth,
        height: _keyboardHeight,
        child: Container(
          decoration: BoxDecoration(
            color: keyColor,
            border: Border.all(
              color: t.accent.withValues(alpha: 0.15),
              width: 0.5,
            ),
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(4),
              bottomRight: Radius.circular(4),
            ),
          ),
          alignment: Alignment.bottomCenter,
          padding: const EdgeInsets.only(bottom: 6),
          child: note % 12 == 0
              ? Text(
                  'C${note ~/ 12}',
                  style: TextStyle(
                    color: isActive ? Colors.white : t.textMinimal,
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                  ),
                )
              : null,
        ),
      );
    });
  }

  List<Widget> _buildBlackKeys(VisionTokens t) {
    final whiteKeyIndex = <int, int>{};
    for (int i = 0; i < _whiteKeys.length; i++) {
      whiteKeyIndex[_whiteKeys[i]] = i;
    }

    return _blackKeys.map((note) {
      final isActive = _activeNotes.contains(note);
      final isHighlighted = widget.highlightedNotes?.contains(note) ?? false;

      Color keyColor;
      if (isActive) {
        keyColor = t.accentEdit;
      } else if (isHighlighted) {
        keyColor = NoteBlock.pitchClassColors[note % 12].withValues(alpha: 0.35);
      } else {
        // Dark theme: barely visible, darker than naturals
        keyColor = t.accent.withValues(alpha: 0.03);
      }

      final lowerWhite = note - 1;
      final lowerWhiteNote =
          _isBlackKey[lowerWhite % 12] ? lowerWhite - 1 : lowerWhite;
      final idx = whiteKeyIndex[lowerWhiteNote];
      if (idx == null) return const SizedBox.shrink();

      final xPos = (idx + 1) * _whiteKeyWidth - _blackKeyWidth / 2;

      return Positioned(
        left: xPos,
        top: 0,
        width: _blackKeyWidth,
        height: _blackKeyHeight,
        child: Container(
          decoration: BoxDecoration(
            color: keyColor,
            border: Border.all(
              color: t.accent.withValues(alpha: 0.15),
              width: 0.5,
            ),
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(4),
              bottomRight: Radius.circular(4),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.4),
                blurRadius: 3,
                offset: const Offset(0, 2),
              ),
            ],
          ),
        ),
      );
    }).toList();
  }
}
