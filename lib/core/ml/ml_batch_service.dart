import 'dart:typed_data';
import 'ml_background_removal_service.dart';
import 'ml_upscale_service.dart';

enum MLBatchStatus { pending, processing, completed, error }

enum MLBatchOperation { removeBackground, upscale }

class MLBatchItem {
  final String id;
  final Uint8List imageBytes;
  final String sourceName;
  MLBatchStatus status;
  Uint8List? resultBytes;
  String? error;

  MLBatchItem({
    required this.id,
    required this.imageBytes,
    required this.sourceName,
    this.status = MLBatchStatus.pending,
    this.resultBytes,
    this.error,
  });
}

class MLBatchService {
  final MLBackgroundRemovalService _bgRemovalService;
  final MLUpscaleService _upscaleService;

  final List<MLBatchItem> _queue = [];
  MLBatchOperation? _operation;
  bool _cancelled = false;

  MLBatchService({
    required MLBackgroundRemovalService bgRemovalService,
    required MLUpscaleService upscaleService,
  })  : _bgRemovalService = bgRemovalService,
        _upscaleService = upscaleService;

  List<MLBatchItem> get results => List.unmodifiable(_queue);

  void addToQueue(List<MLBatchItem> items, MLBatchOperation operation) {
    _queue.addAll(items);
    _operation = operation;
  }

  Future<void> processQueue({
    String? bgModelId,
    String? upscaleModelId,
    void Function(int completed, int total)? onProgress,
  }) async {
    _cancelled = false;
    int completed = 0;
    final total = _queue.length;

    for (final item in _queue) {
      if (_cancelled) break;

      item.status = MLBatchStatus.processing;

      try {
        Uint8List? result;

        switch (_operation!) {
          case MLBatchOperation.removeBackground:
            if (bgModelId == null) throw Exception('No BG model selected');
            final bgResult = await _bgRemovalService.removeBackground(
              item.imageBytes,
              bgModelId,
            );
            result = bgResult?.resultImage;

          case MLBatchOperation.upscale:
            if (upscaleModelId == null) throw Exception('No upscale model selected');
            result = await _upscaleService.upscale(
              item.imageBytes,
              upscaleModelId,
            );
        }

        if (result != null) {
          item.resultBytes = result;
          item.status = MLBatchStatus.completed;
        } else {
          item.error = 'Processing returned null';
          item.status = MLBatchStatus.error;
        }
      } catch (e) {
        item.error = e.toString();
        item.status = MLBatchStatus.error;
      }

      completed++;
      onProgress?.call(completed, total);
    }
  }

  void cancelBatch() {
    _cancelled = true;
  }
}
