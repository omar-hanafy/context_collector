import 'dart:async';
import 'dart:ui' show PointerDeviceKind;

import 'package:context_collector/src/app/shortcuts/shortcut_defaults.dart';
import 'package:desktop_drop/desktop_drop.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/gestures.dart' show kMiddleMouseButton;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_monaco/flutter_monaco.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../features/editor/data/providers.dart';
import '../features/editor/data/settings_service.dart';
import '../features/editor/ui/dialogs/settings_dialog.dart';
import '../features/scan/state/file_list_state.dart';
import '../features/settings/presentation/state/theme_notifier.dart';
import '../shared/dialogs/name_prompt.dart';
import '../shared/platform/platform_caps.dart';
import '../shared/services/drop_payload_splitter.dart';
import '../shared/utils/debug_logger.dart';
import 'global_hotkeys.dart';
import 'persistence/saved_session.dart';
import 'persistence/session_persistence_service.dart';
import 'session_manager.dart';
import 'session_navigator.dart';
import 'shortcuts/shortcut_registry.dart' as app_shortcuts;

enum _TabMenuAction {
  rename,
  newTab,
  refresh,
  newFile,
  paste,
  pastePaths,
  addFiles,
  addFolder,
  duplicate,
  saveWorkspace,
  saveCombined,
  close,
  closeOthers,
  closeAll,
  shortcutSettings,
}

enum _MacEditCommand {
  undo,
  redo,
  cut,
  copy,
  paste,
  selectAll,
}

class _MenuItem {
  const _MenuItem(
    this.action,
    this.label,
    this.icon, {
    this.command,
  });

  final _TabMenuAction action;
  final String label;
  final IconData icon;
  final TabShortcutCommand? command;
}

class TabShell extends ConsumerStatefulWidget {
  const TabShell({super.key});

  @override
  ConsumerState<TabShell> createState() => _TabShellState();
}

class _TabShellState extends ConsumerState<TabShell> {
  static const MethodChannel _macEditChannel = MethodChannel(
    'context_collector/macos_edit',
  );

  final Map<String, GlobalKey> _tabKeys = <String, GlobalKey>{};
  final GlobalKey _addTabKey = GlobalKey();
  String? _hoverTabId;
  bool _isDragging = false;
  String? _editingSessionId;
  bool _isAddTabDropTarget = false;
  final Uuid _uuid = const Uuid();

  void _syncKeyboardVisibleSession(
    List<SessionEntry> sessions,
    String? activeId,
  ) {
    for (final session in sessions) {
      session.container
          .read(monacoEditorStatusProvider.notifier)
          .setVisibleForKeyboardInput(session.id == activeId);
    }
  }

  void _activateSession(SessionEntry session) {
    final activeId = ref.read(activeSessionIdProvider);
    _syncKeyboardVisibleSession(
      ref.read(sessionManagerProvider),
      session.id,
    );
    if (_editingSessionId != null && _editingSessionId != session.id) {
      setState(() => _editingSessionId = null);
    }
    if (activeId != session.id) {
      ref.read(activeSessionIdProvider.notifier).state = session.id;
    }
  }

  void _startRename(SessionEntry session) {
    _activateSession(session);
    if (_editingSessionId == session.id) return;
    setState(() => _editingSessionId = session.id);
  }

  void _handleRenameCommit(SessionEntry session, String rawName) {
    final trimmed = rawName.trim();
    final controller = session.container.read(sessionTitleProvider.notifier);
    final current = session.container.read(sessionTitleProvider);
    if (trimmed.isNotEmpty && trimmed != current) {
      controller.state = trimmed;
      unawaited(
        _saveWorkspace(
          session,
          markActive: true,
          showSnack: false,
          syncEditor: false,
        ),
      );
    }
    if (_editingSessionId != null) {
      setState(() => _editingSessionId = null);
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_restoreSessionFocus(session));
    });
  }

  @override
  Widget build(BuildContext context) {
    final sessions = ref.watch(sessionManagerProvider);
    final activeId = ref.watch(activeSessionIdProvider);

    _tabKeys.removeWhere(
      (id, _) => sessions.every((session) => session.id != id),
    );

    if (sessions.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final entry = ref.read(sessionManagerProvider.notifier).createSession();
        ref.read(activeSessionIdProvider.notifier).state = entry.id;
      });
      return const SizedBox.shrink();
    }

    var currentIndex = sessions.indexWhere((entry) => entry.id == activeId);
    if (currentIndex == -1) {
      currentIndex = 0;
      final fallbackId = sessions.first.id;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(activeSessionIdProvider.notifier).state = fallbackId;
      });
    }
    final visibleSessionId = sessions[currentIndex].id;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _syncKeyboardVisibleSession(
        ref.read(sessionManagerProvider),
        ref.read(activeSessionIdProvider) ?? visibleSessionId,
      );
    });

    final app_shortcuts.ShortcutRegistry shortcuts = ref.watch(
      app_shortcuts.shortcutRegistryProvider,
    );
    // PlatformMenuBar needs a native menu delegate; never treat a macOS
    // browser as macOS.
    final isMac = !kIsWeb && Theme.of(context).platform == TargetPlatform.macOS;

    Widget body = GlobalHotkeys(
      registry: shortcuts,
      onCommand: _handleShortcut,
      child: Scaffold(
        body: DropTarget(
          onDragEntered: (_) {
            if (!_isDragging) {
              setState(() => _isDragging = true);
            }
          },
          onDragExited: (_) {
            if (_isDragging) {
              setState(() {
                _isDragging = false;
                _hoverTabId = null;
                _isAddTabDropTarget = false;
              });
            }
          },
          onDragUpdated: (details) {
            _updateHoverTab(details.globalPosition, sessions);
          },
          onDragDone: (details) async {
            logDropDetails(details, source: 'TabShell/DropTarget');
            await _handleDrop(details, sessions, activeId);
          },
          child: Column(
            children: [
              _TabBar(
                sessions: sessions,
                activeId: activeId,
                hoverTabId: _hoverTabId,
                isDragging: _isDragging,
                tabKeys: _tabKeys,
                onSelect: _handleSelectTab,
                onClose: _handleCloseTab,
                onAddTab: _handleAddTabPressed,
                onRenameRequest: _startRename,
                onRenameCommit: _handleRenameCommit,
                onContextMenu: _showTabContextMenu,
                editingSessionId: _editingSessionId,
                addTabKey: _addTabKey,
                isAddDropTarget: _isAddTabDropTarget,
              ),
              Expanded(
                child: IndexedStack(
                  index: currentIndex,
                  children: [
                    for (final session in sessions)
                      UncontrolledProviderScope(
                        key: ValueKey('session-${session.id}'),
                        container: session.container,
                        child: SessionNavigator(
                          navigatorKey: session.navigatorKey,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );

    if (isMac) {
      body = PlatformMenuBar(
        menus: _buildMacMenus(shortcuts),
        child: body,
      );
    }

    return Focus(
      autofocus: true,
      child: body,
    );
  }

  List<PlatformMenuItem> _buildMacMenus(
    app_shortcuts.ShortcutRegistry shortcuts,
  ) {
    final platform = Theme.of(context).platform;

    SingleActivator? s(TabShortcutCommand command) =>
        shortcuts.activatorFor(command, platform);

    return <PlatformMenuItem>[
      PlatformMenu(
        label: 'Context Collector',
        menus: <PlatformMenuItem>[
          const PlatformMenuItemGroup(
            members: <PlatformMenuItem>[
              PlatformProvidedMenuItem(
                type: PlatformProvidedMenuItemType.about,
              ),
            ],
          ),
          PlatformMenuItemGroup(
            members: <PlatformMenuItem>[
              PlatformMenuItem(
                label: 'Preferences…',
                shortcut: s(TabShortcutCommand.settings),
                onSelected: () =>
                    unawaited(_handleShortcut(TabShortcutCommand.settings)),
              ),
              PlatformMenuItem(
                label: 'Keyboard Shortcuts…',
                onSelected: () => unawaited(_openShortcutSettings()),
              ),
            ],
          ),
          const PlatformMenuItemGroup(
            members: <PlatformMenuItem>[
              PlatformProvidedMenuItem(
                type: PlatformProvidedMenuItemType.servicesSubmenu,
              ),
            ],
          ),
          const PlatformMenuItemGroup(
            members: <PlatformMenuItem>[
              PlatformProvidedMenuItem(
                type: PlatformProvidedMenuItemType.hide,
              ),
              PlatformProvidedMenuItem(
                type: PlatformProvidedMenuItemType.hideOtherApplications,
              ),
              PlatformProvidedMenuItem(
                type: PlatformProvidedMenuItemType.showAllApplications,
              ),
            ],
          ),
          const PlatformMenuItemGroup(
            members: <PlatformMenuItem>[
              PlatformProvidedMenuItem(
                type: PlatformProvidedMenuItemType.quit,
              ),
            ],
          ),
        ],
      ),
      PlatformMenu(
        label: 'File',
        menus: <PlatformMenuItem>[
          PlatformMenuItemGroup(
            members: <PlatformMenuItem>[
              PlatformMenuItem(
                label: 'New Tab',
                shortcut: s(TabShortcutCommand.newTab),
                onSelected: () =>
                    unawaited(_handleShortcut(TabShortcutCommand.newTab)),
              ),
              PlatformMenuItem(
                label: 'New File',
                shortcut: s(TabShortcutCommand.newFile),
                onSelected: () =>
                    unawaited(_handleShortcut(TabShortcutCommand.newFile)),
              ),
              PlatformMenuItem(
                label: 'Duplicate Tab',
                shortcut: s(TabShortcutCommand.duplicate),
                onSelected: () =>
                    unawaited(_handleShortcut(TabShortcutCommand.duplicate)),
              ),
            ],
          ),
          PlatformMenuItemGroup(
            members: <PlatformMenuItem>[
              PlatformMenuItem(
                label: 'Add Files…',
                shortcut: s(TabShortcutCommand.addFiles),
                onSelected: () =>
                    unawaited(_handleShortcut(TabShortcutCommand.addFiles)),
              ),
              if (PlatformCaps.supportsDirectoryPicker)
                PlatformMenuItem(
                  label: 'Add Folder…',
                  shortcut: s(TabShortcutCommand.addFolder),
                  onSelected: () =>
                      unawaited(_handleShortcut(TabShortcutCommand.addFolder)),
                ),
              PlatformMenuItem(
                label: 'Save Workspace…',
                shortcut: s(TabShortcutCommand.saveWorkspace),
                onSelected: () => unawaited(
                  _handleShortcut(TabShortcutCommand.saveWorkspace),
                ),
              ),
              PlatformMenuItem(
                label: 'Save Combined…',
                shortcut: s(TabShortcutCommand.saveCombined),
                onSelected: () =>
                    unawaited(_handleShortcut(TabShortcutCommand.saveCombined)),
              ),
            ],
          ),
          PlatformMenuItemGroup(
            members: <PlatformMenuItem>[
              PlatformMenuItem(
                label: 'Close Tab',
                shortcut: s(TabShortcutCommand.close),
                onSelected: () =>
                    unawaited(_handleShortcut(TabShortcutCommand.close)),
              ),
              PlatformMenuItem(
                label: 'Close Others',
                shortcut: s(TabShortcutCommand.closeOthers),
                onSelected: () =>
                    unawaited(_handleShortcut(TabShortcutCommand.closeOthers)),
              ),
              PlatformMenuItem(
                label: 'Close All',
                shortcut: s(TabShortcutCommand.closeAll),
                onSelected: () =>
                    unawaited(_handleShortcut(TabShortcutCommand.closeAll)),
              ),
              PlatformMenuItem(
                label: 'Reopen Closed Tab',
                shortcut: s(TabShortcutCommand.reopenClosed),
                onSelected: () =>
                    unawaited(_handleShortcut(TabShortcutCommand.reopenClosed)),
              ),
            ],
          ),
        ],
      ),
      PlatformMenu(
        label: 'Edit',
        menus: <PlatformMenuItem>[
          PlatformMenuItemGroup(
            members: <PlatformMenuItem>[
              PlatformMenuItem(
                label: 'Undo',
                shortcut: const SingleActivator(
                  LogicalKeyboardKey.keyZ,
                  meta: true,
                ),
                onSelected: () =>
                    unawaited(_performMacEditCommand(_MacEditCommand.undo)),
              ),
              PlatformMenuItem(
                label: 'Redo',
                shortcut: const SingleActivator(
                  LogicalKeyboardKey.keyZ,
                  meta: true,
                  shift: true,
                ),
                onSelected: () =>
                    unawaited(_performMacEditCommand(_MacEditCommand.redo)),
              ),
            ],
          ),
          PlatformMenuItemGroup(
            members: <PlatformMenuItem>[
              PlatformMenuItem(
                label: 'Cut',
                shortcut: const SingleActivator(
                  LogicalKeyboardKey.keyX,
                  meta: true,
                ),
                onSelected: () =>
                    unawaited(_performMacEditCommand(_MacEditCommand.cut)),
              ),
              PlatformMenuItem(
                label: 'Copy',
                shortcut: const SingleActivator(
                  LogicalKeyboardKey.keyC,
                  meta: true,
                ),
                onSelected: () =>
                    unawaited(_performMacEditCommand(_MacEditCommand.copy)),
              ),
              PlatformMenuItem(
                label: 'Paste',
                shortcut: const SingleActivator(
                  LogicalKeyboardKey.keyV,
                  meta: true,
                ),
                onSelected: () =>
                    unawaited(_performMacEditCommand(_MacEditCommand.paste)),
              ),
              PlatformMenuItem(
                label: 'Select All',
                shortcut: const SingleActivator(
                  LogicalKeyboardKey.keyA,
                  meta: true,
                ),
                onSelected: () => unawaited(
                  _performMacEditCommand(_MacEditCommand.selectAll),
                ),
              ),
            ],
          ),
          PlatformMenuItemGroup(
            members: <PlatformMenuItem>[
              PlatformMenuItem(
                label: 'Refresh',
                shortcut: s(TabShortcutCommand.refresh),
                onSelected: () =>
                    unawaited(_handleShortcut(TabShortcutCommand.refresh)),
              ),
              PlatformMenuItem(
                label: 'Rename',
                shortcut: s(TabShortcutCommand.rename),
                onSelected: () =>
                    unawaited(_handleShortcut(TabShortcutCommand.rename)),
              ),
            ],
          ),
          PlatformMenuItemGroup(
            members: <PlatformMenuItem>[
              PlatformMenuItem(
                label: 'Paste as New File',
                shortcut: s(TabShortcutCommand.paste),
                onSelected: () =>
                    unawaited(_handleShortcut(TabShortcutCommand.paste)),
              ),
              if (PlatformCaps.supportsPastePaths)
                PlatformMenuItem(
                  label: 'Paste Paths',
                  shortcut: s(TabShortcutCommand.pastePaths),
                  onSelected: () => unawaited(
                    _handleShortcut(TabShortcutCommand.pastePaths),
                  ),
                ),
              PlatformMenuItem(
                label: 'Copy Combined',
                shortcut: s(TabShortcutCommand.copyCombined),
                onSelected: () =>
                    unawaited(_handleShortcut(TabShortcutCommand.copyCombined)),
              ),
            ],
          ),
        ],
      ),
      const PlatformMenu(
        label: 'Window',
        menus: <PlatformMenuItem>[
          PlatformMenuItemGroup(
            members: <PlatformMenuItem>[
              PlatformProvidedMenuItem(
                type: PlatformProvidedMenuItemType.minimizeWindow,
              ),
              PlatformProvidedMenuItem(
                type: PlatformProvidedMenuItemType.zoomWindow,
              ),
            ],
          ),
          PlatformMenuItemGroup(
            members: <PlatformMenuItem>[
              PlatformProvidedMenuItem(
                type: PlatformProvidedMenuItemType.arrangeWindowsInFront,
              ),
              PlatformProvidedMenuItem(
                type: PlatformProvidedMenuItemType.toggleFullScreen,
              ),
            ],
          ),
        ],
      ),
    ];
  }

  Future<void> _performMacEditCommand(_MacEditCommand command) async {
    if (kIsWeb || Theme.of(context).platform != TargetPlatform.macOS) {
      return;
    }

    final String commandName = switch (command) {
      _MacEditCommand.undo => 'undo',
      _MacEditCommand.redo => 'redo',
      _MacEditCommand.cut => 'cut',
      _MacEditCommand.copy => 'copy',
      _MacEditCommand.paste => 'paste',
      _MacEditCommand.selectAll => 'selectAll',
    };

    try {
      await _macEditChannel.invokeMethod<void>('perform', commandName);
    } on MissingPluginException {
      // Channel is only wired up on macOS.
    } catch (error, stackTrace) {
      FlutterError.reportError(
        FlutterErrorDetails(
          exception: error,
          stack: stackTrace,
          library: 'tab_shell.dart',
          context: ErrorDescription(
            'while invoking macOS edit command "$commandName"',
          ),
        ),
      );
    }
  }

  void _updateHoverTab(Offset globalPosition, List<SessionEntry> sessions) {
    String? nextHover;
    for (final session in sessions) {
      final rect = _rectForTab(session.id);
      if (rect != null && rect.contains(globalPosition)) {
        nextHover = session.id;
        break;
      }
    }

    final overAdd = _isOverAddButton(globalPosition);
    if (overAdd) {
      nextHover = null;
    }

    if (nextHover != _hoverTabId || overAdd != _isAddTabDropTarget) {
      setState(() {
        _hoverTabId = nextHover;
        _isAddTabDropTarget = overAdd;
      });
    }
  }

  SessionEntry? _resolveActiveSession(
    List<SessionEntry> sessions,
    String? activeId,
  ) {
    if (sessions.isEmpty) return null;
    if (activeId == null) {
      return sessions.first;
    }
    return sessions.firstWhere(
      (session) => session.id == activeId,
      orElse: () => sessions.first,
    );
  }

  Future<void> _handleShortcut(TabShortcutCommand command) async {
    final sessions = ref.read(sessionManagerProvider);
    final activeId = ref.read(activeSessionIdProvider);
    final session = _resolveActiveSession(sessions, activeId);
    if (session == null && command != TabShortcutCommand.newTab) {
      return;
    }

    switch (command) {
      case TabShortcutCommand.newTab:
        _handleAddTab();
        return;
      case TabShortcutCommand.rename:
        final current = session!;
        _startRename(current);
        return;
      case TabShortcutCommand.refresh:
        final current = session!;
        await current.container
            .read(selectionProvider.notifier)
            .refreshAllContents();
        unawaited(_restoreSessionFocus(current));
        return;
      case TabShortcutCommand.newFile:
        final current = session!;
        await _createNewFileInSession(current);
        unawaited(
          _restoreSessionFocus(current, intent: MonacoFocusIntent.user),
        );
        return;
      case TabShortcutCommand.paste:
        final current = session!;
        await _pasteClipboardAsFile(current);
        unawaited(_restoreSessionFocus(current));
        return;
      case TabShortcutCommand.pastePaths:
        final current = session!;
        await current.container
            .read(selectionProvider.notifier)
            .pastePathsFromClipboard(context);
        unawaited(_restoreSessionFocus(current));
        return;
      case TabShortcutCommand.addFiles:
        final current = session!;
        await current.container
            .read(selectionProvider.notifier)
            .pickFiles(context);
        unawaited(_restoreSessionFocus(current));
        return;
      case TabShortcutCommand.addFolder:
        final current = session!;
        await current.container
            .read(selectionProvider.notifier)
            .pickDirectory(context);
        unawaited(_restoreSessionFocus(current));
        return;
      case TabShortcutCommand.saveWorkspace:
        final current = session!;
        await _saveWorkspace(current);
        unawaited(_restoreSessionFocus(current));
        return;
      case TabShortcutCommand.saveCombined:
        final current = session!;
        await _saveCombinedInSession(current);
        unawaited(_restoreSessionFocus(current));
        return;
      case TabShortcutCommand.close:
        final current = session!;
        _handleCloseTab(current.id);
        return;
      case TabShortcutCommand.closeOthers:
        final current = session!;
        await _closeOthers(current.id);
        return;
      case TabShortcutCommand.closeAll:
        await _closeAll();
        return;
      case TabShortcutCommand.settings:
        final current = session!;
        await _openEditorSettings(current);
        return;
      case TabShortcutCommand.copyCombined:
        final current = session!;
        await _copyCombinedContent(current);
        return;
      case TabShortcutCommand.reopenClosed:
        await _reopenLastClosedTab();
        return;
      case TabShortcutCommand.duplicate:
        final current = session!;
        await _duplicateSession(current);
        return;
    }
  }

  Rect? _rectForTab(String sessionId) {
    final key = _tabKeys[sessionId];
    final element = key?.currentContext;
    if (element == null) return null;
    final renderObject = element.findRenderObject();
    if (renderObject is! RenderBox || !renderObject.hasSize) return null;
    final topLeft = renderObject.localToGlobal(Offset.zero);
    return topLeft & renderObject.size;
  }

  Rect? _rectForAddButton() {
    final context = _addTabKey.currentContext;
    if (context == null) return null;
    final renderObject = context.findRenderObject();
    if (renderObject is! RenderBox || !renderObject.hasSize) return null;
    final topLeft = renderObject.localToGlobal(Offset.zero);
    return topLeft & renderObject.size;
  }

  bool _isOverAddButton(Offset position) {
    final rect = _rectForAddButton();
    if (rect == null) return false;
    return rect.contains(position);
  }

  Future<void> _handleDrop(
    DropDoneDetails details,
    List<SessionEntry> sessions,
    String? activeId,
  ) async {
    if (sessions.isEmpty) return;

    setState(() {
      _isDragging = false;
    });

    final dropPosition = _resolveDropPosition(details);
    final isOverAdd = _isOverAddButton(dropPosition);
    SessionEntry target;
    if (isOverAdd) {
      target = _handleAddTab();
    } else {
      final hoveredId = _tabIdAtPosition(dropPosition, sessions) ?? _hoverTabId;
      final targetId = hoveredId ?? activeId ?? sessions.first.id;
      target = sessions.firstWhere(
        (session) => session.id == targetId,
        orElse: () => sessions.first,
      );

      if (target.id != activeId) {
        ref.read(activeSessionIdProvider.notifier).state = target.id;
      }
    }

    final split = await DropPayloadSplitter.fromDetails(details);

    final selectionNotifier = target.container.read(selectionProvider.notifier);

    if (split.hasFiles) {
      await selectionNotifier.processDroppedItems(split.files);
    } else if (split.hasTextOnly) {
      for (final text in split.texts) {
        selectionNotifier.createVirtualFileWithAutoName(
          text,
          promptForName: true,
        );
      }
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_restoreSessionFocus(target));
    });

    if (mounted) {
      setState(() {
        _hoverTabId = null;
        _isAddTabDropTarget = false;
      });
    }
  }

  Offset _resolveDropPosition(DropDoneDetails details) =>
      details.globalPosition;

  String? _tabIdAtPosition(Offset position, List<SessionEntry> sessions) {
    for (final session in sessions) {
      final rect = _rectForTab(session.id);
      if (rect != null && rect.contains(position)) {
        return session.id;
      }
    }
    return null;
  }

  Future<void> _restoreSessionFocus(
    SessionEntry session, {
    MonacoFocusIntent intent = MonacoFocusIntent.maintenance,
    bool afterNativeFocusBoundary = false,
  }) async {
    final service = session.container.read(monacoEditorStatusProvider.notifier);
    await service.layout();
    if (afterNativeFocusBoundary) {
      await service.recoverKeyboardFocusAfterNativeFocusBoundary();
      return;
    }
    await service.recoverKeyboardFocus(intent: intent);
  }

  Future<void> _syncActiveEditorContent(SessionEntry session) async {
    final service = session.container.read(monacoEditorStatusProvider.notifier);
    final selectionState = session.container.read(selectionProvider);
    final activeFileId = selectionState.activeFileId;
    final viewingAll = selectionState.viewingAll;
    if (!viewingAll &&
        selectionState.editorIsBoundToActiveFile &&
        activeFileId != null) {
      try {
        final text = await service.readFileDocumentText(activeFileId);
        if (text != null) {
          session.container
              .read(selectionProvider.notifier)
              .saveEditorTextFor(activeFileId, text);
        }
      } catch (_) {}
    }
  }

  SessionEntry _handleAddTab() {
    final entry = ref.read(sessionManagerProvider.notifier).createSession();
    ref.read(activeSessionIdProvider.notifier).state = entry.id;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_restoreSessionFocus(entry));
    });
    return entry;
  }

  void _handleAddTabPressed() {
    _handleAddTab();
  }

  void _handleCloseTab(String id) {
    final sessions = ref.read(sessionManagerProvider);
    SessionEntry? entry;
    for (final candidate in sessions) {
      if (candidate.id == id) {
        entry = candidate;
        break;
      }
    }

    unawaited(() async {
      if (entry != null) {
        final hasContent = await _hasPersistableContent(
          entry,
          includeLive: true,
        );
        if (hasContent) {
          final saved = await _saveWorkspace(
            entry,
            markActive: false,
            showSnack: false,
            syncEditor: true,
          );
          if (saved == null) {
            _showSnackBar('Close cancelled - failed to save workspace.');
            return;
          }
        }
      }
      if (mounted && _editingSessionId == id) {
        setState(() => _editingSessionId = null);
      }
      ref.read(sessionManagerProvider.notifier).closeSession(id);
    }());
  }

  Future<void> _showTabContextMenu(
    SessionEntry session,
    Offset globalPosition,
  ) async {
    _activateSession(session);

    final overlay = Overlay.of(context);
    final renderObject = overlay.context.findRenderObject();
    if (renderObject is! RenderBox) return;
    final renderBox = renderObject;

    final position = RelativeRect.fromRect(
      Rect.fromLTWH(globalPosition.dx, globalPosition.dy, 0, 0),
      Offset.zero & renderBox.size,
    );

    const items = <_MenuItem>[
      _MenuItem(
        _TabMenuAction.rename,
        'Rename',
        Icons.drive_file_rename_outline,
        command: TabShortcutCommand.rename,
      ),
      _MenuItem(
        _TabMenuAction.newTab,
        'New tab',
        Icons.add,
        command: TabShortcutCommand.newTab,
      ),
      _MenuItem(
        _TabMenuAction.refresh,
        'Refresh',
        Icons.refresh,
        command: TabShortcutCommand.refresh,
      ),
      _MenuItem(
        _TabMenuAction.newFile,
        'New file',
        Icons.note_add_outlined,
        command: TabShortcutCommand.newFile,
      ),
      _MenuItem(
        _TabMenuAction.duplicate,
        'Duplicate tab',
        Icons.copy_all_outlined,
        command: TabShortcutCommand.duplicate,
      ),
      _MenuItem(
        _TabMenuAction.paste,
        'Paste',
        Icons.content_paste,
        command: TabShortcutCommand.paste,
      ),
      if (PlatformCaps.supportsPastePaths)
        _MenuItem(
          _TabMenuAction.pastePaths,
          'Paste paths',
          Icons.file_copy,
          command: TabShortcutCommand.pastePaths,
        ),
      _MenuItem(
        _TabMenuAction.addFiles,
        'Add files',
        Icons.file_open_outlined,
        command: TabShortcutCommand.addFiles,
      ),
      if (PlatformCaps.supportsDirectoryPicker)
        _MenuItem(
          _TabMenuAction.addFolder,
          'Add folder',
          Icons.create_new_folder_outlined,
          command: TabShortcutCommand.addFolder,
        ),
      _MenuItem(
        _TabMenuAction.saveWorkspace,
        'Save workspace…',
        Icons.save_as_rounded,
        command: TabShortcutCommand.saveWorkspace,
      ),
      _MenuItem(
        _TabMenuAction.saveCombined,
        'Save combined...',
        Icons.save_outlined,
        command: TabShortcutCommand.saveCombined,
      ),
      _MenuItem(
        _TabMenuAction.close,
        'Close',
        Icons.close,
        command: TabShortcutCommand.close,
      ),
      _MenuItem(
        _TabMenuAction.closeOthers,
        'Close others',
        Icons.tab_unselected,
        command: TabShortcutCommand.closeOthers,
      ),
      _MenuItem(
        _TabMenuAction.closeAll,
        'Close all',
        Icons.clear_all,
        command: TabShortcutCommand.closeAll,
      ),
      _MenuItem(
        _TabMenuAction.shortcutSettings,
        'Keyboard shortcuts…',
        Icons.keyboard,
      ),
    ];

    final theme = Theme.of(context);
    final platform = theme.platform;
    final app_shortcuts.ShortcutRegistry registry = ref.read(
      app_shortcuts.shortcutRegistryProvider,
    );
    final baseLabelStyle =
        theme.textTheme.bodySmall ?? DefaultTextStyle.of(context).style;
    final baseColor = baseLabelStyle.color;
    final hintColor = baseColor?.withValues(alpha: 0.6);
    final hintStyle = baseLabelStyle.copyWith(color: hintColor);

    final selection = await showMenu<_TabMenuAction>(
      context: context,
      position: position,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      items: [
        for (final item in items)
          PopupMenuItem<_TabMenuAction>(
            value: item.action,
            height: 30,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: Row(
              mainAxisSize: MainAxisSize.max,
              children: [
                Icon(item.icon, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    item.label,
                    style: baseLabelStyle,
                  ),
                ),
                ..._buildShortcutHintWidgets(
                  command: item.command,
                  registry: registry,
                  platform: platform,
                  hintStyle: hintStyle,
                ),
              ],
            ),
          ),
      ],
    );

    var shouldRestoreFocus = true;

    if (selection == null) {
      shouldRestoreFocus = false;
    } else if (selection == _TabMenuAction.saveWorkspace) {
      await _saveWorkspace(session);
    } else if (selection == _TabMenuAction.shortcutSettings) {
      shouldRestoreFocus = false;
      await _openEditorSettings(session, highlightShortcuts: true);
    } else {
      final command = _commandForMenuAction(selection);
      if (command != null) {
        await _handleShortcut(command);
        if (command == TabShortcutCommand.rename) {
          shouldRestoreFocus = false;
        }
      }
    }

    if (shouldRestoreFocus) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        unawaited(_restoreSessionFocus(session));
      });
    }
  }

  TabShortcutCommand? _commandForMenuAction(_TabMenuAction action) =>
      switch (action) {
        _TabMenuAction.rename => TabShortcutCommand.rename,
        _TabMenuAction.newTab => TabShortcutCommand.newTab,
        _TabMenuAction.refresh => TabShortcutCommand.refresh,
        _TabMenuAction.newFile => TabShortcutCommand.newFile,
        _TabMenuAction.duplicate => TabShortcutCommand.duplicate,
        _TabMenuAction.paste => TabShortcutCommand.paste,
        _TabMenuAction.pastePaths => TabShortcutCommand.pastePaths,
        _TabMenuAction.addFiles => TabShortcutCommand.addFiles,
        _TabMenuAction.addFolder => TabShortcutCommand.addFolder,
        _TabMenuAction.saveWorkspace => TabShortcutCommand.saveWorkspace,
        _TabMenuAction.saveCombined => TabShortcutCommand.saveCombined,
        _TabMenuAction.close => TabShortcutCommand.close,
        _TabMenuAction.closeOthers => TabShortcutCommand.closeOthers,
        _TabMenuAction.closeAll => TabShortcutCommand.closeAll,
        _TabMenuAction.shortcutSettings => null,
      };

  List<Widget> _buildShortcutHintWidgets({
    required TabShortcutCommand? command,
    required app_shortcuts.ShortcutRegistry registry,
    required TargetPlatform platform,
    required TextStyle hintStyle,
  }) {
    if (command == null) return const <Widget>[];
    final text = registry.hintFor(command, platform);
    if (text == null || text.isEmpty) return const <Widget>[];
    return <Widget>[
      const SizedBox(width: 8),
      Text(text, style: hintStyle),
    ];
  }

  Future<void> _createNewFileInSession(SessionEntry session) async {
    const initial = 'pasted.txt';
    final name = await _promptForName(
      context,
      initial: initial,
      label: 'File name',
    );
    if (name == null || name.trim().isEmpty) return;
    session.container
        .read(selectionProvider.notifier)
        .createVirtualFile(name.trim(), '');
  }

  Future<void> _pasteClipboardAsFile(SessionEntry session) async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final text = (data?.text ?? '').trim();
    if (text.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Clipboard is empty.')),
      );
      return;
    }
    session.container
        .read(selectionProvider.notifier)
        .createVirtualFileWithAutoName(text, promptForName: true);
  }

  Future<void> _saveCombinedInSession(SessionEntry session) async {
    await _syncActiveEditorContent(session);
    await session.container.read(selectionProvider.notifier).saveToFile();
  }

  Future<SavedSession?> _saveWorkspace(
    SessionEntry session, {
    bool markActive = true,
    bool showSnack = true,
    bool syncEditor = true,
  }) async {
    if (syncEditor && ref.read(activeSessionIdProvider) == session.id) {
      await _syncActiveEditorContent(session);
    }
    if (!await _hasPersistableContent(session)) {
      if (showSnack) {
        _showSnackBar('Nothing to save yet.');
      }
      return null;
    }
    final service = ref.read(sessionPersistenceProvider);
    try {
      final saved = await service.saveSession(
        session,
        isActive: markActive,
      );
      if (saved == null) {
        if (showSnack) {
          _showSnackBar('Nothing to save yet.');
        }
        return null;
      }
      if (showSnack) {
        _showSnackBar('Saved workspace "${saved.title}"');
      }
      return saved;
    } catch (error) {
      if (showSnack) {
        _showSnackBar('Save failed: $error');
      }
      return null;
    }
  }

  Future<bool> _hasPersistableContent(
    SessionEntry session, {
    bool includeLive = false,
  }) async {
    final selection = session.container.read(selectionProvider);
    String? liveContent;
    if (includeLive &&
        !selection.viewingAll &&
        selection.editorIsBoundToActiveFile &&
        selection.activeFileId != null) {
      final service = session.container.read(
        monacoEditorStatusProvider.notifier,
      );
      try {
        liveContent = await service.readFileDocumentText(
          selection.activeFileId!,
        );
      } catch (_) {}
    }
    final persistence = ref.read(sessionPersistenceProvider);
    return persistence.hasPersistableContent(
      selection,
      liveEditorText: liveContent,
      activeFileId: selection.activeFileId,
    );
  }

  Future<void> _reopenLastClosedTab() async {
    final service = ref.read(sessionPersistenceProvider);
    try {
      final snapshot = await service.takeMostRecentClosed();
      if (snapshot == null) {
        _showSnackBar('No recently closed tabs.');
        return;
      }
      await service.restoreIntoNewSession(ref, snapshot);
      _showSnackBar('Reopened "${snapshot.title}"');
    } catch (error) {
      _showSnackBar('Reopen failed: $error');
    }
  }

  Future<void> _duplicateSession(SessionEntry session) async {
    final snapshot = await _saveWorkspace(
      session,
      markActive: true,
      showSnack: false,
      syncEditor: true,
    );
    if (snapshot == null) {
      _showSnackBar('Duplicate failed.');
      return;
    }

    final service = ref.read(sessionPersistenceProvider);
    final cloned = snapshot.copyWith(
      sessionId: _uuid.v4(),
      savedAt: DateTime.now().toUtc(),
      isActive: false,
    );

    try {
      await service.restoreIntoNewSession(
        ref,
        cloned,
        removeSource: false,
      );
      _showSnackBar('Duplicated "${snapshot.title}"');
    } catch (error) {
      _showSnackBar('Duplicate failed: $error');
    }
  }

  Future<void> _copyCombinedContent(SessionEntry session) async {
    await _syncActiveEditorContent(session);

    try {
      final copied = await session.container
          .read(selectionProvider.notifier)
          .copyContextToClipboard();
      if (!copied) {
        _showSnackBar('Nothing to copy.');
        unawaited(_restoreSessionFocus(session));
        return;
      }
      _showSnackBar('Combined content copied!');
    } catch (e) {
      _showSnackBar('Copy failed: $e');
    }
    unawaited(_restoreSessionFocus(session));
  }

  Future<void> _openShortcutSettings() async {
    final sessions = ref.read(sessionManagerProvider);
    final activeId = ref.read(activeSessionIdProvider);
    final session = _resolveActiveSession(sessions, activeId);
    if (session == null) {
      return;
    }
    await _openEditorSettings(session, highlightShortcuts: true);
  }

  Future<void> _openEditorSettings(
    SessionEntry session, {
    bool highlightShortcuts = false,
  }) async {
    final currentOptions = await EditorSettingsService.load();
    if (!mounted) return;
    final updated = await EditorSettingsDialog.show(
      context,
      currentOptions,
      highlightShortcuts: highlightShortcuts,
    );
    if (updated == null) {
      return;
    }

    await EditorSettingsService.save(updated);
    await ref
        .read(themeProvider.notifier)
        .setThemeFromMonaco(EditorSettingsService.effectiveTheme(updated));

    final sessions = ref.read(sessionManagerProvider);
    final updateFutures = <Future<void>>[];
    for (final entry in sessions) {
      final notifier = entry.container.read(
        monacoEditorStatusProvider.notifier,
      );
      updateFutures.add(notifier.updateOptions(updated));
    }
    await Future.wait(updateFutures);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        unawaited(
          _restoreSessionFocus(session, intent: MonacoFocusIntent.user),
        );
      }
    });
  }

  Future<void> _closeOthers(String keepId) async {
    final sessions = ref.read(sessionManagerProvider);
    final targets = sessions.where((entry) => entry.id != keepId).toList();
    if (targets.isEmpty) return;
    if (mounted && _editingSessionId != null && _editingSessionId != keepId) {
      setState(() => _editingSessionId = null);
    }
    for (final entry in targets) {
      await _saveWorkspace(
        entry,
        markActive: false,
        showSnack: false,
        syncEditor: true,
      );
      ref.read(sessionManagerProvider.notifier).closeSession(entry.id);
    }
  }

  Future<void> _closeAll() async {
    final sessions = ref.read(sessionManagerProvider);
    if (sessions.isEmpty) return;
    if (mounted && _editingSessionId != null) {
      setState(() => _editingSessionId = null);
    }
    for (final entry in List<SessionEntry>.from(sessions)) {
      await _saveWorkspace(
        entry,
        markActive: false,
        showSnack: false,
        syncEditor: true,
      );
      ref.read(sessionManagerProvider.notifier).closeSession(entry.id);
    }
  }

  Future<String?> _promptForName(
    BuildContext context, {
    required String initial,
    String label = 'Name',
  }) {
    return promptForName(
      context,
      title: label,
      initialName: initial,
      labelText: label,
    );
  }

  void _handleSelectTab(SessionEntry session) {
    final activeId = ref.read(activeSessionIdProvider);
    final wasActive = activeId == session.id;
    _activateSession(session);
    if (wasActive) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(
        _restoreSessionFocus(session, afterNativeFocusBoundary: true),
      );
    });
  }

  void _showSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}

class _TabBar extends StatelessWidget {
  const _TabBar({
    required this.sessions,
    required this.activeId,
    required this.hoverTabId,
    required this.isDragging,
    required this.tabKeys,
    required this.onSelect,
    required this.onClose,
    required this.onAddTab,
    required this.onRenameRequest,
    required this.onRenameCommit,
    required this.onContextMenu,
    required this.editingSessionId,
    required this.addTabKey,
    required this.isAddDropTarget,
  });

  final List<SessionEntry> sessions;
  final String? activeId;
  final String? hoverTabId;
  final bool isDragging;
  final Map<String, GlobalKey> tabKeys;
  final void Function(SessionEntry session) onSelect;
  final void Function(String id) onClose;
  final VoidCallback onAddTab;
  final void Function(SessionEntry session) onRenameRequest;
  final void Function(SessionEntry session, String name) onRenameCommit;
  final void Function(SessionEntry session, Offset globalPos) onContextMenu;
  final String? editingSessionId;
  final GlobalKey addTabKey;
  final bool isAddDropTarget;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return SafeArea(
      bottom: false,
      child: Container(
        height: 40,
        color: colorScheme.surface,
        padding: const EdgeInsets.symmetric(horizontal: 6),
        child: Row(
          children: [
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    const SizedBox(width: 8),
                    for (var i = 0; i < sessions.length; i++)
                      Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: UncontrolledProviderScope(
                          container: sessions[i].container,
                          child: _SessionTabChip(
                            key: tabKeys.putIfAbsent(
                              sessions[i].id,
                              GlobalKey.new,
                            ),
                            session: sessions[i],
                            isSelected: sessions[i].id == activeId,
                            isRenaming: sessions[i].id == editingSessionId,
                            isHoverTarget:
                                isDragging && sessions[i].id == hoverTabId,
                            colorScheme: colorScheme,
                            onSelect: onSelect,
                            onClose: onClose,
                            onRenameRequest: onRenameRequest,
                            onRenameCommit: onRenameCommit,
                            onContextMenu: onContextMenu,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),
            _ActionButton(
              key: addTabKey,
              icon: Icons.add,
              label: 'New tab',
              onPressed: onAddTab,
              colorScheme: colorScheme,
              isDropTarget: isAddDropTarget,
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onPressed,
    required this.colorScheme,
    this.isDropTarget = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;
  final ColorScheme colorScheme;
  final bool isDropTarget;

  @override
  Widget build(BuildContext context) {
    final onSurface = colorScheme.onSurface;
    final disabled = onSurface.withValues(alpha: onSurface.a * 0.38);
    final highlightColor = isDropTarget
        ? colorScheme.primary.withValues(alpha: colorScheme.primary.a * 0.12)
        : Colors.transparent;
    final List<BoxShadow> shadow = isDropTarget
        ? <BoxShadow>[
            BoxShadow(
              color: colorScheme.primary.withValues(
                alpha: colorScheme.primary.a * 0.2,
              ),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ]
        : const <BoxShadow>[];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        decoration: BoxDecoration(
          color: highlightColor,
          borderRadius: const BorderRadius.all(Radius.circular(8)),
          boxShadow: shadow,
        ),
        child: TextButton.icon(
          onPressed: onPressed,
          icon: Icon(icon, size: 16),
          label: Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w400,
            ),
          ),
          style: ButtonStyle(
            foregroundColor: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.disabled)) {
                return disabled;
              }
              return onSurface;
            }),
            padding: const WidgetStatePropertyAll(
              EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            ),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            minimumSize: const WidgetStatePropertyAll(Size(0, 28)),
            visualDensity: VisualDensity.compact,
            overlayColor: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.pressed)) {
                return colorScheme.primary.withValues(
                  alpha: colorScheme.primary.a * 0.12,
                );
              }
              return null;
            }),
          ),
        ),
      ),
    );
  }
}

class _SessionTabChip extends ConsumerStatefulWidget {
  const _SessionTabChip({
    required super.key,
    required this.session,
    required this.isSelected,
    required this.isRenaming,
    required this.isHoverTarget,
    required this.colorScheme,
    required this.onSelect,
    required this.onClose,
    required this.onRenameRequest,
    required this.onRenameCommit,
    required this.onContextMenu,
  });

  final SessionEntry session;
  final bool isSelected;
  final bool isRenaming;
  final bool isHoverTarget;
  final ColorScheme colorScheme;
  final ValueChanged<SessionEntry> onSelect;
  final ValueChanged<String> onClose;
  final ValueChanged<SessionEntry> onRenameRequest;
  final void Function(SessionEntry, String) onRenameCommit;
  final void Function(SessionEntry, Offset) onContextMenu;

  @override
  ConsumerState<_SessionTabChip> createState() => _SessionTabChipState();
}

class _SessionTabChipState extends ConsumerState<_SessionTabChip> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;
  bool _submitted = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
    _focusNode = FocusNode();
    _focusNode.addListener(_handleFocusChange);
  }

  @override
  void didUpdateWidget(covariant _SessionTabChip oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!oldWidget.isRenaming && widget.isRenaming) {
      final label = ref.read(sessionTitleProvider);
      _controller
        ..text = label
        ..selection = TextSelection(baseOffset: 0, extentOffset: label.length);
      _submitted = false;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _focusNode.requestFocus();
        }
      });
    } else if (oldWidget.isRenaming && !widget.isRenaming) {
      _submitted = false;
      if (_focusNode.hasFocus) {
        _focusNode.unfocus();
      }
    }
  }

  @override
  void dispose() {
    _focusNode
      ..removeListener(_handleFocusChange)
      ..dispose();
    _controller.dispose();
    super.dispose();
  }

  void _handleFocusChange() {
    if (!widget.isRenaming || _submitted) return;
    if (!_focusNode.hasFocus) {
      _submit();
    }
  }

  void _submit() {
    if (_submitted) return;
    _submitted = true;
    widget.onRenameCommit(widget.session, _controller.text);
  }

  @override
  Widget build(BuildContext context) {
    final label = ref.watch(sessionTitleProvider);

    final borderColor = widget.isHoverTarget
        ? widget.colorScheme.primary
        : widget.colorScheme.outlineVariant.withValues(
            alpha: widget.colorScheme.outlineVariant.a * 0.6,
          );
    final borderWidth = widget.isHoverTarget ? 1.2 : 0.6;
    final backgroundColor = widget.isSelected
        ? widget.colorScheme.surfaceContainerHigh
        : widget.colorScheme.surface;
    final textColor = widget.colorScheme.onSurface;
    final closeColor = textColor.withValues(alpha: textColor.a * 0.7);

    return Listener(
      onPointerDown: (event) {
        if (event.kind == PointerDeviceKind.mouse &&
            event.buttons == kMiddleMouseButton) {
          widget.onClose(widget.session.id);
        }
      },
      child: ClipRRect(
        borderRadius: const BorderRadius.all(Radius.circular(8)),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onSecondaryTapDown: (details) =>
              widget.onContextMenu(widget.session, details.globalPosition),
          onLongPressStart: (details) =>
              widget.onContextMenu(widget.session, details.globalPosition),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 120),
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: const BorderRadius.all(Radius.circular(8)),
              border: Border.all(color: borderColor, width: borderWidth),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (widget.isRenaming)
                  _RenameField(
                    controller: _controller,
                    focusNode: _focusNode,
                    onSubmitted: _submit,
                  )
                else
                  TextButton(
                    onPressed: () {
                      if (widget.isSelected) {
                        widget.onRenameRequest(widget.session);
                      } else {
                        widget.onSelect(widget.session);
                      }
                    },
                    style: ButtonStyle(
                      padding: const WidgetStatePropertyAll(
                        EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      ),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      minimumSize: const WidgetStatePropertyAll(Size(0, 28)),
                      visualDensity: VisualDensity.compact,
                      foregroundColor: WidgetStatePropertyAll(textColor),
                      shape: WidgetStatePropertyAll(
                        RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                    child: Text(
                      label,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ),
                Tooltip(
                  message: 'Close Tab',
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 4,
                    ),
                    child: MouseRegion(
                      cursor: SystemMouseCursors.click,
                      child: GestureDetector(
                        behavior: HitTestBehavior.deferToChild,
                        onTap: () => widget.onClose(widget.session.id),
                        child: Icon(
                          Icons.close,
                          size: 14,
                          color: closeColor,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RenameField extends StatelessWidget {
  const _RenameField({
    required this.controller,
    required this.focusNode,
    required this.onSubmitted,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final VoidCallback onSubmitted;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minWidth: 96, maxWidth: 220),
        child: TextField(
          controller: controller,
          focusNode: focusNode,
          autofocus: true,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => onSubmitted(),
          onEditingComplete: onSubmitted,
          decoration: const InputDecoration(
            isDense: true,
            contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            border: OutlineInputBorder(),
          ),
        ),
      ),
    );
  }
}
