import 'package:context_collector/context_collector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_helper_utils/flutter_helper_utils.dart';

/// General settings tab for the editor settings dialog
class GeneralTab extends StatelessWidget {
  const GeneralTab({
    required this.settings,
    required this.fontSizeController,
    required this.lineHeightController,
    required this.letterSpacingController,
    required this.fontSizeFocus,
    required this.lineHeightFocus,
    required this.letterSpacingFocus,
    required this.onSettingsChanged,
    super.key,
  });

  final EditorSettings settings;
  final TextEditingController fontSizeController;
  final TextEditingController lineHeightController;
  final TextEditingController letterSpacingController;
  final FocusNode fontSizeFocus;
  final FocusNode lineHeightFocus;
  final FocusNode letterSpacingFocus;
  final ValueChanged<EditorSettings> onSettingsChanged;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsetsDirectional.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SettingsSectionHeader(title: 'Font & Typography'),
          const SizedBox(height: 16),
          _buildFontFamilyDropdown(context),
          const SizedBox(height: 16),
          _buildFontControls(context),
          const SizedBox(height: 32),
          const SettingsSectionHeader(title: 'Basic Options'),
          const SizedBox(height: 16),
          _buildBasicOptions(context),
          const SizedBox(height: 32),
          _buildPreviewSection(context),
        ],
      ),
    );
  }

  Widget _buildFontFamilyDropdown(BuildContext context) {
    return SettingsDropdownField<String>(
      label: 'Font Family',
      value: settings.fontFamily,
      items: EditorConstants.fontFamilies,
      onChanged: (value) {
        if (value != null) {
          onSettingsChanged(settings.copyWith(fontFamily: value));
        }
      },
      helperText: 'Select font family',
    );
  }

  Widget _buildFontControls(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: SettingsNumberField(
            label: 'Font Size',
            controller: fontSizeController,
            min: EditorConstants.minFontSize,
            max: EditorConstants.maxFontSize,
            suffix: 'px',
            onChanged: (value) {
              if (value != null) {
                onSettingsChanged(settings.copyWith(fontSize: value));
              }
            },
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: SettingsNumberField(
            label: 'Line Height',
            controller: lineHeightController,
            min: 1,
            max: 3,
            decimals: 1,
            onChanged: (value) {
              if (value != null) {
                onSettingsChanged(settings.copyWith(lineHeight: value));
              }
            },
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: SettingsNumberField(
            label: 'Letter Spacing',
            controller: letterSpacingController,
            min: -2,
            max: 5,
            decimals: 1,
            suffix: 'px',
            onChanged: (value) {
              if (value != null) {
                onSettingsChanged(settings.copyWith(letterSpacing: value));
              }
            },
          ),
        ),
      ],
    );
  }

  Widget _buildBasicOptions(BuildContext context) {
    return Column(
      children: [
        SettingsSwitchTile(
          title: 'Read Only',
          subtitle: 'Make editor read-only (view mode)',
          value: settings.readOnly,
          onChanged: (value) {
            onSettingsChanged(settings.copyWith(readOnly: value));
          },
        ),
        SettingsSwitchTile(
          title: 'Automatic Layout',
          subtitle: 'Automatically adjust editor size',
          value: settings.automaticLayout,
          onChanged: (value) {
            onSettingsChanged(settings.copyWith(automaticLayout: value));
          },
        ),
        SettingsSwitchTile(
          title: 'Mouse Wheel Zoom',
          subtitle: 'Enable zooming with Ctrl+Mouse wheel',
          value: settings.mouseWheelZoom,
          onChanged: (value) {
            onSettingsChanged(settings.copyWith(mouseWheelZoom: value));
          },
        ),
      ],
    );
  }

  Widget _buildPreviewSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SettingsSectionHeader(title: 'Preview'),
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
              if (settings.showLineNumbers) ...[
                Text(
                  '1\n2\n3',
                  style: TextStyle(
                    fontFamily: settings.fontFamily.split(',').first.trim(),
                    fontSize: settings.fontSize * 0.9,
                    height: settings.lineHeight,
                    letterSpacing: settings.letterSpacing,
                    color: context.onSurfaceVariant.addOpacity(0.4),
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
                    fontFamily: settings.fontFamily.split(',').first.trim(),
                    fontSize: settings.fontSize,
                    height: settings.lineHeight,
                    letterSpacing: settings.letterSpacing,
                    color: context.onSurface,
                  ),
                  softWrap: settings.wordWrap != WordWrap.off,
                  overflow: settings.wordWrap != WordWrap.off
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
}
