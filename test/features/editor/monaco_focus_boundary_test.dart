import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'Context Collector delegates Monaco TextInput handoff to flutter_monaco',
    () {
      final appSource = Directory('lib')
          .listSync(recursive: true)
          .whereType<File>()
          .where((file) => file.path.endsWith('.dart'))
          .map((file) => file.readAsStringSync())
          .join('\n');

      expect(appSource, isNot(contains('TextInput.hide')));
      expect(appSource, isNot(contains('SystemChannels.textInput')));
      expect(appSource, isNot(contains('primaryFocusIsFlutterTextInput')));
    },
  );

  test('Context Collector does not depend directly on WebView plugins', () {
    final pubspec = File('pubspec.yaml').readAsStringSync();

    // 2.2.0 is the first version with the macOS native first-responder
    // handoff; the app's per-click user intent on macOS relies on it being
    // cheap (no focus replay when the editor already owns native focus).
    expect(pubspec, contains('flutter_monaco: ^2.2.0'));
    expect(pubspec, isNot(contains('webview_flutter:')));
    expect(pubspec, isNot(contains('webview_flutter_windows:')));
    expect(pubspec, isNot(contains('webview_windows:')));
  });

  test('tab switching is treated as a native input-readiness boundary', () {
    final tabShell = File('lib/src/app/tab_shell.dart').readAsStringSync();

    expect(tabShell, contains('setVisibleForKeyboardInput'));
    expect(tabShell, contains('afterNativeFocusBoundary: true'));
    expect(
      tabShell,
      contains('recoverKeyboardFocusAfterNativeFocusBoundary'),
    );
  });
}
