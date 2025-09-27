import 'package:flutter/material.dart';
import 'package:flutter_directory_tree/flutter_directory_tree.dart'
    as tree
    show NodeType, NodeVisualState, VisibleNode;

import '../../scan/models/scanned_file.dart';
import '../directory_tree_adapter.dart';
import 'collector_node_row.dart';

/// Renders the special Prompt file above the main tree when present.
class PromptRow extends StatelessWidget {
  const PromptRow({
    super.key,
    required this.adapter,
    required this.file,
    required this.activeFileId,
    required this.onFileActivated,
  });

  final DirectoryTreeAdapter adapter;
  final ScannedFile? file;
  final String? activeFileId;
  final ValueChanged<String> onFileActivated;

  @override
  Widget build(BuildContext context) {
    final promptNode = adapter.promptNode;
    final entryId = promptNode?.entryId;
    if (promptNode == null || entryId == null) {
      return const SizedBox.shrink();
    }

    final visible = tree.VisibleNode(
      id: promptNode.id,
      depth: 0,
      name: promptNode.name,
      type: tree.NodeType.file,
      hasChildren: false,
      virtualPath: promptNode.virtualPath,
      entryId: entryId,
      isVirtual: promptNode.isVirtual,
      sourcePath: promptNode.sourcePath,
    );

    final controller = adapter.controller;
    final visualState = tree.NodeVisualState(
      isExpanded: false,
      isSelected: controller.selection.isSelected(promptNode.id),
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
