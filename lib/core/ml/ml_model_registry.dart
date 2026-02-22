import 'ml_model_entry.dart';

class MLModelRegistry {
  static const _baseUrl =
      'https://github.com/ststoryweaver/NAIWeaver/releases/download/models-v1/';

  static const List<MLModelEntry> backgroundRemovalModels = [
    MLModelEntry(
      id: 'isnet_anime',
      name: 'ISNet Anime',
      description: 'Binary mask, anime-optimized',
      type: MLModelType.backgroundRemoval,
      downloadUrl: '${_baseUrl}isnet-anime.onnx',
      fileSizeBytes: 176069933,
      sha256: 'f15622d853e8260172812b657053460e20806f04b9e05147d49af7bed31a6e99',
      filename: 'isnet-anime.onnx',
      tier: MLPerformanceTier.fast,
      deviceTier: MLDeviceTier.mobile,
    ),
    MLModelEntry(
      id: 'rmbg20_q4f16',
      name: 'RMBG-2.0 Q4F16',
      description: 'Alpha matte, quantized',
      type: MLModelType.backgroundRemoval,
      downloadUrl: '${_baseUrl}model_q4f16.onnx',
      fileSizeBytes: 233815293,
      sha256: '8bfeb5f93220eb19f6747c217b62cf04342840c4e973f55bf64e9762919f446d',
      filename: 'model_q4f16.onnx',
      tier: MLPerformanceTier.balanced,
      deviceTier: MLDeviceTier.desktop,
      minRamMB: 4096,
    ),
    MLModelEntry(
      id: 'rmbg20_fp16',
      name: 'RMBG-2.0 FP16',
      description: 'Alpha matte, best quality',
      type: MLModelType.backgroundRemoval,
      downloadUrl: '${_baseUrl}model_fp16.onnx',
      fileSizeBytes: 513576499,
      sha256: '9dc47db40d113090ba5d7a13d8fcfd9ee4eda510ce92613219b2fe19da4746f6',
      filename: 'model_fp16.onnx',
      tier: MLPerformanceTier.quality,
      deviceTier: MLDeviceTier.desktop,
      minRamMB: 6144,
    ),
  ];

  static const List<MLModelEntry> upscaleModels = [
    MLModelEntry(
      id: 'span_2x_dc',
      name: 'SPAN 2x DC',
      description: '2x upscaling, fast and tiny',
      type: MLModelType.upscale,
      downloadUrl: '${_baseUrl}2x_AniSD_DC_SPAN_92500_fp32.onnx',
      fileSizeBytes: 1656315,
      sha256: '2a6aafadccfa7d910361016843b2691f827863e08853dd81e5bd49facc6933c3',
      filename: '2x_AniSD_DC_SPAN_92500_fp32.onnx',
      tier: MLPerformanceTier.fast,
      deviceTier: MLDeviceTier.mobile,
    ),
    MLModelEntry(
      id: 'compact_2x',
      name: 'Compact 2x',
      description: '2x upscaling, mobile fallback',
      type: MLModelType.upscale,
      downloadUrl: '${_baseUrl}2x_AniSD_AC_G6i2a_Compact_72500_fp32.onnx',
      fileSizeBytes: 2413474,
      sha256: 'c2a22a9cd9d301c48f07576a773c3408a32ae558c5e03d59b297959045916c80',
      filename: '2x_AniSD_AC_G6i2a_Compact_72500_fp32.onnx',
      tier: MLPerformanceTier.fast,
      deviceTier: MLDeviceTier.mobile,
    ),
    MLModelEntry(
      id: 'realplksr_2x_dc',
      name: 'RealPLKSR 2x DC',
      description: '2x upscaling, best quality',
      type: MLModelType.upscale,
      downloadUrl: '${_baseUrl}2x_AniSD_DC_RealPLKSR_115K_fp32_FO_dynamic.onnx',
      fileSizeBytes: 29764466,
      sha256: 'd47195243b6edffc6982f43cb50c80e8cff804925eed8dffcab6466004c08d49',
      filename: '2x_AniSD_DC_RealPLKSR_115K_fp32_FO_dynamic.onnx',
      tier: MLPerformanceTier.quality,
      deviceTier: MLDeviceTier.desktop,
      minRamMB: 6144,
    ),
  ];

  static const List<MLModelEntry> segmentationModels = [
    MLModelEntry(
      id: 'sam21_tiny_encoder',
      name: 'SAM 2.1-Tiny Encoder',
      description: 'Image encoder for interactive segmentation',
      type: MLModelType.segmentation,
      downloadUrl: '${_baseUrl}vision_encoder.onnx',
      fileSizeBytes: 134261339,
      sha256: 'fecccb8e954751e63020123f554951c15ca5bff6351b2c7c5a16967062ee53dd',
      filename: 'vision_encoder.onnx',
      tier: MLPerformanceTier.balanced,
      deviceTier: MLDeviceTier.both,
      pairedModelId: 'sam21_tiny_decoder',
      platformFlags: {'windows', 'linux', 'macos', 'ios'},
    ),
    MLModelEntry(
      id: 'sam21_tiny_decoder',
      name: 'SAM 2.1-Tiny Decoder',
      description: 'Mask decoder for interactive segmentation',
      type: MLModelType.segmentation,
      downloadUrl: '${_baseUrl}prompt_encoder_mask_decoder.onnx',
      fileSizeBytes: 20657357,
      sha256: 'ca28fac6340e2429cb6412690bfac68b8c1a98b828ef611ab252a25827eb325c',
      filename: 'prompt_encoder_mask_decoder.onnx',
      tier: MLPerformanceTier.balanced,
      deviceTier: MLDeviceTier.both,
      pairedModelId: 'sam21_tiny_encoder',
      platformFlags: {'windows', 'linux', 'macos', 'ios'},
    ),
  ];

  static List<MLModelEntry> get all => [
        ...backgroundRemovalModels,
        ...upscaleModels,
        ...segmentationModels,
      ];

  static MLModelEntry? findById(String id) {
    for (final entry in all) {
      if (entry.id == id) return entry;
    }
    return null;
  }

  static List<MLModelEntry> byType(MLModelType type) {
    return all.where((e) => e.type == type).toList();
  }

  static String? pairedDecoderId(String encoderId) {
    final encoder = findById(encoderId);
    return encoder?.pairedModelId;
  }

  static String? pairedEncoderId(String decoderId) {
    final decoder = findById(decoderId);
    return decoder?.pairedModelId;
  }

  /// Combined file size for a segmentation pair (encoder + decoder).
  static int segmentationPairSize(String encoderId) {
    final encoder = findById(encoderId);
    final decoderId = pairedDecoderId(encoderId);
    final decoder = decoderId != null ? findById(decoderId) : null;
    return (encoder?.fileSizeBytes ?? 0) + (decoder?.fileSizeBytes ?? 0);
  }

  static const Map<String, MLModelConfig> configs = {
    // Background Removal
    'isnet_anime': MLModelConfig(
      inputWidth: 1024,
      inputHeight: 1024,
      inputChannels: 3,
      normalization: MLNormalization.zeroToOne,
      scaleFactor: 1,
      inputName: 'input',
      outputName: 'output',
      outputType: MLOutputType.binaryMask,
    ),
    'rmbg20_q4f16': MLModelConfig(
      inputWidth: 1024,
      inputHeight: 1024,
      inputChannels: 3,
      normalization: MLNormalization.zeroToOne,
      scaleFactor: 1,
      inputName: 'pixel_values',
      outputName: 'alphas',
      outputType: MLOutputType.alphaMatte,
    ),
    'rmbg20_fp16': MLModelConfig(
      inputWidth: 1024,
      inputHeight: 1024,
      inputChannels: 3,
      normalization: MLNormalization.zeroToOne,
      scaleFactor: 1,
      inputName: 'pixel_values',
      outputName: 'alphas',
      outputType: MLOutputType.alphaMatte,
    ),
    // Upscale
    'span_2x_dc': MLModelConfig(
      inputChannels: 3,
      normalization: MLNormalization.zeroToOne,
      scaleFactor: 2,
      maxTileSize: 256,
      tileOverlap: 16,
      inputName: 'input',
      outputName: 'output',
    ),
    'compact_2x': MLModelConfig(
      inputChannels: 3,
      normalization: MLNormalization.zeroToOne,
      scaleFactor: 2,
      maxTileSize: 512,
      tileOverlap: 16,
      inputName: 'input',
      outputName: 'output',
    ),
    'realplksr_2x_dc': MLModelConfig(
      inputChannels: 3,
      normalization: MLNormalization.zeroToOne,
      scaleFactor: 2,
      maxTileSize: 256,
      tileOverlap: 32,
      inputName: 'input',
      outputName: 'output',
    ),

    // Segmentation (SAM 2.1-Tiny)
    'sam21_tiny_encoder': MLModelConfig(
      inputWidth: 1024,
      inputHeight: 1024,
      inputChannels: 3,
      normalization: MLNormalization.imageNet,
      inputName: 'image',
      outputName: 'image_embeddings',
    ),
    'sam21_tiny_decoder': MLModelConfig(
      inputName: 'image_embeddings',
      outputName: 'masks',
      inputNames: [
        'image_embeddings',
        'point_coords',
        'point_labels',
        'mask_input',
        'has_mask_input',
        'orig_im_size',
      ],
      outputNames: ['masks', 'iou_predictions', 'low_res_masks'],
    ),
  };

  static MLModelConfig? configFor(String modelId) => configs[modelId];

  /// Legacy model IDs that may exist in user preferences from previous versions.
  static const Set<String> legacyModelIds = {
    'isnet_general', 'u2net', 'modnet', 'birefnet', 'rmbg14',
    'real_esrgan_x4', 'rfdn_x2', 'real_cugan_x2', 'swinir_x4', 'hat_x4',
    'edgesam_encoder', 'edgesam_decoder',
    'rmbg20_q4f16_ort', 'rmbg20_fp16_ort',
  };
}
