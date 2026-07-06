import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';

/// Configures the native desktop window (size, title, visibility).
Future<void> configureDesktopWindow() async {
  await windowManager.ensureInitialized();

  const windowOptions = WindowOptions(
    size: Size(1400, 850),
    center: true,
    backgroundColor: Colors.transparent,
    skipTaskbar: false,
    titleBarStyle: TitleBarStyle.normal,
    title: 'Context Collector',
  );

  await windowManager.waitUntilReadyToShow(windowOptions, () async {
    await windowManager.show();
    await windowManager.focus();
  });
}

/// Handle to a registered window focus/blur listener.
abstract interface class WindowFocusSubscription {
  void cancel();
}

/// Registers native window focus/blur callbacks; cancel the returned
/// subscription in `dispose`.
WindowFocusSubscription addWindowFocusListener({
  required VoidCallback onFocus,
  required VoidCallback onBlur,
}) {
  return _NativeWindowFocusSubscription(onFocus, onBlur);
}

class _NativeWindowFocusSubscription
    with WindowListener
    implements WindowFocusSubscription {
  _NativeWindowFocusSubscription(this._onFocus, this._onBlur) {
    windowManager.addListener(this);
  }

  final VoidCallback _onFocus;
  final VoidCallback _onBlur;

  @override
  void onWindowFocus() => _onFocus();

  @override
  void onWindowBlur() => _onBlur();

  @override
  void cancel() {
    windowManager.removeListener(this);
  }
}
