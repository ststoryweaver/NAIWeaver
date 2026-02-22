import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import '../../../core/utils/image_utils.dart';
import '../providers/gallery_notifier.dart';

class GalleryImportService {
  /// Import files into the gallery output directory.
  ///
  /// For each successfully imported file, [onFileImported] is called with the
  /// destination [File] and its source modification date, allowing the caller
  /// to register the file in the gallery.
  Future<ImportResult> importFiles(
    List<String> filePaths, {
    required String outputDir,
    required void Function(File file, DateTime date) onFileImported,
    void Function(int current, int total)? onProgress,
  }) async {
    final fmt = DateFormat('yyyyMMdd_HHmmssSSS');
    int succeeded = 0;
    int withMetadata = 0;
    int converted = 0;
    final errors = <String>[];

    for (int i = 0; i < filePaths.length; i++) {
      onProgress?.call(i + 1, filePaths.length);
      try {
        final srcFile = File(filePaths[i]);
        final bytes = await srcFile.readAsBytes();
        Uint8List pngBytes;

        if (isPng(bytes)) {
          pngBytes = bytes;
        } else {
          // Check if the original file had a .png extension — Android's photo
          // picker may have transcoded it, losing PNG metadata chunks.
          final ext = p.extension(filePaths[i]).toLowerCase();
          if (ext == '.png') {
            // Source claimed to be PNG but bytes aren't — likely transcoded.
            // Try to recover metadata from original bytes and re-inject.
            final result = await compute(convertToPngPreservingMetadata, {
              'bytes': bytes,
              'originalBytes': bytes,
            });
            if (result == null) {
              errors.add(p.basename(filePaths[i]));
              continue;
            }
            pngBytes = result;
          } else {
            final result = await compute(convertToPng, bytes);
            if (result == null) {
              errors.add(p.basename(filePaths[i]));
              continue;
            }
            pngBytes = result;
          }
          converted++;
        }

        // Extract original date from EXIF metadata, falling back to file stat
        final srcStat = await srcFile.stat();
        final extractedDateStr = await compute(extractOriginalDate, {
          'bytes': bytes,
          'statModified': srcStat.modified.toIso8601String(),
        });
        final sourceDate = DateTime.parse(extractedDateStr);

        // Inject OriginalDate chunk into PNG for refresh resilience
        pngBytes = await compute(injectOriginalDate, {
          'bytes': pngBytes,
          'date': sourceDate.toIso8601String(),
        });

        final now = DateTime.now();
        final destName = 'Imp_${fmt.format(now)}.png';
        final destPath = p.join(outputDir, destName);
        final destFile = File(destPath);
        await destFile.writeAsBytes(pngBytes);
        await destFile.setLastModified(sourceDate);

        onFileImported(destFile, sourceDate);

        // Check for NovelAI metadata
        final metadata = await compute(extractMetadata, pngBytes);
        if (metadata != null && metadata.containsKey('Comment')) {
          withMetadata++;
        }

        succeeded++;
      } catch (e) {
        errors.add(p.basename(filePaths[i]));
      }
    }

    return ImportResult(
      total: filePaths.length,
      succeeded: succeeded,
      withMetadata: withMetadata,
      converted: converted,
      errors: errors,
    );
  }
}
