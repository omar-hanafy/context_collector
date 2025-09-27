// lib/src/ops/reveal.dart
import 'package:directory_tree/src/models/tree_data.dart';
import 'package:directory_tree/src/models/tree_node.dart';

/// Returns a chain of ancestor ids from root->...->node (inclusive).
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

/// Finds the first node whose virtualPath equals [virtualPath].
String? findByVirtualPath(TreeData data, String virtualPath) {
  if (virtualPath.isEmpty) return null;
  for (final entry in data.nodes.entries) {
    if (entry.value.virtualPath == virtualPath) {
      return entry.key;
    }
  }
  return null;
}
