import 'dart:io';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

/// Image extensions for manual filtering when using FileType.any.
const _imageExtensions = {'.png', '.jpg', '.jpeg', '.webp', '.bmp', '.gif'};

bool _isAndroid() => !kIsWeb && Platform.isAndroid;

/// Picks image files using the platform media picker.
///
/// By default uses [FileType.image] so Android shows the gallery picker.
/// Set [useFileBrowser] to true to use [FileType.any] instead, which opens
/// the document browser showing all apps (ZArchiver, FStop, etc.) but with
/// a less image-friendly UI. Results are filtered by image extension.
Future<FilePickerResult?> pickImageFiles({
  bool allowMultiple = false,
  bool withData = false,
  bool useFileBrowser = false,
}) async {
  // Web has no file paths: the picked bytes are only available when the
  // picker is asked to load them, so force it there.
  final effectiveWithData = kIsWeb || withData;
  if (useFileBrowser && _isAndroid()) {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.any,
      allowMultiple: allowMultiple,
      withData: effectiveWithData,
      compressionQuality: 0,
    );
    if (result == null) return null;
    final filtered = result.files.where((f) {
      if (f.path == null) return false;
      final ext = f.path!.toLowerCase();
      return _imageExtensions.any((e) => ext.endsWith(e));
    }).toList();
    return filtered.isEmpty ? null : FilePickerResult(filtered);
  }
  return FilePicker.platform.pickFiles(
    type: FileType.image,
    allowMultiple: allowMultiple,
    withData: effectiveWithData,
    // file_picker 8.x defaults compressionQuality to 30, which forces a
    // JPEG re-encode on Android for image/* MIME and destroys PNG metadata
    // chunks (NovelAI Comment, etc.). Disable to preserve original bytes.
    compressionQuality: 0,
  );
}

/// Reads the bytes of a picked file, whichever way the platform delivered
/// them: in-memory `bytes` (web, or `withData: true`) or a filesystem path.
/// Returns null when neither is available.
Future<Uint8List?> readPickedFileBytes(PlatformFile file) async {
  if (file.bytes != null) return file.bytes;
  final path = file.path;
  if (path == null) return null;
  return File(path).readAsBytes();
}

/// Picks files with custom extensions, using [FileType.any] on Android
/// (where [FileType.custom] can fail) with manual extension filtering.
Future<FilePickerResult?> pickCustomFiles({
  required List<String> allowedExtensions,
  bool allowMultiple = false,
  bool withData = false,
}) async {
  final android = _isAndroid();
  final result = await FilePicker.platform.pickFiles(
    type: android ? FileType.any : FileType.custom,
    allowedExtensions: android ? null : allowedExtensions,
    allowMultiple: allowMultiple,
    withData: kIsWeb || withData,
  );
  if (result == null || !android) return result;

  final exts = allowedExtensions.map((e) => '.$e'.toLowerCase()).toSet();
  final filtered = result.files.where((f) {
    if (f.path == null) return false;
    final path = f.path!.toLowerCase();
    return exts.any((e) => path.endsWith(e));
  }).toList();

  return filtered.isEmpty ? null : FilePickerResult(filtered);
}
