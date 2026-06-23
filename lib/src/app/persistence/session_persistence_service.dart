import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:collection/collection.dart';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../features/editor/data/providers.dart';
import '../../features/scan/models/scanned_file.dart';
import '../../features/scan/state/file_list_state.dart';
import '../session_manager.dart';
import 'saved_session.dart';

final sessionPersistenceProvider = Provider<SessionPersistenceService>((ref) {
  return SessionPersistenceService();
});

class SessionPersistenceService {
  static const int _recentlyClosedLimit = 20;
  final List<String> _recentlyClosedIds = <String>[];
  Future<void> _writeQueue = Future<void>.value();

  Future<Directory> _baseDir() async {
    final supportDir = await getApplicationSupportDirectory();
    final target = Directory(p.join(supportDir.path, 'workspaces'));
    if (!target.existsSync()) {
      target.createSync(recursive: true);
    }
    return target;
  }

  Future<File> _indexFile() async {
    final dir = await _baseDir();
    return File(p.join(dir.path, 'index.json'));
  }

  Future<File> _sessionFile(String sessionId) async {
    final dir = await _baseDir();
    return File(p.join(dir.path, '$sessionId.json'));
  }

  Future<List<SavedSessionIndexItem>> list({bool includeActive = true}) async {
    final file = await _indexFile();
    if (!file.existsSync()) {
      return const <SavedSessionIndexItem>[];
    }
    try {
      final raw = jsonDecode(await file.readAsString()) as List<dynamic>;
      final items = raw
          .map(
            (dynamic item) => SavedSessionIndexItem.fromJson(
              (item as Map<dynamic, dynamic>).cast<String, dynamic>(),
            ),
          )
          .toList(growable: false);
      if (includeActive) {
        return items;
      }
      return items.where((item) => !item.isActive).toList(growable: false);
    } catch (error, stackTrace) {
      debugPrint('[SessionPersistence] Failed to read index: $error');
      debugPrintStack(stackTrace: stackTrace);
      return const <SavedSessionIndexItem>[];
    }
  }

  Future<T> _enqueueWrite<T>(Future<T> Function() action) {
    final completer = Completer<T>();
    _writeQueue = _writeQueue
        .then((_) async {
          try {
            final result = await action();
            if (!completer.isCompleted) {
              completer.complete(result);
            }
          } catch (error, stackTrace) {
            if (!completer.isCompleted) {
              completer.completeError(error, stackTrace);
            }
            // Re-throw so the catchError below can log; the queue will continue
            // because the catchError handler returns normally.
            rethrow;
          }
        })
        .catchError((Object error, StackTrace stackTrace) {
          debugPrint('[SessionPersistence] write queue error: $error');
        });

    return completer.future;
  }

  Future<void> _atomicWrite(File file, String contents) async {
    final tmp = File('${file.path}.tmp');
    await tmp.writeAsString(contents, flush: true);
    if (await file.exists()) {
      await file.delete();
    }
    await tmp.rename(file.path);
  }

  Future<void> _writeIndex(List<SavedSessionIndexItem> items) async {
    final file = await _indexFile();
    final payload = jsonEncode(
      items.map((e) => e.toJson()).toList(growable: false),
    );
    await _atomicWrite(file, payload);
  }

  Future<SavedSession?> load(String sessionId) async {
    final file = await _sessionFile(sessionId);
    if (!file.existsSync()) return null;
    try {
      final raw =
          jsonDecode(await file.readAsString()) as Map<dynamic, dynamic>;
      return SavedSession.fromJson(raw.cast<String, dynamic>());
    } catch (error, stackTrace) {
      debugPrint(
        '[SessionPersistence] Failed to load session $sessionId: $error',
      );
      debugPrintStack(stackTrace: stackTrace);
      return null;
    }
  }

  Future<void> delete(String sessionId) {
    return _enqueueWrite(() async {
      final file = await _sessionFile(sessionId);
      if (file.existsSync()) {
        await file.delete();
      }
      final items = await list();
      await _writeIndex(
        items.where((item) => item.sessionId != sessionId).toList(),
      );
      _recentlyClosedIds.remove(sessionId);
    });
  }

  bool hasPersistableContent(
    SelectionState selection, {
    String? liveEditorText,
    String? activeFileId,
  }) {
    if (selection.fileMap.isEmpty) {
      return false;
    }
    for (final file in selection.fileMap.values) {
      if (!file.isVirtual) {
        return true;
      }
      var content = file.effectiveContent;
      if (!selection.viewingAll &&
          activeFileId != null &&
          liveEditorText != null &&
          file.id == activeFileId) {
        content = liveEditorText;
      }
      if (content.trim().isNotEmpty) {
        return true;
      }
    }
    return false;
  }

  Future<SavedSession?> saveSession(
    SessionEntry entry, {
    bool isActive = true,
  }) {
    return _enqueueWrite(() async {
      final container = entry.container;
      final initialSelection = container.read(selectionProvider);
      final controller = container.read(monacoControllerProvider);
      String? liveEditorText;
      if (!initialSelection.viewingAll &&
          initialSelection.editorIsBoundToActiveFile &&
          controller != null &&
          initialSelection.activeFileId != null) {
        try {
          liveEditorText = await controller.getValue();
        } catch (error, stackTrace) {
          debugPrint(
            '[SessionPersistence] Failed to read editor value: $error',
          );
          debugPrintStack(stackTrace: stackTrace);
        }
      }

      final selection = container.read(selectionProvider);
      final currentActiveId = selection.activeFileId;
      if (!hasPersistableContent(
        selection,
        liveEditorText: liveEditorText,
        activeFileId: currentActiveId,
      )) {
        return null;
      }
      final title = container.read(sessionTitleProvider);

      String realKey(ScannedFile file) => file.fullPath;
      String virtualKey(ScannedFile file) {
        final relative = file.relativePath;
        final key = relative.isEmpty ? file.name : relative;
        return 'vpath:$key';
      }

      final realFiles = <String>[
        for (final file in selection.fileMap.values)
          if (!file.isVirtual) file.fullPath,
      ]..sort();

      final virtualFiles = <VirtualFileSnapshot>[
        for (final file in selection.fileMap.values)
          if (file.isVirtual)
            VirtualFileSnapshot(
              name: file.name,
              content:
                  (!selection.viewingAll &&
                      liveEditorText != null &&
                      file.id == currentActiveId)
                  ? liveEditorText
                  : file.effectiveContent,
              virtualPath: file.relativePath.isEmpty ? null : file.relativePath,
            ),
      ]..sort((a, b) => a.name.compareTo(b.name));

      final selectedKeys = <String>[
        for (final file in selection.selectedFiles)
          file.isVirtual ? virtualKey(file) : realKey(file),
      ];

      final activeFile = selection.activeFile;
      final activeKey = activeFile == null
          ? null
          : activeFile.isVirtual
          ? virtualKey(activeFile)
          : realKey(activeFile);

      final overrides = <String, String>{};
      for (final file in selection.fileMap.values) {
        if (file.isVirtual) continue;
        if (!selection.viewingAll &&
            selection.editorIsBoundToActiveFile &&
            liveEditorText != null &&
            file.id == currentActiveId) {
          overrides[file.fullPath] = liveEditorText;
          continue;
        }
        final edited = file.editedContent;
        if (edited != null) {
          overrides[file.fullPath] = edited;
        }
      }

      final saved = SavedSession(
        sessionId: entry.id,
        title: title,
        savedAt: DateTime.now().toUtc(),
        filePaths: realFiles,
        virtualFiles: virtualFiles,
        selectedKeys: selectedKeys,
        viewingAll: selection.viewingAll,
        isActive: isActive,
        schemaVersion: SavedSession.currentSchemaVersion,
        activeKey: activeKey,
        editedOverridesByPath: overrides,
      );

      final payload = jsonEncode(saved.toJson());
      final sessionFile = await _sessionFile(saved.sessionId);
      await _atomicWrite(sessionFile, payload);

      final currentIndex = await list();
      final filtered =
          currentIndex
              .where((item) => item.sessionId != saved.sessionId)
              .toList()
            ..add(
              SavedSessionIndexItem(
                sessionId: saved.sessionId,
                title: saved.title,
                savedAt: saved.savedAt,
                fileCount: realFiles.length + virtualFiles.length,
                isActive: isActive,
              ),
            )
            ..sort((a, b) => b.savedAt.compareTo(a.savedAt));
      await _writeIndex(filtered);

      if (isActive) {
        _recentlyClosedIds.remove(saved.sessionId);
      } else {
        _recentlyClosedIds
          ..remove(saved.sessionId)
          ..insert(0, saved.sessionId);
        if (_recentlyClosedIds.length > _recentlyClosedLimit) {
          _recentlyClosedIds.removeRange(
            _recentlyClosedLimit,
            _recentlyClosedIds.length,
          );
        }
      }

      return saved;
    });
  }

  Future<SessionEntry> restoreIntoNewSession(
    WidgetRef ref,
    SavedSession saved, {
    bool removeSource = true,
  }) async {
    final manager = ref.read(sessionManagerProvider.notifier);
    final entry = manager.createSession();
    ref.read(activeSessionIdProvider.notifier).state = entry.id;

    final notifier = entry.container.read(selectionProvider.notifier);

    for (final virtual in saved.virtualFiles) {
      notifier.createVirtualFile(
        virtual.name,
        virtual.content,
        virtualPath:
            (virtual.virtualPath == null || virtual.virtualPath!.isEmpty)
            ? virtual.name
            : virtual.virtualPath,
      );
    }

    if (saved.filePaths.isNotEmpty) {
      final files = <XFile>[];
      final missing = <String>[];
      for (final path in saved.filePaths) {
        if (path.isEmpty) continue;
        final file = File(path);
        if (file.existsSync()) {
          files.add(XFile(file.path));
        } else {
          missing.add(path);
        }
      }
      if (missing.isNotEmpty) {
        debugPrint('[SessionPersistence] Skipping missing files: $missing');
      }
      if (files.isNotEmpty) {
        await notifier.processDroppedItems(files);
      }
    }

    if (saved.editedOverridesByPath.isNotEmpty) {
      final state = entry.container.read(selectionProvider);
      for (final entryFile in state.fileMap.values) {
        if (!entryFile.isVirtual) {
          final content = saved.editedOverridesByPath[entryFile.fullPath];
          if (content != null) {
            notifier.onFileContentChanged(entryFile.id, content);
          }
        }
      }
    }

    String? resolveId(String key) {
      final current = entry.container.read(selectionProvider);
      if (key.startsWith('vpath:')) {
        final path = key.substring('vpath:'.length);
        return current.fileMap.values
            .firstWhereOrNull(
              (file) =>
                  file.isVirtual &&
                  (file.relativePath == path || file.name == path),
            )
            ?.id;
      }
      if (key.startsWith('virtual:')) {
        final name = key.substring('virtual:'.length);
        return current.fileMap.values
            .firstWhereOrNull((file) => file.isVirtual && file.name == name)
            ?.id;
      }
      return current.fileMap.values
          .firstWhereOrNull(
            (file) => !file.isVirtual && file.fullPath == key,
          )
          ?.id;
    }

    final selectedIds = <String>{};
    for (final key in saved.selectedKeys) {
      final id = resolveId(key);
      if (id != null) {
        selectedIds.add(id);
      }
    }
    if (selectedIds.isNotEmpty) {
      notifier.onTreeSelectionChanged(selectedIds);
    }

    if (saved.activeKey != null) {
      final id = resolveId(saved.activeKey!);
      if (id != null) {
        notifier.setActiveFile(id);
      }
    }

    notifier.setViewingAll(saved.viewingAll);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final monaco = entry.container.read(monacoEditorStatusProvider.notifier);
      unawaited(monaco.layout());
      unawaited(monaco.recoverKeyboardFocus());
    });

    if (removeSource) {
      await delete(saved.sessionId);
    }
    await saveSession(entry, isActive: true);

    return entry;
  }

  Future<SavedSession?> takeMostRecentClosed() async {
    while (_recentlyClosedIds.isNotEmpty) {
      final sessionId = _recentlyClosedIds.removeAt(0);
      final snapshot = await load(sessionId);
      if (snapshot != null && !snapshot.isActive) {
        return snapshot;
      }
    }

    final closed = await list(includeActive: false);
    if (closed.isEmpty) {
      return null;
    }
    final snapshot = await load(closed.first.sessionId);
    if (snapshot == null) {
      await delete(closed.first.sessionId);
      return takeMostRecentClosed();
    }
    return snapshot;
  }
}
