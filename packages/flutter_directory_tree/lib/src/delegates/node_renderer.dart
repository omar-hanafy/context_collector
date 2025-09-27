// lib/src/delegates/node_renderer.dart
import 'package:directory_tree/directory_tree.dart' show VisibleNode;
import 'package:flutter/widgets.dart';

/// Visual bits needed by a row builder.
class NodeVisualState {
  const NodeVisualState({
    required this.isExpanded,
    required this.isSelected,
    required this.isFocused,
    required this.isHovered,
    required this.depth,
    this.contentIndent,
  });

  final bool isExpanded;
  final bool isSelected;
  final bool isFocused;
  final bool isHovered;
  final int depth;
  final double? contentIndent;
}

/// Builds a row for a given visible node.
typedef NodeBuilder = Widget Function(
  BuildContext context,
  VisibleNode node,
  NodeVisualState state,
);

/// Builder for the "expander" affordance (chevron/caret).
typedef ExpanderBuilder = Widget Function(
  BuildContext context,
  VisibleNode node,
  bool isExpanded,
  VoidCallback onPressed,
);
