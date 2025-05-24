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
    _collapseController.value = 1.0; // Start expanded

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

      // Apply settings to Monaco bridge when ready
      if (_isEditorReady) {
        await _applySettingsToEditor();
      }
    }
  }

  Future<void> _applySettingsToEditor() async {
    if (!_isEditorReady) return;

    try {
      // Apply all settings to the editor
      await _monacoBridge.updateSettings(_editorSettings);

      // Apply keybinding preset
      await _monacoBridge
          .applyKeybindingPreset(_editorSettings.keybindingPreset);

      // Setup custom keybindings
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

  @override
  Widget build(BuildContext context) {
    return Consumer<SelectionCubit>(
      builder: (context, cubit, child) {
        return Column(
          children: [
            // Enhanced header with more controls
            _buildEnhancedHeader(context, cubit),

            // Content area
            Expanded(
              child: AnimatedBuilder(
                animation: _collapseAnimation,
                builder: (context, child) {
                  return Row(
                    children: [
                      // Collapsed sidebar
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        width: _isCollapsed ? 56 : 0,
                        child: _isCollapsed
                            ? _buildCollapsedSidebar(context, cubit)
                            : const SizedBox.shrink(),
                      ),

                      // Main content
                      Expanded(
                        child: SizeTransition(
                          sizeFactor: _collapseAnimation,
                          axis: Axis.horizontal,
                          child: Container(
                            margin: const EdgeInsetsDirectional.all(16),
                            child: _buildContent(context, cubit),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildEnhancedHeader(BuildContext context, SelectionCubit cubit) {
    return Container(
      padding: const EdgeInsetsDirectional.symmetric(
        horizontal: 16,
        vertical: 12,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            context.primary.addOpacity(0.08),
            context.primary.addOpacity(0.04),
          ],
          begin: AlignmentDirectional.topStart,
          end: AlignmentDirectional.bottomEnd,
        ),
        border: BorderDirectional(
          bottom: BorderSide(
            color: context.onSurface.addOpacity(0.1),
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: context.onSurface.addOpacity(0.05),
            offset: const Offset(0, 2),
            blurRadius: 4,
          ),
        ],
      ),
      child: Row(
        children: [
          // Collapse/Expand button
          _buildCollapseButton(context),
          const SizedBox(width: 12),

          // Title with icon and animated indicator
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsetsDirectional.symmetric(
              horizontal: 12,
              vertical: 6,
            ),
            decoration: BoxDecoration(
              color: _isEditorReady
                  ? context.primary.addOpacity(0.1)
                  : context.onSurface.addOpacity(0.05),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: _isEditorReady
                    ? context.primary.addOpacity(0.3)
                    : context.onSurface.addOpacity(0.1),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Stack(
                  children: [
                    Icon(
                      Icons.merge_type_rounded,
                      size: 20,
                      color: _isEditorReady
                          ? context.primary
                          : context.onSurface.addOpacity(0.6),
                    ),
                    if (!_isEditorReady)
                      Positioned.fill(
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: context.primary.addOpacity(0.6),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 8),
                Text(
                  'Monaco Editor',
                  style: context.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: _isEditorReady
                        ? context.primary
                        : context.onSurface.addOpacity(0.8),
                  ),
                ),
              ],
            ),
          ),

          // File count and stats
          if (cubit.selectedFilesCount > 0) ...[
            const SizedBox(width: 16),
            _buildStatsChips(context, cubit),
          ],

          const Spacer(),

          // Quick actions
          _buildQuickActions(context, cubit),

          const SizedBox(width: 8),

          // Settings button with enhanced tooltip
          Tooltip(
            message: 'Editor Settings\n'
                '• ${_editorSettings.theme} theme\n'
                '• ${_editorSettings.fontSize}px font size\n'
                '• ${_editorSettings.keybindingPreset.name} keybindings',
            child: IconButton(
              onPressed: () => _showEnhancedEditorSettings(context),
              icon: Stack(
                children: [
                  const Icon(Icons.tune),
                  if (_hasCustomSettings())
                    PositionedDirectional(
                      top: 2,
                      end: 2,
                      child: Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: context.primary,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                ],
              ),
              iconSize: 20,
              tooltip: '',
              style: IconButton.styleFrom(
                foregroundColor: context.primary,
                backgroundColor: context.primary.addOpacity(0.1),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsChips(BuildContext context, SelectionCubit cubit) {
    return Row(
      children: [
        // File count chip
        Container(
          padding: const EdgeInsetsDirectional.symmetric(
            horizontal: 10,
            vertical: 4,
          ),
          decoration: BoxDecoration(
            color: context.primary.addOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: context.primary.addOpacity(0.3),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.description,
                size: 14,
                color: context.primary,
              ),
              const SizedBox(width: 4),
              Text(
                '${cubit.selectedFilesCount}',
                style: context.labelSmall?.copyWith(
                  color: context.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),

        // Character count chip (if content available)
        if (cubit.combinedContent.isNotEmpty) ...[
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsetsDirectional.symmetric(
              horizontal: 10,
              vertical: 4,
            ),
            decoration: BoxDecoration(
              color: context.onSurface.addOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: context.onSurface.addOpacity(0.1),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.text_fields,
                  size: 14,
                  color: context.onSurface.addOpacity(0.6),
                ),
                const SizedBox(width: 4),
                Text(
                  _formatByteSize(cubit.combinedContent.length),
                  style: context.labelSmall?.copyWith(
                    color: context.onSurface.addOpacity(0.6),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildQuickActions(BuildContext context, SelectionCubit cubit) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Theme toggle
        Tooltip(
          message: 'Toggle theme',
          child: IconButton(
            onPressed: _toggleTheme,
            icon: Icon(
              _editorSettings.theme.contains('dark')
                  ? Icons.light_mode_outlined
                  : Icons.dark_mode_outlined,
            ),
            iconSize: 18,
            style: IconButton.styleFrom(
              foregroundColor: context.onSurface.addOpacity(0.7),
            ),
          ),
        ),

        // Font size controls
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Tooltip(
              message: 'Decrease font size',
              child: IconButton(
                onPressed:
                    _editorSettings.fontSize > 8 ? _decreaseFontSize : null,
                icon: const Icon(Icons.text_decrease),
                iconSize: 16,
                style: IconButton.styleFrom(
                  foregroundColor: context.onSurface.addOpacity(0.7),
                ),
              ),
            ),
            Container(
              width: 28,
              alignment: Alignment.center,
              child: Text(
                '${_editorSettings.fontSize.round()}',
                style: context.labelSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: context.onSurface.addOpacity(0.8),
                ),
              ),
            ),
            Tooltip(
              message: 'Increase font size',
              child: IconButton(
                onPressed:
                    _editorSettings.fontSize < 32 ? _increaseFontSize : null,
                icon: const Icon(Icons.text_increase),
                iconSize: 16,
                style: IconButton.styleFrom(
                  foregroundColor: context.onSurface.addOpacity(0.7),
                ),
              ),
            ),
          ],
        ),

        // Word wrap toggle
        Tooltip(
          message: 'Toggle word wrap',
          child: IconButton(
            onPressed: _toggleWordWrap,
            icon: Icon(
              _editorSettings.wordWrap != WordWrap.off
                  ? Icons.wrap_text
                  : Icons.notes,
            ),
            iconSize: 18,
            style: IconButton.styleFrom(
              foregroundColor: _editorSettings.wordWrap != WordWrap.off
                  ? context.primary
                  : context.onSurface.addOpacity(0.7),
              backgroundColor: _editorSettings.wordWrap != WordWrap.off
                  ? context.primary.addOpacity(0.1)
                  : null,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCollapseButton(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _toggleCollapse,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsetsDirectional.all(8),
          decoration: BoxDecoration(
            color: context.surface,
            border: Border.all(
              color: context.onSurface.addOpacity(0.2),
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: AnimatedRotation(
            turns: _isCollapsed ? 0.5 : 0,
            duration: const Duration(milliseconds: 300),
            child: Icon(
              Icons.chevron_left,
              size: 18,
              color: context.onSurface.addOpacity(0.7),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCollapsedSidebar(BuildContext context, SelectionCubit cubit) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            context.surface,
            if (context.isDark)
              Colors.black.addOpacity(0.2)
            else
              Colors.grey.shade50,
          ],
          begin: AlignmentDirectional.topCenter,
          end: AlignmentDirectional.bottomCenter,
        ),
        border: BorderDirectional(
          end: BorderSide(
            color: context.onSurface.addOpacity(0.1),
          ),
        ),
      ),
      child: Column(
        children: [
          const SizedBox(height: 16),
          IconButton(
            onPressed: _toggleCollapse,
            icon: const Icon(Icons.chevron_right),
            tooltip: 'Expand editor',
            style: IconButton.styleFrom(
              backgroundColor: context.primary.addOpacity(0.1),
              foregroundColor: context.primary,
            ),
          ),
          const SizedBox(height: 24),
          if (cubit.combinedContent.isNotEmpty) ...[
            // Copy button
            IconButton(
              onPressed: () => _copyToClipboard(context, cubit.combinedContent),
              icon: const Icon(Icons.copy),
              tooltip: 'Copy content',
              style: IconButton.styleFrom(
                foregroundColor: context.onSurface.addOpacity(0.7),
              ),
            ),
            const SizedBox(height: 12),

            // Format button
            IconButton(
              onPressed: _formatContent,
              icon: const Icon(Icons.auto_fix_high),
              tooltip: 'Format content',
              style: IconButton.styleFrom(
                foregroundColor: context.onSurface.addOpacity(0.7),
              ),
            ),
            const SizedBox(height: 12),

            // Go to top
            IconButton(
              onPressed: _scrollToTop,
              icon: const Icon(Icons.keyboard_arrow_up),
              tooltip: 'Scroll to top',
              style: IconButton.styleFrom(
                foregroundColor: context.onSurface.addOpacity(0.7),
              ),
            ),
            const SizedBox(height: 24),

            // File count indicator
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
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context, SelectionCubit cubit) {
    if (cubit.combinedContent.isEmpty) {
      return _buildEmptyState(context);
    }

    // Update bridge content when cubit changes
    if (_monacoBridge.content != cubit.combinedContent) {
      _monacoBridge.setContent(cubit.combinedContent);
    }

    return Column(
      children: [
        // Editor
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

                // Apply settings after editor is ready
                await _applySettingsToEditor();

                // Set content after a small delay
                await 100.millisecondsDelay();
                await _monacoBridge.setContent(cubit.combinedContent);
              },
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Enhanced info bar with more controls
        MonacoEditorInfoBar(
          bridge: _monacoBridge,
          onCopy: () => _copyToClipboard(context, cubit.combinedContent),
          onSettings: () => _showEnhancedEditorSettings(context),
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

          // Enhanced quick tips with better styling
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

  // Helper methods
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
