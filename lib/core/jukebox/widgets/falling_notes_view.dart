import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/game_score.dart';
import '../models/note_block.dart';
import '../providers/jukebox_notifier.dart';
import '../../theme/theme_extensions.dart';
import 'piano_layout.dart';
import '../../l10n/l10n_extensions.dart';

/// Falling notes game view — renders note rectangles falling toward a hit line.
///
/// In **watch mode**, notes fall in sync with playback and keys light up
/// automatically. In **game mode**, the target channel is muted and the player
/// must press keys to hear notes and score points.
class FallingNotesView extends StatefulWidget {
  final List<NoteBlock> noteBlocks;
  final int targetChannel;
  final bool gameMode;
  final Set<int>? activeKeys;
  final void Function(int note, int deltaMs)? onHit;
  final void Function()? onMiss;

  /// When provided, override the dynamic note range so falling notes
  /// align with keyboard key positions.
  final int? keyboardNoteMin;
  final int? keyboardNoteMax;

  const FallingNotesView({
    super.key,
    required this.noteBlocks,
    required this.targetChannel,
    this.gameMode = false,
    this.activeKeys,
    this.onHit,
    this.onMiss,
    this.keyboardNoteMin,
    this.keyboardNoteMax,
  });

  @override
  State<FallingNotesView> createState() => FallingNotesViewState();
}

class FallingNotesViewState extends State<FallingNotesView>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  // Track which notes have been judged (by index) to avoid double-counting
  final Set<int> _judgedNotes = {};
  // Recent hit grades for on-screen feedback
  final List<_HitFeedback> _hitFeedbacks = [];
  // M1: Windowed iteration — skip notes already past the miss deadline
  int _windowStartIndex = 0;

  // Shared note range — computed once and shared between painter and feedback
  late int _noteMin;
  late int _noteRange;

  // Piano-layout aligned positioning (non-null when keyboard range is known)
  PianoLayout? _pianoLayout;
  double _viewWidth = 0;

  // Track when game mode started for timing hint
  DateTime? _gameStartTime;

  @override
  void initState() {
    super.initState();
    _computeNoteRange();
    if (widget.gameMode) _gameStartTime = DateTime.now();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..addListener(_tick);
    _controller.repeat();
  }

  @override
  void didUpdateWidget(covariant FallingNotesView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.noteBlocks != widget.noteBlocks ||
        oldWidget.keyboardNoteMin != widget.keyboardNoteMin ||
        oldWidget.keyboardNoteMax != widget.keyboardNoteMax) {
      _computeNoteRange();
    }
    if (widget.gameMode && !oldWidget.gameMode) {
      _gameStartTime = DateTime.now();
    } else if (!widget.gameMode && oldWidget.gameMode) {
      _gameStartTime = null;
    }
  }

  void _computeNoteRange() {
    if (widget.keyboardNoteMin != null && widget.keyboardNoteMax != null) {
      _noteMin = widget.keyboardNoteMin! - 2;
      _noteRange = (widget.keyboardNoteMax! - widget.keyboardNoteMin! + 4);
      _noteRange = max(_noteRange, 12);
    } else if (widget.noteBlocks.isEmpty) {
      _noteMin = 48; // C3
      _noteRange = 36; // 3 octaves
    } else {
      int minN = 127, maxN = 0;
      for (final block in widget.noteBlocks) {
        if (block.note < minN) minN = block.note;
        if (block.note > maxN) maxN = block.note;
      }
      final range = max(maxN - minN, 24);
      _noteMin = minN - 2;
      _noteRange = range + 4;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _tick() {
    if (!widget.gameMode || widget.noteBlocks.isEmpty) {
      return;
    }

    final jukebox = context.read<JukeboxNotifier>();
    final positionMicros = jukebox.position.inMicroseconds;
    final tempo = jukebox.tempo;

    bool stateChanged = false;

    for (int i = _windowStartIndex; i < widget.noteBlocks.length; i++) {
      if (_judgedNotes.contains(i)) continue;
      final block = widget.noteBlocks[i];
      final scaledStart = (block.startMicros * tempo).round();
      final deltaMs = ((positionMicros - scaledStart) / 1000).round();

      if (deltaMs > GameScore.goodWindow) {
        _judgedNotes.add(i);
        widget.onMiss?.call();
        _hitFeedbacks.add(_HitFeedback(
          grade: HitGrade.miss,
          x: _noteToX(block.note, 1.0),
          time: DateTime.now(),
        ));
        stateChanged = true;
      }
    }

    while (_windowStartIndex < widget.noteBlocks.length) {
      final block = widget.noteBlocks[_windowStartIndex];
      final scaledStart = (block.startMicros * tempo).round();
      final deltaMs = ((positionMicros - scaledStart) / 1000).round();
      if (deltaMs > GameScore.goodWindow &&
          _judgedNotes.contains(_windowStartIndex)) {
        _windowStartIndex++;
      } else {
        break;
      }
    }

    final feedbacksBefore = _hitFeedbacks.length;
    _hitFeedbacks.removeWhere(
        (f) => DateTime.now().difference(f.time).inMilliseconds > 600);
    if (_hitFeedbacks.length != feedbacksBefore) stateChanged = true;

    if (stateChanged || _hitFeedbacks.isNotEmpty) {
      setState(() {});
    }
  }

  /// Try to hit a note at the current position.
  void tryHit(int note) {
    if (!widget.gameMode || widget.noteBlocks.isEmpty) return;

    final jukebox = context.read<JukeboxNotifier>();
    final positionMicros = jukebox.position.inMicroseconds;
    final tempo = jukebox.tempo;

    int? bestIdx;
    int bestDelta = 999999;

    for (int i = _windowStartIndex; i < widget.noteBlocks.length; i++) {
      if (_judgedNotes.contains(i)) continue;
      final block = widget.noteBlocks[i];
      if (block.note != note) continue;
      final scaledStart = (block.startMicros * tempo).round();
      final deltaMs = ((positionMicros - scaledStart) / 1000).round().abs();
      if (deltaMs < bestDelta && deltaMs <= GameScore.goodWindow) {
        bestDelta = deltaMs;
        bestIdx = i;
      }
    }

    if (bestIdx != null) {
      _judgedNotes.add(bestIdx);
      widget.onHit?.call(note, bestDelta);
      final grade = GameScore.judge(bestDelta);
      _hitFeedbacks.add(_HitFeedback(
        grade: grade,
        x: _noteToX(note, 1.0),
        time: DateTime.now(),
      ));
    }
  }

  double _noteToX(int note, double totalWidth) {
    final layout = _pianoLayout;
    if (layout != null && _viewWidth > 0) {
      final pos = layout.positionOf(note);
      if (pos != null) {
        final offset = layout.centeringOffset(_viewWidth);
        return (pos.centerX + offset) / _viewWidth;
      }
    }
    return ((note - _noteMin) / _noteRange) * totalWidth;
  }

  @override
  Widget build(BuildContext context) {
    final jukebox = context.watch<JukeboxNotifier>();
    final t = context.t;
    final score = jukebox.currentScore;

    return LayoutBuilder(builder: (context, constraints) {
      final viewWidth = constraints.maxWidth;
      _viewWidth = viewWidth;

      // Compute piano layout when keyboard range is available
      if (widget.keyboardNoteMin != null && widget.keyboardNoteMax != null) {
        _pianoLayout = PianoLayout.fromRange(
          gameNoteMin: widget.keyboardNoteMin!,
          gameNoteMax: widget.keyboardNoteMax!,
          availableWidth: viewWidth,
        );
      } else {
        _pianoLayout = null;
      }

      return Stack(
        children: [
          // Falling notes canvas
          Positioned.fill(
            child: CustomPaint(
              painter: _FallingNotesPainter(
                noteBlocks: widget.noteBlocks,
                positionMicros: jukebox.position.inMicroseconds,
                tempo: jukebox.tempo,
                activeKeys: widget.activeKeys ?? {},
                gameMode: widget.gameMode,
                judgedNotes: _judgedNotes,
                accentColor: t.accent,
                noteMin: _noteMin,
                noteRange: _noteRange,
                pianoLayout: _pianoLayout,
                centeringOffset: _pianoLayout?.centeringOffset(viewWidth) ?? 0,
              ),
            ),
          ),
          // Score overlay (game mode only)
          if (widget.gameMode && score != null) ...[
            Positioned(
              top: 8,
              right: 12,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${score.score}',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: t.fontSize(18),
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2,
                      shadows: const [
                        Shadow(color: Colors.black54, blurRadius: 4)
                      ],
                    ),
                  ),
                  if (score.comboMultiplier > 1)
                    Text(
                      '${score.comboMultiplier}x',
                      style: TextStyle(
                        color: t.accentEdit,
                        fontSize: t.fontSize(11),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                ],
              ),
            ),
            if (score.combo > 0)
              Positioned(
                top: 8,
                left: 0,
                right: 0,
                child: Center(
                  child: Text(
                    context.l.jukeboxCombo(score.combo),
                    style: TextStyle(
                      color: score.combo >= 30
                          ? t.accentEdit
                          : score.combo >= 10
                              ? t.accent
                              : Colors.white70,
                      fontSize: t.fontSize(score.combo >= 30 ? 16 : 12),
                      fontWeight: FontWeight.w900,
                      letterSpacing: 3,
                      shadows: const [
                        Shadow(color: Colors.black54, blurRadius: 4)
                      ],
                    ),
                  ),
                ),
              ),
            Positioned(
              bottom: 8,
              right: 12,
              child: Text(
                '${(score.accuracy * 100).toStringAsFixed(1)}%',
                style: TextStyle(
                  color: Colors.white54,
                  fontSize: t.fontSize(10),
                  letterSpacing: 1,
                ),
              ),
            ),
          ],
          // "PRESS ON THE LINE" timing hint
          if (widget.gameMode && _gameStartTime != null &&
              DateTime.now().difference(_gameStartTime!).inMilliseconds <= 5000)
            Positioned(
              bottom: constraints.maxHeight * 0.18 + 8,
              left: 12,
              child: Opacity(
                opacity: () {
                  final elapsed = DateTime.now()
                      .difference(_gameStartTime!).inMilliseconds;
                  return elapsed < 4000
                      ? 0.5
                      : (0.5 * (1 - (elapsed - 4000) / 1000))
                          .clamp(0.0, 0.5);
                }(),
                child: Text(
                  context.l.jukeboxPressOnTheLine,
                  style: TextStyle(
                    color: t.textMinimal,
                    fontSize: t.fontSize(10),
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.5,
                  ),
                ),
              ),
            ),
          // Hit grade feedback — positioned at the note's X column
          ..._hitFeedbacks.map((f) {
            final age =
                DateTime.now().difference(f.time).inMilliseconds / 600;
            final opacity = (1 - age).clamp(0.0, 1.0);
            final xPos = f.x * viewWidth;
            final fontSize = switch (f.grade) {
              HitGrade.perfect => t.fontSize(16),
              HitGrade.great => t.fontSize(14),
              _ => t.fontSize(12),
            };
            return Positioned(
              left: (xPos - 30).clamp(0.0, viewWidth - 60),
              width: 60,
              bottom: 40 + age * 30,
              child: Opacity(
                opacity: opacity,
                child: Text(
                  _gradeText(f.grade, context),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: _gradeColor(f.grade),
                    fontSize: fontSize,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2,
                    shadows: const [
                      Shadow(color: Colors.black87, blurRadius: 6)
                    ],
                  ),
                ),
              ),
            );
          }),
        ],
      );
    });
  }

  String _gradeText(HitGrade grade, BuildContext context) {
    final l = context.l;
    switch (grade) {
      case HitGrade.perfect:
        return l.jukeboxGradePerfect;
      case HitGrade.great:
        return l.jukeboxGradeGreat;
      case HitGrade.good:
        return l.jukeboxGradeGood;
      case HitGrade.miss:
        return l.jukeboxGradeMiss;
    }
  }

  Color _gradeColor(HitGrade grade) {
    switch (grade) {
      case HitGrade.perfect:
        return const Color(0xFFFFD700);
      case HitGrade.great:
        return const Color(0xFF22C55E);
      case HitGrade.good:
        return const Color(0xFF3B82F6);
      case HitGrade.miss:
        return const Color(0xFFEF4444);
    }
  }
}

class _HitFeedback {
  final HitGrade grade;
  final double x; // 0..1 normalized
  final DateTime time;
  _HitFeedback({required this.grade, required this.x, required this.time});
}

/// CustomPainter that renders falling note rectangles + hit line.
class _FallingNotesPainter extends CustomPainter {
  final List<NoteBlock> noteBlocks;
  final int positionMicros;
  final double tempo;
  final Set<int> activeKeys;
  final bool gameMode;
  final Set<int> judgedNotes;
  final Color accentColor;
  final int noteMin;
  final int noteRange;
  final PianoLayout? pianoLayout;
  final double centeringOffset;

  static const _lookAheadMicros = 4000000;
  static const _lookBehindMicros = 500000;
  static const _isBlackKey = [
    false, true, false, true, false, false,
    true, false, true, false, true, false,
  ];

  _FallingNotesPainter({
    required this.noteBlocks,
    required this.positionMicros,
    required this.tempo,
    required this.activeKeys,
    required this.gameMode,
    required this.judgedNotes,
    required this.accentColor,
    required this.noteMin,
    required this.noteRange,
    this.pianoLayout,
    this.centeringOffset = 0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (noteBlocks.isEmpty) return;

    final layout = pianoLayout;
    final hitLineY = size.height * 0.85;
    final pixelsPerMicro = hitLineY / _lookAheadMicros;

    // Draw hit line
    final hitLinePaint = Paint()
      ..color = accentColor.withValues(alpha: 0.6)
      ..strokeWidth = 2;
    canvas.drawLine(
      Offset(0, hitLineY),
      Offset(size.width, hitLineY),
      hitLinePaint,
    );

    // Hit line glow
    final glowPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          accentColor.withValues(alpha: 0),
          accentColor.withValues(alpha: 0.15),
          accentColor.withValues(alpha: 0),
        ],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(
          Rect.fromLTWH(0, hitLineY - 10, size.width, 20));
    canvas.drawRect(
        Rect.fromLTWH(0, hitLineY - 10, size.width, 20), glowPaint);

    // Fallback note width for linear mode
    final linearNoteWidth = (size.width / noteRange).clamp(6.0, 28.0);

    // Lane dividers & black-key shading
    if (layout != null) {
      final lanePaint = Paint()
        ..color = Colors.white.withValues(alpha: 0.03)
        ..strokeWidth = 0.5;
      // Draw lane dividers at each C boundary
      for (final note in layout.whiteKeys) {
        if (note % 12 == 0) {
          final pos = layout.positionOf(note);
          if (pos != null) {
            final x = pos.centerX - pos.width / 2 + centeringOffset;
            canvas.drawLine(Offset(x, 0), Offset(x, size.height), lanePaint);
          }
        }
      }

      // Black-key lane shading
      final blackLanePaint = Paint()
        ..color = Colors.white.withValues(alpha: 0.025);
      for (final note in layout.blackKeys) {
        final pos = layout.positionOf(note);
        if (pos != null) {
          final x = pos.centerX + centeringOffset;
          canvas.drawRect(
            Rect.fromLTWH(
                x - pos.width / 2, 0, pos.width, size.height),
            blackLanePaint,
          );
        }
      }
    } else {
      // Fallback: linear lane dividers
      final lanePaint = Paint()
        ..color = Colors.white.withValues(alpha: 0.03)
        ..strokeWidth = 0.5;
      for (int n = noteMin; n <= noteMin + noteRange; n++) {
        if (n % 12 == 0) {
          final x = (n - noteMin) / noteRange * size.width;
          canvas.drawLine(Offset(x, 0), Offset(x, size.height), lanePaint);
        }
      }

      // Fallback: linear black-key lane shading
      final blackLanePaint = Paint()
        ..color = Colors.white.withValues(alpha: 0.025);
      for (int n = noteMin; n <= noteMin + noteRange; n++) {
        if (_isBlackKey[n % 12]) {
          final x = (n - noteMin) / noteRange * size.width;
          canvas.drawRect(
            Rect.fromLTWH(
                x - linearNoteWidth / 2, 0, linearNoteWidth, size.height),
            blackLanePaint,
          );
        }
      }
    }

    // Draw notes
    for (int i = 0; i < noteBlocks.length; i++) {
      final block = noteBlocks[i];
      final scaledStart = (block.startMicros * tempo).round();
      final scaledEnd = (block.endMicros * tempo).round();

      final startDelta = scaledStart - positionMicros;
      final endDelta = scaledEnd - positionMicros;
      if (startDelta > _lookAheadMicros) continue;
      if (endDelta < -_lookBehindMicros) continue;

      // Compute X and width from layout or linear fallback
      final double x;
      final double noteWidth;
      final pos = layout?.positionOf(block.note);
      if (pos != null) {
        x = pos.centerX + centeringOffset;
        noteWidth = pos.width;
      } else {
        x = ((block.note - noteMin) / noteRange) * size.width;
        noteWidth = linearNoteWidth;
      }

      final yTop = hitLineY - startDelta * pixelsPerMicro;
      final yBottom = hitLineY - endDelta * pixelsPerMicro;
      final height = (yBottom - yTop).clamp(6.0, size.height * 2);

      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(x - noteWidth / 2, yTop, noteWidth, height),
        const Radius.circular(3),
      );

      final bool isJudged = judgedNotes.contains(i);
      final bool isPast = startDelta < 0;
      final proximity =
          1 - (startDelta.abs() / _lookAheadMicros).clamp(0.0, 1.0);
      final velocityAlpha = 0.4 + (block.velocity / 127) * 0.6;

      Color noteColor;
      double alpha;

      if (isJudged && gameMode) {
        noteColor = Colors.white;
        alpha = isPast
            ? (0.5 - (startDelta.abs() / _lookBehindMicros)).clamp(0.0, 0.5)
            : 0.3;
      } else if (isPast && gameMode) {
        noteColor = Colors.grey;
        alpha = (0.4 - (startDelta.abs() / _lookBehindMicros) * 0.4)
            .clamp(0.0, 0.4);
      } else if (isPast) {
        noteColor = block.color;
        alpha = (velocityAlpha -
                (startDelta.abs() / _lookBehindMicros) * velocityAlpha)
            .clamp(0.0, velocityAlpha);
      } else {
        // Approach glow: lerp toward white as note enters bottom half
        if (proximity > 0.5) {
          final warmup = (proximity - 0.5) / 0.5; // 0→1 over bottom half
          noteColor = Color.lerp(block.color, Colors.white, warmup)!;
          alpha = (velocityAlpha * (0.5 + proximity * 0.5) + warmup * 0.3)
              .clamp(0.0, 1.0);
        } else {
          noteColor = block.color;
          alpha = velocityAlpha * (0.5 + proximity * 0.5);
        }
      }

      final paint = Paint()..color = noteColor.withValues(alpha: alpha);
      canvas.drawRRect(rect, paint);

      // Glow effect — starts at proximity > 0.5, intensifies toward hit line
      if (!isPast && proximity > 0.5) {
        final glowT = (proximity - 0.5) / 0.5; // 0→1
        final glowAlpha = glowT * 0.4 * velocityAlpha;
        final blurRadius = 4.0 + glowT * 10.0; // 4→14
        final glow = Paint()
          ..color = noteColor.withValues(alpha: glowAlpha)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, blurRadius);
        canvas.drawRRect(rect, glow);
      }

      // Flash on hit line when note is hit
      if (isJudged && gameMode && startDelta.abs() < 100000) {
        final flashPaint = Paint()
          ..color = Colors.white.withValues(alpha: 0.4)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
        canvas.drawCircle(Offset(x, hitLineY), noteWidth * 0.8, flashPaint);
      }

      // Diamond marker for black-key notes
      if (_isBlackKey[block.note % 12]) {
        final diamondSize = noteWidth * 0.35;
        final diamondPaint = Paint()
          ..color = Colors.white.withValues(alpha: 0.5);
        final cx = x;
        final cy = yTop + diamondSize + 2;
        canvas.save();
        canvas.translate(cx, cy);
        canvas.rotate(pi / 4);
        canvas.drawRect(
          Rect.fromCenter(
              center: Offset.zero,
              width: diamondSize,
              height: diamondSize),
          diamondPaint,
        );
        canvas.restore();
      }
    }
  }

  @override
  bool shouldRepaint(_FallingNotesPainter oldDelegate) =>
      positionMicros != oldDelegate.positionMicros ||
      tempo != oldDelegate.tempo ||
      gameMode != oldDelegate.gameMode ||
      noteMin != oldDelegate.noteMin ||
      noteRange != oldDelegate.noteRange ||
      accentColor != oldDelegate.accentColor ||
      centeringOffset != oldDelegate.centeringOffset ||
      !identical(noteBlocks, oldDelegate.noteBlocks) ||
      !identical(pianoLayout, oldDelegate.pianoLayout) ||
      !identical(activeKeys, oldDelegate.activeKeys) ||
      !identical(judgedNotes, oldDelegate.judgedNotes);
}
