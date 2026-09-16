import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:naiweaver/features/generation/models/nai_character.dart';
import 'package:naiweaver/features/tools/cascade/models/cascade_beat.dart';
import 'package:naiweaver/features/tools/cascade/models/prompt_cascade.dart';
import 'package:naiweaver/features/tools/cascade/providers/cascade_notifier.dart';

/// A distinct 1-byte preview per beat so we can assert which beat each preview
/// ends up attached to after a structural change.
Uint8List _preview(int tag) => Uint8List.fromList([tag]);

CascadeBeat _beat() => CascadeBeat(
  characterSlots: [BeatCharacterSlot(position: NaiCoordinate(x: 2, y: 2))],
  environmentTags: '',
);

PromptCascade _cascade(int beatCount) => PromptCascade(
  name: 'test',
  characterCount: 1,
  beats: List.generate(beatCount, (_) => _beat()),
);

/// Seeds a notifier with [beatCount] beats and a preview+caption on each,
/// tagged by index so re-association is observable.
CascadeNotifier _seeded(int beatCount) {
  final n = CascadeNotifier();
  n.setActiveCascade(_cascade(beatCount));
  for (var i = 0; i < beatCount; i++) {
    n.setBeatPreview(i, _preview(i));
    n.setBeatCaption(i, 'caption-$i');
  }
  return n;
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('CascadeNotifier cast-time map remapping', () {
    test('removeBeat drops the removed beat and shifts later entries down', () {
      final n = _seeded(
        4,
      ); // beats 0,1,2,3 each with preview/caption tagged by index
      n.removeBeat(1);

      final s = n.state;
      expect(s.activeCascade!.beats.length, 3);
      // Old beat 0 unchanged; old beats 2,3 slide into slots 1,2.
      expect(s.beatPreviews[0], _preview(0));
      expect(s.beatPreviews[1], _preview(2));
      expect(s.beatPreviews[2], _preview(3));
      expect(s.beatPreviews.containsKey(3), isFalse);
      expect(s.beatCaptions[0], 'caption-0');
      expect(s.beatCaptions[1], 'caption-2');
      expect(s.beatCaptions[2], 'caption-3');
      expect(s.beatCaptions.containsKey(3), isFalse);
    });

    test('cloneBeat shifts later entries up and leaves the new slot empty', () {
      final n = _seeded(3); // beats 0,1,2
      n.cloneBeat(0); // insert clone at index 1

      final s = n.state;
      expect(s.activeCascade!.beats.length, 4);
      // Slot 0 keeps its preview; slot 1 (the clone) is un-generated; old 1,2
      // move to slots 2,3.
      expect(s.beatPreviews[0], _preview(0));
      expect(s.beatPreviews.containsKey(1), isFalse);
      expect(s.beatPreviews[2], _preview(1));
      expect(s.beatPreviews[3], _preview(2));
      expect(s.beatCaptions[0], 'caption-0');
      expect(s.beatCaptions.containsKey(1), isFalse);
      expect(s.beatCaptions[2], 'caption-1');
      expect(s.beatCaptions[3], 'caption-2');
    });

    test('beatSavedBasenames follow clone/remove/reorder like previews', () {
      final n = _seeded(3);
      n.setBeatSavedBasename(0, 'a.png');
      n.setBeatSavedBasename(1, 'b.png');
      n.setBeatSavedBasename(2, 'c.png');

      n.cloneBeat(0);
      expect(n.state.beatSavedBasenames[0], 'a.png');
      expect(n.state.beatSavedBasenames.containsKey(1), isFalse);
      expect(n.state.beatSavedBasenames[2], 'b.png');
      expect(n.state.beatSavedBasenames[3], 'c.png');

      n.removeBeat(2); // drop old beat 1 ('b.png')
      expect(n.state.beatSavedBasenames[0], 'a.png');
      expect(n.state.beatSavedBasenames.containsKey(1), isFalse);
      expect(n.state.beatSavedBasenames[2], 'c.png');
    });

    test(
      'recordBasenameForImage binds the filename to the matching preview',
      () {
        final n = _seeded(2);
        final img = n.state.beatPreviews[1]!;
        n.recordBasenameForImage(img, 'beat-1.png');
        expect(n.state.beatSavedBasenames[1], 'beat-1.png');
        expect(n.state.beatSavedBasenames.containsKey(0), isFalse);
      },
    );

    test('reorderBeats carries each beat\'s preview to its new position', () {
      final n = _seeded(3); // beats 0,1,2
      // Move beat 0 to the end (ReorderableListView convention: newIndex past end).
      n.reorderBeats(0, 3);

      final s = n.state;
      // Resulting beat order is [1, 2, 0]; previews must follow.
      expect(s.beatPreviews[0], _preview(1));
      expect(s.beatPreviews[1], _preview(2));
      expect(s.beatPreviews[2], _preview(0));
      expect(s.beatCaptions[0], 'caption-1');
      expect(s.beatCaptions[1], 'caption-2');
      expect(s.beatCaptions[2], 'caption-0');
    });
  });

  group('CascadeNotifier.applySceneToAllBeats', () {
    test('copies the scene tags onto every beat', () {
      final n = CascadeNotifier();
      n.setActiveCascade(_cascade(3));
      n.applySceneToAllBeats('hugging, wide shot');

      for (final beat in n.state.activeCascade!.beats) {
        expect(beat.sceneTags, 'hugging, wide shot');
      }
    });
  });

  group('CascadeNotifier.createNewCascade', () {
    test('seeds one appearance slot per character so beats can render', () {
      final n = CascadeNotifier();
      n.createNewCascade('fresh', 2);

      // Regression: createNewCascade used to leave characterAppearances empty,
      // so CascadeStitchingService.render threw "Not enough character
      // appearances" and beat generation silently no-op'd.
      expect(n.state.characterAppearances.length, 2);
      expect(n.state.characterAppearances, ['', '']);
    });

    test('clears cast-time state carried over from a previous cascade', () {
      final n = CascadeNotifier();
      n.setActiveCascade(_cascade(2));
      n.updateAppearance(0, 'miku, blue hair');
      n.updateGlobalInjection('masterpiece');
      n.setBeatPreview(0, _preview(0));
      n.setBeatCaption(0, 'old caption');

      n.createNewCascade('brand new', 1);

      expect(n.state.characterAppearances, ['']);
      expect(n.state.globalInjection, '');
      expect(n.state.globalSceneTags, '');
      expect(n.state.beatPreviews, isEmpty);
      expect(n.state.beatCaptions, isEmpty);
    });
  });

  group('CascadeNotifier per-beat characters', () {
    test('addCharacterToActiveBeat grows the beat and the cast roster', () {
      final n = CascadeNotifier();
      n.createNewCascade('cast', 1);

      n.addCharacterToActiveBeat();

      final beat = n.state.activeCascade!.beats.first;
      expect(beat.characterSlots.length, 2);
      expect(n.state.activeCascade!.characterCount, 2);
      expect(n.state.characterAppearances.length, 2);
    });

    test(
      'removeCharacterFromActiveBeat drops the slot and shrinks roster when unused',
      () {
        final n = CascadeNotifier();
        n.createNewCascade('cast', 2);
        n.updateAppearance(1, 'second');

        n.removeCharacterFromActiveBeat(1);

        expect(n.state.activeCascade!.beats.first.characterSlots.length, 1);
        expect(n.state.activeCascade!.characterCount, 1);
        expect(n.state.characterAppearances, ['']);
      },
    );

    test(
      'removing a slot from one beat does not shrink roster used by another beat',
      () {
        final n = CascadeNotifier();
        n.createNewCascade('cast', 2);
        n.addBeat();
        n.selectBeat(0);
        n.removeCharacterFromActiveBeat(1);

        expect(n.state.activeCascade!.beats[0].characterSlots.length, 1);
        expect(n.state.activeCascade!.beats[1].characterSlots.length, 2);
        expect(n.state.activeCascade!.characterCount, 2);
        expect(n.state.characterAppearances.length, 2);
      },
    );

    test('removing the first slot keeps the second character\'s identity', () {
      final n = CascadeNotifier();
      n.createNewCascade('cast', 2);
      n.updateAppearance(0, 'red hair');
      n.updateAppearance(1, 'black hair');
      n.addBeat(); // beat 1 also has C1 + C2

      n.removeCharacterFromActiveBeat(0); // beat 1: C2 alone

      final solo = n.state.activeCascade!.beats[1].characterSlots.single;
      expect(solo.castIndex, 1);
      // Cast is unchanged because beat 0 still uses both characters.
      expect(n.state.activeCascade!.characterCount, 2);
      expect(n.state.characterAppearances, ['red hair', 'black hair']);
    });

    test('a character no beat uses is dropped and the rest renumbered', () {
      final n = CascadeNotifier();
      n.createNewCascade('cast', 3);
      n.updateAppearance(0, 'a');
      n.updateAppearance(1, 'b');
      n.updateAppearance(2, 'c');

      n.removeCharacterFromActiveBeat(0); // C1 gone everywhere

      final slots = n.state.activeCascade!.beats.single.characterSlots;
      expect(slots.map((s) => s.castIndex), [0, 1]);
      expect(n.state.activeCascade!.characterCount, 2);
      expect(n.state.characterAppearances, ['b', 'c']);
    });

    test('addCharacterToActiveBeat can re-add an existing cast member', () {
      final n = CascadeNotifier();
      n.createNewCascade('cast', 2);
      n.addBeat();
      n.removeCharacterFromActiveBeat(0); // beat 1: C2 only
      expect(n.castMembersMissingFromActiveBeat(), [0]);

      n.addCharacterToActiveBeat(castIndex: 0);

      final slots = n.state.activeCascade!.beats[1].characterSlots;
      expect(slots.map((s) => s.castIndex), [1, 0]);
      expect(n.state.activeCascade!.characterCount, 2);
      expect(n.castMembersMissingFromActiveBeat(), isEmpty);
      // Same member twice on one beat is refused.
      n.addCharacterToActiveBeat(castIndex: 0);
      expect(n.state.activeCascade!.beats[1].characterSlots.length, 2);
    });

    test('addCharacterToActiveBeat without castIndex grows the cast', () {
      final n = CascadeNotifier();
      n.createNewCascade('cast', 1);
      n.addCharacterToActiveBeat();
      final slots = n.state.activeCascade!.beats.single.characterSlots;
      expect(slots.map((s) => s.castIndex), [0, 1]);
      expect(n.state.activeCascade!.characterCount, 2);
    });

    test('addBeat inherits the previous beat cast, not its slot count', () {
      final n = CascadeNotifier();
      n.createNewCascade('cast', 2);
      n.addBeat(); // beat 1: C1 + C2
      n.removeCharacterFromActiveBeat(0); // beat 1: C2 only
      n.addBeat(); // beat 2 should open with C2 only
      final added = n.state.activeCascade!.beats.last.characterSlots;
      expect(added.map((s) => s.castIndex), [1]);
      expect(n.state.activeCascade!.characterCount, 2);
    });

    test('removing a slot prunes action tags that lost their partner', () {
      final n = CascadeNotifier();
      n.createNewCascade('cast', 3);
      final beat = n.state.activeCascade!.beats.single;
      n.updateActiveBeat(
        beat.copyWith(
          characterSlots: [
            beat.characterSlots[0].copyWith(actionTags: ['source#hugging']),
            beat.characterSlots[1].copyWith(
              actionTags: ['target#hugging', 'mutual#holding hands'],
            ),
            beat.characterSlots[2].copyWith(
              actionTags: ['mutual#holding hands'],
            ),
          ],
        ),
      );

      n.removeCharacterFromActiveBeat(0); // the hugger leaves

      final slots = n.state.activeCascade!.beats.single.characterSlots;
      expect(slots[0].actionTags, ['mutual#holding hands']);
      expect(slots[1].actionTags, ['mutual#holding hands']);
    });

    test('reorderCharactersInActiveBeat keeps cast identity with the slot', () {
      final n = CascadeNotifier();
      n.createNewCascade('cast', 2);
      n.reorderCharactersInActiveBeat(0, 2);
      final slots = n.state.activeCascade!.beats.single.characterSlots;
      expect(slots.map((s) => s.castIndex), [1, 0]);
    });

    test('reorderCharactersInActiveBeat swaps slot data', () {
      final n = CascadeNotifier();
      n.createNewCascade('cast', 2);
      final beat = n.state.activeCascade!.beats.first;
      n.updateActiveBeat(
        beat.copyWith(
          characterSlots: [
            beat.characterSlots[0].copyWith(positivePrompt: 'alpha'),
            beat.characterSlots[1].copyWith(positivePrompt: 'beta'),
          ],
        ),
      );

      n.reorderCharactersInActiveBeat(0, 2);

      final slots = n.state.activeCascade!.beats.first.characterSlots;
      expect(slots.map((s) => s.positivePrompt).toList(), ['beta', 'alpha']);
    });

    test('setActiveBeatUseCoords overrides cascade-level placement', () {
      final n = CascadeNotifier();
      n.createNewCascade('cast', 1, useCoords: true);
      expect(
        n.state.activeCascade!.effectiveUseCoords(
          n.state.activeCascade!.beats.first,
        ),
        isTrue,
      );

      n.setActiveBeatUseCoords(false);

      final beat = n.state.activeCascade!.beats.first;
      expect(beat.useCoords, isFalse);
      expect(n.state.activeCascade!.effectiveUseCoords(beat), isFalse);
      expect(n.state.activeCascade!.useCoords, isTrue);
    });

    test('addBeat copies the last beat cast and placement', () {
      final n = CascadeNotifier();
      n.createNewCascade('cast', 1, useCoords: true);
      n.addCharacterToActiveBeat();
      n.setActiveBeatUseCoords(false);
      n.addBeat();

      final added = n.state.activeCascade!.beats.last;
      expect(added.characterSlots.length, 2);
      expect(added.useCoords, isFalse);
    });
  });

  group('CascadeNotifier per-beat save bookkeeping', () {
    test('setBeatSavedBasename(null) forgets a stale filename', () {
      final n = _seeded(2);
      n.setBeatSavedBasename(1, 'old.png');
      expect(n.state.beatSavedBasenames[1], 'old.png');

      // A regenerate with auto-save off yields no filename: the previous
      // render's name must not stick to the new pixels.
      n.setBeatSavedBasename(1, null);

      expect(n.state.beatSavedBasenames.containsKey(1), isFalse);
      expect(n.state.beatSavedBasenames, isEmpty);
    });

    test(
      'setBeatPreview stores metadata per beat and drops it when absent',
      () {
        final n = _seeded(2);
        n.setBeatPreview(0, _preview(10), metadata: {'seed': 1});
        n.setBeatPreview(1, _preview(11), metadata: {'seed': 2});
        expect(n.state.beatMetadata[0], {'seed': 1});
        expect(n.state.beatMetadata[1], {'seed': 2});

        n.setBeatPreview(0, _preview(12));

        expect(n.state.beatMetadata.containsKey(0), isFalse);
        expect(n.state.beatMetadata[1], {'seed': 2});
      },
    );

    test('beat metadata travels with its beat on remove and reorder', () {
      final n = _seeded(3);
      for (var i = 0; i < 3; i++) {
        n.setBeatPreview(i, _preview(i), metadata: {'beat': i});
      }

      n.removeBeat(0);
      expect(n.state.beatMetadata[0], {'beat': 1});
      expect(n.state.beatMetadata[1], {'beat': 2});

      n.reorderBeats(0, 2);
      expect(n.state.beatMetadata[0], {'beat': 2});
      expect(n.state.beatMetadata[1], {'beat': 1});
    });

    test('exiting cascade mode clears beat metadata', () {
      final n = _seeded(1);
      n.setBeatPreview(0, _preview(0), metadata: {'beat': 0});
      n.exitCascadeMode();
      expect(n.state.beatMetadata, isEmpty);
    });
  });

  group('CascadeNotifier.pruneOrphanActionTags roles', () {
    BeatCharacterSlot slot(List<String> tags) => BeatCharacterSlot(
      position: NaiCoordinate(x: 0.5, y: 0.5),
      actionTags: tags,
    );

    test('two sources of the same action do not keep each other', () {
      final pruned = CascadeNotifier.pruneOrphanActionTags([
        slot(['source#hug']),
        slot(['source#hug']),
      ]);
      expect(pruned[0].actionTags, isEmpty);
      expect(pruned[1].actionTags, isEmpty);
    });

    test('source and target pair up; a mutual needs another mutual', () {
      final pruned = CascadeNotifier.pruneOrphanActionTags([
        slot(['source#hug', 'mutual#kiss']),
        slot(['target#hug']),
        slot(['source#kiss']),
      ]);
      expect(pruned[0].actionTags, ['source#hug']);
      expect(pruned[1].actionTags, ['target#hug']);
      expect(pruned[2].actionTags, isEmpty);
    });

    test('mutual pairs survive', () {
      final pruned = CascadeNotifier.pruneOrphanActionTags([
        slot(['mutual#holding hands']),
        slot(['mutual#holding hands']),
      ]);
      expect(pruned[0].actionTags, ['mutual#holding hands']);
      expect(pruned[1].actionTags, ['mutual#holding hands']);
    });
  });

  group('CascadeNotifier slot cap follows the model', () {
    test('default cap is six, a V5-sized cap admits more', () {
      final n = CascadeNotifier();
      n.createNewCascade('cast', 6);
      n.addCharacterToActiveBeat();
      expect(n.state.activeCascade!.beats.single.characterSlots.length, 6);

      n.addCharacterToActiveBeat(maxSlots: 32);
      expect(n.state.activeCascade!.beats.single.characterSlots.length, 7);
      expect(n.state.activeCascade!.characterCount, 7);
      expect(n.state.characterAppearances.length, 7);
    });
  });
}
