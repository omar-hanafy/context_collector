import 'package:context_collector/context_collector.dart';
import 'package:flutter_helper_utils/flutter_helper_utils.dart';
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
    return Padding(
      padding: const EdgeInsets.only(bottom: DesignSystem.space8),
      child: DsTile(
        leading: Icon(
          icon,
          size: DesignSystem.iconSizeSmall + 2,
          color: value ? context.primary : context.onSurfaceVariant,
        ),
        title: Text(title),
        trailing: DsSwitch(
          value: value,
          onChanged: onChanged,
        ),
        onTap: () => onChanged(!value),
      ),
    );
  }
}
