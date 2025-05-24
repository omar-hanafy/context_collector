import 'package:flutter/material.dart';

import '../../../../shared/theme/extensions.dart';
import '../../bridge/monaco_bridge.dart';

/// Enhanced info bar for Monaco editor with better controls
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
  final List<String> _supportedLanguages = [
    'plaintext',
    'dart',
    'html',
    'css',
    'javascript',
    'typescript',
    'json',
    'yaml',
    'markdown',
    'python',
    'shell',
    'xml',
    'sql',
  ];

  final List<({String value, String label})> _themes = [
    (value: 'vs', label: 'Light'),
    (value: 'vs-dark', label: 'Dark'),
    (value: 'hc-black', label: 'High Contrast'),
  ];

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.bridge,
      builder: (context, _) {
        if (!widget.bridge.isReady) {
          return const SizedBox.shrink();
        }

        return Container(
          margin: const EdgeInsetsDirectional.only(top: 8),
          padding: const EdgeInsetsDirectional.symmetric(
            horizontal: 16,
            vertical: 8,
          ),
          decoration: BoxDecoration(
            color: context.isDark
                ? Colors.black.addOpacity(0.3)
                : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: context.onSurface.addOpacity(0.1),
            ),
          ),
          child: Row(
            children: [
              // Language selector
              _buildDropdownSelector(
                context,
                icon: Icons.code,
                label: 'Language',
                value: widget.bridge.language,
                items: _supportedLanguages
                    .map((lang) => DropdownMenuItem(
                          value: lang,
                          child: Text(
                            lang == 'plaintext'
                                ? 'Plain Text'
                                : _capitalize(lang),
                          ),
                        ))
                    .toList(),
                onChanged: (value) {
                  if (value != null) {
                    widget.bridge.setLanguage(value);
                  }
                },
              ),
              const SizedBox(width: 16),

              // Theme selector
              _buildDropdownSelector(
                context,
                icon: Icons.palette,
                label: 'Theme',
                value: widget.bridge.theme,
                items: _themes
                    .map((theme) => DropdownMenuItem(
                          value: theme.value,
                          child: Text(theme.label),
                        ))
                    .toList(),
                onChanged: (value) {
                  if (value != null) {
                    widget.bridge.setTheme(value);
                  }
                },
              ),

              const Spacer(),

              // Quick toggles
              _buildToggleButton(
                context,
                icon: Icons.wrap_text,
                tooltip: widget.bridge.wordWrap
                    ? 'Disable word wrap'
                    : 'Enable word wrap',
                isActive: widget.bridge.wordWrap,
                onPressed: () {
                  widget.bridge.updateOptions(
                    wordWrap: !widget.bridge.wordWrap,
                  );
                },
              ),
              const SizedBox(width: 8),

              _buildToggleButton(
                context,
                icon: Icons.format_list_numbered,
                tooltip: widget.bridge.showLineNumbers
                    ? 'Hide line numbers'
                    : 'Show line numbers',
                isActive: widget.bridge.showLineNumbers,
                onPressed: () {
                  widget.bridge.updateOptions(
                    showLineNumbers: !widget.bridge.showLineNumbers,
                  );
                },
              ),
              const SizedBox(width: 8),

              _buildToggleButton(
                context,
                icon: widget.bridge.readOnly ? Icons.edit_off : Icons.edit,
                tooltip: widget.bridge.readOnly
                    ? 'Enable editing'
                    : 'Disable editing (Read-only)',
                isActive: !widget.bridge.readOnly,
                onPressed: () {
                  widget.bridge.updateOptions(
                    readOnly: !widget.bridge.readOnly,
                  );
                },
              ),
              const SizedBox(width: 8),

              // Divider
              Container(
                height: 24,
                width: 1,
                color: context.onSurface.addOpacity(0.2),
              ),
              const SizedBox(width: 8),

              // Action buttons
              _buildActionButton(
                context,
                icon: Icons.search,
                tooltip: 'Find (Ctrl/Cmd+F)',
                onPressed: () => widget.bridge.find(),
              ),
              const SizedBox(width: 8),

              _buildActionButton(
                context,
                icon: Icons.format_align_left,
                tooltip: 'Format document',
                onPressed: () => widget.bridge.format(),
              ),
              const SizedBox(width: 8),

              _buildActionButton(
                context,
                icon: Icons.vertical_align_top,
                tooltip: 'Scroll to top',
                onPressed: () => widget.bridge.scrollToTop(),
              ),
              const SizedBox(width: 8),

              _buildActionButton(
                context,
                icon: Icons.copy,
                tooltip: 'Copy to clipboard',
                onPressed: widget.onCopy,
              ),
              const SizedBox(width: 8),

              _buildActionButton(
                context,
                icon: Icons.settings,
                tooltip: 'Editor settings',
                onPressed: widget.onSettings,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDropdownSelector<T>(
    BuildContext context, {
    required IconData icon,
    required String label,
    required T value,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?> onChanged,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: context.isDark
            ? Colors.black.addOpacity(0.2)
            : Colors.white.addOpacity(0.9),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: context.onSurface.addOpacity(0.1),
        ),
      ),
      padding: const EdgeInsetsDirectional.symmetric(
        horizontal: 12,
        vertical: 4,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 16,
            color: context.onSurface.addOpacity(0.7),
          ),
          const SizedBox(width: 8),
          Text(
            '$label:',
            style: context.labelSmall?.copyWith(
              color: context.onSurface.addOpacity(0.7),
            ),
          ),
          const SizedBox(width: 8),
          DropdownButton<T>(
            value: value,
            items: items,
            onChanged: onChanged,
            underline: const SizedBox(),
            borderRadius: BorderRadius.circular(8),
            isDense: true,
            style: context.bodySmall?.copyWith(
              fontWeight: FontWeight.w600,
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
  }) {
    return IconButton(
      onPressed: onPressed,
      icon: Icon(icon),
      iconSize: 18,
      tooltip: tooltip,
      style: IconButton.styleFrom(
        backgroundColor: context.primary.addOpacity(0.1),
        foregroundColor: context.primary,
        padding: const EdgeInsetsDirectional.all(6),
        minimumSize: const Size(32, 32),
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
      iconSize: 18,
      tooltip: tooltip,
      style: IconButton.styleFrom(
        backgroundColor: isActive
            ? context.primary.addOpacity(0.2)
            : context.onSurface.addOpacity(0.05),
        foregroundColor:
            isActive ? context.primary : context.onSurface.addOpacity(0.6),
        padding: const EdgeInsetsDirectional.all(6),
        minimumSize: const Size(32, 32),
      ),
    );
  }

  String _capitalize(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
  }
}
