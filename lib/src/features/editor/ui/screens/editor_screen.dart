import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_monaco/flutter_monaco.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../context_collector.dart';
import '../../../../shared/dialogs/name_prompt.dart';
import '../../../../shared/widgets/shared_drop_zone.dart';
import '../../../scan/ui/file_display_helper.dart';
// Route focus restorer not needed with push/pop lifecycle.

/// Refactored editor screen using flutter_monaco package
class EditorScreen extends ConsumerStatefulWidget {
  const EditorScreen({super.key});

  @override
  ConsumerState<EditorScreen> createState() => _EditorScreenState();
}

class _EditorScreenState extends ConsumerState<EditorScreen>
    with SingleTickerProviderStateMixin {
  Timer? _debounceTimer;
  bool _viewAllToggleBusy = false;

  // Track if a rename dialog is active to avoid stacking.
  bool _renameDialogOpen = false;

  // Settings state
  EditorOptions _editorOptions = const EditorOptions();
  bool _hasAppliedInitialSettings = false;

  // Sidebar removed — editor uses full right panel

  // Splitter controller
  SplitterController? _splitterController;
  bool _isSplitterInitialized = false;
  static const String _splitRatioKey = 'editor_split_ratio';
  ProviderSubscription<EditorStatus>? _editorStatusSub;
  ProviderSubscription<SelectionState>? _selectionSub;

  @override
  void initState() {
    super.initState();

    // Create Monaco for this route instance
    ref.read(monacoEditorStatusProvider.notifier).initialize();

    // Initialize splitter controller with saved ratio
    _initializeSplitter();

    // Load saved editor settings
    _loadEditorSettings();

    // Register Riverpod listeners once
    _wireRiverpodListeners();

    // If Monaco is already ready (prewarmed), push initial content once.
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted || _hasAppliedInitialSettings) return;
      final status = ref.read(monacoEditorStatusProvider);
      if (status.isReady) {
        _hasAppliedInitialSettings = true;
        final selection = ref.read(selectionProvider);
        String text = '';
        String? lang;
        final id = selection.activeFileId;
        if (id != null) {
          final file = selection.fileMap[id];
          if (file != null) {
            text = file.effectiveContent;
            lang = FileDisplayHelper.getLanguageFromFile(file);
          }
        }
        await ref
            .read(monacoEditorStatusProvider.notifier)
            .updateContent(text, language: lang);
        unawaited(
          ref.read(monacoEditorStatusProvider.notifier).ensureNativeFocus(),
        );
      }
    });
  }

  void _wireRiverpodListeners() {
    // Listen for editor ready state to apply initial settings and push initial content
    _editorStatusSub = ref.listenManual<EditorStatus>(
        monacoEditorStatusProvider, (previous, next) async {
      if (!_hasAppliedInitialSettings && next.isReady) {
        _hasAppliedInitialSettings = true;
        
        final selection = ref.read(selectionProvider);
        String text = '';
        String? lang;
        final id = selection.activeFileId;
        if (id != null) {
          final file = selection.fileMap[id];
          if (file != null) {
            text = file.effectiveContent;
            lang = FileDisplayHelper.getLanguageFromFile(file);
          }
        }
        await ref
            .read(monacoEditorStatusProvider.notifier)
            .updateContent(text, language: lang);
        unawaited(
          ref.read(monacoEditorStatusProvider.notifier).ensureNativeFocus(),
        );
      }
    });

    // Keep Monaco’s content in sync with the active file and edits
    _selectionSub = ref.listenManual<SelectionState>(
        selectionProvider, (previous, next) async {
      final editorService = ref.read(monacoEditorStatusProvider.notifier);
      final controller = ref.read(monacoControllerProvider);

      if (!_renameDialogOpen && next.pendingRenameFileId != null) {
        _renameDialogOpen = true;
        WidgetsBinding.instance.addPostFrameCallback((_) async {
          if (!mounted) return;
          final fileId = ref.read(selectionProvider).pendingRenameFileId!;
          final fileName =
              ref.read(selectionProvider).fileMap[fileId]?.name ??
              'pasted.txt';
          final newName = await promptForNewFileName(
            context,
            initialName: fileName,
          );
          if (newName != null && newName.trim().isNotEmpty) {
            ref
                .read(selectionProvider.notifier)
                .renameFile(fileId, newName.trim());
          } else {
            ref.read(selectionProvider.notifier).clearPendingRename();
          }
          _renameDialogOpen = false;
        });
      }

      final prevId = previous?.activeFileId;
      final nextId = next.activeFileId;

      final wasViewingAll = previous?.viewingAll ?? false;
      final isViewingAll = next.viewingAll;

      if ((previous != null && wasViewingAll) && !isViewingAll) {
        String targetText = '';
        String? language;
        if (nextId != null) {
          final file = next.fileMap[nextId];
          if (file != null) {
            targetText = file.effectiveContent;
            language = FileDisplayHelper.getLanguageFromFile(file);
          }
        }
        await editorService.updateContent(targetText, language: language);
        return;
      }

      if (!wasViewingAll &&
          !isViewingAll &&
          prevId != null &&
          prevId != nextId &&
          controller != null) {
        try {
          final currentText = await controller.getValue();
          ref
              .read(selectionProvider.notifier)
              .saveEditorTextFor(prevId, currentText);
        } catch (_) {}
      }

      String targetText = '';
      String? language;
      if (nextId != null) {
        final file = next.fileMap[nextId];
        if (file != null) {
          targetText = file.effectiveContent;
          language = FileDisplayHelper.getLanguageFromFile(file);
        }
      }

      final activeChanged = prevId != nextId;
      final contentChanged =
          nextId != null &&
          (previous == null ||
              (previous.activeFileId == nextId &&
                  (previous.fileMap[nextId]?.effectiveContent ?? '') !=
                      targetText));

      if (!isViewingAll && (activeChanged || contentChanged)) {
        _debounceTimer?.cancel();
        _debounceTimer = Timer(const Duration(milliseconds: 80), () async {
          if (!mounted) return;
          await editorService.updateContent(targetText, language: language);
        });
      }
    });
  }

  Future<void> _initializeSplitter() async {
    final prefs = await SharedPreferences.getInstance();
    final savedRatio = prefs.getDouble(_splitRatioKey) ?? 0.35;
    if (mounted) {
      setState(() {
        _splitterController = SplitterController(initialRatio: savedRatio);
        _isSplitterInitialized = true;
      });
    }
  }

  @override
  void dispose() {
    _splitterController?.dispose();
    _debounceTimer?.cancel();
    _editorStatusSub?.close();
    _selectionSub?.close();
    super.dispose();
  }

  Future<void> _saveSplitRatio(double ratio) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_splitRatioKey, ratio);
  }

  Future<void> _loadEditorSettings() async {
    final options = await EditorSettingsService.load();
    if (mounted) {
      setState(() {
        _editorOptions = options;
      });
    }
  }

  Future<void> _applySettingsToEditor() async {
    final editorService = ref.read(monacoEditorStatusProvider.notifier);
    await editorService.updateOptions(_editorOptions);
  }

  Future<void> _saveAndApplyOptions(EditorOptions newOptions) async {
    setState(() {
      _editorOptions = newOptions;
    });
    await EditorSettingsService.save(newOptions);
    await _applySettingsToEditor();
    // Sync app ThemeMode to Monaco theme selection
    await ref.read(themeProvider.notifier).setThemeFromMonaco(newOptions.theme);
  }

  // Removed quick toggles; font size and word wrap can be adjusted via Settings dialog

  Future<void> _showEnhancedEditorSettings(BuildContext context) async {
    final newOptions = await EditorSettingsDialog.show(
      context,
      _editorOptions,
    );
    if (newOptions != null && mounted) {
      await _saveAndApplyOptions(newOptions);
    }
  }

  /// Copy full paths of selected files to clipboard
  Future<void> _copyFullPathsToClipboard() async {
    try {
      await ref.read(selectionProvider.notifier).copyFullPathsToClipboard();
      if (mounted) {
        context.showOk('Full paths copied to clipboard!');
      }
    } catch (e) {
      if (mounted) {
        context.showErr('Error copying paths: $e');
      }
    }
  }

  /// Copy AI-formatted paths of selected files to clipboard
  Future<void> _copyAiPathsToClipboard() async {
    try {
      await ref.read(selectionProvider.notifier).copyAiPathsToClipboard();
      if (mounted) {
        context.showOk('AI paths copied to clipboard!');
      }
    } catch (e) {
      if (mounted) {
        context.showErr('Error copying AI paths: $e');
      }
    }
  }

  /// Copy the editor's current content
  Future<void> _copyEditorContentToClipboard() async {
    // Flush Monaco → state for the active file so combined content has the latest edits
    final controller = ref.read(monacoControllerProvider);
    final activeId = ref.read(selectionProvider).activeFileId;
    final viewingAll = ref.read(selectionProvider).viewingAll;
    if (!viewingAll && controller != null && activeId != null) {
      try {
        final text = await controller.getValue();
        ref.read(selectionProvider.notifier).saveEditorTextFor(activeId, text);
      } catch (e) {
        debugPrint('[EditorScreen] Failed to get live content: $e');
      }
    }

    final content = ref.read(selectionProvider).combinedContent;
    if (content.isEmpty) {
      if (mounted) {
        context.showInfo('Nothing to copy.');
      }
      return;
    }

    try {
      await Clipboard.setData(ClipboardData(text: content));
      if (mounted) {
        context.showOk('Combined context copied to clipboard!');
      }
    } catch (e) {
      if (mounted) {
        context.showErr('Error copying to clipboard: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectionState = ref.watch(selectionProvider);
    final selectionNotifier = ref.read(selectionProvider.notifier);
    final editorStatus = ref.watch(monacoEditorStatusProvider);

    // (Listeners are wired once in initState)

    return Scaffold(
      backgroundColor: context.surface,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        toolbarHeight: 40,
        titleSpacing: 6,
        scrolledUnderElevation: 0,
        shadowColor: Colors.transparent,
        // backgroundColor: context.surface,
        centerTitle: false,
        elevation: 0,
        // LEFT group — compact icon-only actions
        leadingWidth: 260,
        leading: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            const SizedBox(width: 8),
            _tb(Icons.refresh_rounded, 'Reload from disk', () {
              ref.read(selectionProvider.notifier).refreshAllContents();
            }),
            _tb(Icons.note_add_outlined, 'New virtual file', () async {
              final name = await promptForNewFileName(
                context,
                initialName: 'pasted.txt',
              );
              if (name != null && name.trim().isNotEmpty) {
                ref
                    .read(selectionProvider.notifier)
                    .createVirtualFile(name.trim(), '');
              }
            }),
            _tb(Icons.file_open_rounded, 'Add files…', () {
              ref.read(selectionProvider.notifier).pickFiles(context);
            }),
            _tb(Icons.folder_open_rounded, 'Add folder…', () {
              ref.read(selectionProvider.notifier).pickDirectory(context);
            }),
            _pasteIconButton(context),
            _tb(
              Icons.save_alt_rounded,
              'Save Markdown',
              selectionState.hasSelectedFiles
                  ? () async {
                      final controller = ref.read(monacoControllerProvider);
                      final activeId = ref.read(selectionProvider).activeFileId;
                      final viewingAll = ref.read(selectionProvider).viewingAll;
                      if (!viewingAll &&
                          controller != null &&
                          activeId != null) {
                        try {
                          final text = await controller.getValue();
                          ref
                              .read(selectionProvider.notifier)
                              .saveEditorTextFor(activeId, text);
                        } catch (_) {}
                      }
                      await selectionNotifier.saveToFile();
                    }
                  : null,
            ),
          ],
        ),

        // RIGHT group — compact icon-only actions
        actions: [
          _tb(Icons.settings_outlined, 'Settings', () async {
            await _showEnhancedEditorSettings(context);
          }),
            _tb(
              Icons.view_agenda_rounded,
              ref.watch(selectionProvider).viewingAll ? 'Exit View All' : 'View All',
              _toggleViewAllInMonaco,
            ),
          _tb(
            Icons.clear_all_rounded,
            'Clear all',
            selectionState.hasFiles ? selectionNotifier.clearFiles : null,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: DropZone(
        child: Column(
          children: [
            // Main editor area with production ResizableSplitter
            Expanded(
              child: _isSplitterInitialized && _splitterController != null
                  ? ResizableSplitter(
                      controller: _splitterController,
                      minRatio: 0.2,
                      maxRatio: 0.6,
                      minPanelSize: 300,
                      onRatioChanged: _saveSplitRatio,
                      dividerThickness: 6,
                      enableKeyboard: false,
                      semanticsLabel:
                          'Editor panels splitter. Drag to resize or use arrow keys.',
                      startPanel: DecoratedBox(
                        decoration: BoxDecoration(
                          color: context.surfaceContainerHighest,
                          border: Border(
                            right: BorderSide(
                              color: Theme.of(context)
                                  .colorScheme
                                  .outlineVariant,
                            ),
                          ),
                        ),
                        child: Column(
                          children: [
                            const Expanded(child: FileListScreen()),
                            if (selectionState.isProcessing)
                              const LinearProgressIndicator(),
                          ],
                        ),
                      ),
                      endPanel: DecoratedBox(
                        decoration: BoxDecoration(
                          color: context.surface,
                        ),
                        child: const MonacoEditorIntegrated(),
                      ),
                    )
                  : Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(
                            color: context.primary,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Loading layout...',
                            style: context.textTheme.bodyMedium?.copyWith(
                              color: context.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
            ),

            // Bottom info bar
            if (editorStatus.isReady)
              MonacoEditorInfoBar(
                onCopy: _copyEditorContentToClipboard,
                onCopyFullPaths: _copyFullPathsToClipboard,
                onCopyAiPaths: _copyAiPathsToClipboard,
              ),
          ],
        ),
      ),
    );
  }
}

/// Sidebar removed; Editor uses full panel

// === Helper methods for compact toolbar and smart paste ===
extension _ToolbarHelpers on _EditorScreenState {
  // Uniform compact icon buttons
  Widget _tb(IconData icon, String tip, VoidCallback? onPressed) {
    return IconButton(
      icon: Icon(icon, size: 18),
      tooltip: tip,
      onPressed: onPressed,
      padding: const EdgeInsets.all(6),
      constraints: const BoxConstraints.tightFor(width: 32, height: 32),
      splashRadius: 18,
    );
  }

  // Paste icon with left-click = paste paths, right-click = paste as content
  Widget _pasteIconButton(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.opaque,
      onPointerDown: (event) async {
        if (event.kind == PointerDeviceKind.mouse &&
            (event.buttons & kSecondaryMouseButton) != 0) {
          await _pasteClipboardAsContent();
        }
      },
      child: _tb(
        Icons.content_paste_go_rounded,
        'Paste (left: paths • right: content)',
        () => ref
            .read(selectionProvider.notifier)
            .pastePathsFromClipboard(context),
      ),
    );
  }

  // Paste clipboard as content into a new virtual file
  Future<void> _pasteClipboardAsContent() async {
    try {
      final data = await Clipboard.getData(Clipboard.kTextPlain);
      final text = (data?.text ?? '').trim();
      if (text.isEmpty) {
        if (mounted) context.showInfo('Clipboard is empty.');
        return;
      }
      final name = await promptForNewFileName(
        context,
        initialName: 'pasted.txt',
      );
      if (name == null || name.trim().isEmpty) return;
      final trimmedName = name.trim();
      ref.read(selectionProvider.notifier).createVirtualFile(trimmedName, text);
      // Write-through so state also holds the live text for this new file.
      final newId = ref.read(selectionProvider).activeFileId;
      if (newId != null) {
        ref.read(selectionProvider.notifier).saveEditorTextFor(newId, text);
      }
      if (mounted) context.showOk('Created "$trimmedName" from clipboard text.');
    } catch (e) {
      if (mounted) context.showErr('Paste failed: $e');
    }
  }

  
  // Legacy inline prompt removed; using shared promptForNewFileName()

  // View All: show combined markdown of selected files in Monaco (non-destructive)
  Future<void> _viewAllInMonaco() async {
    // Enter combined view mode state
    ref.read(selectionProvider.notifier).setViewingAll(true);
    final status = ref.read(monacoEditorStatusProvider);
    if (!status.isReady) {
      if (mounted) context.showInfo('Editor is still loading…');
      return;
    }

    // Flush Monaco → state so combined content is accurate
    final controller = ref.read(monacoControllerProvider);
    final activeId = ref.read(selectionProvider).activeFileId;
    if (controller != null && activeId != null) {
      try {
        final live = await controller.getValue();
        ref.read(selectionProvider.notifier).saveEditorTextFor(activeId, live);
      } catch (_) {}
    }

    final combined = ref.read(selectionProvider).combinedContent;
    await ref
        .read(monacoEditorStatusProvider.notifier)
        .updateContent(
          combined.isEmpty ? '# (Nothing selected)' : combined,
          language: 'markdown',
        );

    // Combined view mode is tracked in SelectionState.viewingAll
  }

  // Toggle View All mode. If currently viewing all, exit back to active file.
  Future<void> _toggleViewAllInMonaco() async {
    if (_viewAllToggleBusy) return;
    _viewAllToggleBusy = true;
    try {
      final viewingAll = ref.read(selectionProvider).viewingAll;
      if (!viewingAll) {
        // Enter combined view (do all work here)
        await _viewAllInMonaco();
      } else {
        // Exit combined view: clear flag and immediately push active file content.
        ref.read(selectionProvider.notifier).setViewingAll(false);
        final next = ref.read(selectionProvider);
        String text = '';
        String? language;
        final id = next.activeFileId;
        if (id != null) {
          final file = next.fileMap[id];
          if (file != null) {
            text = file.effectiveContent;
            language = FileDisplayHelper.getLanguageFromFile(file);
          }
        }
        await ref
            .read(monacoEditorStatusProvider.notifier)
            .updateContent(text, language: language);
      }
    } finally {
      _viewAllToggleBusy = false;
    }
  }
}
