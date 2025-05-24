import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../../shared/theme/extensions.dart';
import '../../../settings/presentation/state/preferences_cubit.dart';
import '../../bridge/monaco_bridge.dart';
import '../../domain/editor_settings.dart';
import '../../domain/keybinding_manager.dart';
import '../../domain/theme_manager.dart';

/// Unified settings dialog combining app and editor settings
class EnhancedEditorSettingsDialog extends StatefulWidget {
  const EnhancedEditorSettingsDialog({
    super.key,
    required this.settings,
    this.customThemes = const [],
    this.customKeybindingPresets = const [],
  });

  final EditorSettings settings;
  final List<EditorTheme> customThemes;
  final List<KeybindingPreset> customKeybindingPresets;

  static Future<EditorSettings?> show(
    BuildContext context,
    EditorSettings currentSettings, {
    List<EditorTheme> customThemes = const [],
    List<KeybindingPreset> customKeybindingPresets = const [],
  }) async {
    return showDialog<EditorSettings>(
      context: context,
      barrierDismissible: false,
      builder: (context) => EnhancedEditorSettingsDialog(
        settings: currentSettings,
        customThemes: customThemes,
        customKeybindingPresets: customKeybindingPresets,
      ),
    );
  }

  @override
  State<EnhancedEditorSettingsDialog> createState() =>
      _EnhancedEditorSettingsDialogState();
}

class _EnhancedEditorSettingsDialogState
    extends State<EnhancedEditorSettingsDialog> with TickerProviderStateMixin {
  late EditorSettings _settings;
  late TabController _tabController;

  // Tab indices for unified settings
  static const int _appTab = 0;
  static const int _editorTab = 1;
  static const int _extensionsTab = 2;
  static const int _keybindingsTab = 3;
  static const int _advancedTab = 4;

  // Form controllers
  final _fontSizeController = TextEditingController();
  final _lineHeightController = TextEditingController();
  final _tabSizeController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _settings = widget.settings;
    _tabController = TabController(length: 5, vsync: this);

    // Initialize form controllers
    _fontSizeController.text = _settings.fontSize.toString();
    _lineHeightController.text = _settings.lineHeight.toString();
    _tabSizeController.text = _settings.tabSize.toString();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _fontSizeController.dispose();
    _lineHeightController.dispose();
    _tabSizeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
      child: Container(
        width: 900,
        height: 700,
        decoration: BoxDecoration(
          color: context.surface,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            _buildHeader(),
            _buildTabBar(),
            Expanded(child: _buildTabContent()),
            _buildFooter(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsetsDirectional.all(24),
      decoration: BoxDecoration(
        color: context.primary.addOpacity(0.05),
        border: BorderDirectional(
          bottom: BorderSide(
            color: context.onSurface.addOpacity(0.1),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.tune,
            size: 28,
            color: context.primary,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Settings',
                  style: context.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: context.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Configure your Context Collector experience',
                  style: context.bodyMedium?.copyWith(
                    color: context.onSurface.addOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: Icon(
              Icons.close,
              color: context.onSurface.addOpacity(0.6),
            ),
            tooltip: 'Close',
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      decoration: BoxDecoration(
        color: context.surface,
        border: BorderDirectional(
          bottom: BorderSide(
            color: context.onSurface.addOpacity(0.1),
            width: 1,
          ),
        ),
      ),
      child: TabBar(
        controller: _tabController,
        isScrollable: true,
        tabAlignment: TabAlignment.start,
        labelColor: context.primary,
        unselectedLabelColor: context.onSurface.addOpacity(0.6),
        indicatorColor: context.primary,
        indicatorWeight: 3,
        labelStyle: context.labelLarge?.copyWith(
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: context.labelLarge?.copyWith(
          fontWeight: FontWeight.w400,
        ),
        tabs: const [
          Tab(text: 'General'),
          Tab(text: 'Editor'),
          Tab(text: 'File Types'),
          Tab(text: 'Shortcuts'),
          Tab(text: 'Advanced'),
        ],
      ),
    );
  }

  Widget _buildTabContent() {
    return TabBarView(
      controller: _tabController,
      children: [
        _buildGeneralTab(),
        _buildEditorTab(),
        _buildExtensionsTab(),
        _buildKeybindingsTab(),
        _buildAdvancedTab(),
      ],
    );
  }

  Widget _buildGeneralTab() {
    return SingleChildScrollView(
      padding: const EdgeInsetsDirectional.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('Application Settings'),
          const SizedBox(height: 16),

          // App behavior settings
          _buildSwitchTile(
            title: 'Auto-load content on file selection',
            subtitle: 'Automatically load file content when files are selected',
            value: true, // This would come from app preferences
            onChanged: (value) {
              // Update app preferences
            },
          ),

          _buildSwitchTile(
            title: 'Remember window size',
            subtitle: 'Save and restore window dimensions between sessions',
            value: true,
            onChanged: (value) {
              // Update app preferences
            },
          ),

          _buildSwitchTile(
            title: 'Show file previews',
            subtitle: 'Display file content previews in tooltips',
            value: false,
            onChanged: (value) {
              // Update app preferences
            },
          ),

          const SizedBox(height: 32),
          _buildSectionHeader('Default Behavior'),
          const SizedBox(height: 16),

          // File panel default width
          _buildSliderTile(
            title: 'File panel width',
            subtitle: 'Default width of the file list panel',
            value: 35,
            min: 25,
            max: 50,
            divisions: 25,
            format: (value) => '${value.round()}%',
            onChanged: (value) {
              // Update default panel ratio
            },
          ),

          // Auto-collapse behavior
          _buildSwitchTile(
            title: 'Auto-collapse editor controls',
            subtitle: 'Automatically hide editor control panel after inactivity',
            value: true,
            onChanged: (value) {
              // Update app preferences
            },
          ),

          const SizedBox(height: 32),
          _buildSectionHeader('Performance'),
          const SizedBox(height: 16),

          _buildSliderTile(
            title: 'Max file size',
            subtitle: 'Maximum file size to load (MB)',
            value: 10,
            min: 1,
            max: 100,
            divisions: 99,
            format: (value) => '${value.round()} MB',
            onChanged: (value) {
              // Update max file size preference
            },
          ),

          _buildSwitchTile(
            title: 'Enable file caching',
            subtitle: 'Cache file contents for faster reopening',
            value: true,
            onChanged: (value) {
              // Update caching preference
            },
          ),
        ],
      ),
    );
  }

  Widget _buildEditorTab() {
    return SingleChildScrollView(
      padding: const EdgeInsetsDirectional.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('Font & Typography'),
          const SizedBox(height: 16),

          // Font Family
          _buildDropdownField(
            label: 'Font Family',
            value: _settings.fontFamily,
            items: [
              'JetBrains Mono, SF Mono, Menlo, Consolas, "Courier New", monospace',
              'SF Mono, Monaco, Consolas, monospace',
              'Consolas, Monaco, monospace',
              'Courier New, monospace',
              'monospace',
            ],
            onChanged: (value) {
              if (value != null) {
                setState(() {
                  _settings = _settings.copyWith(fontFamily: value);
                });
              }
            },
          ),
          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: _buildNumberField(
                  label: 'Font Size',
                  controller: _fontSizeController,
                  min: 8,
                  max: 32,
                  suffix: 'px',
                  onChanged: (value) {
                    setState(() {
                      _settings = _settings.copyWith(fontSize: value);
                    });
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildNumberField(
                  label: 'Line Height',
                  controller: _lineHeightController,
                  min: 1,
                  max: 3,
                  step: 0.1,
                  onChanged: (value) {
                    setState(() {
                      _settings = _settings.copyWith(lineHeight: value);
                    });
                  },
                ),
              ),
            ],
          ),

          const SizedBox(height: 32),
          _buildSectionHeader('Appearance'),
          const SizedBox(height: 16),

          // Theme selection
          _buildThemeSelection(),

          const SizedBox(height: 16),

          // Display options
          _buildSwitchTile(
            title: 'Show Line Numbers',
            subtitle: 'Display line numbers in the editor gutter',
            value: _settings.showLineNumbers,
            onChanged: (value) {
              setState(() {
                _settings = _settings.copyWith(showLineNumbers: value);
              });
            },
          ),

          _buildSwitchTile(
            title: 'Show Minimap',
            subtitle: 'Display miniature overview of the file',
            value: _settings.showMinimap,
            onChanged: (value) {
              setState(() {
                _settings = _settings.copyWith(showMinimap: value);
              });
            },
          ),

          _buildSwitchTile(
            title: 'Word Wrap',
            subtitle: 'Wrap long lines instead of horizontal scrolling',
            value: _settings.wordWrap != WordWrap.off,
            onChanged: (value) {
              setState(() {
                _settings = _settings.copyWith(
                  wordWrap: value ? WordWrap.on : WordWrap.off,
                );
              });
            },
          ),

          const SizedBox(height: 32),
          _buildSectionHeader('Behavior'),
          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: _buildNumberField(
                  label: 'Tab Size',
                  controller: _tabSizeController,
                  min: 1,
                  max: 16,
                  onChanged: (value) {
                    setState(() {
                      _settings = _settings.copyWith(tabSize: value.toInt());
                    });
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildSwitchTile(
                  title: 'Insert Spaces',
                  subtitle: 'Use spaces instead of tabs',
                  value: _settings.insertSpaces,
                  onChanged: (value) {
                    setState(() {
                      _settings = _settings.copyWith(insertSpaces: value);
                    });
                  },
                ),
              ),
            ],
          ),

          _buildSwitchTile(
            title: 'Format on Save',
            subtitle: 'Automatically format code when saving',
            value: _settings.formatOnSave,
            onChanged: (value) {
              setState(() {
                _settings = _settings.copyWith(formatOnSave: value);
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildExtensionsTab() {
    return Consumer<PreferencesCubit>(
      builder: (context, cubit, child) {
        if (cubit.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        final groupedExtensions = cubit.groupedExtensions;

        return Column(
          children: [
            Container(
              padding: const EdgeInsetsDirectional.all(16),
              color: context.surfaceContainerHighest,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Supported File Types',
                    style: context.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Configure which file types can be processed by Context Collector.',
                    style: context.bodyMedium?.copyWith(
                      color: context.onSurface.addOpacity(0.7),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      FilledButton.icon(
                        onPressed: () => _showAddExtensionDialog(context, cubit),
                        icon: const Icon(Icons.add_rounded, size: 18),
                        label: const Text('Add Custom Extension'),
                      ),
                      const SizedBox(width: 12),
                      OutlinedButton.icon(
                        onPressed: () => _resetExtensions(cubit),
                        icon: const Icon(Icons.restore, size: 18),
                        label: const Text('Reset to Defaults'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsetsDirectional.all(16),
                itemCount: groupedExtensions.length,
                itemBuilder: (context, index) {
                  final category = groupedExtensions.keys.elementAt(index);
                  final extensions = groupedExtensions[category]!;
                  final enabledCount = extensions.where((e) => e.value).length;

                  return Card(
                    margin: const EdgeInsetsDirectional.only(bottom: 16),
                    child: ExpansionTile(
                      leading: Icon(category.icon),
                      title: Text(category.displayName),
                      subtitle: Text(
                        '$enabledCount of ${extensions.length} enabled',
                        style: context.bodySmall?.copyWith(
                          color: context.onSurface.addOpacity(0.6),
                        ),
                      ),
                      children: [
                        const Divider(height: 1),
                        Padding(
                          padding: const EdgeInsetsDirectional.all(8),
                          child: Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: extensions.map((entry) {
                              final extension = entry.key;
                              final isEnabled = entry.value;
                              final isCustom = cubit.preferences.customExtensions
                                  .containsKey(extension);

                              return FilterChip(
                                label: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(extension),
                                    if (isCustom) ...[
                                      const SizedBox(width: 4),
                                      Icon(
                                        Icons.star_rounded,
                                        size: 14,
                                        color: context.primary,
                                      ),
                                    ],
                                  ],
                                ),
                                selected: isEnabled,
                                onSelected: (_) async {
                                  await cubit.toggleExtension(extension);
                                },
                                showCheckmark: true,
                                deleteIcon: isCustom
                                    ? const Icon(Icons.close_rounded, size: 18)
                                    : null,
                                onDeleted: isCustom
                                    ? () async {
                                        await cubit.toggleExtension(extension);
                                      }
                                    : null,
                              );
                            }).toList(),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildKeybindingsTab() {
    final allPresets = KeybindingManager.getAllPresets(
      customPresets: widget.customKeybindingPresets,
    );

    return SingleChildScrollView(
      padding: const EdgeInsetsDirectional.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('Keybinding Preset'),
          const SizedBox(height: 8),
          Text(
            'Choose a keybinding scheme that matches your workflow.',
            style: context.bodyMedium?.copyWith(
              color: context.onSurface.addOpacity(0.7),
            ),
          ),
          const SizedBox(height: 16),

          // Preset selection
          Container(
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
                    groupValue: _settings.keybindingPreset,
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          _settings = _settings.copyWith(keybindingPreset: value);
                        });
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
          ),

          const SizedBox(height: 32),
          _buildSectionHeader('Common Shortcuts'),
          const SizedBox(height: 16),

          // Show common shortcuts for selected preset
          _buildShortcutsPreview(),
        ],
      ),
    );
  }

  Widget _buildAdvancedTab() {
    return SingleChildScrollView(
      padding: const EdgeInsetsDirectional.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('Performance'),
          const SizedBox(height: 16),

          _buildSwitchTile(
            title: 'Smooth Scrolling',
            subtitle: 'Enable smooth scrolling animations in editor',
            value: _settings.smoothScrolling,
            onChanged: (value) {
              setState(() {
                _settings = _settings.copyWith(smoothScrolling: value);
              });
            },
          ),

          _buildSwitchTile(
            title: 'Hardware Acceleration',
            subtitle: 'Use GPU acceleration for better performance',
            value: !_settings.disableLayerHinting,
            onChanged: (value) {
              setState(() {
                _settings = _settings.copyWith(disableLayerHinting: !value);
              });
            },
          ),

          const SizedBox(height: 32),
          _buildSectionHeader('Accessibility'),
          const SizedBox(height: 16),

          _buildDropdownField<AccessibilitySupport>(
            label: 'Screen Reader Support',
            value: _settings.accessibilitySupport,
            items: AccessibilitySupport.values,
            itemBuilder: (support) => support.name.capitalize(),
            onChanged: (value) {
              if (value != null) {
                setState(() {
                  _settings = _settings.copyWith(accessibilitySupport: value);
                });
              }
            },
          ),

          const SizedBox(height: 32),
          _buildSectionHeader('Data Management'),
          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _exportSettings,
                  icon: const Icon(Icons.download, size: 18),
                  label: const Text('Export Settings'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _importSettings,
                  icon: const Icon(Icons.upload, size: 18),
                  label: const Text('Import Settings'),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          OutlinedButton.icon(
            onPressed: _showResetDialog,
            icon: Icon(Icons.restore, color: context.error, size: 18),
            label: Text(
              'Reset All Settings',
              style: TextStyle(color: context.error),
            ),
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: context.error),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildThemeSelection() {
    const themes = [
      ('vs', 'Light'),
      ('vs-dark', 'Dark'),
      ('hc-black', 'High Contrast'),
      ('one-dark-pro', 'One Dark Pro'),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Editor Theme',
          style: context.labelMedium?.copyWith(
            fontWeight: FontWeight.w500,
            color: context.onSurface.addOpacity(0.8),
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: themes.map((theme) {
            final isSelected = _settings.theme == theme.$1;
            return InkWell(
              onTap: () {
                setState(() {
                  _settings = _settings.copyWith(theme: theme.$1);
                });
              },
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
                    // Theme preview
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(7),
                        color: theme.$1.contains('dark') || theme.$1 == 'hc-black'
                            ? const Color(0xFF1E1E1E)
                            : Colors.white,
                      ),
                      child: Column(
                        children: [
                          Container(
                            height: 20,
                            decoration: BoxDecoration(
                              color: context.primary.addOpacity(0.1),
                              borderRadius: const BorderRadiusDirectional.only(
                                topStart: Radius.circular(7),
                                topEnd: Radius.circular(7),
                              ),
                            ),
                          ),
                          Expanded(
                            child: Center(
                              child: Text(
                                theme.$2,
                                style: context.labelSmall?.copyWith(
                                  color: theme.$1.contains('dark') || theme.$1 == 'hc-black'
                                      ? Colors.white
                                      : Colors.black,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Selection indicator
                    if (isSelected)
                      PositionedDirectional(
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
                      ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildShortcutsPreview() {
    final preset = KeybindingManager.findPresetById(_settings.keybindingPreset.name);
    if (preset == null) return const SizedBox.shrink();

    final shortcuts = preset.keybindings.take(8).toList();

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
          for (final shortcut in shortcuts) ...[
            Row(
              children: [
                Expanded(
                  child: Text(
                    shortcut.description ?? shortcut.command,
                    style: context.bodyMedium,
                  ),
                ),
                Container(
                  padding: const EdgeInsetsDirectional.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: context.onSurface.addOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    shortcut.key,
                    style: context.labelSmall?.copyWith(
                      fontFamily: 'monospace',
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            if (shortcut != shortcuts.last)
              Divider(
                color: context.onSurface.addOpacity(0.1),
                height: 16,
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsetsDirectional.all(24),
      decoration: BoxDecoration(
        color: context.surface,
        border: BorderDirectional(
          top: BorderSide(
            color: context.onSurface.addOpacity(0.1),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Text(
            'Changes are saved automatically',
            style: context.bodySmall?.copyWith(
              color: context.onSurface.addOpacity(0.6),
            ),
          ),
          const Spacer(),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          const SizedBox(width: 12),
          FilledButton(
            onPressed: () async {
              await _settings.save();
              if (mounted) {
                Navigator.of(context).pop(_settings);
              }
            },
            child: const Text('Apply & Close'),
          ),
        ],
      ),
    );
  }

  // Helper widgets
  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: context.titleMedium?.copyWith(
        fontWeight: FontWeight.w600,
        color: context.onSurface,
      ),
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      margin: const EdgeInsetsDirectional.only(bottom: 16),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => onChanged(!value),
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsetsDirectional.symmetric(
              horizontal: 12,
              vertical: 12,
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
                      const SizedBox(height: 4),
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

  Widget _buildSliderTile({
    required String title,
    required String subtitle,
    required double value,
    required double min,
    required double max,
    required int divisions,
    required String Function(double) format,
    required ValueChanged<double> onChanged,
  }) {
    return Container(
      margin: const EdgeInsetsDirectional.only(bottom: 16),
      padding: const EdgeInsetsDirectional.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
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
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: context.labelSmall?.copyWith(
                        color: context.onSurface.addOpacity(0.6),
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                format(value),
                style: context.labelMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: context.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Slider(
            value: value,
            min: min,
            max: max,
            divisions: divisions,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  Widget _buildDropdownField<T>({
    required String label,
    required T value,
    required List<T> items,
    String Function(T)? itemBuilder,
    required ValueChanged<T?> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: context.labelMedium?.copyWith(
            fontWeight: FontWeight.w500,
            color: context.onSurface.addOpacity(0.8),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: context.onSurface.addOpacity(0.2),
            ),
          ),
          child: DropdownButtonFormField<T>(
            value: value,
            decoration: const InputDecoration(
              border: InputBorder.none,
              contentPadding: EdgeInsetsDirectional.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
            ),
            items: items.map((item) {
              return DropdownMenuItem<T>(
                value: item,
                child: Text(
                  itemBuilder?.call(item) ?? item.toString(),
                  style: context.bodyMedium,
                ),
              );
            }).toList(),
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }

  Widget _buildNumberField({
    required String label,
    required TextEditingController controller,
    required double min,
    required double max,
    double step = 1.0,
    String? suffix,
    required ValueChanged<double> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: context.labelMedium?.copyWith(
            fontWeight: FontWeight.w500,
            color: context.onSurface.addOpacity(0.8),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: context.onSurface.addOpacity(0.2),
            ),
          ),
          child: TextFormField(
            controller: controller,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
            ],
            decoration: InputDecoration(
              border: InputBorder.none,
              contentPadding: const EdgeInsetsDirectional.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
              suffixText: suffix,
            ),
            onChanged: (value) {
              final numValue = double.tryParse(value);
              if (numValue != null && numValue >= min && numValue <= max) {
                onChanged(numValue);
              }
            },
          ),
        ),
      ],
    );
  }

  // Action methods
  Future<void> _showAddExtensionDialog(BuildContext context, PreferencesCubit cubit) async {
    // Implementation for adding custom extensions
    // This would be similar to the existing implementation
  }

  Future<void> _resetExtensions(PreferencesCubit cubit) async {
    await cubit.resetToDefaults();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Extensions reset to defaults'),
          backgroundColor: context.primary,
        ),
      );
    }
  }

  Future<void> _exportSettings() async {
    // Implementation for exporting settings
  }

  Future<void> _importSettings() async {
    // Implementation for importing settings
  }

  Future<void> _showResetDialog() async {
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset All Settings'),
        content: const Text(
          'This will reset all settings to their default values. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                _settings = const EditorSettings();
                _fontSizeController.text = _settings.fontSize.toString();
                _lineHeightController.text = _settings.lineHeight.toString();
                _tabSizeController.text = _settings.tabSize.toString();
              });
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
}

extension StringExtension on String {
  String capitalize() {
    if (isEmpty) return this;
    return this[0].toUpperCase() + substring(1);
  }
}