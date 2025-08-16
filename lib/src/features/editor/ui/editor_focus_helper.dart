import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/providers.dart';

/// A helper class to manage focus restoration for the Monaco editor.
class EditorFocusHelper {
  EditorFocusHelper._();

  /// Restores focus to the Monaco editor after a dialog closes.
  ///
  /// This is a workaround for a known issue on macOS where platform views
  /// (like the Monaco editor) don't regain focus automatically.
  static Future<void> restoreFocus(WidgetRef ref) async {
    // 1. Force Flutter's native text input plugin to release the keyboard.
    await SystemChannels.textInput.invokeMethod<void>('TextInput.clearClient');

    // 2. Wait a brief moment for the engine to process the channel message.
    await Future<void>.delayed(const Duration(milliseconds: 50));

    // 3. Now that the path is clear, tell Monaco to take focus.
    final controller = ref.read(monacoControllerProvider);
    await controller?.focus();
  }
}
