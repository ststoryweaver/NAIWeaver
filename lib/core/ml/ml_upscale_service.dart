import 'package:flutter/foundation.dart';
import 'ml_image_processing.dart';
import 'ml_inference_service.dart';
import 'ml_model_entry.dart';
import 'ml_model_registry.dart';

class MLUpscaleService {
  final MLInferenceService _inferenceService;

  MLUpscaleService(this._inferenceService);

  /// Standard upscale — handles alpha channel preservation automatically.
  Future<Uint8List?> upscale(
    Uint8List imageBytes,
    String modelId, {
    void Function(String stage, double progress)? onProgress,
    bool tileable = false,
  }) async {
    final config = MLModelRegistry.configFor(modelId);
    if (config == null) return null;

    // Check for alpha channel
    onProgress?.call('Analyzing image...', 0.02);
    final alphaSplit = await compute(
      splitAlphaChannel,
      AlphaSplitParams(imageBytes: imageBytes),
    );

    // Upscale RGB
    final rgbResult = await _upscaleRGB(
      alphaSplit.rgbBytes,
      modelId,
      config,
      tileable: tileable,
      onProgress: (stage, progress) {
        // Scale progress to 0.05–0.85 range
        onProgress?.call(stage, 0.05 + progress * 0.80);
      },
    );

    if (rgbResult == null) return null;

    // If no alpha, we're done
    if (!alphaSplit.hasAlpha || alphaSplit.alphaBytes == null) {
      onProgress?.call('Complete', 1.0);
      return rgbResult;
    }

    // Upscale alpha channel separately (bilinear resize, no model needed)
    onProgress?.call('Recombining alpha...', 0.90);
    final upscaledW = alphaSplit.width * config.scaleFactor;
    final upscaledH = alphaSplit.height * config.scaleFactor;

    final finalResult = await compute(
      recombineAlphaChannel,
      AlphaRecombineParams(
        rgbBytes: rgbResult,
        alphaBytes: alphaSplit.alphaBytes!,
        targetWidth: upscaledW,
        targetHeight: upscaledH,
      ),
    );

    onProgress?.call('Complete', 1.0);
    return finalResult;
  }

  /// Internal: upscale RGB bytes using tiled inference.
  Future<Uint8List?> _upscaleRGB(
    Uint8List rgbBytes,
    String modelId,
    MLModelConfig config, {
    bool tileable = false,
    void Function(String stage, double progress)? onProgress,
  }) async {
    final tileSize = config.maxTileSize ?? 256;
    final overlap = config.tileOverlap;

    // Step 1: Load model
    onProgress?.call('Loading model...', 0.05);
    final loaded = await _inferenceService.loadModel(modelId);
    if (!loaded) return null;

    // Step 2: Split into tiles (isolate)
    onProgress?.call('Splitting into tiles...', 0.1);
    final TileResult tileResult;
    if (tileable) {
      tileResult = await compute(
        splitIntoTilesTileable,
        TileableParams(
          imageBytes: rgbBytes,
          tileSize: tileSize,
          overlap: overlap,
          channels: config.inputChannels,
          normalization: config.normalization,
        ),
      );
    } else {
      tileResult = await compute(
        splitIntoTiles,
        TileParams(
          imageBytes: rgbBytes,
          tileSize: tileSize,
          overlap: overlap,
          channels: config.inputChannels,
          normalization: config.normalization,
        ),
      );
    }

    // Step 3: Run inference per tile (main thread, async native)
    final upscaledTiles = <StitchTileData>[];
    final totalTiles = tileResult.tiles.length;

    for (int i = 0; i < totalTiles; i++) {
      final tile = tileResult.tiles[i];
      final progress = 0.1 + (0.8 * (i / totalTiles));
      onProgress?.call('Upscaling tile ${i + 1}/$totalTiles...', progress);

      final result = await _inferenceService.runInference(
        modelId: modelId,
        inputData: tile.data,
        inputShape: tile.shape,
      );

      if (result == null) return null;

      upscaledTiles.add(StitchTileData(
        data: result.data,
        shape: result.shape,
        x: tile.x,
        y: tile.y,
        width: tile.width,
        height: tile.height,
      ));
    }

    // Step 4: Stitch tiles (isolate)
    onProgress?.call('Stitching result...', 0.95);
    final result = await compute(
      stitchTiles,
      StitchParams(
        tiles: upscaledTiles,
        imageWidth: tileResult.imageWidth,
        imageHeight: tileResult.imageHeight,
        scaleFactor: config.scaleFactor,
        tileSize: tileResult.tileSize,
        overlap: tileResult.overlap,
        normalization: config.normalization,
      ),
    );

    onProgress?.call('Complete', 1.0);
    return result;
  }
}
