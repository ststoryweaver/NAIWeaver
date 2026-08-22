import 'package:flutter/material.dart';

/// Grey/white checkerboard used behind images with real alpha (NovelAI V5
/// transparent-background renders) so transparency reads as transparency.
class CheckerboardPainter extends CustomPainter {
  final double cell;
  final Color light;
  final Color dark;

  const CheckerboardPainter({
    this.cell = 12,
    this.light = const Color(0xFFBDBDBD),
    this.dark = const Color(0xFF8A8A8A),
  });

  @override
  void paint(Canvas canvas, Size size) {
    final lightPaint = Paint()..color = light;
    final darkPaint = Paint()..color = dark;
    canvas.drawRect(Offset.zero & size, lightPaint);
    final cols = (size.width / cell).ceil();
    final rows = (size.height / cell).ceil();
    for (var y = 0; y < rows; y++) {
      for (var x = 0; x < cols; x++) {
        if ((x + y).isOdd) {
          canvas.drawRect(
            Rect.fromLTWH(x * cell, y * cell, cell, cell),
            darkPaint,
          );
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant CheckerboardPainter old) =>
      old.cell != cell || old.light != light || old.dark != dark;
}
