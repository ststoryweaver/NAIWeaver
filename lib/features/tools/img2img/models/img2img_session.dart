import 'dart:typed_data';
import 'dart:ui';

/// A single brush stroke on the mask canvas.
class MaskStroke {
  /// Points in normalized 0-1 coordinates relative to the image.
  final List<Offset> points;

  /// Brush radius in normalized 0-1 coordinates.
  final double radius;

  /// Whether this stroke paints (white = regenerate) or erases (black = preserve).
  final bool isErase;

  const MaskStroke({
    required this.points,
    required this.radius,
    this.isErase = false,
  });
}

/// Settings for the img2img / inpainting request.
class Img2ImgSettings {
  final double strength;
  final double noise;
  final bool colorCorrect;
  final int maskBlur;

  const Img2ImgSettings({
    this.strength = 1.0,
    this.noise = 0.0,
    this.colorCorrect = true,
    this.maskBlur = 0,
  });

  Img2ImgSettings copyWith({
    double? strength,
    double? noise,
    bool? colorCorrect,
    int? maskBlur,
  }) {
    return Img2ImgSettings(
      strength: strength ?? this.strength,
      noise: noise ?? this.noise,
      colorCorrect: colorCorrect ?? this.colorCorrect,
      maskBlur: maskBlur ?? this.maskBlur,
    );
  }
}

/// The full editing session state.
class Img2ImgSession {
  final Uint8List sourceImageBytes;
  final int sourceWidth;
  final int sourceHeight;
  final List<MaskStroke> maskStrokes;
  final Img2ImgSettings settings;
  final String prompt;
  final String negativePrompt;
  final Uint8List? resultImageBytes;
  final String? sourceFilePath;

  const Img2ImgSession({
    required this.sourceImageBytes,
    required this.sourceWidth,
    required this.sourceHeight,
    this.maskStrokes = const [],
    this.settings = const Img2ImgSettings(),
    this.prompt = '',
    this.negativePrompt = '',
    this.resultImageBytes,
    this.sourceFilePath,
  });

  Img2ImgSession copyWith({
    Uint8List? sourceImageBytes,
    int? sourceWidth,
    int? sourceHeight,
    List<MaskStroke>? maskStrokes,
    Img2ImgSettings? settings,
    String? prompt,
    String? negativePrompt,
    Uint8List? resultImageBytes,
    bool clearResult = false,
    String? sourceFilePath,
    bool clearSourceFilePath = false,
  }) {
    return Img2ImgSession(
      sourceImageBytes: sourceImageBytes ?? this.sourceImageBytes,
      sourceWidth: sourceWidth ?? this.sourceWidth,
      sourceHeight: sourceHeight ?? this.sourceHeight,
      maskStrokes: maskStrokes ?? this.maskStrokes,
      settings: settings ?? this.settings,
      prompt: prompt ?? this.prompt,
      negativePrompt: negativePrompt ?? this.negativePrompt,
      resultImageBytes: clearResult ? null : (resultImageBytes ?? this.resultImageBytes),
      sourceFilePath: clearSourceFilePath ? null : (sourceFilePath ?? this.sourceFilePath),
    );
  }

  bool get hasMask => maskStrokes.isNotEmpty;
}
