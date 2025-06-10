import 'package:context_collector/src/features/editor/domain/editor_settings.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('EditorSettings', () {
    test('toJson produces prefixed keys for SharedPreferences', () {
      const settings = EditorSettings(
        theme: 'vs-dark',
        fontSize: 16,
        showLineNumbers: true,
        wordWrap: WordWrap.on,
      );

      final json = settings.toJson();

      // Check that keys have 'editor_' prefix
      expect(json['editor_theme'], equals('vs-dark'));
      expect(json['editor_font_size'], equals(16));
      expect(json['editor_show_line_numbers'], equals(true));
      expect(json['editor_word_wrap'], equals('on'));
    });

    test('toMonacoOptions produces Monaco-compatible format', () {
      const settings = EditorSettings(
        theme: 'vs-dark',
        fontSize: 16,
        showLineNumbers: true,
        lineNumbersStyle: LineNumbersStyle.on,
        wordWrap: WordWrap.on,
        showMinimap: true,
        minimapSide: MinimapSide.right,
        bracketPairColorization: true,
        cursorBlinking: CursorBlinking.blink,
        multiCursorModifier: MultiCursorModifier.ctrlCmd,
      );

      final monacoOptions = settings.toMonacoOptions();

      // Check that keys do NOT have prefixes
      expect(monacoOptions['fontSize'], equals(16));
      expect(monacoOptions['lineNumbers'], equals('on'));
      expect(monacoOptions['wordWrap'], equals('on'));

      // Check nested options
      expect(monacoOptions['minimap'], isA<Map<String, dynamic>>());
      expect(monacoOptions['minimap']['enabled'], equals(true));
      expect(monacoOptions['minimap']['side'], equals('right'));

      expect(monacoOptions['bracketPairColorization'],
          isA<Map<String, dynamic>>());
      expect(monacoOptions['bracketPairColorization']['enabled'], equals(true));

      expect(monacoOptions['cursorBlinking'], equals('blink'));
      expect(monacoOptions['multiCursorModifier'], equals('ctrlCmd'));

      // Verify theme is NOT included (set separately)
      expect(monacoOptions.containsKey('theme'), isFalse);
      expect(monacoOptions.containsKey('editor_theme'), isFalse);
    });

    test('toMonacoOptions handles line numbers correctly', () {
      // When showLineNumbers is false
      const settingsNoLines = EditorSettings(showLineNumbers: false);
      final optionsNoLines = settingsNoLines.toMonacoOptions();
      expect(optionsNoLines['lineNumbers'], equals('off'));

      // When showLineNumbers is true with different styles
      const settingsRelative = EditorSettings(
        showLineNumbers: true,
        lineNumbersStyle: LineNumbersStyle.relative,
      );
      final optionsRelative = settingsRelative.toMonacoOptions();
      expect(optionsRelative['lineNumbers'], equals('relative'));
    });

    test('toMonacoOptions handles minimap size correctly', () {
      const settings1 = EditorSettings(minimapSize: 1);
      expect(settings1.toMonacoOptions()['minimap']['size'],
          equals('proportional'));

      const settings2 = EditorSettings(minimapSize: 2);
      expect(settings2.toMonacoOptions()['minimap']['size'], equals('fill'));

      const settings3 = EditorSettings(minimapSize: 3);
      expect(settings3.toMonacoOptions()['minimap']['size'], equals('fit'));
    });

    test('toMonacoOptions handles boolean options with objects', () {
      const settings = EditorSettings(
        parameterHints: true,
        hover: true,
        stickyScroll: true,
      );

      final options = settings.toMonacoOptions();

      expect(options['parameterHints'], isA<Map<String, dynamic>>());
      expect(options['parameterHints']['enabled'], equals(true));

      expect(options['hover'], isA<Map<String, dynamic>>());
      expect(options['hover']['enabled'], equals(true));

      expect(options['stickyScroll'], isA<Map<String, dynamic>>());
      expect(options['stickyScroll']['enabled'], equals(true));
    });
  });
}
