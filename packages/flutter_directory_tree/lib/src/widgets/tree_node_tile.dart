// lib/src/widgets/tree_node_tile.dart
import 'package:directory_tree/directory_tree.dart' show VisibleNode;
import 'package:flutter/widgets.dart';
import 'package:flutter_directory_tree/src/delegates/node_renderer.dart';
import 'package:flutter_directory_tree/src/theme/directory_tree_theme.dart';

/// A lightly-styled, theme-aware row for a tree node.
///
/// Keeps the public API identical, but now paints selection/hover backgrounds
/// from [DirectoryTreeThemeData] so it looks good out of the box while
/// remaining easy to replace with a custom builder.
class TreeNodeTile extends StatefulWidget {
  const TreeNodeTile({
    super.key,
    required this.node,
    required this.state,
    this.leading,
    this.trailing,
    this.title,
    this.subtitle,
    this.onTap,
    this.onDoubleTap,
    this.onTertiaryTap,
  });

  final VisibleNode node;
  final NodeVisualState state;

  final Widget? leading;
  final Widget? trailing;
  final Widget? title;
  final Widget? subtitle;

  final VoidCallback? onTap;
  final VoidCallback? onDoubleTap;
  final VoidCallback? onTertiaryTap;

  @override
  State<TreeNodeTile> createState() => _TreeNodeTileState();
}

class _TreeNodeTileState extends State<TreeNodeTile> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    final theme = DirectoryTreeTheme.of(context);
    final indentWidth =
        widget.state.contentIndent ?? widget.node.depth * theme.indent;

    Color? background;
    if (widget.state.isSelected && theme.selectionColor != null) {
      background = theme.selectionColor;
    } else if (widget.state.isFocused && theme.focusColor != null) {
      background = theme.focusColor;
    } else if (_hovering && theme.hoverColor != null) {
      background = theme.hoverColor;
    }

    final row = Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(width: indentWidth),
        if (widget.leading != null) widget.leading!,
        Expanded(
          child: widget.title ??
              Text(
                widget.node.name,
                overflow: TextOverflow.ellipsis,
              ),
        ),
        if (widget.subtitle != null) widget.subtitle!,
        if (widget.trailing != null) widget.trailing!,
      ],
    );

    final decorated = DecoratedBox(
      decoration: BoxDecoration(
        color: background,
        borderRadius: theme.roundedCorners ? BorderRadius.circular(4) : null,
      ),
      child: row,
    );

    final handleTap = widget.onTap;
    final hasDoubleTap = widget.onDoubleTap != null;

    final gesture = GestureDetector(
      behavior: HitTestBehavior.opaque,
      // When a double-tap handler is wired, eagerly run the primary tap logic
      // on pointer down so selection updates without waiting for the double-tap
      // gesture timeout.
      onTapDown: hasDoubleTap && handleTap != null ? (_) => handleTap() : null,
      onTap: hasDoubleTap ? null : handleTap,
      onDoubleTap: widget.onDoubleTap,
      onTertiaryTapUp:
          widget.onTertiaryTap == null ? null : (_) => widget.onTertiaryTap!(),
      child: decorated,
    );

    final hoverable = MouseRegion(
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: gesture,
    );

    final hasChildren = widget.node.hasChildren;

    return Semantics(
      container: true,
      focusable: true,
      label: widget.node.name,
      selected: widget.state.isSelected,
      expanded: hasChildren ? widget.state.isExpanded : null,
      enabled: widget.onTap != null || widget.onDoubleTap != null,
      button: widget.onTap != null,
      onTap: widget.onTap,
      child: hoverable,
    );
  }
}
