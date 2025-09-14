part of 'design_system.dart';

// ============================================================================
// KEEP THESE - They provide significant value
// ============================================================================

/// Chip/Badge component for status, tags, and labels - KEEP (unique styling)
class DsChip extends StatelessWidget {
  const DsChip({
    required this.label,
    super.key,
    this.backgroundColor,
    this.textColor,
    this.icon,
    this.onTap,
    this.onDeleted,
    this.dense = false,
    this.outlined = false,
  });

  final String label;
  final Color? backgroundColor;
  final Color? textColor;
  final Widget? icon;
  final VoidCallback? onTap;
  final VoidCallback? onDeleted;
  final bool dense;
  final bool outlined;

  @override
  Widget build(BuildContext context) {
    final bgColor = backgroundColor ?? context.primaryContainer.addOpacity(0.3);
    final fgColor = textColor ?? context.onSurface;

    final content = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null) ...[
          icon!,
          context.ds.spaceWidth(DesignSystem.space4),
        ],
        Text(
          label,
          style: (dense ? context.labelSmall : context.labelMedium)?.copyWith(
            color: fgColor,
            fontWeight: FontWeight.w500,
          ),
        ),
        if (onDeleted != null) ...[
          context.ds.spaceWidth(DesignSystem.space4),
          InkWell(
            onTap: onDeleted,
            borderRadius: BorderRadius.circular(10),
            child: Icon(
              Icons.close_rounded,
              size: dense ? 14 : 16,
              color: fgColor.addOpacity(0.7),
            ),
          ),
        ],
      ],
    );

    final chip = Container(
      padding: EdgeInsets.symmetric(
        horizontal: dense ? 8 : 12,
        vertical: dense ? 4 : 6,
      ),
      decoration: BoxDecoration(
        color: outlined ? Colors.transparent : bgColor,
        borderRadius: BorderRadius.circular(dense ? 4 : 6),
        border: outlined ? Border.all(color: bgColor, width: 1) : null,
      ),
      child: content,
    );

    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(dense ? 4 : 6),
        child: chip,
      );
    }
    return chip;
  }
}

/// Empty state widget with icon and optional actions - KEEP (complex layout)
class DsEmptyState extends StatelessWidget {
  const DsEmptyState({
    required this.icon,
    required this.title,
    super.key,
    this.subtitle,
    this.actions,
    this.customIcon,
    this.iconSize = 64,
    this.iconColor,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final List<Widget>? actions;
  final Widget? customIcon;
  final double iconSize;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: DsDimensions.paddingLarge,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            customIcon ??
                Icon(
                  icon,
                  size: iconSize,
                  color: iconColor ?? context.onSurfaceVariant.addOpacity(0.5),
                ),
            context.ds.spaceHeight(DesignSystem.space24),
            Text(
              title,
              style: context.titleMedium,
              textAlign: TextAlign.center,
            ),
            if (subtitle != null) ...[
              context.ds.spaceHeight(DesignSystem.space8),
              Text(
                subtitle!,
                style: context.bodyMuted,
                textAlign: TextAlign.center,
              ),
            ],
            if (actions != null && actions!.isNotEmpty) ...[
              context.ds.spaceHeight(DesignSystem.space24),
              ...actions!,
            ],
          ],
        ),
      ),
    );
  }
}

/// Consistent icon container with background - KEEP (common pattern)
class DsIconContainer extends StatelessWidget {
  const DsIconContainer({
    required this.icon,
    super.key,
    this.iconColor,
    this.backgroundColor,
    this.size = DesignSystem.iconSizeMedium,
    this.padding = DesignSystem.space8,
    this.borderRadius,
  });

  final IconData icon;
  final Color? iconColor;
  final Color? backgroundColor;
  final double size;
  final double padding;
  final BorderRadius? borderRadius;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(padding),
      decoration: BoxDecoration(
        color: backgroundColor ?? context.primaryContainer.addOpacity(0.2),
        borderRadius: borderRadius ?? BorderRadius.circular(8),
      ),
      child: Icon(
        icon,
        size: size,
        color: iconColor ?? context.primary,
      ),
    );
  }
}

/// Section header widget - KEEP (provides consistent styling)
class DsSectionHeader extends StatelessWidget {
  const DsSectionHeader({
    required this.title,
    super.key,
    this.subtitle,
    this.trailing,
  });

  final String title;
  final String? subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: context.titleBold),
              if (subtitle != null) ...[
                context.ds.spaceHeight(DesignSystem.space4),
                Text(subtitle!, style: context.bodyMuted),
              ],
            ],
          ),
        ),
        if (trailing != null) trailing!,
      ],
    );
  }
}

/// Status card for displaying info - KEEP (complex layout)
class DsStatusCard extends StatelessWidget {
  const DsStatusCard({
    required this.title,
    super.key,
    this.leading,
    this.subtitle,
    this.trailing,
    this.backgroundColor,
    this.showProgress = false,
    this.progress,
    this.progressLabel,
  });

  final Widget? leading;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final Color? backgroundColor;
  final bool showProgress;
  final double? progress;
  final String? progressLabel;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: DsDimensions.paddingMedium,
      decoration: BoxDecoration(
        color: backgroundColor ?? context.surface,
        borderRadius: context.ds.radiusMedium,
        border: Border.all(
          color: context.outlineVariant.addOpacity(0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (leading != null) ...[
                leading!,
                context.ds.spaceWidth(DesignSystem.space12),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: context.titleSmall),
                    if (subtitle != null) ...[
                      context.ds.spaceHeight(DesignSystem.space4),
                      Text(subtitle!, style: context.bodyMuted),
                    ],
                  ],
                ),
              ),
              if (trailing != null) ...[
                context.ds.spaceWidth(DesignSystem.space12),
                trailing!,
              ],
            ],
          ),
          if (showProgress) ...[
            context.ds.spaceHeight(DesignSystem.space12),
            ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: LinearProgressIndicator(
                value: progress,
                backgroundColor: context.surfaceContainerHighest,
                valueColor: AlwaysStoppedAnimation<Color>(context.primary),
                minHeight: 4,
              ),
            ),
            if (progressLabel != null) ...[
              context.ds.spaceHeight(DesignSystem.space4),
              Text(
                progressLabel!,
                style: context.labelSmall?.copyWith(
                  color: context.onSurfaceVariant,
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }
}

// ============================================================================
// REMOVED WIDGETS - Use Material widgets directly instead:
// ============================================================================
// DsCard → Use Card or Container
// DsTile → Use ListTile 
// DsButton → Use FilledButton, OutlinedButton, TextButton
// DsSwitch → Use Switch
// DsDropdown → Use DropdownButton  
// DsDivider → Use Divider
// DsProgress → Use LinearProgressIndicator or CircularProgressIndicator
// DsInfoRow → Use Row with Text widgets
