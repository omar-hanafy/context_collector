import 'package:context_collector/context_collector.dart';
import 'package:enefty_icons/enefty_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Refactored editor screen with extracted quick sidebar
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
  static const double _expandedSidebarWidth = 280;

  @override
  void initState() {
    super.initState();

    // Initialize animations
    _sidebarAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _sidebarAnimation = CurvedAnimation(
      parent: _sidebarAnimationController,
      curve: Curves.easeInOutCubic,
    );

    // Load saved editor settings
    _loadEditorSettings();
  }

  @override
  void dispose() {
    _sidebarAnimationController.dispose();
    super.dispose();
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
        .then((_) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Icon(
                    Icons.check_circle,
                    color: context.onPrimary,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  const Text('Content copied to clipboard!'),
                ],
              ),
              backgroundColor: context.primary,
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 2),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          );
        })
        .catchError((dynamic error) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error copying to clipboard: $error'),
              backgroundColor: context.error,
            ),
          );
        });
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
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedScale(
                scale: selectionState.hasFiles ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 200),
                child: IconButton(
                  onPressed: selectionState.hasFiles
                      ? selectionNotifier.clearFiles
                      : null,
                  icon: const Icon(Icons.clear_all_rounded),
                  tooltip: 'Clear all files',
                  style: IconButton.styleFrom(
                    backgroundColor: context.error.addOpacity(0.1),
                    foregroundColor: context.error,
                  ),
                  splashRadius: 0.1,
                  highlightColor: Colors.transparent,
                  splashColor: Colors.transparent,
                  hoverColor: context.error.addOpacity(0.05),
                ),
              ),
              const SizedBox(width: 8),
            ],
          ),
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute<void>(
                  builder: (context) => const SettingsScreen(),
                ),
              );
            },
            icon: const Icon(Icons.settings_rounded),
            tooltip: 'Settings',
            splashRadius: 0.1,
            highlightColor: Colors.transparent,
            splashColor: Colors.transparent,
            hoverColor: context.onSurface.addOpacity(0.04),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: DropZone(
        child: Column(
          children: [
            // Main editor area
            Expanded(
              child: ResizableSplitter(
                initialRatio: 0.35,
                maxRatio: 0.6,
                startPanel: Column(
                  children: [
                    const ActionButtonsWidget(),
                    const Expanded(child: FileListWidget()),
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
                            _expandedSidebarWidth * _sidebarAnimation.value;

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
                                            color: context.outline.addOpacity(
                                              0.2,
                                            ),
                                          ),
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: context.shadow.addOpacity(
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
                                        onIncreaseFontSize: _increaseFontSize,
                                        onDecreaseFontSize: _decreaseFontSize,
                                        onShowAllSettings: () =>
                                            _showEnhancedEditorSettings(
                                              context,
                                            ),
                                        onCopyContent: () => _copyToClipboard(
                                          context,
                                          selectionState.combinedContent,
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
                      left: _isSidebarExpanded ? _expandedSidebarWidth - 20 : 8,
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
                              hoverColor: context.onSurface.addOpacity(0.04),
                              child: Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: context.outline.addOpacity(0.2),
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
