import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:naiweaver/core/utils/image_utils.dart';

/// package:image 4.x's PngEncoder ignores its own `textData` field and only
/// writes `Image.textData`. Every helper here used to set the encoder field,
/// so injectMetadata wrote nothing, stripMetadata stripped nothing and
/// convertToPngPreservingMetadata preserved nothing. These pin the real
/// behaviour on the bytes.
void main() {
  Uint8List plainPng() =>
      Uint8List.fromList(img.encodePng(img.Image(width: 4, height: 4)));

  /// A PNG carrying NovelAI-style chunks, as the API returns them.
  Uint8List naiPng() {
    final im = img.Image(width: 4, height: 4)
      ..textData = {
        'Title': 'NovelAI generated image',
        'Software': 'NovelAI',
        'Source': 'NovelAI Diffusion V5 ABCDEF01',
        'Comment': jsonEncode({'prompt': 'from nai', 'steps': 23}),
      };
    return Uint8List.fromList(img.encodePng(im));
  }

  group('injectMetadata', () {
    test('writes our Comment JSON into a plain PNG', () {
      final out = injectMetadata({
        'bytes': plainPng(),
        'metadata': {
          'prompt': '1girl',
          'original_prompt': '1girl',
          'active_style_names': ['Cinematic'],
          'model': 'nai-diffusion-4-5-full',
          'cfg_rescale': 0.2,
        },
      });
      final meta = extractMetadata(out)!;
      expect(meta['Description'], '1girl');
      expect(meta['Software'], 'NovelAI');
      expect(meta['Source'], 'NovelAI Diffusion V4.5 4BDE2A90');
      final comment = jsonDecode(meta['Comment']!) as Map;
      expect(comment['active_style_names'], ['Cinematic']);
      expect(comment['model'], 'nai-diffusion-4-5-full');
      expect(comment['cfg_rescale'], 0.2);
    });

    test('our Comment replaces NovelAI\'s but their Source is kept', () {
      final out = injectMetadata({
        'bytes': naiPng(),
        'metadata': {'prompt': 'ours', 'original_prompt': 'ours'},
      });
      final meta = extractMetadata(out)!;
      expect(meta['Source'], 'NovelAI Diffusion V5 ABCDEF01');
      final comment = jsonDecode(meta['Comment']!) as Map;
      expect(comment['prompt'], 'ours');
      expect(comment['original_prompt'], 'ours');
      expect(comment.containsKey('steps'), isFalse);
    });

    test('drops base64 payload keys from the Comment', () {
      final big = 'A' * 100000;
      final out = injectMetadata({
        'bytes': plainPng(),
        'metadata': {
          'prompt': 'x',
          'image': big,
          'mask': big,
          'reference_image_multiple': [big],
          'director_reference_images': [big],
          'reference_strength_multiple': [0.6],
          'strength': 0.7,
        },
      });
      expect(out.length, lessThan(10000),
          reason: 'payload base64 must not be embedded in the PNG');
      final comment = jsonDecode(extractMetadata(out)!['Comment']!) as Map;
      expect(comment.containsKey('image'), isFalse);
      expect(comment.containsKey('mask'), isFalse);
      expect(comment.containsKey('reference_image_multiple'), isFalse);
      expect(comment.containsKey('director_reference_images'), isFalse);
      // Non-payload siblings stay.
      expect(comment['reference_strength_multiple'], [0.6]);
      expect(comment['strength'], 0.7);
    });
  });

  group('stripMetadata', () {
    test('removes every text chunk', () {
      final stripped = stripMetadata(naiPng());
      expect(extractMetadata(stripped), isNull);
      // Still a decodable PNG.
      expect(img.decodePng(stripped), isNotNull);
    });
  });

  group('convertToPngPreservingMetadata', () {
    test('carries PNG text chunks through a re-encode', () {
      final src = naiPng();
      final out = convertToPngPreservingMetadata({
        'bytes': plainPng(),
        'originalBytes': src,
      })!;
      final meta = extractMetadata(out)!;
      expect(meta['Source'], 'NovelAI Diffusion V5 ABCDEF01');
      expect(jsonDecode(meta['Comment']!)['prompt'], 'from nai');
    });
  });
}
