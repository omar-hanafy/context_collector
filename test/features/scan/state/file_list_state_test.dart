import 'package:context_collector/src/features/scan/state/file_list_state.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('FileListNotifier buildSelectedContextContent', () {
    test('builds content even when the view-all cache is empty', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(selectionProvider.notifier)
        ..createVirtualFile('notes.txt', 'hello from editor');

      final state = container.read(selectionProvider);
      expect(state.viewingAll, isFalse);
      expect(state.combinedContent, isEmpty);

      final content = await notifier.buildSelectedContextContent();

      expect(content, contains('# Context Collection'));
      expect(content, contains('## notes.txt'));
      expect(content, contains('hello from editor'));
    });

    test('returns empty content when nothing is selected', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final content = await container
          .read(selectionProvider.notifier)
          .buildSelectedContextContent();

      expect(content, isEmpty);
    });
  });
}
