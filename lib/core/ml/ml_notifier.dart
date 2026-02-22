import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import '../services/download_manager.dart';
import '../services/preferences_service.dart';
import 'ml_batch_service.dart';
import 'ml_device_capabilities.dart';
import 'ml_download_manager.dart';
import 'ml_model_entry.dart';
import 'ml_model_registry.dart';
import 'ml_inference_service.dart';
import 'ml_storage_service.dart';
import 'ml_background_removal_service.dart';
import 'ml_upscale_service.dart';
import 'ml_segmentation_service.dart';

class MLNotifier extends ChangeNotifier with WidgetsBindingObserver {
  final String mlModelsDir;
  final PreferencesService _prefs;

  late final MLDownloadManager _dlManager;

  String? _selectedBgRemovalModelId;
  String? _selectedUpscaleModelId;
  String? _selectedSegmentationModelId;

  // — Inference services —
  late final MLInferenceService _inferenceService;
  late final MLBackgroundRemovalService _bgRemovalService;
  late final MLUpscaleService _upscaleService;
  late final MLSegmentationService _segmentationService;

  // — Device capabilities —
  MLDeviceCapabilities? _deviceCapabilities;

  // — Processing state —
  bool _isProcessing = false;
  double _processingProgress = 0.0;
  String _processingStage = '';
  String? _processingError;
  BGRemovalResult? _lastBgResult;

  // — Segmentation state —
  SAMEmbeddingResult? _samEmbeddings;
  SAMSegmentResult? _lastSegResult;

  // — Batch state —
  bool _isBatchProcessing = false;
  int _batchTotal = 0;
  int _batchCompleted = 0;
  final List<MLBatchItem> _batchResults = [];
  MLBatchService? _batchService;

  MLNotifier({required this.mlModelsDir, required PreferencesService prefs})
      : _prefs = prefs {
    _inferenceService = MLInferenceService(mlModelsDir: mlModelsDir);
    _dlManager = MLDownloadManager(
      mlModelsDir: mlModelsDir,
      inferenceService: _inferenceService,
    );
    _bgRemovalService = MLBackgroundRemovalService(_inferenceService);
    _upscaleService = MLUpscaleService(_inferenceService);
    _segmentationService = MLSegmentationService(_inferenceService);

    _selectedBgRemovalModelId = _prefs.selectedBgRemovalModel;
    _selectedUpscaleModelId = _prefs.selectedUpscaleModel;
    _selectedSegmentationModelId = _prefs.selectedSegmentationModel;

    WidgetsBinding.instance.addObserver(this);
    _init();
  }

  Future<void> _init() async {
    _migrateLegacyPreferences();
    await _scanDownloaded();
    await _detectCapabilities();
    // Clean up stale partial downloads (>24h old)
    MLStorageService.cleanupStalePartials(mlModelsDir);
  }

  void _migrateLegacyPreferences() {
    if (_selectedBgRemovalModelId != null &&
        MLModelRegistry.legacyModelIds.contains(_selectedBgRemovalModelId)) {
      _selectedBgRemovalModelId = null;
      _prefs.setSelectedBgRemovalModel(null);
    }
    if (_selectedUpscaleModelId != null &&
        MLModelRegistry.legacyModelIds.contains(_selectedUpscaleModelId)) {
      _selectedUpscaleModelId = null;
      _prefs.setSelectedUpscaleModel(null);
    }
    if (_selectedSegmentationModelId != null &&
        MLModelRegistry.legacyModelIds.contains(_selectedSegmentationModelId)) {
      _selectedSegmentationModelId = null;
      _prefs.setSelectedSegmentationModel(null);
    }
  }

  // — Device capabilities —

  MLDeviceCapabilities? get deviceCapabilities => _deviceCapabilities;

  Future<void> _detectCapabilities() async {
    _deviceCapabilities = await _inferenceService.detectCapabilities();
    notifyListeners();
  }

  // — Download state (delegated to MLDownloadManager) —

  DownloadState downloadState(String modelId) => _dlManager.downloadState(modelId);

  bool isModelDownloaded(String modelId) => _dlManager.isModelDownloaded(modelId);

  bool get hasBgRemovalModel => _dlManager.hasBgRemovalModel;

  bool get hasUpscaleModel => _dlManager.hasUpscaleModel;

  bool get hasSegmentationModel => _dlManager.hasSegmentationModel;

  // — Model selection —

  String? get selectedBgRemovalModelId => _selectedBgRemovalModelId;
  String? get selectedUpscaleModelId => _selectedUpscaleModelId;
  String? get selectedSegmentationModelId => _selectedSegmentationModelId;

  void selectBgRemovalModel(String? id) {
    _selectedBgRemovalModelId = id;
    _prefs.setSelectedBgRemovalModel(id);
    notifyListeners();
  }

  void selectUpscaleModel(String? id) {
    _selectedUpscaleModelId = id;
    _prefs.setSelectedUpscaleModel(id);
    notifyListeners();
  }

  void selectSegmentationModel(String? id) {
    // SAM 2.1 crashes on Android — never select segmentation there
    if (id != null && defaultTargetPlatform == TargetPlatform.android) return;
    _selectedSegmentationModelId = id;
    _prefs.setSelectedSegmentationModel(id);
    notifyListeners();
  }

  // — Processing state getters —

  bool get isProcessing => _isProcessing;
  double get processingProgress => _processingProgress;
  String get processingStage => _processingStage;
  String? get processingError => _processingError;
  BGRemovalResult? get lastBgResult => _lastBgResult;

  // — Segmentation state getters —

  SAMEmbeddingResult? get samEmbeddings => _samEmbeddings;
  SAMSegmentResult? get lastSegResult => _lastSegResult;
  bool get hasEncodedImage => _samEmbeddings != null;

  // — Batch state getters —

  bool get isBatchProcessing => _isBatchProcessing;
  int get batchTotal => _batchTotal;
  int get batchCompleted => _batchCompleted;
  List<MLBatchItem> get batchResults => List.unmodifiable(_batchResults);

  // — High-level ML operations —

  Future<Uint8List?> removeBackground(Uint8List imageBytes) async {
    final modelId = _selectedBgRemovalModelId;
    if (modelId == null || _isProcessing) return null;

    _isProcessing = true;
    _processingError = null;
    _processingProgress = 0.0;
    _processingStage = 'Starting...';
    notifyListeners();

    try {
      final result = await _bgRemovalService.removeBackground(
        imageBytes,
        modelId,
        onProgress: (stage, progress) {
          _processingStage = stage;
          _processingProgress = progress;
          notifyListeners();
        },
      );

      if (result == null) {
        _processingError = 'Background removal failed';
        return null;
      }

      _lastBgResult = result;
      return result.resultImage;
    } catch (e) {
      _processingError = e.toString();
      debugPrint('ML: Background removal error: $e');
      return null;
    } finally {
      _isProcessing = false;
      notifyListeners();
    }
  }

  Future<Uint8List?> upscaleImage(Uint8List imageBytes) async {
    final modelId = _selectedUpscaleModelId;
    if (modelId == null || _isProcessing) return null;

    _isProcessing = true;
    _processingError = null;
    _processingProgress = 0.0;
    _processingStage = 'Starting...';
    notifyListeners();

    try {
      final result = await _upscaleService.upscale(
        imageBytes,
        modelId,
        onProgress: (stage, progress) {
          _processingStage = stage;
          _processingProgress = progress;
          notifyListeners();
        },
      );

      if (result == null) {
        _processingError = 'Upscaling failed';
      }

      return result;
    } catch (e) {
      _processingError = e.toString();
      debugPrint('ML: Upscale error: $e');
      return null;
    } finally {
      _isProcessing = false;
      notifyListeners();
    }
  }

  Future<Uint8List> reapplyBgMask({
    double threshold = 0.5,
    double featherRadius = 0,
  }) async {
    final result = _lastBgResult;
    if (result == null) throw Exception('No BG removal result cached');

    return MLBackgroundRemovalService.reapplyMask(
      originalBytes: result.originalImage,
      maskBytes: result.rawMask,
      threshold: threshold,
      featherRadius: featherRadius.round(),
    );
  }

  Future<Uint8List> reapplyBgMatte({
    double opacityMultiplier = 1.0,
    double edgeRefinementRadius = 0,
  }) async {
    final result = _lastBgResult;
    if (result == null) throw Exception('No BG removal result cached');

    return MLBackgroundRemovalService.reapplyAlphaMatte(
      originalBytes: result.originalImage,
      matteBytes: result.rawMask,
      opacityMultiplier: opacityMultiplier,
      edgeRefinementRadius: edgeRefinementRadius.round(),
    );
  }

  void clearBgResult() {
    _lastBgResult = null;
    notifyListeners();
  }

  void clearProcessingError() {
    _processingError = null;
    notifyListeners();
  }

  Future<void> unloadModels() async {
    await _inferenceService.unloadAll();
  }

  // — Segmentation operations —

  Future<SAMEmbeddingResult?> encodeImageForSegmentation(Uint8List imageBytes) async {
    final encoderModelId = _dlManager.findSegmentationEncoder();
    if (encoderModelId == null || _isProcessing) return null;

    _isProcessing = true;
    _processingError = null;
    _processingProgress = 0.0;
    _processingStage = 'Encoding image...';
    notifyListeners();

    try {
      final result = await _segmentationService.encodeImage(
        imageBytes,
        encoderModelId,
        onProgress: (stage, progress) {
          _processingStage = stage;
          _processingProgress = progress;
          notifyListeners();
        },
      );

      _samEmbeddings = result;
      return result;
    } catch (e) {
      _processingError = e.toString();
      debugPrint('ML: Segmentation encoding error: $e');
      return null;
    } finally {
      _isProcessing = false;
      notifyListeners();
    }
  }

  Future<SAMSegmentResult?> segmentAtPoints({
    required List<Offset> positivePoints,
    required List<Offset> negativePoints,
    Rect? boxSelection,
    Float32List? previousMaskLogits,
    List<int>? previousMaskShape,
  }) async {
    if (_samEmbeddings == null) return null;

    final decoderModelId = _dlManager.findSegmentationDecoder();
    if (decoderModelId == null) return null;

    try {
      final result = await _segmentationService.decodeMask(
        embeddings: _samEmbeddings!,
        decoderModelId: decoderModelId,
        positivePoints: positivePoints,
        negativePoints: negativePoints,
        boxSelection: boxSelection,
        originalImageBytes: _samEmbeddings!.originalImageBytes,
        previousMaskLogits: previousMaskLogits,
        previousMaskShape: previousMaskShape,
      );

      _lastSegResult = result;
      notifyListeners();
      return result;
    } catch (e) {
      debugPrint('ML: Segmentation decoding error: $e');
      return null;
    }
  }

  void clearSegmentation() {
    _samEmbeddings = null;
    _lastSegResult = null;
    notifyListeners();
  }

  // — Batch processing —

  Future<List<MLBatchItem>> startBatch({
    required List<MLBatchItem> items,
    required MLBatchOperation operation,
    void Function(int completed, int total)? onProgress,
  }) async {
    if (_isBatchProcessing || _isProcessing) return [];

    _isBatchProcessing = true;
    _batchTotal = items.length;
    _batchCompleted = 0;
    _batchResults.clear();
    notifyListeners();

    _batchService = MLBatchService(
      bgRemovalService: _bgRemovalService,
      upscaleService: _upscaleService,
    );

    _batchService!.addToQueue(items, operation);

    try {
      await _batchService!.processQueue(
        bgModelId: _selectedBgRemovalModelId,
        upscaleModelId: _selectedUpscaleModelId,
        onProgress: (completed, total) {
          _batchCompleted = completed;
          notifyListeners();
          onProgress?.call(completed, total);
        },
      );
    } catch (e) {
      debugPrint('ML: Batch error: $e');
    }

    final results = _batchService!.results;
    _batchResults.addAll(results);
    _isBatchProcessing = false;
    _batchService = null;
    notifyListeners();
    return results;
  }

  void cancelBatch() {
    _batchService?.cancelBatch();
  }

  // — Download operations (delegated to MLDownloadManager) —

  Future<void> downloadModel(MLModelEntry entry) async {
    await _dlManager.downloadModel(
      entry,
      onNotify: notifyListeners,
      onSuccess: () => _autoSelectIfNeeded(entry),
    );
  }

  void cancelDownload(String modelId) {
    _dlManager.cancelDownload(modelId);
  }

  Future<void> deleteModel(MLModelEntry entry) async {
    await _dlManager.deleteModel(entry);

    if (_selectedBgRemovalModelId == entry.id) {
      selectBgRemovalModel(_dlManager.findFirstDownloaded(MLModelType.backgroundRemoval));
    }
    if (_selectedUpscaleModelId == entry.id) {
      selectUpscaleModel(_dlManager.findFirstDownloaded(MLModelType.upscale));
    }
    if (_selectedSegmentationModelId == entry.id) {
      selectSegmentationModel(null);
    }

    notifyListeners();
  }

  // — Memory pressure —

  @override
  void didHaveMemoryPressure() {
    debugPrint('ML: Memory pressure detected, unloading all models');
    _inferenceService.unloadAll();
  }

  // — Internals —

  Future<void> _scanDownloaded() async {
    await _dlManager.scanDownloaded();

    // Auto-select if persisted selection is no longer valid
    if (_selectedBgRemovalModelId != null &&
        !_dlManager.isModelDownloaded(_selectedBgRemovalModelId!)) {
      selectBgRemovalModel(_dlManager.findFirstDownloaded(MLModelType.backgroundRemoval));
    }
    if (_selectedUpscaleModelId != null &&
        !_dlManager.isModelDownloaded(_selectedUpscaleModelId!)) {
      selectUpscaleModel(_dlManager.findFirstDownloaded(MLModelType.upscale));
    }
    if (_selectedSegmentationModelId != null &&
        !_dlManager.isModelDownloaded(_selectedSegmentationModelId!)) {
      selectSegmentationModel(null);
    }
    // Auto-select segmentation if both models downloaded but no selection
    // (skip on Android where SAM 2.1 crashes)
    if (_selectedSegmentationModelId == null &&
        hasSegmentationModel &&
        defaultTargetPlatform != TargetPlatform.android) {
      selectSegmentationModel(_dlManager.findSegmentationEncoder());
    }
    notifyListeners();
  }

  void _autoSelectIfNeeded(MLModelEntry entry) {
    if (entry.type == MLModelType.backgroundRemoval) {
      // Auto-select if nothing selected, or upgrade to a tier-matched model
      if (_selectedBgRemovalModelId == null) {
        selectBgRemovalModel(_dlManager.findBestDownloaded(
          MLModelType.backgroundRemoval, _deviceCapabilities));
      } else {
        _upgradeSelectionIfBetterTier(entry, MLModelType.backgroundRemoval);
      }
    } else if (entry.type == MLModelType.upscale) {
      if (_selectedUpscaleModelId == null) {
        selectUpscaleModel(_dlManager.findBestDownloaded(
          MLModelType.upscale, _deviceCapabilities));
      } else {
        _upgradeSelectionIfBetterTier(entry, MLModelType.upscale);
      }
    } else if (entry.type == MLModelType.segmentation) {
      if (_selectedSegmentationModelId == null &&
          hasSegmentationModel &&
          defaultTargetPlatform != TargetPlatform.android) {
        selectSegmentationModel(_dlManager.findSegmentationEncoder());
      }
    }
  }

  void _upgradeSelectionIfBetterTier(MLModelEntry newEntry, MLModelType type) {
    final caps = _deviceCapabilities;
    if (caps == null) return;

    final currentId = type == MLModelType.backgroundRemoval
        ? _selectedBgRemovalModelId
        : _selectedUpscaleModelId;
    if (currentId == null) return;

    final currentEntry = MLModelRegistry.findById(currentId);
    if (currentEntry == null) return;

    final recommendedTier = caps.recommendedTier;
    final currentMatchesTier = currentEntry.deviceTier == recommendedTier ||
        currentEntry.deviceTier == MLDeviceTier.both;
    final newMatchesTier = newEntry.deviceTier == recommendedTier ||
        newEntry.deviceTier == MLDeviceTier.both;

    // If current doesn't match tier but new one does, upgrade
    if (!currentMatchesTier && newMatchesTier) {
      if (type == MLModelType.backgroundRemoval) {
        selectBgRemovalModel(newEntry.id);
      } else {
        selectUpscaleModel(newEntry.id);
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _dlManager.disposeDownloads();
    _inferenceService.unloadAll();
    super.dispose();
  }
}
