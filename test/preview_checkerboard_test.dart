import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;

import 'package:naiweaver/core/utils/image_utils.dart';
import 'package:naiweaver/core/widgets/checkerboard.dart';

/// Encodes a real PNG so the alpha scan has actual pixels to inspect.
Uint8List _png(int width, int height, {int alpha = 255, int channels = 4}) {
  final image = img.Image(width: width, height: height, numChannels: channels);
  for (final pixel in image) {
    pixel.setRgba(200, 100, 50, alpha);
  }
  return Uint8List.fromList(img.encodePng(image));
}

void main() {
  group('pngSize', () {
    test('reads dimensions from the IHDR header', () {
      final size = pngSize(_png(832, 1216));
      expect(size, isNotNull);
      expect(size!.width, 832);
      expect(size.height, 1216);
    });

    test('non-square dimensions are not transposed', () {
      final size = pngSize(_png(1216, 832));
      expect(size!.width, 1216);
      expect(size.height, 832);
    });

    test('returns null for non-PNG and truncated buffers', () {
      expect(pngSize(Uint8List(3)), isNull);
      expect(pngSize(Uint8List.fromList(List.filled(64, 0x52))), isNull);
    });
  });

  group('pngHasTransparentPixels', () {
    test('opaque RGBA does NOT count as transparent', () {
      // The old header-only check returned true here, which is why the
      // checkerboard showed behind ordinary opaque renders.
      final bytes = _png(64, 64, alpha: 255);
      expect(pngSupportsAlpha(bytes), isTrue, reason: 'RGBA encoding');
      expect(pngHasTransparentPixels(bytes), isFalse);
    });

    test('fully transparent RGBA counts as transparent', () {
      expect(pngHasTransparentPixels(_png(64, 64, alpha: 0)), isTrue);
    });

    test('partially transparent RGBA counts as transparent', () {
      final image = img.Image(width: 8, height: 8, numChannels: 4);
      for (final pixel in image) {
        pixel.setRgba(10, 20, 30, 255);
      }
      image.getPixel(3, 3).a = 128;
      final bytes = Uint8List.fromList(img.encodePng(image));
      expect(pngHasTransparentPixels(bytes), isTrue);
    });

    test('RGB without an alpha channel is never transparent', () {
      final bytes = _png(32, 32, channels: 3);
      expect(pngHasTransparentPixels(bytes), isFalse);
    });

    test('garbage bytes are handled without throwing', () {
      expect(pngHasTransparentPixels(Uint8List(3)), isFalse);
      expect(
        pngHasTransparentPixels(Uint8List.fromList(List.filled(64, 0x52))),
        isFalse,
      );
    });
  });

  group('checkerboard bounds in the preview', () {
    /// Mirrors how ImagePreviewViewer composes the checkerboard: image and
    /// grid share one AspectRatio box, inside a preview area that is a
    /// different shape (Android portrait reserves height for the prompt sheet).
    Widget harness(Uint8List bytes, Size preview) {
      final size = pngSize(bytes)!;
      return MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              key: const Key('preview'),
              width: preview.width,
              height: preview.height,
              child: Center(
                child: AspectRatio(
                  aspectRatio: size.width / size.height,
                  child: Stack(
                    fit: StackFit.passthrough,
                    children: [
                      const Positioned.fill(
                        child: CustomPaint(
                          key: Key('grid'),
                          painter: CheckerboardPainter(),
                        ),
                      ),
                      Image.memory(bytes, fit: BoxFit.contain),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }

    testWidgets(
      'checkerboard never paints outside the letterboxed image rect',
      (tester) async {
        // Square image in a tall preview box: BoxFit.contain leaves empty
        // bands above and below, and the grid must stay out of them.
        final bytes = _png(512, 512, alpha: 0);
        await tester.pumpWidget(harness(bytes, const Size(300, 600)));
        await tester.pumpAndSettle();

        final grid = tester.getRect(find.byKey(const Key('grid')));
        final image = tester.getRect(find.byType(Image));

        expect(grid.height, lessThan(600),
            reason: 'grid must not fill the preview height');
        expect(grid, equals(image),
            reason: 'grid should be exactly the image rect');
      },
    );

    testWidgets('wide image in a tall preview leaves no bottom strip',
        (tester) async {
      final bytes = _png(1216, 832, alpha: 0);
      await tester.pumpWidget(harness(bytes, const Size(360, 640)));
      await tester.pumpAndSettle();

      final grid = tester.getRect(find.byKey(const Key('grid')));
      final preview = tester.getRect(find.byKey(const Key('preview')));

      expect(grid.bottom, lessThan(preview.bottom),
          reason: 'no checkerboard strip below the image');
      expect(grid.top, greaterThan(preview.top));
    });
  });
}
