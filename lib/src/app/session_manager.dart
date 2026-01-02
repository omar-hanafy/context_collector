import 'dart:async';

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../features/editor/data/monaco_service.dart';
import '../features/editor/data/providers.dart';
import '../features/scan/services/markdown_builder.dart';
import '../features/scan/state/file_list_state.dart';
import '../features/virtual_tree/directory_tree_adapter.dart';
import '../features/virtual_tree/providers/virtual_tree_provider.dart';
import 'persistence/session_persistence_service.dart';
import 'route_observers.dart';

/// Per-session UI metadata, scoped within each session's ProviderContainer.
/// Currently exposes the tab title rendered in the tab strip.
final sessionTitleProvider = StateProvider<String>((_) => 'Tab');

class SessionEntry {
  SessionEntry(this.id, this.container)
    : navigatorKey = GlobalKey<NavigatorState>();

  final String id;
  final ProviderContainer container;
  final GlobalKey<NavigatorState> navigatorKey;
  Timer? autoSaveTimer;
  ProviderSubscription<SelectionState>? autoSaveSubscription;
  Timer? autoSavePeriodic;
}

class SessionManager extends StateNotifier<List<SessionEntry>> {
  SessionManager(this.ref) : super(const []) {
    ref.onDispose(_disposeAllSessions);
  }

  final Ref ref;
  final _uuid = const Uuid();

  SessionEntry createSession() {
    final sessionId = _uuid.v4();
    final defaultTitle = 'Tab ${state.length + 1}';

    final container = ProviderContainer(
      parent: ref.container,
      overrides: [
        routeObserverProvider.overrideWithValue(
          RouteObserver<PageRoute<dynamic>>(),
        ),
        selectionProvider.overrideWith((overrideRef) {
          final markdownBuilder = MarkdownBuilder();
          return FileListNotifier(
            ref: overrideRef,
            markdownBuilder: markdownBuilder,
          );
        }),
        directoryTreeAdapterProvider.overrideWith((overrideRef) {
          final adapter = DirectoryTreeAdapter();
          overrideRef.onDispose(adapter.dispose);
          return adapter;
        }),
        monacoEditorStatusProvider.overrideWith((overrideRef) {
          // Keep Monaco alive across route swaps inside a tab.
          // ignore: unused_local_variable
          final link = overrideRef.keepAlive();
          return MonacoService();
        }),

        sessionTitleProvider.overrideWith((_) => defaultTitle),
      ],
    );

    container
        .read(selectionProvider.notifier)
        .initializeDirectoryTree(
          container.read(directoryTreeAdapterProvider),
        );

    final entry = SessionEntry(sessionId, container);
    _attachAutoSave(entry);
    state = [...state, entry];
    return entry;
  }

  void closeSession(String id) {
    final entryIndex = state.indexWhere((entry) => entry.id == id);
    if (entryIndex == -1) {
      throw StateError('Session not found');
    }

    final entry = state[entryIndex];
    final nextSessions = [...state]..removeAt(entryIndex);
    state = nextSessions;

    final activeId = ref.read(activeSessionIdProvider);
    if (activeId == id) {
      final newActive = nextSessions.isEmpty ? null : nextSessions.last.id;
      ref.read(activeSessionIdProvider.notifier).state = newActive;
      if (newActive != null) {
        final target = nextSessions.firstWhereOrNull(
          (session) => session.id == newActive,
        );
        if (target != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            unawaited(_restoreSessionFocus(target));
          });
        }
      }
    }

    entry.autoSaveTimer?.cancel();
    entry
      ..autoSaveTimer = null
      ..autoSavePeriodic?.cancel()
      ..autoSavePeriodic = null
      ..autoSaveSubscription?.close()
      ..autoSaveSubscription = null;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      entry.container.dispose();
    });
  }

  void _disposeAllSessions() {
    for (final entry in state) {
      entry
        ..autoSaveTimer?.cancel()
        ..autoSavePeriodic?.cancel()
        ..autoSaveSubscription?.close()
        ..autoSaveTimer = null
        ..autoSavePeriodic = null
        ..autoSaveSubscription = null
        ..container.dispose();
    }
  }

  Future<void> _restoreSessionFocus(SessionEntry entry) async {
    final service = entry.container.read(monacoEditorStatusProvider.notifier);
    await service.layout();
    await service.recoverKeyboardFocus();
  }

  void _attachAutoSave(SessionEntry entry) {
    final container = entry.container;
    final persistence = container.read(sessionPersistenceProvider);
    entry
      ..autoSaveTimer?.cancel()
      ..autoSaveTimer = null
      ..autoSavePeriodic?.cancel()
      ..autoSavePeriodic = null
      ..autoSaveSubscription?.close()
      ..autoSaveSubscription = container.listen<SelectionState>(
      selectionProvider,
      (previous, next) {
        if (!(next.sessionStarted ||
            next.hasFiles ||
            next.scanHistory.isNotEmpty)) {
          return;
        }
        entry.autoSaveTimer?.cancel();
        entry.autoSaveTimer = Timer(const Duration(seconds: 2), () {
          unawaited(persistence.saveSession(entry, isActive: true));
        });
      },
      fireImmediately: false,
    )
      ..autoSavePeriodic = Timer.periodic(const Duration(seconds: 30), (_) {
        unawaited(persistence.saveSession(entry, isActive: true));
      });
  }
}

final sessionManagerProvider =
    StateNotifierProvider<SessionManager, List<SessionEntry>>((ref) {
      return SessionManager(ref);
    });

final activeSessionIdProvider = StateProvider<String?>((_) => null);
