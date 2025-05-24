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

/// Streamlined editor section with collapsible control panel
class CombinedContentWidget extends StatefulWidget {
  const CombinedContentWidget({super.key});

  @override
  State<CombinedContentWidget> createState() => _CombinedContentWidgetState();
}

class _CombinedContentWidgetState extends State<CombinedContentWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _panelController;
  late Animation<double> _panelAnimation;
  late MonacoBridge _monacoBridge;
  bool _isPanelExpanded = false;
  EditorSettings _editorSettings = const EditorSettings();
  bool _isEditorReady = false;

  @override
  void initState() {
    super.initState();
    _panelController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _panelAnimation = CurvedAnimation(
      parent: _panelController,
      curve: Curves.easeInOut,
    );

    // Initialize Monaco bridge
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
      await _monacoBridge.applyKeybindingPreset(_editorSettings.keybindingPreset);

      if (_editorSettings.customKeybindings.isNotEmpty) {
        await _monacoBridge.setupKeybindings(_editorSettings.customKeybindings);
      }
    } catch (e) {
      debugPrint('Error applying settings to editor: $e');
    }
  }

  @override
  void dispose() {
    _panelController.dispose();
    _monacoBridge.dispose();
    super.dispose();
  }

  void _toggleControlPanel() {
    setState(() {
      _isPanelExpanded = !_isPanelExpanded;
      if (_isPanelExpanded) {
        _panelController.forward();
      } else {
        _panelController.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<SelectionCubit>(
      builder: (context, cubit, child) {
        if (cubit.combinedContent.isEmpty) {
          return _buildEmptyState(context);
        }

        // Update bridge content when cubit changes
        if (_monacoBridge.content != cubit.combinedContent) {
          _monacoBridge.setContent(cubit.combinedContent);
        }

        return _buildEditorWithControls(context, cubit);
      },
    );
  }

  Widget _buildEditorWithControls(BuildContext context, SelectionCubit cubit) {
    return Stack(
      children: [
        // Main editor area - NO top/bottom bars
        Container(
          margin: const EdgeInsetsDirectional.all(16),
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
          child: Column(
            children: [
              // Minimal editor status bar
              _buildMinimalStatusBar(context, cubit),
              
              // Monaco editor takes full remaining space
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
            ],
          ),
        ),

        // Essential floating actions - always visible
        _buildEssentialActions(context, cubit),

        // Collapsible control panel - slides from right
        _buildCollapsibleControlPanel(context),
      ],
    );
  }

  Widget _buildMinimalStatusBar(BuildContext context, SelectionCubit cubit) {
    return Container(
      height: 40,
      padding: const EdgeInsetsDirectional.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: context.surface,
        border: BorderDirectional(
          bottom: BorderSide(
            color: context.onSurface.addOpacity(0.1),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          // Language selector - compact
          _buildCompactLanguageSelector(context),
          
          const SizedBox(width: 16),
          
          // Editor stats
          _buildEditorStats(context),
          
          const Spacer(),
          
          // Read-only indicator
          if (_editorSettings.readOnly)
            Container(
              padding: const EdgeInsetsDirectional.symmetric(
                horizontal: 8,
                vertical: 4,
              ),
              decoration: BoxDecoration(
                color: context.error.addOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.edit_off,
                    size: 14,
                    color: context.error,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Read Only',
                    style: context.labelSmall?.copyWith(
                      color: context.error,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          
          // Control panel toggle
          IconButton(
            onPressed: _toggleControlPanel,
            icon: AnimatedRotation(
              turns: _isPanelExpanded ? 0.5 : 0,
              duration: const Duration(milliseconds: 300),
              child: const Icon(Icons.tune),
            ),
            tooltip: _isPanelExpanded ? 'Hide controls' : 'Show controls',
            style: IconButton.styleFrom(
              backgroundColor: _isPanelExpanded 
                ? context.primary.addOpacity(0.15)
                : context.primary.addOpacity(0.08),
              foregroundColor: context.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactLanguageSelector(BuildContext context) {
    return Container(
      padding: const EdgeInsetsDirectional.symmetric(
        horizontal: 12,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: context.primary.addOpacity(0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: context.primary.addOpacity(0.2),
        ),
      ),
      child: DropdownButton<String>(
        value: _monacoBridge.language,
        underline: const SizedBox(),
        isDense: true,
        icon: Icon(
          Icons.keyboard_arrow_down,
          size: 16,
          color: context.primary,
        ),
        style: context.labelMedium?.copyWith(
          color: context.primary,
          fontWeight: FontWeight.w600,
        ),
        items: MonacoBridge.availableLanguages
            .take(10) // Show only common languages in compact view
            .map((lang) => DropdownMenuItem(
                  value: lang['value'],
                  child: Text(lang['text']!),
                ))
            .toList(),
        onChanged: (value) async {
          if (value != null) {
            await _monacoBridge.setLanguage(value);
          }
        },
      ),
    );
  }

  Widget _buildEditorStats(BuildContext context) {
    return ListenableBuilder(
      listenable: _monacoBridge,
      builder: (context, _) {
        if (!_monacoBridge.isReady) return const SizedBox();
        
        return FutureBuilder<Map<String, dynamic>>(
          future: _monacoBridge.getEditorStats(),
          builder: (context, snapshot) {
            final stats = snapshot.data ?? {};
            final lineCount = stats['lineCount'] as int? ?? 0;
            final characterCount = stats['characterCount'] as int? ?? 0;
            
            return Container(
              padding: const EdgeInsetsDirectional.symmetric(
                horizontal: 8,
                vertical: 4,
              ),
              decoration: BoxDecoration(
                color: context.onSurface.addOpacity(0.05),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                '$lineCount lines • ${_formatCharacterCount(characterCount)}',
                style: context.labelSmall?.copyWith(
                  color: context.onSurface.addOpacity(0.6),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildEssentialActions(BuildContext context, SelectionCubit cubit) {
    return PositionedDirectional(
      bottom: 24,
      end: 24,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Copy content - floating action button
          FloatingActionButton(
            onPressed: () => _copyToClipboard(context, cubit.combinedContent),
            tooltip: 'Copy content',
            child: const Icon(Icons.copy),
          ),
          
          const SizedBox(height: 12),
          
          // Scroll to top
          FloatingActionButton.small(
            onPressed: _scrollToTop,
            tooltip: 'Scroll to top',
            child: const Icon(Icons.keyboard_arrow_up),
          ),
        ],
      ),
    );
  }

  Widget _buildCollapsibleControlPanel(BuildContext context) {
    return PositionedDirectional(
      top: 56, // Below status bar
      end: 16,
      bottom: 16,
      child: AnimatedBuilder(
        animation: _panelAnimation,
        builder: (context, child) {
          return Transform.translate(
            offset: Offset(300 * (1 - _panelAnimation.value), 0),
            child: Container(
              width: 280,
              decoration: BoxDecoration(
                color: context.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: context.onSurface.addOpacity(0.1),
                ),
                boxShadow: [
                  BoxShadow(
                    color: context.onSurface.addOpacity(0.1),
                    offset: const Offset(-2, 0),
                    blurRadius: 12,
                  ),
                ],
              ),
              child: _isPanelExpanded ? _buildControlPanelContent(context) : null,
            ),
          );
        },
      ),
    );
  }

  Widget _buildControlPanelContent(BuildContext context) {
    return Column(
      children: [
        // Panel header
        Container(
          padding: const EdgeInsetsDirectional.all(16),
          decoration: BoxDecoration(
            color: context.primary.addOpacity(0.05),
            borderRadius: const BorderRadiusDirectional.only(
              topStart: Radius.circular(16),
              topEnd: Radius.circular(16),
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.tune,
                color: context.primary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Editor Controls',
                style: context.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: context.primary,
                ),
              ),
              const Spacer(),
              IconButton(
                onPressed: _toggleControlPanel,
                icon: const Icon(Icons.close),
                iconSize: 18,
                style: IconButton.styleFrom(
                  backgroundColor: context.onSurface.addOpacity(0.1),
                ),
              ),
            ],
          ),
        ),

        // Control content
        Expanded(
          child: ListView(
            padding: const EdgeInsetsDirectional.all(16),
            children: [
              // Theme controls
              _buildControlSection(
                context,
                'Appearance',
                [
                  _buildThemeToggleRow(context),
                  _buildFontSizeRow(context),
                  _buildToggleRow(
                    context,
                    'Show Minimap',
                    Icons.map,
                    _editorSettings.showMinimap,
                    (value) => _updateSetting((s) => s.copyWith(showMinimap: value)),
                  ),
                  _buildToggleRow(
                    context,
                    'Line Numbers',
                    Icons.format_list_numbered,
                    _editorSettings.showLineNumbers,
                    (value) => _updateSetting((s) => s.copyWith(showLineNumbers: value)),
                  ),
                  _buildToggleRow(
                    context,
                    'Word Wrap',
                    Icons.wrap_text,
                    _editorSettings.wordWrap != WordWrap.off,
                    (value) => _updateSetting((s) => s.copyWith(
                      wordWrap: value ? WordWrap.on : WordWrap.off,
                    )),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Editor actions
              _buildControlSection(
                context,
                'Actions',
                [
                  _buildActionButton(
                    context,
                    'Format Document',
                    Icons.auto_fix_high,
                    _formatContent,
                  ),
                  _buildActionButton(
                    context,
                    'Find & Replace',
                    Icons.find_replace,
                    () => _monacoBridge.findAndReplace(),
                  ),
                  _buildActionButton(
                    context,
                    'Go to Line',
                    Icons.format_line_spacing,
                    () => _monacoBridge.goToLine(),
                  ),
                  _buildActionButton(
                    context,
                    'Scroll to Bottom',
                    Icons.keyboard_arrow_down,
                    () => _monacoBridge.scrollToBottom(),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Editor mode
              _buildControlSection(
                context,
                'Mode',
                [
                  _buildToggleRow(
                    context,
                    'Read Only',
                    Icons.edit_off,
                    _editorSettings.readOnly,
                    (value) => _updateSetting((s) => s.copyWith(readOnly: value)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildControlSection(
    BuildContext context,
    String title,
    List<Widget> children,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: context.labelLarge?.copyWith(
            fontWeight: FontWeight.w600,
            color: context.onSurface.addOpacity(0.8),
          ),
        ),
        const SizedBox(height: 12),
        ...children,
      ],
    );
  }

  Widget _buildThemeToggleRow(BuildContext context) {
    final isDark = _editorSettings.theme.contains('dark');
    
    return _buildToggleRow(
      context,
      'Dark Theme',
      isDark ? Icons.dark_mode : Icons.light_mode,
      isDark,
      (value) => _updateSetting((s) => s.copyWith(
        theme: value ? 'vs-dark' : 'vs',
      )),
    );
  }

  Widget _buildFontSizeRow(BuildContext context) {
    return Container(
      margin: const EdgeInsetsDirectional.only(bottom: 12),
      child: Row(
        children: [
          Icon(
            Icons.text_fields,
            size: 18,
            color: context.onSurface.addOpacity(0.6),
          ),
          const SizedBox(width: 12),
          Text(
            'Font Size',
            style: context.bodyMedium,
          ),
          const Spacer(),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                onPressed: _editorSettings.fontSize > 8 ? _decreaseFontSize : null,
                icon: const Icon(Icons.remove),
                iconSize: 16,
                style: IconButton.styleFrom(
                  minimumSize: const Size(32, 32),
                ),
              ),
              Container(
                width: 40,
                alignment: AlignmentDirectional.center,
                child: Text(
                  '${_editorSettings.fontSize.round()}',
                  style: context.labelMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              IconButton(
                onPressed: _editorSettings.fontSize < 32 ? _increaseFontSize : null,
                icon: const Icon(Icons.add),
                iconSize: 16,
                style: IconButton.styleFrom(
                  minimumSize: const Size(32, 32),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildToggleRow(
    BuildContext context,
    String title,
    IconData icon,
    bool value,
    ValueChanged<bool> onChanged,
  ) {
    return Container(
      margin: const EdgeInsetsDirectional.only(bottom: 12),
      child: Row(
        children: [
          Icon(
            icon,
            size: 18,
            color: context.onSurface.addOpacity(0.6),
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
    );
  }

  Widget _buildActionButton(
    BuildContext context,
    String title,
    IconData icon,
    VoidCallback onPressed,
  ) {
    return Container(
      margin: const EdgeInsetsDirectional.only(bottom: 8),
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 18),
        label: Text(title),
        style: OutlinedButton.styleFrom(
          alignment: AlignmentDirectional.centerStart,
          padding: const EdgeInsetsDirectional.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
        ),
      ),
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
            'Select files and load their content to start editing',
            textAlign: TextAlign.center,
            style: context.bodyLarge?.copyWith(
              color: context.onSurface.addOpacity(0.6),
            ),
          ),
        ],
      ),
    );
  }

  // Helper methods
  Future<void> _updateSetting(EditorSettings Function(EditorSettings) updater) async {
    final newSettings = updater(_editorSettings);
    setState(() {
      _editorSettings = newSettings;
    });
    await newSettings.save();
    if (_isEditorReady) {
      await _applySettingsToEditor();
    }
  }

  Future<void> _increaseFontSize() async {
    if (_editorSettings.fontSize < 32) {
      await _updateSetting((s) => s.copyWith(fontSize: s.fontSize + 1));
    }
  }

  Future<void> _decreaseFontSize() async {
    if (_editorSettings.fontSize > 8) {
      await _updateSetting((s) => s.copyWith(fontSize: s.fontSize - 1));
    }
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

  String _formatCharacterCount(int count) {
    if (count < 1000) return '${count}c';
    if (count < 1000000) return '${(count / 1000).toStringAsFixed(1)}K';
    return '${(count / 1000000).toStringAsFixed(1)}M';
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