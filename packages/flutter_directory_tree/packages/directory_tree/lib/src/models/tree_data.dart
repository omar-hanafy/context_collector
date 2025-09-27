import 'package:directory_tree/src/models/tree_node.dart';

class TreeData {
  const TreeData({
    required this.nodes,
    required this.rootId,
    required this.visibleRootId,
    this.omitContainerRowAtRoot = false,
  });

  final Map<String, TreeNode> nodes;
  final String rootId;

  /// Suggested starting point for UI rendering without mutating the tree.
  final String visibleRootId;
  /// If true, flatteners should render the visible root's children at depth 0
  /// so top parents appear as direct roots (TRD §6.1).
  final bool omitContainerRowAtRoot;
}
