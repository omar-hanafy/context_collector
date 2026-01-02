import 'package:flutter/material.dart';
import 'package:flutter_directory_tree/flutter_directory_tree.dart'
    as tree
    show NodeType, NodeVisualState, TreeNode, VisibleNode;

import '../../scan/models/scanned_file.dart';
import '../directory_tree_adapter.dart';
import 'collector_node_row.dart';

/// Renders a special file (Header/Footer) above or below the main tree.
class SpecialFileRow extends StatelessWidget {
  const SpecialFileRow({
    super.key,
    required this.adapter,
    required this.node,
    required this.file,
    required this.activeFileId,
    required this.onFileActivated,
  });

  final DirectoryTreeAdapter adapter;
  final tree.TreeNode? node;
  final ScannedFile? file;
  final String? activeFileId;
  final ValueChanged<String> onFileActivated;

  @override
  Widget build(BuildContext context) {
    final entryId = node?.entryId;
    if (node == null || entryId == null) {
      return const SizedBox.shrink();
    }

    final visible = tree.VisibleNode(
      id: node!.id,
      depth: 0,
      name: node!.name,
      type: tree.NodeType.file,
      hasChildren: false,
      virtualPath: node!.virtualPath,
      entryId: entryId,
      isVirtual: node!.isVirtual,
      sourcePath: node!.sourcePath,
    );

    final controller = adapter.controller;
    final visualState = tree.NodeVisualState(
      isExpanded: false,
      isSelected: controller.selection.isSelected(node!.id),
      isFocused: false,
      isHovered: false,
      depth: 0,
    );

    return CollectorNodeRow(
      controller: controller,
      node: visible,
      visualState: visualState,
      file: file,
      isActive: entryId == activeFileId,
      onFileActivated: onFileActivated,
    );
  }
}
