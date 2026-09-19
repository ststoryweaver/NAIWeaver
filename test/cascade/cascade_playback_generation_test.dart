import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:naiweaver/core/services/preferences_service.dart';
import 'package:naiweaver/core/services/tag_service.dart';
import 'package:naiweaver/core/theme/theme_notifier.dart';
import 'package:naiweaver/features/generation/providers/generation_notifier.dart';
import 'package:naiweaver/features/generation/models/cascade_generation_result.dart';
import 'package:naiweaver/features/tools/cascade/models/cascade_beat.dart';
import 'package:naiweaver/features/tools/cascade/models/prompt_cascade.dart';
import 'package:naiweaver/features/tools/cascade/providers/cascade_notifier.dart';
import 'package:naiweaver/features/tools/cascade/services/cascade_preview_store.dart';
import 'package:naiweaver/features/tools/cascade/services/cascade_stitching_service.dart';
import 'package:naiweaver/features/tools/cascade/widgets/cascade_playback_view.dart';
import 'package:naiweaver/l10n/app_localizations.dart';

final _png = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVQIHWP4z8DwHwAFgAI/ScLbtAAAAABJRU5ErkJggg==',
);

PromptCascade _story(String name) => PromptCascade(
  name: name,
  characterCount: 0,
  beats: List.generate(
    3,
    (i) => CascadeBeat(characterSlots: [], environmentTags: 'scene $i'),
  ),
);

class _DelayedGeneration extends ChangeNotifier implements GenerationNotifier {
  late final Completer<Uint8List?> pending;
  bool started = false;
  String? basename = 'A.png';

  @override
  GenerationState get state =>
      GenerationState(isLoading: started && !pending.isCompleted);
  @override
  TagService get tagService => TagService(filePath: 'unused');
  @override
  Map<String, dynamic>? get lastMetadata => {'prompt': 'A', 'seed': 42};
  @override
  String? get lastSavedBasename => basename;
  @override
  Future<CascadeGenerationResult?> generateCascadeBeat(
    CascadeStitchedRequest request,
  ) async {
    pending = Completer<Uint8List?>();
    started = true;
    notifyListeners();
    final result = await pending.future;
    notifyListeners();
    return result == null
        ? null
        : CascadeGenerationResult(
            imageBytes: result,
            metadata: lastMetadata!,
            savedBasename: basename,
          );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Harness {
  final store = MemoryCascadePreviewStore();
  final _DelayedGeneration gen;
  _Harness({_DelayedGeneration? generation})
    : gen = generation ?? _DelayedGeneration();
  final a = _story('A');
  final b = _story('B');
  late final CascadeNotifier notifier = CascadeNotifier(previewStore: store);

  Future<void> start(WidgetTester tester, {int index = 0}) async {
    final prefs = PreferencesService(
      await SharedPreferences.getInstance(),
      const FlutterSecureStorage(),
    );
    await notifier.setPersistBeatPreviews(true);
    notifier.setActiveCascade(a);
    notifier.selectBeat(index);
    await notifier.previewIo;
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider<PreferencesService>.value(value: prefs),
          ChangeNotifierProvider(create: (_) => ThemeNotifier(prefs)),
          ChangeNotifierProvider<CascadeNotifier>.value(value: notifier),
          ChangeNotifierProvider<GenerationNotifier>.value(value: gen),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const Scaffold(body: CascadePlaybackView()),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byType(ElevatedButton));
    await tester.pump();
    expect(gen.started, isTrue);
  }

  Future<void> complete(WidgetTester tester, {bool success = true}) async {
    gen.pending.complete(success ? _png : null);
    await tester.pumpAndSettle();
    await notifier.previewIo;
    expect(tester.takeException(), isNull);
  }

  Future<void> seedPreview({int index = 0}) async {
    notifier.setBeatPreview(index, _png, metadata: {'prompt': 'existing'});
    notifier.setBeatSavedBasename(index, 'existing.png');
    await notifier.previewIo;
  }

  Future<void> expectUnchanged(CascadeState before) async {
    expect(notifier.state.beatPreviews, before.beatPreviews);
    expect(notifier.state.beatMetadata, before.beatMetadata);
    expect(notifier.state.beatSavedBasenames, before.beatSavedBasenames);
    expect(notifier.state.selectedBeatIndex, before.selectedBeatIndex);
    final saved = await store.load(before.activeCascade!.name);
    expect(saved.keys, [before.activeCascade!.beats[0].id]);
    expect(saved.values.single.metadata, {'prompt': 'existing'});
    expect(saved.values.single.bytes, _png);
  }
}

// Model both asynchronous persistence phases without a live API. The returned
// render record stays independent of the viewer's mutable navigation state.
class _SavingGeneration extends _DelayedGeneration {
  final save = Completer<void>();
  final export = Completer<void>();
  bool saving = false;
  bool exporting = false;
  bool loading = false;
  Uint8List? image;
  Map<String, dynamic>? metadata;

  @override
  GenerationState get state =>
      GenerationState(isLoading: loading, generatedImage: image);
  @override
  Map<String, dynamic>? get lastMetadata => metadata;
  @override
  void setGeneratedImage(Uint8List? value, {Map<String, dynamic>? metadata}) {
    if (!identical(image, value)) {
      basename = null;
      this.metadata = metadata;
    }
    image = value;
    notifyListeners();
  }

  @override
  void adoptSavedBasename(String? value) {
    basename = value;
    notifyListeners();
  }

  @override
  Future<CascadeGenerationResult?> generateCascadeBeat(
    CascadeStitchedRequest request,
  ) async {
    pending = Completer<Uint8List?>();
    started = loading = true;
    notifyListeners();
    final bytes = (await pending.future)!;
    final record = {'prompt': 'rendered A', 'seed': 123};
    image = bytes;
    metadata = record;
    basename = null;
    saving = true;
    await save.future;
    if (identical(image, bytes)) basename = 'A.png';
    exporting = true;
    await export.future;
    loading = false;
    notifyListeners();
    return CascadeGenerationResult(
      imageBytes: bytes,
      metadata: record,
      savedBasename: 'A.png',
    );
  }
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));
  late _Harness h;
  setUp(() => h = _Harness());
  tearDown(() {
    h.gen.dispose();
    h.notifier.dispose();
  });

  for (final phase in ['save', 'export']) {
    testWidgets(
      'navigation during auto-$phase keeps the render record together',
      (tester) async {
        final gen = _SavingGeneration();
        h = _Harness(generation: gen);
        await h.start(tester);
        final older = Uint8List.fromList(_png);
        final olderMetadata = {'prompt': 'older B', 'seed': 456};
        h.notifier.setBeatPreview(1, older, metadata: olderMetadata);
        h.notifier.setBeatSavedBasename(1, 'B.png');
        gen.pending.complete(_png);
        await tester.pump();
        expect(gen.saving, isTrue);
        if (phase == 'export') {
          gen.save.complete();
          await tester.pump();
          expect(gen.exporting, isTrue);
        }
        final beats = find.byWidgetPredicate(
          (w) =>
              w is InkWell &&
              w.child is Container &&
              (w.child as Container).constraints?.maxWidth == 40,
        );
        await tester.tap(beats.at(1));
        await tester.pump();
        expect(gen.lastMetadata, olderMetadata);
        expect(gen.lastSavedBasename, 'B.png');
        if (phase == 'save') gen.save.complete();
        gen.export.complete();
        await tester.pumpAndSettle();
        await h.notifier.previewIo;

        expect(h.notifier.state.selectedBeatIndex, 1);
        expect(h.notifier.state.beatPreviews[0], _png);
        expect(h.notifier.state.beatMetadata[0], {
          'prompt': 'rendered A',
          'seed': 123,
        });
        expect(h.notifier.state.beatSavedBasenames, {0: 'A.png', 1: 'B.png'});
        expect(h.notifier.state.beatPreviews[1], older);
        expect(h.notifier.state.beatMetadata[1], olderMetadata);
        expect(gen.state.generatedImage, same(older));
        expect(gen.lastMetadata, olderMetadata);
        expect(gen.lastSavedBasename, 'B.png');
        final disk = await h.store.load('A');
        expect(disk[h.a.beats[0].id]!.metadata, {
          'prompt': 'rendered A',
          'seed': 123,
        });
        expect(disk[h.a.beats[1].id]!.metadata, olderMetadata);
      },
    );
  }

  // Permanent version of the release audit's real-button/controlled-future repro.
  testWidgets(
    'exit and switch cannot overwrite another story in memory or store',
    (tester) async {
      await h.start(tester);
      final exit = find.ancestor(
        of: find.byIcon(Icons.close),
        matching: find.byWidgetPredicate((widget) => widget is TextButton),
      );
      expect(tester.widget<TextButton>(exit).onPressed, isNotNull);
      await tester.tap(exit);
      h.notifier.setActiveCascade(h.b);
      await h.notifier.previewIo;
      await h.seedPreview();
      h.notifier.selectBeat(2);
      final before = h.notifier.state;
      await h.complete(tester);
      expect(h.notifier.state.activeCascade!.name, 'B');
      await h.expectUnchanged(before);
      expect(await h.store.load('A'), isEmpty);
    },
  );

  for (final transition in [
    'direct switch',
    'reopen same story',
    'new story',
    'clear selection',
  ]) {
    testWidgets('$transition discards the old generation', (tester) async {
      await h.start(tester);
      switch (transition) {
        case 'direct switch':
          h.notifier.setActiveCascade(h.b);
        case 'reopen same story':
          h.notifier.exitCascadeMode();
          h.notifier.setActiveCascade(h.a);
        case 'new story':
          h.notifier.createNewCascade('A', 0);
        case 'clear selection':
          h.notifier.setActiveCascade(null);
          h.notifier.setActiveCascade(h.a);
      }
      await h.notifier.previewIo;
      await h.seedPreview();
      final before = h.notifier.state;
      await h.complete(tester);
      await h.expectUnchanged(before);
    });
  }

  testWidgets('exit without re-entry discards completion', (tester) async {
    await h.start(tester);
    h.notifier.exitCascadeMode();
    await h.complete(tester);
    expect(h.notifier.state.activeCascade, isNull);
    expect(h.notifier.state.selectedBeatIndex, isNull);
    expect(h.notifier.state.beatPreviews, isEmpty);
    expect(h.notifier.state.beatMetadata, isEmpty);
    expect(h.notifier.state.beatSavedBasenames, isEmpty);
    expect(await h.store.load('A'), isEmpty);
  });

  testWidgets('removed beat cannot overwrite the beat now at its index', (
    tester,
  ) async {
    await h.start(tester);
    h.notifier.removeBeat(0);
    await h.seedPreview();
    final before = h.notifier.state;
    await h.complete(tester);
    await h.expectUnchanged(before);
  });

  for (final edit in [
    'reorder',
    'remove preceding beat',
    'insert preceding beat',
  ]) {
    testWidgets('$edit keeps result attached to its stable beat ID', (
      tester,
    ) async {
      await h.start(tester, index: 1);
      switch (edit) {
        case 'reorder':
          h.notifier.reorderBeats(1, 0);
        case 'remove preceding beat':
          h.notifier.removeBeat(0);
        case 'insert preceding beat':
          h.notifier.cloneBeat(0);
      }
      final before = h.notifier.state;
      final index = before.activeCascade!.beats.indexWhere(
        (b) => b.id == h.a.beats[1].id,
      );
      await h.complete(tester);
      expect(h.notifier.state.beatPreviews, {index: _png});
      expect(h.notifier.state.beatMetadata, {index: h.gen.lastMetadata});
      expect(h.notifier.state.beatSavedBasenames, {index: 'A.png'});
      expect(
        h.notifier.state.selectedBeatIndex,
        before.selectedBeatIndex == index
            ? index + 1
            : before.selectedBeatIndex,
      );
      final saved = await h.store.load('A');
      expect(saved.keys, [h.a.beats[1].id]);
      expect(saved.values.single.metadata, h.gen.lastMetadata);
    });
  }

  testWidgets('normal completion saves all fields and advances', (
    tester,
  ) async {
    await h.start(tester);
    await h.complete(tester);
    expect(h.notifier.state.beatPreviews, {0: _png});
    expect(h.notifier.state.beatMetadata, {0: h.gen.lastMetadata});
    expect(h.notifier.state.beatSavedBasenames, {0: 'A.png'});
    expect(h.notifier.state.selectedBeatIndex, 1);
    expect((await h.store.load('A')).keys, [h.a.beats[0].id]);
  });

  testWidgets(
    'navigation while generating is preserved and unsaved render clears filename',
    (tester) async {
      await h.start(tester);
      await h.seedPreview();
      h.gen.basename = null;
      h.notifier.selectBeat(2);
      await h.complete(tester);
      expect(h.notifier.state.beatMetadata, {0: h.gen.lastMetadata});
      expect(h.notifier.state.beatSavedBasenames, isEmpty);
      expect(h.notifier.state.selectedBeatIndex, 2);
    },
  );

  testWidgets('failed generation preserves existing preview and selection', (
    tester,
  ) async {
    await h.start(tester);
    await h.seedPreview();
    final before = h.notifier.state;
    await h.complete(tester, success: false);
    await h.expectUnchanged(before);
  });

  testWidgets('unmounted playback discards its pending completion', (
    tester,
  ) async {
    await h.start(tester);
    await tester.pumpWidget(const SizedBox.shrink());
    await h.complete(tester);
    expect(h.notifier.state.beatPreviews, isEmpty);
    expect(h.notifier.state.beatMetadata, isEmpty);
    expect(h.notifier.state.beatSavedBasenames, isEmpty);
    expect(h.notifier.state.selectedBeatIndex, 0);
    expect(await h.store.load('A'), isEmpty);
  });
}
