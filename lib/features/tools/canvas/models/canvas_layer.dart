import 'dart:typed_data';
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
/// Optionally holds an image (for image layers imported from gallery/segmentation).
class CanvasLayer {
  final String id;
  final String name;
  final List<PaintStroke> strokes;
  final bool visible;
  final double opacity;
  final CanvasBlendMode blendMode;

  // Image layer fields (null = stroke-only layer)
  final Uint8List? imageBytes;
  final double imageX; // normalized 0-1
  final double imageY;
  final double imageScale; // 1.0 = fits canvas width
  final double imageRotation; // radians

  bool get isImageLayer => imageBytes != null;

  const CanvasLayer({
    required this.id,
    required this.name,
    this.strokes = const [],
    this.visible = true,
    this.opacity = 1.0,
    this.blendMode = CanvasBlendMode.normal,
    this.imageBytes,
    this.imageX = 0.0,
    this.imageY = 0.0,
    this.imageScale = 1.0,
    this.imageRotation = 0.0,
  });

  CanvasLayer copyWith({
    String? id,
    String? name,
    List<PaintStroke>? strokes,
    bool? visible,
    double? opacity,
    CanvasBlendMode? blendMode,
    Uint8List? imageBytes,
    double? imageX,
    double? imageY,
    double? imageScale,
    double? imageRotation,
  }) {
    return CanvasLayer(
      id: id ?? this.id,
      name: name ?? this.name,
      strokes: strokes ?? this.strokes,
      visible: visible ?? this.visible,
      opacity: opacity ?? this.opacity,
      blendMode: blendMode ?? this.blendMode,
      imageBytes: imageBytes ?? this.imageBytes,
      imageX: imageX ?? this.imageX,
      imageY: imageY ?? this.imageY,
      imageScale: imageScale ?? this.imageScale,
      imageRotation: imageRotation ?? this.imageRotation,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'visible': visible,
        'opacity': opacity,
        'blendMode': blendMode.name,
        'strokes': strokes.map((s) => s.toJson()).toList(),
        'hasImage': isImageLayer,
        'imageX': imageX,
        'imageY': imageY,
        'imageScale': imageScale,
        'imageRotation': imageRotation,
      };

  factory CanvasLayer.fromJson(Map<String, dynamic> json, {Uint8List? imageBytes}) {
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
      imageBytes: imageBytes,
      imageX: (json['imageX'] as num?)?.toDouble() ?? 0.0,
      imageY: (json['imageY'] as num?)?.toDouble() ?? 0.0,
      imageScale: (json['imageScale'] as num?)?.toDouble() ?? 1.0,
      imageRotation: (json['imageRotation'] as num?)?.toDouble() ?? 0.0,
    );
  }
}
