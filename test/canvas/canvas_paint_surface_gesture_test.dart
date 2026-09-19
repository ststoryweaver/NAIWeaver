import 'dart:typed_data';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:naiweaver/core/services/preferences_service.dart';
import 'package:naiweaver/core/theme/theme_notifier.dart';
import 'package:naiweaver/features/tools/canvas/providers/canvas_notifier.dart';
import 'package:naiweaver/features/tools/canvas/widgets/canvas_paint_surface.dart';
import 'package:naiweaver/l10n/app_localizations.dart';

Future<CanvasNotifier> pumpCanvas(WidgetTester tester) async {
  SharedPreferences.setMockInitialValues({});
  final prefs = PreferencesService(
    await SharedPreferences.getInstance(),
    const FlutterSecureStorage(),
  );
  final notifier = CanvasNotifier();
  notifier.startSession(
    Uint8List.fromList(img.encodePng(img.Image(width: 64, height: 64))),
    64,
    64,
  );
  addTearDown(notifier.dispose);
  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeNotifier(prefs)),
        ChangeNotifierProvider.value(value: notifier),
      ],
      child: const MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: CanvasPaintSurface()),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return notifier;
}

void main() {
  for (final tool in [CanvasTool.paint, CanvasTool.erase]) {
    testWidgets(
      '$tool cancels before pinch and paints again after all fingers lift',
      (tester) async {
        final notifier = await pumpCanvas(tester);
        notifier.setTool(tool);
        final first = await tester.startGesture(
          const Offset(300, 200),
          pointer: 1,
        );
        await first.moveBy(const Offset(30, 30));
        expect(notifier.activeStroke, isNotNull);
        final second = await tester.startGesture(
          const Offset(450, 400),
          pointer: 2,
        );
        expect(notifier.session!.activeLayer!.strokes, isEmpty);
        expect(notifier.activeStroke, isNull);
        await second.moveBy(const Offset(50, 50));
        await first.moveBy(const Offset(-50, -50));
        final viewer = tester.widget<InteractiveViewer>(
          find.byType(InteractiveViewer),
        );
        expect(
          viewer.transformationController!.value.getMaxScaleOnAxis(),
          greaterThan(1),
        );
        await second.up();
        await first.moveBy(const Offset(30, 30));
        await first.up();
        expect(notifier.session!.activeLayer!.strokes, isEmpty);
        expect(notifier.activeStroke, isNull);
        final brush = await tester.startGesture(
          const Offset(320, 240),
          pointer: 3,
        );
        await brush.moveBy(const Offset(25, 25));
        await brush.up();
        expect(notifier.session!.activeLayer!.strokes, hasLength(1));
        await tester.pumpAndSettle();
      },
    );
  }

  testWidgets('cancelled touch is discarded and mouse drag still paints', (
    tester,
  ) async {
    final notifier = await pumpCanvas(tester);
    final touch = await tester.startGesture(const Offset(300, 200));
    await touch.moveBy(const Offset(30, 30));
    expect(notifier.activeStroke, isNotNull);
    await touch.cancel();
    expect(notifier.session!.activeLayer!.strokes, isEmpty);
    expect(notifier.activeStroke, isNull);
    final mouse = await tester.startGesture(
      const Offset(300, 200),
      kind: PointerDeviceKind.mouse,
    );
    await mouse.moveBy(const Offset(30, 30));
    await mouse.up();
    expect(notifier.session!.activeLayer!.strokes, hasLength(1));
    await tester.pumpAndSettle();
  });

  testWidgets(
    'cancelled pinch never turns its remaining finger into a stroke',
    (tester) async {
      final notifier = await pumpCanvas(tester);
      final first = await tester.startGesture(
        const Offset(300, 200),
        pointer: 1,
      );
      final second = await tester.startGesture(
        const Offset(450, 400),
        pointer: 2,
      );
      await second.moveBy(const Offset(50, 50));
      await second.cancel();
      await first.moveBy(const Offset(30, 30));
      await first.up();
      expect(notifier.session!.activeLayer!.strokes, isEmpty);
      expect(notifier.activeStroke, isNull);
      await tester.pumpAndSettle();
    },
  );
}
