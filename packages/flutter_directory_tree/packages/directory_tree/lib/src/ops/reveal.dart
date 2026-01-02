// lib/src/ops/reveal.dart
import 'package:directory_tree/src/models/tree_data.dart';
import 'package:directory_tree/src/models/tree_node.dart';

/// Computes the path from the root to the target [nodeId].
///
/// Returns a list of node IDs starting with the root and ending with [nodeId].
///
/// ### Usage
/// Use this to auto-expand all parents of a specific node so that it becomes
/// visible in the UI.
List<String> ancestorChain(TreeData data, String nodeId) {
  final chain = <String>[];
  TreeNode? current = data.nodes[nodeId];
  while (current != null && current.parentId.isNotEmpty) {
    chain.insert(0, current.id);
    current = data.nodes[current.parentId];
  }
  if (current != null) {
    chain.insert(0, current.id);
  }
  return chain;
}

/// Locates a node ID by its virtual path in the tree.
///
/// Returns `null` if no node matches the exact [virtualPath].
String? findByVirtualPath(TreeData data, String virtualPath) {
  if (virtualPath.isEmpty) return null;
  for (final entry in data.nodes.entries) {
    if (entry.value.virtualPath == virtualPath) {
      return entry.key;
    }
  }
  return null;
}
