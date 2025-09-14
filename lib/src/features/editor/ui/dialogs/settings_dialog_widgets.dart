import 'package:flutter/material.dart';
import 'package:flutter_monaco/flutter_monaco.dart';

/// A simple widget for section titles.
class SectionTitle extends StatelessWidget {
  const SectionTitle(this.title, {super.key});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleSmall?.copyWith(
        fontWeight: FontWeight.w600,
        color: Theme.of(context).colorScheme.primary,
      ),
    );
  }
}

/// A widget for a labeled dropdown, consistent with the dialog's style.
class DropdownTile extends StatelessWidget {
  const DropdownTile({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
    this.isExpanded = false,
    super.key,
  });

  final String label;
  final String value;
  final List<String> items;
  final ValueChanged<String> onChanged;
  final bool isExpanded;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(flex: 2, child: Text(label)),
          Expanded(
            flex: 3,
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(
                  color: Theme.of(context).colorScheme.outlineVariant,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  isExpanded: true,
                  value: items.contains(value) ? value : items.first,
                  items: items.map((item) {
                    final displayName = label == 'Theme'
                        ? MonacoTheme.fromId(item).label
                        : item;
                    return DropdownMenuItem(
                      value: item,
                      child: Text(
                        displayName,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    );
                  }).toList(),
                  onChanged: (v) => v != null ? onChanged(v) : null,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// A widget for a labeled text field, for numeric input.
class NumberField extends StatelessWidget {
  const NumberField({
    required this.label,
    required this.controller,
    required this.onChanged,
    super.key,
  });

  final String label;
  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(flex: 2, child: Text(label)),
          Expanded(
            flex: 3,
            child: TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              onChanged: onChanged,
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                isDense: true,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
