import 'dart:js_interop';

import 'package:flutter/material.dart';
import 'package:web/web.dart' as web;

/// Browsers own the window; nothing to configure.
Future<void> configureDesktopWindow() async {}

/// Handle to a registered window focus/blur listener.
abstract interface class WindowFocusSubscription {
  void cancel();
}

/// Registers browser window focus/blur callbacks; cancel the returned
/// subscription in `dispose`.
WindowFocusSubscription addWindowFocusListener({
  required VoidCallback onFocus,
  required VoidCallback onBlur,
}) {
  return _BrowserWindowFocusSubscription(onFocus, onBlur);
}

class _BrowserWindowFocusSubscription implements WindowFocusSubscription {
  _BrowserWindowFocusSubscription(VoidCallback onFocus, VoidCallback onBlur)
    : _focusHandler = ((web.Event _) => onFocus()).toJS,
      _blurHandler = ((web.Event _) => onBlur()).toJS {
    web.window.addEventListener('focus', _focusHandler);
    web.window.addEventListener('blur', _blurHandler);
  }

  final JSFunction _focusHandler;
  final JSFunction _blurHandler;

  @override
  void cancel() {
    web.window.removeEventListener('focus', _focusHandler);
    web.window.removeEventListener('blur', _blurHandler);
  }
}
