// lib/src/ops/selection_utils.dart
import 'package:directory_tree/src/models/tree_data.dart';
import 'package:directory_tree/src/models/tree_node.dart';

/// Aggregated folder selection state considering all descendant files.
enum FolderSelection { none, partial, all }

FolderSelection folderSelection({
  required TreeData data,
  required Set<String> selectedIds,
  required String folderId,
}) {
  final root = data.nodes[folderId];
  if (root == null) return FolderSelection.none;
  var totalFiles = 0;
  var selectedFiles = 0;
  final stack = <String>[folderId];

  while (stack.isNotEmpty) {
    final id = stack.removeLast();
    final node = data.nodes[id];
    if (node == null) continue;
    if (node.type == NodeType.file) {
      totalFiles++;
      if (selectedIds.contains(id)) {
        selectedFiles++;
      }
      continue;
    }
    stack.addAll(node.childIds);
  }

  if (totalFiles == 0 || selectedFiles == 0) return FolderSelection.none;
  if (selectedFiles == totalFiles) return FolderSelection.all;
  return FolderSelection.partial;
}
