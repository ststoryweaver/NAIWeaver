import 'package:flutter_test/flutter_test.dart';
import 'package:naiweaver/core/models/nai_model.dart';

void main() {
  group('NaiModel ids', () {
    test('wire ids match NovelAI', () {
      expect(NaiModel.v5Full.id, 'nai-diffusion-5-full');
      expect(NaiModel.v5Curated.id, 'nai-diffusion-5-curated');
      expect(NaiModel.v45Full.id, 'nai-diffusion-4-5-full');
      expect(NaiModel.v45Curated.id, 'nai-diffusion-4-5-curated');
    });

    test('inpainting ids — V5 Curated still routes to V4.5 Curated inpaint', () {
      expect(NaiModel.v5Full.inpaintingId, 'nai-diffusion-5-full-inpainting');
      expect(NaiModel.v5Curated.inpaintingId,
          'nai-diffusion-4-5-curated-inpainting');
      expect(NaiModel.v45Full.inpaintingId, 'nai-diffusion-4-5-full-inpainting');
      expect(NaiModel.v45Curated.inpaintingId,
          'nai-diffusion-4-5-curated-inpainting');
    });

    test('vibe encode id falls back to the matching V4.5 model on V5', () {
      expect(NaiModel.v5Full.vibeEncodeId, NaiModel.v45Full.id);
      expect(NaiModel.v5Curated.vibeEncodeId, NaiModel.v45Curated.id);
      expect(NaiModel.v45Full.vibeEncodeId, NaiModel.v45Full.id);
    });

    test('fallback is V4.5 Full (nobody is auto-migrated to V5)', () {
      expect(NaiModel.fallback, NaiModel.v45Full);
      expect(NaiModel.fromId(null), NaiModel.v45Full);
      expect(NaiModel.fromId('garbage'), NaiModel.v45Full);
      expect(NaiModel.tryParse('garbage'), isNull);
      expect(NaiModel.tryParse(''), isNull);
    });

    test('tryParse: exact ids, inpaint ids, enum names, and sniffing', () {
      for (final m in NaiModel.values) {
        expect(NaiModel.tryParse(m.id), m);
        expect(NaiModel.tryParse(m.name), m);
        expect(NaiModel.tryParse(m.id.toUpperCase()), m);
      }
      expect(NaiModel.tryParse('nai-diffusion-5-full-inpainting'), NaiModel.v5Full);
      expect(NaiModel.tryParse('nai-diffusion-5-curated-inpainting'),
          NaiModel.v5Curated);
      // The V4.5 curated inpaint id is also V5 Curated's launch inpaint id;
      // it must still import as V4.5 ("4-5-" contains "-5-").
      expect(NaiModel.tryParse('nai-diffusion-4-5-curated-inpainting'),
          NaiModel.v45Curated);
      expect(NaiModel.tryParse('nai-diffusion-4-5-full-inpainting'),
          NaiModel.v45Full);
      expect(NaiModel.tryParse('NovelAI Diffusion V5'), NaiModel.v5Full);
      expect(NaiModel.tryParse('NovelAI Diffusion V5 Curated'), NaiModel.v5Curated);
      expect(NaiModel.tryParse('nai-diffusion-4-5-curated'), NaiModel.v45Curated);
      expect(NaiModel.tryParse('NovelAI Diffusion V4.5'), NaiModel.v45Full);
    });

    test('legacy use_curated migration', () {
      expect(NaiModel.fromLegacyCurated(true), NaiModel.v45Curated);
      expect(NaiModel.fromLegacyCurated(false), NaiModel.v45Full);
    });
  });

  group('NaiCaps', () {
    test('V5 capability table mirrors NovelAI launch day', () {
      final c = NaiModel.v5Full.caps;
      expect(c.vibeTransfer, isFalse);
      expect(c.encodedVibes, isFalse);
      expect(c.characterReference, isFalse);
      expect(c.varietyPlus, isFalse);
      expect(c.noiseSchedule, isFalse);
      expect(c.cfgRescale, isTrue);
      expect(c.smea, isFalse);
      expect(c.decrisper, isFalse);
      expect(c.transparency, isTrue);
      expect(c.freeformPosition, isTrue);
      expect(c.canPositionOneCharacter, isTrue);
      expect(c.autoText, isTrue);
      expect(c.maxEnhance, isTrue);
      expect(c.opusUsageLimit, isTrue);
      expect(c.maxCharacters, 32);
      expect(NaiModel.v5Curated.caps, same(c));
    });

    test('V4.5 capability table', () {
      final c = NaiModel.v45Full.caps;
      expect(c.vibeTransfer, isTrue);
      expect(c.characterReference, isTrue);
      expect(c.noiseSchedule, isTrue);
      expect(c.smea, isFalse);
      expect(c.transparency, isFalse);
      expect(c.freeformPosition, isFalse);
      expect(c.maxCharacters, 6);
      expect(NaiModel.v45Full.opusUnlimited, isTrue);
      expect(NaiModel.v5Full.opusUnlimited, isFalse);
    });

    test('defaults: V5 23/7.0 params_version 4, V4.5 23/5.0 params_version 3', () {
      expect(NaiModel.v5Full.defaults.steps, 23);
      expect(NaiModel.v5Full.defaults.scale, 7.0);
      expect(NaiModel.v5Full.defaults.paramsVersion, 4);
      expect(NaiModel.v45Curated.defaults.steps, 23);
      expect(NaiModel.v45Curated.defaults.scale, 5.0);
      expect(NaiModel.v45Curated.defaults.paramsVersion, 3);
    });

    test('samplers / schedules / presets', () {
      expect(NaiModel.v5Full.samplers.first, 'k_euler_ancestral');
      expect(NaiModel.v5Full.samplers, contains('k_dpmpp_2m_sde'));
      expect(NaiModel.v5Full.samplers, isNot(contains('ddim')));
      expect(NaiModel.v5Full.noiseSchedules, isEmpty);
      expect(NaiModel.v45Full.noiseSchedules, isNot(contains('native')));
      expect(NaiModel.v5Full.qualityPresets.map((q) => q.id), ['standard', 'light']);
      expect(NaiModel.v45Curated.qualityPresets.single.suffix, contains('rating:general'));
      expect(NaiModel.v5Full.ucPresets.map((u) => u.id),
          containsAll(['heavy', 'light', 'humanFocus', 'furryFocus']));
    });
  });

  group('NaiUsage', () {
    test('images left / recharge math mirrors the frontend helpers', () {
      const u = NaiUsage(percent: 42, isNegative: false, secondsPerPercent: 7888);
      expect(u.imagesLeft, (17.3 * 42).round());
      expect(u.percentPerDay, 11.0); // 86400/7888 = 10.95 → 11.0 (0.1 rounding)
      expect(u.imagesPerDay, (17.3 * 11.0).round());
      expect(u.isLow, isFalse);
      expect(u.isEmpty, isFalse);
    });

    test('negative clamps to zero and is low/empty', () {
      const u = NaiUsage(percent: 12, isNegative: true, secondsPerPercent: 8000);
      expect(u.remainingPercent, 0);
      expect(u.imagesLeft, 0);
      expect(u.isLow, isTrue);
      expect(u.isEmpty, isTrue);
    });

    test('under 5% is low but not empty', () {
      const u = NaiUsage(percent: 3, isNegative: false, secondsPerPercent: 8000);
      expect(u.isLow, isTrue);
      expect(u.isEmpty, isFalse);
    });

    test('fromJson tolerates missing/odd fields', () {
      expect(NaiUsage.fromJson(null), isNull);
      expect(NaiUsage.fromJson({'isNegative': true}), isNull);
      final u = NaiUsage.fromJson({'percent': 55.5, 'timeUntilNextPercent': 1000});
      expect(u!.percent, 55.5);
      expect(u.isNegative, isFalse);
      expect(u.secondsPerPercent, 1000);
    });
  });

  group('NaiSubscription', () {
    test('parses the image-host payload', () {
      final s = NaiSubscription.fromJson({
        'tier': 3,
        'active': true,
        'trainingStepsLeft': {
          'fixedTrainingStepsLeft': 9000,
          'purchasedTrainingSteps': 500,
        },
        'usage': {'percent': 80, 'isNegative': false, 'timeUntilNextPercent': 7888},
      });
      expect(s!.isOpus, isTrue);
      expect(s.anlas, 9500);
      expect(s.usage!.percent, 80);
    });

    test('legacy int trainingStepsLeft + no usage', () {
      final s = NaiSubscription.fromJson({'tier': 1, 'active': true, 'trainingStepsLeft': 1000});
      expect(s!.anlas, 1000);
      expect(s.isOpus, isFalse);
      expect(s.usage, isNull);
    });
  });

  group('estimateCostKind', () {
    const opusFull = NaiSubscription(
      tier: 3,
      active: true,
      anlas: 10000,
      usage: NaiUsage(percent: 50, isNegative: false, secondsPerPercent: 7888),
    );
    const opusEmpty = NaiSubscription(
      tier: 3,
      active: true,
      anlas: 10000,
      usage: NaiUsage(percent: 0, isNegative: true, secondsPerPercent: 7888),
    );
    const scroll = NaiSubscription(tier: 2, active: true, anlas: 1000);

    NaiCostKind k(NaiModel m, NaiSubscription? s,
            {int w = 832, int h = 1216, int steps = 28, bool base = false}) =>
        estimateCostKind(
            model: m, width: w, height: h, steps: steps, hasBaseImage: base, subscription: s);

    test('unknown without subscription', () {
      expect(k(NaiModel.v5Full, null), NaiCostKind.unknown);
    });

    test('V4.5 on Opus within the free rule is free', () {
      expect(k(NaiModel.v45Full, opusFull), NaiCostKind.free);
      expect(k(NaiModel.v45Curated, opusEmpty), NaiCostKind.free);
    });

    test('V5 on Opus uses the allowance, costs Anlas when empty', () {
      expect(k(NaiModel.v5Full, opusFull), NaiCostKind.allowance);
      expect(k(NaiModel.v5Full, opusEmpty), NaiCostKind.anlas);
    });

    test('free rule: size, steps, base image', () {
      expect(k(NaiModel.v45Full, opusFull, w: 1024, h: 1536), NaiCostKind.anlas);
      expect(k(NaiModel.v45Full, opusFull, steps: 29), NaiCostKind.anlas);
      expect(k(NaiModel.v45Full, opusFull, base: true), NaiCostKind.anlas);
      expect(k(NaiModel.v45Full, opusFull, w: 1024, h: 1024), NaiCostKind.free);
    });

    test('below Opus everything costs Anlas', () {
      expect(k(NaiModel.v45Full, scroll), NaiCostKind.anlas);
      expect(k(NaiModel.v5Full, scroll), NaiCostKind.anlas);
    });
  });

  test('naiMaxEnhanceAvailable', () {
    expect(naiMaxEnhanceAvailable(NaiModel.v5Full, 832, 1216), isTrue);
    expect(naiMaxEnhanceAvailable(NaiModel.v5Full, 1536, 1664), isFalse);
    expect(naiMaxEnhanceAvailable(NaiModel.v45Full, 832, 1216), isFalse);
  });
}
