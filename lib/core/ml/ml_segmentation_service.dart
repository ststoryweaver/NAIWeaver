import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'ml_image_processing.dart';
import 'ml_inference_service.dart';

class SAMEmbeddingResult {
  final Float32List embeddings;
  final List<int> embeddingShape; // Dynamic — read from encoder output
  final int originalWidth;
  final int originalHeight;
  final double scaleFactor;
  final int padX;
  final int padY;
  final Uint8List originalImageBytes;

  const SAMEmbeddingResult({
    required this.embeddings,
    required this.embeddingShape,
    required this.originalWidth,
    required this.originalHeight,
    required this.scaleFactor,
    required this.padX,
    required this.padY,
    required this.originalImageBytes,
  });

  /// Mask input shape derived from embedding: [1, 1, H/4, W/4] heuristic.
  /// EdgeSAM: embedding [1,256,64,64] → mask [1,1,256,256]
  /// SAM 2.1-Tiny: embedding shape varies — use 256x256 as default mask input.
  List<int> get maskInputShape {
    if (embeddingShape.length == 4) {
      final h = embeddingShape[2] * 4;
      final w = embeddingShape[3] * 4;
      return [1, 1, h, w];
    }
    return [1, 1, 256, 256];
  }

  int get maskInputSize {
    final s = maskInputShape;
    return s[0] * s[1] * s[2] * s[3];
  }
}

class SAMSegmentResult {
  final Uint8List mask; // Grayscale PNG
  final Uint8List resultImage; // RGBA PNG with transparent BG
  final Uint8List originalImage;
  final Float32List lowResMask; // For iterative refinement
  final List<int> lowResMaskShape;
  final double iouScore;
  final int width;
  final int height;

  const SAMSegmentResult({
    required this.mask,
    required this.resultImage,
    required this.originalImage,
    required this.lowResMask,
    required this.lowResMaskShape,
    required this.iouScore,
    required this.width,
    required this.height,
  });
}

class MLSegmentationService {
  final MLInferenceService _inferenceService;

  MLSegmentationService(this._inferenceService);

  Future<SAMEmbeddingResult?> encodeImage(
    Uint8List imageBytes,
    String encoderModelId, {
    void Function(String stage, double progress)? onProgress,
  }) async {
    onProgress?.call('Preprocessing...', 0.1);

    // Preprocess for SAM (resize + pad to 1024x1024 + ImageNet norm)
    final preResult = await compute(
      preprocessForSAM,
      SAMPreprocessParams(imageBytes: imageBytes),
    );

    onProgress?.call('Loading encoder...', 0.2);
    final loaded = await _inferenceService.loadModel(encoderModelId);
    if (!loaded) return null;

    onProgress?.call('Encoding image...', 0.4);
    final result = await _inferenceService.runInference(
      modelId: encoderModelId,
      inputData: preResult.data,
      inputShape: preResult.shape,
    );

    if (result == null) return null;

    debugPrint('ML: Encoder output shape: ${result.shape}');

    onProgress?.call('Complete', 1.0);
    return SAMEmbeddingResult(
      embeddings: result.data,
      embeddingShape: result.shape,
      originalWidth: preResult.originalWidth,
      originalHeight: preResult.originalHeight,
      scaleFactor: preResult.scaleFactor,
      padX: preResult.padX,
      padY: preResult.padY,
      originalImageBytes: imageBytes,
    );
  }

  Future<SAMSegmentResult?> decodeMask({
    required SAMEmbeddingResult embeddings,
    required String decoderModelId,
    required List<Offset> positivePoints, // normalized 0-1
    required List<Offset> negativePoints,
    required Rect? boxSelection, // normalized 0-1
    required Uint8List originalImageBytes,
    Float32List? previousMaskLogits,
    List<int>? previousMaskShape,
  }) async {
    final loaded = await _inferenceService.loadModel(decoderModelId);
    if (!loaded) return null;

    // Build point coordinates and labels
    final allPoints = <List<double>>[];
    final allLabels = <double>[];

    // Add positive points (label 1)
    for (final p in positivePoints) {
      allPoints.add([p.dx, p.dy]);
      allLabels.add(1.0);
    }

    // Add negative points (label 0)
    for (final p in negativePoints) {
      allPoints.add([p.dx, p.dy]);
      allLabels.add(0.0);
    }

    // Add box corners if provided (labels 2 and 3)
    if (boxSelection != null) {
      allPoints.add([boxSelection.left, boxSelection.top]);
      allLabels.add(2.0);
      allPoints.add([boxSelection.right, boxSelection.bottom]);
      allLabels.add(3.0);
    }

    // Need at least one point
    if (allPoints.isEmpty) return null;

    // Transform points to SAM 1024-space
    final transformedPoints = transformPointsToSAM(SAMPointTransformParams(
      points: allPoints,
      originalWidth: embeddings.originalWidth,
      originalHeight: embeddings.originalHeight,
      scaleFactor: embeddings.scaleFactor,
      padX: embeddings.padX,
      padY: embeddings.padY,
    ));

    // Point coords shape: [1, numPoints, 2]
    final numPoints = allPoints.length;
    final pointCoordsData = Float32List(1 * numPoints * 2);
    for (int i = 0; i < numPoints * 2; i++) {
      pointCoordsData[i] = transformedPoints[i];
    }

    // Point labels shape: [1, numPoints]
    final pointLabelsData = Float32List(numPoints);
    for (int i = 0; i < numPoints; i++) {
      pointLabelsData[i] = allLabels[i];
    }

    // Mask input — use dynamic shape from embeddings
    final maskShape = previousMaskShape ?? embeddings.maskInputShape;
    final maskSize = maskShape[0] * maskShape[1] * maskShape[2] * maskShape[3];
    final maskInput = previousMaskLogits ?? Float32List(maskSize);

    // has_mask_input [1]
    final hasMaskInput = Float32List(1);
    hasMaskInput[0] = previousMaskLogits != null ? 1.0 : 0.0;

    // orig_im_size [2] — original image dimensions
    final origImSize = Float32List(2);
    origImSize[0] = embeddings.originalHeight.toDouble();
    origImSize[1] = embeddings.originalWidth.toDouble();

    final inputs = <String, ({Float32List data, List<int> shape})>{
      'image_embeddings': (
        data: embeddings.embeddings,
        shape: embeddings.embeddingShape,
      ),
      'point_coords': (
        data: pointCoordsData,
        shape: [1, numPoints, 2],
      ),
      'point_labels': (
        data: pointLabelsData,
        shape: [1, numPoints],
      ),
      'mask_input': (
        data: maskInput,
        shape: maskShape,
      ),
      'has_mask_input': (
        data: hasMaskInput,
        shape: [1],
      ),
      'orig_im_size': (
        data: origImSize,
        shape: [2],
      ),
    };

    final outputs = await _inferenceService.runMultiInputInference(
      modelId: decoderModelId,
      inputs: inputs,
    );

    if (outputs == null) return null;

    // Extract outputs
    final masksResult = outputs['masks'];
    final iouResult = outputs['iou_predictions'];
    final lowResMasks = outputs['low_res_masks'];

    if (masksResult == null) return null;

    final iouScore = iouResult?.data.isNotEmpty == true ? iouResult!.data[0] : 0.0;

    debugPrint('ML: Decoder masks shape: ${masksResult.shape}, '
        'low_res shape: ${lowResMasks?.shape}, IOU: $iouScore');

    // Postprocess mask
    final maskPng = await compute(
      postprocessSAMMask,
      SAMPostprocessParams(
        maskLogits: masksResult.data,
        maskShape: masksResult.shape,
        originalWidth: embeddings.originalWidth,
        originalHeight: embeddings.originalHeight,
        scaleFactor: embeddings.scaleFactor,
        padX: embeddings.padX,
        padY: embeddings.padY,
        maskIndex: 0,
      ),
    );

    // Composite segmentation
    final resultImage = await compute(
      compositeSegmentation,
      SegCompositeParams(
        originalImageBytes: originalImageBytes,
        maskBytes: maskPng,
      ),
    );

    final lowResData = lowResMasks?.data ?? Float32List(embeddings.maskInputSize);
    final lowResShape = lowResMasks?.shape ?? embeddings.maskInputShape;

    return SAMSegmentResult(
      mask: maskPng,
      resultImage: resultImage,
      originalImage: originalImageBytes,
      lowResMask: lowResData,
      lowResMaskShape: lowResShape,
      iouScore: iouScore.toDouble(),
      width: embeddings.originalWidth,
      height: embeddings.originalHeight,
    );
  }
}
