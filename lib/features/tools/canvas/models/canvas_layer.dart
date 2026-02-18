import 'dart:ui';

import 'paint_stroke.dart';

/// Blend modes available for canvas layers.
enum CanvasBlendMode {
  normal,
  multiply,
  screen,
  overlay,
  darken,
  lighten;

  BlendMode toFlutterBlendMode() => switch (this) {
        normal => BlendMode.srcOver,
        multiply => BlendMode.multiply,
        screen => BlendMode.screen,
        overlay => BlendMode.overlay,
        darken => BlendMode.darken,
        lighten => BlendMode.lighten,
      };

  String label() => name[0].toUpperCase() + name.substring(1);
}

/// A single layer in the canvas editor.
/// Each layer holds its own strokes and has independent visibility, opacity, and blend mode.
class CanvasLayer {
  final String id;
  final String name;
  final List<PaintStroke> strokes;
  final bool visible;
  final double opacity;
  final CanvasBlendMode blendMode;

  const CanvasLayer({
    required this.id,
    required this.name,
    this.strokes = const [],
    this.visible = true,
    this.opacity = 1.0,
    this.blendMode = CanvasBlendMode.normal,
  });

  CanvasLayer copyWith({
    String? id,
    String? name,
    List<PaintStroke>? strokes,
    bool? visible,
    double? opacity,
    CanvasBlendMode? blendMode,
  }) {
    return CanvasLayer(
      id: id ?? this.id,
      name: name ?? this.name,
      strokes: strokes ?? this.strokes,
      visible: visible ?? this.visible,
      opacity: opacity ?? this.opacity,
      blendMode: blendMode ?? this.blendMode,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'visible': visible,
        'opacity': opacity,
        'blendMode': blendMode.name,
        'strokes': strokes.map((s) => s.toJson()).toList(),
      };

  factory CanvasLayer.fromJson(Map<String, dynamic> json) {
    return CanvasLayer(
      id: json['id'] as String,
      name: json['name'] as String,
      visible: json['visible'] as bool? ?? true,
      opacity: (json['opacity'] as num?)?.toDouble() ?? 1.0,
      blendMode: CanvasBlendMode.values.firstWhere(
        (m) => m.name == json['blendMode'],
        orElse: () => CanvasBlendMode.normal,
      ),
      strokes: (json['strokes'] as List?)
              ?.map((j) => PaintStroke.fromJson(j as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}
