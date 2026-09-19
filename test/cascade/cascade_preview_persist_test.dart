import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:naiweaver/features/tools/cascade/models/cascade_beat.dart';
import 'package:naiweaver/features/tools/cascade/models/prompt_cascade.dart';
import 'package:naiweaver/features/tools/cascade/providers/cascade_notifier.dart';
import 'package:naiweaver/features/tools/cascade/services/cascade_preview_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

Uint8List bytes(int n) => Uint8List.fromList([n]);
PromptCascade story(String name) => PromptCascade(
  name: name,
  characterCount: 0,
  beats: [
    CascadeBeat(characterSlots: [], environmentTags: 'first'),
    CascadeBeat(characterSlots: [], environmentTags: 'second'),
  ],
);

class SlowLoadStore extends MemoryCascadePreviewStore {
  Completer<void>? gate;
  final started = Completer<void>();
  @override
  Future<Map<String, CascadePreview>> load(String name) async {
    final snapshot = await super.load(name);
    if (gate != null) {
      if (!started.isCompleted) started.complete();
      await gate!.future;
    }
    return snapshot;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('off by default: neither writes nor restores previews', () async {
    final store = MemoryCascadePreviewStore();
    final a = story('A');
    await store.saveBeat('A', a.beats[0].id, CascadePreview(bytes(1)));
    final n = CascadeNotifier(previewStore: store);
    expect(n.persistBeatPreviews, isFalse);
    n.setActiveCascade(a);
    await n.previewIo;
    expect(n.state.beatPreviews, isEmpty);
    n.setBeatPreview(0, bytes(9));
    await n.previewIo;
    expect((await store.load('A'))[a.beats[0].id]!.bytes, bytes(1));
  });

  test(
    'image and metadata survive a new notifier and serialized cascade',
    () async {
      final store = MemoryCascadePreviewStore();
      final a = story('A');
      final n = CascadeNotifier(previewStore: store);
      await n.setPersistBeatPreviews(true);
      n.setActiveCascade(a);
      n.setBeatPreview(0, bytes(9), metadata: {'seed': 42, 'prompt': 'first'});
      await n.flushPreviews();
      final reopened = CascadeNotifier(previewStore: store);
      await reopened.setPersistBeatPreviews(true);
      reopened.setActiveCascade(
        PromptCascade.fromJson(jsonDecode(jsonEncode(a.toJson()))),
      );
      await reopened.previewIo;
      expect(reopened.state.beatPreviews[0], bytes(9));
      expect(reopened.state.beatMetadata[0], {'seed': 42, 'prompt': 'first'});
    },
  );

  for (final exitInstead in [false, true]) {
    test(
      'queued write retains its owner when ${exitInstead ? 'exiting' : 'switching'}',
      () async {
        final store = SlowLoadStore();
        final n = CascadeNotifier(previewStore: store);
        final a = story('A');
        await n.setPersistBeatPreviews(true);
        store.gate = Completer<void>();
        n.setActiveCascade(a);
        await store.started.future;
        final image = bytes(9);
        final metadata = {'seed': 42};
        n.setBeatPreview(0, image, metadata: metadata);
        image[0] = 99;
        metadata['seed'] = 99;
        if (exitInstead) {
          n.exitCascadeMode();
        } else {
          n.setActiveCascade(story('B'));
        }
        store.gate!.complete();
        await n.previewIo;
        expect(await store.load('B'), isEmpty);
        final saved = (await store.load('A'))[a.beats[0].id]!;
        expect(saved.bytes, bytes(9));
        expect(saved.metadata, {'seed': 42});
      },
    );
  }

  for (final clear in [false, true]) {
    test(
      'pending restore preserves a newer ${clear ? 'clear' : 'image and metadata'}',
      () async {
        final store = SlowLoadStore();
        final a = story('A');
        await store.saveBeat(
          'A',
          a.beats[0].id,
          CascadePreview(bytes(1), metadata: {'seed': 1}),
        );
        final n = CascadeNotifier(previewStore: store);
        await n.setPersistBeatPreviews(true);
        store.gate = Completer<void>();
        n.setActiveCascade(a);
        await store.started.future;
        n.setBeatPreview(
          0,
          clear ? null : bytes(9),
          metadata: clear ? null : {'seed': 9},
        );
        store.gate!.complete();
        await n.previewIo;
        expect(n.state.beatPreviews[0], clear ? null : bytes(9));
        expect(n.state.beatMetadata[0], clear ? null : {'seed': 9});
        expect(
          (await store.load('A'))[a.beats[0].id]?.bytes,
          clear ? null : bytes(9),
        );
      },
    );
  }

  for (final edit in ['remove', 'clone', 'reorder']) {
    test('discard $edit keeps saved image mapping', () async {
      final store = MemoryCascadePreviewStore();
      final n = CascadeNotifier(previewStore: store);
      final a = story('A');
      await n.setPersistBeatPreviews(true);
      n.setActiveCascade(a);
      await n.previewIo;
      n.saveActiveToLibrary();
      n.setBeatPreview(0, bytes(1));
      n.setBeatPreview(1, bytes(2));
      await n.previewIo;
      switch (edit) {
        case 'remove':
          n.removeBeat(0);
        case 'clone':
          n.cloneBeat(0);
        case 'reorder':
          n.reorderBeats(0, 2);
      }
      await n.previewIo;
      n.setActiveCascade(null);
      n.setActiveCascade(n.state.savedCascades.single);
      await n.previewIo;
      expect(n.state.beatPreviews[0], bytes(1));
      expect(n.state.beatPreviews[1], bytes(2));
    });
  }

  test('save after remove/reorder collects only deleted beats', () async {
    final store = MemoryCascadePreviewStore();
    final n = CascadeNotifier(previewStore: store);
    final a = story('A');
    await n.setPersistBeatPreviews(true);
    n.setActiveCascade(a);
    n.setBeatPreview(0, bytes(1));
    n.setBeatPreview(1, bytes(2));
    await n.previewIo;
    n.reorderBeats(0, 2);
    n.removeBeat(1);
    n.saveActiveToLibrary();
    await n.previewIo;
    expect((await store.load('A')).keys, [a.beats[1].id]);
    n.setActiveCascade(null);
    n.setActiveCascade(n.state.savedCascades.single);
    await n.previewIo;
    expect(n.state.beatPreviews[0], bytes(2));
  });

  test('load uses beat IDs after reordering while it was pending', () async {
    final store = SlowLoadStore();
    final n = CascadeNotifier(previewStore: store);
    final a = story('A');
    await store.saveBeat('A', a.beats[0].id, CascadePreview(bytes(1)));
    await n.setPersistBeatPreviews(true);
    store.gate = Completer<void>();
    n.setActiveCascade(a);
    await store.started.future;
    n.reorderBeats(0, 2);
    store.gate!.complete();
    await n.previewIo;
    expect(n.state.beatPreviews[0], isNull);
    expect(n.state.beatPreviews[1], bytes(1));
  });

  test('enabling merges stored images with current edits and clears', () async {
    final store = MemoryCascadePreviewStore();
    final a = story('A');
    await store.saveBeat('A', a.beats[0].id, CascadePreview(bytes(1)));
    await store.saveBeat('A', a.beats[1].id, CascadePreview(bytes(2)));
    final n = CascadeNotifier(previewStore: store);
    n.setActiveCascade(a);
    await n.previewIo;
    n.setBeatPreview(1, null);
    await n.setPersistBeatPreviews(true);
    expect(n.state.beatPreviews[0], bytes(1));
    expect(n.state.beatPreviews[1], isNull);
    final saved = await store.load('A');
    expect(saved[a.beats[0].id]!.bytes, bytes(1));
    expect(saved.containsKey(a.beats[1].id), isFalse);
  });

  test('turning off during restore prevents late images appearing', () async {
    final store = SlowLoadStore();
    final a = story('A');
    await store.saveBeat('A', a.beats[0].id, CascadePreview(bytes(1)));
    final n = CascadeNotifier(previewStore: store);
    await n.setPersistBeatPreviews(true);
    store.gate = Completer<void>();
    n.setActiveCascade(a);
    await store.started.future;
    final toggle = n.setPersistBeatPreviews(false);
    store.gate!.complete();
    await toggle;
    expect(n.state.beatPreviews, isEmpty);
  });

  test(
    'delete after a queued save removes previews and clears the active cascade',
    () async {
      final store = MemoryCascadePreviewStore();
      final n = CascadeNotifier(previewStore: store);
      await n.setPersistBeatPreviews(true);
      n.setActiveCascade(story('A'));
      n.setBeatPreview(0, bytes(1));
      n.deleteCascade('A');
      await n.previewIo;
      expect(await store.load('A'), isEmpty);
      expect(n.state.activeCascade, isNull);
    },
  );

  test('disposed notifier does not publish a pending restore', () async {
    final store = SlowLoadStore();
    final a = story('A');
    await store.saveBeat('A', a.beats[0].id, CascadePreview(bytes(1)));
    final n = CascadeNotifier(previewStore: store);
    await n.setPersistBeatPreviews(true);
    store.gate = Completer<void>();
    n.setActiveCascade(a);
    await store.started.future;
    n.dispose();
    store.gate!.complete();
    await n.previewIo;
  });
}
