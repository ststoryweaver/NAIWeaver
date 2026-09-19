import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:naiweaver/core/services/preferences_service.dart';
import 'package:naiweaver/core/services/tag_service.dart';
import 'package:naiweaver/core/theme/theme_notifier.dart';
import 'package:naiweaver/features/director_ref/models/director_reference.dart';
import 'package:naiweaver/features/director_ref/widgets/director_ref_editor_sheet.dart';
import 'package:naiweaver/features/generation/models/nai_character.dart';
import 'package:naiweaver/features/generation/providers/generation_notifier.dart';
import 'package:naiweaver/features/generation/widgets/action_interaction_sheet.dart';
import 'package:naiweaver/features/vibe_transfer/models/vibe_transfer.dart';
import 'package:naiweaver/features/vibe_transfer/widgets/vibe_transfer_editor_sheet.dart';
import 'package:naiweaver/l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _Generation extends ChangeNotifier implements GenerationNotifier {
  @override
  final tagService = TagService(filePath: 'unused');

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  final bytes = Uint8List.fromList(
    img.encodePng(img.Image(width: 8, height: 8)),
  );
  final sheets = <String, Widget Function()>{
    'interaction': () => ActionInteractionSheet(
      sourceIndices: const [0],
      targetIndices: const [1],
      initialType: InteractionType.sourceTarget,
      characters: const [],
      onSave: (_) {},
      onDelete: () {},
    ),
    'vibe': () => VibeTransferEditorSheet(
      vibe: VibeTransfer(
        id: 'v',
        originalImageBytes: bytes,
        processedPreview: bytes,
        vibeVectorBase64: '',
      ),
      onStrengthChanged: (_) {},
      onInfoExtractedChanged: (_) {},
      onToggleEnabled: () {},
      onRemove: () {},
    ),
    'reference': () => DirectorRefEditorSheet(
      reference: DirectorReference(
        id: 'r',
        originalImageBytes: bytes,
        processedBase64: '',
      ),
      onTypeChanged: (_) {},
      onStrengthChanged: (_) {},
      onFidelityChanged: (_) {},
      onToggleEnabled: () {},
      onRemove: () {},
    ),
  };

  for (final entry in sheets.entries) {
    for (final keyboard in [0.0, 300.0]) {
      testWidgets('${entry.key} stays above system UI (keyboard $keyboard)', (
        tester,
      ) async {
        tester.view.physicalSize = const Size(400, 800);
        tester.view.devicePixelRatio = 1;
        tester.view.viewPadding = const FakeViewPadding(bottom: 48);
        tester.view.padding = FakeViewPadding(bottom: keyboard == 0 ? 48 : 0);
        tester.view.viewInsets = FakeViewPadding(bottom: keyboard);
        addTearDown(tester.view.reset);
        SharedPreferences.setMockInitialValues({});
        final prefs = PreferencesService(
          await SharedPreferences.getInstance(),
          const FlutterSecureStorage(),
        );
        await tester.pumpWidget(
          MultiProvider(
            providers: [
              ChangeNotifierProvider(create: (_) => ThemeNotifier(prefs)),
              ChangeNotifierProvider<GenerationNotifier>(
                create: (_) => _Generation(),
              ),
            ],
            child: MaterialApp(
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              home: Scaffold(
                body: Builder(
                  builder: (context) => TextButton(
                    onPressed: () => showModalBottomSheet<void>(
                      context: context,
                      isScrollControlled: true,
                      builder: (_) => entry.value(),
                    ),
                    child: const Text('Open'),
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.tap(find.text('Open'));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        final scroll = find.byType(SingleChildScrollView).first;
        expect(scroll, findsOneWidget);
        final bottom = tester.getRect(scroll).bottom;
        expect(
          bottom,
          closeTo(800 - (keyboard == 0 ? 48 : keyboard) - 16, 0.01),
        );
        await tester.drag(scroll, const Offset(0, -500));
        await tester.pumpAndSettle();
        if (entry.key == 'interaction') {
          final save = find.byType(ElevatedButton);
          expect(tester.getRect(save).bottom, lessThanOrEqualTo(bottom));
          await tester.tap(save);
          await tester.pumpAndSettle();
          expect(find.byType(ActionInteractionSheet), findsNothing);
        }
        expect(tester.takeException(), isNull);
      });
    }
  }
}
