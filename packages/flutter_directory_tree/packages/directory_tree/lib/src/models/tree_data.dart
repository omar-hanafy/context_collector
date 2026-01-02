import 'package:directory_tree/src/models/tree_node.dart';

/// Holds the complete state of the directory tree at a specific point in time.
///
/// [TreeData] is the "source of truth" for your UI. It contains the graph of
/// [TreeNode]s and the entry points for traversal.
///
/// ### Behavior
/// *   **Traversal:** Use [nodes] combined with [rootId] or [visibleRootId] to
///     walk the tree.
/// *   **Updates:** This class is immutable. To change the tree (e.g., expand a folder),
///     you typically create a new [TreeData] (or a sidecar state object) rather than mutating this one.
/// *   **Rendering:** Pass this to [FlattenStrategy.flatten] to produce a renderable list.
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
