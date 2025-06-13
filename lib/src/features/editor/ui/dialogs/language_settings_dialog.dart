import 'package:context_collector/context_collector.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_helper_utils/flutter_helper_utils.dart';

/// Dialog for configuring language-specific settings
class LanguageSettingsDialog extends StatefulWidget {
  const LanguageSettingsDialog({
    required this.currentConfigs,
    this.language,
    this.initialConfig,
    super.key,
  });

  final Map<String, LanguageConfig> currentConfigs;
  final String? language;
  final LanguageConfig? initialConfig;

  @override
  State<LanguageSettingsDialog> createState() => _LanguageSettingsDialogState();
}

class _LanguageSettingsDialogState extends State<LanguageSettingsDialog> {
  String? _selectedLanguage;
  late LanguageConfig _config;

  final _tabSizeController = TextEditingController();
  final _rulersController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _selectedLanguage = widget.language;
    _config = widget.initialConfig ?? const LanguageConfig();

    _tabSizeController.text = _config.tabSize?.toString() ?? '';
    _rulersController.text = _config.rulers.join(',');
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
      existingKeys.remove(widget.language);
    }

    return EditorConstants.languages.entries
        .where((entry) => !existingKeys.contains(entry.key))
        .map(
          (entry) => DropdownMenuItem<String>(
            value: entry.key,
            child: Text(entry.value),
          ),
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.themeData;
    final isEditing = widget.language != null;

    return AlertDialog(
      title: Text(
        isEditing
            ? 'Edit ${EditorConstants.languages[_selectedLanguage] ?? _selectedLanguage} Settings'
            : 'Add Language-Specific Settings',
      ),
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
                  'Editing settings for: ${EditorConstants.languages[_selectedLanguage] ?? _selectedLanguage}',
                  style: theme.titleMedium,
                ),
              ),
            const SizedBox(height: 16),
            _buildTabSizeField(),
            const SizedBox(height: 16),
            _buildInsertSpacesSwitch(),
            const SizedBox(height: 16),
            _buildWordWrapDropdown(),
            const SizedBox(height: 16),
            _buildRulersField(),
            const SizedBox(height: 16),
            _buildFormatOptions(),
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
              final finalConfig = _config.copyWith(
                tabSize: _tabSizeController.text.isEmpty
                    ? null
                    : _config.tabSize,
                rulers: _rulersController.text.isEmpty ? [] : _config.rulers,
              );
              Navigator.of(context).pop(
                MapEntry(_selectedLanguage!, finalConfig),
              );
            } else if (!isEditing) {
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

  Widget _buildTabSizeField() {
    return TextFormField(
      controller: _tabSizeController,
      decoration: const InputDecoration(
        labelText: 'Tab Size (Optional)',
        border: OutlineInputBorder(),
      ),
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      onChanged: (value) {
        final val = int.tryParse(value);
        _config = _config.copyWith(tabSize: val);
      },
    );
  }

  Widget _buildInsertSpacesSwitch() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text('Insert Spaces (Optional)', style: context.bodyMedium),
        Switch(
          value: _config.insertSpaces ?? false,
          onChanged: (newValue) {
            setState(() {
              if (_config.insertSpaces == null) {
                _config = _config.copyWith(insertSpaces: true);
              } else if (_config.insertSpaces == true) {
                _config = _config.copyWith(insertSpaces: false);
              } else {
                _config = _config.copyWith(insertSpaces: null);
              }
            });
          },
          activeColor: context.primary,
        ),
      ],
    );
  }

  Widget _buildWordWrapDropdown() {
    return DropdownButtonFormField<WordWrap?>(
      decoration: const InputDecoration(
        labelText: 'Word Wrap (Optional)',
        border: OutlineInputBorder(),
      ),
      value: _config.wordWrap,
      items: [
        const DropdownMenuItem<WordWrap?>(
          value: null,
          child: Text('Default'),
        ),
        ...WordWrap.values.map(
          (ww) => DropdownMenuItem<WordWrap?>(
            value: ww,
            child: Text(ww.name.toTitle),
          ),
        ),
      ],
      onChanged: (value) {
        setState(() {
          _config = _config.copyWith(wordWrap: value);
        });
      },
    );
  }

  Widget _buildRulersField() {
    return TextFormField(
      controller: _rulersController,
      decoration: const InputDecoration(
        labelText: 'Rulers (Optional, e.g., 80,100)',
        border: OutlineInputBorder(),
      ),
      onChanged: (value) {
        final rulers = value
            .split(',')
            .map((s) => int.tryParse(s.trim()))
            .whereType<int>()
            .toList();
        _config = _config.copyWith(rulers: rulers);
      },
    );
  }

  Widget _buildFormatOptions() {
    return Column(
      children: [
        SwitchListTile(
          title: const Text('Format on Save (Optional)'),
          value: _config.formatOnSave ?? false,
          onChanged: (value) {
            setState(() {
              _config = _config.copyWith(formatOnSave: value);
            });
          },
        ),
        SwitchListTile(
          title: const Text('Format on Paste (Optional)'),
          value: _config.formatOnPaste ?? false,
          onChanged: (value) {
            setState(() {
              _config = _config.copyWith(formatOnPaste: value);
            });
          },
        ),
        SwitchListTile(
          title: const Text('Format on Type (Optional)'),
          value: _config.formatOnType ?? false,
          onChanged: (value) {
            setState(() {
              _config = _config.copyWith(formatOnType: value);
            });
          },
        ),
        SwitchListTile(
          title: const Text('Bracket Pair Colorization (Optional)'),
          value: _config.bracketPairColorization ?? false,
          onChanged: (value) {
            setState(() {
              _config = _config.copyWith(bracketPairColorization: value);
            });
          },
        ),
      ],
    );
  }
}
