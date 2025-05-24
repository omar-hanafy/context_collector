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
  late AnimationController _collapseController;
  late Animation<double> _collapseAnimation;
  late MonacoBridge _monacoBridge;
  bool _isCollapsed = false;
  EditorSettings _editorSettings = const EditorSettings();
  final List<EditorTheme> _customThemes = [];
  final List<KeybindingPreset> _customKeybindingPresets = [];
  bool _isEditorReady = false;

  // Store the width of the sidebar for animation and layout
  final double _sidebarWidth = 250;

  @override
  void initState() {
    super.initState();
    _collapseController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _collapseAnimation = CurvedAnimation(
      parent: _collapseController,
      curve: Curves.easeInOut,
    );
    // Start collapsed, so controller value is 0.0
    // The button will allow it to expand to 1.0
    _collapseController.value = 0.0;
    _isCollapsed = true; // Reflects initial state

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
    _collapseController.dispose();
    _monacoBridge.dispose();
    super.dispose();
  }

  void _toggleCollapse() {
    setState(() {
      _isCollapsed = !_isCollapsed;
      if (_isCollapsed) {
        _collapseController.reverse();
      } else {
        _collapseController.forward();
      }
    });
  }

  // _buildEnhancedHeader is REMOVED
  // _buildCollapseButton (old top bar button) is REMOVED or will be repurposed/replaced by edge toggle logic

  Widget _buildCollapsedSidebar(BuildContext context, SelectionCubit cubit) {
    // Original content restored
    return Container(
      width: _sidebarWidth, // It takes full width when animation allows
      padding: const EdgeInsetsDirectional.symmetric(vertical: 16),
      alignment: AlignmentDirectional.topCenter, // Align content to top
      child: Column(
        mainAxisAlignment:
            MainAxisAlignment.center, // Center the content vertically
        children: [
          if (cubit.selectedFilesCount > 0)
            RotatedBox(
              quarterTurns: -1,
              child: Container(
                padding: const EdgeInsetsDirectional.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: context.primary.addOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${cubit.selectedFilesCount} files',
                  style: context.labelSmall?.copyWith(
                    color: context.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildExpandedSidebarContent(BuildContext context) {
    // Original content restored
    return SingleChildScrollView(
      padding: const EdgeInsetsDirectional.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Font Size', style: context.titleSmall),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                onPressed:
                    _editorSettings.fontSize > 8 ? _decreaseFontSize : null,
                icon: const Icon(Icons.text_decrease),
                iconSize: 20,
                tooltip: 'Decrease font size',
              ),
              Container(
                width: 36,
                alignment: Alignment.center,
                child: Text(
                  '${_editorSettings.fontSize.round()}',
                  style: context.labelLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              IconButton(
                onPressed:
                    _editorSettings.fontSize < 32 ? _increaseFontSize : null,
                icon: const Icon(Icons.text_increase),
                iconSize: 20,
                tooltip: 'Increase font size',
              ),
            ],
          ),
          const Divider(height: 24),
          ListTile(
            contentPadding: EdgeInsetsDirectional.zero,
            leading: Icon(
              _editorSettings.wordWrap != WordWrap.off
                  ? Icons.wrap_text
                  : Icons.notes,
              color: _editorSettings.wordWrap != WordWrap.off
                  ? context.primary
                  : context.onSurface.addOpacity(0.7),
            ),
            title: const Text('Word Wrap'),
            trailing: Switch(
              value: _editorSettings.wordWrap != WordWrap.off,
              onChanged: (_) => _toggleWordWrap(),
            ),
            onTap: _toggleWordWrap,
          ),
          const Divider(height: 24),
          ElevatedButton.icon(
            icon: const Icon(Icons.tune),
            label: const Text('Editor Settings'),
            onPressed: () => _showEnhancedEditorSettings(context),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 40),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebarToggleButton(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _toggleCollapse,
        borderRadius: BorderRadius.circular(30), // Make it roundish
        child: Container(
          padding: const EdgeInsetsDirectional.all(8),
          decoration: BoxDecoration(
            color: context.surface.addOpacity(0.8),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.addOpacity(0.2),
                blurRadius: 4,
                offset: const Offset(1, 1),
              )
            ],
            border: Border.all(color: context.onSurface.addOpacity(0.2)),
          ),
          child: AnimatedRotation(
            turns: _isCollapsed
                ? 0
                : 0.5, // Point right when collapsed, left when expanded
            duration: const Duration(milliseconds: 300),
            child: Icon(
              Icons
                  .chevron_left, // Icon always points left, rotation handles direction
              size: 20,
              color: context.onSurface.addOpacity(0.7),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<SelectionCubit>(
      builder: (context, cubit, child) {
        return Column(
          children: [
            // _buildEnhancedHeader is REMOVED
            Expanded(
              child: Stack(
                children: [
                  Row(
                    children: [
                      // Collapsed or Expanded sidebar content
                      SizeTransition(
                        sizeFactor: _collapseAnimation,
                        axis: Axis.horizontal,
                        child: Container(
                          // This container defines the full expanded width
                          width: _sidebarWidth,
                          decoration: BoxDecoration(
                            color: Theme.of(context)
                                .colorScheme
                                .surfaceContainerHighest,
                            border: BorderDirectional(
                              end: BorderSide(
                                color: context.onSurface.addOpacity(0.1),
                              ),
                            ),
                          ),
                          // Key added here to ensure the Container and its child are swapped correctly
                          key: ValueKey<String>(
                              _isCollapsed ? 'collapsed' : 'expanded'),
                          child: _isCollapsed
                              ? _buildCollapsedSidebar(context, cubit) // Green
                              : _buildExpandedSidebarContent(context), // Blue
                          // Removed Opacity widget here
                        ),
                      ),
                      Expanded(
                        child: Container(
                          margin: const EdgeInsetsDirectional.all(16),
                          child: _buildContent(context, cubit),
                        ),
                      ),
                    ],
                  ),
                  // Positioned Sidebar Toggle Button
                  AnimatedBuilder(
                    animation: _collapseAnimation,
                    builder: (context, child) {
                      const double buttonRadius =
                          18; // Approximate half-width of the button
                      double startPosition;
                      if (_collapseAnimation.value < 0.1) {
                        // Mostly or fully collapsed
                        startPosition =
                            4.0; // Keep button slightly inset from screen edge
                      } else {
                        // Expanding or fully expanded
                        startPosition =
                            (_sidebarWidth * _collapseAnimation.value) -
                                buttonRadius;
                      }

                      return PositionedDirectional(
                        top: 0,
                        bottom: 0,
                        start: startPosition,
                        child: Center(
                          child: _buildSidebarToggleButton(context),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        );
      },
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
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: context.onSurface.addOpacity(0.1),
              ),
              boxShadow: [
                BoxShadow(
                  color: context.onSurface.addOpacity(0.05),
                  offset: const Offset(0, 2),
                  blurRadius: 8,
                ),
              ],
            ),
            clipBehavior: Clip.antiAlias,
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
        ),
        const SizedBox(height: 16),
        MonacoEditorInfoBar(
          bridge: _monacoBridge,
          onCopy: () => _copyToClipboard(context, cubit.combinedContent),
          // onSettings is removed as per previous refactor
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
            'Select files and load their content to start editing with the full power of Monaco',
            textAlign: TextAlign.center,
            style: context.bodyLarge?.copyWith(
              color: context.onSurface.addOpacity(0.6),
            ),
          ),
          const SizedBox(height: 40),
          Container(
            constraints: const BoxConstraints(maxWidth: 500),
            padding: const EdgeInsetsDirectional.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  context.primary.addOpacity(0.08),
                  context.primary.addOpacity(0.03),
                ],
                begin: AlignmentDirectional.topStart,
                end: AlignmentDirectional.bottomEnd,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: context.primary.addOpacity(0.2),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsetsDirectional.all(8),
                      decoration: BoxDecoration(
                        color: context.primary.addOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.auto_awesome,
                        size: 20,
                        color: context.primary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Monaco Editor Features',
                      style: context.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: context.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildFeatureTip(context, Icons.palette,
                    'Multiple themes including One Dark Pro'),
                _buildFeatureTip(context, Icons.keyboard,
                    'VS Code, IntelliJ, Vim, and Emacs keybindings'),
                _buildFeatureTip(context, Icons.code,
                    'Syntax highlighting for 80+ languages'),
                _buildFeatureTip(context, Icons.search,
                    'Advanced find & replace with regex support'),
                _buildFeatureTip(context, Icons.format_align_left,
                    'Auto-formatting and code folding'),
                _buildFeatureTip(context, Icons.accessibility,
                    'Full accessibility and screen reader support'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureTip(BuildContext context, IconData icon, String text) {
    return Padding(
      padding: const EdgeInsetsDirectional.only(bottom: 12),
      child: Row(
        children: [
          Icon(
            icon,
            size: 16,
            color: context.primary.addOpacity(0.8),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: context.bodyMedium?.copyWith(
                color: context.onSurface.addOpacity(0.8),
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  bool _hasCustomSettings() {
    const defaultSettings = EditorSettings();
    return _editorSettings.theme != defaultSettings.theme ||
        _editorSettings.fontSize != defaultSettings.fontSize ||
        _editorSettings.keybindingPreset != defaultSettings.keybindingPreset ||
        _editorSettings.wordWrap != defaultSettings.wordWrap;
  }

  String _formatByteSize(int bytes) {
    if (bytes < 1024) return '${bytes}B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)}KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)}MB';
  }

  Future<void> _toggleTheme() async {
    final newTheme = _editorSettings.theme.contains('dark') ? 'vs' : 'vs-dark';
    final newSettings = _editorSettings.copyWith(theme: newTheme);
    await _saveAndApplySettings(newSettings);
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

  Future<void> _formatContent() async {
    if (_isEditorReady) {
      await _monacoBridge.format();
    }
  }

  Future<void> _scrollToTop() async {
    if (_isEditorReady) {
      await _monacoBridge.scrollToTop();
    }
  }

  Future<void> _scrollToBottom() async {
    // Added for completeness, if called from somewhere
    if (_isEditorReady) {
      await _monacoBridge.scrollToBottom();
    }
  }

  Future<void> _saveAndApplySettings(EditorSettings newSettings) async {
    setState(() {
      _editorSettings = newSettings;
    });
    await newSettings.save();
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
