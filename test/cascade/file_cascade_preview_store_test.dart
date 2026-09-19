import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:naiweaver/features/tools/cascade/models/prompt_cascade.dart';
import 'package:naiweaver/features/tools/cascade/services/cascade_preview_store.dart';
import 'package:naiweaver/features/tools/cascade/services/file_cascade_preview_store.dart';

CascadePreview preview(int n) => CascadePreview(
  Uint8List.fromList([n, n + 1]),
  metadata: {
    'seed': n,
    'prompt': 'image $n',
    'characters': [
      {'prompt': 'hello'},
    ],
  },
);
String hash(String value) => sha256.convert(utf8.encode(value)).toString();

void main() {
  late Directory sandbox;
  late String root;
  late FileCascadePreviewStore store;
  setUp(() async {
    sandbox = await Directory.systemTemp.createTemp('cascade_store_test_');
    root = p.join(sandbox.path, 'previews');
    store = FileCascadePreviewStore(root);
  });
  tearDown(() async {
    final target = p.normalize(p.absolute(sandbox.path));
    expect(
      p.isWithin(p.normalize(p.absolute(Directory.systemTemp.path)), target),
      isTrue,
    );
    expect(p.basename(target).startsWith('cascade_store_test_'), isTrue);
    if (await sandbox.exists()) await sandbox.delete(recursive: true);
  });

  test('round-trips and atomically replaces image with its metadata', () async {
    await store.saveBeat('My Story', 'beat-a', preview(1));
    await store.saveBeat('My Story', 'beat-a', preview(9));
    await store.saveBeat('My Story', 'beat-b', preview(2));
    final loaded = await store.load('My Story');
    expect(loaded['beat-a']!.bytes, preview(9).bytes);
    expect(loaded['beat-a']!.metadata, preview(9).metadata);
    expect(loaded['beat-b']!.metadata, preview(2).metadata);
    expect(
      await Directory(
        root,
      ).list(recursive: true).where((e) => e.path.endsWith('.tmp')).isEmpty,
      isTrue,
    );
    await store.retainBeats('My Story', {'beat-b'});
    expect((await store.load('My Story')).keys, ['beat-b']);
    await store.deleteCascade('My Story');
    expect(await store.load('My Story'), isEmpty);
  });

  for (final name in ['..', '.', '', '../other', 'CON', 'name.', '日本語']) {
    test('name "$name" cannot write/delete unrelated files', () async {
      final sentinel = File(p.join(sandbox.path, 'unrelated.txt'));
      await sentinel.writeAsString('keep');
      await store.saveBeat('other', 'beat', preview(1));
      await store.saveBeat(name, '../../beat', preview(2));
      expect((await store.load(name))['../../beat']!.bytes, preview(2).bytes);
      await store.deleteCascade(name);
      expect(await sentinel.readAsString(), 'keep');
      expect((await store.load('other'))['beat']!.bytes, preview(1).bytes);
      expect(await File(p.join(sandbox.path, 'beat_0.bin')).exists(), isFalse);
    });
  }

  test('case-distinct names do not share files on Windows', () async {
    await store.saveBeat('Story', 'beat', preview(1));
    await store.saveBeat('story', 'beat', preview(2));
    await store.deleteCascade('Story');
    expect((await store.load('story'))['beat']!.bytes, preview(2).bytes);
  });

  test('bad records are skipped without losing healthy beats', () async {
    await store.saveBeat('A', 'bad', preview(1));
    await store.saveBeat('A', 'good', preview(2));
    final bad = File(p.join(root, '.v2', hash('A'), '${hash('bad')}.json'));
    final record = jsonDecode(await bad.readAsString()) as Map<String, dynamic>;
    record['bytes'] = base64Encode([99]); // valid JSON/base64, invalid checksum
    await bad.writeAsString(jsonEncode(record));
    expect((await store.load('A')).keys, ['good']);
    await bad.writeAsString('{truncated');
    expect((await store.load('A')).keys, ['good']);
  });

  test(
    'legacy bins migrate using stable legacy IDs and preserve unrelated files',
    () async {
      final legacy = Directory(p.join(root, Uri.encodeComponent('Old Story')));
      await legacy.create(recursive: true);
      await File(
        p.join(legacy.path, 'beat_0.bin'),
      ).writeAsBytes(preview(1).bytes);
      final sentinel = File(p.join(legacy.path, 'keep.txt'));
      await sentinel.writeAsString('keep');
      final cascade = PromptCascade.fromJson({
        'name': 'Old Story',
        'characterCount': 0,
        'beats': [
          {'characterSlots': [], 'environmentTags': ''},
        ],
      });
      final loaded = await store.load('Old Story');
      expect(loaded[cascade.beats.single.id]!.bytes, preview(1).bytes);
      expect(await File(p.join(legacy.path, 'beat_0.bin')).exists(), isFalse);
      await store.deleteCascade('Old Story');
      expect(await sentinel.readAsString(), 'keep');
    },
  );

  test('legacy cleanup does not recursively delete the v2 namespace', () async {
    await store.saveBeat('other', 'beat', preview(1));
    await store.deleteCascade('.v2');
    expect((await store.load('other'))['beat']!.bytes, preview(1).bytes);
  });
}
