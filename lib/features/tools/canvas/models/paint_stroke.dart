import 'dart:ui';

/// Shape type for a paint stroke.
enum StrokeType { freehand, line, rectangle, circle, fill, text }

/// A single paint or erase stroke on the canvas.
/// Points use normalized 0-1 coordinates (same system as MaskStroke).
class PaintStroke {
  final List<Offset> points;
  final double radius; // normalized 0-1 relative to image width
  final int colorValue; // ARGB int
  final double opacity; // 0.0-1.0, applied per-stroke
  final bool isErase;
  final StrokeType strokeType;
  final bool smooth;
  final String? text;
  final double? fontSize; // normalized 0-1 relative to image height
  final String? fontFamily; // Google Fonts family name (null = default)
  final double? letterSpacing; // normalized relative to image height

  const PaintStroke({
    required this.points,
    required this.radius,
    required this.colorValue,
    this.opacity = 1.0,
    this.isErase = false,
    this.strokeType = StrokeType.freehand,
    this.smooth = false,
    this.text,
    this.fontSize,
    this.fontFamily,
    this.letterSpacing,
  });

  Color get color => Color(colorValue);

  Map<String, dynamic> toJson() => {
        'points': points.map((p) => [p.dx, p.dy]).toList(),
        'radius': radius,
        'colorValue': colorValue,
        'opacity': opacity,
        'isErase': isErase,
        'strokeType': strokeType.name,
        'smooth': smooth,
        if (text != null) 'text': text,
        if (fontSize != null) 'fontSize': fontSize,
        if (fontFamily != null) 'fontFamily': fontFamily,
        if (letterSpacing != null) 'letterSpacing': letterSpacing,
      };

  factory PaintStroke.fromJson(Map<String, dynamic> json) {
    return PaintStroke(
      points: (json['points'] as List)
          .map((p) => Offset((p as List)[0] as double, p[1] as double))
          .toList(),
      radius: (json['radius'] as num).toDouble(),
      colorValue: json['colorValue'] as int,
      opacity: (json['opacity'] as num?)?.toDouble() ?? 1.0,
      isErase: json['isErase'] as bool? ?? false,
      strokeType: StrokeType.values.firstWhere(
        (e) => e.name == json['strokeType'],
        orElse: () => StrokeType.freehand,
      ),
      smooth: json['smooth'] as bool? ?? false,
      text: json['text'] as String?,
      fontSize: (json['fontSize'] as num?)?.toDouble(),
      fontFamily: json['fontFamily'] as String?,
      letterSpacing: (json['letterSpacing'] as num?)?.toDouble(),
    );
  }
}
