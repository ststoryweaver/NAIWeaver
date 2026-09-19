import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:naiweaver/core/services/preferences_service.dart';
import 'package:naiweaver/core/services/styles.dart';
import 'package:naiweaver/core/services/tag_service.dart';
import 'package:naiweaver/core/services/wildcard_service.dart';
import 'package:naiweaver/core/theme/theme_notifier.dart';
import 'package:naiweaver/core/widgets/tag_suggestion_overlay.dart';
import 'package:naiweaver/features/characters/providers/character_library_notifier.dart';
import 'package:naiweaver/features/generation/providers/generation_notifier.dart';
import 'package:naiweaver/features/tools/cascade/models/prompt_cascade.dart';
import 'package:naiweaver/features/tools/cascade/models/cascade_beat.dart';
import 'package:naiweaver/features/tools/cascade/providers/cascade_notifier.dart';
import 'package:naiweaver/features/tools/cascade/widgets/director_view.dart';
import 'package:naiweaver/l10n/app_localizations.dart';

PromptCascade story(String name) => PromptCascade(
  name: name,
  characterCount: 0,
  beats: [
    CascadeBeat(characterSlots: [], environmentTags: 'first'),
    CascadeBeat(characterSlots: [], environmentTags: 'second'),
  ],
);

class ReviewTags extends TagService {
  ReviewTags() : super(filePath: 'unused');
  @override
  List<DanbooruTag> getSuggestions(String query, {int limit = 20}) => [
    DanbooruTag(tag: '1girl', count: 10),
    DanbooruTag(tag: '1boy', count: 9),
  ];
}

class ReviewGen extends ChangeNotifier implements GenerationNotifier {
  @override
  GenerationState get state => GenerationState();
  @override
  TagService get tagService => ReviewTags();
  @override
  WildcardService get wildcardService => WildcardService(wildcardDir: 'unused');
  @override
  List<PromptStyle> get stylesForCurrentModel => [];
  @override
  int get hiddenStyleCountForCurrentModel => 0;
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class ReviewCharacters extends ChangeNotifier
    implements CharacterLibraryNotifier {
  ReviewCharacters({this.withCharacter = false});
  final bool withCharacter;
  @override
  List<DanbooruTag> suggestionTags(String query, {int limit = 8}) =>
      withCharacter
      ? [
          DanbooruTag(
            tag: 'Alice',
            count: 0,
            typeName: 'saved_character',
            expansion: 'state aware outfit',
            flatExpansion: 'flat outfit',
          ),
        ]
      : [];
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));
  testWidgets('real director Tab highlights and Enter inserts after typing', (
    tester,
  ) async {
    final prefs = PreferencesService(
      await SharedPreferences.getInstance(),
      const FlutterSecureStorage(),
    );
    final n = CascadeNotifier();
    n.setActiveCascade(story('A'));
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider<PreferencesService>.value(value: prefs),
          ChangeNotifierProvider(create: (_) => ThemeNotifier(prefs)),
          ChangeNotifierProvider<CascadeNotifier>.value(value: n),
          ChangeNotifierProvider<GenerationNotifier>(
            create: (_) => ReviewGen(),
          ),
          ChangeNotifierProvider<CharacterLibraryNotifier>(
            create: (_) => ReviewCharacters(),
          ),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const Scaffold(body: DirectorView()),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final field = find.byType(TextField).first;
    await tester.enterText(field, '1gi');
    await tester.pump(const Duration(milliseconds: 200));
    await tester.pump();
    expect(find.byType(TagSuggestionOverlay), findsOneWidget);
    expect(
      tester
          .widget<TagSuggestionOverlay>(find.byType(TagSuggestionOverlay))
          .suggestions
          .length,
      2,
    );
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    expect(
      tester
          .widget<TagSuggestionOverlay>(find.byType(TagSuggestionOverlay))
          .selectedIndex,
      0,
    );
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();
    expect(n.state.activeCascade!.beats.first.sceneTags, '1girl, ');
  });

  testWidgets('keyboard respects honor outfit state off just like clicking', (
    tester,
  ) async {
    final prefs = PreferencesService(
      await SharedPreferences.getInstance(),
      const FlutterSecureStorage(),
    );
    await prefs.setHonorOutfitState(false);
    expect(prefs.honorOutfitState, isFalse);
    final n = CascadeNotifier();
    n.setActiveCascade(story('A'));
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider<PreferencesService>.value(value: prefs),
          ChangeNotifierProvider(create: (_) => ThemeNotifier(prefs)),
          ChangeNotifierProvider<CascadeNotifier>.value(value: n),
          ChangeNotifierProvider<GenerationNotifier>(
            create: (_) => ReviewGen(),
          ),
          ChangeNotifierProvider<CharacterLibraryNotifier>(
            create: (_) => ReviewCharacters(withCharacter: true),
          ),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const Scaffold(body: DirectorView()),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final field = find.byType(TextField).first;
    await tester.enterText(field, 'Alice');
    await tester.pump(const Duration(milliseconds: 200));
    await tester.pumpAndSettle();
    await tester.tap(
      find.descendant(
        of: find.byType(TagSuggestionOverlay),
        matching: find.text('Alice'),
      ),
    );
    await tester.pump();
    expect(n.state.activeCascade!.beats.first.sceneTags, 'flat outfit, ');
    await tester.enterText(field, 'Alice');
    await tester.pump(const Duration(milliseconds: 200));
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();
    expect(n.state.activeCascade!.beats.first.sceneTags, 'flat outfit, ');
  });
}
