import 'package:flutter/foundation.dart';
import 'ml_image_processing.dart';
import 'ml_inference_service.dart';
import 'ml_model_entry.dart';
import 'ml_model_registry.dart';

class BGRemovalResult {
  final Uint8List rawMask;
  final Uint8List resultImage;
  final Uint8List originalImage;
  final int width;
  final int height;

  const BGRemovalResult({
    required this.rawMask,
    required this.resultImage,
    required this.originalImage,
    required this.width,
    required this.height,
  });
}

class MLBackgroundRemovalService {
  final MLInferenceService _inferenceService;

  MLBackgroundRemovalService(this._inferenceService);

  Future<BGRemovalResult?> removeBackground(
    Uint8List imageBytes,
    String modelId, {
    void Function(String stage, double progress)? onProgress,
  }) async {
    final config = MLModelRegistry.configFor(modelId);
    if (config == null) return null;

    final inputW = config.inputWidth ?? 320;
    final inputH = config.inputHeight ?? 320;

    // Step 1: Preprocess (isolate)
    onProgress?.call('Preprocessing...', 0.1);
    final preprocessed = await compute(
      preprocessImage,
      PreprocessParams(
        imageBytes: imageBytes,
        targetWidth: inputW,
        targetHeight: inputH,
        channels: config.inputChannels,
        normalization: config.normalization,
      ),
    );

    // Step 2: Load model (free memory first; skip NNAPI — causes native crashes on Android)
    onProgress?.call('Loading model...', 0.2);
    await _inferenceService.unloadAll();
    final loaded = await _inferenceService.loadModel(modelId, skipNnapi: true);
    if (!loaded) return null;

    // Step 3: Run inference (main thread, async native)
    onProgress?.call('Running inference...', 0.4);
    final result = await _inferenceService.runInference(
      modelId: modelId,
      inputData: preprocessed.data,
      inputShape: preprocessed.shape,
    );
    if (result == null) return null;

    // Step 4: Generate mask or matte (isolate)
    final isMatte = config.outputType == MLOutputType.alphaMatte;
    onProgress?.call(isMatte ? 'Generating matte...' : 'Generating mask...', 0.7);
    final Uint8List rawMask;
    if (isMatte) {
      rawMask = await compute(
        generateAlphaMatte,
        MaskParams(
          rawOutput: result.data,
          outputShape: result.shape,
          originalWidth: preprocessed.originalWidth,
          originalHeight: preprocessed.originalHeight,
        ),
      );
    } else {
      rawMask = await compute(
        generateMask,
        MaskParams(
          rawOutput: result.data,
          outputShape: result.shape,
          originalWidth: preprocessed.originalWidth,
          originalHeight: preprocessed.originalHeight,
        ),
      );
    }

    // Step 5: Apply mask/matte with default settings (isolate)
    onProgress?.call('Applying mask...', 0.9);
    final Uint8List resultImage;
    if (isMatte) {
      resultImage = await compute(
        applyAlphaMatteToImage,
        ApplyMatteParams(
          originalImageBytes: imageBytes,
          matteBytes: rawMask,
        ),
      );
    } else {
      resultImage = await compute(
        applyMaskToImage,
        ApplyMaskParams(
          originalImageBytes: imageBytes,
          maskBytes: rawMask,
          threshold: 0.5,
          featherRadius: 0,
        ),
      );
    }

    onProgress?.call('Complete', 1.0);

    return BGRemovalResult(
      rawMask: rawMask,
      resultImage: resultImage,
      originalImage: imageBytes,
      width: preprocessed.originalWidth,
      height: preprocessed.originalHeight,
    );
  }

  /// Re-apply mask with different threshold/feather settings.
  /// Runs in isolate — no inference needed.
  static Future<Uint8List> reapplyMask({
    required Uint8List originalBytes,
    required Uint8List maskBytes,
    double threshold = 0.5,
    int featherRadius = 0,
  }) async {
    return compute(
      applyMaskToImage,
      ApplyMaskParams(
        originalImageBytes: originalBytes,
        maskBytes: maskBytes,
        threshold: threshold,
        featherRadius: featherRadius,
      ),
    );
  }

  /// Re-apply alpha matte with different opacity/edge refinement settings.
  /// Runs in isolate — no inference needed.
  static Future<Uint8List> reapplyAlphaMatte({
    required Uint8List originalBytes,
    required Uint8List matteBytes,
    double opacityMultiplier = 1.0,
    int edgeRefinementRadius = 0,
  }) async {
    return compute(
      applyAlphaMatteToImage,
      ApplyMatteParams(
        originalImageBytes: originalBytes,
        matteBytes: matteBytes,
        opacityMultiplier: opacityMultiplier,
        edgeRefinementRadius: edgeRefinementRadius,
      ),
    );
  }
}
