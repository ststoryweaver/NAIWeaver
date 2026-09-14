import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:naiweaver/core/services/preferences_service.dart';
import 'package:naiweaver/core/services/tag_service.dart';
import 'package:naiweaver/core/theme/theme_notifier.dart';
import 'package:naiweaver/core/widgets/tag_suggestion_overlay.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> _pump(
  WidgetTester tester, {
  required List<DanbooruTag> suggestions,
  required int selectedIndex,
}) async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  final prefsService = PreferencesService(prefs, const FlutterSecureStorage());
  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<ThemeNotifier>(
          create: (_) => ThemeNotifier(prefsService),
        ),
        Provider<PreferencesService>.value(value: prefsService),
      ],
      child: MaterialApp(
        home: Scaffold(
          body: TagSuggestionOverlay(
            suggestions: suggestions,
            selectedIndex: selectedIndex,
            onTagSelected: (_) {},
          ),
        ),
      ),
    ),
  );
  await tester.pump();
}

void main() {
  final suggestions = [
    DanbooruTag(tag: '1girl', count: 10),
    DanbooruTag(tag: '1boy', count: 9),
    DanbooruTag(
      tag: 'male bro',
      count: 0,
      typeName: 'saved_character',
      expansion: '1boy, short hair',
    ),
  ];

  testWidgets('keyboard highlight thickens the selected chip border', (
    tester,
  ) async {
    await _pump(tester, suggestions: suggestions, selectedIndex: 1);

    expect(find.text('1girl'), findsOneWidget);
    expect(find.text('1boy'), findsOneWidget);
    expect(find.text('male bro'), findsOneWidget);

    final boyBox = tester.widget<Container>(
      find
          .ancestor(of: find.text('1boy'), matching: find.byType(Container))
          .first,
    );
    final girlBox = tester.widget<Container>(
      find
          .ancestor(of: find.text('1girl'), matching: find.byType(Container))
          .first,
    );
    final boyBorder = (boyBox.decoration as BoxDecoration).border!;
    final girlBorder = (girlBox.decoration as BoxDecoration).border!;
    expect(boyBorder.top.width, 1.5);
    expect(girlBorder.top.width, 0.5);
  });

  testWidgets('no chip is highlighted when selectedIndex is -1', (
    tester,
  ) async {
    await _pump(tester, suggestions: suggestions, selectedIndex: -1);

    for (final label in ['1girl', '1boy', 'male bro']) {
      final box = tester.widget<Container>(
        find.ancestor(of: find.text(label), matching: find.byType(Container)).first,
      );
      final border = (box.decoration as BoxDecoration).border!;
      expect(border.top.width, 0.5, reason: '$label should not be highlighted');
    }
  });
}
