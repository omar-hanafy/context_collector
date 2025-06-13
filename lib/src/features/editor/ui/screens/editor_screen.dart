import 'package:context_collector/context_collector.dart';
import 'package:context_collector/src/shared/widgets/shared_drop_zone.dart';
import 'package:enefty_icons/enefty_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_helper_utils/flutter_helper_utils.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Refactored editor screen with production-ready ResizableSplitter(startPanel: startPanel, endPanel: endPanel)
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
  EditorSettings _editorSettings = const EditorSettings();
  bool _hasAppliedInitialSettings = false;

  // Sidebar dimensions
  static const double _expandedSidebarWidth = DsDimensions.sidebarWidth;

  // Splitter controller - now using the new SplitterController
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
    final settings = await EditorSettingsServiceHelper.load();
    if (mounted) {
      setState(() {
        _editorSettings = settings;
      });
    }
  }

  Future<void> _applySettingsToEditor() async {
    final editorService = ref.read(monacoEditorServiceProvider);
    await editorService.updateSettings(_editorSettings);
  }

  Future<void> _saveAndApplySettings(EditorSettings newSettings) async {
    setState(() {
      _editorSettings = newSettings;
    });
    await EditorSettingsServiceHelper.save(newSettings);
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
    if (_editorSettings.fontSize < EditorConstants.maxFontSize) {
      final newSettings = _editorSettings.copyWith(
        fontSize: _editorSettings.fontSize + 1,
      );
      await _saveAndApplySettings(newSettings);
    }
  }

  Future<void> _decreaseFontSize() async {
    if (_editorSettings.fontSize > EditorConstants.minFontSize) {
      final newSettings = _editorSettings.copyWith(
        fontSize: _editorSettings.fontSize - 1,
      );
      await _saveAndApplySettings(newSettings);
    }
  }

  Future<void> _toggleWordWrap() async {
    final newWrap = _editorSettings.wordWrap == WordWrap.off
        ? WordWrap.on
        : WordWrap.off;
    final newSettings = _editorSettings.copyWith(wordWrap: newWrap);
    await _saveAndApplySettings(newSettings);
  }

  Future<void> _showEnhancedEditorSettings(BuildContext context) async {
    final newSettings = await EditorSettingsDialog.show(
      context,
      _editorSettings,
      customThemes: [],
      customKeybindingPresets: [],
    );
    if (newSettings != null && mounted) {
      await _saveAndApplySettings(newSettings);
    }
  }

  void _copyToClipboard(BuildContext context, String content) {
    Clipboard.setData(ClipboardData(text: content))
        .then((_) => context.showOk('Content copied to clipboard!'))
        .catchError(
          (dynamic error) =>
              context.showErr('Error copying to clipboard: $error'),
        );
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

    return Scaffold(
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
                onSelected: (value) {
                  if (value == 'files') {
                    selectionNotifier.pickFiles(context);
                  } else if (value == 'folder') {
                    selectionNotifier.pickDirectory(context);
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

              // Save action
              FilledButton.icon(
                icon: const Icon(Icons.save_alt_rounded, size: 18),
                label: const Text('Save'),
                onPressed: selectionState.hasSelectedFiles
                    ? selectionNotifier.saveToFile
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
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    context.primary,
                    context.primary.addOpacity(0.8),
                  ],
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.collections_bookmark_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            const Text('Context Collector'),
          ],
        ),
        centerTitle: true,

        actions: [
          // Right side - App-level actions
          IconButton(
            icon: Icon(
              Icons.clear_all_rounded,
              size: 20,
              color: selectionState.hasFiles
                  ? context.error.withOpacity(0.8)
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
              );
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
                      controller: _splitterController!,
                      minRatio: 0.2,
                      maxRatio: 0.6,
                      minPanelSize: 300,
                      onRatioChanged: _saveSplitRatio,
                      dividerThickness: 12,
                      enableKeyboard: true,
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
                          // Monaco Editor
                          const MonacoEditorContainer(
                            key: Key('editor-screen-monaco'),
                          ),

                          // Animated Sidebar (INSIDE Monaco editor area)
                          AnimatedBuilder(
                            animation: _sidebarAnimation,
                            builder: (context, child) {
                              final width =
                                  _expandedSidebarWidth *
                                  _sidebarAnimation.value;

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
                                              color: context
                                                  .surfaceContainerHighest,
                                              border: BorderDirectional(
                                                end: BorderSide(
                                                  color: context.outline
                                                      .addOpacity(
                                                        0.2,
                                                      ),
                                                ),
                                              ),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: context.shadow
                                                      .addOpacity(
                                                        0.05,
                                                      ),
                                                  offset: const Offset(2, 0),
                                                  blurRadius: 4,
                                                ),
                                              ],
                                            ),
                                            child: QuickSidebar(
                                              settings: _editorSettings,
                                              selectionState: selectionState,
                                              onSettingsChanged:
                                                  _saveAndApplySettings,
                                              onWordWrapToggle: _toggleWordWrap,
                                              onIncreaseFontSize:
                                                  _increaseFontSize,
                                              onDecreaseFontSize:
                                                  _decreaseFontSize,
                                              onShowAllSettings: () =>
                                                  _showEnhancedEditorSettings(
                                                    context,
                                                  ),
                                              onCopyContent: () =>
                                                  _copyToClipboard(
                                                    context,
                                                    selectionState
                                                        .combinedContent,
                                                  ),
                                            ),
                                          ),
                                        )
                                      : null,
                                ),
                              );
                            },
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
                bridge: ref.read(monacoEditorServiceProvider).bridge,
                onCopy: () =>
                    _copyToClipboard(context, selectionState.combinedContent),
              ),
          ],
        ),
      ),
    );
  }
}
