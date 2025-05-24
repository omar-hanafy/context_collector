import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../../shared/theme/extensions.dart';
import '../../bridge/monaco_bridge.dart';
import '../../../scan/presentation/state/selection_cubit.dart';
import '../../domain/editor_settings.dart';
import 'monaco_editor_embedded.dart';
import 'monaco_editor_info_bar.dart';
import 'editor_settings_dialog.dart';

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

      // Apply settings to Monaco bridge
      await _monacoBridge.updateOptions(
        fontSize: settings.fontSize,
        wordWrap: settings.wordWrap,
        showLineNumbers: settings.showLineNumbers,
      );
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
            // Header with collapse button
            Container(
              padding: const EdgeInsetsDirectional.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
              decoration: BoxDecoration(
                color: context.surface,
                border: BorderDirectional(
                  bottom: BorderSide(
                    color: context.onSurface.addOpacity(0.1),
                  ),
                ),
                boxShadow: [
                  BoxShadow(
                    color: context.onSurface.addOpacity(0.05),
                    offset: const Offset(0, 1),
                    blurRadius: 3,
                  ),
                ],
              ),
              child: Row(
                children: [
                  // Collapse/Expand button
                  _buildCollapseButton(context),
                  const SizedBox(width: 12),

                  // Title with icon
                  Icon(
                    Icons.merge_type_rounded,
                    size: 20,
                    color: context.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Combined Content',
                    style: context.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),

                  // File count badge
                  if (cubit.selectedFilesCount > 0) ...[
                    const SizedBox(width: 12),
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
                      child: Text(
                        '${cubit.selectedFilesCount} files',
                        style: context.labelSmall?.copyWith(
                          color: context.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],

                  const Spacer(),

                  // Settings button (for font size, theme, etc.)
                  IconButton(
                    onPressed: () => _showEditorSettings(context),
                    icon: const Icon(Icons.settings_outlined),
                    iconSize: 20,
                    tooltip: 'Editor settings',
                    style: IconButton.styleFrom(
                      foregroundColor: context.onSurface.addOpacity(0.7),
                    ),
                  ),
                ],
              ),
            ),

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
                        width: _isCollapsed ? 48 : 0,
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

  Widget _buildCollapseButton(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _toggleCollapse,
        borderRadius: BorderRadius.circular(6),
        child: Container(
          padding: const EdgeInsetsDirectional.all(6),
          decoration: BoxDecoration(
            border: Border.all(
              color: context.onSurface.addOpacity(0.2),
            ),
            borderRadius: BorderRadius.circular(6),
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

  Widget _buildCollapsedSidebar(
      BuildContext context, SelectionCubit cubit) {
    return Container(
      decoration: BoxDecoration(
        color: context.isDark
            ? Colors.black.addOpacity(0.3)
            : Colors.grey.shade100,
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
          ),
          const SizedBox(height: 24),
          if (cubit.combinedContent.isNotEmpty) ...[
            IconButton(
              onPressed: () =>
                  _copyToClipboard(context, cubit.combinedContent),
              icon: const Icon(Icons.copy),
              tooltip: 'Copy content',
            ),
            const SizedBox(height: 16),
            RotatedBox(
              quarterTurns: -1,
              child: Text(
                '${cubit.selectedFilesCount} files',
                style: context.labelSmall?.copyWith(
                  color: context.onSurface.addOpacity(0.6),
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
          child: MonacoEditorEmbedded(
            bridge: _monacoBridge,
            onReady: () async {
              // Editor is ready, ensure content is set after a small delay
              await 100.millisecondsDelay();
              await _monacoBridge.setContent(cubit.combinedContent);
            },
          ),
        ),

        // Info bar with controls
        MonacoEditorInfoBar(
          bridge: _monacoBridge,
          onCopy: () => _copyToClipboard(context, cubit.combinedContent),
          onSettings: () => _showEditorSettings(context),
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
            padding: const EdgeInsetsDirectional.all(24),
            decoration: BoxDecoration(
              color: context.primary.addOpacity(0.05),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.merge_type_rounded,
              size: 64,
              color: context.primary.addOpacity(0.3),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Combined Content Preview',
            style: context.titleLarge?.copyWith(
              color: context.onSurface.addOpacity(0.8),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Select files and load their content to see the combined result here',
            textAlign: TextAlign.center,
            style: context.bodyMedium?.copyWith(
              color: context.onSurface.addOpacity(0.6),
            ),
          ),
          const SizedBox(height: 32),

          // Quick tips
          Container(
            padding: const EdgeInsetsDirectional.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  context.primary.addOpacity(0.05),
                  context.primary.addOpacity(0.02),
                ],
                begin: AlignmentDirectional.topStart,
                end: AlignmentDirectional.bottomEnd,
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: context.primary.addOpacity(0.2),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.lightbulb_outline,
                      size: 20,
                      color: context.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Quick Tips',
                      style: context.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: context.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _buildTip(
                  context,
                  '• Drag and drop files or folders directly onto the app',
                ),
                _buildTip(
                  context,
                  '• Use the action buttons to load, copy, or save content',
                ),
                _buildTip(
                  context,
                  '• Toggle file selection to customize your collection',
                ),
                _buildTip(
                  context,
                  '• Line numbers help navigate large combined files',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTip(BuildContext context, String text) {
    return Padding(
      padding: const EdgeInsetsDirectional.only(bottom: 4),
      child: Text(
        text,
        style: context.bodySmall?.copyWith(
          color: context.onSurface.addOpacity(0.7),
          height: 1.5,
        ),
      ),
    );
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

  Future<void> _showEditorSettings(BuildContext context) async {
    final newSettings = await EditorSettingsDialog.show(
      context,
      _editorSettings,
    );

    if (newSettings != null && mounted) {
      setState(() {
        _editorSettings = newSettings;
      });

      // Apply new settings to Monaco bridge
      await _monacoBridge.updateOptions(
        fontSize: newSettings.fontSize,
        wordWrap: newSettings.wordWrap,
        showLineNumbers: newSettings.showLineNumbers,
      );
    }
  }
}
