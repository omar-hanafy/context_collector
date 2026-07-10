import 'dart:async';
import 'dart:convert';

import 'package:collection/collection.dart';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/editor/data/providers.dart';
import '../../features/scan/models/scanned_file.dart';
import '../../features/scan/services/fs/platform_fs.dart';
import '../../features/scan/state/file_list_state.dart';
import '../session_manager.dart';
import 'saved_session.dart';
import 'session_store/session_store.dart';

final sessionPersistenceProvider = Provider<SessionPersistenceService>((ref) {
  return SessionPersistenceService();
});

class SessionPersistenceService {
  static const int _recentlyClosedLimit = 20;
  final SessionStore _store = SessionStore();
  final List<String> _recentlyClosedIds = <String>[];
  Future<void> _writeQueue = Future<void>.value();

  Future<List<SavedSessionIndexItem>> list({bool includeActive = true}) async {
    final payload = await _store.readIndex();
    if (payload == null) {
      return const <SavedSessionIndexItem>[];
    }
    try {
      final raw = jsonDecode(payload) as List<dynamic>;
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

  Future<void> _writeIndex(List<SavedSessionIndexItem> items) async {
    final payload = jsonEncode(
      items.map((e) => e.toJson()).toList(growable: false),
    );
    await _store.writeIndex(payload);
  }

  Future<SavedSession?> load(String sessionId) async {
    final payload = await _store.readSession(sessionId);
    if (payload == null) return null;
    try {
      final raw = jsonDecode(payload) as Map<dynamic, dynamic>;
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
      await _store.deleteSession(sessionId);
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
      final editorService = container.read(monacoEditorStatusProvider.notifier);
      String? liveEditorText;
      if (!initialSelection.viewingAll &&
          initialSelection.editorIsBoundToActiveFile &&
          initialSelection.activeFileId != null) {
        try {
          liveEditorText = await editorService.readFileDocumentText(
            initialSelection.activeFileId!,
          );
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
      await _store.writeSession(saved.sessionId, payload);

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
        if (PlatformFs.pathExists(path)) {
          files.add(XFile(path));
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
