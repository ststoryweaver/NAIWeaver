import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../services/download_manager.dart';
import 'ml_model_entry.dart';
import 'ml_storage_service.dart';

class MLDownloadService {
  static Future<DownloadResult> download({
    required String mlModelsDir,
    required MLModelEntry entry,
    required CancelToken cancelToken,
    void Function(int received, int total)? onProgress,
  }) async {
    final partFile = File(MLStorageService.partialPath(mlModelsDir, entry));
    final finalFile = File(MLStorageService.modelPath(mlModelsDir, entry));
    final dio = Dio();

    try {
      int existingBytes = 0;
      if (await partFile.exists()) {
        existingBytes = await partFile.length();
      }

      final options = Options(
        responseType: ResponseType.stream,
        headers: existingBytes > 0
            ? {'Range': 'bytes=$existingBytes-'}
            : null,
      );

      final response = await dio.get<ResponseBody>(
        entry.downloadUrl,
        options: options,
        cancelToken: cancelToken,
      );

      final sink = partFile.openWrite(mode: existingBytes > 0 ? FileMode.append : FileMode.write);
      int received = existingBytes;

      try {
        await for (final chunk in response.data!.stream) {
          sink.add(chunk);
          received += chunk.length;
          onProgress?.call(received, entry.fileSizeBytes);
        }
      } finally {
        await sink.close();
      }

      // SHA-256 verification (streaming)
      final hash = await _computeSha256(partFile);
      if (hash != entry.sha256) {
        debugPrint('ML model hash mismatch: expected ${entry.sha256}, got $hash');
        await partFile.delete();
        return DownloadResult.hashMismatch;
      }

      await partFile.rename(finalFile.path);
      return DownloadResult.success;
    } on DioException catch (e) {
      if (CancelToken.isCancel(e)) {
        return DownloadResult.cancelled;
      }
      debugPrint('ML model download error: $e');
      return DownloadResult.error;
    } catch (e) {
      debugPrint('ML model download error: $e');
      return DownloadResult.error;
    } finally {
      dio.close();
    }
  }

  static Future<String> _computeSha256(File file) async {
    final stream = file.openRead();
    final digest = await sha256.bind(stream).first;
    return digest.toString();
  }
}
