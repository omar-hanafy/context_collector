// lib/src/features/editor/presentation/ui/editor_screen.dart
import 'dart:io';

import 'package:desktop_drop/desktop_drop.dart';
import 'package:enefty_icons/enefty_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/shared.dart';
import '../../../scan/presentation/state/selection_notifier.dart';
import '../../../scan/presentation/ui/action_buttons_widget.dart';
import '../../../scan/presentation/ui/file_list_widget.dart';
import '../../../settings/presentation/ui/settings_screen.dart';
import '../../domain/editor_settings.dart';
import '../../services/monaco_editor_providers.dart';
import '../../services/monaco_editor_state.dart';
import 'enhanced_editor_settings_dialog.dart';
import 'monaco_editor_container.dart';
import 'monaco_editor_info_bar.dart';

/// Complete editor screen with file list and Monaco editor
/// This is the bottom layer in the layered architecture
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
  bool _isDragging = false;

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
    final settings = await EditorSettings.load();
    if (mounted) {
      setState(() {
        _editorSettings = settings;
      });
    }
  }

  Future<void> _applySettingsToEditor() async {
    final editorService = ref.read(monacoEditorServiceProvider);
    await editorService.applySettings(_editorSettings);
  }

  Future<void> _saveAndApplySettings(EditorSettings newSettings) async {
    setState(() {
      _editorSettings = newSettings;
    });
    await newSettings.save();
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
    if (_editorSettings.fontSize < 32) {
      final newSettings =
          _editorSettings.copyWith(fontSize: _editorSettings.fontSize + 1);
      await _saveAndApplySettings(newSettings);
    }
  }

  Future<void> _decreaseFontSize() async {
    if (_editorSettings.fontSize > 8) {
      final newSettings =
          _editorSettings.copyWith(fontSize: _editorSettings.fontSize - 1);
      await _saveAndApplySettings(newSettings);
    }
  }

  Future<void> _toggleWordWrap() async {
    final newWrap =
        _editorSettings.wordWrap == WordWrap.off ? WordWrap.on : WordWrap.off;
    final newSettings = _editorSettings.copyWith(wordWrap: newWrap);
    await _saveAndApplySettings(newSettings);
  }

  @override
  Widget build(BuildContext context) {
    final selectionState = ref.watch(selectionProvider);
    final selectionNotifier = ref.read(selectionProvider.notifier);
    final editorStatus = ref.watch(monacoEditorStatusProvider);

    // Listen for editor ready state to apply initial settings
    ref.listen<MonacoEditorStatus>(monacoEditorStatusProvider,
        (previous, next) {
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
      body: DropTarget(
        onDragEntered: (details) {
          setState(() => _isDragging = true);
        },
        onDragExited: (details) {
          setState(() => _isDragging = false);
        },
        onDragDone: (details) async {
          setState(() => _isDragging = false);

          final files = <String>[];
          final directories = <String>[];

          for (final file in details.files) {
            final entity = FileSystemEntity.typeSync(file.path);
            if (entity == FileSystemEntityType.file) {
              files.add(file.path);
            } else if (entity == FileSystemEntityType.directory) {
              directories.add(file.path);
            }
          }

          if (files.isNotEmpty) {
            await selectionNotifier.addFiles(files);
          }

          for (final directory in directories) {
            await selectionNotifier.addDirectory(directory);
          }
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: _isDragging
                ? context.primary.addOpacity(0.05)
                : Colors.transparent,
            border: _isDragging
                ? Border.all(
                    color: context.primary.addOpacity(0.3),
                    width: 2,
                  )
                : null,
          ),
          child: Column(
            children: [
              // Main editor area
              Expanded(
                child: ResizableSplitter(
                  initialRatio: 0.35,
                  minRatio: 0.2,
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
                                          color:
                                              context.surfaceContainerHighest,
                                          border: BorderDirectional(
                                            end: BorderSide(
                                              color: context.outline
                                                  .addOpacity(0.2),
                                            ),
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: context.shadow
                                                  .addOpacity(0.05),
                                              offset: const Offset(2, 0),
                                              blurRadius: 4,
                                            ),
                                          ],
                                        ),
                                        child: _buildExpandedSidebar(
                                            context, selectionState),
                                      ),
                                    )
                                  : null,
                            ),
                          );
                        },
                      ),

                      // Floating Toggle Button (positioned in editor area)
                      Positioned(
                        left:
                            _isSidebarExpanded ? _expandedSidebarWidth - 20 : 8,
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
      ),
    );
  }

  Widget _buildExpandedSidebar(
    BuildContext context,
    SelectionState selectionState,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with some spacing for the floating button
          const SizedBox(height: 28),
          Row(
            children: [
              Icon(
                Icons.tune,
                size: 20,
                color: context.primary,
              ),
              const SizedBox(width: 8),
              Text(
                'Quick Settings',
                style: context.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // File Count Badge
          if (selectionState.selectedFilesCount > 0) ...[
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 8,
              ),
              decoration: BoxDecoration(
                color: context.primary.addOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: context.primary.addOpacity(0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.description_outlined,
                    size: 16,
                    color: context.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${selectionState.selectedFilesCount} files selected',
                    style: context.labelMedium?.copyWith(
                      color: context.primary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Font Size Section
          _buildSectionTitle('Font Size'),
          const SizedBox(height: 8),
          Row(
            children: [
              IconButton(
                onPressed:
                    _editorSettings.fontSize > 8 ? _decreaseFontSize : null,
                icon: Icon(
                  Icons.remove,
                  color: context.onSurfaceVariant,
                ),
                iconSize: 18,
                style: IconButton.styleFrom(
                  minimumSize: const Size(32, 32),
                ),
                splashRadius: 0.1,
                highlightColor: Colors.transparent,
                splashColor: Colors.transparent,
                hoverColor: context.onSurface.addOpacity(0.04),
              ),
              Expanded(
                child: Container(
                  height: 32,
                  decoration: BoxDecoration(
                    color: context.surface,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text(
                      '${_editorSettings.fontSize.round()}px',
                      style: context.labelLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
              IconButton(
                onPressed:
                    _editorSettings.fontSize < 32 ? _increaseFontSize : null,
                icon: Icon(
                  Icons.add,
                  color: context.onSurfaceVariant,
                ),
                iconSize: 18,
                style: IconButton.styleFrom(
                  minimumSize: const Size(32, 32),
                ),
                splashRadius: 0.1,
                highlightColor: Colors.transparent,
                splashColor: Colors.transparent,
                hoverColor: context.onSurface.addOpacity(0.04),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Quick Toggles
          _buildSectionTitle('Editor Options'),
          const SizedBox(height: 8),

          _buildToggleTile(
            icon: Icons.wrap_text,
            title: 'Word Wrap',
            value: _editorSettings.wordWrap != WordWrap.off,
            onChanged: (_) => _toggleWordWrap(),
          ),

          _buildToggleTile(
            icon: Icons.format_list_numbered,
            title: 'Line Numbers',
            value: _editorSettings.showLineNumbers,
            onChanged: (value) async {
              final newSettings =
                  _editorSettings.copyWith(showLineNumbers: value);
              await _saveAndApplySettings(newSettings);
            },
          ),

          _buildToggleTile(
            icon: Icons.map_outlined,
            title: 'Minimap',
            value: _editorSettings.showMinimap,
            onChanged: (value) async {
              final newSettings = _editorSettings.copyWith(showMinimap: value);
              await _saveAndApplySettings(newSettings);
            },
          ),

          _buildToggleTile(
            icon: _editorSettings.readOnly ? Icons.edit_off : Icons.edit,
            title: 'Edit Mode',
            value: !_editorSettings.readOnly,
            onChanged: (isEditable) async {
              final newSettings =
                  _editorSettings.copyWith(readOnly: !isEditable);
              await _saveAndApplySettings(newSettings);
            },
          ),

          const SizedBox(height: 20),

          // Theme Quick Select
          Row(
            children: [
              Icon(
                Icons.palette_outlined,
                size: 16,
                color: context.onSurfaceVariant,
              ),
              const SizedBox(width: 8),
              _buildSectionTitle('Theme'),
            ],
          ),
          const SizedBox(height: 8),
          Theme(
            data: Theme.of(context).copyWith(
              // Override dropdown position calculation
              popupMenuTheme: PopupMenuThemeData(
                color: context.surface,
                elevation: 8,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            child: Container(
              decoration: BoxDecoration(
                color: context.surface,
                borderRadius: BorderRadius.circular(8),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  isExpanded: true,
                  value: _editorSettings.theme,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  borderRadius: BorderRadius.circular(8),
                  dropdownColor: context.surface,
                  elevation: 8,
                  menuMaxHeight: 300,
                  alignment: AlignmentDirectional.centerStart,
                  items: [
                    _buildThemeDropdownItem('vs', 'Light'),
                    _buildThemeDropdownItem('vs-dark', 'Dark'),
                    _buildThemeDropdownItem('hc-black', 'High Contrast'),
                    _buildThemeDropdownItem('one-dark-pro', 'One Dark Pro'),
                  ],
                  onChanged: (value) async {
                    if (value != null) {
                      final newSettings =
                          _editorSettings.copyWith(theme: value);
                      await _saveAndApplySettings(newSettings);
                    }
                  },
                ),
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Full Settings Button
          FilledButton.icon(
            icon: const Icon(Icons.settings, size: 18),
            label: const Text('All Settings'),
            onPressed: () => _showEnhancedEditorSettings(context),
            style: FilledButton.styleFrom(
              minimumSize: const Size(double.infinity, 40),
            ),
          ),

          const SizedBox(height: 12),

          // Copy Button
          OutlinedButton.icon(
            icon: const Icon(Icons.copy, size: 18),
            label: const Text('Copy Content'),
            onPressed: selectionState.combinedContent.isNotEmpty
                ? () =>
                    _copyToClipboard(context, selectionState.combinedContent)
                : null,
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(double.infinity, 40),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: context.labelMedium?.copyWith(
        fontWeight: FontWeight.w600,
        color: context.onSurfaceVariant,
      ),
    );
  }

  Widget _buildToggleTile({
    required IconData icon,
    required String title,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: context.surface,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: () => onChanged(!value),
          borderRadius: BorderRadius.circular(8),
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
          hoverColor: context.onSurface.addOpacity(0.02),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 8,
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 18,
                  color: value ? context.primary : context.onSurfaceVariant,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: context.bodyMedium,
                  ),
                ),
                Switch(
                  value: value,
                  onChanged: onChanged,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  DropdownMenuItem<String> _buildThemeDropdownItem(String value, String label) {
    return DropdownMenuItem(
      value: value,
      child: Text(
        label,
        style: context.bodyMedium,
      ),
    );
  }

  Future<void> _showEnhancedEditorSettings(BuildContext context) async {
    final newSettings = await EnhancedEditorSettingsDialog.show(
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
    Clipboard.setData(ClipboardData(text: content)).then((_) {
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
    }).catchError((dynamic error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error copying to clipboard: $error'),
          backgroundColor: context.error,
        ),
      );
    });
  }
}
