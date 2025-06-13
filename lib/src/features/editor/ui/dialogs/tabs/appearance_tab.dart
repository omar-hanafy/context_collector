import 'package:context_collector/context_collector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_helper_utils/flutter_helper_utils.dart';

/// Appearance settings tab for the editor settings dialog
class AppearanceTab extends StatelessWidget {
  const AppearanceTab({
    required this.settings,
    required this.onSettingsChanged,
    required this.customThemes,
    super.key,
  });

  final EditorSettings settings;
  final ValueChanged<EditorSettings> onSettingsChanged;
  final List<EditorTheme> customThemes;

  @override
  Widget build(BuildContext context) {
    final availableThemes = ThemeManager.getAllThemes(
      customThemes: customThemes,
    );

    return SingleChildScrollView(
      padding: const EdgeInsetsDirectional.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SettingsSectionHeader(title: 'Theme'),
          const SizedBox(height: 16),
          _buildThemeSelection(context, availableThemes),
          const SizedBox(height: 32),
          const SettingsSectionHeader(title: 'Display'),
          const SizedBox(height: 16),
          _buildDisplayOptions(context),
        ],
      ),
    );
  }

  Widget _buildThemeSelection(
    BuildContext context,
    List<EditorTheme> availableThemes,
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
          for (final category in ThemeCategory.values)
            if (availableThemes.any((t) => t.category == category)) ...[
              ThemeCategorySection(
                category: category,
                themes: availableThemes
                    .where((t) => t.category == category)
                    .toList(),
                selectedTheme: settings.theme,
                onThemeSelected: (themeId) {
                  onSettingsChanged(settings.copyWith(theme: themeId));
                },
              ),
              if (category != ThemeCategory.values.last)
                const SizedBox(height: 24),
            ],
        ],
      ),
    );
  }

  Widget _buildDisplayOptions(BuildContext context) {
    return Column(
      children: [
        _buildLineNumbersOptions(context),
        const SizedBox(height: 16),
        _buildMinimapOptions(context),
        const SizedBox(height: 16),
        _buildOtherDisplayOptions(context),
      ],
    );
  }

  Widget _buildLineNumbersOptions(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: SettingsSwitchTile(
            title: 'Show Line Numbers',
            subtitle: 'Display line numbers in the gutter',
            value: settings.showLineNumbers,
            onChanged: (value) {
              onSettingsChanged(settings.copyWith(showLineNumbers: value));
            },
          ),
        ),
        const SizedBox(width: 16),
        if (settings.showLineNumbers)
          Expanded(
            child: SettingsDropdownField<LineNumbersStyle>(
              label: 'Line Number Style',
              value: settings.lineNumbersStyle,
              items: LineNumbersStyle.values,
              itemBuilder: (style) => style.name.toTitle,
              onChanged: (value) {
                if (value != null) {
                  onSettingsChanged(settings.copyWith(lineNumbersStyle: value));
                }
              },
            ),
          ),
      ],
    );
  }

  Widget _buildMinimapOptions(BuildContext context) {
    return Column(
      children: [
        SettingsSwitchTile(
          title: 'Show Minimap',
          subtitle: 'Display miniature overview of the entire file',
          value: settings.showMinimap,
          onChanged: (value) {
            onSettingsChanged(settings.copyWith(showMinimap: value));
          },
        ),
        if (settings.showMinimap) ...[
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: SettingsDropdownField<MinimapSide>(
                  label: 'Minimap Side',
                  value: settings.minimapSide,
                  items: MinimapSide.values,
                  itemBuilder: (side) => side.name.toTitle,
                  onChanged: (value) {
                    if (value != null) {
                      onSettingsChanged(settings.copyWith(minimapSide: value));
                    }
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: SettingsSwitchTile(
                  title: 'Render Characters',
                  subtitle: 'Show actual characters in minimap',
                  value: settings.minimapRenderCharacters,
                  onChanged: (value) {
                    onSettingsChanged(
                      settings.copyWith(
                        minimapRenderCharacters: value,
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildOtherDisplayOptions(BuildContext context) {
    return Column(
      children: [
        SettingsSwitchTile(
          title: 'Show Indent Guides',
          subtitle: 'Display vertical lines to show indentation',
          value: settings.showIndentGuides,
          onChanged: (value) {
            onSettingsChanged(settings.copyWith(showIndentGuides: value));
          },
        ),
        const SizedBox(height: 16),
        SettingsDropdownField<RenderWhitespace>(
          label: 'Render Whitespace',
          value: settings.renderWhitespace,
          items: RenderWhitespace.values,
          itemBuilder: (ws) => ws.name.toTitle,
          onChanged: (value) {
            if (value != null) {
              onSettingsChanged(settings.copyWith(renderWhitespace: value));
            }
          },
        ),
        const SizedBox(height: 16),
        SettingsSwitchTile(
          title: 'Bracket Pair Colorization',
          subtitle: 'Color matching brackets with different colors',
          value: settings.bracketPairColorization,
          onChanged: (value) {
            onSettingsChanged(
              settings.copyWith(bracketPairColorization: value),
            );
          },
        ),
      ],
    );
  }
}

/// Widget for displaying themes grouped by category
class ThemeCategorySection extends StatelessWidget {
  const ThemeCategorySection({
    required this.category,
    required this.themes,
    required this.selectedTheme,
    required this.onThemeSelected,
    super.key,
  });

  final ThemeCategory category;
  final List<EditorTheme> themes;
  final String selectedTheme;
  final ValueChanged<String> onThemeSelected;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _getCategoryName(),
          style: context.labelLarge?.copyWith(
            fontWeight: FontWeight.w600,
            color: context.onSurface.addOpacity(0.8),
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: themes.map((theme) {
            return ThemePreviewCard(
              theme: theme,
              isSelected: selectedTheme == theme.id,
              onTap: () => onThemeSelected(theme.id),
            );
          }).toList(),
        ),
      ],
    );
  }

  String _getCategoryName() {
    switch (category) {
      case ThemeCategory.light:
        return 'Light Themes';
      case ThemeCategory.dark:
        return 'Dark Themes';
      case ThemeCategory.highContrast:
        return 'High Contrast';
      case ThemeCategory.custom:
        return 'Custom Themes';
    }
  }
}

/// Theme preview card widget
class ThemePreviewCard extends StatelessWidget {
  const ThemePreviewCard({
    required this.theme,
    required this.isSelected,
    required this.onTap,
    super.key,
  });

  final EditorTheme theme;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final previewColors = ThemeManager.getThemePreviewColors(theme);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 120,
        height: 80,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected
                ? context.primary
                : context.onSurface.addOpacity(0.2),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Stack(
          children: [
            _buildThemePreview(context, previewColors),
            if (isSelected) _buildSelectionIndicator(context),
          ],
        ),
      ),
    );
  }

  Widget _buildThemePreview(
    BuildContext context,
    Map<String, String> previewColors,
  ) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(7),
        color: Color(
          int.parse(
            previewColors['background']!.replaceFirst('#', '0xFF'),
          ),
        ),
      ),
      child: Column(
        children: [
          Container(
            height: 20,
            decoration: BoxDecoration(
              color: Color(
                int.parse(
                  previewColors['accent']!.replaceFirst('#', '0xFF'),
                ),
              ).addOpacity(0.1),
              borderRadius: const BorderRadiusDirectional.only(
                topStart: Radius.circular(7),
                topEnd: Radius.circular(7),
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsetsDirectional.all(8),
              child: Row(
                children: [
                  Container(
                    width: 8,
                    decoration: BoxDecoration(
                      color: Color(
                        int.parse(
                          previewColors['lineNumber']!.replaceFirst(
                            '#',
                            '0xFF',
                          ),
                        ),
                      ),
                      borderRadius: BorderRadius.circular(1),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          height: 2,
                          width: double.infinity,
                          color: Color(
                            int.parse(
                              previewColors['foreground']!.replaceFirst(
                                '#',
                                '0xFF',
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Container(
                          height: 2,
                          width: 40,
                          color: Color(
                            int.parse(
                              previewColors['accent']!.replaceFirst(
                                '#',
                                '0xFF',
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Container(
                          height: 2,
                          width: 60,
                          color: Color(
                            int.parse(
                              previewColors['foreground']!.replaceFirst(
                                '#',
                                '0xFF',
                              ),
                            ),
                          ).addOpacity(0.7),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectionIndicator(BuildContext context) {
    return PositionedDirectional(
      top: 4,
      end: 4,
      child: Container(
        width: 16,
        height: 16,
        decoration: BoxDecoration(
          color: context.primary,
          shape: BoxShape.circle,
        ),
        child: Icon(
          Icons.check,
          size: 12,
          color: context.onPrimary,
        ),
      ),
    );
  }
}
