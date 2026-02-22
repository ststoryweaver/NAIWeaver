import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/jukebox_song.dart';
import '../providers/jukebox_notifier.dart';
import '../../theme/theme_extensions.dart';

class _Particle {
  Offset position;
  double radius;
  double opacity;
  double velocity;
  double angle;
  Color color;

  _Particle({
    required this.position,
    required this.radius,
    required this.opacity,
    required this.velocity,
    required this.angle,
    required this.color,
  });
}

/// Lightweight particle/glow visualizer driven by MIDI note activity.
class KaraokeVisualizer extends StatefulWidget {
  const KaraokeVisualizer({super.key});

  @override
  State<KaraokeVisualizer> createState() => _KaraokeVisualizerState();
}

class _KaraokeVisualizerState extends State<KaraokeVisualizer>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<_Particle> _particles = [];
  final Random _rng = Random();
  Color _accentColor = Colors.white;

  // Shared state for non-particle painters
  double _time = 0.0;
  final List<_Ring> _rings = [];
  final List<_Star> _stars = [];
  // Bar heights (smooth decay)
  final List<double> _barHeights = List.filled(24, 0.0);

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..addListener(_tick);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _tick() {
    final jukebox = context.read<JukeboxNotifier>();
    final activity = jukebox.noteActivity;
    final style = jukebox.visualizerStyle;
    final intensity = jukebox.vizIntensity;
    final speed = jukebox.vizSpeed;
    final density = jukebox.vizDensity;

    _time += 0.016 * (0.5 + speed);

    switch (style) {
      case VisualizerStyle.particles:
        _tickParticles(activity, intensity, speed, density);
      case VisualizerStyle.bars:
        _tickBars(activity, intensity, speed, density);
      case VisualizerStyle.rings:
        _tickRings(activity, intensity, speed, density);
      case VisualizerStyle.wave:
        // Wave is fully stateless — computed in painter
        break;
      case VisualizerStyle.starfield:
        _tickStarfield(activity, intensity, speed, density);
      case VisualizerStyle.plasma:
        // Plasma is fully stateless — computed in painter
        break;
    }

    setState(() {});
  }

  void _tickParticles(double activity, double intensity, double speed, double density) {
    final maxP = (15 + density * 30).round();
    if (activity > 0.1 && _particles.length < maxP) {
      final count = (activity * intensity * 4).ceil().clamp(0, 4);
      for (int i = 0; i < count && _particles.length < maxP; i++) {
        _spawnParticle(activity, intensity);
      }
    }
    for (final p in _particles) {
      p.position = Offset(
        p.position.dx + cos(p.angle) * p.velocity * (0.5 + speed),
        p.position.dy + sin(p.angle) * p.velocity * (0.5 + speed),
      );
      p.opacity -= 0.008 + speed * 0.008;
      p.radius += 0.1;
    }
    _particles.removeWhere((p) => p.opacity <= 0);
  }

  void _spawnParticle(double activity, double intensity) {
    final size = context.size;
    if (size == null) return;
    final cx = size.width / 2;
    final cy = size.height / 2;
    final offsetX = (_rng.nextDouble() - 0.5) * size.width * 0.6;
    final offsetY = (_rng.nextDouble() - 0.5) * size.height * 0.4;
    _particles.add(_Particle(
      position: Offset(cx + offsetX, cy + offsetY),
      radius: 2 + _rng.nextDouble() * 4,
      opacity: (0.3 + _rng.nextDouble() * 0.4) * intensity,
      velocity: 0.3 + _rng.nextDouble() * 0.7,
      angle: _rng.nextDouble() * 2 * pi,
      color: _accentColor,
    ));
  }

  void _tickBars(double activity, double intensity, double speed, double density) {
    final barCount = (8 + density * 16).round();
    while (_barHeights.length < barCount) {
      _barHeights.add(0.0);
    }
    for (int i = 0; i < _barHeights.length; i++) {
      if (i < barCount && activity > 0.05) {
        final target = activity * intensity * (0.5 + _rng.nextDouble() * 0.5);
        _barHeights[i] = _barHeights[i] + (target - _barHeights[i]) * (0.3 + speed * 0.4);
      } else {
        _barHeights[i] *= 0.85 - speed * 0.1;
      }
    }
  }

  void _tickRings(double activity, double intensity, double speed, double density) {
    final maxRings = (3 + density * 8).round();
    if (activity > 0.2 && _rings.length < maxRings) {
      if (_rings.isEmpty || _rings.last.radius > 20) {
        _rings.add(_Ring(radius: 0, opacity: activity * intensity));
      }
    }
    for (final r in _rings) {
      r.radius += 1.5 + speed * 3;
      r.opacity -= 0.008 + speed * 0.006;
    }
    _rings.removeWhere((r) => r.opacity <= 0);
  }

  void _tickStarfield(double activity, double intensity, double speed, double density) {
    final maxStars = (20 + density * 60).round();
    if (_stars.length < maxStars) {
      final spawnCount = (1 + activity * density * 3).round();
      for (int i = 0; i < spawnCount && _stars.length < maxStars; i++) {
        _stars.add(_Star(
          angle: _rng.nextDouble() * 2 * pi,
          distance: _rng.nextDouble() * 10,
          speed: 0.5 + _rng.nextDouble() * 1.5,
          brightness: (0.3 + _rng.nextDouble() * 0.7) * intensity,
          size: 1 + _rng.nextDouble() * 2,
        ));
      }
    }
    for (final s in _stars) {
      s.distance += s.speed * (0.5 + speed) * (1 + activity * intensity * 2);
    }
    _stars.removeWhere((s) => s.distance > 500);
  }

  @override
  Widget build(BuildContext context) {
    final jukebox = context.watch<JukeboxNotifier>();
    final accent = jukebox.visualizerColor ?? context.t.accent;
    _accentColor = accent;

    final isActive = jukebox.isPlaying && jukebox.currentSong != null;

    if (isActive && !_controller.isAnimating) {
      _controller.repeat();
    } else if (!isActive && _controller.isAnimating) {
      _controller.stop();
      _particles.clear();
      _rings.clear();
      _stars.clear();
    }

    final style = jukebox.visualizerStyle;
    final activity = jukebox.noteActivity;
    final intensity = jukebox.vizIntensity;
    final speed = jukebox.vizSpeed;
    final density = jukebox.vizDensity;

    final CustomPainter painter;
    switch (style) {
      case VisualizerStyle.particles:
        painter = _ParticleVisualizerPainter(
          particles: _particles,
          noteActivity: activity,
          accentColor: accent,
          intensity: intensity,
        );
      case VisualizerStyle.bars:
        painter = _BarVisualizerPainter(
          barHeights: _barHeights,
          barCount: (8 + density * 16).round(),
          accentColor: accent,
          intensity: intensity,
        );
      case VisualizerStyle.rings:
        painter = _RingVisualizerPainter(
          rings: _rings,
          accentColor: accent,
          intensity: intensity,
        );
      case VisualizerStyle.wave:
        painter = _WaveVisualizerPainter(
          time: _time,
          noteActivity: activity,
          accentColor: accent,
          intensity: intensity,
          speed: speed,
          density: density,
        );
      case VisualizerStyle.starfield:
        painter = _StarfieldVisualizerPainter(
          stars: _stars,
          accentColor: accent,
          intensity: intensity,
        );
      case VisualizerStyle.plasma:
        painter = _PlasmaVisualizerPainter(
          time: _time,
          noteActivity: activity,
          accentColor: accent,
          intensity: intensity,
          density: density,
        );
    }

    return CustomPaint(
      painter: painter,
      size: Size.infinite,
    );
  }
}

// ─────────────────────────────────────────
// Helper models
// ─────────────────────────────────────────

class _Ring {
  double radius;
  double opacity;
  _Ring({required this.radius, required this.opacity});
}

class _Star {
  final double angle;
  double distance;
  final double speed;
  final double brightness;
  final double size;
  _Star({required this.angle, required this.distance, required this.speed, required this.brightness, required this.size});
}

// ─────────────────────────────────────────
// Particles (original style)
// ─────────────────────────────────────────

class _ParticleVisualizerPainter extends CustomPainter {
  final List<_Particle> particles;
  final double noteActivity;
  final Color accentColor;
  final double intensity;

  _ParticleVisualizerPainter({
    required this.particles,
    required this.noteActivity,
    required this.accentColor,
    required this.intensity,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (noteActivity > 0.01) {
      final center = Offset(size.width / 2, size.height / 2);
      final glowRadius = size.width * 0.4;
      final glowPaint = Paint()
        ..shader = RadialGradient(
          colors: [
            accentColor.withValues(alpha: noteActivity * 0.15 * intensity),
            accentColor.withValues(alpha: 0),
          ],
        ).createShader(Rect.fromCircle(center: center, radius: glowRadius));
      canvas.drawCircle(center, glowRadius, glowPaint);
    }
    for (final p in particles) {
      if (p.opacity <= 0) continue;
      final paint = Paint()
        ..color = p.color.withValues(alpha: p.opacity)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, p.radius * 0.8);
      canvas.drawCircle(p.position, p.radius, paint);
    }
  }

  @override
  bool shouldRepaint(_ParticleVisualizerPainter oldDelegate) => true;
}

// ─────────────────────────────────────────
// Bars
// ─────────────────────────────────────────

class _BarVisualizerPainter extends CustomPainter {
  final List<double> barHeights;
  final int barCount;
  final Color accentColor;
  final double intensity;

  _BarVisualizerPainter({
    required this.barHeights,
    required this.barCount,
    required this.accentColor,
    required this.intensity,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final count = barCount.clamp(1, barHeights.length);
    final gap = 3.0;
    final barWidth = (size.width - gap * (count + 1)) / count;
    if (barWidth <= 0) return;

    for (int i = 0; i < count; i++) {
      final h = barHeights[i] * size.height * 0.8;
      if (h < 1) continue;
      final x = gap + i * (barWidth + gap);
      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(x, size.height - h, barWidth, h),
        const Radius.circular(2),
      );
      final paint = Paint()
        ..color = accentColor.withValues(alpha: 0.3 + barHeights[i] * 0.7 * intensity);
      canvas.drawRRect(rect, paint);

      // Glow cap
      final capPaint = Paint()
        ..color = accentColor.withValues(alpha: barHeights[i] * intensity)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
      canvas.drawRect(
        Rect.fromLTWH(x, size.height - h, barWidth, 3),
        capPaint,
      );
    }
  }

  @override
  bool shouldRepaint(_BarVisualizerPainter oldDelegate) => true;
}

// ─────────────────────────────────────────
// Rings
// ─────────────────────────────────────────

class _RingVisualizerPainter extends CustomPainter {
  final List<_Ring> rings;
  final Color accentColor;
  final double intensity;

  _RingVisualizerPainter({
    required this.rings,
    required this.accentColor,
    required this.intensity,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    for (final r in rings) {
      if (r.opacity <= 0) continue;
      final paint = Paint()
        ..color = accentColor.withValues(alpha: r.opacity * intensity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2 + r.opacity * 3;
      canvas.drawCircle(center, r.radius, paint);
    }
  }

  @override
  bool shouldRepaint(_RingVisualizerPainter oldDelegate) => true;
}

// ─────────────────────────────────────────
// Wave
// ─────────────────────────────────────────

class _WaveVisualizerPainter extends CustomPainter {
  final double time;
  final double noteActivity;
  final Color accentColor;
  final double intensity;
  final double speed;
  final double density;

  _WaveVisualizerPainter({
    required this.time,
    required this.noteActivity,
    required this.accentColor,
    required this.intensity,
    required this.speed,
    required this.density,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final layerCount = (1 + density * 3).round();
    final amplitude = size.height * 0.15 * noteActivity * intensity;
    if (amplitude < 0.5) return;

    for (int l = 0; l < layerCount; l++) {
      final path = Path();
      final phase = time * (1 + l * 0.3) + l * 1.5;
      final freq = 2 + l * 0.7;
      final yOffset = size.height / 2 + (l - layerCount / 2) * 8;
      final alpha = (0.2 + (1 - l / layerCount.toDouble()) * 0.5) * intensity;

      path.moveTo(0, yOffset);
      for (double x = 0; x <= size.width; x += 2) {
        final y = yOffset + sin(x / size.width * pi * freq + phase) * amplitude * (1 - l * 0.15);
        path.lineTo(x, y);
      }

      final paint = Paint()
        ..color = accentColor.withValues(alpha: alpha)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5 - l * 0.3
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(_WaveVisualizerPainter oldDelegate) => true;
}

// ─────────────────────────────────────────
// Starfield
// ─────────────────────────────────────────

class _StarfieldVisualizerPainter extends CustomPainter {
  final List<_Star> stars;
  final Color accentColor;
  final double intensity;

  _StarfieldVisualizerPainter({
    required this.stars,
    required this.accentColor,
    required this.intensity,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final maxDist = size.width * 0.7;

    for (final s in stars) {
      final x = cx + cos(s.angle) * s.distance;
      final y = cy + sin(s.angle) * s.distance;
      if (x < -10 || x > size.width + 10 || y < -10 || y > size.height + 10) continue;

      final progress = (s.distance / maxDist).clamp(0.0, 1.0);
      final r = s.size * (0.5 + progress * 2);
      final alpha = s.brightness * progress * intensity;
      if (alpha < 0.01) continue;

      final paint = Paint()
        ..color = accentColor.withValues(alpha: alpha)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, r * 0.5);
      canvas.drawCircle(Offset(x, y), r, paint);
    }
  }

  @override
  bool shouldRepaint(_StarfieldVisualizerPainter oldDelegate) => true;
}

// ─────────────────────────────────────────
// Plasma
// ─────────────────────────────────────────

class _PlasmaVisualizerPainter extends CustomPainter {
  final double time;
  final double noteActivity;
  final Color accentColor;
  final double intensity;
  final double density;

  _PlasmaVisualizerPainter({
    required this.time,
    required this.noteActivity,
    required this.accentColor,
    required this.intensity,
    required this.density,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final step = (12 - density * 6).round().clamp(4, 16).toDouble();
    final sat = 0.3 + noteActivity * 0.7 * intensity;
    final hslBase = HSLColor.fromColor(accentColor);

    for (double x = 0; x < size.width; x += step) {
      for (double y = 0; y < size.height; y += step) {
        final nx = x / size.width;
        final ny = y / size.height;

        final v = (sin(nx * 6 + time) +
                sin(ny * 4 + time * 0.7) +
                sin((nx + ny) * 5 + time * 1.3) +
                sin(sqrt(nx * nx + ny * ny) * 8 + time * 0.5)) /
            4.0;

        final hueShift = v * 60;
        final hue = (hslBase.hue + hueShift) % 360;
        final color = HSLColor.fromAHSL(
          (0.15 + v.abs() * 0.25) * intensity,
          hue,
          sat,
          0.4 + v * 0.2,
        ).toColor();

        canvas.drawRect(
          Rect.fromLTWH(x, y, step, step),
          Paint()..color = color,
        );
      }
    }
  }

  @override
  bool shouldRepaint(_PlasmaVisualizerPainter oldDelegate) => true;
}
