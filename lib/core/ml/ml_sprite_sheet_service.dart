import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;

class SpriteSheetConfig {
  final int columns;
  final int padding;
  final bool powerOfTwo;
  final bool includeMetadata;
  final int backgroundColor; // ARGB

  const SpriteSheetConfig({
    this.columns = 4,
    this.padding = 2,
    this.powerOfTwo = true,
    this.includeMetadata = true,
    this.backgroundColor = 0x00000000, // transparent
  });
}

class SpriteFrame {
  final String name;
  final int x;
  final int y;
  final int width;
  final int height;

  const SpriteFrame({
    required this.name,
    required this.x,
    required this.y,
    required this.width,
    required this.height,
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'x': x,
        'y': y,
        'width': width,
        'height': height,
      };
}

class SpriteSheetResult {
  final Uint8List sheetBytes; // PNG
  final String atlasJson; // JSON with frame rects + names
  final int sheetWidth;
  final int sheetHeight;
  final List<SpriteFrame> frames;

  const SpriteSheetResult({
    required this.sheetBytes,
    required this.atlasJson,
    required this.sheetWidth,
    required this.sheetHeight,
    required this.frames,
  });
}

class _SpriteSheetParams {
  final List<Uint8List> images;
  final List<String> names;
  final SpriteSheetConfig config;

  const _SpriteSheetParams({
    required this.images,
    required this.names,
    required this.config,
  });
}

class MLSpriteSheetService {
  Future<SpriteSheetResult?> generate({
    required List<Uint8List> images,
    required List<String> names,
    SpriteSheetConfig config = const SpriteSheetConfig(),
  }) async {
    if (images.isEmpty) return null;

    return compute(
      _generateSpriteSheet,
      _SpriteSheetParams(images: images, names: names, config: config),
    );
  }
}

SpriteSheetResult _generateSpriteSheet(_SpriteSheetParams params) {
  final config = params.config;
  final decoded = <img.Image>[];
  final frameNames = <String>[];

  for (int i = 0; i < params.images.length; i++) {
    final image = img.decodeImage(params.images[i]);
    if (image != null) {
      decoded.add(image);
      frameNames.add(i < params.names.length ? params.names[i] : 'frame_$i');
    }
  }

  if (decoded.isEmpty) throw Exception('No valid images to pack');

  final cols = config.columns.clamp(1, decoded.length);
  final rows = (decoded.length / cols).ceil();
  final pad = config.padding;

  // Find max cell size
  int maxCellW = 0, maxCellH = 0;
  for (final image in decoded) {
    maxCellW = max(maxCellW, image.width);
    maxCellH = max(maxCellH, image.height);
  }

  int sheetW = cols * maxCellW + (cols + 1) * pad;
  int sheetH = rows * maxCellH + (rows + 1) * pad;

  // Round to power of two if requested
  if (config.powerOfTwo) {
    sheetW = _nextPowerOfTwo(sheetW);
    sheetH = _nextPowerOfTwo(sheetH);
  }

  // Create sheet
  final sheet = img.Image(width: sheetW, height: sheetH, numChannels: 4);

  // Fill background
  final bgA = (config.backgroundColor >> 24) & 0xFF;
  final bgR = (config.backgroundColor >> 16) & 0xFF;
  final bgG = (config.backgroundColor >> 8) & 0xFF;
  final bgB = config.backgroundColor & 0xFF;
  for (int y = 0; y < sheetH; y++) {
    for (int x = 0; x < sheetW; x++) {
      sheet.setPixelRgba(x, y, bgR, bgG, bgB, bgA);
    }
  }

  // Place sprites
  final frames = <SpriteFrame>[];
  for (int i = 0; i < decoded.length; i++) {
    final col = i % cols;
    final row = i ~/ cols;
    final cx = pad + col * (maxCellW + pad);
    final cy = pad + row * (maxCellH + pad);

    // Center within cell
    final ox = cx + (maxCellW - decoded[i].width) ~/ 2;
    final oy = cy + (maxCellH - decoded[i].height) ~/ 2;

    img.compositeImage(sheet, decoded[i], dstX: ox, dstY: oy);

    frames.add(SpriteFrame(
      name: frameNames[i],
      x: ox,
      y: oy,
      width: decoded[i].width,
      height: decoded[i].height,
    ));
  }

  final atlasJson = jsonEncode({
    'frames': frames.map((f) => f.toJson()).toList(),
    'meta': {
      'size': {'w': sheetW, 'h': sheetH},
      'scale': 1,
      'format': 'RGBA8888',
    },
  });

  return SpriteSheetResult(
    sheetBytes: Uint8List.fromList(img.encodePng(sheet)),
    atlasJson: atlasJson,
    sheetWidth: sheetW,
    sheetHeight: sheetH,
    frames: frames,
  );
}

int _nextPowerOfTwo(int v) {
  v--;
  v |= v >> 1;
  v |= v >> 2;
  v |= v >> 4;
  v |= v >> 8;
  v |= v >> 16;
  return v + 1;
}
