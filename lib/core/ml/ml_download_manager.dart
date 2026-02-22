import 'package:flutter/foundation.dart';
import '../services/download_manager.dart';
import 'ml_device_capabilities.dart';
import 'ml_model_entry.dart';
import 'ml_model_registry.dart';
import 'ml_storage_service.dart';
import 'ml_download_service.dart';
import 'ml_inference_service.dart';

/// Manages ML model download state, filesystem scanning, sequential download
/// queue, and model availability queries.
///
/// This wraps the generic [DownloadManager] with ML-specific concerns:
/// sequential queuing, scan-on-init, tier-based best-model lookup, and
/// filesystem deletion with session unloading.
///
/// Auto-selection and tier-upgrade logic remain in [MLNotifier] because they
/// depend on notifier state. The notifier passes callbacks via [onSuccess]
/// parameters when starting downloads.
class MLDownloadManager {
  final String mlModelsDir;
  final DownloadManager _downloads = DownloadManager();
  final MLInferenceService _inferenceService;

  final List<MLModelEntry> _downloadQueue = [];
  bool _isDownloading = false;

  MLDownloadManager({
    required this.mlModelsDir,
    required MLInferenceService inferenceService,
  }) : _inferenceService = inferenceService;

  // ---------------------------------------------------------------------------
  // Delegate to DownloadManager
  // ---------------------------------------------------------------------------

  /// Returns the current [DownloadState] for [modelId].
  DownloadState downloadState(String modelId) => _downloads.state(modelId);

  /// Whether [modelId] has been fully downloaded (or was found on disk).
  bool isModelDownloaded(String modelId) => _downloads.isCompleted(modelId);

  /// Whether [modelId] is currently being downloaded.
  bool isDownloading(String modelId) => _downloads.isDownloading(modelId);

  /// Mark [modelId] as completed (used during filesystem scan).
  void markCompleted(String id) => _downloads.markCompleted(id);

  // ---------------------------------------------------------------------------
  // Availability queries
  // ---------------------------------------------------------------------------

  /// Whether at least one background-removal model is downloaded.
  bool get hasBgRemovalModel =>
      MLModelRegistry.backgroundRemovalModels.any((e) => _downloads.isCompleted(e.id));

  /// Whether at least one upscale model is downloaded.
  bool get hasUpscaleModel =>
      MLModelRegistry.upscaleModels.any((e) => _downloads.isCompleted(e.id));

  /// Whether a complete segmentation pair (encoder + decoder) is downloaded.
  bool get hasSegmentationModel {
    for (final entry in MLModelRegistry.segmentationModels) {
      if (entry.id.contains('encoder') && _downloads.isCompleted(entry.id)) {
        final decoderId = MLModelRegistry.pairedDecoderId(entry.id);
        if (decoderId != null && _downloads.isCompleted(decoderId)) return true;
      }
    }
    return false;
  }

  // ---------------------------------------------------------------------------
  // Filesystem scan
  // ---------------------------------------------------------------------------

  /// Scan the models directory and mark every already-downloaded model as
  /// completed in the download manager.
  Future<void> scanDownloaded() async {
    for (final entry in MLModelRegistry.all) {
      if (await MLStorageService.isDownloaded(mlModelsDir, entry)) {
        _downloads.markCompleted(entry.id);
      }
    }
  }

  // ---------------------------------------------------------------------------
  // Sequential download queue
  // ---------------------------------------------------------------------------

  /// Queue [entry] for download.
  ///
  /// [onNotify] is called whenever listeners should be notified (typically
  /// `notifyListeners` from a ChangeNotifier).
  ///
  /// [onSuccess] is invoked after a successful download (used by MLNotifier
  /// for auto-selection).
  Future<void> downloadModel(
    MLModelEntry entry, {
    required VoidCallback onNotify,
    VoidCallback? onSuccess,
  }) async {
    _downloadQueue.add(entry);
    onNotify();
    _processDownloadQueue(onNotify: onNotify, onSuccess: onSuccess);
  }

  Future<void> _processDownloadQueue({
    required VoidCallback onNotify,
    VoidCallback? onSuccess,
  }) async {
    if (_isDownloading || _downloadQueue.isEmpty) return;
    _isDownloading = true;

    while (_downloadQueue.isNotEmpty) {
      final entry = _downloadQueue.removeAt(0);

      if (_downloads.isDownloading(entry.id)) continue;

      await _downloads.download(
        id: entry.id,
        downloadFn: (cancelToken, onProgress) => MLDownloadService.download(
          mlModelsDir: mlModelsDir,
          entry: entry,
          cancelToken: cancelToken,
          onProgress: onProgress,
        ),
        onNotify: onNotify,
        onSuccess: onSuccess,
      );
    }

    _isDownloading = false;
  }

  /// Cancel an in-progress or queued download.
  void cancelDownload(String modelId) {
    _downloads.cancel(modelId);
    _downloadQueue.removeWhere((e) => e.id == modelId);
  }

  /// Delete a downloaded model from disk and unload its inference session.
  ///
  /// The caller is responsible for re-selecting models after deletion.
  Future<void> deleteModel(MLModelEntry entry) async {
    await _inferenceService.unloadModel(entry.id);
    await MLStorageService.delete(mlModelsDir, entry);
    await MLStorageService.deletePartial(mlModelsDir, entry);
    _downloads.remove(entry.id);
  }

  // ---------------------------------------------------------------------------
  // Model lookup helpers
  // ---------------------------------------------------------------------------

  /// Returns the first downloaded model ID for [type], or `null`.
  String? findFirstDownloaded(MLModelType type) {
    for (final entry in MLModelRegistry.byType(type)) {
      if (_downloads.isCompleted(entry.id)) return entry.id;
    }
    return null;
  }

  /// Returns the best downloaded model ID for [type] considering device
  /// capabilities, or `null`.
  ///
  /// Prefers models whose [MLModelEntry.deviceTier] matches the recommended
  /// tier for the current device.
  String? findBestDownloaded(MLModelType type, MLDeviceCapabilities? caps) {
    final models = MLModelRegistry.byType(type)
        .where((e) => _downloads.isCompleted(e.id))
        .toList();
    if (models.isEmpty) return null;

    if (caps != null) {
      final recommendedTier = caps.recommendedTier;
      final tierMatch = models.where((e) =>
          e.deviceTier == recommendedTier || e.deviceTier == MLDeviceTier.both);
      if (tierMatch.isNotEmpty) return tierMatch.first.id;
    }

    return models.first.id;
  }

  /// Returns the first downloaded segmentation encoder ID, or `null`.
  String? findSegmentationEncoder() {
    for (final entry in MLModelRegistry.segmentationModels) {
      if (entry.id.contains('encoder') && _downloads.isCompleted(entry.id)) {
        return entry.id;
      }
    }
    return null;
  }

  /// Returns the decoder ID paired with the first downloaded encoder, or
  /// `null`.
  String? findSegmentationDecoder() {
    final encoderId = findSegmentationEncoder();
    if (encoderId == null) return null;
    return MLModelRegistry.pairedDecoderId(encoderId);
  }

  // ---------------------------------------------------------------------------
  // Lifecycle
  // ---------------------------------------------------------------------------

  /// Cancel all in-flight downloads. Call from your notifier's `dispose()`.
  void disposeDownloads() => _downloads.disposeDownloads();
}
