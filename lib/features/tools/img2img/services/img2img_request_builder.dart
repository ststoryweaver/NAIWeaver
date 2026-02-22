import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import '../models/img2img_session.dart';
import 'mask_encoder.dart';

/// The assembled request ready for GenerationNotifier.generateImg2Img().
class Img2ImgRequest {
  final String prompt;
  final String negativePrompt;
  final int width;
  final int height;
  final double scale;
  final int steps;
  final String sampler;
  final String sourceImageBase64;
  final String? maskBase64;
  final double strength;
  final double noise;
  final bool colorCorrect;
  final int maskBlur;

  Img2ImgRequest({
    required this.prompt,
    required this.negativePrompt,
    required this.width,
    required this.height,
    required this.scale,
    required this.steps,
    required this.sampler,
    required this.sourceImageBase64,
    this.maskBase64,
    required this.strength,
    required this.noise,
    required this.colorCorrect,
    required this.maskBlur,
  });
}

class Img2ImgRequestBuilder {
  /// Builds a complete [Img2ImgRequest] from session state and generation params.
  static Future<Img2ImgRequest> build({
    required Img2ImgSession session,
    required int targetWidth,
    required int targetHeight,
    double scale = 5.0,
    int steps = 28,
    String sampler = 'k_euler_ancestral',
  }) async {
    // Resize source image to target resolution and encode as base64
    final sourceBase64 = await compute(_resizeAndEncode, _ResizeParams(
      bytes: session.sourceImageBytes,
      width: targetWidth,
      height: targetHeight,
    ));

    // Render mask if strokes exist
    String? maskBase64;
    if (session.hasMask) {
      maskBase64 = await MaskEncoder.renderMaskBase64(
        strokes: session.maskStrokes,
        width: targetWidth,
        height: targetHeight,
      );
      // Save debug mask in debug mode only
      if (kDebugMode) {
        try {
          await MaskEncoder.debugSaveMask(maskBase64, 'output/_debug_mask.png');
        } catch (e) {
          debugPrint('Img2ImgRequestBuilder.build: $e');
        }
      }
    }

    return Img2ImgRequest(
      prompt: session.prompt,
      negativePrompt: session.negativePrompt,
      width: targetWidth,
      height: targetHeight,
      scale: scale,
      steps: steps,
      sampler: sampler,
      sourceImageBase64: sourceBase64,
      maskBase64: maskBase64,
      strength: session.settings.strength,
      noise: session.settings.noise,
      colorCorrect: session.settings.colorCorrect,
      maskBlur: session.settings.maskBlur,
    );
  }
}

class _ResizeParams {
  final Uint8List bytes;
  final int width;
  final int height;

  _ResizeParams({required this.bytes, required this.width, required this.height});
}

String _resizeAndEncode(_ResizeParams params) {
  final decoded = img.decodeImage(params.bytes);
  if (decoded == null) throw Exception('Failed to decode source image');

  final resized = img.copyResize(decoded, width: params.width, height: params.height);
  final rgb = resized.convert(numChannels: 3);
  final pngBytes = img.encodePng(rgb);
  return base64Encode(pngBytes);
}
