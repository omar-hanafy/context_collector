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

    expect(pubspec, contains('flutter_monaco: ^2.1.1'));
    expect(pubspec, isNot(contains('webview_flutter:')));
    expect(pubspec, isNot(contains('webview_flutter_windows:')));
    expect(pubspec, isNot(contains('webview_windows:')));
  });
}
