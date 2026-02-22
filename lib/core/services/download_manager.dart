import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

/// Generic download status shared across ML models, soundfonts, etc.
enum DownloadStatus { idle, downloading, completed, error }

/// Generic download result shared across download services.
enum DownloadResult { success, cancelled, hashMismatch, error }

/// Immutable state for a single download.
class DownloadState {
  final DownloadStatus status;
  final double progress;
  final String? errorMessage;

  const DownloadState({
    this.status = DownloadStatus.idle,
    this.progress = 0.0,
    this.errorMessage,
  });
}

/// Manages download state, cancel tokens, and completed IDs for a category of
/// downloadable items.
///
/// Mix this into a ChangeNotifier or use as a delegate. Call [disposeDownloads]
/// from your notifier's `dispose()`.
class DownloadManager {
  final Map<String, DownloadState> _states = {};
  final Map<String, CancelToken> _cancelTokens = {};
  final Set<String> _completedIds = {};

  /// Returns the current download state for [id], or idle if unknown.
  DownloadState state(String id) =>
      _states[id] ?? const DownloadState();

  /// Whether [id] has been fully downloaded.
  bool isCompleted(String id) => _completedIds.contains(id);

  /// Mark [id] as completed (e.g. after scanning the filesystem on init).
  void markCompleted(String id) => _completedIds.add(id);

  /// Whether [id] is currently downloading.
  bool isDownloading(String id) => _cancelTokens.containsKey(id);

  /// Start a download for [id].
  ///
  /// [downloadFn] is the actual download logic; it receives a [CancelToken]
  /// and a progress callback `(int received, int total)`.
  /// It must return a [DownloadResult].
  ///
  /// [onNotify] is called whenever listeners should be notified (pass
  /// `notifyListeners` from your ChangeNotifier).
  ///
  /// [onSuccess] is an optional callback for domain-specific post-download
  /// logic (e.g. auto-select model).
  Future<void> download({
    required String id,
    required Future<DownloadResult> Function(
      CancelToken cancelToken,
      void Function(int received, int total) onProgress,
    ) downloadFn,
    required VoidCallback onNotify,
    VoidCallback? onSuccess,
  }) async {
    if (_cancelTokens.containsKey(id)) return; // already in progress

    final cancelToken = CancelToken();
    _cancelTokens[id] = cancelToken;
    _states[id] = const DownloadState(status: DownloadStatus.downloading);
    onNotify();

    final result = await downloadFn(
      cancelToken,
      (received, total) {
        _states[id] = DownloadState(
          status: DownloadStatus.downloading,
          progress: total > 0 ? received / total : 0.0,
        );
        onNotify();
      },
    );

    _cancelTokens.remove(id);

    switch (result) {
      case DownloadResult.success:
        _completedIds.add(id);
        _states[id] = const DownloadState(status: DownloadStatus.completed);
        onSuccess?.call();
      case DownloadResult.cancelled:
        _states[id] = const DownloadState(); // back to idle
      case DownloadResult.hashMismatch:
        _states[id] = const DownloadState(
          status: DownloadStatus.error,
          errorMessage: 'Hash verification failed',
        );
      case DownloadResult.error:
        _states[id] = const DownloadState(
          status: DownloadStatus.error,
          errorMessage: 'Download failed',
        );
    }
    onNotify();
  }

  /// Cancel an in-progress download.
  void cancel(String id) {
    _cancelTokens[id]?.cancel();
    _cancelTokens.remove(id);
  }

  /// Remove a completed download from tracking.
  /// Caller should delete files before calling this.
  void remove(String id) {
    _completedIds.remove(id);
    _states.remove(id);
  }

  /// Cancel all in-flight downloads. Call from your notifier's dispose().
  void disposeDownloads() {
    for (final token in _cancelTokens.values) {
      token.cancel();
    }
    _cancelTokens.clear();
  }
}
