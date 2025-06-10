import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Reusable switch tile for settings
class SettingsSwitchTile extends StatelessWidget {
  const SettingsSwitchTile({
    required this.title,
    required this.value,
    required this.onChanged,
    super.key,
    this.subtitle,
    this.activeColor,
  });

  final String title;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  final Color? activeColor;

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      title: Text(title),
      subtitle: subtitle != null ? Text(subtitle!) : null,
      value: value,
      onChanged: onChanged,
      activeColor: activeColor ?? Theme.of(context).colorScheme.primary,
    );
  }
}

/// Reusable number field for settings
class SettingsNumberField extends StatelessWidget {
  const SettingsNumberField({
    required this.label,
    required this.controller,
    required this.onChanged,
    super.key,
    this.min,
    this.max,
    this.decimals = 0,
    this.suffix,
    this.helperText,
  });

  final String label;
  final TextEditingController controller;
  final ValueChanged<double?> onChanged;
  final double? min;
  final double? max;
  final int decimals;
  final String? suffix;
  final String? helperText;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        helperText: helperText,
        suffix: suffix != null ? Text(suffix!) : null,
        border: const OutlineInputBorder(),
      ),
      keyboardType: TextInputType.numberWithOptions(decimal: decimals > 0),
      inputFormatters: [
        if (decimals > 0)
          FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))
        else
          FilteringTextInputFormatter.digitsOnly,
      ],
      onChanged: (value) {
        final parsed = double.tryParse(value);
        if (parsed != null) {
          if (min != null && parsed < min!) {
            controller.text = min!.toString();
            onChanged(min);
          } else if (max != null && parsed > max!) {
            controller.text = max!.toString();
            onChanged(max);
          } else {
            onChanged(parsed);
          }
        } else {
          onChanged(null);
        }
      },
    );
  }
}

/// Reusable dropdown field for settings
class SettingsDropdownField<T> extends StatelessWidget {
  const SettingsDropdownField({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
    super.key,
    this.itemBuilder,
    this.helperText,
  });

  final String label;
  final T value;
  final List<T> items;
  final ValueChanged<T?> onChanged;
  final String Function(T)? itemBuilder;
  final String? helperText;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<T>(
      decoration: InputDecoration(
        labelText: label,
        helperText: helperText,
        border: const OutlineInputBorder(),
      ),
      value: value,
      items: items.map((item) {
        return DropdownMenuItem<T>(
          value: item,
          child: Text(itemBuilder?.call(item) ?? item.toString()),
        );
      }).toList(),
      onChanged: onChanged,
    );
  }
}

/// Reusable text field for settings
class SettingsTextField extends StatelessWidget {
  const SettingsTextField({
    required this.label,
    required this.controller,
    required this.onChanged,
    super.key,
    this.helperText,
    this.maxLines = 1,
    this.keyboardType,
    this.inputFormatters,
  });

  final String label;
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final String? helperText;
  final int maxLines;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        helperText: helperText,
        border: const OutlineInputBorder(),
      ),
      maxLines: maxLines,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      onChanged: onChanged,
    );
  }
}

/// Reusable color picker for settings
class SettingsColorPicker extends StatelessWidget {
  const SettingsColorPicker({
    required this.label,
    required this.color,
    required this.onColorChanged,
    super.key,
    this.helperText,
  });

  final String label;
  final Color color;
  final ValueChanged<Color> onColorChanged;
  final String? helperText;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => _showColorPicker(context),
      borderRadius: BorderRadius.circular(8),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          helperText: helperText,
          border: const OutlineInputBorder(),
        ),
        child: Row(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color: Theme.of(context).dividerColor,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              '#${color.value.toRadixString(16).substring(2).toUpperCase()}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showColorPicker(BuildContext context) async {
    // Simple color picker dialog
    final colors = [
      Colors.red,
      Colors.pink,
      Colors.purple,
      Colors.deepPurple,
      Colors.indigo,
      Colors.blue,
      Colors.lightBlue,
      Colors.cyan,
      Colors.teal,
      Colors.green,
      Colors.lightGreen,
      Colors.lime,
      Colors.yellow,
      Colors.amber,
      Colors.orange,
      Colors.deepOrange,
      Colors.brown,
      Colors.grey,
      Colors.blueGrey,
    ];

    final selectedColor = await showDialog<Color>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(label),
        content: SizedBox(
          width: 280,
          child: GridView.builder(
            shrinkWrap: true,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 5,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemCount: colors.length,
            itemBuilder: (context, index) {
              final itemColor = colors[index];
              return InkWell(
                onTap: () => Navigator.of(context).pop(itemColor),
                borderRadius: BorderRadius.circular(4),
                child: Container(
                  decoration: BoxDecoration(
                    color: itemColor,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                      color: itemColor == color
                          ? Theme.of(context).colorScheme.primary
                          : Colors.transparent,
                      width: 2,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );

    if (selectedColor != null) {
      onColorChanged(selectedColor);
    }
  }
}

/// Reusable section header for settings
class SettingsSectionHeader extends StatelessWidget {
  const SettingsSectionHeader({
    required this.title,
    super.key,
    this.subtitle,
  });

  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 4),
          Text(
            subtitle!,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
        ],
      ],
    );
  }
}
