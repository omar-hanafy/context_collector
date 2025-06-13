part of 'design_system.dart';

/// Base Design System Card widget
class DsCard extends StatelessWidget {
  const DsCard({
    required this.child,
    super.key,
    this.padding,
    this.margin,
    this.decoration,
    this.onTap,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final BoxDecoration? decoration;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final container = Container(
      padding: padding ?? DsDimensions.paddingMedium,
      margin: margin,
      decoration: decoration ?? context.ds.cardDecoration,
      child: child,
    );

    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        borderRadius:
            (decoration ?? context.ds.cardDecoration).borderRadius
                as BorderRadius?,
        child: container,
      );
    }
    return container;
  }
}

/// Base Design System Tile widget
class DsTile extends StatelessWidget {
  const DsTile({
    required this.title,
    super.key,
    this.subtitle,
    this.leading,
    this.trailing,
    this.onTap,
    this.padding,
    this.isSelected = false,
  });

  final Widget title;
  final Widget? subtitle;
  final Widget? leading;
  final Widget? trailing;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry? padding;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isSelected ? context.primaryOverlay : Colors.transparent,
      borderRadius: context.ds.radiusMedium,
      child: InkWell(
        onTap: onTap,
        borderRadius: context.ds.radiusMedium,
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        hoverColor: context.hoverColor,
        child: Padding(
          padding: padding ?? DsDimensions.listItemPaddingCompact,
          child: Row(
            children: [
              if (leading != null) ...[
                leading!,
                context.ds.spaceWidth(DesignSystem.space12),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    DefaultTextStyle(
                      style: context.bodyMedium!,
                      child: title,
                    ),
                    if (subtitle != null) ...[
                      context.ds.spaceHeight(DesignSystem.space4),
                      DefaultTextStyle(
                        style: context.bodyMuted!,
                        child: subtitle!,
                      ),
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
        ),
      ),
    );
  }
}

/// Base Design System Switch widget
class DsSwitch extends StatelessWidget {
  const DsSwitch({
    required this.value,
    required this.onChanged,
    super.key,
    this.activeColor,
  });

  final bool value;
  final ValueChanged<bool> onChanged;
  final Color? activeColor;

  @override
  Widget build(BuildContext context) {
    return Switch(
      value: value,
      onChanged: onChanged,
      activeColor: activeColor ?? context.primary,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }
}

/// Base Design System Dropdown widget
class DsDropdown<T> extends StatelessWidget {
  const DsDropdown({
    required this.value,
    required this.items,
    required this.onChanged,
    super.key,
    this.isExpanded = true,
    this.decoration,
    this.padding,
  });

  final T value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?> onChanged;
  final bool isExpanded;
  final BoxDecoration? decoration;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration:
          decoration ??
          BoxDecoration(
            color: context.surface,
            borderRadius: context.ds.radiusMedium,
          ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          isExpanded: isExpanded,
          value: value,
          items: items,
          onChanged: onChanged,
          padding:
              padding ??
              const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          borderRadius: context.ds.radiusMedium,
          dropdownColor: context.surface,
        ),
      ),
    );
  }
}

/// Base Design System Button widget
class DsButton extends StatelessWidget {
  const DsButton({
    required this.onPressed,
    required this.child,
    super.key,
    this.icon,
    this.style,
    this.isOutlined = false,
    this.isFilled = false,
  });

  final VoidCallback? onPressed;
  final Widget child;
  final Widget? icon;
  final ButtonStyle? style;
  final bool isOutlined;
  final bool isFilled;

  @override
  Widget build(BuildContext context) {
    if (icon != null) {
      if (isFilled) {
        return FilledButton.icon(
          onPressed: onPressed,
          icon: icon,
          label: child,
          style: style ?? context.ds.filledButtonStyle,
        );
      } else if (isOutlined) {
        return OutlinedButton.icon(
          onPressed: onPressed,
          icon: icon,
          label: child,
          style: style ?? context.ds.outlinedButtonStyle,
        );
      } else {
        return TextButton.icon(
          onPressed: onPressed,
          icon: icon,
          label: child,
          style: style ?? context.ds.textButtonStyle,
        );
      }
    }

    if (isFilled) {
      return FilledButton(
        onPressed: onPressed,
        style: style ?? context.ds.filledButtonStyle,
        child: child,
      );
    } else if (isOutlined) {
      return OutlinedButton(
        onPressed: onPressed,
        style: style ?? context.ds.outlinedButtonStyle,
        child: child,
      );
    } else {
      return TextButton(
        onPressed: onPressed,
        style: style ?? context.ds.textButtonStyle,
        child: child,
      );
    }
  }
}

/// Section header widget using Design System
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

/// Divider with consistent styling
class DsDivider extends StatelessWidget {
  const DsDivider({super.key, this.height, this.indent, this.endIndent});

  final double? height;
  final double? indent;
  final double? endIndent;

  @override
  Widget build(BuildContext context) {
    return Divider(
      color: context.borderColor,
      height: height ?? 1,
      indent: indent,
      endIndent: endIndent,
    );
  }
}

/// Chip/Badge component for status, tags, and labels
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

/// Progress indicator with optional labels
class DsProgress extends StatelessWidget {
  const DsProgress({
    super.key,
    this.value,
    this.label,
    this.sublabel,
    this.isLinear = true,
    this.color,
    this.backgroundColor,
    this.height,
    this.showPercentage = false,
  });

  final double? value;
  final String? label;
  final String? sublabel;
  final bool isLinear;
  final Color? color;
  final Color? backgroundColor;
  final double? height;
  final bool showPercentage;

  @override
  Widget build(BuildContext context) {
    final progressColor = color ?? context.primary;
    final bgColor = backgroundColor ?? context.surfaceContainerHighest;

    Widget progress;
    if (isLinear) {
      progress = ClipRRect(
        borderRadius: BorderRadius.circular(height != null ? height! / 2 : 2),
        child: LinearProgressIndicator(
          value: value,
          backgroundColor: bgColor,
          valueColor: AlwaysStoppedAnimation<Color>(progressColor),
          minHeight: height ?? 4,
        ),
      );
    } else {
      progress = CircularProgressIndicator(
        value: value,
        backgroundColor: bgColor,
        valueColor: AlwaysStoppedAnimation<Color>(progressColor),
        strokeWidth: 3,
      );
    }

    if (label == null && sublabel == null && !showPercentage) {
      return progress;
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null) ...[
          Row(
            children: [
              Expanded(
                child: Text(label!, style: context.labelMedium),
              ),
              if (showPercentage && value != null)
                Text(
                  '${(value! * 100).toInt()}%',
                  style: context.labelSmall?.copyWith(
                    color: context.onSurfaceVariant,
                  ),
                ),
            ],
          ),
          context.ds.spaceHeight(DesignSystem.space8),
        ],
        progress,
        if (sublabel != null) ...[
          context.ds.spaceHeight(DesignSystem.space4),
          Text(
            sublabel!,
            style: context.labelSmall?.copyWith(
              color: context.onSurfaceVariant,
            ),
          ),
        ],
      ],
    );
  }
}

/// Consistent icon container with background
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

/// Info row for displaying label-value pairs
class DsInfoRow extends StatelessWidget {
  const DsInfoRow({
    required this.label,
    required this.value,
    super.key,
    this.labelStyle,
    this.valueStyle,
    this.spacing = DesignSystem.space8,
  });

  final String label;
  final String value;
  final TextStyle? labelStyle;
  final TextStyle? valueStyle;
  final double spacing;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          label,
          style: labelStyle ?? context.labelBold,
        ),
        SizedBox(width: spacing),
        Expanded(
          child: Text(
            value,
            style: valueStyle ?? context.bodyMuted,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

/// Empty state widget with icon and optional actions
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

/// Status card for displaying info with optional progress
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
    return DsCard(
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
                      Text(
                        subtitle!,
                        style: context.bodyMuted,
                      ),
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
            DsProgress(
              value: progress,
              label: progressLabel,
              showPercentage: progress != null,
            ),
          ],
        ],
      ),
    );
  }
}
