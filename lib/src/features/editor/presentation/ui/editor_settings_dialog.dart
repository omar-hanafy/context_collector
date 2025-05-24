import 'package:flutter/material.dart';

import '../../../../shared/theme/extensions.dart';
import '../../domain/editor_settings.dart';

class EditorSettingsDialog extends StatefulWidget {
  const EditorSettingsDialog({
    super.key,
    required this.settings,
  });

  final EditorSettings settings;

  static Future<EditorSettings?> show(
    BuildContext context,
    EditorSettings currentSettings,
  ) async {
    return showDialog<EditorSettings>(
      context: context,
      builder: (context) => EditorSettingsDialog(settings: currentSettings),
    );
  }

  @override
  State<EditorSettingsDialog> createState() => _EditorSettingsDialogState();
}

class _EditorSettingsDialogState extends State<EditorSettingsDialog> {
  late EditorSettings _settings;

  @override
  void initState() {
    super.initState();
    _settings = widget.settings;
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        width: 400,
        padding: const EdgeInsetsDirectional.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.settings_outlined,
                  color: context.primary,
                ),
                const SizedBox(width: 12),
                Text(
                  'Editor Settings',
                  style: context.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Font size
            _buildSectionTitle(context, 'Font Size'),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Slider(
                    value: _settings.fontSize,
                    min: 10,
                    max: 20,
                    divisions: 10,
                    label: '${_settings.fontSize.round()}px',
                    onChanged: (value) {
                      setState(() {
                        _settings = _settings.copyWith(fontSize: value);
                      });
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Container(
                  width: 60,
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
                  child: Text(
                    '${_settings.fontSize.round()}px',
                    style: context.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Preview
            Container(
              padding: const EdgeInsetsDirectional.all(12),
              decoration: BoxDecoration(
                color: context.isDark
                    ? Colors.black.addOpacity(0.3)
                    : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: context.onSurface.addOpacity(0.1),
                ),
              ),
              child: Row(
                children: [
                  if (_settings.showLineNumbers) ...[
                    Text(
                      '1\n2\n3',
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: _settings.fontSize * 0.9,
                        height: 1.4,
                        color: context.onSurface.addOpacity(0.4),
                      ),
                    ),
                    Container(
                      width: 1,
                      height: 50,
                      margin:
                          const EdgeInsetsDirectional.symmetric(horizontal: 12),
                      color: context.onSurface.addOpacity(0.1),
                    ),
                  ],
                  Expanded(
                    child: Text(
                      'Sample text preview\nLine 2 of code\nLine 3 of code',
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: _settings.fontSize,
                        height: 1.4,
                        color: context.onSurface,
                      ),
                      softWrap: _settings.wordWrap,
                      overflow: _settings.wordWrap
                          ? TextOverflow.visible
                          : TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Options
            _buildSectionTitle(context, 'Display Options'),
            const SizedBox(height: 12),

            // Show line numbers
            _buildOptionTile(
              context,
              title: 'Show Line Numbers',
              subtitle: 'Display line numbers on the left side',
              value: _settings.showLineNumbers,
              onChanged: (value) {
                setState(() {
                  _settings = _settings.copyWith(showLineNumbers: value);
                });
              },
            ),

            // Word wrap
            _buildOptionTile(
              context,
              title: 'Word Wrap',
              subtitle: 'Wrap long lines instead of horizontal scrolling',
              value: _settings.wordWrap,
              onChanged: (value) {
                setState(() {
                  _settings = _settings.copyWith(wordWrap: value);
                });
              },
            ),

            const SizedBox(height: 24),

            // Actions
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: () async {
                    await _settings.save();
                    if (mounted) {
                      Navigator.of(context).pop(_settings);
                    }
                  },
                  child: const Text('Apply'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Text(
      title,
      style: context.titleSmall?.copyWith(
        fontWeight: FontWeight.w600,
        color: context.onSurface.addOpacity(0.8),
      ),
    );
  }

  Widget _buildOptionTile(
    BuildContext context, {
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsetsDirectional.only(bottom: 8),
      child: Material(
        color: Colors.transparent,
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
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: context.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        subtitle,
                        style: context.labelSmall?.copyWith(
                          color: context.onSurface.addOpacity(0.6),
                        ),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: value,
                  onChanged: onChanged,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
