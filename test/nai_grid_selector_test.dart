import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:naiweaver/core/services/preferences_service.dart';
import 'package:naiweaver/core/theme/theme_notifier.dart';
import 'package:naiweaver/features/generation/models/nai_character.dart';
import 'package:naiweaver/features/generation/widgets/nai_grid_selector.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The grid inside a box shaped like the cascade director's landscape beat
/// (1216×832 at ~130 px wide on a phone), where the old GridView clipped
/// its bottom rows.
Future<void> pumpGrid(
  WidgetTester tester, {
  required double aspectRatio,
  required ValueChanged<NaiCoordinate> onSelected,
}) async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  final prefsService = PreferencesService(prefs, const FlutterSecureStorage());
  await tester.pumpWidget(
    ChangeNotifierProvider<ThemeNotifier>(
      create: (_) => ThemeNotifier(prefsService),
      child: MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 130,
              child: NaiGridSelector(
                selectedCoordinate: NaiCoordinate(x: 0.5, y: 0.5),
                onCoordinateSelected: onSelected,
                aspectRatio: aspectRatio,
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('every row of a landscape grid is reachable', (tester) async {
    NaiCoordinate? picked;
    await pumpGrid(
      tester,
      aspectRatio: 1216 / 832,
      onSelected: (c) => picked = c,
    );

    final cells = find.byType(InkWell);
    expect(cells, findsNWidgets(25));

    // No cell may extend past the grid's own box.
    final box = tester.getRect(find.byType(NaiGridSelector));
    for (final cell in cells.evaluate()) {
      final rect = tester.getRect(find.byWidget(cell.widget));
      expect(rect.bottom, lessThanOrEqualTo(box.bottom + 0.01));
      expect(rect.right, lessThanOrEqualTo(box.right + 0.01));
    }

    // The bottom-right cell (index 24) is the y=0.9 row that used to clip.
    await tester.tap(cells.at(24));
    expect(picked, isNotNull);
    expect(picked!.x, 0.9);
    expect(picked!.y, 0.9);
  });

  testWidgets('a square grid still maps taps to the standard points', (
    tester,
  ) async {
    NaiCoordinate? picked;
    await pumpGrid(tester, aspectRatio: 1, onSelected: (c) => picked = c);
    await tester.tap(find.byType(InkWell).at(2)); // top row, centre column
    expect(picked!.x, 0.5);
    expect(picked!.y, 0.1);
  });
}
