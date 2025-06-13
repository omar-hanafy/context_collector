import 'package:context_collector/context_collector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_helper_utils/flutter_helper_utils.dart';

/// Editor behavior settings tab
class EditorTab extends StatelessWidget {
  const EditorTab({
    required this.settings,
    required this.tabSizeController,
    required this.wordWrapColumnController,
    required this.tabSizeFocus,
    required this.wordWrapColumnFocus,
    required this.onSettingsChanged,
    super.key,
  });

  final EditorSettings settings;
  final TextEditingController tabSizeController;
  final TextEditingController wordWrapColumnController;
  final FocusNode tabSizeFocus;
  final FocusNode wordWrapColumnFocus;
  final ValueChanged<EditorSettings> onSettingsChanged;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsetsDirectional.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SettingsSectionHeader(title: 'Text Editing'),
          const SizedBox(height: 16),
          _buildTextEditingOptions(context),
          const SizedBox(height: 32),
          const SettingsSectionHeader(title: 'Auto Features'),
          const SizedBox(height: 16),
          _buildAutoFeatures(context),
          const SizedBox(height: 32),
          const SettingsSectionHeader(title: 'Code Intelligence'),
          const SizedBox(height: 16),
          _buildCodeIntelligence(context),
          const SizedBox(height: 32),
          const SettingsSectionHeader(title: 'Cursor & Selection'),
          const SizedBox(height: 16),
          _buildCursorOptions(context),
        ],
      ),
    );
  }

  Widget _buildTextEditingOptions(BuildContext context) {
    return Column(
      children: [
        SettingsDropdownField<WordWrap>(
          label: 'Word Wrap',
          value: settings.wordWrap,
          items: WordWrap.values,
          itemBuilder: (wrap) => wrap.name.toTitle,
          onChanged: (value) {
            if (value != null) {
              onSettingsChanged(settings.copyWith(wordWrap: value));
            }
          },
        ),
        if (settings.wordWrap == WordWrap.wordWrapColumn) ...[
          const SizedBox(height: 16),
          SettingsNumberField(
            label: 'Word Wrap Column',
            controller: wordWrapColumnController,
            min: 40,
            max: 200,
            onChanged: (value) {
              if (value != null) {
                onSettingsChanged(
                  settings.copyWith(wordWrapColumn: value.toInt()),
                );
              }
            },
          ),
        ],
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: SettingsNumberField(
                label: 'Tab Size',
                controller: tabSizeController,
                min: EditorConstants.minTabSize.toDouble(),
                max: EditorConstants.maxTabSize.toDouble(),
                onChanged: (value) {
                  if (value != null) {
                    onSettingsChanged(
                      settings.copyWith(tabSize: value.toInt()),
                    );
                  }
                },
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: SettingsSwitchTile(
                title: 'Insert Spaces',
                subtitle: 'Use spaces instead of tabs',
                value: settings.insertSpaces,
                onChanged: (value) {
                  onSettingsChanged(settings.copyWith(insertSpaces: value));
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAutoFeatures(BuildContext context) {
    return Column(
      children: [
        SettingsSwitchTile(
          title: 'Format on Save',
          subtitle: 'Automatically format code when saving',
          value: settings.formatOnSave,
          onChanged: (value) {
            onSettingsChanged(settings.copyWith(formatOnSave: value));
          },
        ),
        SettingsSwitchTile(
          title: 'Format on Paste',
          subtitle: 'Automatically format pasted code',
          value: settings.formatOnPaste,
          onChanged: (value) {
            onSettingsChanged(settings.copyWith(formatOnPaste: value));
          },
        ),
        SettingsSwitchTile(
          title: 'Format on Type',
          subtitle: 'Format code as you type',
          value: settings.formatOnType,
          onChanged: (value) {
            onSettingsChanged(settings.copyWith(formatOnType: value));
          },
        ),
      ],
    );
  }

  Widget _buildCodeIntelligence(BuildContext context) {
    return Column(
      children: [
        SettingsSwitchTile(
          title: 'Quick Suggestions',
          subtitle: 'Show auto-completion suggestions',
          value: settings.quickSuggestions,
          onChanged: (value) {
            onSettingsChanged(settings.copyWith(quickSuggestions: value));
          },
        ),
        SettingsSwitchTile(
          title: 'Parameter Hints',
          subtitle: 'Show parameter hints for functions',
          value: settings.parameterHints,
          onChanged: (value) {
            onSettingsChanged(settings.copyWith(parameterHints: value));
          },
        ),
        SettingsSwitchTile(
          title: 'Hover Information',
          subtitle: 'Show hover information for symbols',
          value: settings.hover,
          onChanged: (value) {
            onSettingsChanged(settings.copyWith(hover: value));
          },
        ),
      ],
    );
  }

  Widget _buildCursorOptions(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: SettingsDropdownField<CursorBlinking>(
            label: 'Cursor Blinking',
            value: settings.cursorBlinking,
            items: CursorBlinking.values,
            itemBuilder: (blinking) => blinking.name.toTitle,
            onChanged: (value) {
              if (value != null) {
                onSettingsChanged(settings.copyWith(cursorBlinking: value));
              }
            },
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: SettingsDropdownField<CursorStyle>(
            label: 'Cursor Style',
            value: settings.cursorStyle,
            items: CursorStyle.values,
            itemBuilder: (style) => style.name.toTitle,
            onChanged: (value) {
              if (value != null) {
                onSettingsChanged(settings.copyWith(cursorStyle: value));
              }
            },
          ),
        ),
      ],
    );
  }
}
