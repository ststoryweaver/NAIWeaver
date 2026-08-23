import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:naiweaver/core/models/nai_model.dart';
import 'package:naiweaver/core/services/nai_request_builder.dart';
import 'package:naiweaver/features/generation/models/nai_character.dart';

NaiCharacter _char(String prompt, double x, double y, {String uc = ''}) =>
    NaiCharacter(prompt: prompt, uc: uc, center: NaiCoordinate(x: x, y: y));

Map<String, dynamic> _params(Map<String, dynamic> body) =>
    body['parameters'] as Map<String, dynamic>;

void main() {
  group('V4.5 body (must stay what the app has always sent)', () {
    test('plain txt2img', () {
      final body = buildNaiGenerateBody(
        model: NaiModel.v45Full,
        prompt: '1girl, smile',
        width: 832,
        height: 1216,
        seed: 42,
        steps: 28,
        scale: 6.0,
        negativePrompt: 'lowres',
        promptPrefix: 'best quality, ',
        promptSuffix: ', very aesthetic',
      );
      expect(body['model'], 'nai-diffusion-4-5-full');
      expect(body['action'], 'generate');
      expect(body['input'], 'best quality, 1girl, smile, very aesthetic');
      final p = _params(body);
      expect(p.keys.toList(), [
        'params_version',
        'width',
        'height',
        'scale',
        'sampler',
        'steps',
        'seed',
        'n_samples',
        'noise_schedule',
        'sm',
        'sm_dyn',
        'dynamic_thresholding',
        // NovelAI's own V4.5 body carries both of these (research doc §2.4:
        // cfg_rescale 0, skip_cfg_above_sigma null).
        'cfg_rescale',
        'skip_cfg_above_sigma',
        'uc',
        'v4_prompt',
        'v4_negative_prompt',
      ]);
      expect(p['params_version'], 3);
      expect(p['noise_schedule'], 'karras');
      expect(p['sm'], false);
      expect(p['sm_dyn'], false);
      expect(p['dynamic_thresholding'], false);
      expect(p['cfg_rescale'], 0);
      expect(p['skip_cfg_above_sigma'], isNull);
      expect(p['uc'], 'lowres');
      expect(p['v4_prompt']['caption']['base_caption'], 'best quality, 1girl, smile, very aesthetic');
      expect(p['v4_prompt']['use_coords'], false);
      expect(p['v4_prompt']['use_order'], true);
      expect(p['v4_negative_prompt']['caption']['base_caption'], 'lowres');
      expect(p.containsKey('straight_alpha'), isFalse);
      expect(p.containsKey('prefer_brownian'), isFalse);
    });

    test('sm:true from an old preset is neutralised (NovelAI returns 500)', () {
      final p = _params(buildNaiGenerateBody(
        model: NaiModel.v45Curated,
        prompt: 'x',
        width: 64,
        height: 64,
        seed: 1,
        smea: true,
        smeaDyn: true,
        decrisper: true,
      ));
      expect(p['sm'], false);
      expect(p['sm_dyn'], false);
      expect(p['dynamic_thresholding'], false);
    });

    test('characters keep grid centers, interactions, characterPrompts mirror', () {
      final p = _params(buildNaiGenerateBody(
        model: NaiModel.v45Full,
        prompt: 'two people',
        width: 64,
        height: 64,
        seed: 1,
        characters: [_char('girl', 0.3, 0.5, uc: 'bad hands'), _char('boy', 0.7, 0.5)],
        interactions: [
          NaiInteraction(
            sourceCharacterIndices: [0],
            targetCharacterIndices: [1],
            actionName: 'hug',
            type: InteractionType.sourceTarget,
          ),
        ],
      ));
      final caps = p['v4_prompt']['caption']['char_captions'] as List;
      expect(caps[0]['char_caption'], 'source#hug, girl');
      expect(caps[1]['char_caption'], 'target#hug, boy');
      expect(caps[0]['centers'], [
        {'x': 0.3, 'y': 0.5}
      ]);
      expect(p['v4_prompt']['use_coords'], true);
      expect((p['characterPrompts'] as List).length, 2);
      expect(p['characterPrompts'][0]['center'], {'x': 0.3, 'y': 0.5});
      final neg = p['v4_negative_prompt']['caption']['char_captions'] as List;
      expect(neg[0]['char_caption'], 'bad hands');
      expect(neg[0]['centers'], [
        {'x': 0.3, 'y': 0.5}
      ]);
    });

    test('vibe arrays are sent on V4.5 when no director ref is set', () {
      final p = _params(buildNaiGenerateBody(
        model: NaiModel.v45Full,
        prompt: 'x',
        width: 64,
        height: 64,
        seed: 1,
        vibeTransferImages: ['VIBE'],
        vibeTransferStrengths: [0.6],
        vibeTransferInfoExtracted: [1.0],
      ));
      expect(p['reference_image_multiple'], ['VIBE']);
      expect(p['reference_strength_multiple'], [0.6]);
      expect(p['reference_information_extracted_multiple'], [1.0]);
    });

    test('director arrays are sent on V4.5', () {
      final p = _params(buildNaiGenerateBody(
        model: NaiModel.v45Full,
        prompt: 'x',
        width: 64,
        height: 64,
        seed: 1,
        directorRefImages: ['REF'],
        directorRefDescriptions: [
          {'caption': {'base_caption': 'character&style', 'char_captions': []}, 'legacy_uc': false}
        ],
        directorRefStrengths: [1.0],
        directorRefSecondaryStrengths: [1.0],
        directorRefInfoExtracted: [1.0],
      ));
      expect(p['director_reference_images'], ['REF']);
      expect(p['director_reference_strength_values'], [1.0]);
    });

    // Issue #24: NovelAI's UI hides Vibe once a Director reference is set, and
    // sending both returns a ZIP with an empty/truncated image entry, which
    // the app used to save as a corrupt file (and then froze the gallery on).
    test('vibe is dropped when a director ref is present (issue #24)', () {
      final p = _params(buildNaiGenerateBody(
        model: NaiModel.v45Full,
        prompt: 'x',
        width: 64,
        height: 64,
        seed: 1,
        vibeTransferImages: ['VIBE'],
        vibeTransferStrengths: [0.6],
        vibeTransferInfoExtracted: [1.0],
        directorRefImages: ['REF'],
        directorRefDescriptions: [
          {'caption': {'base_caption': 'character&style', 'char_captions': []}, 'legacy_uc': false}
        ],
        directorRefStrengths: [1.0],
        directorRefSecondaryStrengths: [1.0],
        directorRefInfoExtracted: [1.0],
      ));
      // Director wins, matching NovelAI's own frontend.
      expect(p['director_reference_images'], ['REF']);
      for (final k in p.keys) {
        expect(k.startsWith('reference_'), isFalse,
            reason: 'vibe key "$k" must not be sent alongside a director ref');
      }
    });

    test('noise_schedule honours a supported choice on V4.5', () {
      for (final schedule in ['exponential', 'polyexponential', 'karras']) {
        final p = _params(buildNaiGenerateBody(
          model: NaiModel.v45Full,
          prompt: 'x',
          width: 64,
          height: 64,
          seed: 1,
          noiseSchedule: schedule,
        ));
        expect(p['noise_schedule'], schedule);
      }
    });

    test('an unsupported noise_schedule falls back to the model default', () {
      for (final schedule in ['native', 'nonsense', '']) {
        final p = _params(buildNaiGenerateBody(
          model: NaiModel.v45Full,
          prompt: 'x',
          width: 64,
          height: 64,
          seed: 1,
          noiseSchedule: schedule,
        ));
        expect(p['noise_schedule'], 'karras');
      }
    });

    test('cfg_rescale defaults to 0 and honours an explicit value', () {
      final dflt = _params(buildNaiGenerateBody(
        model: NaiModel.v45Full,
        prompt: 'x',
        width: 64,
        height: 64,
        seed: 1,
      ));
      expect(dflt['cfg_rescale'], 0);

      final set = _params(buildNaiGenerateBody(
        model: NaiModel.v45Full,
        prompt: 'x',
        width: 64,
        height: 64,
        seed: 1,
        cfgRescale: 0.4,
      ));
      expect(set['cfg_rescale'], 0.4);
    });

    test('skip_cfg_above_sigma is null when Variety+ is off, set when on', () {
      final off = _params(buildNaiGenerateBody(
        model: NaiModel.v45Full,
        prompt: 'x',
        width: 64,
        height: 64,
        seed: 1,
      ));
      expect(off.containsKey('skip_cfg_above_sigma'), isTrue);
      expect(off['skip_cfg_above_sigma'], isNull);

      final on = _params(buildNaiGenerateBody(
        model: NaiModel.v45Full,
        prompt: 'x',
        width: 64,
        height: 64,
        seed: 1,
        varietyBoostSigma: 58.0,
      ));
      expect(on['skip_cfg_above_sigma'], 58.0);
    });

    test('img2img / infill fields and inpaint model id', () {
      final img = buildNaiGenerateBody(
        model: NaiModel.v45Curated,
        prompt: 'x',
        width: 64,
        height: 64,
        seed: 7,
        action: 'img2img',
        sourceImageBase64: 'SRC',
        img2imgStrength: 0.5,
        img2imgNoise: 0.1,
      );
      expect(img['model'], 'nai-diffusion-4-5-curated');
      final ip = _params(img);
      expect(ip['image'], 'SRC');
      expect(ip['strength'], 0.5);
      expect(ip['noise'], 0.1);
      expect(ip['extra_noise_seed'], 7);
      expect(ip['add_original_image'], true);

      final infill = buildNaiGenerateBody(
        model: NaiModel.v45Curated,
        prompt: 'x',
        width: 64,
        height: 64,
        seed: 7,
        action: 'infill',
        sourceImageBase64: 'SRC',
        maskBase64: 'MASK',
        img2imgStrength: 1.0,
        maskBlur: 4,
      );
      expect(infill['model'], 'nai-diffusion-4-5-curated-inpainting');
      expect(_params(infill)['mask'], 'MASK');
      expect(_params(infill)['mask_blur'], 4);
      expect(_params(infill).containsKey('noise'), isFalse);
    });

    test('no autoText on V4.5', () {
      final body = buildNaiGenerateBody(
        model: NaiModel.v45Full,
        prompt: 'sign reading "OPEN"',
        width: 64,
        height: 64,
        seed: 1,
      );
      expect(body['input'], 'sign reading "OPEN"');
    });
  });

  group('V5 body (NovelAI frontend sanitiser)', () {
    test('drops sm/sm_dyn, forces karras, params_version 4, brownian flags', () {
      final p = _params(buildNaiGenerateBody(
        model: NaiModel.v5Full,
        prompt: '1girl',
        width: 832,
        height: 1216,
        seed: 1,
        smea: true,
        smeaDyn: true,
        decrisper: true,
      ));
      expect(p['params_version'], 4);
      expect(p.containsKey('sm'), isFalse);
      expect(p.containsKey('sm_dyn'), isFalse);
      expect(p['dynamic_thresholding'], false);
      expect(p['noise_schedule'], 'karras');
      expect(p['deliberate_euler_ancestral_bug'], false);
      expect(p['prefer_brownian'], true);
      expect(p.containsKey('straight_alpha'), isFalse);
      expect(p.containsKey('tag_hint_transparent_background'), isFalse);
    });

    test('brownian flags only for Euler Ancestral; ddim is remapped', () {
      final p = _params(buildNaiGenerateBody(
        model: NaiModel.v5Full,
        prompt: 'x',
        width: 64,
        height: 64,
        seed: 1,
        sampler: 'k_dpmpp_2m',
      ));
      expect(p['sampler'], 'k_dpmpp_2m');
      expect(p.containsKey('prefer_brownian'), isFalse);

      final d = _params(buildNaiGenerateBody(
        model: NaiModel.v5Full,
        prompt: 'x',
        width: 64,
        height: 64,
        seed: 1,
        sampler: 'ddim',
      ));
      expect(d['sampler'], 'k_euler_ancestral');
      expect(d['prefer_brownian'], true);
    });

    test('V5 forces its noise schedule and drops Variety+', () {
      final p = _params(buildNaiGenerateBody(
        model: NaiModel.v5Full,
        prompt: 'x',
        width: 64,
        height: 64,
        seed: 1,
        // Both of these are unsupported on V5 and must not leak through.
        noiseSchedule: 'exponential',
        varietyBoostSigma: 58.0,
      ));
      expect(p['noise_schedule'], 'karras');
      expect(p.containsKey('skip_cfg_above_sigma'), isFalse);
      // cfg_rescale IS supported on V5.
      expect(p['cfg_rescale'], 0);
    });

    test('vibe + director arrays are NOT sent on V5', () {
      final p = _params(buildNaiGenerateBody(
        model: NaiModel.v5Curated,
        prompt: 'x',
        width: 64,
        height: 64,
        seed: 1,
        vibeTransferImages: ['VIBE'],
        vibeTransferStrengths: [0.6],
        vibeTransferInfoExtracted: [1.0],
        directorRefImages: ['REF'],
        directorRefStrengths: [1.0],
      ));
      for (final k in p.keys) {
        expect(k.startsWith('reference_'), isFalse, reason: k);
        expect(k.startsWith('director_'), isFalse, reason: k);
      }
    });

    test('raw 3-dp character centers, 32-character cap', () {
      final chars = List.generate(40, (i) => _char('c$i', 0.123456, 0.98765));
      final p = _params(buildNaiGenerateBody(
        model: NaiModel.v5Full,
        prompt: 'crowd',
        width: 64,
        height: 64,
        seed: 1,
        characters: chars,
      ));
      final caps = p['v4_prompt']['caption']['char_captions'] as List;
      expect(caps.length, 32);
      expect(caps.first['centers'], [
        {'x': 0.123, 'y': 0.988}
      ]);
      expect((p['characterPrompts'] as List).length, 32);
      expect((p['v4_negative_prompt']['caption']['char_captions'] as List).length, 32);
      expect(p['v4_negative_prompt']['caption']['char_captions'][0]['centers'], [
        {'x': 0.123, 'y': 0.988}
      ]);
    });

    test('V4.5 caps characters at 6', () {
      final chars = List.generate(10, (i) => _char('c$i', 0.5, 0.5));
      final p = _params(buildNaiGenerateBody(
        model: NaiModel.v45Full,
        prompt: 'crowd',
        width: 64,
        height: 64,
        seed: 1,
        characters: chars,
      ));
      expect((p['v4_prompt']['caption']['char_captions'] as List).length, 6);
    });

    test('transparent background: prompt tag + alpha fields', () {
      final body = buildNaiGenerateBody(
        model: NaiModel.v5Full,
        prompt: '1girl',
        width: 64,
        height: 64,
        seed: 1,
        promptSuffix: ', very aesthetic, masterpiece, no text',
        transparentBackground: true,
      );
      expect(body['input'], '1girl, transparent background, very aesthetic, masterpiece, no text');
      final p = _params(body);
      expect(p['straight_alpha'], true);
      expect(p['tag_hint_transparent_background'], true);
    });

    test('transparent background is ignored on V4.5', () {
      final body = buildNaiGenerateBody(
        model: NaiModel.v45Full,
        prompt: '1girl',
        width: 64,
        height: 64,
        seed: 1,
        transparentBackground: true,
      );
      expect(body['input'], '1girl');
      expect(_params(body).containsKey('straight_alpha'), isFalse);
    });

    test('inpaint ids: V5 Full own, V5 Curated → V4.5 Curated inpaint', () {
      Map<String, dynamic> infill(NaiModel m) => buildNaiGenerateBody(
            model: m,
            prompt: 'x',
            width: 64,
            height: 64,
            seed: 1,
            action: 'infill',
            sourceImageBase64: 'S',
            maskBase64: 'M',
          );
      expect(infill(NaiModel.v5Full)['model'], 'nai-diffusion-5-full-inpainting');
      expect(infill(NaiModel.v5Curated)['model'], 'nai-diffusion-4-5-curated-inpainting');
    });

    test('V5 Curated infill body is V4.5-shaped for the V4.5 wire model', () {
      // The wire model is nai-diffusion-4-5-curated-inpainting, so a V5-shaped
      // block (params_version 4, no sm keys, prefer_brownian, straight_alpha)
      // must not be sent — the API 500s over mis-shaped bodies (cf. sm: true).
      final body = buildNaiGenerateBody(
        model: NaiModel.v5Curated,
        prompt: 'x',
        width: 64,
        height: 64,
        seed: 1,
        action: 'infill',
        sourceImageBase64: 'S',
        maskBase64: 'M',
        transparentBackground: true,
      );
      final p = body['parameters'] as Map<String, dynamic>;
      expect(p['params_version'], 3);
      expect(p['sm'], false);
      expect(p['sm_dyn'], false);
      expect(p.containsKey('prefer_brownian'), isFalse);
      expect(p.containsKey('deliberate_euler_ancestral_bug'), isFalse);
      expect(p.containsKey('straight_alpha'), isFalse);

      // V5 Full inpaints through a real V5 model — its body stays V5-shaped.
      final v5 = buildNaiGenerateBody(
        model: NaiModel.v5Full,
        prompt: 'x',
        width: 64,
        height: 64,
        seed: 1,
        action: 'infill',
        sourceImageBase64: 'S',
        maskBase64: 'M',
      );
      final v5p = v5['parameters'] as Map<String, dynamic>;
      expect(v5p['params_version'], 4);
      expect(v5p.containsKey('sm'), isFalse);
      expect(v5p['prefer_brownian'], true);
    });

    test('autoText: quoted strings become a Text: block, manual Text: wins', () {
      final a = buildNaiGenerateBody(
        model: NaiModel.v5Full,
        prompt: 'a sign reading "OPEN", neon',
        width: 64,
        height: 64,
        seed: 1,
      );
      expect(a['input'], 'a sign reading "OPEN", neon\nText: OPEN');
      expect(_params(a)['v4_prompt']['caption']['base_caption'], 'a sign reading "OPEN", neon\nText: OPEN');

      final b = buildNaiGenerateBody(
        model: NaiModel.v5Full,
        prompt: 'a sign reading "OPEN"\nText: CLOSED',
        width: 64,
        height: 64,
        seed: 1,
      );
      expect(b['input'], 'a sign reading "OPEN"\nText: CLOSED');

      final c = buildNaiGenerateBody(
        model: NaiModel.v5Full,
        prompt: '看板に「営業中」',
        width: 64,
        height: 64,
        seed: 1,
      );
      expect(c['input'], '看板に「営業中」\nText: 営業中');
    });

    test('applyAutoText joins multiple quotes and ignores empty ones', () {
      expect(applyAutoText('"A" and "B" and ""'), '"A" and "B" and ""\nText: A, B');
      expect(applyAutoText('no quotes'), 'no quotes');
      expect(applyAutoText('x\ntext: already'), 'x\ntext: already');
    });

    test('body is JSON-encodable', () {
      final body = buildNaiGenerateBody(
        model: NaiModel.v5Full,
        prompt: 'x',
        width: 64,
        height: 64,
        seed: 1,
        characters: [_char('a', 0.2, 0.8)],
        transparentBackground: true,
      );
      expect(() => jsonEncode(body), returnsNormally);
    });
  });

  test('sanitizePromptForNai strips backslashes', () {
    expect(sanitizePromptForNai(r'a\b\\c'), 'abc');
    expect(sanitizePromptForNai(null), '');
  });
}
