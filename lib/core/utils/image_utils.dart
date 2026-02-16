import 'dart:convert';
import 'dart:typed_data';
import 'package:image/image.dart' as img;

/// Helper to inject metadata into PNG bytes.
/// This runs in a separate isolate via compute.
Uint8List injectMetadata(Map<String, dynamic> data) {
  final bytes = data['bytes'] as Uint8List;
  final metadata = data['metadata'] as Map<String, dynamic>;

  final image = img.decodePng(bytes);
  if (image == null) return bytes;

  // Add NovelAI official metadata chunks
  final Map<String, String> textChunks = {
    'Title': 'NovelAI generated image',
    'Description': metadata['prompt'] ?? '',
    'Software': 'NovelAI',
    'Source': 'NovelAI Diffusion V4.5 4BDE2A90',
    // NovelAI stores full generation parameters in the Comment field as JSON
    'Comment': jsonEncode(metadata),
  };

  final encoder = img.PngEncoder();
  encoder.textData = textChunks;

  return Uint8List.fromList(encoder.encode(image));
}

/// Helper to extract metadata from PNG bytes.
/// This runs in a separate isolate via compute.
Map<String, String>? extractMetadata(Uint8List bytes) {
  final image = img.decodePng(bytes);
  if (image == null) return null;
  return image.textData;
}

/// Strips all text metadata (Title, Description, Comment, etc.) from PNG bytes.
/// Re-encodes the image without any text chunks.
Uint8List stripMetadata(Uint8List bytes) {
  final image = img.decodePng(bytes);
  if (image == null) return bytes;

  final encoder = img.PngEncoder();
  encoder.textData = {};
  return Uint8List.fromList(encoder.encode(image));
}

/// Checks if bytes represent a PNG file by inspecting the 8-byte magic header.
bool isPng(Uint8List bytes) {
  if (bytes.length < 8) return false;
  return bytes[0] == 0x89 &&
      bytes[1] == 0x50 &&
      bytes[2] == 0x4E &&
      bytes[3] == 0x47 &&
      bytes[4] == 0x0D &&
      bytes[5] == 0x0A &&
      bytes[6] == 0x1A &&
      bytes[7] == 0x0A;
}

/// Converts non-PNG image bytes to PNG format.
/// Returns null if the image format is unsupported.
/// Intended for use via compute() in an isolate.
Uint8List? convertToPng(Uint8List bytes) {
  final image = img.decodeImage(bytes);
  if (image == null) return null;
  return Uint8List.fromList(img.encodePng(image));
}

/// Converts image bytes to PNG while preserving metadata from the original source.
/// [data] must contain 'bytes' (possibly-transcoded) and 'originalBytes' (raw source).
/// Extracts text chunks from originalBytes (if valid PNG) and re-injects them.
/// Intended for use via compute() in an isolate.
Uint8List? convertToPngPreservingMetadata(Map<String, dynamic> data) {
  final bytes = data['bytes'] as Uint8List;
  final originalBytes = data['originalBytes'] as Uint8List;

  // Try to extract metadata from the original source
  final origImage = img.decodePng(originalBytes);
  final textData = origImage?.textData;

  // Decode the (possibly-transcoded) bytes
  final image = img.decodeImage(bytes);
  if (image == null) return null;

  final encoder = img.PngEncoder();
  if (textData != null && textData.isNotEmpty) {
    encoder.textData = textData;
  }
  return Uint8List.fromList(encoder.encode(image));
}

/// Parses the JSON from a PNG Comment chunk.
/// Tries direct decode first, falls back to trimming trailing garbage.
Map<String, dynamic>? parseCommentJson(String comment) {
  try {
    return jsonDecode(comment);
  } catch (_) {
    final end = comment.lastIndexOf('}');
    if (end < 0) return null;
    try {
      return jsonDecode(comment.substring(0, end + 1));
    } catch (_) {
      return null;
    }
  }
}
