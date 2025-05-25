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
          padding: const EdgeInsetsDirectional.symmetric(horizontal: 8),
          decoration: const BoxDecoration(
            color: Colors.transparent,
          ),
          child: Row(
            // Simplified to a single Row for controls
            children: [
              // Concise Language selector
              _buildConciseDropdown<String>(
                context: context,
                icon: Icons.translate,
                // Changed icon for languages
                value: currentLanguage,
                items: _supportedLanguages
                    .map((lang) => DropdownMenuItem<String>(
                          value: lang['value'],
                          child: Text(lang['text']!,
                              style: context.labelMedium), // For the list items
                        ))
                    .toList(),
                onChanged: (value) async {
                  if (value != null && value != currentLanguage) {
                    await widget.bridge.setLanguage(value);
                    await _loadEditorStats();
                  }
                },
                getShortDisplayName: (val) {
                  final selectedLang = _supportedLanguages.firstWhere(
                      (lang) => lang['value'] == val,
                      orElse: () => {'text': val.toUpperCase()});
                  return selectedLang['text']!;
                },
                tooltip: 'Select Language',
              ),
              const SizedBox(width: 8),

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
    required String Function(T value) getShortDisplayName, // Added
    String? tooltip,
  }) {
    return Tooltip(
      message: tooltip ?? '',
      child: Container(
        padding:
            const EdgeInsetsDirectional.symmetric(horizontal: 8, vertical: 4),
        // Adjusted padding
        decoration: BoxDecoration(
          color: context.onSurface.addOpacity(0.05),
          borderRadius: BorderRadius.circular(8),
        ),
        // Removed fixed maxWidth from here to allow DropdownButton to size more intrinsically
        // It will be constrained by the parent Row if necessary.
        child: DropdownButtonHideUnderline(
          child: DropdownButton<T>(
            icon: Icon(Icons.arrow_drop_down,
                size: 20, color: context.onSurface.addOpacity(0.7)),
            // Slightly larger icon
            isDense: true,
            value: value,
            items: items,
            onChanged: onChanged,
            selectedItemBuilder: (context) {
              return items.map((DropdownMenuItem<T> item) {
                // Ensure item is typed
                // This Row is what's shown in the button when an item is selected.
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(icon,
                        size: 16,
                        color:
                            context.primary), // Main icon for the dropdown type
                    const SizedBox(width: 6),
                    Flexible(
                      fit: FlexFit.loose,
                      child: Text(
                        getShortDisplayName(value),
                        // Display short name of the *selected* value
                        style: context.labelSmall?.copyWith(
                            color: context.onSurface.addOpacity(0.9)),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
                  ],
                );
              }).toList();
            },
            hint: Row(
              // Fallback hint if value is null (should not happen often here)
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 16, color: context.onSurface.addOpacity(0.7)),
                const SizedBox(width: 6),
                Text('Select...',
                    style: context.labelSmall, overflow: TextOverflow.ellipsis),
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
