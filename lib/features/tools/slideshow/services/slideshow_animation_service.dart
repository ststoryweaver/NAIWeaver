import 'dart:math';
import 'package:flutter/material.dart';
import '../models/slideshow_config.dart';

class KenBurnsAnimation {
  final Offset startOffset;
  final Offset endOffset;
  final double startScale;
  final double endScale;

  const KenBurnsAnimation({
    required this.startOffset,
    required this.endOffset,
    required this.startScale,
    required this.endScale,
  });

  /// Generates a random Ken Burns animation that keeps the image in frame.
  /// [intensity] ranges from 0.0 (subtle) to 1.0 (dramatic).
  factory KenBurnsAnimation.random(double intensity) {
    final rng = Random();
    final maxScale = 1.0 + intensity * 0.3;
    final s1 = 1.0 + rng.nextDouble() * (maxScale - 1.0);
    final s2 = 1.0 + rng.nextDouble() * (maxScale - 1.0);

    // Max offset so image never shows empty space:
    // offset range = (scale - 1) / 2 of the normalised 0..1 range
    double clampedOffset(double scale) {
      final maxOff = (scale - 1.0) / (2.0 * scale);
      return (rng.nextDouble() * 2 - 1) * maxOff;
    }

    return KenBurnsAnimation(
      startOffset: Offset(clampedOffset(s1), clampedOffset(s1)),
      endOffset: Offset(clampedOffset(s2), clampedOffset(s2)),
      startScale: s1,
      endScale: s2,
    );
  }

  /// Interpolate at progress t ∈ [0,1].
  double scaleAt(double t) => startScale + (endScale - startScale) * t;
  Offset offsetAt(double t) => Offset(
        startOffset.dx + (endOffset.dx - startOffset.dx) * t,
        startOffset.dy + (endOffset.dy - startOffset.dy) * t,
      );
}

class SlideshowAnimationService {
  /// Returns a transitionBuilder for [AnimatedSwitcher].
  static AnimatedSwitcherTransitionBuilder getTransitionBuilder(
      TransitionType type) {
    switch (type) {
      case TransitionType.fade:
        return (child, animation) => FadeTransition(
              opacity: animation,
              child: child,
            );
      case TransitionType.slideLeft:
        return (child, animation) {
          final offset =
              Tween<Offset>(begin: const Offset(1, 0), end: Offset.zero)
                  .animate(animation);
          return SlideTransition(position: offset, child: child);
        };
      case TransitionType.slideRight:
        return (child, animation) {
          final offset =
              Tween<Offset>(begin: const Offset(-1, 0), end: Offset.zero)
                  .animate(animation);
          return SlideTransition(position: offset, child: child);
        };
      case TransitionType.slideUp:
        return (child, animation) {
          final offset =
              Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero)
                  .animate(animation);
          return SlideTransition(position: offset, child: child);
        };
      case TransitionType.zoom:
        return (child, animation) => ScaleTransition(
              scale: animation,
              child: child,
            );
      case TransitionType.crossZoom:
        return (child, animation) => FadeTransition(
              opacity: animation,
              child: ScaleTransition(
                scale: Tween<double>(begin: 0.9, end: 1.0).animate(animation),
                child: child,
              ),
            );
    }
  }
}
