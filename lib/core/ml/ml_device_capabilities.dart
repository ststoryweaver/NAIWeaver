import 'ml_model_entry.dart';

enum MLRecommendationLevel { recommended, slow, notRecommended, unavailable }

class MLDeviceCapabilities {
  final List<String> availableProviders;
  final String activeProvider;
  final bool hasGpuAcceleration;
  final int? totalRamMB;
  final String? gpuName;
  final String platform;

  const MLDeviceCapabilities({
    required this.availableProviders,
    required this.activeProvider,
    required this.hasGpuAcceleration,
    this.totalRamMB,
    this.gpuName,
    this.platform = '',
  });

  String get providerLabel {
    if (hasGpuAcceleration) {
      if (activeProvider.contains('TensorRT')) return 'GPU: TensorRT';
      if (activeProvider.contains('CUDA')) return 'GPU: CUDA';
      if (activeProvider.contains('DirectML')) return 'GPU: DirectML';
      if (activeProvider.contains('CoreML')) return 'GPU: CoreML';
      if (activeProvider.contains('NNAPI')) return 'GPU: NNAPI';
      return 'GPU: $activeProvider';
    }
    return 'CPU only';
  }

  String get deviceInfoLabel {
    final provider = providerLabel;
    if (totalRamMB != null) {
      final gb = (totalRamMB! / 1024).round();
      return '$provider \u00b7 $gb GB RAM';
    }
    return provider;
  }

  MLRecommendationLevel? recommendation(MLModelEntry entry) {
    // Platform check first
    if (!isPlatformSupported(entry)) return MLRecommendationLevel.unavailable;

    // Desktop-only models on mobile devices
    if (entry.deviceTier == MLDeviceTier.desktop && recommendedTier == MLDeviceTier.mobile) {
      return MLRecommendationLevel.unavailable;
    }

    // RAM check
    if (isLowRam(entry)) return MLRecommendationLevel.notRecommended;

    // CPU tier check (only when no GPU)
    if (!hasGpuAcceleration) {
      return switch (entry.tier) {
        MLPerformanceTier.fast => MLRecommendationLevel.recommended,
        MLPerformanceTier.balanced => MLRecommendationLevel.slow,
        MLPerformanceTier.quality => MLRecommendationLevel.notRecommended,
      };
    }

    // GPU with sufficient RAM — no label needed
    return null;
  }

  bool isLowRam(MLModelEntry entry) {
    return totalRamMB != null && entry.minRamMB != null && totalRamMB! < entry.minRamMB!;
  }

  MLPerformanceTier recommendedTierFor(MLModelEntry entry) {
    if (hasGpuAcceleration) return entry.tier;
    // On CPU, quality models may be too slow
    if (entry.tier == MLPerformanceTier.quality) {
      return MLPerformanceTier.balanced;
    }
    return entry.tier;
  }

  bool isModelRecommended(MLModelEntry entry) {
    if (hasGpuAcceleration) return true;
    return entry.tier == MLPerformanceTier.fast;
  }

  bool isPlatformSupported(MLModelEntry entry) {
    if (entry.platformFlags.isEmpty) return true;
    if (platform.isEmpty) return true;
    return entry.platformFlags.contains(platform);
  }

  bool get supportsTensorRT =>
      availableProviders.any((p) => p.contains('TensorRT') || p.contains('Tensor_RT'));

  bool isDesktopOnlyOnMobile(MLModelEntry entry) {
    return entry.deviceTier == MLDeviceTier.desktop && recommendedTier == MLDeviceTier.mobile;
  }

  MLDeviceTier get recommendedTier {
    final isDesktopPlatform =
        platform == 'windows' || platform == 'linux' || platform == 'macos';
    if (isDesktopPlatform && (totalRamMB ?? 0) >= 8192) {
      return MLDeviceTier.desktop;
    }
    return MLDeviceTier.mobile;
  }
}
