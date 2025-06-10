import 'package:context_collector/context_collector.dart';
import 'package:flutter/material.dart';

/// Row displaying editor statistics
class StatsRow extends StatelessWidget {
  const StatsRow({
    required this.stats,
    required this.content,
    super.key,
  });

  final LiveStats stats;
  final String content;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        StatItem(
          label: stats.lineCount.label,
          value: stats.lineCount.value,
        ),
        StatItem(
          label: stats.charCount.label,
          value: stats.charCount.value,
        ),
        if (stats.hasSelection) ...[
          StatItem(
            label: stats.selectedLines.label,
            value: stats.selectedLines.value,
          ),
          StatItem(
            label: stats.selectedCharacters.label,
            value: stats.selectedCharacters.value,
          ),
        ],
        if (stats.caretCount.value > 1)
          StatItem(
            label: stats.caretCount.label,
            value: stats.caretCount.value,
          ),
        if (stats.charCount.value > 0) TokenCountChip(content: content),
      ],
    );
  }
}

/// Individual stat item widget
class StatItem extends StatelessWidget {
  const StatItem({
    required this.label,
    required this.value,
    super.key,
  });

  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Text(
        '$label: $value',
        style: context.labelSmall?.copyWith(color: context.onSurfaceVariant),
      ),
    );
  }
}
