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
        _BrandGlyph(size: compact ? 16 : 18),
        const SizedBox(width: 8),
        Text('Context Collector', style: textStyle),
      ],
    );
  }
}

/// Small composite glyph that better conveys the app's identity:
/// a document/paste icon with a subtle "spark" overlay.
class _BrandGlyph extends StatelessWidget {
  const _BrandGlyph({required this.size});
  final double size;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final base = size;
    final spark = (size * 0.58).clamp(9.0, 12.0);

    return SizedBox(
      width: base,
      height: base,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Base document/paste icon
          Positioned.fill(
            child: Icon(
              Icons.content_paste_rounded,
              size: base,
              color: cs.primary,
              semanticLabel: 'Context Collector',
            ),
          ),
          // Spark overlay (slightly offset to top-right)
          Positioned(
            right: -base * 0.10,
            top: -base * 0.10,
            child: Icon(
              Icons.auto_awesome,
              size: spark,
              color: Colors.amber,
            ),
          ),
        ],
      ),
    );
  }
}
