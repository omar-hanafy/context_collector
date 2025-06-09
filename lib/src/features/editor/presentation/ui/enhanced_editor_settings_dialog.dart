import 'dart:convert';
import 'dart:io';

import 'package:context_collector/src/features/editor/domain/editor_settings.dart';
import 'package:context_collector/src/features/editor/domain/keybinding_manager.dart';
import 'package:context_collector/src/features/editor/domain/monaco_data.dart';
import 'package:context_collector/src/features/editor/domain/theme_manager.dart';
import 'package:context_collector/src/features/editor/services/editor_settings_service.dart';
import 'package:context_collector/src/features/editor/utils/monaco_settings_converter.dart';
import 'package:context_collector/src/shared/theme/extensions.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Enhanced settings dialog with tabbed interface and comprehensive options
class EnhancedEditorSettingsDialog extends StatefulWidget {
  const EnhancedEditorSettingsDialog({
    required this.settings,
    super.key,
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

  // Form controllers
  final _fontSizeController = TextEditingController();
  final _lineHeightController = TextEditingController();
  final _letterSpacingController = TextEditingController();
  final _tabSizeController = TextEditingController();
  final _wordWrapColumnController = TextEditingController();

  // Focus nodes
  final _fontSizeFocus = FocusNode();
  final _lineHeightFocus = FocusNode();
  final _letterSpacingFocus = FocusNode();
  final _tabSizeFocus = FocusNode();
  final _wordWrapColumnFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    _settings = widget.settings;
    _tabController = TabController(length: 6, vsync: this);

    // Initialize form controllers
    _fontSizeController.text = _settings.fontSize.toString();
    _lineHeightController.text = _settings.lineHeight.toString();
    _letterSpacingController.text = _settings.letterSpacing.toString();
    _tabSizeController.text = _settings.tabSize.toString();
    _wordWrapColumnController.text = _settings.wordWrapColumn.toString();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _fontSizeController.dispose();
    _lineHeightController.dispose();
    _letterSpacingController.dispose();
    _tabSizeController.dispose();
    _wordWrapColumnController.dispose();
    _fontSizeFocus.dispose();
    _lineHeightFocus.dispose();
    _letterSpacingFocus.dispose();
    _tabSizeFocus.dispose();
    _wordWrapColumnFocus.dispose();
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
        border: Border(
          bottom: BorderSide(
            color: context.onSurface.addOpacity(0.1),
          ),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.settings_outlined,
            size: 28,
            color: context.primary,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Editor Settings',
                  style: context.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: context.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Customize your Monaco editor experience',
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
        border: Border(
          bottom: BorderSide(
            color: context.onSurface.addOpacity(0.1),
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
          Tab(text: 'Appearance'),
          Tab(text: 'Editor'),
          Tab(text: 'Keybindings'),
          Tab(text: 'Languages'),
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
        _buildAppearanceTab(),
        _buildEditorTab(),
        _buildKeybindingsTab(),
        _buildLanguagesTab(),
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
          _buildSectionHeader('Font & Typography'),
          const SizedBox(height: 16),

          // Font Family
          _buildDropdownField(
            label: 'Font Family',
            value: _settings.fontFamily,
            items: [
              'JetBrains Mono, SF Mono, Menlo, Consolas, "Courier New", monospace',
              'JetBrains Mono, SF Mono, Menlo, Consolas, monospace',
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
            hint: 'Select font family',
          ),
          const SizedBox(height: 16),

          Row(
            children: [
              // Font Size
              Expanded(
                child: _buildNumberField(
                  label: 'Font Size',
                  controller: _fontSizeController,
                  focusNode: _fontSizeFocus,
                  min: 8,
                  max: 72,
                  suffix: 'px',
                  onChanged: (value) {
                    setState(() {
                      _settings = _settings.copyWith(fontSize: value);
                    });
                  },
                ),
              ),
              const SizedBox(width: 16),

              // Line Height
              Expanded(
                child: _buildNumberField(
                  label: 'Line Height',
                  controller: _lineHeightController,
                  focusNode: _lineHeightFocus,
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
              const SizedBox(width: 16),

              // Letter Spacing
              Expanded(
                child: _buildNumberField(
                  label: 'Letter Spacing',
                  controller: _letterSpacingController,
                  focusNode: _letterSpacingFocus,
                  min: -2,
                  max: 5,
                  step: 0.1,
                  suffix: 'px',
                  onChanged: (value) {
                    setState(() {
                      _settings = _settings.copyWith(letterSpacing: value);
                    });
                  },
                ),
              ),
            ],
          ),

          const SizedBox(height: 32),
          _buildSectionHeader('Basic Options'),
          const SizedBox(height: 16),

          // Read Only
          _buildSwitchTile(
            title: 'Read Only',
            subtitle: 'Make editor read-only (view mode)',
            value: _settings.readOnly,
            onChanged: (value) {
              setState(() {
                _settings = _settings.copyWith(readOnly: value);
              });
            },
          ),

          // Automatic Layout
          _buildSwitchTile(
            title: 'Automatic Layout',
            subtitle: 'Automatically adjust editor size',
            value: _settings.automaticLayout,
            onChanged: (value) {
              setState(() {
                _settings = _settings.copyWith(automaticLayout: value);
              });
            },
          ),

          // Mouse Wheel Zoom
          _buildSwitchTile(
            title: 'Mouse Wheel Zoom',
            subtitle: 'Enable zooming with Ctrl+Mouse wheel',
            value: _settings.mouseWheelZoom,
            onChanged: (value) {
              setState(() {
                _settings = _settings.copyWith(mouseWheelZoom: value);
              });
            },
          ),

          const SizedBox(height: 32),
          _buildPreviewSection(),
        ],
      ),
    );
  }

  Widget _buildAppearanceTab() {
    final availableThemes =
        ThemeManager.getAllThemes(customThemes: widget.customThemes);

    return SingleChildScrollView(
      padding: const EdgeInsetsDirectional.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('Theme'),
          const SizedBox(height: 16),

          // Theme Selection
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
                for (final category in ThemeCategory.values)
                  if (availableThemes.any((t) => t.category == category)) ...[
                    _buildThemeCategorySection(category, availableThemes),
                    if (category != ThemeCategory.values.last)
                      const SizedBox(height: 24),
                  ],
              ],
            ),
          ),

          const SizedBox(height: 32),
          _buildSectionHeader('Display'),
          const SizedBox(height: 16),

          // Line Numbers
          Row(
            children: [
              Expanded(
                child: _buildSwitchTile(
                  title: 'Show Line Numbers',
                  subtitle: 'Display line numbers in the gutter',
                  value: _settings.showLineNumbers,
                  onChanged: (value) {
                    setState(() {
                      _settings = _settings.copyWith(showLineNumbers: value);
                    });
                  },
                ),
              ),
              const SizedBox(width: 16),
              if (_settings.showLineNumbers)
                Expanded(
                  child: _buildDropdownField<LineNumbersStyle>(
                    label: 'Line Number Style',
                    value: _settings.lineNumbersStyle,
                    items: LineNumbersStyle.values,
                    itemBuilder: (style) {
                      switch (style) {
                        case LineNumbersStyle.off:
                          return 'Off';
                        case LineNumbersStyle.on:
                          return 'On';
                        case LineNumbersStyle.relative:
                          return 'Relative';
                        case LineNumbersStyle.interval:
                          return 'Interval';
                      }
                    },
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          _settings =
                              _settings.copyWith(lineNumbersStyle: value);
                        });
                      }
                    },
                  ),
                ),
            ],
          ),

          // Minimap
          _buildSwitchTile(
            title: 'Show Minimap',
            subtitle: 'Display miniature overview of the entire file',
            value: _settings.showMinimap,
            onChanged: (value) {
              setState(() {
                _settings = _settings.copyWith(showMinimap: value);
              });
            },
          ),

          if (_settings.showMinimap) ...[
            Row(
              children: [
                Expanded(
                  child: _buildDropdownField<MinimapSide>(
                    label: 'Minimap Side',
                    value: _settings.minimapSide,
                    items: MinimapSide.values,
                    itemBuilder: (side) => side.name.capitalize(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          _settings = _settings.copyWith(minimapSide: value);
                        });
                      }
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildSwitchTile(
                    title: 'Render Characters',
                    subtitle: 'Show actual characters in minimap',
                    value: _settings.minimapRenderCharacters,
                    onChanged: (value) {
                      setState(() {
                        _settings =
                            _settings.copyWith(minimapRenderCharacters: value);
                      });
                    },
                  ),
                ),
              ],
            ),
          ],

          // Other Display Options
          _buildSwitchTile(
            title: 'Show Indent Guides',
            subtitle: 'Display vertical lines to show indentation',
            value: _settings.showIndentGuides,
            onChanged: (value) {
              setState(() {
                _settings = _settings.copyWith(showIndentGuides: value);
              });
            },
          ),

          _buildDropdownField<RenderWhitespace>(
            label: 'Render Whitespace',
            value: _settings.renderWhitespace,
            items: RenderWhitespace.values,
            itemBuilder: (ws) {
              switch (ws) {
                case RenderWhitespace.none:
                  return 'None';
                case RenderWhitespace.boundary:
                  return 'Boundary';
                case RenderWhitespace.selection:
                  return 'Selection';
                case RenderWhitespace.trailing:
                  return 'Trailing';
                case RenderWhitespace.all:
                  return 'All';
              }
            },
            onChanged: (value) {
              if (value != null) {
                setState(() {
                  _settings = _settings.copyWith(renderWhitespace: value);
                });
              }
            },
          ),

          _buildSwitchTile(
            title: 'Bracket Pair Colorization',
            subtitle: 'Color matching brackets with different colors',
            value: _settings.bracketPairColorization,
            onChanged: (value) {
              setState(() {
                _settings = _settings.copyWith(bracketPairColorization: value);
              });
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
          _buildSectionHeader('Text Editing'),
          const SizedBox(height: 16),

          // Word Wrap
          _buildDropdownField<WordWrap>(
            label: 'Word Wrap',
            value: _settings.wordWrap,
            items: WordWrap.values,
            itemBuilder: (wrap) {
              switch (wrap) {
                case WordWrap.off:
                  return 'Off';
                case WordWrap.on:
                  return 'On';
                case WordWrap.wordWrapColumn:
                  return 'At Column';
                case WordWrap.bounded:
                  return 'Bounded';
              }
            },
            onChanged: (value) {
              if (value != null) {
                setState(() {
                  _settings = _settings.copyWith(wordWrap: value);
                });
              }
            },
          ),

          if (_settings.wordWrap == WordWrap.wordWrapColumn) ...[
            const SizedBox(height: 16),
            _buildNumberField(
              label: 'Word Wrap Column',
              controller: _wordWrapColumnController,
              focusNode: _wordWrapColumnFocus,
              min: 40,
              max: 200,
              onChanged: (value) {
                setState(() {
                  _settings = _settings.copyWith(wordWrapColumn: value.toInt());
                });
              },
            ),
          ],

          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: _buildNumberField(
                  label: 'Tab Size',
                  controller: _tabSizeController,
                  focusNode: _tabSizeFocus,
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

          const SizedBox(height: 32),
          _buildSectionHeader('Auto Features'),
          const SizedBox(height: 16),

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

          _buildSwitchTile(
            title: 'Format on Paste',
            subtitle: 'Automatically format pasted code',
            value: _settings.formatOnPaste,
            onChanged: (value) {
              setState(() {
                _settings = _settings.copyWith(formatOnPaste: value);
              });
            },
          ),

          _buildSwitchTile(
            title: 'Format on Type',
            subtitle: 'Format code as you type',
            value: _settings.formatOnType,
            onChanged: (value) {
              setState(() {
                _settings = _settings.copyWith(formatOnType: value);
              });
            },
          ),

          const SizedBox(height: 32),
          _buildSectionHeader('Code Intelligence'),
          const SizedBox(height: 16),

          _buildSwitchTile(
            title: 'Quick Suggestions',
            subtitle: 'Show auto-completion suggestions',
            value: _settings.quickSuggestions,
            onChanged: (value) {
              setState(() {
                _settings = _settings.copyWith(quickSuggestions: value);
              });
            },
          ),

          _buildSwitchTile(
            title: 'Parameter Hints',
            subtitle: 'Show parameter hints for functions',
            value: _settings.parameterHints,
            onChanged: (value) {
              setState(() {
                _settings = _settings.copyWith(parameterHints: value);
              });
            },
          ),

          _buildSwitchTile(
            title: 'Hover Information',
            subtitle: 'Show hover information for symbols',
            value: _settings.hover,
            onChanged: (value) {
              setState(() {
                _settings = _settings.copyWith(hover: value);
              });
            },
          ),

          const SizedBox(height: 32),
          _buildSectionHeader('Cursor & Selection'),
          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: _buildDropdownField<CursorBlinking>(
                  label: 'Cursor Blinking',
                  value: _settings.cursorBlinking,
                  items: CursorBlinking.values,
                  itemBuilder: (blinking) => blinking.name.capitalize(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _settings = _settings.copyWith(cursorBlinking: value);
                      });
                    }
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildDropdownField<CursorStyle>(
                  label: 'Cursor Style',
                  value: _settings.cursorStyle,
                  items: CursorStyle.values,
                  itemBuilder: (style) => style.name.capitalize(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _settings = _settings.copyWith(cursorStyle: value);
                      });
                    }
                  },
                ),
              ),
            ],
          ),
        ],
      ),
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
          const SizedBox(height: 16),

          // Preset Selection
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
                          _settings =
                              _settings.copyWith(keybindingPreset: value);
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
          _buildSectionHeader('Popular Shortcuts'),
          const SizedBox(height: 16),

          // Show common shortcuts
          _buildShortcutsPreview(),
        ],
      ),
    );
  }

  Widget _buildLanguagesTab() {
    return SingleChildScrollView(
      padding: const EdgeInsetsDirectional.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('Language-Specific Settings'),
          const SizedBox(height: 8),
          Text(
            'Configure settings that apply only to specific programming languages.',
            style: context.bodyMedium?.copyWith(
              color: context.onSurface.addOpacity(0.7),
            ),
          ),
          const SizedBox(height: 24),
          _buildLanguageConfigsList(),
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

  Widget _buildLanguageConfigsList() {
    final entries = _settings.languageConfigs.entries.toList();
    if (entries.isEmpty) {
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
        final languageName = MonacoData.availableLanguages.firstWhere(
            (lang) => lang['value'] == entry.key,
            orElse: () => {'value': entry.key, 'text': entry.key})['text'];

        return ListTile(
          contentPadding: const EdgeInsetsDirectional.symmetric(
              horizontal: 16, vertical: 8),
          leading: Icon(Icons.language, color: context.primary),
          title: Text(languageName ?? entry.key, style: context.bodyLarge),
          subtitle: Text(
            _getLanguageConfigSummary(entry.value),
            style: context.bodySmall
                ?.copyWith(color: context.onSurface.addOpacity(0.6)),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: Icon(Icons.edit_outlined,
                    color: context.onSurface.addOpacity(0.7)),
                tooltip: 'Edit',
                onPressed: () =>
                    _showLanguageSettingsDialog(context, language: entry.key),
              ),
              IconButton(
                icon: Icon(Icons.delete_outline, color: context.error),
                tooltip: 'Remove',
                onPressed: () => _removeLanguageConfig(entry.key),
              ),
            ],
          ),
          onTap: () =>
              _showLanguageSettingsDialog(context, language: entry.key),
        );
      },
    );
  }

  String _getLanguageConfigSummary(LanguageConfig config) {
    final parts = <String>[];
    if (config.tabSize != null) parts.add('Tab Size: ${config.tabSize}');
    if (config.insertSpaces != null) {
      parts.add(config.insertSpaces! ? 'Use Spaces' : 'Use Tabs');
    }
    if (config.wordWrap != null && config.wordWrap != WordWrap.off) {
      parts.add('Word Wrap: ${config.wordWrap!.name.capitalize()}');
    }
    if (config.formatOnSave != null && config.formatOnSave!) {
      parts.add('Format on Save');
    }
    return parts.isNotEmpty ? parts.join(', ') : 'Default settings';
  }

  void _removeLanguageConfig(String language) {
    setState(() {
      _settings.languageConfigs.remove(language);
      _settings = _settings.copyWith(
        languageConfigs: Map.from(_settings.languageConfigs),
      );
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Removed configuration for $language'),
        backgroundColor: context.error,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _showLanguageSettingsDialog(BuildContext context,
      {String? language}) async {
    final result = await showDialog<MapEntry<String, LanguageConfig>?>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _LanguageSettingsDialog(
        currentConfigs: _settings.languageConfigs,
        language: language,
        initialConfig:
            language != null ? _settings.languageConfigs[language] : null,
      ),
    );

    if (result != null) {
      setState(() {
        final newConfigs =
            Map<String, LanguageConfig>.from(_settings.languageConfigs);
        newConfigs[result.key] = result.value;
        _settings = _settings.copyWith(languageConfigs: newConfigs);
      });
    }
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
            subtitle: 'Enable smooth scrolling animations',
            value: _settings.smoothScrolling,
            onChanged: (value) {
              setState(() {
                _settings = _settings.copyWith(smoothScrolling: value);
              });
            },
          ),
          _buildSwitchTile(
            title: 'Disable Layer Hinting',
            subtitle: 'May improve performance on some devices',
            value: _settings.disableLayerHinting,
            onChanged: (value) {
              setState(() {
                _settings = _settings.copyWith(disableLayerHinting: value);
              });
            },
          ),
          _buildSwitchTile(
            title: 'Disable Monospace Optimizations',
            subtitle: 'Disable font optimizations for monospace fonts',
            value: _settings.disableMonospaceOptimizations,
            onChanged: (value) {
              setState(() {
                _settings =
                    _settings.copyWith(disableMonospaceOptimizations: value);
              });
            },
          ),
          const SizedBox(height: 32),
          _buildSectionHeader('Accessibility'),
          const SizedBox(height: 16),
          _buildDropdownField<AccessibilitySupport>(
            label: 'Accessibility Support',
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
          _buildSectionHeader('Reset & Backup'),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _showResetDialog,
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
                  onPressed: _exportSettings,
                  icon: const Icon(Icons.download),
                  label: const Text('Export Settings'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _importSettings,
                  icon: const Icon(Icons.upload),
                  label: const Text('Import Settings'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: context.titleMedium?.copyWith(
        fontWeight: FontWeight.w600,
        color: context.onSurface,
      ),
    );
  }

  Widget _buildDropdownField<T>({
    required String label,
    required T value,
    required List<T> items,
    String Function(T)? itemBuilder,
    void Function(T?)? onChanged,
    String? hint,
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
            decoration: InputDecoration(
              border: InputBorder.none,
              contentPadding: const EdgeInsetsDirectional.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
              hintText: hint,
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
    required FocusNode focusNode,
    required double min,
    required double max,
    required void Function(double) onChanged,
    double step = 1.0,
    String? suffix,
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
            focusNode: focusNode,
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

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required void Function(bool) onChanged,
  }) {
    return Container(
      margin: const EdgeInsetsDirectional.only(bottom: 12),
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
                  activeColor: context.primary,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildThemeCategorySection(
      ThemeCategory category, List<EditorTheme> themes) {
    final categoryThemes = themes.where((t) => t.category == category).toList();
    if (categoryThemes.isEmpty) return const SizedBox.shrink();

    String categoryName;
    switch (category) {
      case ThemeCategory.light:
        categoryName = 'Light Themes';
      case ThemeCategory.dark:
        categoryName = 'Dark Themes';
      case ThemeCategory.highContrast:
        categoryName = 'High Contrast';
      case ThemeCategory.custom:
        categoryName = 'Custom Themes';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          categoryName,
          style: context.labelLarge?.copyWith(
            fontWeight: FontWeight.w600,
            color: context.onSurface.addOpacity(0.8),
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: categoryThemes.map((theme) {
            final isSelected = _settings.theme == theme.id;
            final previewColors = ThemeManager.getThemePreviewColors(theme);

            return InkWell(
              onTap: () {
                setState(() {
                  _settings = _settings.copyWith(theme: theme.id);
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
                        color: Color(int.parse(previewColors['background']!
                            .replaceFirst('#', '0xFF'))),
                      ),
                      child: Column(
                        children: [
                          Container(
                            height: 20,
                            decoration: BoxDecoration(
                              color: Color(int.parse(previewColors['accent']!
                                      .replaceFirst('#', '0xFF')))
                                  .addOpacity(0.1),
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
                                      color: Color(int.parse(
                                          previewColors['lineNumber']!
                                              .replaceFirst('#', '0xFF'))),
                                      borderRadius: BorderRadius.circular(1),
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Container(
                                          height: 2,
                                          width: double.infinity,
                                          color: Color(int.parse(
                                              previewColors['foreground']!
                                                  .replaceFirst('#', '0xFF'))),
                                        ),
                                        const SizedBox(height: 2),
                                        Container(
                                          height: 2,
                                          width: 40,
                                          color: Color(int.parse(
                                              previewColors['accent']!
                                                  .replaceFirst('#', '0xFF'))),
                                        ),
                                        const SizedBox(height: 2),
                                        Container(
                                          height: 2,
                                          width: 60,
                                          color: Color(int.parse(
                                                  previewColors['foreground']!
                                                      .replaceFirst(
                                                          '#', '0xFF')))
                                              .addOpacity(0.7),
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

  Widget _buildPreviewSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Preview'),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsetsDirectional.all(16),
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
                    fontFamily: _settings.fontFamily.split(',').first.trim(),
                    fontSize: _settings.fontSize * 0.9,
                    height: _settings.lineHeight,
                    letterSpacing: _settings.letterSpacing,
                    color: context.onSurface.addOpacity(0.4),
                  ),
                ),
                Container(
                  width: 1,
                  height: 50,
                  margin: const EdgeInsetsDirectional.symmetric(horizontal: 12),
                  color: context.onSurface.addOpacity(0.1),
                ),
              ],
              Expanded(
                child: Text(
                  'Sample code preview\nfunc main() {\n    print("Hello, World!")\n}',
                  style: TextStyle(
                    fontFamily: _settings.fontFamily.split(',').first.trim(),
                    fontSize: _settings.fontSize,
                    height: _settings.lineHeight,
                    letterSpacing: _settings.letterSpacing,
                    color: context.onSurface,
                  ),
                  softWrap: _settings.wordWrap != WordWrap.off,
                  overflow: _settings.wordWrap != WordWrap.off
                      ? TextOverflow.visible
                      : TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildShortcutsPreview() {
    // Get current preset shortcuts
    final preset =
        KeybindingManager.findPresetById(_settings.keybindingPreset.name);
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

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsetsDirectional.all(24),
      decoration: BoxDecoration(
        color: context.surface,
        border: Border(
          top: BorderSide(
            color: context.onSurface.addOpacity(0.1),
          ),
        ),
      ),
      child: Row(
        children: [
          TextButton.icon(
            onPressed: _loadPreset,
            icon: const Icon(Icons.category_outlined),
            label: const Text('Load Preset'),
          ),
          const Spacer(),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          const SizedBox(width: 12),
          FilledButton(
            onPressed: () async {
              await EditorSettingsService.save(_settings);
              if (mounted) {
                Navigator.of(context).pop(_settings);
              }
            },
            child: const Text('Apply Settings'),
          ),
        ],
      ),
    );
  }

  Future<void> _loadPreset() async {
    await showDialog<dynamic>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Load Preset'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final presetName in [
              'beginner',
              'developer',
              'poweruser',
              'accessibility'
            ])
              ListTile(
                title: Text(presetName.capitalize()),
                subtitle: Text(_getPresetDescription(presetName)),
                onTap: () {
                  setState(() {
                    _settings = EditorSettings.createPreset(presetName);
                    // Update form controllers
                    _fontSizeController.text = _settings.fontSize.toString();
                    _lineHeightController.text =
                        _settings.lineHeight.toString();
                    _letterSpacingController.text =
                        _settings.letterSpacing.toString();
                    _tabSizeController.text = _settings.tabSize.toString();
                    _wordWrapColumnController.text =
                        _settings.wordWrapColumn.toString();
                  });
                  Navigator.of(context).pop();
                },
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  String _getPresetDescription(String preset) {
    switch (preset) {
      case 'beginner':
        return 'Larger font, word wrap enabled, helpful features';
      case 'developer':
        return 'Balanced settings for daily development';
      case 'poweruser':
        return 'Advanced features, compact layout';
      case 'accessibility':
        return 'Optimized for screen readers and visibility';
      default:
        return '';
    }
  }

  Future<void> _showResetDialog() async {
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
              setState(() {
                _settings = const EditorSettings();
                // Update form controllers
                _fontSizeController.text = _settings.fontSize.toString();
                _lineHeightController.text = _settings.lineHeight.toString();
                _letterSpacingController.text =
                    _settings.letterSpacing.toString();
                _tabSizeController.text = _settings.tabSize.toString();
                _wordWrapColumnController.text =
                    _settings.wordWrapColumn.toString();
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

  Future<void> _exportSettings() async {
    final settingsJson = jsonEncode(MonacoSettingsConverter.toMonacoOptions(_settings));
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
        if (mounted) {
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
      if (mounted) {
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

  Future<void> _importSettings() async {
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

        setState(() {
          _settings = newSettings;
          // Update all form controllers
          _fontSizeController.text = _settings.fontSize.toString();
          _lineHeightController.text = _settings.lineHeight.toString();
          _letterSpacingController.text = _settings.letterSpacing.toString();
          _tabSizeController.text = _settings.tabSize.toString();
          _wordWrapColumnController.text = _settings.wordWrapColumn.toString();
          // ... update other controllers for all tabs ...
        });

        if (mounted) {
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
      if (mounted) {
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

class _LanguageSettingsDialog extends StatefulWidget {
  const _LanguageSettingsDialog({
    required this.currentConfigs,
    this.language,
    this.initialConfig,
  });

  final Map<String, LanguageConfig> currentConfigs;
  final String? language;
  final LanguageConfig? initialConfig;

  @override
  State<_LanguageSettingsDialog> createState() =>
      _LanguageSettingsDialogState();
}

class _LanguageSettingsDialogState extends State<_LanguageSettingsDialog> {
  String? _selectedLanguage;
  late LanguageConfig _config;

  final _tabSizeController = TextEditingController();
  final _rulersController =
      TextEditingController(); // For comma-separated numbers

  @override
  void initState() {
    super.initState();
    _selectedLanguage = widget.language;
    _config = widget.initialConfig ?? const LanguageConfig();

    _tabSizeController.text = _config.tabSize?.toString() ?? '';
    _rulersController.text = _config.rulers?.join(',') ?? '';
  }

  @override
  void dispose() {
    _tabSizeController.dispose();
    _rulersController.dispose();
    super.dispose();
  }

  List<DropdownMenuItem<String>> _getLanguageDropdownItems() {
    final existingKeys = widget.currentConfigs.keys.toSet();
    if (widget.language != null) {
      // If editing, allow current language
      existingKeys.remove(widget.language);
    }

    return MonacoData.availableLanguages
        .where((lang) => !existingKeys.contains(lang['value']))
        .map((lang) => DropdownMenuItem<String>(
              value: lang['value'],
              child: Text(lang['text'] ?? lang['value']!),
            ))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.themeData;
    final isEditing = widget.language != null;

    return AlertDialog(
      title: Text(isEditing
          ? 'Edit ${MonacoData.availableLanguages.firstWhere((l) => l['value'] == _selectedLanguage, orElse: () => {
                'text': _selectedLanguage!
              })['text']} Settings'
          : 'Add Language-Specific Settings'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            if (!isEditing)
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(labelText: 'Language'),
                value: _selectedLanguage,
                items: _getLanguageDropdownItems(),
                onChanged: (value) {
                  setState(() {
                    _selectedLanguage = value;
                  });
                },
                validator: (value) =>
                    value == null ? 'Please select a language' : null,
              )
            else
              Padding(
                padding: const EdgeInsetsDirectional.only(bottom: 16),
                child: Text(
                    'Editing settings for: ${MonacoData.availableLanguages.firstWhere((l) => l['value'] == _selectedLanguage, orElse: () => {
                          'text': _selectedLanguage!
                        })['text']}',
                    style: theme.titleMedium),
              ),
            const SizedBox(height: 16),
            _buildTextField(
                controller: _tabSizeController,
                label: 'Tab Size (Optional)',
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                onChanged: (value) {
                  final val = int.tryParse(value);
                  _config = _config.copyWith(tabSize: val);
                }),
            const SizedBox(height: 16),
            _buildSwitch(
              label: 'Insert Spaces (Optional)',
              value: _config.insertSpaces,
              onChanged: (value) {
                setState(() {
                  _config = _config.copyWith(insertSpaces: value);
                });
              },
            ),
            const SizedBox(height: 16),
            _buildDropdown<WordWrap>(
              label: 'Word Wrap (Optional)',
              value: _config.wordWrap,
              items: [null, ...WordWrap.values],
              // Allow clearing
              itemBuilder: (ww) =>
                  ww == null ? 'Default' : ww.name.capitalize(),
              onChanged: (value) {
                setState(() {
                  _config = _config.copyWith(wordWrap: value);
                });
              },
            ),
            const SizedBox(height: 16),
            _buildTextField(
                controller: _rulersController,
                label: 'Rulers (Optional, e.g., 80,100)',
                keyboardType: TextInputType.text,
                onChanged: (value) {
                  final rulers = value
                      .split(',')
                      .map((s) => int.tryParse(s.trim()))
                      .whereType<int>()
                      .toList();
                  _config = _config.copyWith(
                      rulers: rulers.isNotEmpty ? rulers : null);
                }),
            const SizedBox(height: 16),
            _buildSwitch(
              label: 'Format on Save (Optional)',
              value: _config.formatOnSave,
              onChanged: (value) {
                setState(() {
                  _config = _config.copyWith(formatOnSave: value);
                });
              },
            ),
            _buildSwitch(
              label: 'Format on Paste (Optional)',
              value: _config.formatOnPaste,
              onChanged: (value) {
                setState(() {
                  _config = _config.copyWith(formatOnPaste: value);
                });
              },
            ),
            _buildSwitch(
              label: 'Format on Type (Optional)',
              value: _config.formatOnType,
              onChanged: (value) {
                setState(() {
                  _config = _config.copyWith(formatOnType: value);
                });
              },
            ),
            _buildSwitch(
              label: 'Bracket Pair Colorization (Optional)',
              value: _config.bracketPairColorization,
              onChanged: (value) {
                setState(() {
                  _config = _config.copyWith(bracketPairColorization: value);
                });
              },
            ),
          ],
        ),
      ),
      actions: <Widget>[
        TextButton(
          child: const Text('Cancel'),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        FilledButton(
          child: const Text('Save'),
          onPressed: () {
            if (_selectedLanguage != null) {
              // Clear fields if they are empty strings after editing, to truly make them null
              final finalConfig = _config.copyWith(
                tabSize:
                    _tabSizeController.text.isEmpty ? null : _config.tabSize,
                rulers: _rulersController.text.isEmpty ? null : _config.rulers,
              );
              Navigator.of(context)
                  .pop(MapEntry(_selectedLanguage!, finalConfig));
            } else if (!isEditing) {
              // Show error if no language selected when adding
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('Please select a language.'),
                  backgroundColor: Theme.of(context).colorScheme.error,
                ),
              );
            }
          },
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required ValueChanged<String> onChanged,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      onChanged: onChanged,
    );
  }

  Widget _buildSwitch({
    required String label,
    required ValueChanged<bool?> onChanged,
    bool? value, // Nullable for tri-state (default, true, false)
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: context.bodyMedium),
        Switch(
          value: value ?? false, // Default to false for switch UI if null
          onChanged: (newValue) {
            // If it was null, toggle to true. If true, to false. If false, to null (clear).
            if (value == null) {
              onChanged(true);
            } else if (value == true) {
              onChanged(false);
            } else {
              onChanged(null); // This allows clearing the setting
            }
          },
          activeColor: context.primary,
          // tristate: true, // Enable if you want visual tristate
        ),
      ],
    );
  }

  Widget _buildDropdown<T>({
    required String label,
    T? value,
    required List<T?> items,
    required String Function(T?) itemBuilder,
    required void Function(T?)? onChanged,
  }) {
    return DropdownButtonFormField<T?>(
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      value: value,
      items: items.map((item) {
        return DropdownMenuItem<T?>(
          value: item,
          child: Text(itemBuilder(item)),
        );
      }).toList(),
      onChanged: onChanged,
    );
  }
}

extension StringExtension on String {
  String capitalize() {
    if (isEmpty) return this;
    return this[0].toUpperCase() + substring(1);
  }
}
