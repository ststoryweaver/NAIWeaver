import 'package:flutter/material.dart';
import '../../../core/theme/theme_extensions.dart';
import '../../../core/theme/vision_tokens.dart';
import '../../../core/utils/nai_coordinate_utils.dart';
import '../models/nai_character.dart';

/// Character position picker.
///
/// * V4.5 (`freeform: false`, default): the classic 5×5 grid — NovelAI only
///   honours the standard 0.1 / 0.3 / 0.5 / 0.7 / 0.9 centers.
/// * V5 (`freeform: true`): a free-drag canvas, aspect-matched to the current
///   resolution, storing raw `{x,y}` rounded to 3 dp ("no more tiny grids").
///   Faint 5×5 guide lines are kept so existing muscle memory still works.
class NaiGridSelector extends StatelessWidget {
  final NaiCoordinate selectedCoordinate;
  final ValueChanged<NaiCoordinate> onCoordinateSelected;

  /// Allow arbitrary positions (V5) instead of snapping to the 5×5 grid.
  final bool freeform;

  /// Width / height of the target image; only used in freeform mode so the
  /// canvas matches the output proportions. Must be > 0.
  final double aspectRatio;

  const NaiGridSelector({
    super.key,
    required this.selectedCoordinate,
    required this.onCoordinateSelected,
    this.freeform = false,
    this.aspectRatio = 1,
  });

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    if (freeform) {
      return _FreeformCanvas(
        coordinate: selectedCoordinate,
        aspectRatio: aspectRatio > 0 ? aspectRatio : 1,
        onChanged: onCoordinateSelected,
      );
    }

    // Five rows of five Expanded cells rather than a GridView: the box follows
    // the target aspect ratio, and a non-scrolling GridView with square cells
    // overflowed (clipping the bottom rows) whenever the box was wider than
    // tall. Expanded cells simply share whatever height the box has.
    return AspectRatio(
      aspectRatio: aspectRatio > 0 ? aspectRatio : 1,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          border: Border.all(color: t.borderStrong),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            for (int row = 0; row < 5; row++) ...[
              if (row > 0) const SizedBox(height: 4),
              Expanded(
                child: Row(
                  children: [
                    for (int col = 0; col < 5; col++) ...[
                      if (col > 0) const SizedBox(width: 4),
                      Expanded(child: _cell(t, row * 5 + col)),
                    ],
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _cell(VisionTokens t, int index) {
    final coord = NaiCoordinateUtils.getCoordinateFromIndex(index);
    final isSelected =
        coord.x == selectedCoordinate.x && coord.y == selectedCoordinate.y;
    return InkWell(
      onTap: () => onCoordinateSelected(coord),
      borderRadius: BorderRadius.circular(4),
      child: Container(
        decoration: BoxDecoration(
          color: isSelected ? t.accent : t.textMinimal,
          borderRadius: BorderRadius.circular(4),
          border: isSelected ? null : Border.all(color: t.textMinimal),
        ),
      ),
    );
  }
}

class _FreeformCanvas extends StatelessWidget {
  final NaiCoordinate coordinate;
  final double aspectRatio;
  final ValueChanged<NaiCoordinate> onChanged;

  const _FreeformCanvas({
    required this.coordinate,
    required this.aspectRatio,
    required this.onChanged,
  });

  static double _round3(double v) => (v * 1000).round() / 1000;

  void _emit(Offset local, Size size) {
    if (size.width <= 0 || size.height <= 0) return;
    final x = (local.dx / size.width).clamp(0.0, 1.0);
    final y = (local.dy / size.height).clamp(0.0, 1.0);
    onChanged(NaiCoordinate(x: _round3(x), y: _round3(y)));
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    return AspectRatio(
      aspectRatio: aspectRatio,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final size = Size(constraints.maxWidth, constraints.maxHeight);
          return GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapDown: (d) => _emit(d.localPosition, size),
            onPanStart: (d) => _emit(d.localPosition, size),
            onPanUpdate: (d) => _emit(d.localPosition, size),
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(color: t.borderStrong),
                borderRadius: BorderRadius.circular(8),
                color: t.textMinimal.withValues(alpha: 0.35),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(7),
                child: CustomPaint(
                  painter: _FreeformPainter(
                    coordinate: coordinate,
                    guideColor: t.textMinimal,
                    dotColor: t.accent,
                  ),
                  child: Align(
                    alignment: Alignment.bottomRight,
                    child: Padding(
                      padding: const EdgeInsets.all(3),
                      child: Text(
                        '${coordinate.x.toStringAsFixed(2)}, ${coordinate.y.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: t.fontSize(7),
                          color: t.textDisabled,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _FreeformPainter extends CustomPainter {
  final NaiCoordinate coordinate;
  final Color guideColor;
  final Color dotColor;

  const _FreeformPainter({
    required this.coordinate,
    required this.guideColor,
    required this.dotColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final guide = Paint()
      ..color = guideColor
      ..strokeWidth = 1;
    for (var i = 1; i < 5; i++) {
      final dx = size.width * i / 5;
      final dy = size.height * i / 5;
      canvas.drawLine(Offset(dx, 0), Offset(dx, size.height), guide);
      canvas.drawLine(Offset(0, dy), Offset(size.width, dy), guide);
    }
    final center = Offset(
      coordinate.x.clamp(0.0, 1.0) * size.width,
      coordinate.y.clamp(0.0, 1.0) * size.height,
    );
    canvas.drawCircle(
      center,
      9,
      Paint()..color = dotColor.withValues(alpha: 0.25),
    );
    canvas.drawCircle(center, 5, Paint()..color = dotColor);
  }

  @override
  bool shouldRepaint(covariant _FreeformPainter old) =>
      old.coordinate.x != coordinate.x ||
      old.coordinate.y != coordinate.y ||
      old.dotColor != dotColor ||
      old.guideColor != guideColor;
}
