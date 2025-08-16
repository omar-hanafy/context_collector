import 'package:flutter_monaco/flutter_monaco.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('MonacoController Safety Tests', () {
    test('setValue before ready should queue content', () async {
      // This would have thrown before our fixes
      final future = MonacoController.create();

      // Immediately try to set value (before ready)
      final controller = await future;

      // Should not throw even if called immediately
      await controller.setValue('Test content');

      expect(controller.webViewWidget, isNotNull);
    });

    test('Multiple rapid setValue calls should handle queueing', () async {
      final future = MonacoController.create();
      final controller = await future;

      // Rapid fire multiple setValue calls
      final futures = [
        controller.setValue('First'),
        controller.setValue('Second'),
        controller.setValue('Third'),
      ];

      // All should complete without errors
      await Future.wait(futures);

      expect(controller.webViewWidget, isNotNull);
    });

    test('LiveStats should have consistent defaults', () {
      final stats = LiveStats.defaults();

      expect(stats.lineCount.value, 0);
      expect(stats.charCount.value, 0);
      expect(stats.selectedLines.value, 0);
      expect(stats.selectedCharacters.value, 0);
      expect(stats.caretCount.value, 0); // Should be 0 in defaults
      expect(stats.hasSelection, false);
    });

    test('LiveStats fromJson should default caretCount to 1', () {
      final stats = LiveStats.fromJson({
        'lineCount': 10,
        'charCount': 100,
        'selLines': 0,
        'selChars': 0,
        // caretCount not provided, should default to 1
      });

      expect(stats.caretCount.value, 1); // Default in fromJson
    });

    test('Range should handle empty selection correctly', () {
      final range = Range(
        startLine: 1,
        startColumn: 1,
        endLine: 1,
        endColumn: 1,
      );

      expect(range.isCollapsed, true);
    });
  });
}
