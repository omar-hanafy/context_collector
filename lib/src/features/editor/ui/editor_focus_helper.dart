import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/providers.dart';
import '../data/monaco_service.dart';

/// A helper class to manage focus restoration for the Monaco editor.
class EditorFocusHelper {
  EditorFocusHelper._();

  /// Restores focus to the Monaco editor after a dialog closes.
  ///
  /// This is a workaround for a known issue on macOS where platform views
  /// (like the Monaco editor) don't regain focus automatically.
  static Future<void> restoreFocus(WidgetRef ref) async {
    // 1) Release any lingering Flutter text input client.
    try { FocusManager.instance.primaryFocus?.unfocus(); } catch (_) {}
    try {
      await SystemChannels.textInput.invokeMethod<void>('TextInput.clearClient');
    } catch (_) {}

    // 2) Wait for frames so platform views reattach after a route pop.
    await WidgetsBinding.instance.endOfFrame;
    await WidgetsBinding.instance.endOfFrame;

    // 3) Ensure native WebView becomes first responder, then focus Monaco.
    final service = ref.read(monacoEditorStatusProvider.notifier) as MonacoService;
    await service.ensureNativeFocus();
    final controller = ref.read(monacoControllerProvider);
    await controller?.focus();
  }
}
