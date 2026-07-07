import 'package:context_collector/context_collector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_monaco/flutter_monaco.dart';

/// Language selector dropdown for the info bar
class LanguageSelector extends StatelessWidget {
  const LanguageSelector({
    required this.currentLanguage,
    required this.onLanguageChanged,
    super.key,
  });

  final String currentLanguage;
  final ValueChanged<String> onLanguageChanged;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      tooltip: 'Select Language',
      onSelected: onLanguageChanged,
      offset: const Offset(0, -300),
      itemBuilder: (_) => MonacoLanguage.builtIn.map((lang) {
        final isSelected = currentLanguage == lang.id;
        return PopupMenuItem<String>(
          value: lang.id,
          child: Row(
            children: [
              Icon(
                Icons.check,
                size: 16,
                color: isSelected ? context.primary : Colors.transparent,
              ),
              const SizedBox(width: 8),
              Text(lang.label ?? lang.id),
            ],
          ),
        );
      }).toList(),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: context.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: Theme.of(context).colorScheme.outlineVariant,
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Icon(Icons.translate, size: 16, color: context.primary),
            const SizedBox(width: 6),
            Text(
              MonacoLanguage(currentLanguage).label ?? currentLanguage,
              style: context.labelSmall?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.arrow_drop_down,
              size: 18,
              color: context.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }
}
