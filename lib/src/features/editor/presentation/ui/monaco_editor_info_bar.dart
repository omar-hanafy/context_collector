import 'package:flutter/material.dart';

import '../../../../shared/theme/extensions.dart';
import '../../bridge/monaco_bridge.dart';

/// Enhanced info bar for Monaco editor with comprehensive controls
class MonacoEditorInfoBar extends StatefulWidget {
  const MonacoEditorInfoBar({
    super.key,
    required this.bridge,
    required this.onCopy,
  });

  final MonacoBridge bridge;
  final VoidCallback onCopy;

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

        final String currentLanguage = _supportedLanguages
                .any((lang) => lang['value'] == detectedRawLanguage)
            ? detectedRawLanguage
            : (_supportedLanguages.isNotEmpty
                ? _supportedLanguages.first['value']!
                : 'plaintext');

        // Theme for concise display
        final String currentThemeName = _getThemeDisplayName(settings.theme);

        return Container(
          margin: const EdgeInsetsDirectional.only(top: 8),
          padding: const EdgeInsetsDirectional.symmetric(
            horizontal: 12, // Reduced padding for a more compact bar
            vertical: 8, // Reduced padding
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
          child: Row(
            // Simplified to a single Row for controls
            children: [
              // Concise Language selector
              _buildConciseDropdown(
                context: context,
                icon: Icons.code,
                value: currentLanguage,
                items: _supportedLanguages
                    .map((lang) => DropdownMenuItem<String>(
                          value: lang['value'],
                          child: Text(lang['text']!, style: context.labelSmall),
                        ))
                    .toList(),
                onChanged: (value) async {
                  if (value != null && value != currentLanguage) {
                    await widget.bridge.setLanguage(value);
                    await _loadEditorStats();
                  }
                },
                tooltip: 'Select Language',
              ),
              const SizedBox(width: 8),

              // Concise Theme selector
              _buildConciseDropdown(
                context: context,
                icon: Icons.palette_outlined,
                value: settings.theme,
                items: _availableThemes
                    .map((theme) => DropdownMenuItem<String>(
                          value: theme,
                          child: Text(_getThemeDisplayName(theme),
                              style: context.labelSmall),
                        ))
                    .toList(),
                onChanged: (value) async {
                  if (value != null && value != settings.theme) {
                    final newSettings =
                        widget.bridge.settings.copyWith(theme: value);
                    await widget.bridge.updateSettings(newSettings);
                  }
                },
                // Displaying only the current theme name or icon
                // child: Text(currentThemeName, style: context.labelMedium?.copyWith(color: context.primary)),
                tooltip: 'Select Theme ($currentThemeName)',
              ),

              const Spacer(), // Pushes actions to the right

              // Action Buttons - unified style
              _buildActionButton(
                context,
                icon: Icons.copy_outlined,
                tooltip: 'Copy Content',
                onPressed: widget.onCopy,
              ),
              _buildActionButton(
                context,
                icon:
                    Icons.format_align_left_outlined, // Or Icons.auto_fix_high
                tooltip: 'Format Content',
                onPressed: () async => widget.bridge.format(),
              ),
              _buildActionButton(
                context,
                icon: Icons.keyboard_arrow_up_outlined,
                tooltip: 'Scroll to Top',
                onPressed: () async => widget.bridge.scrollToTop(),
              ),
              _buildActionButton(
                context,
                icon: Icons.keyboard_arrow_down_outlined,
                tooltip: 'Scroll to Bottom',
                onPressed: () async =>
                    widget.bridge.scrollToBottom(), // New Action
              ),

              // Settings button - REMOVED (now in sidebar)
              // _buildActionButton(
              //   context,
              //   icon: Icons.settings_outlined,
              //   tooltip: 'Editor Settings',
              //   onPressed: widget.onSettings, // This callback is removed
              // ),
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

  // New method for concise dropdowns
  Widget _buildConciseDropdown<T>({
    required BuildContext context,
    required IconData icon,
    required T value,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?> onChanged,
    Widget? child,
    String? tooltip,
  }) {
    return Tooltip(
      message: tooltip ?? '',
      child: Container(
        padding:
            const EdgeInsetsDirectional.symmetric(horizontal: 6, vertical: 4),
        decoration: BoxDecoration(
          color: context.onSurface.addOpacity(0.05),
          borderRadius: BorderRadius.circular(8),
        ),
        constraints:
            const BoxConstraints(maxWidth: 150), // Max width for dropdown
        child: DropdownButtonHideUnderline(
          child: DropdownButton<T>(
            icon: Icon(Icons.arrow_drop_down,
                size: 18, color: context.onSurface.addOpacity(0.6)),
            isDense: true,
            value: value,
            items: items,
            onChanged: onChanged,
            selectedItemBuilder: child != null
                ? (context) {
                    // This part is tricky for dynamic width based on selected item text
                    // For now, let's assume the icon + a short text or just icon is enough.
                    // If child is provided, it's used, otherwise, we show the icon.
                    return items.map((item) {
                      return Align(
                        alignment: AlignmentDirectional.centerStart,
                        child: child ??
                            Icon(icon, size: 18, color: context.primary),
                      );
                    }).toList();
                  }
                : null,
            // If selectedItemBuilder is not used, this is the representation when closed
            // We might want to show icon + current value text here
            hint: child ??
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(icon,
                        size: 16, color: context.primary.addOpacity(0.8)),
                    // Optional: Add a short text representation of the current value if space allows
                    // For example, for theme, the name; for language, its short code.
                  ],
                ),
          ),
        ),
      ),
    );
  }

  // New method for action buttons for unified styling
  Widget _buildActionButton(
    BuildContext context, {
    required IconData icon,
    required String tooltip,
    required VoidCallback? onPressed,
  }) {
    return IconButton(
      icon: Icon(icon, size: 20),
      tooltip: tooltip,
      onPressed: onPressed,
      style: IconButton.styleFrom(
        foregroundColor: context.onSurface.addOpacity(0.7),
        padding: const EdgeInsets.all(10), // Consistent padding
      ),
      iconSize: 20,
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
}
