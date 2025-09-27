// lib/src/ops/visible_node.dart
import 'package:directory_tree/src/models/tree_node.dart';

/// Immutable row descriptor for painting the list.
class VisibleNode {
  const VisibleNode({
    required this.id,
    required this.depth,
    required this.name,
    required this.type,
    required this.hasChildren,
    required this.virtualPath,
    this.entryId,
    this.isVirtual = false,
    this.sourcePath,
    this.origin = SelectionOrigin.none,
  });

  final String id; // TreeNode.id
  final int depth; // indentation level starting at 0 for visible root
  final String name;
  final NodeType type; // folder/file/root
  final bool hasChildren;
  final String virtualPath;
  final String? entryId;
  final bool isVirtual;
  final String? sourcePath;
  final SelectionOrigin origin;
}
