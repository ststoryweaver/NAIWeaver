import 'dart:convert';
import 'dart:typed_data';
import 'package:archive/archive.dart' show ZLibDecoder;
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
/// Custom chunk parser that reads both tEXt and iTXt chunks, since the
/// `image` package's decodePng only reads tEXt.
/// This runs in a separate isolate via compute.
Map<String, String>? extractMetadata(Uint8List bytes) {
  return _extractPngTextChunks(bytes);
}

/// Parses PNG tEXt and iTXt chunks directly from raw bytes.
/// Returns null if the bytes are not a valid PNG or contain no text chunks.
Map<String, String>? _extractPngTextChunks(Uint8List bytes) {
  if (!isPng(bytes)) return null;

  final result = <String, String>{};
  var offset = 8; // Skip PNG signature

  while (offset + 12 <= bytes.length) {
    // Read chunk length (big-endian uint32)
    final length = (bytes[offset] << 24) |
        (bytes[offset + 1] << 16) |
        (bytes[offset + 2] << 8) |
        bytes[offset + 3];
    offset += 4;

    // Read chunk type
    if (offset + 4 > bytes.length) break;
    final type = String.fromCharCodes(bytes, offset, offset + 4);
    offset += 4;

    // Validate remaining data
    if (offset + length + 4 > bytes.length) break;

    final chunkData =
        Uint8List.sublistView(bytes, offset, offset + length);

    if (type == 'tEXt') {
      _parseTEXtChunk(chunkData, result);
    } else if (type == 'iTXt') {
      _parseITXtChunk(chunkData, result);
    } else if (type == 'IEND') {
      break;
    }

    offset += length + 4; // Skip data + CRC
  }

  return result.isEmpty ? null : result;
}

/// Parses a tEXt chunk: keyword \0 text (Latin-1 encoded).
void _parseTEXtChunk(Uint8List data, Map<String, String> result) {
  final nullIndex = data.indexOf(0);
  if (nullIndex < 0) return;
  final keyword = latin1.decode(data.sublist(0, nullIndex));
  final text = latin1.decode(data.sublist(nullIndex + 1));
  result[keyword] = text;
}

/// Parses an iTXt chunk:
///   keyword \0 compressionFlag(1) compressionMethod(1)
///   languageTag \0 translatedKeyword \0 text
void _parseITXtChunk(Uint8List data, Map<String, String> result) {
  final nullIndex = data.indexOf(0);
  if (nullIndex < 0 || nullIndex + 2 >= data.length) return;

  final keyword = utf8.decode(data.sublist(0, nullIndex));
  final compressionFlag = data[nullIndex + 1];
  // compressionMethod at data[nullIndex + 2] (0 = zlib)

  // Find end of language tag
  final langEnd = data.indexOf(0, nullIndex + 3);
  if (langEnd < 0) return;

  // Find end of translated keyword
  final transEnd = data.indexOf(0, langEnd + 1);
  if (transEnd < 0) return;

  final textBytes = data.sublist(transEnd + 1);

  String text;
  if (compressionFlag == 1) {
    try {
      final decompressed = const ZLibDecoder().decodeBytes(textBytes);
      text = utf8.decode(Uint8List.fromList(decompressed));
    } catch (_) {
      return; // Skip chunk if decompression fails
    }
  } else {
    text = utf8.decode(textBytes, allowMalformed: true);
  }

  result[keyword] = text;
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

  // Try to extract metadata from the original source (supports both tEXt and iTXt)
  final textData = _extractPngTextChunks(originalBytes);

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
