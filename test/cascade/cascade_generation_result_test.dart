import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:naiweaver/core/models/nai_model.dart';
import 'package:naiweaver/core/services/novel_ai_service.dart';
import 'package:naiweaver/core/services/preferences_service.dart';
import 'package:naiweaver/core/services/tag_service.dart';
import 'package:naiweaver/core/services/wildcard_service.dart';
import 'package:naiweaver/features/gallery/providers/gallery_notifier.dart';
import 'package:naiweaver/features/generation/providers/generation_notifier.dart';
import 'package:naiweaver/features/tools/cascade/services/cascade_stitching_service.dart';

class _Service implements NovelAIService {
  final ready = Completer<void>();
  final GenerationResult result;
  _Service(this.result);

  @override
  Future<NaiSubscription?> getSubscription() async {
    if (!ready.isCompleted) ready.complete();
    return null;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) {
    if (invocation.memberName == #generateImage) {
      return Future<GenerationResult>.value(result);
    }
    return super.noSuchMethod(invocation);
  }
}

// A gallery notification can synchronously cause the UI to show another beat.
// This runs between the disk save and auto-export in the real notifier.
class _Gallery extends ChangeNotifier implements GalleryNotifier {
  late VoidCallback onSaved;
  @override
  bool get demoMode => false;
  @override
  void addFile(File file, DateTime date, {String? albumId}) => onSaved();
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'real Cascade save/export keeps its record and leaves a navigated viewer intact',
    () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.windows;
      addTearDown(() => debugDefaultTargetPlatformOverride = null);
      SharedPreferences.setMockInitialValues({});
      FlutterSecureStorage.setMockInitialValues({});
      final prefs = PreferencesService(
        await SharedPreferences.getInstance(),
        const FlutterSecureStorage(),
      );
      final directory = await Directory.systemTemp.createTemp(
        'naiweaver_cascade_result_',
      );
      addTearDown(() async {
        // Only remove the disposable directory allocated for this test.
        expect(
          p.isWithin(
            Directory.systemTemp.absolute.path,
            directory.absolute.path,
          ),
          isTrue,
        );
        expect(
          p.basename(directory.path),
          startsWith('naiweaver_cascade_result_'),
        );
        await directory.delete(recursive: true);
      });
      final output = p.join(directory.path, 'output');
      final export = p.join(directory.path, 'export');
      await prefs.setAutoSaveImages(true);
      await prefs.setAutoExportToDevice(true);
      await prefs.setExportFolderPath(export);
      await prefs.setFilenamePattern('<seed>');
      final bytes = Uint8List.fromList(
        img.encodePng(img.Image(width: 16, height: 16)),
      );
      final record = {'prompt': 'rendered A', 'seed': 123};
      final service = _Service(
        GenerationResult(imageBytes: bytes, metadata: record),
      );
      final gallery = _Gallery();
      addTearDown(gallery.dispose);
      final notifier = GenerationNotifier(
        preferences: prefs,
        tagService: TagService(filePath: p.join(directory.path, 'tags.json')),
        wildcardService: WildcardService(
          wildcardDir: p.join(directory.path, 'wildcards'),
        ),
        outputDir: output,
        presetsFilePath: p.join(directory.path, 'presets.json'),
        stylesFilePath: p.join(directory.path, 'styles.json'),
        galleryNotifier: gallery,
        serviceFactory: (_) => service,
      );
      addTearDown(notifier.dispose);
      await service.ready.future;
      final older = Uint8List.fromList(
        img.encodePng(img.Image(width: 8, height: 8)),
      );
      final olderMetadata = {'prompt': 'older B', 'seed': 456};
      var saved = false;
      gallery.onSaved = () {
        saved = true;
        notifier.setGeneratedImage(older, metadata: olderMetadata);
        notifier.adoptSavedBasename('B.png');
      };

      final result = await notifier.generateCascadeBeat(
        CascadeStitchedRequest(
          baseCaption: 'rendered A',
          characters: [],
          sampler: 'k_euler_ancestral',
          steps: 28,
          scale: 6,
          width: 16,
          height: 16,
        ),
      );
      expect(saved, isTrue);
      expect(result, isNotNull);
      expect(result!.imageBytes, bytes);
      expect(result.metadata, record);
      expect(result.savedBasename, '123.png');
      expect(notifier.state.generatedImage, same(older));
      expect(notifier.lastMetadata, olderMetadata);
      expect(notifier.lastSavedBasename, 'B.png');
      expect(await File(p.join(output, '123.png')).exists(), isTrue);
      expect(await File(p.join(export, '123.png')).readAsBytes(), bytes);
      expect(await File(p.join(export, '456.png')).exists(), isFalse);
    },
  );
}
