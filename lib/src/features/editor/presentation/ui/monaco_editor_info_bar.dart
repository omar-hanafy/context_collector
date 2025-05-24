import 'package:flutter/material.dart';

import '../../../../shared/theme/extensions.dart';
import '../../bridge/monaco_bridge.dart';
import '../../domain/editor_settings.dart';

/// Enhanced info bar for Monaco editor with comprehensive controls
class MonacoEditorInfoBar extends StatefulWidget {
  const MonacoEditorInfoBar({
    super.key,
    required this.bridge,
    required this.onCopy,
    required this.onSettings,
  });

  final MonacoBridge bridge;
  final VoidCallback onCopy;
  final VoidCallback onSettings;

  @override
  State<MonacoEditorInfoBar> createState() => _MonacoEditorInfoBarState();
}

class _MonacoEditorInfoBarState extends State<MonacoEditorInfoBar> {
  Map<String, dynamic> _editorStats = {};

  @override
  void initState() {
    super.initState();
    _loadEditorStats();
  }

  Future<void> _loadEditorStats() async {
    if (widget.bridge.isReady) {
      final stats = await widget.bridge.getEditorStats();
      if (mounted) {
        setState(() {
          _editorStats = stats;
        });
      }
    }
  }

  // Available languages from the enhanced bridge
  final List<Map<String, String>> _supportedLanguages =
      MonacoBridge.availableLanguages;

  // Available themes from the theme manager
  final List<String> _availableThemes = MonacoBridge.availableThemes;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.bridge,
      builder: (context, _) {
        if (!widget.bridge.isReady) {
          return _buildLoadingBar(context);
        }

        final settings = widget.bridge.settings;
        final String detectedRawLanguage =
            _editorStats['language'] as String? ?? 'plaintext';

        // Ensure currentLanguage is always a value present in the dropdown items
        final String currentLanguage = _supportedLanguages
                .any((lang) => lang['value'] == detectedRawLanguage)
            ? detectedRawLanguage
            : (_supportedLanguages.isNotEmpty
                ? _supportedLanguages.first['value']!
                : 'plaintext');

        return Container(
          margin: const EdgeInsetsDirectional.only(top: 8),
          padding: const EdgeInsetsDirectional.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                context.primary.addOpacity(0.05),
                context.primary.addOpacity(0.02),
              ],
              begin: AlignmentDirectional.centerStart,
              end: AlignmentDirectional.centerEnd,
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: context.primary.addOpacity(0.1),
            ),
          ),
          child: Column(
            children: [
              // Main controls row
              Row(
                children: [
                  // Language selector
                  _buildLanguageSelector(context, currentLanguage),
                  const SizedBox(width: 16),

                  // Theme selector
                  _buildThemeSelector(context, settings.theme),
                  const SizedBox(width: 16),

                  // Editor stats
                  _buildEditorStats(context),

                  const Spacer(),

                  // Quick toggles
                  _buildQuickToggles(context, settings),

                  // Divider
                  Container(
                    height: 28,
                    width: 1,
                    margin:
                        const EdgeInsetsDirectional.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.transparent,
                          context.onSurface.addOpacity(0.2),
                          Colors.transparent,
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),

                  // Action buttons
                  _buildActionButtons(context),
                ],
              ),

              // Secondary controls row (if needed)
              if (_editorStats.isNotEmpty) ...[
                const SizedBox(height: 8),
                _buildSecondaryControls(context),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildLoadingBar(BuildContext context) {
    return Container(
      margin: const EdgeInsetsDirectional.only(top: 8),
      padding: const EdgeInsetsDirectional.symmetric(
        horizontal: 16,
        vertical: 12,
      ),
      decoration: BoxDecoration(
        color: context.onSurface.addOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: context.onSurface.addOpacity(0.1),
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: context.primary,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            'Initializing Monaco Editor...',
            style: context.bodyMedium?.copyWith(
              color: context.onSurface.addOpacity(0.6),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLanguageSelector(BuildContext context, String currentLanguage) {
    final languageName = _supportedLanguages.firstWhere(
          (lang) => lang['value'] == currentLanguage,
          orElse: () =>
              {'value': currentLanguage, 'text': currentLanguage.toUpperCase()},
        )['text'] ??
        currentLanguage.toUpperCase();

    return _buildDropdownSelector(
      context,
      icon: Icons.code,
      label: 'Language',
      value: currentLanguage,
      displayValue: languageName,
      items: _supportedLanguages
          .map((lang) => DropdownMenuItem(
                value: lang['value'],
                child: Text(lang['text']!),
              ))
          .toList(),
      onChanged: (value) async {
        if (value != null && value != currentLanguage) {
          await widget.bridge.setLanguage(value);
          // Refresh stats
          await _loadEditorStats();
        }
      },
    );
  }

  Widget _buildThemeSelector(BuildContext context, String currentTheme) {
    final themeName = _getThemeDisplayName(currentTheme);

    return _buildDropdownSelector(
      context,
      icon: Icons.palette,
      label: 'Theme',
      value: currentTheme,
      displayValue: themeName,
      items: _availableThemes
          .map((theme) => DropdownMenuItem(
                value: theme,
                child: Text(_getThemeDisplayName(theme)),
              ))
          .toList(),
      onChanged: (value) async {
        if (value != null && value != currentTheme) {
          final newSettings = widget.bridge.settings.copyWith(theme: value);
          await widget.bridge.updateSettings(newSettings);
        }
      },
    );
  }

  String _getThemeDisplayName(String themeId) {
    switch (themeId) {
      case 'vs':
        return 'Light';
      case 'vs-dark':
        return 'Dark';
      case 'hc-black':
        return 'High Contrast';
      case 'one-dark-pro':
        return 'One Dark Pro';
      case 'one-dark-pro-transparent':
        return 'One Dark Pro Transparent';
      default:
        return themeId
            .split('-')
            .map((word) => word[0].toUpperCase() + word.substring(1))
            .join(' ');
    }
  }

  Widget _buildEditorStats(BuildContext context) {
    final lineCount = _editorStats['lineCount'] as int? ?? 0;
    final characterCount = _editorStats['characterCount'] as int? ?? 0;
    final hasSelection = _editorStats['hasSelection'] as bool? ?? false;

    return Container(
      padding: const EdgeInsetsDirectional.symmetric(
        horizontal: 12,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: context.onSurface.addOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: context.onSurface.addOpacity(0.1),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.analytics_outlined,
            size: 14,
            color: context.onSurface.addOpacity(0.6),
          ),
          const SizedBox(width: 6),
          Text(
            '$lineCount lines',
            style: context.labelSmall?.copyWith(
              color: context.onSurface.addOpacity(0.8),
              fontWeight: FontWeight.w500,
            ),
          ),
          if (characterCount > 0) ...[
            Text(
              ' • ',
              style: context.labelSmall?.copyWith(
                color: context.onSurface.addOpacity(0.4),
              ),
            ),
            Text(
              _formatCharacterCount(characterCount),
              style: context.labelSmall?.copyWith(
                color: context.onSurface.addOpacity(0.6),
              ),
            ),
          ],
          if (hasSelection) ...[
            const SizedBox(width: 8),
            Icon(
              Icons.text_fields,
              size: 12,
              color: context.primary,
            ),
          ],
        ],
      ),
    );
  }

  String _formatCharacterCount(int count) {
    if (count < 1000) return '${count}c';
    if (count < 1000000) return '${(count / 1000).toStringAsFixed(1)}K';
    return '${(count / 1000000).toStringAsFixed(1)}M';
  }

  Widget _buildQuickToggles(BuildContext context, EditorSettings settings) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildToggleButton(
          context,
          icon: Icons.wrap_text,
          tooltip: settings.wordWrap != WordWrap.off
              ? 'Disable word wrap'
              : 'Enable word wrap',
          isActive: settings.wordWrap != WordWrap.off,
          onPressed: () async {
            final newWrap =
                settings.wordWrap == WordWrap.off ? WordWrap.on : WordWrap.off;
            final newSettings = settings.copyWith(wordWrap: newWrap);
            await widget.bridge.updateSettings(newSettings);
          },
        ),
        const SizedBox(width: 6),
        _buildToggleButton(
          context,
          icon: Icons.format_list_numbered,
          tooltip: settings.showLineNumbers
              ? 'Hide line numbers'
              : 'Show line numbers',
          isActive: settings.showLineNumbers,
          onPressed: () async {
            final newSettings = settings.copyWith(
              showLineNumbers: !settings.showLineNumbers,
            );
            await widget.bridge.updateSettings(newSettings);
          },
        ),
        const SizedBox(width: 6),
        _buildToggleButton(
          context,
          icon: settings.showMinimap ? Icons.map : Icons.map_outlined,
          tooltip: settings.showMinimap ? 'Hide minimap' : 'Show minimap',
          isActive: settings.showMinimap,
          onPressed: () async {
            final newSettings = settings.copyWith(
              showMinimap: !settings.showMinimap,
            );
            await widget.bridge.updateSettings(newSettings);
          },
        ),
        const SizedBox(width: 6),
        _buildToggleButton(
          context,
          icon: settings.readOnly ? Icons.edit_off : Icons.edit,
          tooltip: settings.readOnly ? 'Enable editing' : 'Make read-only',
          isActive: !settings.readOnly,
          onPressed: () async {
            final newSettings = settings.copyWith(
              readOnly: !settings.readOnly,
            );
            await widget.bridge.updateSettings(newSettings);
          },
        ),
      ],
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildActionButton(
          context,
          icon: Icons.search,
          tooltip: 'Find (Ctrl/Cmd+F)',
          onPressed: () => widget.bridge.find(),
        ),
        const SizedBox(width: 6),
        _buildActionButton(
          context,
          icon: Icons.find_replace,
          tooltip: 'Find & Replace (Ctrl/Cmd+H)',
          onPressed: () => widget.bridge.findAndReplace(),
        ),
        const SizedBox(width: 6),
        _buildActionButton(
          context,
          icon: Icons.format_align_left,
          tooltip: 'Format document',
          onPressed: () => widget.bridge.format(),
        ),
        const SizedBox(width: 6),
        _buildActionButton(
          context,
          icon: Icons.vertical_align_top,
          tooltip: 'Go to top',
          onPressed: () => widget.bridge.scrollToTop(),
        ),
        const SizedBox(width: 6),
        _buildActionButton(
          context,
          icon: Icons.vertical_align_bottom,
          tooltip: 'Go to bottom',
          onPressed: () => widget.bridge.scrollToBottom(),
        ),
        const SizedBox(width: 6),
        _buildActionButton(
          context,
          icon: Icons.copy,
          tooltip: 'Copy content',
          onPressed: widget.onCopy,
        ),
        const SizedBox(width: 6),
        _buildActionButton(
          context,
          icon: Icons.tune,
          tooltip: 'Editor settings',
          onPressed: widget.onSettings,
          isPrimary: true,
        ),
      ],
    );
  }

  Widget _buildSecondaryControls(BuildContext context) {
    return Row(
      children: [
        // Quick font size controls
        _buildQuickFontControls(context),

        const Spacer(),

        // Advanced actions
        _buildAdvancedActions(context),
      ],
    );
  }

  Widget _buildQuickFontControls(BuildContext context) {
    final settings = widget.bridge.settings;

    return Container(
      padding: const EdgeInsetsDirectional.symmetric(
        horizontal: 8,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: context.onSurface.addOpacity(0.05),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.text_fields,
            size: 12,
            color: context.onSurface.addOpacity(0.6),
          ),
          const SizedBox(width: 6),
          IconButton(
            onPressed: settings.fontSize > 8
                ? () async {
                    final newSettings =
                        settings.copyWith(fontSize: settings.fontSize - 1);
                    await widget.bridge.updateSettings(newSettings);
                  }
                : null,
            icon: const Icon(Icons.text_decrease),
            iconSize: 14,
            tooltip: 'Decrease font size',
            style: IconButton.styleFrom(
              minimumSize: const Size(24, 24),
              padding: EdgeInsets.zero,
            ),
          ),
          Container(
            width: 32,
            alignment: Alignment.center,
            child: Text(
              '${settings.fontSize.round()}',
              style: context.labelSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          IconButton(
            onPressed: settings.fontSize < 32
                ? () async {
                    final newSettings =
                        settings.copyWith(fontSize: settings.fontSize + 1);
                    await widget.bridge.updateSettings(newSettings);
                  }
                : null,
            icon: const Icon(Icons.text_increase),
            iconSize: 14,
            tooltip: 'Increase font size',
            style: IconButton.styleFrom(
              minimumSize: const Size(24, 24),
              padding: EdgeInsets.zero,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdvancedActions(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildMiniActionButton(
          context,
          icon: Icons.unfold_less,
          tooltip: 'Fold all',
          onPressed: () => widget.bridge.foldAll(),
        ),
        const SizedBox(width: 4),
        _buildMiniActionButton(
          context,
          icon: Icons.unfold_more,
          tooltip: 'Unfold all',
          onPressed: () => widget.bridge.unfoldAll(),
        ),
        const SizedBox(width: 4),
        _buildMiniActionButton(
          context,
          icon: Icons.comment,
          tooltip: 'Toggle comment',
          onPressed: () => widget.bridge.toggleLineComment(),
        ),
        const SizedBox(width: 4),
        _buildMiniActionButton(
          context,
          icon: Icons.select_all,
          tooltip: 'Select all',
          onPressed: () => widget.bridge.selectAll(),
        ),
      ],
    );
  }

  Widget _buildDropdownSelector<T>(
    BuildContext context, {
    required IconData icon,
    required String label,
    required T value,
    String? displayValue,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?> onChanged,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: context.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: context.onSurface.addOpacity(0.15),
        ),
        boxShadow: [
          BoxShadow(
            color: context.onSurface.addOpacity(0.05),
            offset: const Offset(0, 1),
            blurRadius: 2,
          ),
        ],
      ),
      padding: const EdgeInsetsDirectional.symmetric(
        horizontal: 12,
        vertical: 6,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 16,
            color: context.primary,
          ),
          const SizedBox(width: 8),
          Text(
            '$label:',
            style: context.labelSmall?.copyWith(
              color: context.onSurface.addOpacity(0.7),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 8),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 120),
            child: DropdownButton<T>(
              value: value,
              items: items,
              onChanged: onChanged,
              underline: const SizedBox(),
              borderRadius: BorderRadius.circular(8),
              isDense: true,
              style: context.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: context.onSurface,
              ),
              hint: Text(
                displayValue ?? value.toString(),
                style: context.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: context.onSurface,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(
    BuildContext context, {
    required IconData icon,
    required String tooltip,
    VoidCallback? onPressed,
    bool isPrimary = false,
  }) {
    return IconButton(
      onPressed: onPressed,
      icon: Icon(icon),
      iconSize: 18,
      tooltip: tooltip,
      style: IconButton.styleFrom(
        backgroundColor: isPrimary
            ? context.primary.addOpacity(0.15)
            : context.primary.addOpacity(0.08),
        foregroundColor: context.primary,
        padding: const EdgeInsetsDirectional.all(8),
        minimumSize: const Size(36, 36),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  Widget _buildMiniActionButton(
    BuildContext context, {
    required IconData icon,
    required String tooltip,
    VoidCallback? onPressed,
  }) {
    return IconButton(
      onPressed: onPressed,
      icon: Icon(icon),
      iconSize: 14,
      tooltip: tooltip,
      style: IconButton.styleFrom(
        backgroundColor: context.onSurface.addOpacity(0.05),
        foregroundColor: context.onSurface.addOpacity(0.7),
        padding: const EdgeInsetsDirectional.all(4),
        minimumSize: const Size(24, 24),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
        ),
      ),
    );
  }

  Widget _buildToggleButton(
    BuildContext context, {
    required IconData icon,
    required String tooltip,
    required bool isActive,
    VoidCallback? onPressed,
  }) {
    return IconButton(
      onPressed: onPressed,
      icon: Icon(icon),
      iconSize: 16,
      tooltip: tooltip,
      style: IconButton.styleFrom(
        backgroundColor: isActive
            ? context.primary.addOpacity(0.15)
            : context.onSurface.addOpacity(0.05),
        foregroundColor:
            isActive ? context.primary : context.onSurface.addOpacity(0.6),
        padding: const EdgeInsetsDirectional.all(6),
        minimumSize: const Size(32, 32),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(6),
        ),
      ),
    );
  }
}
