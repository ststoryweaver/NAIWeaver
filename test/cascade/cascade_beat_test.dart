import 'package:flutter_test/flutter_test.dart';
import 'package:naiweaver/features/generation/models/nai_character.dart';
import 'package:naiweaver/features/tools/cascade/models/cascade_beat.dart';
import 'package:naiweaver/features/tools/cascade/services/cascade_stitching_service.dart';

void main() {
  group('BeatCharacterSlot action tags', () {
    test('round-trips multiple action tags through JSON', () {
      final slot = BeatCharacterSlot(
        position: NaiCoordinate(x: 0.25, y: 0.5),
        actionTags: const ['source#hugging', 'target#kissing'],
        positivePrompt: 'smiling',
        negativePrompt: 'blurry',
      );

      final restored = BeatCharacterSlot.fromJson(slot.toJson());

      expect(restored.actionTags, ['source#hugging', 'target#kissing']);
      expect(restored.positivePrompt, 'smiling');
      expect(restored.negativePrompt, 'blurry');
      expect(restored.position.x, 0.25);
    });

    test('migrates legacy single actionTag string into a one-element list', () {
      final legacyJson = {
        'position': {'x': 0.5, 'y': 0.5},
        'actionTag': 'source#hugging',
        'positivePrompt': '',
        'negativePrompt': '',
      };

      final slot = BeatCharacterSlot.fromJson(legacyJson);

      expect(slot.actionTags, ['source#hugging']);
    });

    test('legacy empty/absent actionTag yields no tags', () {
      final emptyTag = BeatCharacterSlot.fromJson({
        'position': {'x': 0.5, 'y': 0.5},
        'actionTag': '',
      });
      final absentTag = BeatCharacterSlot.fromJson({
        'position': {'x': 0.5, 'y': 0.5},
      });

      expect(emptyTag.actionTags, isEmpty);
      expect(absentTag.actionTags, isEmpty);
    });
  });

  group('CascadeBeat sceneTags', () {
    test('round-trips sceneTags through JSON', () {
      final beat = CascadeBeat(
        characterSlots: [
          BeatCharacterSlot(position: NaiCoordinate(x: 0.5, y: 0.5)),
        ],
        sceneTags: '2girls, hugging, wide shot',
        environmentTags: 'bedroom',
      );

      final restored = CascadeBeat.fromJson(beat.toJson());

      expect(restored.sceneTags, '2girls, hugging, wide shot');
      expect(restored.environmentTags, 'bedroom');
    });

    test('useCoords is omitted for legacy beats and round-trips when set', () {
      final legacy = CascadeBeat.fromJson({
        'characterSlots': [
          {
            'position': {'x': 0.5, 'y': 0.5},
          },
        ],
        'environmentTags': 'forest',
      });
      expect(legacy.useCoords, isNull);

      final explicit = CascadeBeat(
        characterSlots: [
          BeatCharacterSlot(position: NaiCoordinate(x: 0.5, y: 0.5)),
        ],
        environmentTags: 'forest',
        useCoords: false,
      );
      final restored = CascadeBeat.fromJson(explicit.toJson());
      expect(restored.useCoords, isFalse);
      expect(explicit.toJson().containsKey('useCoords'), isTrue);
    });

    test('out-of-range legacy positions load as the centre', () {
      // Pre-0.9.5 slots defaulted to (2, 2), outside NovelAI's 0..1 space.
      final legacy = BeatCharacterSlot.fromJson({
        'position': {'x': 2, 'y': 2},
      });
      expect(legacy.position.x, 0.5);
      expect(legacy.position.y, 0.5);

      // Real grid and freeform values are untouched.
      final grid = BeatCharacterSlot.fromJson({
        'position': {'x': 0.1, 'y': 0.9},
      });
      expect(grid.position.x, 0.1);
      expect(grid.position.y, 0.9);
      final free = BeatCharacterSlot.fromJson({
        'position': {'x': 0.333, 'y': 1.0},
      });
      expect(free.position.x, 0.333);
      expect(free.position.y, 1.0);
    });

    test('castIndex round-trips and legacy slots fall back to position', () {
      final beat = CascadeBeat(
        characterSlots: [
          BeatCharacterSlot(
            position: NaiCoordinate(x: 0.5, y: 0.5),
            castIndex: 2,
          ),
          BeatCharacterSlot(
            position: NaiCoordinate(x: 0.5, y: 0.5),
            castIndex: 0,
          ),
        ],
        environmentTags: '',
      );
      final restored = CascadeBeat.fromJson(beat.toJson());
      expect(restored.characterSlots.map((s) => s.castIndex), [2, 0]);

      final legacy = CascadeBeat.fromJson({
        'characterSlots': [
          {
            'position': {'x': 0.5, 'y': 0.5},
          },
          {
            'position': {'x': 0.5, 'y': 0.5},
          },
          {
            'position': {'x': 0.5, 'y': 0.5},
          },
        ],
        'environmentTags': '',
      });
      expect(legacy.characterSlots.map((s) => s.castIndex), [0, 1, 2]);
    });

    test(
      'stitching pairs each slot with its cast member, not its position',
      () {
        final beat = CascadeBeat(
          characterSlots: [
            BeatCharacterSlot(
              position: NaiCoordinate(x: 0.5, y: 0.5),
              castIndex: 1,
              positivePrompt: 'waving',
            ),
          ],
          environmentTags: '',
        );
        final request = CascadeStitchingService.render(
          beat: beat,
          appearances: const ['1girl, red hair', '1boy, black hair'],
        );
        expect(request.characters.single.prompt, '1boy, black hair, waving');
      },
    );

    test('stitching rejects a slot whose cast member has no appearance', () {
      final beat = CascadeBeat(
        characterSlots: [
          BeatCharacterSlot(
            position: NaiCoordinate(x: 0.5, y: 0.5),
            castIndex: 3,
          ),
        ],
        environmentTags: '',
      );
      expect(
        () => CascadeStitchingService.render(
          beat: beat,
          appearances: const ['a'],
        ),
        throwsArgumentError,
      );
    });

    test('legacy JSON without sceneTags loads with empty string', () {
      final legacyJson = {
        'characterSlots': [
          {
            'position': {'x': 0.5, 'y': 0.5},
          },
        ],
        'environmentTags': 'forest',
      };

      final beat = CascadeBeat.fromJson(legacyJson);

      expect(beat.sceneTags, '');
      expect(beat.environmentTags, 'forest');
    });

    test('copyWith updates sceneTags independently', () {
      final beat = CascadeBeat(
        characterSlots: const [],
        sceneTags: 'old',
        environmentTags: 'park',
      );

      final updated = beat.copyWith(sceneTags: 'new');

      expect(updated.sceneTags, 'new');
      expect(updated.environmentTags, 'park');
    });
  });

  group('CascadeStitchingService base caption ordering', () {
    test('places scene tags ahead of environment in the base caption', () {
      final beat = CascadeBeat(
        characterSlots: [
          BeatCharacterSlot(position: NaiCoordinate(x: 0.5, y: 0.5)),
        ],
        sceneTags: '2girls, hugging, wide shot',
        environmentTags: 'bedroom, night',
      );

      final request = CascadeStitchingService.render(
        beat: beat,
        appearances: const ['1girl'],
      );

      expect(request.baseCaption, '2girls, hugging, wide shot, bedroom, night');
    });

    test('scene tags lead the manual prompt and global style too', () {
      final beat = CascadeBeat(
        characterSlots: [
          BeatCharacterSlot(position: NaiCoordinate(x: 0.5, y: 0.5)),
        ],
        sceneTags: 'from above',
        environmentTags: 'rooftop',
      );

      final request = CascadeStitchingService.render(
        beat: beat,
        appearances: const ['1girl'],
        manualPrompt: 'masterpiece',
        globalStyle: 'best quality',
      );

      expect(
        request.baseCaption,
        'from above, rooftop, masterpiece, best quality',
      );
    });

    test('global scene tags lead per-beat scene and environment', () {
      final beat = CascadeBeat(
        characterSlots: [
          BeatCharacterSlot(position: NaiCoordinate(x: 0.5, y: 0.5)),
        ],
        sceneTags: 'hugging',
        environmentTags: 'bedroom',
      );

      final request = CascadeStitchingService.render(
        beat: beat,
        appearances: const ['1girl'],
        globalSceneTags: '2girls, school uniform',
        globalStyle: 'best quality',
      );

      expect(
        request.baseCaption,
        '2girls, school uniform, hugging, bedroom, best quality',
      );
    });

    test('blank global scene tags are omitted', () {
      final beat = CascadeBeat(
        characterSlots: [
          BeatCharacterSlot(position: NaiCoordinate(x: 0.5, y: 0.5)),
        ],
        sceneTags: 'hugging',
        environmentTags: 'bedroom',
      );

      final request = CascadeStitchingService.render(
        beat: beat,
        appearances: const ['1girl'],
        globalSceneTags: '   ',
      );

      expect(request.baseCaption, 'hugging, bedroom');
    });

    test('empty scene tags leave the base caption unchanged', () {
      final beat = CascadeBeat(
        characterSlots: [
          BeatCharacterSlot(position: NaiCoordinate(x: 0.5, y: 0.5)),
        ],
        environmentTags: 'beach',
      );

      final request = CascadeStitchingService.render(
        beat: beat,
        appearances: const ['1boy'],
      );

      expect(request.baseCaption, 'beach');
    });
  });

  group('CascadeStitchingService multi-tag rendering', () {
    test('prepends every action tag before appearance and positive prompt', () {
      final beat = CascadeBeat(
        characterSlots: [
          BeatCharacterSlot(
            position: NaiCoordinate(x: 0.5, y: 0.5),
            actionTags: const ['source#hugging', 'target#kissing'],
            positivePrompt: 'smiling',
          ),
        ],
        environmentTags: 'bedroom',
      );

      final request = CascadeStitchingService.render(
        beat: beat,
        appearances: const ['1girl, blue hair'],
      );

      expect(
        request.characters.single.prompt,
        'source#hugging, target#kissing, 1girl, blue hair, smiling',
      );
    });

    test('renders cleanly with no action tags', () {
      final beat = CascadeBeat(
        characterSlots: [
          BeatCharacterSlot(position: NaiCoordinate(x: 0.5, y: 0.5)),
        ],
        environmentTags: 'park',
      );

      final request = CascadeStitchingService.render(
        beat: beat,
        appearances: const ['1boy'],
      );

      expect(request.characters.single.prompt, '1boy');
    });
  });
}
