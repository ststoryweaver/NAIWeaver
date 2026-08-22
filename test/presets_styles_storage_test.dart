import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:naiweaver/core/services/presets.dart';
import 'package:naiweaver/core/services/styles.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';

GenerationPreset _samplePreset(String name) => GenerationPreset(
      name: name,
      prompt: 'a wizard, $name',
      negativePrompt: 'low quality',
      width: 832,
      height: 1216,
      scale: 5,
      steps: 28,
      sampler: 'k_euler',
      smea: false,
      smeaDyn: false,
      decrisper: false,
    );

void main() {
  late Directory tmp;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    tmp = await Directory.systemTemp.createTemp('storage_test_');
  });

  tearDown(() async {
    if (await tmp.exists()) {
      await tmp.delete(recursive: true);
    }
  });

  group('PresetStorage', () {
    test('returns empty list when nothing saved', () async {
      final loaded = await PresetStorage.loadPresets(
        p.join(tmp.path, 'presets.json'),
      );
      expect(loaded, isEmpty);
    });

    test('round-trips presets via the file backend', () async {
      final path = p.join(tmp.path, 'presets.json');
      final originals = [_samplePreset('alpha'), _samplePreset('beta')];

      await PresetStorage.savePresets(path, originals);
      expect(await File(path).exists(), isTrue);

      final loaded = await PresetStorage.loadPresets(path);
      expect(loaded.length, 2);
      expect(loaded[0].name, 'alpha');
      expect(loaded[1].name, 'beta');
      expect(loaded[0].prompt, 'a wizard, alpha');
    });

    // Issue #35: schedule / rescale / Variety+ ride along in presets, and
    // presets saved before the fields existed load with NovelAI's defaults.
    test('round-trips noise schedule, cfg_rescale and Variety+', () async {
      final path = p.join(tmp.path, 'presets.json');
      final preset = GenerationPreset(
        name: 'v+',
        prompt: 'x',
        negativePrompt: '',
        width: 832,
        height: 1216,
        scale: 5,
        steps: 28,
        sampler: 'k_euler',
        smea: false,
        smeaDyn: false,
        decrisper: false,
        noiseSchedule: 'exponential',
        cfgRescale: 0.4,
        varietyBoostSigma: 58,
      );
      await PresetStorage.savePresets(path, [preset]);
      final loaded = (await PresetStorage.loadPresets(path)).single;
      expect(loaded.noiseSchedule, 'exponential');
      expect(loaded.cfgRescale, 0.4);
      expect(loaded.varietyBoostSigma, 58.0);

      final legacy = GenerationPreset.fromJson({
        'name': 'old',
        'prompt': 'x',
        'negativePrompt': '',
        'width': 832,
        'height': 1216,
        'scale': 5,
        'steps': 28,
        'sampler': 'k_euler',
      });
      expect(legacy.noiseSchedule, 'karras');
      expect(legacy.cfgRescale, 0);
      expect(legacy.varietyBoostSigma, isNull);
    });

    test('overwrites previous data on subsequent save', () async {
      final path = p.join(tmp.path, 'presets.json');
      await PresetStorage.savePresets(path, [_samplePreset('one')]);
      await PresetStorage.savePresets(path, [_samplePreset('two')]);

      final loaded = await PresetStorage.loadPresets(path);
      expect(loaded.length, 1);
      expect(loaded[0].name, 'two');
    });
  });

  group('StyleStorage', () {
    test('round-trips styles', () async {
      final path = p.join(tmp.path, 'prompt_styles.json');
      final originals = [
        PromptStyle(name: 'Cinematic', prefix: 'cinematic, '),
        PromptStyle(name: 'Anime', prefix: 'anime, ', suffix: ', cel-shaded'),
      ];

      await StyleStorage.saveStyles(path, originals);
      expect(await File(path).exists(), isTrue);

      final loaded = await StyleStorage.loadStyles(path);
      expect(loaded.length, 2);
      expect(loaded[0].name, 'Cinematic');
      expect(loaded[1].suffix, ', cel-shaded');
    });
  });
}
