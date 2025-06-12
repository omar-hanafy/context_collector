import 'package:context_collector/context_collector.dart';
import 'package:flutter_helper_utils/flutter_helper_utils.dart';
import 'package:flutter/material.dart';

/// Keybindings settings tab
class KeybindingsTab extends StatelessWidget {
  const KeybindingsTab({
    required this.settings,
    required this.onSettingsChanged,
    required this.customKeybindingPresets,
    super.key,
  });

  final EditorSettings settings;
  final ValueChanged<EditorSettings> onSettingsChanged;
  final List<KeybindingPreset> customKeybindingPresets;

  @override
  Widget build(BuildContext context) {
    final allPresets = KeybindingManager.getAllPresets(
      customPresets: customKeybindingPresets,
    );

    return SingleChildScrollView(
      padding: const EdgeInsetsDirectional.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SettingsSectionHeader(title: 'Keybinding Preset'),
          const SizedBox(height: 16),
          _buildPresetSelection(context, allPresets),
          const SizedBox(height: 32),
          const SettingsSectionHeader(title: 'Popular Shortcuts'),
          const SizedBox(height: 16),
          _buildShortcutsPreview(context),
        ],
      ),
    );
  }

  Widget _buildPresetSelection(
    BuildContext context,
    List<KeybindingPreset> allPresets,
  ) {
    return Container(
      padding: const EdgeInsetsDirectional.all(16),
      decoration: BoxDecoration(
        color: context.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: context.onSurface.addOpacity(0.1),
        ),
      ),
      child: Column(
        children: [
          for (final preset in allPresets) ...[
            RadioListTile<KeybindingPresetEnum>(
              title: Text(
                preset.name,
                style: context.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
              subtitle: preset.description != null
                  ? Text(
                      preset.description!,
                      style: context.bodySmall?.copyWith(
                        color: context.onSurface.addOpacity(0.6),
                      ),
                    )
                  : null,
              value: KeybindingPresetEnum.values.firstWhere(
                (p) => p.name == preset.id,
                orElse: () => KeybindingPresetEnum.custom,
              ),
              groupValue: settings.keybindingPreset,
              onChanged: (value) {
                if (value != null) {
                  onSettingsChanged(settings.copyWith(keybindingPreset: value));
                }
              },
              activeColor: context.primary,
            ),
            if (preset != allPresets.last)
              Divider(
                color: context.onSurface.addOpacity(0.1),
                height: 1,
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildShortcutsPreview(BuildContext context) {
    final preset = KeybindingManager.findPresetById(
      settings.keybindingPreset.name,
    );
    if (preset == null) return const SizedBox.shrink();

    final popularShortcuts = preset.keybindings.take(10).toList();

    return Container(
      padding: const EdgeInsetsDirectional.all(16),
      decoration: BoxDecoration(
        color: context.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: context.onSurface.addOpacity(0.1),
        ),
      ),
      child: Column(
        children: [
          for (final shortcut in popularShortcuts) ...[
            ShortcutRow(
              description: shortcut.description ?? shortcut.command,
              keyBinding: shortcut.key,
            ),
            if (shortcut != popularShortcuts.last)
              Divider(
                color: context.onSurface.addOpacity(0.1),
                height: 16,
              ),
          ],
        ],
      ),
    );
  }
}

/// Widget for displaying a single keyboard shortcut
class ShortcutRow extends StatelessWidget {
  const ShortcutRow({
    required this.description,
    required this.keyBinding,
    super.key,
  });

  final String description;
  final String keyBinding;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            description,
            style: context.bodyMedium,
          ),
        ),
        KeyBindingChip(keyBinding: keyBinding),
      ],
    );
  }
}

/// Widget for displaying a keyboard shortcut in a chip
class KeyBindingChip extends StatelessWidget {
  const KeyBindingChip({
    required this.keyBinding,
    super.key,
  });

  final String keyBinding;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsetsDirectional.symmetric(
        horizontal: 8,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: context.onSurface.addOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        keyBinding,
        style: context.labelSmall?.copyWith(
          fontFamily: 'monospace',
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
