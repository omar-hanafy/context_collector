import 'package:flutter/material.dart';
import 'package:flutter_helper_utils/flutter_helper_utils.dart';

/// Shared app bar title widget used across the app
class AppBarTitle extends StatelessWidget {
  const AppBarTitle({this.compact = false, super.key});

  /// Render a tighter chip when true (for compact toolbars).
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = context.themeData;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Theme.of(context).colorScheme.primary,
                Theme.of(context).colorScheme.primary.withValues(alpha: 0.8),
              ],
            ),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(
            Icons.content_paste_search_rounded, // Clearer “context” icon
            color: Colors.white,
            size: 18,
          ),
        ),
        const SizedBox(width: 8),
        Text('Context Collector', style: theme.titleMedium),
      ],
    );
  }
}
