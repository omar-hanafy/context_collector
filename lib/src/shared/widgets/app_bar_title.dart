import 'package:flutter/material.dart';

/// Shared app bar title widget used across the app (flat, calm)
class AppBarTitle extends StatelessWidget {
  const AppBarTitle({this.compact = false, super.key});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final textStyle = Theme.of(context).textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w600,
          color: cs.onSurface,
        );
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.content_paste_search_rounded,
          size: compact ? 16 : 18,
          color: cs.primary,
        ),
        const SizedBox(width: 8),
        Text('Context Collector', style: textStyle),
      ],
    );
  }
}
