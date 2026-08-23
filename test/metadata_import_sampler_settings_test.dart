import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:naiweaver/core/utils/image_utils.dart';
import 'package:naiweaver/features/generation/services/metadata_import_service.dart';

/// Issue #35: noise schedule, Prompt Guidance Rescale (`cfg_rescale`) and
/// Variety+ (`skip_cfg_above_sigma`) are part of the Comment JSON in both our
/// own PNGs and NovelAI's, and must round-trip through metadata import.
void main() {
  late Directory tmp;

  setUp(() async {
    tmp = await Directory.systemTemp.createTemp('meta_import_');
  });

  tearDown(() async {
    if (await tmp.exists()) await tmp.delete(recursive: true);
  });

  Future<File> pngWith(Map<String, dynamic> comment) async {
    final plain = Uint8List.fromList(
        img.encodePng(img.Image(width: 4, height: 4)));
    final withMeta = injectMetadata({'bytes': plain, 'metadata': comment});
    final file = File('${tmp.path}/gen.png');
    await file.writeAsBytes(withMeta);
    return file;
  }

  final service = MetadataImportService();

  test('reads noise_schedule, cfg_rescale and an active Variety+ sigma',
      () async {
    final file = await pngWith({
      'prompt': '1girl',
      'uc': 'lowres',
      'width': 832,
      'height': 1216,
      'noise_schedule': 'exponential',
      'cfg_rescale': 0.3,
      'skip_cfg_above_sigma': 58,
    });
    final r = await service.parseImageMetadata(file, smartStyleImport: false);
    expect(r.noiseSchedule, 'exponential');
    expect(r.cfgRescale, 0.3);
    expect(r.hasVarietyBoostKey, isTrue);
    expect(r.varietyBoostSigma, 58.0);
  });

  test('an explicit null skip_cfg_above_sigma means Variety+ off', () async {
    final file = await pngWith({
      'prompt': '1girl',
      'uc': 'lowres',
      'width': 832,
      'noise_schedule': 'karras',
      'cfg_rescale': 0,
      'skip_cfg_above_sigma': null,
    });
    final r = await service.parseImageMetadata(file, smartStyleImport: false);
    expect(r.hasVarietyBoostKey, isTrue,
        reason: 'NovelAI writes the key as null when the toggle is off');
    expect(r.varietyBoostSigma, isNull);
    expect(r.cfgRescale, 0);
  });

  test('images that predate the keys leave them unset', () async {
    final file = await pngWith({
      'prompt': '1girl',
      'uc': 'lowres',
      'width': 832,
      'sampler': 'k_euler',
    });
    final r = await service.parseImageMetadata(file, smartStyleImport: false);
    expect(r.noiseSchedule, isNull);
    expect(r.cfgRescale, isNull);
    expect(r.hasVarietyBoostKey, isFalse);
    expect(r.varietyBoostSigma, isNull);
  });

  test('model imports from an explicit model key', () async {
    final file = await pngWith({'prompt': '1girl', 'model': 'nai-diffusion-5-full'});
    final r = await service.parseImageMetadata(file, smartStyleImport: false);
    expect(r.model, 'nai-diffusion-5-full');
  });

  test('model is never sniffed from the Source chunk', () async {
    // NAI-style PNG: `Source` names the family but never the Curated
    // variant, and the Comment has no `model` key. Sniffing Source parsed
    // to the Full model and silently switched (and persisted) a Curated
    // user's model on any settings import — the model must stay unset.
    final image = img.Image(width: 4, height: 4);
    image.textData = {
      'Source': 'NovelAI Diffusion V4.5 4BDE2A90',
      'Comment': jsonEncode({'prompt': '1girl', 'uc': 'x', 'width': 832}),
    };
    final file = File('${tmp.path}/nai.png');
    await file.writeAsBytes(img.PngEncoder().encode(image));
    final r = await service.parseImageMetadata(file, smartStyleImport: false);
    expect(r.model, isNull);
  });

  test('the Comment JSON written by injectMetadata is what we parse', () async {
    // Sanity: the helper used above writes a NovelAI-shaped Comment chunk.
    final file = await pngWith({'prompt': 'x', 'cfg_rescale': 0.5});
    final meta = extractMetadata(await file.readAsBytes())!;
    expect(jsonDecode(meta['Comment']!)['cfg_rescale'], 0.5);
  });
}
