import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../models/jukebox_soundfont.dart';
import 'soundfont_storage_service.dart';

enum SoundFontDownloadResult { success, cancelled, hashMismatch, error }

class SoundFontDownloadService {
  static Future<SoundFontDownloadResult> download({
    required String soundfontsDir,
    required JukeboxSoundFont sf,
    required CancelToken cancelToken,
    void Function(int received, int total)? onProgress,
  }) async {
    final partFile = File(SoundFontStorageService.partialPath(soundfontsDir, sf));
    final finalFile = File(SoundFontStorageService.soundFontPath(soundfontsDir, sf));
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
        sf.downloadUrl!,
        options: options,
        cancelToken: cancelToken,
      );

      final sink = partFile.openWrite(
        mode: existingBytes > 0 ? FileMode.append : FileMode.write,
      );
      int received = existingBytes;

      try {
        await for (final chunk in response.data!.stream) {
          sink.add(chunk);
          received += chunk.length;
          onProgress?.call(received, sf.fileSizeBytes);
        }
      } finally {
        await sink.close();
      }

      // SHA-256 verification
      final hash = await _computeSha256(partFile);
      if (sf.sha256 == null) {
        debugPrint('WARNING: SoundFont ${sf.id} has no SHA-256 hash — accepting download without verification');
      } else if (hash != sf.sha256) {
        debugPrint('SoundFont hash mismatch: expected ${sf.sha256}, got $hash');
        await partFile.delete();
        return SoundFontDownloadResult.hashMismatch;
      }

      await partFile.rename(finalFile.path);
      return SoundFontDownloadResult.success;
    } on DioException catch (e) {
      if (CancelToken.isCancel(e)) {
        return SoundFontDownloadResult.cancelled;
      }
      debugPrint('SoundFont download error: $e');
      return SoundFontDownloadResult.error;
    } catch (e) {
      debugPrint('SoundFont download error: $e');
      return SoundFontDownloadResult.error;
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
