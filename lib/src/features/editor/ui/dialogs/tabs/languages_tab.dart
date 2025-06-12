import 'package:context_collector/context_collector.dart';
import 'package:flutter_helper_utils/flutter_helper_utils.dart';
import 'package:flutter/material.dart';

/// Languages settings tab
class LanguagesTab extends StatelessWidget {
  const LanguagesTab({
    required this.settings,
    required this.onSettingsChanged,
    super.key,
  });

  final EditorSettings settings;
  final ValueChanged<EditorSettings> onSettingsChanged;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsetsDirectional.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SettingsSectionHeader(
            title: 'Language-Specific Settings',
            subtitle:
                'Configure settings that apply only to specific programming languages.',
          ),
          const SizedBox(height: 24),
          _buildLanguageConfigsList(context),
          const SizedBox(height: 24),
          Center(
            child: OutlinedButton.icon(
              onPressed: () => _showLanguageSettingsDialog(context),
              icon: const Icon(Icons.add),
              label: const Text('Add Language Configuration'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLanguageConfigsList(BuildContext context) {
    final entries = settings.languageConfigs.entries.toList();
    if (entries.isEmpty) {
      return EmptyLanguageConfigs(
        onAddPressed: () => _showLanguageSettingsDialog(context),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: entries.length,
      separatorBuilder: (context, index) => Divider(
        color: context.onSurface.addOpacity(0.1),
        height: 1,
      ),
      itemBuilder: (context, index) {
        final entry = entries[index];
        return LanguageConfigTile(
          languageKey: entry.key,
          config: entry.value,
          onEdit: () => _showLanguageSettingsDialog(
            context,
            language: entry.key,
          ),
          onRemove: () => _removeLanguageConfig(context, entry.key),
        );
      },
    );
  }

  void _removeLanguageConfig(BuildContext context, String language) {
    settings.languageConfigs.remove(language);
    onSettingsChanged(
      settings.copyWith(
        languageConfigs: Map.from(settings.languageConfigs),
      ),
    );
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Removed configuration for $language'),
        backgroundColor: context.error,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _showLanguageSettingsDialog(
    BuildContext context, {
    String? language,
  }) async {
    final result = await showDialog<MapEntry<String, LanguageConfig>?>(
      context: context,
      barrierDismissible: false,
      builder: (_) => LanguageSettingsDialog(
        currentConfigs: settings.languageConfigs,
        language: language,
        initialConfig: language != null
            ? settings.languageConfigs[language]
            : null,
      ),
    );

    if (result != null) {
      final newConfigs = Map<String, LanguageConfig>.from(
        settings.languageConfigs,
      );
      newConfigs[result.key] = result.value;
      onSettingsChanged(settings.copyWith(languageConfigs: newConfigs));
    }
  }
}

/// Empty state widget for language configurations
class EmptyLanguageConfigs extends StatelessWidget {
  const EmptyLanguageConfigs({
    required this.onAddPressed,
    super.key,
  });

  final VoidCallback onAddPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsetsDirectional.all(24),
      decoration: BoxDecoration(
        color: context.surfaceContainerHighest.addOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: context.onSurface.addOpacity(0.1),
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.code_off_outlined,
            size: 48,
            color: context.onSurface.addOpacity(0.4),
          ),
          const SizedBox(height: 16),
          Text(
            'No Language-Specific Configurations',
            style: context.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Click "Add Language Configuration" to define custom settings for specific languages.',
            textAlign: TextAlign.center,
            style: context.bodyMedium?.copyWith(
              color: context.onSurface.addOpacity(0.6),
            ),
          ),
        ],
      ),
    );
  }
}

/// Tile widget for displaying a language configuration
class LanguageConfigTile extends StatelessWidget {
  const LanguageConfigTile({
    required this.languageKey,
    required this.config,
    required this.onEdit,
    required this.onRemove,
    super.key,
  });

  final String languageKey;
  final LanguageConfig config;
  final VoidCallback onEdit;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final languageName = EditorConstants.languages[languageKey] ?? languageKey;

    return ListTile(
      contentPadding: const EdgeInsetsDirectional.symmetric(
        horizontal: 16,
        vertical: 8,
      ),
      leading: Icon(Icons.language, color: context.primary),
      title: Text(languageName, style: context.bodyLarge),
      subtitle: Text(
        _getConfigSummary(config),
        style: context.bodySmall?.copyWith(
          color: context.onSurface.addOpacity(0.6),
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: Icon(
              Icons.edit_outlined,
              color: context.onSurface.addOpacity(0.7),
            ),
            tooltip: 'Edit',
            onPressed: onEdit,
          ),
          IconButton(
            icon: Icon(Icons.delete_outline, color: context.error),
            tooltip: 'Remove',
            onPressed: onRemove,
          ),
        ],
      ),
      onTap: onEdit,
    );
  }

  String _getConfigSummary(LanguageConfig config) {
    final parts = <String>[];
    if (config.tabSize != null) parts.add('Tab Size: ${config.tabSize}');
    if (config.insertSpaces != null) {
      parts.add(config.insertSpaces! ? 'Use Spaces' : 'Use Tabs');
    }
    if (config.wordWrap != null && config.wordWrap != WordWrap.off) {
      parts.add('Word Wrap: ${config.wordWrap!.name.toTitle}');
    }
    if (config.formatOnSave != null && config.formatOnSave!) {
      parts.add('Format on Save');
    }
    return parts.isNotEmpty ? parts.join(', ') : 'Default settings';
  }
}
