import 'dart:io';

import 'package:context_collector/src/features/scan/models/scan_result.dart';
import 'package:context_collector/src/features/scan/models/scanned_file.dart';
import 'package:context_collector/src/features/scan/state/file_list_state.dart';
import 'package:file_selector/file_selector.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> _waitFor(
  bool Function() condition, {
  String reason = 'condition was not met',
}) async {
  for (var i = 0; i < 50; i++) {
    if (condition()) return;
    await Future<void>.delayed(const Duration(milliseconds: 10));
  }
  fail(reason);
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('ScannedFile editor content', () {
    test(
      'keeps unloaded real files distinct from loaded empty files',
      () async {
        final directory = await Directory.systemTemp.createTemp(
          'context_collector_scanned_file_test',
        );
        addTearDown(() => directory.delete(recursive: true));
        final diskFile = File('${directory.path}/notes.txt');
        await diskFile.writeAsString('from disk');

        final unloaded = ScannedFile.fromFile(diskFile);
        expect(unloaded.editorContent, isNull);
        expect(unloaded.hasEditorContent, isFalse);
        expect(unloaded.effectiveContent, isEmpty);

        final loadedEmpty = unloaded.copyWith(content: '');
        expect(loadedEmpty.editorContent, isEmpty);
        expect(loadedEmpty.hasEditorContent, isTrue);
      },
    );

    test('can clear edited content explicitly', () async {
      final file = ScannedFile(
        id: 'file_1',
        name: 'notes.txt',
        fullPath: '/tmp/notes.txt',
        relativePath: 'notes.txt',
        extension: '.txt',
        size: 5,
        lastModified: DateTime.utc(2026),
        source: ScanSource.browse,
        content: 'base',
        editedContent: '',
      );

      final cleared = file.copyWith(clearEditedContent: true);

      expect(cleared.editedContent, isNull);
      expect(cleared.editorContent, 'base');
      expect(cleared.isDirty, isFalse);
    });
  });

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

  group('FileListNotifier editor binding', () {
    test('lazy loads the first active real file', () async {
      final directory = await Directory.systemTemp.createTemp(
        'context_collector_file_list_test',
      );
      addTearDown(() => directory.delete(recursive: true));
      final diskFile = File('${directory.path}/first.txt');
      await diskFile.writeAsString('real file content');

      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(selectionProvider.notifier);

      await notifier.processDroppedItems([XFile(diskFile.path)]);

      await _waitFor(
        () =>
            container.read(selectionProvider).activeFile?.content ==
            'real file content',
        reason: 'first active file never loaded',
      );

      final activeFile = container.read(selectionProvider).activeFile;
      expect(activeFile?.editorContent, 'real file content');
    });

    test('refuses Monaco writeback until the file is editor-bound', () async {
      final directory = await Directory.systemTemp.createTemp(
        'context_collector_writeback_test',
      );
      addTearDown(() => directory.delete(recursive: true));
      final diskFile = File('${directory.path}/source.txt');
      await diskFile.writeAsString('original content');

      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(selectionProvider.notifier);

      await notifier.processDroppedItems([XFile(diskFile.path)]);
      await _waitFor(
        () =>
            container.read(selectionProvider).activeFile?.content ==
            'original content',
        reason: 'source file never loaded',
      );

      final activeFile = container.read(selectionProvider).activeFile!;
      expect(notifier.saveEditorTextFor(activeFile.id, ''), isFalse);
      expect(
        container.read(selectionProvider).fileMap[activeFile.id]?.editedContent,
        isNull,
      );

      notifier.markEditorContentBoundToFile(activeFile.id);
      expect(notifier.saveEditorTextFor(activeFile.id, ''), isTrue);

      final editedFile = container
          .read(selectionProvider)
          .fileMap[activeFile.id]!;
      expect(editedFile.editedContent, isEmpty);
      expect(editedFile.isDirty, isTrue);
    });

    test(
      'keeps previous editor binding long enough to flush on switch',
      () async {
        final directory = await Directory.systemTemp.createTemp(
          'context_collector_switch_flush_test',
        );
        addTearDown(() => directory.delete(recursive: true));
        final first = File('${directory.path}/first.txt');
        final second = File('${directory.path}/second.txt');
        await first.writeAsString('first content');
        await second.writeAsString('second content');

        final container = ProviderContainer();
        addTearDown(container.dispose);
        final notifier = container.read(selectionProvider.notifier);

        await notifier.processDroppedItems([
          XFile(first.path),
          XFile(second.path),
        ]);
        await _waitFor(
          () =>
              container.read(selectionProvider).activeFile?.content ==
              'first content',
          reason: 'first file never loaded',
        );

        final firstId = container.read(selectionProvider).activeFileId!;
        final secondId = container
            .read(selectionProvider)
            .fileMap
            .values
            .firstWhere((file) => file.fullPath == second.path)
            .id;

        notifier
          ..markEditorContentBoundToFile(firstId)
          ..setActiveFile(secondId);

        expect(container.read(selectionProvider).editorBoundFileId, firstId);
        expect(
          notifier.saveEditorTextFor(firstId, 'edited before switch completed'),
          isTrue,
        );
        expect(
          container.read(selectionProvider).fileMap[firstId]?.editedContent,
          'edited before switch completed',
        );
      },
    );
  });
}
