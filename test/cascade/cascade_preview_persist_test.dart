import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:naiweaver/features/generation/models/nai_character.dart';
import 'package:naiweaver/features/tools/cascade/models/cascade_beat.dart';
import 'package:naiweaver/features/tools/cascade/models/prompt_cascade.dart';
import 'package:naiweaver/features/tools/cascade/providers/cascade_notifier.dart';
import 'package:naiweaver/features/tools/cascade/services/cascade_preview_store.dart';
import 'package:naiweaver/features/tools/cascade/services/file_cascade_preview_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

Uint8List _bytes(int tag) => Uint8List.fromList([tag, tag + 1, tag + 2]);

PromptCascade _cascade(String name, int beats) => PromptCascade(
  name: name,
  characterCount: 1,
  beats: List.generate(
    beats,
    (_) => CascadeBeat(
      characterSlots: [
        BeatCharacterSlot(position: NaiCoordinate(x: 0.5, y: 0.5)),
      ],
      environmentTags: '',
    ),
  ),
);

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('persist is off by default and does not write', () async {
    final store = MemoryCascadePreviewStore();
    final n = CascadeNotifier(previewStore: store);
    expect(n.persistBeatPreviews, isFalse);

    n.setActiveCascade(_cascade('story', 2));
    n.setBeatPreview(0, _bytes(1));
    await n.previewIo;

    expect(await store.load('story'), isEmpty);
  });

  test('when enabled, setBeatPreview writes and reopen restores', () async {
    final store = MemoryCascadePreviewStore();
    final n = CascadeNotifier(previewStore: store);
    await n.setPersistBeatPreviews(true);

    n.setActiveCascade(_cascade('story', 2));
    n.setBeatPreview(0, _bytes(9));
    n.setBeatPreview(1, _bytes(8));
    await n.previewIo;

    final saved = await store.load('story');
    expect(saved[0], _bytes(9));
    expect(saved[1], _bytes(8));

    n.setActiveCascade(null);
    n.setActiveCascade(_cascade('story', 2));
    await n.previewIo;

    expect(n.state.beatPreviews[0], _bytes(9));
    expect(n.state.beatPreviews[1], _bytes(8));
  });

  test('disabled load does not restore even if files exist', () async {
    final store = MemoryCascadePreviewStore();
    await store.saveBeat('story', 0, _bytes(3));
    final n = CascadeNotifier(previewStore: store);
    expect(n.persistBeatPreviews, isFalse);

    n.setActiveCascade(_cascade('story', 1));
    await n.previewIo;

    expect(n.state.beatPreviews[0], isNull);
  });

  test('deleteCascade removes stored images', () async {
    final store = MemoryCascadePreviewStore();
    final n = CascadeNotifier(previewStore: store);
    await n.setPersistBeatPreviews(true);
    n.setActiveCascade(_cascade('story', 1));
    n.setBeatPreview(0, _bytes(4));
    await n.previewIo;

    n.deleteCascade('story');
    await n.previewIo;

    expect(await store.load('story'), isEmpty);
  });

  test('removeBeat remaps persisted files', () async {
    final store = MemoryCascadePreviewStore();
    final n = CascadeNotifier(previewStore: store);
    await n.setPersistBeatPreviews(true);
    n.setActiveCascade(_cascade('story', 3));
    n.setBeatPreview(0, _bytes(0));
    n.setBeatPreview(1, _bytes(1));
    n.setBeatPreview(2, _bytes(2));
    await n.previewIo;

    n.removeBeat(1);
    await n.previewIo;

    final saved = await store.load('story');
    expect(saved[0], _bytes(0));
    expect(saved[1], _bytes(2));
    expect(saved.containsKey(2), isFalse);
  });

  test('FileCascadePreviewStore round-trips bytes', () async {
    final dir = await Directory.systemTemp.createTemp('cascade_previews_');
    addTearDown(() => dir.delete(recursive: true));
    final store = FileCascadePreviewStore(dir.path);

    await store.saveBeat('My Story', 0, _bytes(11));
    await store.saveBeat('My Story', 2, _bytes(22));
    var loaded = await store.load('My Story');
    expect(loaded[0], _bytes(11));
    expect(loaded[2], _bytes(22));

    await store.replaceAll('My Story', {1: _bytes(33)});
    loaded = await store.load('My Story');
    expect(loaded.keys.toList(), [1]);
    expect(loaded[1], _bytes(33));

    await store.deleteCascade('My Story');
    expect(await store.load('My Story'), isEmpty);
  });
}
