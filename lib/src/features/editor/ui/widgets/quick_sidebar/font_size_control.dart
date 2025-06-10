import 'package:context_collector/context_collector.dart';
import 'package:flutter/material.dart';

/// Font size control widget with increase/decrease buttons
class FontSizeControl extends StatelessWidget {
  const FontSizeControl({
    required this.fontSize,
    required this.onIncrease,
    required this.onDecrease,
    super.key,
  });

  final double fontSize;
  final VoidCallback onIncrease;
  final VoidCallback onDecrease;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(
          onPressed: fontSize > EditorConstants.minFontSize ? onDecrease : null,
          icon: Icon(
            Icons.remove,
            color: context.onSurfaceVariant,
          ),
          iconSize: 18,
          style: IconButton.styleFrom(
            minimumSize: const Size(32, 32),
          ),
          splashRadius: 0.1,
          highlightColor: Colors.transparent,
          splashColor: Colors.transparent,
          hoverColor: context.onSurface.addOpacity(0.04),
        ),
        Expanded(
          child: Container(
            height: 32,
            decoration: BoxDecoration(
              color: context.surface,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                '${fontSize.round()}px',
                style: context.labelLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ),
        IconButton(
          onPressed: fontSize < EditorConstants.maxFontSize ? onIncrease : null,
          icon: Icon(
            Icons.add,
            color: context.onSurfaceVariant,
          ),
          iconSize: 18,
          style: IconButton.styleFrom(
            minimumSize: const Size(32, 32),
          ),
          splashRadius: 0.1,
          highlightColor: Colors.transparent,
          splashColor: Colors.transparent,
          hoverColor: context.onSurface.addOpacity(0.04),
        ),
      ],
    );
  }
}
