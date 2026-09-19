import 'dart:async';
import 'dart:ui';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:window_manager/window_manager.dart';
import 'package:naiweaver/core/services/app_window_listener.dart';
import 'package:naiweaver/core/services/preferences_service.dart';

class TestWindow extends Fake implements WindowManager {
  final events = <String>[];
  bool stallClose = false;
  bool stallDestroy = false;
  void Function()? onClose;
  @override
  Future<Rect> getBounds() async => const Rect.fromLTWH(10, 20, 800, 600);
  @override
  Future<bool> isMaximized() async => true;
  @override
  Future<void> hide() async {
    events.add('hide');
  }

  @override
  Future<void> setPreventClose(bool value) async {
    events.add('prevent:$value');
  }

  @override
  Future<void> close() async {
    events.add('close');
    onClose?.call();
    if (stallClose) await Completer<void>().future;
  }

  @override
  Future<void> destroy() async {
    events.add('destroy');
    if (stallDestroy) await Completer<void>().future;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late PreferencesService prefs;
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = PreferencesService(
      await SharedPreferences.getInstance(),
      const FlutterSecureStorage(),
    );
  });

  test('hides, saves geometry, flushes writes and closes only once', () async {
    final window = TestWindow();
    final listener = AppWindowListener(
      prefs,
      manager: window,
      flushPendingWrites: () async {
        expect(window.events, ['hide']);
        expect(prefs.windowBounds?.w, 800);
        window.events.add('flush');
      },
    );
    window.onClose = listener.onWindowClose;
    final first = listener.close();
    expect(identical(first, listener.close()), isTrue);
    await first;
    expect(window.events, ['hide', 'flush', 'prevent:false', 'close']);
    expect(prefs.windowMaximized, isTrue);
  });

  test('a stuck flush cannot prevent close', () async {
    final window = TestWindow();
    await AppWindowListener(
      prefs,
      manager: window,
      shutdownTimeout: const Duration(milliseconds: 10),
      flushPendingWrites: () => Completer<void>().future,
    ).close();
    expect(window.events.last, 'close');
  });

  test('timed out close falls back to destroy', () async {
    final window = TestWindow()..stallClose = true;
    await AppWindowListener(
      prefs,
      manager: window,
      shutdownTimeout: const Duration(milliseconds: 10),
    ).close();
    expect(window.events.last, 'destroy');
  });

  test('timed out close and destroy use the final exit fallback', () async {
    final window = TestWindow()
      ..stallClose = true
      ..stallDestroy = true;
    int? exitCode;
    await AppWindowListener(
      prefs,
      manager: window,
      shutdownTimeout: const Duration(milliseconds: 10),
      forceExit: (code) => exitCode = code,
    ).close();
    expect(exitCode, 0);
  });
}
