import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_monaco/flutter_monaco.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:resizable_splitter/resizable_splitter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:window_manager/window_manager.dart';

import '../../../../app/route_observers.dart';
import '../../../../context_collector.dart';
import '../../../../shared/dialogs/name_prompt.dart';
import '../../../scan/ui/file_display_helper.dart';
import '../../data/workspace_completion_provider.dart';
import '../widgets/editor_top_bar.dart';
import '../widgets/info_bar/copy_feedback.dart';
// Route focus restorer not needed with push/pop lifecycle.

/// Refactored editor screen using flutter_monaco package
class EditorScreen extends ConsumerStatefulWidget {
  const EditorScreen({super.key});

  @override
  ConsumerState<EditorScreen> createState() => _EditorScreenState();
}

class _EditorScreenState extends ConsumerState<EditorScreen>
    with
        SingleTickerProviderStateMixin,
        WindowListener,
        WidgetsBindingObserver,
        RouteAware {
  RouteObserver<PageRoute<dynamic>>? _routeObserver;
  PageRoute<dynamic>? _subscribedRoute;
  Timer? _debounceTimer;
  bool _viewAllToggleBusy = false;

  // Track if a rename dialog is active to avoid stacking.
  bool _renameDialogOpen = false;

  // Settings state
  EditorOptions _editorOptions = const EditorOptions();
  bool _hasAppliedInitialSettings = false;
  bool _requestedInitialFocus = false;

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
    windowManager.addListener(this);
    WidgetsBinding.instance.addObserver(this);

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
        await _applyActiveSelectionToEditor(
          ref.read(selectionProvider),
          ref.read(monacoEditorStatusProvider.notifier),
        );
        unawaited(_recoverEditorFocus());
      }
    });
  }

  void _wireRiverpodListeners() {
    // Listen for editor ready state to apply initial settings and push initial content
    _editorStatusSub = ref.listenManual<EditorStatus>(
      monacoEditorStatusProvider,
      (previous, next) async {
        if (!mounted) return;
        if (!_hasAppliedInitialSettings && next.isReady) {
          _hasAppliedInitialSettings = true;

          await _applyActiveSelectionToEditor(
            ref.read(selectionProvider),
            ref.read(monacoEditorStatusProvider.notifier),
          );
          unawaited(_recoverEditorFocus());
        }
      },
    );

    // Keep Monaco’s content in sync with the active file and edits
    _selectionSub = ref.listenManual<SelectionState>(selectionProvider, (
      previous,
      next,
    ) async {
      if (!mounted) return;
      final editorService = ref.read(monacoEditorStatusProvider.notifier);
      final controller = ref.read(monacoControllerProvider);

      if (!_renameDialogOpen &&
          next.pendingRenameFileId != null &&
          next.pendingRenameFileId != previous?.pendingRenameFileId) {
        _renameDialogOpen = true;
        WidgetsBinding.instance.addPostFrameCallback((_) async {
          if (!mounted) return;
          final fileId = ref.read(selectionProvider).pendingRenameFileId!;
          final fileName =
              ref.read(selectionProvider).fileMap[fileId]?.name ?? 'pasted.txt';
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
          // After rename dialog closes, recover focus.
          if (mounted) {
            unawaited(
              _recoverEditorFocus(intent: MonacoFocusIntent.user),
            );
          }
        });
      }

      final prevId = previous?.activeFileId;
      final nextId = next.activeFileId;

      final wasViewingAll = previous?.viewingAll ?? false;
      final isViewingAll = next.viewingAll;
      final combinedChanged = previous?.combinedContent != next.combinedContent;

      if ((previous != null && wasViewingAll) && !isViewingAll) {
        // Cancel stale writes queued while in view-all so they don't override file view.
        _debounceTimer?.cancel();
        await _applyActiveSelectionToEditor(next, editorService);
        return;
      }

      if (isViewingAll) {
        // Drop pending file writes now that combined view is active.
        _debounceTimer?.cancel();
        if (!wasViewingAll || combinedChanged) {
          final content = next.combinedContent;
          await editorService.updateContent(
            content.isEmpty ? '# (Nothing selected)' : content,
            language: 'markdown',
          );
        }
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

      String? targetText;
      String? language;
      if (nextId != null) {
        final file = next.fileMap[nextId];
        if (file != null) {
          targetText = file.editorContent;
          language = FileDisplayHelper.getLanguageFromFile(file);
        }
      }

      final activeChanged = prevId != nextId;
      final contentChanged =
          nextId != null &&
          (previous == null ||
              (previous.activeFileId == nextId &&
                  previous.fileMap[nextId]?.editorContent != targetText));

      if (!isViewingAll && (activeChanged || contentChanged)) {
        _debounceTimer?.cancel();
        if (nextId != null && targetText == null) {
          ref.read(selectionProvider.notifier).clearEditorContentBinding();
          return;
        }
        // Capture the file we intend to update so we can drop stale writes.
        final scheduledActiveId = nextId;
        final scheduledText = targetText ?? '';
        final scheduledLanguage = language;
        _debounceTimer = Timer(const Duration(milliseconds: 80), () async {
          if (!mounted) return;
          final s = ref.read(selectionProvider);
          if (s.viewingAll) return;
          if (scheduledActiveId != null &&
              s.activeFileId != scheduledActiveId) {
            return;
          }
          await editorService.updateContent(
            scheduledText,
            language: scheduledLanguage,
          );
          if (!mounted) return;
          final latest = ref.read(selectionProvider);
          if (scheduledActiveId != null &&
              !latest.viewingAll &&
              latest.activeFileId == scheduledActiveId &&
              latest.fileMap[scheduledActiveId]?.editorContent != null) {
            ref
                .read(selectionProvider.notifier)
                .markEditorContentBoundToFile(scheduledActiveId);
          } else {
            ref.read(selectionProvider.notifier).clearEditorContentBinding();
          }
        });
      }
    });
  }

  Future<void> _applyActiveSelectionToEditor(
    SelectionState selection,
    MonacoService editorService,
  ) async {
    final notifier = ref.read(selectionProvider.notifier);
    final activeId = selection.activeFileId;
    if (activeId == null) {
      notifier.clearEditorContentBinding();
      await editorService.updateContent('');
      return;
    }

    final file = selection.fileMap[activeId];
    final text = file?.editorContent;
    if (file == null || text == null) {
      notifier.clearEditorContentBinding();
      return;
    }

    await editorService.updateContent(
      text,
      language: FileDisplayHelper.getLanguageFromFile(file),
    );
    if (!mounted) return;

    final latest = ref.read(selectionProvider);
    if (!latest.viewingAll &&
        latest.activeFileId == activeId &&
        latest.fileMap[activeId]?.editorContent != null) {
      notifier.markEditorContentBoundToFile(activeId);
    }
  }

  Future<void> _flushBoundActiveEditorText() async {
    final selection = ref.read(selectionProvider);
    if (selection.viewingAll || !selection.editorIsBoundToActiveFile) {
      return;
    }
    final controller = ref.read(monacoControllerProvider);
    final activeId = selection.activeFileId;
    if (controller == null || activeId == null) return;
    try {
      final text = await controller.getValue();
      ref.read(selectionProvider.notifier).saveEditorTextFor(activeId, text);
    } catch (e) {
      debugPrint('[EditorScreen] Failed to get live content: $e');
    }
  }

  Future<void> _initializeSplitter() async {
    final prefs = await SharedPreferences.getInstance();
    final savedRatio = prefs.getDouble(_splitRatioKey) ?? 0.35;
    if (mounted) {
      setState(() {
        _splitterController = SplitterController(
          initialPosition: SplitterPosition.fraction(savedRatio),
        );
        _isSplitterInitialized = true;
      });
    }
  }

  @override
  void dispose() {
    windowManager.removeListener(this);
    WidgetsBinding.instance.removeObserver(this);
    if (_subscribedRoute != null) {
      _routeObserver?.unsubscribe(this);
      _subscribedRoute = null;
    }
    _routeObserver = null;
    _splitterController?.dispose();
    _debounceTimer?.cancel();
    _editorStatusSub?.close();
    _selectionSub?.close();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final observer = ref.read(routeObserverProvider);
    final route = ModalRoute.of(context);

    if (!identical(observer, _routeObserver)) {
      if (_subscribedRoute != null) {
        _routeObserver?.unsubscribe(this);
        _subscribedRoute = null;
      }
      _routeObserver = observer;
    }

    if (route is PageRoute<dynamic>) {
      if (!identical(_subscribedRoute, route)) {
        if (_subscribedRoute != null) {
          _routeObserver?.unsubscribe(this);
        }
        _routeObserver?.subscribe(this, route);
        _subscribedRoute = route;
      }
    } else if (_subscribedRoute != null) {
      _routeObserver?.unsubscribe(this);
      _subscribedRoute = null;
    }
  }

  // WindowListener: regain focus when window is focused
  @override
  void onWindowFocus() {
    unawaited(_recoverEditorFocusAfterNativeFocusBoundary());
  }

  @override
  void onWindowBlur() {
    _invalidateEditorInputReadinessAfterNativeFocusBoundary();
  }

  // WidgetsBindingObserver: regain focus when app resumes
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(_recoverEditorFocusAfterNativeFocusBoundary());
    } else {
      _invalidateEditorInputReadinessAfterNativeFocusBoundary();
    }
  }

  @override
  void didPushNext() {
    _invalidateEditorInputReadinessAfterNativeFocusBoundary();
  }

  // RouteAware: called when a route above this one has been popped (e.g., a dialog closed)
  @override
  void didPopNext() {
    // Defer to next frame to allow focus to settle after dialog teardown.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(_recoverEditorFocusAfterNativeFocusBoundary());
    });
  }

  Future<void> _recoverEditorFocus({
    MonacoFocusIntent intent = MonacoFocusIntent.maintenance,
  }) async {
    final svc = ref.read(monacoEditorStatusProvider.notifier);
    await svc.recoverKeyboardFocus(intent: intent);
  }

  void _invalidateEditorInputReadinessAfterNativeFocusBoundary() {
    ref
        .read(monacoEditorStatusProvider.notifier)
        .invalidateInputReadinessAfterNativeFocusBoundary();
  }

  Future<void> _recoverEditorFocusAfterNativeFocusBoundary() async {
    final svc = ref.read(monacoEditorStatusProvider.notifier);
    await svc.recoverKeyboardFocusAfterNativeFocusBoundary();
  }

  Future<void> _saveSplitRatio(double ratio) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_splitRatioKey, ratio);
  }

  void _handleSplitRatioChanged(SplitterChangeDetails details) {
    // Persist ratio and nudge Monaco to recompute layout during resize.
    unawaited(_saveSplitRatio(details.effectiveFraction));
    unawaited(
      ref.read(monacoEditorStatusProvider.notifier).layout(),
    );
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
      // Strong recovery after dialog containing TextFields
      unawaited(_recoverEditorFocus(intent: MonacoFocusIntent.user));
    }
  }

  /// Copy full paths of selected files to clipboard
  Future<CopyFeedback> _copyFullPathsToClipboard() async {
    try {
      await ref.read(selectionProvider.notifier).copyFullPathsToClipboard();
      return CopyFeedback.success;
    } catch (e) {
      debugPrint('[EditorScreen] Error copying full paths: $e');
      return CopyFeedback.error;
    }
  }

  /// Copy AI-formatted paths of selected files to clipboard
  Future<CopyFeedback> _copyAiPathsToClipboard() async {
    try {
      await ref.read(selectionProvider.notifier).copyAiPathsToClipboard();
      return CopyFeedback.success;
    } catch (e) {
      debugPrint('[EditorScreen] Error copying AI paths: $e');
      return CopyFeedback.error;
    }
  }

  /// Copy the editor's current content
  Future<CopyFeedback> _copyEditorContentToClipboard() async {
    await _flushBoundActiveEditorText();

    try {
      final content = await ref
          .read(selectionProvider.notifier)
          .buildSelectedContextContent();
      if (content.trim().isEmpty) {
        return CopyFeedback.empty;
      }

      await Clipboard.setData(ClipboardData(text: content));
      return CopyFeedback.success;
    } catch (e) {
      debugPrint('[EditorScreen] Error copying editor content: $e');
      return CopyFeedback.error;
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectionState = ref.watch(selectionProvider);
    final selectionNotifier = ref.read(selectionProvider.notifier);
    final editorStatus = ref.watch(monacoEditorStatusProvider);
    ref.watch(workspaceCompletionProvider);
    // On first frame after entering the editor route, ensure editor focus.
    if (!_requestedInitialFocus && editorStatus.isReady) {
      _requestedInitialFocus = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        unawaited(_recoverEditorFocus());
      });
    }

    // (Listeners are wired once in initState)

    return Scaffold(
      backgroundColor: context.surface,
      body: Column(
        children: [
          SafeArea(
            bottom: false,
            child: EditorTopBar(
              hasFiles: selectionState.hasFiles,
              hasSelectedFiles: selectionState.hasSelectedFiles,
              isViewingAll: selectionState.viewingAll,
              onClearFiles: selectionState.hasFiles
                  ? selectionNotifier.clearFiles
                  : null,
              onReload: _handleRefreshAllContents,
              onCreateNewFile: _handleCreateNewFile,
              onPasteClipboardContent: _pasteClipboardAsContent,
              onPastePaths: _handlePastePaths,
              onAddFiles: _handleAddFiles,
              onAddFolder: _handleAddFolder,
              onSave: selectionState.hasSelectedFiles
                  ? _handleSaveSelection
                  : null,
              onOpenSettings: _handleOpenSettings,
              onToggleViewAll: _toggleViewAllInMonaco,
            ),
          ),
          // Main editor area with production ResizableSplitter
          Expanded(
            child: _isSplitterInitialized && _splitterController != null
                ? ResizableSplitter(
                    controller: _splitterController,
                    minStartFraction: 0.2,
                    maxStartFraction: 0.6,
                    startConstraints: const SplitterPaneConstraints(
                      minExtent: 300,
                    ),
                    endConstraints: const SplitterPaneConstraints(
                      minExtent: 300,
                    ),
                    onChanged: _handleSplitRatioChanged,
                    divider: const SplitterDividerStyle(thickness: 6),
                    enableKeyboard: false,
                    semanticsLabel:
                        'Editor panels splitter. Drag to resize or use arrow keys.',
                    start: DecoratedBox(
                      decoration: BoxDecoration(
                        color: context.surfaceContainerHighest,
                        border: Border(
                          right: BorderSide(
                            color: Theme.of(
                              context,
                            ).colorScheme.outlineVariant,
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
                    end: DecoratedBox(
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
    );
  }

  // Sidebar removed; Editor uses full panel

  void _handleRefreshAllContents() {
    unawaited(ref.read(selectionProvider.notifier).refreshAllContents());
  }

  Future<void> _handleCreateNewFile(BuildContext context) async {
    final name = await promptForNewFileName(
      context,
      initialName: 'pasted.txt',
    );
    if (name != null && name.trim().isNotEmpty) {
      ref.read(selectionProvider.notifier).createVirtualFile(name.trim(), '');
    }
    unawaited(_recoverEditorFocus(intent: MonacoFocusIntent.user));
  }

  Future<void> _handlePastePaths(BuildContext context) async {
    await ref.read(selectionProvider.notifier).pastePathsFromClipboard(context);
    unawaited(_recoverEditorFocus());
  }

  Future<void> _handleAddFiles(BuildContext context) async {
    await ref.read(selectionProvider.notifier).pickFiles(context);
  }

  Future<void> _handleAddFolder(BuildContext context) async {
    await ref.read(selectionProvider.notifier).pickDirectory(context);
  }

  Future<void> _handleSaveSelection() async {
    await _flushBoundActiveEditorText();
    await ref.read(selectionProvider.notifier).saveToFile();
  }

  Future<void> _handleOpenSettings(BuildContext context) async {
    await _showEnhancedEditorSettings(context);
    unawaited(_recoverEditorFocus(intent: MonacoFocusIntent.user));
  }

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
      if (mounted) {
        context.showOk('Created "$trimmedName" from clipboard text.');
      }
    } catch (e) {
      if (mounted) context.showErr('Paste failed: $e');
    } finally {
      // Always recover after this flow, even if canceled or errored.
      unawaited(_recoverEditorFocus(intent: MonacoFocusIntent.user));
    }
  }

  Future<void> _viewAllInMonaco() async {
    // Kill any pending file write so combined view stays visible.
    _debounceTimer?.cancel();
    // Flush current editor text BEFORE entering view-all mode
    await _flushBoundActiveEditorText();

    final status = ref.read(monacoEditorStatusProvider);
    if (!status.isReady) {
      if (mounted) context.showInfo('Editor is still loading…');
      return;
    }

    // Now enter combined view mode state
    ref.read(selectionProvider.notifier).setViewingAll(true);
    ref.read(selectionProvider.notifier).clearEditorContentBinding();

    final combined = ref.read(selectionProvider).combinedContent;
    await ref
        .read(monacoEditorStatusProvider.notifier)
        .updateContent(
          combined.isEmpty ? '# (Nothing selected)' : combined,
          language: 'markdown',
        );
    unawaited(_recoverEditorFocus());

    // Combined view mode is tracked in SelectionState.viewingAll
  }

  Future<void> _toggleViewAllInMonaco() async {
    if (_viewAllToggleBusy) return;
    _viewAllToggleBusy = true;
    try {
      // Cancel queued writes before toggling modes to avoid races.
      _debounceTimer?.cancel();
      final viewingAll = ref.read(selectionProvider).viewingAll;
      if (!viewingAll) {
        // Enter combined view (do all work here)
        await _viewAllInMonaco();
      } else {
        // Exit combined view: clear flag and immediately push active file content.
        ref.read(selectionProvider.notifier).setViewingAll(false);
        await _applyActiveSelectionToEditor(
          ref.read(selectionProvider),
          ref.read(monacoEditorStatusProvider.notifier),
        );
        unawaited(_recoverEditorFocus());
      }
    } finally {
      _viewAllToggleBusy = false;
    }
  }
}
