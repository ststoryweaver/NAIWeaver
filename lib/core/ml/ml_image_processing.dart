import 'dart:math';
import 'dart:typed_data';
import 'package:image/image.dart' as img;
import 'ml_model_entry.dart';

// All functions are top-level for compute() isolate safety.
// No platform channels — pure Dart + image package only.

// --- Parameter classes (must be serializable for compute()) ---

class PreprocessParams {
  final Uint8List imageBytes;
  final int targetWidth;
  final int targetHeight;
  final int channels;
  final MLNormalization normalization;

  const PreprocessParams({
    required this.imageBytes,
    required this.targetWidth,
    required this.targetHeight,
    this.channels = 3,
    this.normalization = MLNormalization.zeroToOne,
  });
}

class PreprocessResult {
  final Float32List data;
  final List<int> shape;
  final int originalWidth;
  final int originalHeight;

  const PreprocessResult({
    required this.data,
    required this.shape,
    required this.originalWidth,
    required this.originalHeight,
  });
}

class MaskParams {
  final Float32List rawOutput;
  final List<int> outputShape;
  final int originalWidth;
  final int originalHeight;

  const MaskParams({
    required this.rawOutput,
    required this.outputShape,
    required this.originalWidth,
    required this.originalHeight,
  });
}

class ApplyMaskParams {
  final Uint8List originalImageBytes;
  final Uint8List maskBytes;
  final double threshold;
  final int featherRadius;

  const ApplyMaskParams({
    required this.originalImageBytes,
    required this.maskBytes,
    this.threshold = 0.5,
    this.featherRadius = 0,
  });
}

class TensorToPngParams {
  final Float32List data;
  final List<int> shape;
  final MLNormalization normalization;

  const TensorToPngParams({
    required this.data,
    required this.shape,
    this.normalization = MLNormalization.zeroToOne,
  });
}

class TileParams {
  final Uint8List imageBytes;
  final int tileSize;
  final int overlap;
  final int channels;
  final MLNormalization normalization;

  const TileParams({
    required this.imageBytes,
    this.tileSize = 256,
    this.overlap = 16,
    this.channels = 3,
    this.normalization = MLNormalization.zeroToOne,
  });
}

class TileInfo {
  final Float32List data;
  final List<int> shape;
  final int x;
  final int y;
  final int width;
  final int height;

  const TileInfo({
    required this.data,
    required this.shape,
    required this.x,
    required this.y,
    required this.width,
    required this.height,
  });
}

class TileResult {
  final List<TileInfo> tiles;
  final int imageWidth;
  final int imageHeight;
  final int tileSize;
  final int overlap;

  const TileResult({
    required this.tiles,
    required this.imageWidth,
    required this.imageHeight,
    required this.tileSize,
    required this.overlap,
  });
}

class StitchParams {
  final List<StitchTileData> tiles;
  final int imageWidth;
  final int imageHeight;
  final int scaleFactor;
  final int tileSize;
  final int overlap;
  final MLNormalization normalization;

  const StitchParams({
    required this.tiles,
    required this.imageWidth,
    required this.imageHeight,
    required this.scaleFactor,
    required this.tileSize,
    required this.overlap,
    this.normalization = MLNormalization.zeroToOne,
  });
}

class StitchTileData {
  final Float32List data;
  final List<int> shape;
  final int x;
  final int y;
  final int width;
  final int height;

  const StitchTileData({
    required this.data,
    required this.shape,
    required this.x,
    required this.y,
    required this.width,
    required this.height,
  });
}

// --- Preprocessing ---

PreprocessResult preprocessImage(PreprocessParams params) {
  final decoded = img.decodeImage(params.imageBytes);
  if (decoded == null) {
    throw Exception('Failed to decode image');
  }

  final originalWidth = decoded.width;
  final originalHeight = decoded.height;

  // Resize to target dimensions
  final resized = img.copyResize(
    decoded,
    width: params.targetWidth,
    height: params.targetHeight,
    interpolation: img.Interpolation.linear,
  );

  // Convert to NCHW Float32List
  final h = params.targetHeight;
  final w = params.targetWidth;
  final c = params.channels;
  final data = Float32List(1 * c * h * w);

  for (int y = 0; y < h; y++) {
    for (int x = 0; x < w; x++) {
      final pixel = resized.getPixel(x, y);
      final r = pixel.r.toDouble();
      final g = pixel.g.toDouble();
      final b = pixel.b.toDouble();

      final idx = y * w + x;

      switch (params.normalization) {
        case MLNormalization.zeroToOne:
          data[0 * h * w + idx] = r / 255.0;
          if (c > 1) data[1 * h * w + idx] = g / 255.0;
          if (c > 2) data[2 * h * w + idx] = b / 255.0;
        case MLNormalization.negOneToOne:
          data[0 * h * w + idx] = r / 127.5 - 1.0;
          if (c > 1) data[1 * h * w + idx] = g / 127.5 - 1.0;
          if (c > 2) data[2 * h * w + idx] = b / 127.5 - 1.0;
        case MLNormalization.imageNet:
          data[0 * h * w + idx] = (r / 255.0 - 0.485) / 0.229;
          if (c > 1) data[1 * h * w + idx] = (g / 255.0 - 0.456) / 0.224;
          if (c > 2) data[2 * h * w + idx] = (b / 255.0 - 0.406) / 0.225;
      }
    }
  }

  return PreprocessResult(
    data: data,
    shape: [1, c, h, w],
    originalWidth: originalWidth,
    originalHeight: originalHeight,
  );
}

// --- BG Removal Post-processing ---

Uint8List generateMask(MaskParams params) {
  // Output shape is typically [1, 1, H, W] or [1, H, W]
  final shape = params.outputShape;
  int maskH, maskW;

  if (shape.length == 4) {
    maskH = shape[2];
    maskW = shape[3];
  } else if (shape.length == 3) {
    maskH = shape[1];
    maskW = shape[2];
  } else {
    // Assume square
    final side = sqrt(params.rawOutput.length).round();
    maskH = side;
    maskW = side;
  }

  // Apply sigmoid if values suggest logits (outside 0-1 range)
  final needsSigmoid = params.rawOutput.any((v) => v < -0.5 || v > 1.5);

  // Create grayscale mask image at model output size
  final mask = img.Image(width: maskW, height: maskH, numChannels: 1);
  for (int y = 0; y < maskH; y++) {
    for (int x = 0; x < maskW; x++) {
      double val = params.rawOutput[y * maskW + x];
      if (needsSigmoid) {
        val = 1.0 / (1.0 + exp(-val));
      }
      val = val.clamp(0.0, 1.0);
      final byte = (val * 255).round();
      mask.setPixelR(x, y, byte);
    }
  }

  // Resize to original dimensions
  final resized = img.copyResize(
    mask,
    width: params.originalWidth,
    height: params.originalHeight,
    interpolation: img.Interpolation.linear,
  );

  return Uint8List.fromList(img.encodePng(resized));
}

// --- Alpha Matte Generation (continuous 0-255, no binary threshold) ---

Uint8List generateAlphaMatte(MaskParams params) {
  final shape = params.outputShape;
  int maskH, maskW;

  if (shape.length == 4) {
    maskH = shape[2];
    maskW = shape[3];
  } else if (shape.length == 3) {
    maskH = shape[1];
    maskW = shape[2];
  } else {
    final side = sqrt(params.rawOutput.length).round();
    maskH = side;
    maskW = side;
  }

  final needsSigmoid = params.rawOutput.any((v) => v < -0.5 || v > 1.5);

  final mask = img.Image(width: maskW, height: maskH, numChannels: 1);
  for (int y = 0; y < maskH; y++) {
    for (int x = 0; x < maskW; x++) {
      double val = params.rawOutput[y * maskW + x];
      if (needsSigmoid) {
        val = 1.0 / (1.0 + exp(-val));
      }
      val = val.clamp(0.0, 1.0);
      mask.setPixelR(x, y, (val * 255).round());
    }
  }

  final resized = img.copyResize(
    mask,
    width: params.originalWidth,
    height: params.originalHeight,
    interpolation: img.Interpolation.linear,
  );

  return Uint8List.fromList(img.encodePng(resized));
}

class ApplyMatteParams {
  final Uint8List originalImageBytes;
  final Uint8List matteBytes;
  final double opacityMultiplier;
  final int edgeRefinementRadius;

  const ApplyMatteParams({
    required this.originalImageBytes,
    required this.matteBytes,
    this.opacityMultiplier = 1.0,
    this.edgeRefinementRadius = 0,
  });
}

Uint8List applyAlphaMatteToImage(ApplyMatteParams params) {
  final original = img.decodeImage(params.originalImageBytes);
  final matte = img.decodeImage(params.matteBytes);
  if (original == null || matte == null) {
    throw Exception('Failed to decode image or matte');
  }

  final w = original.width;
  final h = original.height;

  final resizedMatte = (matte.width != w || matte.height != h)
      ? img.copyResize(matte, width: w, height: h, interpolation: img.Interpolation.linear)
      : matte;

  // Apply edge refinement (Gaussian blur on matte) if requested
  img.Image processedMatte;
  if (params.edgeRefinementRadius > 0) {
    final matteImg = img.Image(width: w, height: h);
    for (int y = 0; y < h; y++) {
      for (int x = 0; x < w; x++) {
        final v = resizedMatte.getPixel(x, y).r.toInt();
        matteImg.setPixelRgba(x, y, v, v, v, 255);
      }
    }
    processedMatte = img.gaussianBlur(matteImg, radius: params.edgeRefinementRadius);
  } else {
    processedMatte = resizedMatte;
  }

  final result = img.Image(width: w, height: h, numChannels: 4);
  for (int y = 0; y < h; y++) {
    for (int x = 0; x < w; x++) {
      final origPixel = original.getPixel(x, y);
      final matteVal = processedMatte.getPixel(x, y).r.toInt();
      final alpha = (matteVal * params.opacityMultiplier).round().clamp(0, 255);
      result.setPixelRgba(x, y, origPixel.r.toInt(), origPixel.g.toInt(), origPixel.b.toInt(), alpha);
    }
  }

  return Uint8List.fromList(img.encodePng(result));
}

Uint8List applyMaskToImage(ApplyMaskParams params) {
  final original = img.decodeImage(params.originalImageBytes);
  final mask = img.decodeImage(params.maskBytes);
  if (original == null || mask == null) {
    throw Exception('Failed to decode image or mask');
  }

  final w = original.width;
  final h = original.height;

  // Resize mask if dimensions don't match
  final resizedMask = (mask.width != w || mask.height != h)
      ? img.copyResize(mask, width: w, height: h, interpolation: img.Interpolation.linear)
      : mask;

  // Apply feather (Gaussian-like box blur on mask) if requested
  img.Image processedMask;
  if (params.featherRadius > 0) {
    // Convert mask to a blurrable image
    final maskImg = img.Image(width: w, height: h);
    for (int y = 0; y < h; y++) {
      for (int x = 0; x < w; x++) {
        final v = resizedMask.getPixel(x, y).r.toInt();
        maskImg.setPixelRgba(x, y, v, v, v, 255);
      }
    }
    processedMask = img.gaussianBlur(maskImg, radius: params.featherRadius);
  } else {
    processedMask = resizedMask;
  }

  // Create RGBA output
  final result = img.Image(width: w, height: h, numChannels: 4);

  final thresholdByte = (params.threshold * 255).round();

  for (int y = 0; y < h; y++) {
    for (int x = 0; x < w; x++) {
      final origPixel = original.getPixel(x, y);
      final maskVal = processedMask.getPixel(x, y).r.toInt();

      // Alpha from mask: above threshold = opaque, below = transparent
      // With feather, we get smooth edges
      int alpha;
      if (params.featherRadius > 0) {
        // Smooth alpha from feathered mask
        alpha = maskVal;
        if (alpha < thresholdByte ~/ 2) alpha = 0;
      } else {
        alpha = maskVal >= thresholdByte ? 255 : 0;
      }

      result.setPixelRgba(x, y, origPixel.r.toInt(), origPixel.g.toInt(), origPixel.b.toInt(), alpha);
    }
  }

  return Uint8List.fromList(img.encodePng(result));
}

// --- SAM Preprocessing ---

class SAMPreprocessParams {
  final Uint8List imageBytes;
  const SAMPreprocessParams({required this.imageBytes});
}

class SAMPreprocessResult {
  final Float32List data;
  final List<int> shape; // [1, 3, 1024, 1024]
  final int originalWidth;
  final int originalHeight;
  final double scaleFactor;
  final int padX;
  final int padY;

  const SAMPreprocessResult({
    required this.data,
    required this.shape,
    required this.originalWidth,
    required this.originalHeight,
    required this.scaleFactor,
    required this.padX,
    required this.padY,
  });
}

SAMPreprocessResult preprocessForSAM(SAMPreprocessParams params) {
  final decoded = img.decodeImage(params.imageBytes);
  if (decoded == null) throw Exception('Failed to decode image');

  final origW = decoded.width;
  final origH = decoded.height;
  const targetSize = 1024;

  // Resize longest side to 1024, maintain aspect ratio
  final scale = targetSize / max(origW, origH);
  final newW = (origW * scale).round();
  final newH = (origH * scale).round();

  final resized = img.copyResize(
    decoded,
    width: newW,
    height: newH,
    interpolation: img.Interpolation.linear,
  );

  // Pad to 1024x1024
  final padX = targetSize - newW;
  final padY = targetSize - newH;

  // NCHW float32 with ImageNet normalization
  final data = Float32List(1 * 3 * targetSize * targetSize);

  for (int y = 0; y < targetSize; y++) {
    for (int x = 0; x < targetSize; x++) {
      final idx = y * targetSize + x;

      if (x < newW && y < newH) {
        final pixel = resized.getPixel(x, y);
        data[0 * targetSize * targetSize + idx] = (pixel.r.toDouble() / 255.0 - 0.485) / 0.229;
        data[1 * targetSize * targetSize + idx] = (pixel.g.toDouble() / 255.0 - 0.456) / 0.224;
        data[2 * targetSize * targetSize + idx] = (pixel.b.toDouble() / 255.0 - 0.406) / 0.225;
      } else {
        // Zero-pad
        data[0 * targetSize * targetSize + idx] = (0.0 - 0.485) / 0.229;
        data[1 * targetSize * targetSize + idx] = (0.0 - 0.456) / 0.224;
        data[2 * targetSize * targetSize + idx] = (0.0 - 0.406) / 0.225;
      }
    }
  }

  return SAMPreprocessResult(
    data: data,
    shape: [1, 3, targetSize, targetSize],
    originalWidth: origW,
    originalHeight: origH,
    scaleFactor: scale,
    padX: padX,
    padY: padY,
  );
}

class SAMPointTransformParams {
  final List<List<double>> points; // normalized 0-1 [[x, y], ...]
  final int originalWidth;
  final int originalHeight;
  final double scaleFactor;
  final int padX;
  final int padY;

  const SAMPointTransformParams({
    required this.points,
    required this.originalWidth,
    required this.originalHeight,
    required this.scaleFactor,
    required this.padX,
    required this.padY,
  });
}

Float32List transformPointsToSAM(SAMPointTransformParams params) {
  final result = Float32List(params.points.length * 2);
  for (int i = 0; i < params.points.length; i++) {
    final px = params.points[i][0] * params.originalWidth * params.scaleFactor;
    final py = params.points[i][1] * params.originalHeight * params.scaleFactor;
    result[i * 2] = px;
    result[i * 2 + 1] = py;
  }
  return result;
}

class SAMPostprocessParams {
  final Float32List maskLogits;
  final List<int> maskShape; // e.g. [1, 1, 256, 256] or [1, 3, 256, 256]
  final int originalWidth;
  final int originalHeight;
  final double scaleFactor;
  final int padX;
  final int padY;
  final int maskIndex; // which mask to use (0 = best)

  const SAMPostprocessParams({
    required this.maskLogits,
    required this.maskShape,
    required this.originalWidth,
    required this.originalHeight,
    required this.scaleFactor,
    required this.padX,
    required this.padY,
    this.maskIndex = 0,
  });
}

Uint8List postprocessSAMMask(SAMPostprocessParams params) {
  final shape = params.maskShape;
  // Shape: [1, numMasks, H, W]
  final numMasks = shape.length == 4 ? shape[1] : 1;
  final maskH = shape.length == 4 ? shape[2] : shape[1];
  final maskW = shape.length == 4 ? shape[3] : shape[2];

  final idx = params.maskIndex.clamp(0, numMasks - 1);
  final offset = idx * maskH * maskW;

  // Create mask at SAM output resolution
  final mask = img.Image(width: maskW, height: maskH, numChannels: 1);
  for (int y = 0; y < maskH; y++) {
    for (int x = 0; x < maskW; x++) {
      final val = params.maskLogits[offset + y * maskW + x];
      // Sigmoid + threshold at 0.0
      final prob = 1.0 / (1.0 + exp(-val));
      mask.setPixelR(x, y, prob > 0.5 ? 255 : 0);
    }
  }

  // Resize to 1024x1024 first
  final full = img.copyResize(mask, width: 1024, height: 1024,
      interpolation: img.Interpolation.nearest);

  // Crop padding
  final newW = (params.originalWidth * params.scaleFactor).round();
  final newH = (params.originalHeight * params.scaleFactor).round();
  final cropped = img.copyCrop(full, x: 0, y: 0, width: newW, height: newH);

  // Resize to original dims
  final resized = img.copyResize(cropped,
      width: params.originalWidth,
      height: params.originalHeight,
      interpolation: img.Interpolation.nearest);

  return Uint8List.fromList(img.encodePng(resized));
}

class SegCompositeParams {
  final Uint8List originalImageBytes;
  final Uint8List maskBytes;

  const SegCompositeParams({
    required this.originalImageBytes,
    required this.maskBytes,
  });
}

Uint8List compositeSegmentation(SegCompositeParams params) {
  final original = img.decodeImage(params.originalImageBytes);
  final mask = img.decodeImage(params.maskBytes);
  if (original == null || mask == null) {
    throw Exception('Failed to decode image or mask');
  }

  final w = original.width;
  final h = original.height;

  final resizedMask = (mask.width != w || mask.height != h)
      ? img.copyResize(mask, width: w, height: h, interpolation: img.Interpolation.nearest)
      : mask;

  final result = img.Image(width: w, height: h, numChannels: 4);
  for (int y = 0; y < h; y++) {
    for (int x = 0; x < w; x++) {
      final origPixel = original.getPixel(x, y);
      final maskVal = resizedMask.getPixel(x, y).r.toInt();
      result.setPixelRgba(x, y, origPixel.r.toInt(), origPixel.g.toInt(),
          origPixel.b.toInt(), maskVal);
    }
  }

  return Uint8List.fromList(img.encodePng(result));
}

// --- Alpha-Aware Processing ---

class AlphaSplitParams {
  final Uint8List imageBytes;
  const AlphaSplitParams({required this.imageBytes});
}

class AlphaSplitResult {
  final Uint8List rgbBytes;
  final Uint8List? alphaBytes; // null if no alpha channel
  final int width;
  final int height;
  final bool hasAlpha;

  const AlphaSplitResult({
    required this.rgbBytes,
    this.alphaBytes,
    required this.width,
    required this.height,
    required this.hasAlpha,
  });
}

AlphaSplitResult splitAlphaChannel(AlphaSplitParams params) {
  final decoded = img.decodeImage(params.imageBytes);
  if (decoded == null) throw Exception('Failed to decode image');

  final w = decoded.width;
  final h = decoded.height;

  // Check if image has meaningful alpha
  bool hasAlpha = false;
  for (int y = 0; y < h && !hasAlpha; y++) {
    for (int x = 0; x < w && !hasAlpha; x++) {
      if (decoded.getPixel(x, y).a.toInt() < 255) hasAlpha = true;
    }
  }

  // Create RGB image
  final rgb = img.Image(width: w, height: h);
  for (int y = 0; y < h; y++) {
    for (int x = 0; x < w; x++) {
      final p = decoded.getPixel(x, y);
      rgb.setPixelRgb(x, y, p.r.toInt(), p.g.toInt(), p.b.toInt());
    }
  }

  Uint8List? alphaBytes;
  if (hasAlpha) {
    final alpha = img.Image(width: w, height: h);
    for (int y = 0; y < h; y++) {
      for (int x = 0; x < w; x++) {
        final a = decoded.getPixel(x, y).a.toInt();
        alpha.setPixelRgb(x, y, a, a, a);
      }
    }
    alphaBytes = Uint8List.fromList(img.encodePng(alpha));
  }

  return AlphaSplitResult(
    rgbBytes: Uint8List.fromList(img.encodePng(rgb)),
    alphaBytes: alphaBytes,
    width: w,
    height: h,
    hasAlpha: hasAlpha,
  );
}

class AlphaRecombineParams {
  final Uint8List rgbBytes;
  final Uint8List alphaBytes;
  final int targetWidth;
  final int targetHeight;

  const AlphaRecombineParams({
    required this.rgbBytes,
    required this.alphaBytes,
    required this.targetWidth,
    required this.targetHeight,
  });
}

Uint8List recombineAlphaChannel(AlphaRecombineParams params) {
  final rgb = img.decodeImage(params.rgbBytes);
  var alpha = img.decodeImage(params.alphaBytes);
  if (rgb == null || alpha == null) throw Exception('Failed to decode');

  // Upscale alpha with bilinear to match RGB
  if (alpha.width != params.targetWidth || alpha.height != params.targetHeight) {
    alpha = img.copyResize(alpha,
        width: params.targetWidth,
        height: params.targetHeight,
        interpolation: img.Interpolation.linear);
  }

  final w = rgb.width;
  final h = rgb.height;
  final result = img.Image(width: w, height: h, numChannels: 4);
  for (int y = 0; y < h; y++) {
    for (int x = 0; x < w; x++) {
      final p = rgb.getPixel(x, y);
      final a = alpha.getPixel(x, y).r.toInt();
      result.setPixelRgba(x, y, p.r.toInt(), p.g.toInt(), p.b.toInt(), a);
    }
  }

  return Uint8List.fromList(img.encodePng(result));
}

// --- Tileable Texture Mode ---

class TileableParams {
  final Uint8List imageBytes;
  final int tileSize;
  final int overlap;
  final int channels;
  final MLNormalization normalization;

  const TileableParams({
    required this.imageBytes,
    this.tileSize = 256,
    this.overlap = 16,
    this.channels = 3,
    this.normalization = MLNormalization.zeroToOne,
  });
}

/// Split into tiles with mirror-padding at edges for seamless tiling after upscale.
TileResult splitIntoTilesTileable(TileableParams params) {
  final decoded = img.decodeImage(params.imageBytes);
  if (decoded == null) throw Exception('Failed to decode image for tiling');

  final w = decoded.width;
  final h = decoded.height;
  final step = params.tileSize - params.overlap;
  final pad = params.overlap;

  // Create mirror-padded image
  final padded = img.Image(width: w + pad * 2, height: h + pad * 2);
  for (int y = 0; y < padded.height; y++) {
    for (int x = 0; x < padded.width; x++) {
      // Mirror coordinates
      int srcX = x - pad;
      int srcY = y - pad;
      if (srcX < 0) srcX = -srcX;
      if (srcY < 0) srcY = -srcY;
      if (srcX >= w) srcX = 2 * w - srcX - 2;
      if (srcY >= h) srcY = 2 * h - srcY - 2;
      srcX = srcX.clamp(0, w - 1);
      srcY = srcY.clamp(0, h - 1);
      final p = decoded.getPixel(srcX, srcY);
      padded.setPixelRgb(x, y, p.r.toInt(), p.g.toInt(), p.b.toInt());
    }
  }

  // Now tile the padded image as normal
  final tiles = <TileInfo>[];
  for (int y = 0; y < h; y += step) {
    for (int x = 0; x < w; x += step) {
      final cropX = x; // offset in padded = original x (pad is already added)
      final cropY = y;
      final cw = min(params.tileSize, padded.width - cropX);
      final ch = min(params.tileSize, padded.height - cropY);
      final cropped = img.copyCrop(padded, x: cropX, y: cropY, width: cw, height: ch);

      img.Image tile;
      if (cw < params.tileSize || ch < params.tileSize) {
        tile = img.Image(width: params.tileSize, height: params.tileSize);
        img.compositeImage(tile, cropped);
      } else {
        tile = cropped;
      }

      final c = params.channels;
      final data = Float32List(1 * c * params.tileSize * params.tileSize);
      for (int ty = 0; ty < params.tileSize; ty++) {
        for (int tx = 0; tx < params.tileSize; tx++) {
          final pixel = tile.getPixel(tx, ty);
          final idx = ty * params.tileSize + tx;

          switch (params.normalization) {
            case MLNormalization.zeroToOne:
              data[0 * params.tileSize * params.tileSize + idx] = pixel.r.toDouble() / 255.0;
              if (c > 1) data[1 * params.tileSize * params.tileSize + idx] = pixel.g.toDouble() / 255.0;
              if (c > 2) data[2 * params.tileSize * params.tileSize + idx] = pixel.b.toDouble() / 255.0;
            case MLNormalization.negOneToOne:
              data[0 * params.tileSize * params.tileSize + idx] = pixel.r.toDouble() / 127.5 - 1.0;
              if (c > 1) data[1 * params.tileSize * params.tileSize + idx] = pixel.g.toDouble() / 127.5 - 1.0;
              if (c > 2) data[2 * params.tileSize * params.tileSize + idx] = pixel.b.toDouble() / 127.5 - 1.0;
            case MLNormalization.imageNet:
              data[0 * params.tileSize * params.tileSize + idx] = (pixel.r.toDouble() / 255.0 - 0.485) / 0.229;
              if (c > 1) data[1 * params.tileSize * params.tileSize + idx] = (pixel.g.toDouble() / 255.0 - 0.456) / 0.224;
              if (c > 2) data[2 * params.tileSize * params.tileSize + idx] = (pixel.b.toDouble() / 255.0 - 0.406) / 0.225;
          }
        }
      }

      tiles.add(TileInfo(
        data: data,
        shape: [1, c, params.tileSize, params.tileSize],
        x: x,
        y: y,
        width: min(params.tileSize, w - x),
        height: min(params.tileSize, h - y),
      ));
    }
  }

  return TileResult(
    tiles: tiles,
    imageWidth: w,
    imageHeight: h,
    tileSize: params.tileSize,
    overlap: params.overlap,
  );
}

// --- Upscale Post-processing ---

Uint8List tensorToPng(TensorToPngParams params) {
  final shape = params.shape;
  // NCHW: [1, C, H, W]
  final c = shape.length == 4 ? shape[1] : 3;
  final h = shape.length == 4 ? shape[2] : shape[1];
  final w = shape.length == 4 ? shape[3] : shape[2];

  final result = img.Image(width: w, height: h);

  for (int y = 0; y < h; y++) {
    for (int x = 0; x < w; x++) {
      final idx = y * w + x;
      double r, g, b;

      switch (params.normalization) {
        case MLNormalization.zeroToOne:
          r = params.data[0 * h * w + idx] * 255.0;
          g = c > 1 ? params.data[1 * h * w + idx] * 255.0 : r;
          b = c > 2 ? params.data[2 * h * w + idx] * 255.0 : r;
        case MLNormalization.negOneToOne:
          r = (params.data[0 * h * w + idx] + 1.0) * 127.5;
          g = c > 1 ? (params.data[1 * h * w + idx] + 1.0) * 127.5 : r;
          b = c > 2 ? (params.data[2 * h * w + idx] + 1.0) * 127.5 : r;
        case MLNormalization.imageNet:
          r = (params.data[0 * h * w + idx] * 0.229 + 0.485) * 255.0;
          g = c > 1 ? (params.data[1 * h * w + idx] * 0.224 + 0.456) * 255.0 : r;
          b = c > 2 ? (params.data[2 * h * w + idx] * 0.225 + 0.406) * 255.0 : r;
      }

      result.setPixelRgb(
        x, y,
        r.round().clamp(0, 255),
        g.round().clamp(0, 255),
        b.round().clamp(0, 255),
      );
    }
  }

  return Uint8List.fromList(img.encodePng(result));
}

// --- Tiling ---

TileResult splitIntoTiles(TileParams params) {
  final decoded = img.decodeImage(params.imageBytes);
  if (decoded == null) throw Exception('Failed to decode image for tiling');

  final w = decoded.width;
  final h = decoded.height;
  final step = params.tileSize - params.overlap;

  final tiles = <TileInfo>[];

  for (int y = 0; y < h; y += step) {
    for (int x = 0; x < w; x += step) {
      final tileW = min(params.tileSize, w - x);
      final tileH = min(params.tileSize, h - y);

      final cropped = img.copyCrop(decoded, x: x, y: y, width: tileW, height: tileH);

      // Pad to tileSize if needed
      img.Image tile;
      if (tileW < params.tileSize || tileH < params.tileSize) {
        tile = img.Image(width: params.tileSize, height: params.tileSize);
        img.compositeImage(tile, cropped);
      } else {
        tile = cropped;
      }

      // Convert to NCHW Float32List
      final c = params.channels;
      final data = Float32List(1 * c * params.tileSize * params.tileSize);
      for (int ty = 0; ty < params.tileSize; ty++) {
        for (int tx = 0; tx < params.tileSize; tx++) {
          final pixel = tile.getPixel(tx, ty);
          final idx = ty * params.tileSize + tx;

          switch (params.normalization) {
            case MLNormalization.zeroToOne:
              data[0 * params.tileSize * params.tileSize + idx] = pixel.r.toDouble() / 255.0;
              if (c > 1) data[1 * params.tileSize * params.tileSize + idx] = pixel.g.toDouble() / 255.0;
              if (c > 2) data[2 * params.tileSize * params.tileSize + idx] = pixel.b.toDouble() / 255.0;
            case MLNormalization.negOneToOne:
              data[0 * params.tileSize * params.tileSize + idx] = pixel.r.toDouble() / 127.5 - 1.0;
              if (c > 1) data[1 * params.tileSize * params.tileSize + idx] = pixel.g.toDouble() / 127.5 - 1.0;
              if (c > 2) data[2 * params.tileSize * params.tileSize + idx] = pixel.b.toDouble() / 127.5 - 1.0;
            case MLNormalization.imageNet:
              data[0 * params.tileSize * params.tileSize + idx] = (pixel.r.toDouble() / 255.0 - 0.485) / 0.229;
              if (c > 1) data[1 * params.tileSize * params.tileSize + idx] = (pixel.g.toDouble() / 255.0 - 0.456) / 0.224;
              if (c > 2) data[2 * params.tileSize * params.tileSize + idx] = (pixel.b.toDouble() / 255.0 - 0.406) / 0.225;
          }
        }
      }

      tiles.add(TileInfo(
        data: data,
        shape: [1, c, params.tileSize, params.tileSize],
        x: x,
        y: y,
        width: tileW,
        height: tileH,
      ));
    }
  }

  return TileResult(
    tiles: tiles,
    imageWidth: w,
    imageHeight: h,
    tileSize: params.tileSize,
    overlap: params.overlap,
  );
}

Uint8List stitchTiles(StitchParams params) {
  final outW = params.imageWidth * params.scaleFactor;
  final outH = params.imageHeight * params.scaleFactor;
  final scaledTileSize = params.tileSize * params.scaleFactor;
  final scaledOverlap = params.overlap * params.scaleFactor;

  final result = img.Image(width: outW, height: outH);
  // Weight buffer for overlap blending
  final weights = Float32List(outW * outH);

  for (final tile in params.tiles) {
    final outX = tile.x * params.scaleFactor;
    final outY = tile.y * params.scaleFactor;
    final tileW = tile.width * params.scaleFactor;
    final tileH = tile.height * params.scaleFactor;

    // Decode tile tensor to pixels
    final shape = tile.shape;
    final c = shape.length == 4 ? shape[1] : 3;
    final tH = shape.length == 4 ? shape[2] : shape[1];
    final tW = shape.length == 4 ? shape[3] : shape[2];

    for (int y = 0; y < tileH && (outY + y) < outH; y++) {
      for (int x = 0; x < tW && (outX + x) < outW; x++) {
        if (y >= tileH || x >= tileW) continue;

        final idx = y * tW + x;
        double r, g, b;

        switch (params.normalization) {
          case MLNormalization.zeroToOne:
            r = tile.data[0 * tH * tW + idx] * 255.0;
            g = c > 1 ? tile.data[1 * tH * tW + idx] * 255.0 : r;
            b = c > 2 ? tile.data[2 * tH * tW + idx] * 255.0 : r;
          case MLNormalization.negOneToOne:
            r = (tile.data[0 * tH * tW + idx] + 1.0) * 127.5;
            g = c > 1 ? (tile.data[1 * tH * tW + idx] + 1.0) * 127.5 : r;
            b = c > 2 ? (tile.data[2 * tH * tW + idx] + 1.0) * 127.5 : r;
          case MLNormalization.imageNet:
            r = (tile.data[0 * tH * tW + idx] * 0.229 + 0.485) * 255.0;
            g = c > 1 ? (tile.data[1 * tH * tW + idx] * 0.224 + 0.456) * 255.0 : r;
            b = c > 2 ? (tile.data[2 * tH * tW + idx] * 0.225 + 0.406) * 255.0 : r;
        }

        // Compute blend weight for overlap regions
        double weight = 1.0;
        if (scaledOverlap > 0) {
          // Left fade
          if (x < scaledOverlap && outX > 0) {
            weight *= x / scaledOverlap;
          }
          // Top fade
          if (y < scaledOverlap && outY > 0) {
            weight *= y / scaledOverlap;
          }
          // Right fade
          if (x >= tileW - scaledOverlap && outX + scaledTileSize < outW) {
            weight *= (tileW - x) / scaledOverlap;
          }
          // Bottom fade
          if (y >= tileH - scaledOverlap && outY + scaledTileSize < outH) {
            weight *= (tileH - y) / scaledOverlap;
          }
        }

        final px = outX + x;
        final py = outY + y;
        if (px >= outW || py >= outH) continue;

        final existing = result.getPixel(px, py);
        final existingWeight = weights[py * outW + px];

        if (existingWeight == 0) {
          result.setPixelRgb(
            px, py,
            r.round().clamp(0, 255),
            g.round().clamp(0, 255),
            b.round().clamp(0, 255),
          );
        } else {
          // Blend
          final totalWeight = existingWeight + weight;
          final nr = (existing.r * existingWeight + r * weight) / totalWeight;
          final ng = (existing.g * existingWeight + g * weight) / totalWeight;
          final nb = (existing.b * existingWeight + b * weight) / totalWeight;
          result.setPixelRgb(
            px, py,
            nr.round().clamp(0, 255),
            ng.round().clamp(0, 255),
            nb.round().clamp(0, 255),
          );
        }

        weights[py * outW + px] = existingWeight + weight;
      }
    }
  }

  return Uint8List.fromList(img.encodePng(result));
}
