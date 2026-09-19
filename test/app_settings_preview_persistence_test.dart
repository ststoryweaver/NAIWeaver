import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:naiweaver/core/l10n/locale_notifier.dart';
import 'package:naiweaver/core/services/preferences_service.dart';
import 'package:naiweaver/core/theme/theme_notifier.dart';
import 'package:naiweaver/features/gallery/models/gallery_album.dart';
import 'package:naiweaver/features/gallery/providers/gallery_notifier.dart';
import 'package:naiweaver/features/generation/providers/generation_notifier.dart';
import 'package:naiweaver/features/tools/cascade/providers/cascade_notifier.dart';
import 'package:naiweaver/features/tools/cascade/services/cascade_preview_store.dart';
import 'package:naiweaver/features/tools/widgets/app_settings.dart';
import 'package:naiweaver/l10n/app_localizations.dart';

class _Generation extends ChangeNotifier implements GenerationNotifier {
  @override
  GenerationState get state => GenerationState();
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Gallery extends ChangeNotifier implements GalleryNotifier {
  @override
  List<GalleryAlbum> get albums => [];
  @override
  bool get demoMode => false;
  @override
  int get demoSafeCount => 0;
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  // Run this file both on the VM and with `flutter test --platform chrome`.
  for (final enabled in [false, true]) {
    testWidgets(
      'preview persistence availability with saved preference $enabled',
      (tester) async {
        SharedPreferences.setMockInitialValues({});
        FlutterSecureStorage.setMockInitialValues({});
        final prefs = PreferencesService(
          await SharedPreferences.getInstance(),
          const FlutterSecureStorage(),
        );
        await prefs.setPersistCascadeBeatPreviews(enabled);
        final cascade = CascadeNotifier(
          prefs: prefs,
          previewStore: kIsWeb ? null : MemoryCascadePreviewStore(),
        );
        addTearDown(cascade.dispose);
        await tester.pumpWidget(
          MultiProvider(
            providers: [
              Provider<PreferencesService>.value(value: prefs),
              ChangeNotifierProvider(create: (_) => ThemeNotifier(prefs)),
              ChangeNotifierProvider(create: (_) => LocaleNotifier(prefs)),
              ChangeNotifierProvider<CascadeNotifier>.value(value: cascade),
              ChangeNotifierProvider<GenerationNotifier>(
                create: (_) => _Generation(),
              ),
              ChangeNotifierProvider<GalleryNotifier>(
                create: (_) => _Gallery(),
              ),
            ],
            child: MaterialApp(
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              home: const Scaffold(body: AppSettings()),
            ),
          ),
        );
        await tester.pumpAndSettle();
        final l = AppLocalizations.of(
          tester.element(find.byType(AppSettings)),
        );
        final label = find.text(l.settingsPersistCascadePreviews.toUpperCase());
        final description = find.text(l.settingsPersistCascadePreviewsDesc);
        expect(
          find.text(l.settingsRememberSession.toUpperCase()),
          findsOneWidget,
        );
        if (kIsWeb) {
          expect(label, findsNothing);
          expect(description, findsNothing);
          expect(prefs.persistCascadeBeatPreviews, enabled);
        } else {
          expect(label, findsOneWidget);
          expect(description, findsOneWidget);
          final row = find.ancestor(of: label, matching: find.byType(Row));
          final toggle = find.descendant(
            of: row,
            matching: find.byType(Switch),
          );
          expect(tester.widget<Switch>(toggle).value, enabled);
          await tester.ensureVisible(toggle);
          await tester.tap(toggle);
          await tester.pumpAndSettle();
          await cascade.previewIo;
          expect(prefs.persistCascadeBeatPreviews, !enabled);
          expect(cascade.persistBeatPreviews, !enabled);
          expect(tester.widget<Switch>(toggle).value, !enabled);
        }
        expect(tester.takeException(), isNull);
      },
    );
  }
}
