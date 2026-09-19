import 'dart:typed_data';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:naiweaver/features/tools/img2img/providers/img2img_notifier.dart';
import 'package:naiweaver/features/tools/img2img/widgets/mask_canvas.dart';
import 'package:provider/provider.dart';

Future<Img2ImgNotifier> pumpCanvas(WidgetTester tester) async {
  final notifier = Img2ImgNotifier();
  final bytes = Uint8List.fromList(
    img.encodePng(img.Image(width: 64, height: 64)),
  );
  await tester.runAsync(() => notifier.loadSourceImage(bytes));
  await tester.pumpWidget(
    ChangeNotifierProvider.value(
      value: notifier,
      child: const MaterialApp(home: Scaffold(body: MaskCanvas())),
    ),
  );
  await tester.pumpAndSettle();
  addTearDown(notifier.dispose);
  return notifier;
}

void main() {
  testWidgets('adding a second finger cancels the brush before pinch starts', (
    tester,
  ) async {
    final notifier = await pumpCanvas(tester);
    final first = await tester.startGesture(const Offset(300, 200), pointer: 1);
    await first.moveBy(const Offset(20, 20));
    expect(notifier.activeStroke, isNotNull);
    final second = await tester.startGesture(
      const Offset(400, 400),
      pointer: 2,
    );
    expect(notifier.session!.maskStrokes, isEmpty);
    expect(notifier.activeStroke, isNull);
    await second.moveBy(const Offset(50, 60));
    await first.moveBy(const Offset(-50, -60));
    final viewer = tester.widget<InteractiveViewer>(
      find.byType(InteractiveViewer),
    );
    expect(
      viewer.transformationController!.value.getMaxScaleOnAxis(),
      greaterThan(1),
    );
    await second.up();
    await first.moveBy(const Offset(30, 20));
    await first.up();
    expect(notifier.session!.maskStrokes, isEmpty);
    expect(notifier.activeStroke, isNull);
    // A fresh contact after all pinch fingers lift can paint again.
    final brush = await tester.startGesture(const Offset(320, 240), pointer: 3);
    await brush.moveBy(const Offset(25, 25));
    await brush.up();
    expect(notifier.session!.maskStrokes, hasLength(1));
    await tester.pumpAndSettle();
  });

  testWidgets('lifting one pinch finger never starts a trailing brush stroke', (
    tester,
  ) async {
    final notifier = await pumpCanvas(tester);
    final first = await tester.startGesture(const Offset(300, 200), pointer: 1);
    final second = await tester.startGesture(
      const Offset(400, 400),
      pointer: 2,
    );
    await second.moveBy(const Offset(50, 60));
    await first.moveBy(const Offset(-50, -60));
    await second.up();
    await first.moveBy(const Offset(25, 25));
    await first.moveBy(const Offset(25, 25));
    await first.up();
    expect(notifier.session!.maskStrokes, isEmpty);
    await tester.pumpAndSettle();
  });

  testWidgets('cancelled touch is discarded and mouse drag still paints', (
    tester,
  ) async {
    final notifier = await pumpCanvas(tester);
    final touch = await tester.startGesture(const Offset(300, 200));
    await touch.moveBy(const Offset(30, 30));
    await touch.cancel();
    expect(notifier.session!.maskStrokes, isEmpty);
    final mouse = await tester.startGesture(
      const Offset(300, 200),
      kind: PointerDeviceKind.mouse,
    );
    await mouse.moveBy(const Offset(30, 30));
    await mouse.up();
    expect(notifier.session!.maskStrokes, hasLength(1));
    await tester.pumpAndSettle();
  });
}
