import 'dart:convert';
import 'dart:typed_data';
import 'package:archive/archive.dart' show ZLibDecoder;
import 'package:image/image.dart' as img;

/// Request keys whose values are base64 payloads (source image, mask, vibe
/// vectors, reference images). NovelAI leaves these out of its own Comment
/// chunk, and embedding them would put megabytes of base64 into every PNG.
const Set<String> _binaryMetadataKeys = {
  'image',
  'mask',
  'reference_image_multiple',
  'director_reference_images',
};

/// Helper to inject metadata into PNG bytes.
/// This runs in a separate isolate via compute.
///
/// package:image 4.x's [img.PngEncoder] ignores its own `textData` field and
/// only writes `Image.textData` — so the chunks must be set on the decoded
/// image, not the encoder. (Setting them on the encoder silently wrote
/// nothing; the only metadata our PNGs carried was whatever NovelAI had put
/// in the bytes it returned.)
Uint8List injectMetadata(Map<String, dynamic> data) {
  final bytes = data['bytes'] as Uint8List;
  final metadata = data['metadata'] as Map<String, dynamic>;

  final image = _decodePngSafe(bytes);
  if (image == null) return bytes;

  final comment = Map<String, dynamic>.of(metadata)
    ..removeWhere((k, _) => _binaryMetadataKeys.contains(k));

  // NovelAI's own chunks (Title/Description/Software/Source/Comment) survive
  // the decode; overlay ours on top. `Source` names the model family and
  // is only known for sure when NovelAI wrote it, so keep theirs if present.
  //
  // `Comment` is NovelAI's canonical provenance record (it can carry keys the
  // app's reconstruction lacks, e.g. signed fields) — when present it is kept
  // verbatim and the app's record goes into its own `NAIWeaver` chunk instead;
  // [extractMetadata] overlays that back for readers. Only images with no NAI
  // Comment (edited or non-NAI sources) get the app's record under `Comment`.
  final existing = image.textData ?? const <String, String>{};
  final hasNaiComment = existing.containsKey('Comment');
  final appRecord = jsonEncode(comment);
  image.textData = {
    ...existing,
    'Title': 'NovelAI generated image',
    'Description': comment['prompt']?.toString() ?? '',
    'Software': 'NovelAI',
    if (!existing.containsKey('Source'))
      'Source': 'NovelAI Diffusion V4.5 4BDE2A90',
    if (hasNaiComment) 'NAIWeaver': appRecord else 'Comment': appRecord,
  };

  return Uint8List.fromList(img.PngEncoder().encode(image));
}

/// Helper to extract metadata from image bytes.
/// Supports PNG (tEXt/iTXt chunks) and WebP/JPEG (EXIF UserComment).
/// This runs in a separate isolate via compute.
Map<String, String>? extractMetadata(Uint8List bytes) {
  // Try PNG text chunks first
  if (isPng(bytes)) return _overlayAppRecord(_extractPngTextChunks(bytes));

  // For WebP/JPEG: try to extract NovelAI metadata from EXIF UserComment
  try {
    final image = img.decodeImage(bytes);
    if (image == null) return null;

    final result = <String, String>{};

    // NovelAI stores the Comment JSON in EXIF UserComment (tag 0x9286)
    final userComment = image.exif.exifIfd[0x9286]?.toString();
    if (userComment != null && userComment.isNotEmpty) {
      result['Comment'] = userComment;
    }

    // Also check ImageDescription (tag 0x010E) for the prompt/Description
    final imageDesc = image.exif.imageIfd[0x010E]?.toString();
    if (imageDesc != null && imageDesc.isNotEmpty) {
      result['Description'] = imageDesc;
    }

    // Check Software tag (0x0131)
    final software = image.exif.imageIfd[0x0131]?.toString();
    if (software != null && software.isNotEmpty) {
      result['Software'] = software;
    }

    return result.isEmpty ? null : result;
  } catch (_) {
    return null;
  }
}

/// Merges the app's `NAIWeaver` record into the `Comment` view.
///
/// [injectMetadata] keeps NovelAI's canonical `Comment` chunk verbatim and
/// writes the app's reconstruction (original_prompt, model, styles, …) to a
/// separate `NAIWeaver` chunk. Every reader in the app parses
/// `metadata['Comment']`, so present them one merged view — app keys overlay
/// NovelAI's — while the bytes on disk keep both records intact.
Map<String, String>? _overlayAppRecord(Map<String, String>? chunks) {
  final app = chunks?['NAIWeaver'];
  if (chunks == null || app == null) return chunks;
  final appJson = parseCommentJson(app);
  if (appJson == null) return chunks;
  final naiComment = chunks['Comment'];
  final naiJson = naiComment == null ? null : parseCommentJson(naiComment);
  return {
    ...chunks,
    'Comment': jsonEncode({...?naiJson, ...appJson}),
  };
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
  final image = _decodePngSafe(bytes);
  if (image == null) return bytes;

  // See [injectMetadata]: the encoder's own textData is ignored, the chunks
  // written are the image's — clearing those is what actually strips.
  image.textData = null;
  return Uint8List.fromList(img.PngEncoder().encode(image));
}

/// decodePng that never throws: package:image throws (e.g. RangeError) on
/// truncated data with a valid signature instead of returning null (issue #24).
img.Image? _decodePngSafe(Uint8List bytes) {
  try {
    return img.decodePng(bytes);
  } catch (_) {
    return null;
  }
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
  // Falls back to EXIF extraction for non-PNG formats (WebP/JPEG)
  var textData = _extractPngTextChunks(originalBytes);
  textData ??= extractMetadata(originalBytes);

  // Decode the (possibly-transcoded) bytes
  final image = img.decodeImage(bytes);
  if (image == null) return null;

  // See [injectMetadata]: chunks are written from the image, not the encoder.
  if (textData != null && textData.isNotEmpty) {
    image.textData = {...?image.textData, ...textData};
  }
  return Uint8List.fromList(img.PngEncoder().encode(image));
}

/// Extracts the original creation date from image metadata (EXIF for JPEG/WEBP).
/// Falls back to the provided file stat date if no metadata date is found.
/// Designed to run in an isolate via compute().
String extractOriginalDate(Map<String, dynamic> data) {
  final bytes = data['bytes'] as Uint8List;
  final statModified = data['statModified'] as String;

  // 1. Try EXIF (works for JPEG/WEBP)
  if (!isPng(bytes)) {
    try {
      final image = img.decodeImage(bytes);
      if (image != null) {
        // DateTimeOriginal (0x9003) → DateTimeDigitized (0x9004) → DateTime (0x0132)
        final dto = image.exif.exifIfd[0x9003]?.toString();
        final dtd = image.exif.exifIfd[0x9004]?.toString();
        final dt = image.exif.imageIfd[0x0132]?.toString();
        final exifStr = dto ?? dtd ?? dt;
        if (exifStr != null) {
          final parsed = _parseExifDate(exifStr);
          if (parsed != null) return parsed.toIso8601String();
        }
      }
    } catch (_) {}
  }

  // 2. For PNGs, check for an existing OriginalDate text chunk
  if (isPng(bytes)) {
    final metadata = _extractPngTextChunks(bytes);
    if (metadata != null && metadata.containsKey('OriginalDate')) {
      final origDate = DateTime.tryParse(metadata['OriginalDate']!);
      if (origDate != null) return origDate.toIso8601String();
    }
  }

  // 3. Fall back to file stat
  return statModified;
}

/// Parses EXIF date format "YYYY:MM:DD HH:MM:SS" into a DateTime.
DateTime? _parseExifDate(String exifDate) {
  try {
    final parts = exifDate.split(' ');
    if (parts.length != 2) return null;
    final dateParts = parts[0].split(':');
    final timeParts = parts[1].split(':');
    if (dateParts.length != 3 || timeParts.length != 3) return null;
    return DateTime(
      int.parse(dateParts[0]),
      int.parse(dateParts[1]),
      int.parse(dateParts[2]),
      int.parse(timeParts[0]),
      int.parse(timeParts[1]),
      int.parse(timeParts[2]),
    );
  } catch (_) {
    return null;
  }
}

/// Injects an OriginalDate tEXt chunk into PNG bytes without re-encoding pixels.
/// Designed to run in an isolate via compute().
Uint8List injectOriginalDate(Map<String, dynamic> data) {
  final bytes = data['bytes'] as Uint8List;
  final date = data['date'] as String;
  return _insertPngTextChunk(bytes, 'OriginalDate', date);
}

/// Inserts a tEXt chunk into PNG bytes before the first IDAT chunk.
Uint8List _insertPngTextChunk(Uint8List bytes, String key, String value) {
  if (!isPng(bytes)) return bytes;

  // Build tEXt chunk data: keyword \0 text
  final keyBytes = latin1.encode(key);
  final valueBytes = latin1.encode(value);
  final chunkData = Uint8List(keyBytes.length + 1 + valueBytes.length);
  chunkData.setRange(0, keyBytes.length, keyBytes);
  chunkData[keyBytes.length] = 0;
  chunkData.setRange(keyBytes.length + 1, chunkData.length, valueBytes);

  // Compute CRC over type + data
  const chunkType = [0x74, 0x45, 0x58, 0x74]; // 'tEXt'
  final crc = _pngCrc32([...chunkType, ...chunkData]);

  // Build full chunk: length(4) + type(4) + data + crc(4)
  final len = chunkData.length;
  final fullChunk = Uint8List(12 + len);
  fullChunk[0] = (len >> 24) & 0xFF;
  fullChunk[1] = (len >> 16) & 0xFF;
  fullChunk[2] = (len >> 8) & 0xFF;
  fullChunk[3] = len & 0xFF;
  fullChunk[4] = 0x74; fullChunk[5] = 0x45;
  fullChunk[6] = 0x58; fullChunk[7] = 0x74;
  fullChunk.setRange(8, 8 + len, chunkData);
  fullChunk[8 + len] = (crc >> 24) & 0xFF;
  fullChunk[8 + len + 1] = (crc >> 16) & 0xFF;
  fullChunk[8 + len + 2] = (crc >> 8) & 0xFF;
  fullChunk[8 + len + 3] = crc & 0xFF;

  // Find insertion point: before first IDAT chunk
  var offset = 8; // Skip PNG signature
  while (offset + 12 <= bytes.length) {
    final chunkLen = (bytes[offset] << 24) |
        (bytes[offset + 1] << 16) |
        (bytes[offset + 2] << 8) |
        bytes[offset + 3];
    final type = String.fromCharCodes(bytes, offset + 4, offset + 8);
    if (type == 'IDAT') {
      final result = Uint8List(bytes.length + fullChunk.length);
      result.setRange(0, offset, bytes);
      result.setRange(offset, offset + fullChunk.length, fullChunk);
      result.setRange(
          offset + fullChunk.length, result.length,
          Uint8List.sublistView(bytes, offset));
      return result;
    }
    offset += 12 + chunkLen;
  }

  return bytes;
}

/// Computes CRC-32 for PNG chunk validation.
int _pngCrc32(List<int> data) {
  int crc = 0xFFFFFFFF;
  for (final byte in data) {
    crc ^= byte;
    for (int i = 0; i < 8; i++) {
      if ((crc & 1) != 0) {
        crc = (crc >> 1) ^ 0xEDB88320;
      } else {
        crc >>= 1;
      }
    }
  }
  return (crc ^ 0xFFFFFFFF) & 0xFFFFFFFF;
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

/// Reads the pixel dimensions from a PNG's IHDR chunk without decoding it.
/// Returns null if [bytes] is not a PNG or the header is truncated.
///
/// Used to size the transparency checkerboard to the image itself, so it never
/// paints into the letterbox bands left by BoxFit.contain.
({int width, int height})? pngSize(Uint8List bytes) {
  if (bytes.length < 33) return null;
  if (!isPng(bytes)) return null;
  // 8 (sig) + 4 (len) + 4 ('IHDR'), then width(4) height(4) big-endian.
  if (bytes[12] != 0x49 ||
      bytes[13] != 0x48 ||
      bytes[14] != 0x44 ||
      bytes[15] != 0x52) {
    return null;
  }
  final width =
      (bytes[16] << 24) | (bytes[17] << 16) | (bytes[18] << 8) | bytes[19];
  final height =
      (bytes[20] << 24) | (bytes[21] << 16) | (bytes[22] << 8) | bytes[23];
  if (width <= 0 || height <= 0) return null;
  return (width: width, height: height);
}

/// Whether a PNG's colour type or chunks allow transparent pixels at all.
///
/// This is a cheap header-only screen: an opaque RGBA image still passes. Use
/// [pngHasTransparentPixels] before showing transparency affordances.
bool pngSupportsAlpha(Uint8List bytes) {
  if (bytes.length < 29) return false;
  if (!isPng(bytes)) return false;
  if (bytes[12] != 0x49 ||
      bytes[13] != 0x48 ||
      bytes[14] != 0x44 ||
      bytes[15] != 0x52) {
    return false;
  }
  final colorType = bytes[25];
  // 4 = grey+alpha, 6 = RGBA. Types 0/2/3 carry alpha only via a tRNS chunk.
  if (colorType == 4 || colorType == 6) return true;
  return _hasTrnsChunk(bytes);
}

/// Whether a PNG actually contains at least one *visibly* transparent pixel.
///
/// [pngSupportsAlpha] only reports that the encoding *can* carry alpha, which
/// is true of every RGBA PNG NovelAI returns — including fully opaque ones. The
/// preview checkerboard keys off this instead, so it appears only for genuinely
/// transparent renders. Decodes the image, so cache the result per image rather
/// than calling it from build().
///
/// "Visibly" matters: opaque NovelAI renders (V4.5 and V5 alike) carry bands of
/// VAE noise at alpha 254/255 — imperceptible, but a strict `< max` scan called
/// them transparent, so the checkerboard was drawn behind almost every render
/// and its edge peeked out wherever the scaled image missed the last fractional
/// pixel (the bottom/right slivers on opaque V5 renders). A pixel counts as
/// transparent only below [_opaqueAlphaFraction] of full alpha; a real
/// transparent background sits at or near alpha 0 and clears it easily.
const double _opaqueAlphaFraction = 0.95;

bool pngHasTransparentPixels(Uint8List bytes) {
  if (!pngSupportsAlpha(bytes)) return false;
  final image = _decodePngSafe(bytes);
  if (image == null) return false;
  if (!image.hasAlpha) return false;
  final threshold = image.maxChannelValue * _opaqueAlphaFraction;
  for (final pixel in image) {
    if (pixel.a < threshold) return true;
  }
  return false;
}

/// Scans the chunk list for a tRNS transparency chunk.
bool _hasTrnsChunk(Uint8List bytes) {
  var offset = 8;
  while (offset + 8 <= bytes.length) {
    final length = (bytes[offset] << 24) |
        (bytes[offset + 1] << 16) |
        (bytes[offset + 2] << 8) |
        bytes[offset + 3];
    if (length < 0) return false;
    final type = String.fromCharCodes(bytes.sublist(offset + 4, offset + 8));
    if (type == 'tRNS') return true;
    if (type == 'IDAT' || type == 'IEND') return false;
    offset += 12 + length;
  }
  return false;
}
