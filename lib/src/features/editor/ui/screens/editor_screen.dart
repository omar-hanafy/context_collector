import 'package:enefty_icons/enefty_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_helper_utils/flutter_helper_utils.dart';
import 'package:flutter_monaco/flutter_monaco.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../context_collector.dart';
import '../../../../shared/widgets/app_bar_title.dart';
import '../../../../shared/widgets/shared_drop_zone.dart';
import '../../../scan/ui/paste_paths_dialog.dart';
import '../route_focus_restorer.dart';

/// Refactored editor screen using flutter_monaco package
class EditorScreen extends ConsumerStatefulWidget {
  const EditorScreen({super.key});

  @override
  ConsumerState<EditorScreen> createState() => _EditorScreenState();
}

class _EditorScreenState extends ConsumerState<EditorScreen>
    with SingleTickerProviderStateMixin {
  // Animation controllers for sidebar
  late AnimationController _sidebarAnimationController;
  late Animation<double> _sidebarAnimation;
  bool _isSidebarExpanded = false;

  // Settings state
  EditorOptions _editorOptions = const EditorOptions();
  bool _hasAppliedInitialSettings = false;

  // Sidebar dimensions
  static const double _expandedSidebarWidth = DsDimensions.sidebarWidth;

  // Splitter controller
  SplitterController? _splitterController;
  bool _isSplitterInitialized = false;
  static const String _splitRatioKey = 'editor_split_ratio';

  @override
  void initState() {
    super.initState();

    // Initialize splitter controller with saved ratio
    _initializeSplitter();

    // Initialize animations
    _sidebarAnimationController = AnimationController(
      duration: DesignSystem.durationMedium,
      vsync: this,
    );
    _sidebarAnimation = CurvedAnimation(
      parent: _sidebarAnimationController,
      curve: Curves.easeInOutCubic,
    );

    // Load saved editor settings
    _loadEditorSettings();
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
    _sidebarAnimationController.dispose();
    _splitterController?.dispose();
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
  }

  void _toggleSidebar() {
    setState(() {
      _isSidebarExpanded = !_isSidebarExpanded;
      if (_isSidebarExpanded) {
        _sidebarAnimationController.forward();
      } else {
        _sidebarAnimationController.reverse();
      }
    });
  }

  Future<void> _increaseFontSize() async {
    final currentSize = _editorOptions.fontSize ?? 14;
    if (currentSize < MonacoConstants.maxFontSize) {
      final newOptions = _editorOptions.copyWith(
        fontSize: currentSize + 1,
      );
      await _saveAndApplyOptions(newOptions);
    }
  }

  Future<void> _decreaseFontSize() async {
    final currentSize = _editorOptions.fontSize ?? 14;
    if (currentSize > MonacoConstants.minFontSize) {
      final newOptions = _editorOptions.copyWith(
        fontSize: currentSize - 1,
      );
      await _saveAndApplyOptions(newOptions);
    }
  }

  Future<void> _toggleWordWrap() async {
    final newOptions = _editorOptions.copyWith(
      wordWrap: !_editorOptions.wordWrap,
    );
    await _saveAndApplyOptions(newOptions);
  }

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
    if (controller != null && activeId != null) {
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

    // Listen for editor ready state to apply initial settings
    ref.listen<EditorStatus>(monacoEditorStatusProvider, (previous, next) {
      if (!_hasAppliedInitialSettings && next.isReady) {
        _hasAppliedInitialSettings = true;
        _applySettingsToEditor();
      }
    });

    // When the active file changes, nudge focus back to Monaco
    ref.listen<SelectionState>(selectionProvider, (prev, next) {
      if (prev?.activeFileId != next.activeFileId && next.activeFileId != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          EditorFocusHelper.restoreFocus(ref);
        });
      }
    });

    return MonacoRouteFocusRestorer(
      child: Scaffold(
      backgroundColor: context.surface,
      appBar: AppBar(
        // Compact height for desktop
        toolbarHeight: 56,

        // Left side - Primary actions
        leading: Padding(
          padding: const EdgeInsets.only(left: 12),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Single Add button with dropdown
              PopupMenuButton<String>(
                tooltip: 'Add files or folder',
                position: PopupMenuPosition.under,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                onCanceled: () {
                  // Menu dismissed without selection – ensure editor regains focus
                  EditorFocusHelper.restoreFocus(ref);
                },
                onSelected: (value) async {
                  if (value == 'files') {
                    await selectionNotifier.pickFiles(context);
                    await EditorFocusHelper.restoreFocus(ref);
                  } else if (value == 'folder') {
                    await selectionNotifier.pickDirectory(context);
                    await EditorFocusHelper.restoreFocus(ref);
                  } else if (value == 'paste_paths') {
                    await PastePathsDialog.show(context);
                    await EditorFocusHelper.restoreFocus(ref);
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'files',
                    child: ListTile(
                      dense: true,
                      leading: Icon(Icons.insert_drive_file_outlined, size: 20),
                      title: Text('Add Files'),
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'folder',
                    child: ListTile(
                      dense: true,
                      leading: Icon(Icons.folder_outlined, size: 20),
                      title: Text('Add Folder'),
                    ),
                  ),
                  const PopupMenuDivider(),
                  const PopupMenuItem(
                    value: 'paste_paths',
                    child: ListTile(
                      dense: true,
                      leading: Icon(Icons.content_paste_go, size: 20),
                      title: Text('Paste Paths...'),
                    ),
                  ),
                ],
                child: FilledButton.tonalIcon(
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: const Text('Add'),
                  onPressed: null, // Button is just for display
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    visualDensity: VisualDensity.compact,
                  ),
                ),
              ),

              const SizedBox(width: 8),

              // Save action (saves combined markdown)
              FilledButton.icon(
                icon: const Icon(Icons.save_alt_rounded, size: 18),
                label: const Text('Save'),
                onPressed: selectionState.hasSelectedFiles
                    ? () async {
                        // Flush Monaco → state before saving combined content
                        final controller = ref.read(monacoControllerProvider);
                        final activeId =
                            ref.read(selectionProvider).activeFileId;
                        if (controller != null && activeId != null) {
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
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  visualDensity: VisualDensity.compact,
                ),
              ),
            ],
          ),
        ),
        leadingWidth: 280,

        // Centered title
        title: const AppBarTitle(),
        centerTitle: true,

        actions: [
          // Right side - App-level actions
          IconButton(
            icon: Icon(
              Icons.clear_all_rounded,
              size: 20,
              color: selectionState.hasFiles
                  ? context.error.addOpacity(0.8)
                  : null,
            ),
            onPressed: selectionState.hasFiles
                ? selectionNotifier.clearFiles
                : null,
            tooltip: 'Clear All Files',
          ),

          const SizedBox(width: 4),

          IconButton(
            icon: const Icon(Icons.settings_outlined, size: 20),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute<void>(
                  builder: (context) => const SettingsScreen(),
                ),
              ).then((_) => EditorFocusHelper.restoreFocus(ref));
            },
            tooltip: 'Settings',
          ),

          const SizedBox(width: 16),
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
                      dividerThickness: 12,
                      enableKeyboard: false,
                      semanticsLabel:
                          'Editor panels splitter. Drag to resize or use arrow keys.',
                      startPanel: Column(
                        children: [
                          const Expanded(child: FileListScreen()),
                          if (selectionState.isProcessing)
                            const LinearProgressIndicator(),
                        ],
                      ),
                      endPanel: Stack(
                        children: [
                          const MonacoEditorIntegrated(),
                          _EditorSidebar(
                            animation: _sidebarAnimation,
                            expandedWidth: _expandedSidebarWidth,
                            editorOptions: _editorOptions,
                            selectionState: selectionState,
                            onSaveAndApplyOptions: _saveAndApplyOptions,
                            onToggleWordWrap: _toggleWordWrap,
                            onIncreaseFontSize: _increaseFontSize,
                            onDecreaseFontSize: _decreaseFontSize,
                            onShowEnhancedEditorSettings: () =>
                                _showEnhancedEditorSettings(context),
                            onCopyEditorContent: _copyEditorContentToClipboard,
                          ),

                          // Floating Toggle Button (positioned in editor area)
                          Positioned(
                            left: _isSidebarExpanded
                                ? _expandedSidebarWidth - 20
                                : 8,
                            top: 16,
                            child: AnimatedBuilder(
                              animation: _sidebarAnimation,
                              builder: (context, child) {
                                return Material(
                                  color: _isSidebarExpanded
                                      ? context.surfaceContainerHighest
                                      : context.surface,
                                  elevation: 4,
                                  shape: const CircleBorder(),
                                  child: InkWell(
                                    onTap: _toggleSidebar,
                                    customBorder: const CircleBorder(),
                                    splashColor: Colors.transparent,
                                    highlightColor: Colors.transparent,
                                    hoverColor: context.onSurface.addOpacity(
                                      0.04,
                                    ),
                                    child: Container(
                                      width: 36,
                                      height: 36,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: context.outline.addOpacity(
                                            0.2,
                                          ),
                                        ),
                                      ),
                                      child: Icon(
                                        _isSidebarExpanded
                                            ? Icons.chevron_left
                                            : EneftyIcons.setting_3_outline,
                                        size: 20,
                                        color: context.onSurfaceVariant,
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),

                          // Keyboard hint (shows when editor is loading)
                          Positioned(
                            bottom: 8,
                            right: 8,
                            child: AnimatedOpacity(
                              opacity: editorStatus.isReady ? 0.0 : 1.0,
                              duration: DesignSystem.durationMedium,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: context.surface.addOpacity(0.9),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: context.outline.addOpacity(0.2),
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.keyboard_rounded,
                                      size: 14,
                                      color: context.onSurfaceVariant,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      'Tab to focus splitter • ←→ to resize',
                                      style: context.textTheme.bodySmall
                                          ?.copyWith(
                                            color: context.onSurfaceVariant,
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
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
    ),
    );
  }
}

/// Extracted sidebar widget to simplify the main build method.
class _EditorSidebar extends StatelessWidget {
  const _EditorSidebar({
    required this.animation,
    required this.expandedWidth,
    required this.editorOptions,
    required this.selectionState,
    required this.onSaveAndApplyOptions,
    required this.onToggleWordWrap,
    required this.onIncreaseFontSize,
    required this.onDecreaseFontSize,
    required this.onShowEnhancedEditorSettings,
    required this.onCopyEditorContent,
  });

  final Animation<double> animation;
  final double expandedWidth;
  final EditorOptions editorOptions;
  final SelectionState selectionState;
  final ValueChanged<EditorOptions> onSaveAndApplyOptions;
  final VoidCallback onToggleWordWrap;
  final VoidCallback onIncreaseFontSize;
  final VoidCallback onDecreaseFontSize;
  final VoidCallback onShowEnhancedEditorSettings;
  final VoidCallback onCopyEditorContent;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        final width = expandedWidth * animation.value;

        return Positioned(
          left: 0,
          top: 0,
          bottom: 0,
          child: SizedBox(
            width: width,
            child: width > 0
                ? ClipRect(
                    child: Container(
                      decoration: BoxDecoration(
                        color: context.surfaceContainerHighest,
                        border: BorderDirectional(
                          end: BorderSide(
                            color: context.outline.addOpacity(0.2),
                          ),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: context.shadow.addOpacity(0.05),
                            offset: const Offset(2, 0),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                      child: QuickSidebar(
                        options: editorOptions,
                        selectionState: selectionState,
                        onOptionsChanged: onSaveAndApplyOptions,
                        onWordWrapToggle: onToggleWordWrap,
                        onIncreaseFontSize: onIncreaseFontSize,
                        onDecreaseFontSize: onDecreaseFontSize,
                        onShowAllSettings: onShowEnhancedEditorSettings,
                        onCopyContent: onCopyEditorContent,
                      ),
                    ),
                  )
                : null,
          ),
        );
      },
    );
  }
}
