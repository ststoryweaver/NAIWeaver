enum MLModelType { backgroundRemoval, upscale, segmentation }

enum MLNormalization { zeroToOne, negOneToOne, imageNet }

enum MLPerformanceTier { fast, balanced, quality }

enum MLDeviceTier { mobile, desktop, both }

enum MLOutputType { binaryMask, alphaMatte }

class MLModelConfig {
  final int? inputWidth;
  final int? inputHeight;
  final int inputChannels;
  final MLNormalization normalization;
  final int scaleFactor;
  final int? maxTileSize;
  final int tileOverlap;
  final String inputName;
  final String outputName;
  final List<String>? inputNames;
  final List<String>? outputNames;
  final MLOutputType outputType;

  const MLModelConfig({
    this.inputWidth,
    this.inputHeight,
    this.inputChannels = 3,
    this.normalization = MLNormalization.zeroToOne,
    this.scaleFactor = 1,
    this.maxTileSize,
    this.tileOverlap = 0,
    this.inputName = 'input',
    this.outputName = 'output',
    this.inputNames,
    this.outputNames,
    this.outputType = MLOutputType.binaryMask,
  });
}

class MLModelEntry {
  final String id;
  final String name;
  final String description;
  final MLModelType type;
  final String downloadUrl;
  final int fileSizeBytes;
  final String sha256;
  final String filename;
  final MLPerformanceTier tier;
  final MLDeviceTier deviceTier;
  final Set<String> platformFlags;
  final int version;
  final String? pairedModelId;
  final int? minRamMB;

  const MLModelEntry({
    required this.id,
    required this.name,
    required this.description,
    required this.type,
    required this.downloadUrl,
    required this.fileSizeBytes,
    required this.sha256,
    required this.filename,
    this.tier = MLPerformanceTier.balanced,
    this.deviceTier = MLDeviceTier.mobile,
    this.platformFlags = const {},
    this.version = 1,
    this.pairedModelId,
    this.minRamMB,
  });

  String get fileSizeLabel {
    if (fileSizeBytes >= 1024 * 1024 * 1024) {
      return '${(fileSizeBytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
    } else if (fileSizeBytes >= 1024 * 1024) {
      return '${(fileSizeBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    } else if (fileSizeBytes >= 1024) {
      return '${(fileSizeBytes / 1024).toStringAsFixed(1)} KB';
    }
    return '$fileSizeBytes B';
  }

  bool get isAvailableOnPlatform {
    if (platformFlags.isEmpty) return true;
    // Check at runtime
    return true; // Filtered in UI via MLDeviceCapabilities
  }
}
