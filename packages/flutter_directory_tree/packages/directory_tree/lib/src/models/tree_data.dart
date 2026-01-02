import 'package:directory_tree/src/models/tree_node.dart';

/// An immutable snapshot of the entire directory tree structure.
///
/// [TreeData] holds the complete graph of [TreeNode]s and metadata about the
/// tree's root. It is the output of [TreeBuilder.build].
///
/// ### Usage
/// *   Pass this object to a [FlattenStrategy] to generate a linear list for
///     UI rendering.
/// *   Use [nodes] to look up specific node details by ID.
///
/// This class is designed to be inexpensive to copy, facilitating efficient
/// state management updates (e.g., when toggling expansion).
class TreeData {
  /// Creates a new [TreeData] instance.
  const TreeData({
    required this.nodes,
    required this.rootId,
    required this.visibleRootId,
    this.omitContainerRowAtRoot = false,
  });

  /// The map of all nodes in the tree, indexed by ID.
  final Map<String, TreeNode> nodes;

  /// The ID of the absolute root of the tree (usually hidden).
  final String rootId;

  /// The ID of the node to start rendering from.
  final String visibleRootId;

  /// If true, the [visibleRootId] node itself is skipped, and its children
  /// are rendered at the top level.
  final bool omitContainerRowAtRoot;
}
