import 'dart:convert';

import '../../scan/models/scan_result.dart';
import '../../scan/models/scanned_file.dart';
import '../models/tree_node.dart';

export '../models/tree_node.dart';

/// Virtual Tree API contract for scanner integration
abstract class VirtualTreeAPI {
  /// Build tree from files and metadata
  Future<TreeData> buildTree({
    required List<ScannedFile> files,
    required List<ScanMetadata> scanMetadata,
  });

  /// Get current tree structure
  TreeData? getCurrentTree();

  /// Selection management
  Set<String> getSelectedFileIds();

  void setSelectedFileIds(Set<String> ids);

  /// Content building (handled by scanner in our case)
  Future<String> buildCombinedContent(Set<String> selectedIds);

  /// Tree operations callbacks
  void onNodeCreated(
    void Function(String parentPath, String name, String content) callback,
  );

  void onNodeEdited(void Function(String fileId, String content) callback);

  void onSelectionChanged(void Function(Set<String> selectedIds) callback);

  /// Clear the tree
  void clearTree();

  /// Directly add a new virtual file node to the tree under a specific parent.
  void addVirtualFileNode({
    required String parentNodeId,
    required ScannedFile file,
  });

  /// Get the virtual path of a node by its ID
  String? getNodeVirtualPath(String nodeId);

  /// Create a virtual folder in the tree
  void createVirtualFolder({
    required String parentNodeId,
    required String folderName,
  });
}

/// Tree data structure
class TreeData {
  const TreeData({
    required this.nodes,
    required this.rootId,
  });
  factory TreeData.fromJson(String json) =>
      TreeData.fromMap(jsonDecode(json) as Map<String, dynamic>);

  factory TreeData.fromMap(Map<String, dynamic> map) => TreeData(
    nodes: (map['nodes'] as Map<String, dynamic>).map(
      (k, v) => MapEntry(k, TreeNode.fromMap(v as Map<String, dynamic>)),
    ),
    rootId: map['rootId'] as String,
  );
  final Map<String, TreeNode> nodes;
  final String rootId;

  Map<String, dynamic> toMap() => {
    'nodes': nodes.map((k, v) => MapEntry(k, v.toMap())),
    'rootId': rootId,
  };

  String toJson() => jsonEncode(toMap());
}
