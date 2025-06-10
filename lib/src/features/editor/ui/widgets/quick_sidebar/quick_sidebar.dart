import 'package:context_collector/context_collector.dart';
import 'package:flutter/material.dart';

/// Quick sidebar for editor settings
class QuickSidebar extends StatelessWidget {
  const QuickSidebar({
    required this.settings,
    required this.selectionState,
    required this.onSettingsChanged,
    required this.onWordWrapToggle,
    required this.onIncreaseFontSize,
    required this.onDecreaseFontSize,
    required this.onShowAllSettings,
    required this.onCopyContent,
    super.key,
  });

  final EditorSettings settings;
  final SelectionState selectionState;
  final ValueChanged<EditorSettings> onSettingsChanged;
  final VoidCallback onWordWrapToggle;
  final VoidCallback onIncreaseFontSize;
  final VoidCallback onDecreaseFontSize;
  final VoidCallback onShowAllSettings;
  final VoidCallback onCopyContent;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with some spacing for the floating button
          const SizedBox(height: 28),
          _buildHeader(context),
          const SizedBox(height: 20),

          // File Count Badge
          if (selectionState.selectedFilesCount > 0) ...[
            FileCountBadge(count: selectionState.selectedFilesCount),
            const SizedBox(height: 16),
          ],

          // Font Size Section
          const SectionTitle(title: 'Font Size'),
          const SizedBox(height: 8),
          FontSizeControl(
            fontSize: settings.fontSize,
            onIncrease: onIncreaseFontSize,
            onDecrease: onDecreaseFontSize,
          ),

          const SizedBox(height: 20),

          // Quick Toggles
          const SectionTitle(title: 'Editor Options'),
          const SizedBox(height: 8),

          ToggleTile(
            icon: Icons.wrap_text,
            title: 'Word Wrap',
            value: settings.wordWrap != WordWrap.off,
            onChanged: (_) => onWordWrapToggle(),
          ),

          ToggleTile(
            icon: Icons.format_list_numbered,
            title: 'Line Numbers',
            value: settings.showLineNumbers,
            onChanged: (value) {
              onSettingsChanged(settings.copyWith(showLineNumbers: value));
            },
          ),

          ToggleTile(
            icon: Icons.map_outlined,
            title: 'Minimap',
            value: settings.showMinimap,
            onChanged: (value) {
              onSettingsChanged(settings.copyWith(showMinimap: value));
            },
          ),

          ToggleTile(
            icon: settings.readOnly ? Icons.edit_off : Icons.edit,
            title: 'Edit Mode',
            value: !settings.readOnly,
            onChanged: (isEditable) {
              onSettingsChanged(settings.copyWith(readOnly: !isEditable));
            },
          ),

          const SizedBox(height: 20),

          // Theme Quick Select
          _buildThemeSection(context),

          const SizedBox(height: 24),

          // Action Buttons
          FilledButton.icon(
            icon: const Icon(Icons.settings, size: 18),
            label: const Text('All Settings'),
            onPressed: onShowAllSettings,
            style: FilledButton.styleFrom(
              minimumSize: const Size(double.infinity, 40),
            ),
          ),

          const SizedBox(height: 12),

          OutlinedButton.icon(
            icon: const Icon(Icons.copy, size: 18),
            label: const Text('Copy Content'),
            onPressed: selectionState.combinedContent.isNotEmpty
                ? onCopyContent
                : null,
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(double.infinity, 40),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        Icon(
          Icons.tune,
          size: 20,
          color: context.primary,
        ),
        const SizedBox(width: 8),
        Text(
          'Quick Settings',
          style: context.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildThemeSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.palette_outlined,
              size: 16,
              color: context.onSurfaceVariant,
            ),
            const SizedBox(width: 8),
            const SectionTitle(title: 'Theme'),
          ],
        ),
        const SizedBox(height: 8),
        ThemeDropdown(
          currentTheme: settings.theme,
          onThemeChanged: (theme) {
            onSettingsChanged(settings.copyWith(theme: theme));
          },
        ),
      ],
    );
  }
}

/// Section title widget
class SectionTitle extends StatelessWidget {
  const SectionTitle({
    required this.title,
    super.key,
  });

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: context.labelMedium?.copyWith(
        fontWeight: FontWeight.w600,
        color: context.onSurfaceVariant,
      ),
    );
  }
}

/// File count badge widget
class FileCountBadge extends StatelessWidget {
  const FileCountBadge({
    required this.count,
    super.key,
  });

  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
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
      child: Row(
        children: [
          Icon(
            Icons.description_outlined,
            size: 16,
            color: context.primary,
          ),
          const SizedBox(width: 8),
          Text(
            '$count files selected',
            style: context.labelMedium?.copyWith(
              color: context.primary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

/// Theme dropdown widget
class ThemeDropdown extends StatelessWidget {
  const ThemeDropdown({
    required this.currentTheme,
    required this.onThemeChanged,
    super.key,
  });

  final String currentTheme;
  final ValueChanged<String> onThemeChanged;

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(
        popupMenuTheme: PopupMenuThemeData(
          color: context.surface,
          elevation: 8,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: context.surface,
          borderRadius: BorderRadius.circular(8),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            isExpanded: true,
            value: currentTheme,
            padding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 4,
            ),
            borderRadius: BorderRadius.circular(8),
            dropdownColor: context.surface,
            menuMaxHeight: 300,
            items: EditorConstants.themeNames.entries
                .map(
                  (entry) => DropdownMenuItem(
                    value: entry.key,
                    child: Text(
                      entry.value,
                      style: context.bodyMedium,
                    ),
                  ),
                )
                .toList(),
            onChanged: (value) {
              if (value != null) {
                onThemeChanged(value);
              }
            },
          ),
        ),
      ),
    );
  }
}
