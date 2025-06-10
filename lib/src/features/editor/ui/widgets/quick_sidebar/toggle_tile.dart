import 'package:context_collector/context_collector.dart';
import 'package:flutter/material.dart';

/// Reusable toggle tile widget for settings
class ToggleTile extends StatelessWidget {
  const ToggleTile({
    required this.icon,
    required this.title,
    required this.value,
    required this.onChanged,
    super.key,
  });

  final IconData icon;
  final String title;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: context.surface,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: () => onChanged(!value),
          borderRadius: BorderRadius.circular(8),
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
          hoverColor: context.onSurface.addOpacity(0.02),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 8,
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 18,
                  color: value ? context.primary : context.onSurfaceVariant,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: context.bodyMedium,
                  ),
                ),
                Switch(
                  value: value,
                  onChanged: onChanged,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
