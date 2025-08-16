import 'package:flutter/material.dart';
import 'package:flutter_monaco/flutter_monaco.dart';

import 'token_chip.dart';

/// Row displaying editor statistics
class StatsRow extends StatelessWidget {
  const StatsRow({
    required this.stats,
    super.key,
  });

  final LiveStats stats;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        StatItem(
          label: 'Ln',
          value: stats.lineCount.value,
        ),
        StatItem(
          label: 'Ch',
          value: stats.charCount.value,
        ),
        if (stats.selectedCharacters.value > 0) ...[
          StatItem(
            label: 'Sel Ln',
            value: stats.selectedLines.value,
          ),
          StatItem(
            label: 'Sel Ch',
            value: stats.selectedCharacters.value,
          ),
        ],
        if (stats.caretCount.value > 1)
          StatItem(
            label: 'Cursors',
            value: stats.caretCount.value,
          ),
        if (stats.charCount.value > 0) const TokenCountChip(),
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
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}
