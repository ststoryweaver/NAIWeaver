import 'dart:async';
import 'dart:io';
import 'dart:ui';
import 'package:window_manager/window_manager.dart';
import 'preferences_service.dart';

/// Hide promptly, finish accepted writes, then close once. All platform calls
/// are bounded so a stalled plugin cannot strand an invisible application.
class AppWindowListener extends WindowListener {
  AppWindowListener(
    this.prefs, {
    WindowManager? manager,
    this.flushPendingWrites,
    void Function(int)? forceExit,
    this.shutdownTimeout = const Duration(seconds: 2),
  }) : manager = manager ?? windowManager,
       forceExit = forceExit ?? exit;

  final PreferencesService prefs;
  final WindowManager manager;
  final Future<void> Function()? flushPendingWrites;
  final void Function(int) forceExit;
  final Duration shutdownTimeout;
  Future<void>? _closing;

  @override
  void onWindowClose() => unawaited(close());

  /// A normal OS close can emit onWindowClose again; share the same operation.
  Future<void> close() => _closing ??= _close();

  Future<void> _close() async {
    Rect? bounds;
    var maximized = false;
    try {
      bounds = await manager.getBounds().timeout(
        const Duration(milliseconds: 400),
      );
    } catch (_) {}
    try {
      maximized = await manager.isMaximized().timeout(
        const Duration(milliseconds: 200),
      );
    } catch (_) {}
    try {
      await manager.hide().timeout(const Duration(milliseconds: 400));
    } catch (_) {}
    try {
      if (bounds != null && bounds.width >= 400 && bounds.height >= 300) {
        await prefs
            .saveWindowState(
              x: bounds.left,
              y: bounds.top,
              w: bounds.width,
              h: bounds.height,
              maximized: maximized,
            )
            .timeout(shutdownTimeout);
      }
    } catch (_) {}
    try {
      await flushPendingWrites?.call().timeout(shutdownTimeout);
    } catch (_) {}
    try {
      await manager.setPreventClose(false).timeout(shutdownTimeout);
      await manager.close().timeout(shutdownTimeout);
    } catch (_) {
      try {
        await manager.destroy().timeout(shutdownTimeout);
      } catch (_) {
        forceExit(0);
      }
    }
  }
}
