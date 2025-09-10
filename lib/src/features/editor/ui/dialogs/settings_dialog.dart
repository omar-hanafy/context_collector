import 'package:flutter/material.dart';
import 'package:flutter_monaco/flutter_monaco.dart';

import '../../data/settings_service.dart';
import 'settings_dialog_widgets.dart';

/// Data model for a toggle setting
class _ToggleSetting {
  const _ToggleSetting({
    required this.title,
    required this.getValue,
    required this.onChanged,
  });

  final String title;
  final bool Function(EditorOptions options) getValue;
  final EditorOptions Function(EditorOptions options, bool value) onChanged;
}

/// Simplified settings dialog for EditorOptions
class EditorSettingsDialog extends StatefulWidget {
  const EditorSettingsDialog({
    required this.options,
    super.key,
  });

  final EditorOptions options;

  static Future<EditorOptions?> show(
    BuildContext context,
    EditorOptions currentOptions,
  ) async {
    return showDialog<EditorOptions>(
      context: context,
      barrierDismissible: false,
      builder: (context) => EditorSettingsDialog(options: currentOptions),
    );
  }

  @override
  State<EditorSettingsDialog> createState() => _EditorSettingsDialogState();
}

class _EditorSettingsDialogState extends State<EditorSettingsDialog> {
  late EditorOptions _options;
  late TextEditingController _fontSizeController;
  late TextEditingController _tabSizeController;

  // Data-driven list for feature toggles
  static final List<_ToggleSetting> _featureToggles = [
    _ToggleSetting(
      title: 'Show Minimap',
      getValue: (o) => o.minimap,
      onChanged: (o, v) => o.copyWith(minimap: v),
    ),
    _ToggleSetting(
      title: 'Show Line Numbers',
      getValue: (o) => o.lineNumbers,
      onChanged: (o, v) => o.copyWith(lineNumbers: v),
    ),
    _ToggleSetting(
      title: 'Bracket Pair Colorization',
      getValue: (o) => o.bracketPairColorization,
      onChanged: (o, v) => o.copyWith(bracketPairColorization: v),
    ),
    _ToggleSetting(
      title: 'Format on Paste',
      getValue: (o) => o.formatOnPaste,
      onChanged: (o, v) => o.copyWith(formatOnPaste: v),
    ),
    _ToggleSetting(
      title: 'Format on Type',
      getValue: (o) => o.formatOnType,
      onChanged: (o, v) => o.copyWith(formatOnType: v),
    ),
    _ToggleSetting(
      title: 'Mouse Wheel Zoom',
      getValue: (o) => o.mouseWheelZoom,
      onChanged: (o, v) => o.copyWith(mouseWheelZoom: v),
    ),
    _ToggleSetting(
      title: 'Read Only',
      getValue: (o) => o.readOnly,
      onChanged: (o, v) => o.copyWith(readOnly: v),
    ),
  ];

  @override
  void initState() {
    super.initState();
    _options = widget.options;
    _fontSizeController = TextEditingController(
      text: _options.fontSize.toString(),
    );
    _tabSizeController = TextEditingController(
      text: _options.tabSize.toString(),
    );
  }

  @override
  void dispose() {
    _fontSizeController.dispose();
    _tabSizeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          Icon(
            Icons.settings_outlined,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: 12),
          const Text('Editor Settings'),
        ],
      ),
      content: SizedBox(
        width: 500,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Theme Section
              const SectionTitle('Appearance'),
              const SizedBox(height: 8),
              DropdownTile(
                label: 'Theme',
                value: _options.theme.id,
                items: MonacoTheme.values.map((t) => t.id).toList(),
                onChanged: (value) => setState(() {
                  _options = _options.copyWith(
                    theme: MonacoTheme.fromId(value),
                  );
                }),
              ),
              const SizedBox(height: 16),

              // Font Settings
              const SectionTitle('Font'),
              const SizedBox(height: 8),
              NumberField(
                label: 'Font Size',
                controller: _fontSizeController,
                onChanged: (value) {
                  final size = double.tryParse(value);
                  if (size != null && size >= 8 && size <= 48) {
                    setState(() {
                      _options = _options.copyWith(fontSize: size);
                    });
                  }
                },
              ),
              const SizedBox(height: 8),
              DropdownTile(
                label: 'Font Family',
                value: _options.fontFamily,
                items: MonacoFont.all,
                onChanged: (value) => setState(() {
                  _options = _options.copyWith(fontFamily: value);
                }),
                isExpanded: true,
              ),
              const SizedBox(height: 16),

              // Editor Settings
              const SectionTitle('Editor'),
              const SizedBox(height: 8),
              NumberField(
                label: 'Tab Size',
                controller: _tabSizeController,
                onChanged: (value) {
                  final size = int.tryParse(value);
                  if (size != null && size >= 1 && size <= 8) {
                    setState(() {
                      _options = _options.copyWith(tabSize: size);
                    });
                  }
                },
              ),
              const SizedBox(height: 8),
              SwitchListTile(
                title: const Text('Word Wrap'),
                value: _options.wordWrap,
                onChanged: (value) => setState(() {
                  _options = _options.copyWith(wordWrap: value);
                }),
                dense: true,
              ),
              const SizedBox(height: 16),

              // Common Toggles - Data-driven approach
              const SectionTitle('Features'),
              const SizedBox(height: 8),
              ..._featureToggles.map((setting) {
                return SwitchListTile(
                  title: Text(setting.title),
                  value: setting.getValue(_options),
                  onChanged: (value) => setState(() {
                    _options = setting.onChanged(_options, value);
                  }),
                  dense: true,
                );
              }),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            // Reset to defaults
            setState(() {
              _options = const EditorOptions();
              _fontSizeController.text = '14';
              _tabSizeController.text = '4';
            });
          },
          child: const Text('Reset'),
        ),
        const Spacer(),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () async {
            await EditorSettingsService.save(_options);
            if (mounted) {
              Navigator.of(context).pop(_options);
            }
          },
          child: const Text('Apply'),
        ),
      ],
    );
  }
}
