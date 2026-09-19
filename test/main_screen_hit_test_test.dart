import 'dart:typed_data';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:naiweaver/core/services/preferences_service.dart';
import 'package:naiweaver/core/theme/theme_notifier.dart';
import 'package:naiweaver/features/generation/widgets/image_viewer.dart';
import 'package:naiweaver/features/generation/widgets/settings_panel.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// A real (opaque) PNG so the viewer has an image to show.
Uint8List _png(int width, int height) {
  final image = img.Image(width: width, height: height, numChannels: 3);
  for (final pixel in image) {
    pixel.setRgb(200, 100, 50);
  }
  return Uint8List.fromList(img.encodePng(image));
}

/// Mobile phone geometry the main screen lays out against.
const _screen = Size(400, 800);
const _promptReserve = 140.0; // Positioned.fill(bottom:) for the viewer on mobile
const _headerH = 48.0; // mobile grabber height
const _collapsedH = _headerH; // no bottom inset in tests
const _expandedH = 800 * 0.75;

/// Replicates the main screen's default body Stack: the image viewer pinned
/// above the prompt reserve, a stand-in for the prompt area, and the settings
/// panel as the LAST child (so it hit-tests first).
Future<void> pumpMainStack(WidgetTester tester, {required bool expanded, Uint8List? image}) async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  final prefsService = PreferencesService(prefs, const FlutterSecureStorage());

  await tester.pumpWidget(
    ChangeNotifierProvider<ThemeNotifier>(
      create: (_) => ThemeNotifier(prefsService),
      child: MaterialApp(
        home: Scaffold(
          body: Stack(
            children: [
              Positioned.fill(
                bottom: _promptReserve,
                child: ImagePreviewViewer(
                  generatedImage: image ?? _png(832, 1216),
                  isLoading: false,
                  isDragging: false,
                  pulseAnimation: const AlwaysStoppedAnimation(0.5),
                ),
              ),
              // Prompt area stand-in (bottom: 48 + inset on mobile).
              Positioned(
                left: 0,
                right: 0,
                bottom: 48,
                child: SizedBox(height: 80, child: Container(key: const Key('prompt'))),
              ),
              SettingsPanelFrame(
                isExpanded: expanded,
                collapsedHeight: _collapsedH,
                expandedHeight: _expandedH,
                headerHeight: _headerH,
                mobile: true,
                collapsedLabel: 'ADVANCED SETTINGS',
                onToggle: () {},
                expandedContent: expanded ? const SizedBox.expand(key: Key('content')) : null,
              ),
            ],
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

/// Every render object on the hit path at [point].
List<RenderObject> hitTargets(WidgetTester tester, Offset point) {
  final result = HitTestResult();
  tester.binding.hitTestInView(result, point, tester.view.viewId);
  return result.path.map((e) => e.target).whereType<RenderObject>().toList();
}

bool _isUnder(RenderObject candidate, RenderObject ancestor) {
  RenderObject? r = candidate;
  while (r != null) {
    if (identical(r, ancestor)) return true;
    r = r.parent;
  }
  return false;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    // Phone-sized logical viewport (isMobile: width < 600).
    TestWidgetsFlutterBinding.instance.platformDispatcher.views.first
      ..physicalSize = _screen
      ..devicePixelRatio = 1.0;
  });

  tearDown(() {
    TestWidgetsFlutterBinding.instance.platformDispatcher.views.first
      ..resetPhysicalSize()
      ..resetDevicePixelRatio();
  });

  group('main-screen Stack hit testing (mobile, settings panel collapsed)', () {
    testWidgets('a point in the bottom quarter of the image reaches the InteractiveViewer, not the panel', (tester) async {
      await pumpMainStack(tester, expanded: false);

      final viewerBox = tester.getRect(find.byType(ImagePreviewViewer));
      expect(viewerBox.bottom, _screen.height - _promptReserve);

      final viewer = tester.renderObject(find.byType(InteractiveViewer));
      final panel = tester.renderObject(find.byType(SettingsPanelFrame));

      // Bottom quarter of the image box, horizontally centred.
      final bottomQuarter = Offset(viewerBox.center.dx, viewerBox.bottom - viewerBox.height * 0.125);
      final targets = hitTargets(tester, bottomQuarter);

      expect(targets.any((t) => _isUnder(t, viewer)), isTrue,
          reason: 'the pinch recogniser must see a finger landing on the bottom of the image');
      expect(targets.any((t) => _isUnder(t, panel)), isFalse,
          reason: 'the collapsed panel must not intercept pointers above its slot');
    });

    testWidgets('two fingers, one on each half, both reach the InteractiveViewer', (tester) async {
      await pumpMainStack(tester, expanded: false);
      final viewerBox = tester.getRect(find.byType(ImagePreviewViewer));
      final viewer = tester.renderObject(find.byType(InteractiveViewer));

      final top = Offset(viewerBox.center.dx - 40, viewerBox.top + viewerBox.height * 0.25);
      final bottom = Offset(viewerBox.center.dx + 40, viewerBox.top + viewerBox.height * 0.9);
      for (final p in [top, bottom]) {
        expect(hitTargets(tester, p).any((t) => _isUnder(t, viewer)), isTrue, reason: '$p');
      }
    });

    testWidgets('the letterbox band beside a wide image still hits the viewer (opaque detector)', (tester) async {
      // A wide image inside the tall preview box leaves empty bands above and
      // below the pixels; those used to have no hit-testable child.
      await pumpMainStack(tester, expanded: false, image: _png(1216, 832));
      final viewerBox = tester.getRect(find.byType(ImagePreviewViewer));
      final viewer = tester.renderObject(find.byType(InteractiveViewer));

      final imageBox = tester.getRect(find.byType(Image));
      expect(imageBox.bottom, lessThan(viewerBox.bottom - 20), reason: 'test needs a real band');

      final band = Offset(viewerBox.center.dx, viewerBox.bottom - 8);
      expect(hitTargets(tester, band).any((t) => _isUnder(t, viewer)), isTrue);
    });

    testWidgets('the collapsed grabber itself still takes the tap', (tester) async {
      await pumpMainStack(tester, expanded: false);
      final panel = tester.renderObject(find.byType(SettingsPanelFrame));
      final grabber = Offset(_screen.width / 2, _screen.height - _collapsedH / 2);
      expect(hitTargets(tester, grabber).any((t) => _isUnder(t, panel)), isTrue);
    });

    testWidgets('the panel is clipped to its slot', (tester) async {
      await pumpMainStack(tester, expanded: false);
      final clip = find.descendant(of: find.byType(SettingsPanelFrame), matching: find.byType(ClipRect));
      expect(clip, findsOneWidget);
      // Inside the 1px border of the panel container, never taller than the slot.
      final slot = tester.getRect(clip);
      expect(slot.height, lessThanOrEqualTo(_collapsedH));
      expect(slot.top, greaterThanOrEqualTo(_screen.height - _collapsedH));
      expect(slot.bottom, lessThanOrEqualTo(_screen.height));
    });
  });

  testWidgets('repeated pinches accept a second finger in the lower half', (tester) async {
    await pumpMainStack(tester, expanded: false, image: _png(1216, 832));
    final controller = tester.widget<InteractiveViewer>(find.byType(InteractiveViewer)).transformationController!;
    for (var i = 0; i < 3; i++) {
      final before = controller.value.getMaxScaleOnAxis();
      final first = await tester.startGesture(const Offset(160, 200), pointer: 1);
      await first.moveBy(const Offset(0, -25));
      final second = await tester.startGesture(const Offset(240, 560), pointer: 2);
      await second.moveBy(const Offset(0, 20));
      await first.moveBy(const Offset(0, -40));
      await second.moveBy(const Offset(0, 40));
      expect(controller.value.getMaxScaleOnAxis(), greaterThan(before));
      await second.up();
      await first.up();
      await tester.pumpAndSettle();
    }
  });

  group('main-screen Stack hit testing (mobile, settings panel expanded)', () {
    testWidgets('the expanded panel covers the image bottom, the image top stays reachable', (tester) async {
      await pumpMainStack(tester, expanded: true);
      final viewer = tester.renderObject(find.byType(InteractiveViewer));
      final panel = tester.renderObject(find.byType(SettingsPanelFrame));

      final covered = Offset(_screen.width / 2, _screen.height - _expandedH + 40);
      expect(hitTargets(tester, covered).any((t) => _isUnder(t, panel)), isTrue);
      expect(hitTargets(tester, covered).any((t) => _isUnder(t, viewer)), isFalse);

      final above = Offset(_screen.width / 2, _screen.height - _expandedH - 40);
      expect(hitTargets(tester, above).any((t) => _isUnder(t, viewer)), isTrue);
      expect(hitTargets(tester, above).any((t) => _isUnder(t, panel)), isFalse);
    });
  });

  testWidgets('the outer detector of the viewer is opaque and double-tap still zooms', (tester) async {
    await pumpMainStack(tester, expanded: false);
    final detector = tester.widget<GestureDetector>(
      find.ancestor(of: find.byType(InteractiveViewer), matching: find.byType(GestureDetector)).first,
    );
    expect(detector.behavior, HitTestBehavior.opaque);

    final viewerBox = tester.getRect(find.byType(ImagePreviewViewer));
    final controller = tester.widget<InteractiveViewer>(find.byType(InteractiveViewer)).transformationController!;
    expect(controller.value.getMaxScaleOnAxis(), 1.0);

    final p = Offset(viewerBox.center.dx, viewerBox.bottom - 30);
    await tester.tapAt(p);
    await tester.pump(kDoubleTapMinTime);
    await tester.tapAt(p);
    await tester.pumpAndSettle();
    expect(controller.value.getMaxScaleOnAxis(), greaterThan(2.0));
  });
}
