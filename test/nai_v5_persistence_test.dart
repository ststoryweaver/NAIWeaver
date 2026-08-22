import 'dart:typed_data';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:naiweaver/core/models/nai_model.dart';
import 'package:naiweaver/core/services/preferences_service.dart';
import 'package:naiweaver/core/services/presets.dart';
import 'package:naiweaver/core/utils/image_utils.dart';
import 'package:naiweaver/features/generation/services/session_snapshot_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<PreferencesService> makeService(Map<String, Object> initial) async {
    SharedPreferences.setMockInitialValues(initial);
    final prefs = await SharedPreferences.getInstance();
    return PreferencesService(prefs, const FlutterSecureStorage());
  }

  group('PreferencesService.naiModel', () {
    test('fresh install → V4.5 Full (no auto-migration to V5)', () async {
      final s = await makeService({});
      expect(s.naiModel, NaiModel.v45Full);
    });

    test('legacy use_curated=true → V4.5 Curated', () async {
      final s = await makeService({'use_curated': true});
      expect(s.naiModel, NaiModel.v45Curated);
    });

    test('nai_model wins over use_curated and round-trips', () async {
      final s = await makeService({'use_curated': true, 'nai_model': 'nai-diffusion-5-full'});
      expect(s.naiModel, NaiModel.v5Full);
      await s.setNaiModel(NaiModel.v5Curated);
      expect(s.naiModel, NaiModel.v5Curated);
      // Legacy flag kept coherent for old builds.
      expect(s.useCurated, isTrue);
      await s.setNaiModel(NaiModel.v45Full);
      expect(s.useCurated, isFalse);
    });

    test('garbage nai_model falls back to the legacy flag', () async {
      final s = await makeService({'use_curated': true, 'nai_model': 'nope'});
      expect(s.naiModel, NaiModel.v45Curated);
    });

    test('nai_model is part of the exportable settings allowlist', () async {
      final s = await makeService({'nai_model': 'nai-diffusion-5-curated'});
      final exported = s.exportableSettings();
      expect(exported['nai_model'], 'nai-diffusion-5-curated');
    });
  });

  group('SessionSnapshot model migration', () {
    SessionSnapshot fromJson(Map<String, dynamic> j) => SessionSnapshot.fromJson({
          'prompt': '',
          'negative_prompt': '',
          'seed': '',
          ...j,
        });

    test('pre-V5 snapshot with use_curated', () {
      expect(fromJson({'use_curated': true}).model, NaiModel.v45Curated);
      expect(fromJson({'use_curated': false}).model, NaiModel.v45Full);
      expect(fromJson({}).model, NaiModel.v45Full);
      expect(fromJson({}).transparentBackground, isFalse);
    });

    test('nai_model wins, transparent flag round-trips', () {
      final snap = SessionSnapshot(
        prompt: 'p',
        negativePrompt: 'n',
        seed: '1',
        width: 832,
        height: 1216,
        scale: 7,
        steps: 23,
        sampler: 'k_euler_ancestral',
        smea: false,
        smeaDyn: false,
        decrisper: false,
        randomizeSeed: true,
        autoPositioning: false,
        activeStyleNames: const [],
        isStyleEnabled: true,
        furryMode: false,
        model: NaiModel.v5Full,
        transparentBackground: true,
        characters: const [],
        interactions: const [],
        directorReferences: const [],
        vibeTransfers: const [],
      );
      final json = snap.toJson();
      expect(json['nai_model'], 'nai-diffusion-5-full');
      expect(json['use_curated'], false); // legacy mirror
      expect(json['transparent_background'], true);
      final back = SessionSnapshot.fromJson(json);
      expect(back.model, NaiModel.v5Full);
      expect(back.transparentBackground, isTrue);
    });
  });

  group('GenerationPreset.model', () {
    test('null model is omitted from JSON and survives round-trip', () {
      final p = GenerationPreset(
        name: 'n',
        prompt: 'p',
        negativePrompt: 'u',
        width: 832,
        height: 1216,
        scale: 5,
        steps: 28,
        sampler: 'k_euler_ancestral',
        smea: false,
        smeaDyn: false,
        decrisper: false,
      );
      expect(p.toJson().containsKey('model'), isFalse);
      expect(GenerationPreset.fromJson(p.toJson()).model, isNull);
    });

    test('pinned model round-trips', () {
      final p = GenerationPreset(
        name: 'n',
        prompt: 'p',
        negativePrompt: 'u',
        width: 832,
        height: 1216,
        scale: 7,
        steps: 23,
        sampler: 'k_euler_ancestral',
        smea: false,
        smeaDyn: false,
        decrisper: false,
        model: NaiModel.v5Curated.id,
      );
      final back = GenerationPreset.fromJson(p.toJson());
      expect(back.model, 'nai-diffusion-5-curated');
      expect(NaiModel.tryParse(back.model), NaiModel.v5Curated);
    });
  });

  group('pngSupportsAlpha', () {
    Uint8List png(int colorType) {
      final b = Uint8List(40);
      const sig = [0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A];
      b.setRange(0, 8, sig);
      b[11] = 13; // IHDR length
      b.setRange(12, 16, 'IHDR'.codeUnits);
      b[25] = colorType;
      return b;
    }

    test('RGBA (6) and grey+alpha (4) are alpha; RGB (2) is not', () {
      expect(pngSupportsAlpha(png(6)), isTrue);
      expect(pngSupportsAlpha(png(4)), isTrue);
      expect(pngSupportsAlpha(png(2)), isFalse);
      expect(pngSupportsAlpha(png(0)), isFalse);
    });

    test('non-PNG / short buffers are false', () {
      expect(pngSupportsAlpha(Uint8List(3)), isFalse);
      expect(pngSupportsAlpha(Uint8List.fromList(List.filled(40, 0x52))), isFalse);
    });
  });
}
