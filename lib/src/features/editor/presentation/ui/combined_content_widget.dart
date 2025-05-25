import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../../shared/theme/extensions.dart';
import '../../../scan/presentation/state/selection_cubit.dart';
import '../../bridge/monaco_bridge.dart';
import '../../domain/editor_settings.dart';
import '../../domain/keybinding_manager.dart';
import '../../domain/theme_manager.dart';
import 'enhanced_editor_settings_dialog.dart';
import 'monaco_editor_embedded.dart';
import 'monaco_editor_info_bar.dart';

class CombinedContentWidget extends StatefulWidget {
  const CombinedContentWidget({super.key});

  @override
  State<CombinedContentWidget> createState() => _CombinedContentWidgetState();
}

class _CombinedContentWidgetState extends State<CombinedContentWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _sidebarAnimation;
  late MonacoBridge _monacoBridge;
  bool _isSidebarExpanded = false;
  EditorSettings _editorSettings = const EditorSettings();
  final List<EditorTheme> _customThemes = [];
  final List<KeybindingPreset> _customKeybindingPresets = [];
  bool _isEditorReady = false;

  // Sidebar dimensions
  static const double _expandedSidebarWidth = 280;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _sidebarAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOutCubic,
    );

    _monacoBridge = MonacoBridge();
    _loadEditorSettings();
  }

  Future<void> _loadEditorSettings() async {
    final settings = await EditorSettings.load();
    if (mounted) {
      setState(() {
        _editorSettings = settings;
      });
      if (_isEditorReady) {
        await _applySettingsToEditor();
      }
    }
  }

  Future<void> _applySettingsToEditor() async {
    if (!_isEditorReady) return;
    debugPrint(
        '[_applySettingsToEditor] Applying to editor, current _editorSettings.showLineNumbers: ${_editorSettings.showLineNumbers}');
    try {
      await _monacoBridge.updateSettings(_editorSettings);
      await _monacoBridge
          .applyKeybindingPreset(_editorSettings.keybindingPreset);
      if (_editorSettings.customKeybindings.isNotEmpty) {
        await _monacoBridge.setupKeybindings(_editorSettings.customKeybindings);
      }
    } catch (e) {
      debugPrint('Error applying settings to editor: $e');
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _monacoBridge.dispose();
    super.dispose();
  }

  void _toggleSidebar() {
    setState(() {
      _isSidebarExpanded = !_isSidebarExpanded;
      if (_isSidebarExpanded) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<SelectionCubit>(
      builder: (context, cubit, child) {
        return Stack(
          children: [
            // Main content with animated padding
            Row(
              children: [
                // Animated Sidebar
                AnimatedBuilder(
                  animation: _sidebarAnimation,
                  builder: (context, child) {
                    final width =
                        _expandedSidebarWidth * _sidebarAnimation.value;

                    return SizedBox(
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
                                child: _buildExpandedSidebar(context, cubit),
                              ),
                            )
                          : null,
                    );
                  },
                ),

                // Main Content (takes all remaining space)
                Expanded(
                  child: Container(
                    padding: const EdgeInsetsDirectional.only(bottom: 16),
                    child: _buildContent(context, cubit),
                  ),
                ),
              ],
            ),

            // Floating Toggle Button (positioned absolutely)
            PositionedDirectional(
              start: _isSidebarExpanded ? _expandedSidebarWidth - 20 : 8,
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
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: context.outline.addOpacity(0.2),
                          ),
                        ),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            Icon(
                              _isSidebarExpanded
                                  ? Icons.chevron_left
                                  : Icons.tune,
                              size: 20,
                              color: context.onSurfaceVariant,
                            ),
                            // File count badge (when collapsed and files selected)
                            if (!_isSidebarExpanded &&
                                cubit.selectedFilesCount > 0)
                              PositionedDirectional(
                                end: 0,
                                top: 0,
                                child: Container(
                                  width: 14,
                                  height: 14,
                                  decoration: BoxDecoration(
                                    color: context.error,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: context.surface,
                                      width: 1.5,
                                    ),
                                  ),
                                  child: Center(
                                    child: Text(
                                      cubit.selectedFilesCount > 9
                                          ? '9+'
                                          : cubit.selectedFilesCount.toString(),
                                      style: TextStyle(
                                        color: context.onError,
                                        fontSize: 8,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildExpandedSidebar(BuildContext context, SelectionCubit cubit) {
    return SingleChildScrollView(
      padding: const EdgeInsetsDirectional.all(16),
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
          if (cubit.selectedFilesCount > 0) ...[
            Container(
              padding: const EdgeInsetsDirectional.symmetric(
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
                    '${cubit.selectedFilesCount} files selected',
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
                  color: context.themeData.onSurfaceVariant,
                ),
                iconSize: 18,
                style: IconButton.styleFrom(
                  minimumSize: const Size(32, 32),
                ),
              ),
              Flexible(
                fit: FlexFit.tight,
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
                  color: context.themeData.onSurfaceVariant,
                ),
                iconSize: 18,
                style: IconButton.styleFrom(
                  minimumSize: const Size(32, 32),
                ),
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
          Container(
            decoration: BoxDecoration(
              color: context.surface,
              borderRadius: BorderRadius.circular(8),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                isExpanded: true,
                value: _editorSettings.theme,
                padding: const EdgeInsetsDirectional.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                borderRadius: BorderRadius.circular(8),
                items: [
                  _buildThemeDropdownItem('vs', 'Light'),
                  _buildThemeDropdownItem('vs-dark', 'Dark'),
                  _buildThemeDropdownItem('hc-black', 'High Contrast'),
                  _buildThemeDropdownItem('one-dark-pro', 'One Dark Pro'),
                ],
                onChanged: (value) async {
                  if (value != null) {
                    final newSettings = _editorSettings.copyWith(theme: value);
                    await _saveAndApplySettings(newSettings);
                  }
                },
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
            onPressed: cubit.combinedContent.isNotEmpty
                ? () => _copyToClipboard(context, cubit.combinedContent)
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
      margin: const EdgeInsetsDirectional.only(bottom: 8),
      child: Material(
        color: context.surface,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: () => onChanged(!value),
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsetsDirectional.symmetric(
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

  Widget _buildContent(BuildContext context, SelectionCubit cubit) {
    if (cubit.combinedContent.isEmpty) {
      return _buildEmptyState(context);
    }
    if (_monacoBridge.content != cubit.combinedContent) {
      _monacoBridge.setContent(cubit.combinedContent);
    }
    return Column(
      children: [
        Expanded(
          child: MonacoEditorEmbedded(
            bridge: _monacoBridge,
            onReady: () async {
              setState(() {
                _isEditorReady = true;
              });
              await _applySettingsToEditor();
              await 100.millisecondsDelay();
              await _monacoBridge.setContent(cubit.combinedContent);
            },
          ),
        ),
        const SizedBox(height: 16),
        MonacoEditorInfoBar(
          bridge: _monacoBridge,
          onCopy: () => _copyToClipboard(context, cubit.combinedContent),
        ),
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsetsDirectional.all(32),
            decoration: BoxDecoration(
              gradient: RadialGradient(
                colors: [
                  context.primary.addOpacity(0.1),
                  context.primary.addOpacity(0.05),
                ],
              ),
              shape: BoxShape.circle,
              border: Border.all(
                color: context.primary.addOpacity(0.2),
                width: 2,
              ),
            ),
            child: Icon(
              Icons.merge_type_rounded,
              size: 64,
              color: context.primary.addOpacity(0.6),
            ),
          ),
          const SizedBox(height: 32),
          Text(
            'Monaco Editor Ready',
            style: context.headlineSmall?.copyWith(
              color: context.onSurface.addOpacity(0.9),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Select files to start editing with Monaco',
            textAlign: TextAlign.center,
            style: context.bodyLarge?.copyWith(
              color: context.onSurface.addOpacity(0.6),
            ),
          ),
        ],
      ),
    );
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

  Future<void> _saveAndApplySettings(EditorSettings newSettings) async {
    setState(() {
      _editorSettings = newSettings;
    });
    await newSettings.save();
    debugPrint(
        '[_saveAndApplySettings] _isEditorReady: $_isEditorReady, new showLineNumbers: ${newSettings.showLineNumbers}');
    if (_isEditorReady) {
      await _applySettingsToEditor();
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

  Future<void> _showEnhancedEditorSettings(BuildContext context) async {
    final newSettings = await EnhancedEditorSettingsDialog.show(
      context,
      _editorSettings,
      customThemes: _customThemes,
      customKeybindingPresets: _customKeybindingPresets,
    );
    if (newSettings != null && mounted) {
      await _saveAndApplySettings(newSettings);
    }
  }
}
