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
