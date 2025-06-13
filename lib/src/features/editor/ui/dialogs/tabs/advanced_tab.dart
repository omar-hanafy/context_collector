import 'dart:convert';
import 'dart:io';

import 'package:context_collector/context_collector.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_helper_utils/flutter_helper_utils.dart';

/// Advanced settings tab
class AdvancedTab extends StatelessWidget {
  const AdvancedTab({
    required this.settings,
    required this.onSettingsChanged,
    required this.onResetSettings,
    super.key,
  });

  final EditorSettings settings;
  final ValueChanged<EditorSettings> onSettingsChanged;
  final VoidCallback onResetSettings;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsetsDirectional.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SettingsSectionHeader(title: 'Performance'),
          const SizedBox(height: 16),
          _buildPerformanceOptions(context),
          const SizedBox(height: 32),
          const SettingsSectionHeader(title: 'Accessibility'),
          const SizedBox(height: 16),
          _buildAccessibilityOptions(context),
          const SizedBox(height: 32),
          const SettingsSectionHeader(title: 'Reset & Backup'),
          const SizedBox(height: 16),
          _buildResetBackupOptions(context),
        ],
      ),
    );
  }

  Widget _buildPerformanceOptions(BuildContext context) {
    return Column(
      children: [
        SettingsSwitchTile(
          title: 'Smooth Scrolling',
          subtitle: 'Enable smooth scrolling animations',
          value: settings.smoothScrolling,
          onChanged: (value) {
            onSettingsChanged(settings.copyWith(smoothScrolling: value));
          },
        ),
        SettingsSwitchTile(
          title: 'Disable Layer Hinting',
          subtitle: 'May improve performance on some devices',
          value: settings.disableLayerHinting,
          onChanged: (value) {
            onSettingsChanged(settings.copyWith(disableLayerHinting: value));
          },
        ),
        SettingsSwitchTile(
          title: 'Disable Monospace Optimizations',
          subtitle: 'Disable font optimizations for monospace fonts',
          value: settings.disableMonospaceOptimizations,
          onChanged: (value) {
            onSettingsChanged(
              settings.copyWith(
                disableMonospaceOptimizations: value,
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildAccessibilityOptions(BuildContext context) {
    return SettingsDropdownField<AccessibilitySupport>(
      label: 'Accessibility Support',
      value: settings.accessibilitySupport,
      items: AccessibilitySupport.values,
      itemBuilder: (support) => support.name.toTitle,
      onChanged: (value) {
        if (value != null) {
          onSettingsChanged(settings.copyWith(accessibilitySupport: value));
        }
      },
    );
  }

  Widget _buildResetBackupOptions(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => _showResetDialog(context),
            icon: Icon(
              Icons.restore,
              color: context.error,
            ),
            label: Text(
              'Reset to Defaults',
              style: TextStyle(color: context.error),
            ),
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: context.error),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => _exportSettings(context),
            icon: const Icon(Icons.download),
            label: const Text('Export Settings'),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => _importSettings(context),
            icon: const Icon(Icons.upload),
            label: const Text('Import Settings'),
          ),
        ),
      ],
    );
  }

  Future<void> _showResetDialog(BuildContext context) async {
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset Settings'),
        content: const Text(
          'Are you sure you want to reset all settings to defaults? This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              onResetSettings();
              Navigator.of(context).pop();
            },
            style: TextButton.styleFrom(
              foregroundColor: context.error,
            ),
            child: const Text('Reset'),
          ),
        ],
      ),
    );
  }

  Future<void> _exportSettings(BuildContext context) async {
    final settingsJson = jsonEncode(settings.toJson());
    try {
      final outputFile = await FilePicker.platform.saveFile(
        dialogTitle: 'Export Editor Settings',
        fileName: 'editor_settings.json',
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (outputFile != null) {
        final file = File(outputFile);
        await file.writeAsString(settingsJson);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Settings exported successfully to $outputFile'),
              backgroundColor: context.primary,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error exporting settings: $e'),
            backgroundColor: context.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _importSettings(BuildContext context) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (result != null && result.files.single.path != null) {
        final file = File(result.files.single.path!);
        final content = await file.readAsString();
        final jsonMap = jsonDecode(content) as Map<String, dynamic>;

        final newSettings = EditorSettings.fromJson(jsonMap);
        onSettingsChanged(newSettings);

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Settings imported successfully!'),
              backgroundColor: context.primary,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error importing settings: $e'),
            backgroundColor: context.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }
}
