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
