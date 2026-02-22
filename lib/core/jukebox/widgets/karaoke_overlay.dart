import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/jukebox_notifier.dart';
import '../midi_sequencer.dart';
import '../../theme/theme_extensions.dart';

/// Translucent overlay for displaying karaoke lyrics.
/// Shows current lyric line with syllable highlighting.
class KaraokeOverlay extends StatelessWidget {
  final bool singleLine;
  final bool preview;

  const KaraokeOverlay({super.key, this.singleLine = false, this.preview = false});

  @override
  Widget build(BuildContext context) {
    final jukebox = context.watch<JukeboxNotifier>();

    if (jukebox.currentSong == null || !jukebox.currentSong!.isKaraoke) {
      return const SizedBox.shrink();
    }

    final lyrics = jukebox.lyrics;
    if (lyrics.isEmpty) return const SizedBox.shrink();

    // Find current lyric line based on position
    final position = jukebox.position;
    LyricLine? currentLine;
    LyricLine? nextLine;

    for (int i = 0; i < lyrics.length; i++) {
      final line = lyrics[i];
      final nextLineTs = i + 1 < lyrics.length ? lyrics[i + 1].timestamp : jukebox.duration;

      if (position >= line.timestamp && position < nextLineTs) {
        currentLine = line;
        if (i + 1 < lyrics.length) nextLine = lyrics[i + 1];
        break;
      }
    }

    if (currentLine == null) return const SizedBox.shrink();

    final t = context.t;
    final highlightColor = jukebox.karaokeHighlightColor ?? t.accent;
    final upcomingColor = jukebox.karaokeUpcomingColor ?? t.textPrimary;
    final nextLineColor = jukebox.karaokeNextLineColor ?? t.textMinimal;
    final fontFamily = jukebox.karaokeFontFamily;
    final fontScale = jukebox.karaokeFontScale;

    if (singleLine) {
      return _KaraokeLine(
        line: currentLine,
        position: position,
        isCurrent: true,
        highlightColor: highlightColor,
        upcomingColor: upcomingColor,
        nextLineColor: nextLineColor,
        fontFamily: fontFamily,
        fontSize: t.fontSize(9) * fontScale,
        compact: true,
      );
    }

    final bottomSafe = preview ? 0.0 : MediaQuery.of(context).padding.bottom;

    return Container(
      padding: preview
          ? const EdgeInsets.fromLTRB(12, 8, 12, 8)
          : EdgeInsets.fromLTRB(32, 16, 32, 16 + bottomSafe),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _KaraokeLine(
            line: currentLine,
            position: position,
            isCurrent: true,
            highlightColor: highlightColor,
            upcomingColor: upcomingColor,
            nextLineColor: nextLineColor,
            fontFamily: fontFamily,
            fontSize: t.fontSize(preview ? 13 : 22) * fontScale,
            maxLines: preview ? 4 : 2,
          ),
          if (nextLine != null) ...[
            const SizedBox(height: 8),
            _KaraokeLine(
              line: nextLine,
              position: position,
              isCurrent: false,
              highlightColor: highlightColor,
              upcomingColor: upcomingColor,
              nextLineColor: nextLineColor,
              fontFamily: fontFamily,
              fontSize: t.fontSize(preview ? 10 : 14) * fontScale,
            ),
          ],
        ],
      ),
    );
  }
}

class _KaraokeLine extends StatelessWidget {
  final LyricLine line;
  final Duration position;
  final bool isCurrent;
  final Color highlightColor;
  final Color upcomingColor;
  final Color nextLineColor;
  final String? fontFamily;
  final double fontSize;
  final bool compact;
  final int? maxLines;

  const _KaraokeLine({
    required this.line,
    required this.position,
    required this.isCurrent,
    required this.highlightColor,
    required this.upcomingColor,
    required this.nextLineColor,
    this.fontFamily,
    required this.fontSize,
    this.compact = false,
    this.maxLines,
  });

  @override
  Widget build(BuildContext context) {
    final color = isCurrent ? upcomingColor : nextLineColor;
    final shadows = isCurrent && !compact
        ? const [
            Shadow(color: Colors.black, blurRadius: 4, offset: Offset(1, 1)),
            Shadow(color: Colors.black, blurRadius: 8, offset: Offset(0, 0)),
          ]
        : null;

    final effectiveMaxLines = maxLines ?? (compact ? 1 : 2);

    if (line.syllables.isEmpty) {
      return Text(
        line.text,
        textAlign: TextAlign.center,
        maxLines: effectiveMaxLines,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: color,
          fontSize: fontSize,
          fontWeight: FontWeight.bold,
          fontFamily: fontFamily,
          letterSpacing: 1,
          shadows: shadows,
        ),
      );
    }

    return RichText(
      textAlign: TextAlign.center,
      maxLines: effectiveMaxLines,
      overflow: TextOverflow.ellipsis,
      text: TextSpan(
        children: line.syllables.map((syllable) {
          final isPast = position >= syllable.timestamp;
          return TextSpan(
            text: syllable.text,
            style: TextStyle(
              color: isCurrent
                  ? (isPast ? highlightColor : upcomingColor)
                  : nextLineColor,
              fontSize: fontSize,
              fontWeight: FontWeight.bold,
              fontFamily: fontFamily,
              letterSpacing: 1,
              shadows: shadows,
            ),
          );
        }).toList(),
      ),
    );
  }
}
