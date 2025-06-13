import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as path;

import '../../scan/models/scan_result.dart';
import '../../scan/models/scanned_file.dart';
import '../api/virtual_tree_api.dart';
import '../services/tree_builder.dart';

/// State for the virtual tree
class TreeState {
  const TreeState({
    required this.nodes,
    required this.rootId,
    this.selectedNodeIds = const {},
    this.expansionState = const {},
  });

  final Map<String, TreeNode> nodes;
  final String rootId;
  final Set<String> selectedNodeIds;
  final Map<String, bool> expansionState;

  /// Get all selected tree nodes
  List<TreeNode> get selectedNodes =>
      selectedNodeIds.map((id) => nodes[id]).whereType<TreeNode>().toList();

  /// Get file IDs of selected file nodes
  Set<String> get selectedFileIds => selectedNodes
      .where((node) => node.type == NodeType.file && node.fileId != null)
      .map((node) => node.fileId!)
      .toSet();

  /// Check if tree has any nodes
  bool get hasNodes =>
      nodes.isNotEmpty && nodes.length > 1; // More than just root

  /// Create a copy with updated values
  TreeState copyWith({
    Map<String, TreeNode>? nodes,
    String? rootId,
    Set<String>? selectedNodeIds,
    Map<String, bool>? expansionState,
  }) {
    return TreeState(
      nodes: nodes ?? this.nodes,
      rootId: rootId ?? this.rootId,
      selectedNodeIds: selectedNodeIds ?? this.selectedNodeIds,
      expansionState: expansionState ?? this.expansionState,
    );
  }
}

/// State notifier for virtual tree
class TreeStateNotifier extends StateNotifier<TreeState> {
  TreeStateNotifier() : super(const TreeState(nodes: {}, rootId: ''));

  final TreeBuilder _treeBuilder = TreeBuilder();

  // Scanner integration callbacks
  void Function(String, String, String)? onNodeCreatedCallback;
  void Function(String, String)? onNodeEditedCallback;
  void Function(Set<String>)? onSelectionChangedCallback;

  /// Build tree from files and metadata (performs a full rebuild)
  void buildFromFiles(List<ScannedFile> files, List<ScanMetadata> metadata) {
    // 1. Preserve the old UI state before rebuilding
    final oldExpansionState = state.expansionState;
    final oldSelectedFileIds = state.selectedFileIds;

    // 2. Build a brand new tree from the single source of truth.
    //    The tree builder now handles virtual file preservation internally.
    final treeData = _treeBuilder.buildTree(
      files: files,
      scanMetadata: metadata,
    );

    // 3. Re-apply the preserved UI state to the new tree
    final newNodes = treeData.nodes;
    final newExpansionState = <String, bool>{};
    final newSelectedNodeIds = <String>{};

    for (final node in newNodes.values) {
      // Re-apply expansion state by node ID
      newExpansionState[node.id] =
          oldExpansionState[node.id] ?? node.isExpanded;

      // Re-apply selection state by matching the stable ScannedFile.id
      if (node.fileId != null && oldSelectedFileIds.contains(node.fileId)) {
        newSelectedNodeIds.add(node.id);
      }
    }

    // Also include any files that were auto-selected during the build (i.e., new files)
    for (final node in newNodes.values) {
      if (node.isSelected && node.type == NodeType.file) {
        newSelectedNodeIds.add(node.id);
      }
    }

    // 4. Set the new, corrected state
    state = TreeState(
      nodes: newNodes,
      rootId: treeData.rootId,
      expansionState: newExpansionState,
      selectedNodeIds: newSelectedNodeIds,
    );

    // 5. Notify the scanner that the selection may have changed
    onSelectionChangedCallback?.call(state.selectedFileIds);
  }

  /// Toggle node (expand/collapse for folders, select/deselect for files)
  void toggleNode(String nodeId) {
    final node = state.nodes[nodeId];
    if (node == null) return;

    if (node.type == NodeType.file) {
      _toggleFileSelection(nodeId);
    } else {
      toggleFolderExpansion(nodeId);
    }
  }

  /// Toggle file selection
  void _toggleFileSelection(String nodeId) {
    final newSelection = Set<String>.from(state.selectedNodeIds);

    if (newSelection.contains(nodeId)) {
      newSelection.remove(nodeId);
    } else {
      newSelection.add(nodeId);
    }

    state = state.copyWith(selectedNodeIds: newSelection);

    // Notify scanner of selection change - CRITICAL for content update
    final fileIds = state.selectedFileIds;
    onSelectionChangedCallback?.call(fileIds);
  }

  /// Toggle folder expansion
  void toggleFolderExpansion(String nodeId) {
    final newExpansionState = Map<String, bool>.from(state.expansionState);
    newExpansionState[nodeId] = !(newExpansionState[nodeId] ?? true);

    state = state.copyWith(expansionState: newExpansionState);
  }

  /// Check if a node is expanded
  bool isExpanded(String nodeId) {
    return state.expansionState[nodeId] ??
        state.nodes[nodeId]?.isExpanded ??
        false;
  }

  /// Select all files in a folder
  void selectFolder(String folderId) {
    final folder = state.nodes[folderId];
    if (folder == null || folder.type == NodeType.file) return;

    final newSelection = Set<String>.from(state.selectedNodeIds);

    // Recursively collect all file nodes
    final fileNodes = <String>[];
    _collectFileNodes(folderId, fileNodes);

    // Add all file nodes to selection
    newSelection.addAll(fileNodes);

    state = state.copyWith(selectedNodeIds: newSelection);

    // Notify scanner - CRITICAL for content update
    final fileIds = state.selectedFileIds;
    onSelectionChangedCallback?.call(fileIds);
  }

  /// Deselect all files in a folder
  void deselectFolder(String folderId) {
    final folder = state.nodes[folderId];
    if (folder == null || folder.type == NodeType.file) return;

    final newSelection = Set<String>.from(state.selectedNodeIds);

    // Recursively collect all file nodes
    final fileNodes = <String>[];
    _collectFileNodes(folderId, fileNodes);

    // Remove all file nodes from selection
    newSelection.removeAll(fileNodes);

    state = state.copyWith(selectedNodeIds: newSelection);

    // Notify scanner - CRITICAL for content update
    final fileIds = state.selectedFileIds;
    onSelectionChangedCallback?.call(fileIds);
  }

  /// Recursively collect all file node IDs under a folder
  void _collectFileNodes(String folderId, List<String> fileNodes) {
    final folder = state.nodes[folderId];
    if (folder == null) return;

    for (final childId in folder.childIds) {
      final child = state.nodes[childId];
      if (child == null) continue;

      if (child.type == NodeType.file) {
        fileNodes.add(childId);
      } else {
        _collectFileNodes(childId, fileNodes);
      }
    }
  }

  /// Create a new node (file or folder)
  void createNode({
    required String parentId,
    required String name,
    required bool isFolder,
    String? content,
  }) {
    final parent = state.nodes[parentId];
    if (parent == null) return;

    // For folders, we can still create them directly as they have no file data
    if (isFolder) {
      final virtualPath = path.join(parent.virtualPath, name);
      final newNode = TreeNode(
        name: name,
        type: NodeType.folder,
        parentId: parentId,
        virtualPath: virtualPath,
        isVirtual: true,
        source: FileSource.created,
        isExpanded: true,
      );
      final newNodes = Map<String, TreeNode>.from(state.nodes);
      newNodes[newNode.id] = newNode;
      final updatedParent = parent.copyWith(
        childIds: [...parent.childIds, newNode.id],
      );
      newNodes[parentId] = updatedParent;
      state = state.copyWith(nodes: newNodes);
    } else {
      // For files, simply trigger the callback.
      // DO NOT create a TreeNode here. Let the FileListNotifier handle it.
      onNodeCreatedCallback?.call(parent.virtualPath, name, content ?? '');
    }
  }

  /// Edit node content (for files)
  void editNodeContent(String nodeId, String content) {
    final node = state.nodes[nodeId];
    if (node?.fileId == null || node!.type != NodeType.file) return;

    // Notify scanner of content change
    onNodeEditedCallback?.call(node.fileId!, content);
  }

  /// Update selection from scanner
  void updateSelectionFromFileIds(Set<String> fileIds) {
    final newSelection = <String>{};

    // Find tree nodes for the given file IDs
    for (final entry in state.nodes.entries) {
      final node = entry.value;
      if (node.type == NodeType.file &&
          node.fileId != null &&
          fileIds.contains(node.fileId)) {
        newSelection.add(node.id);
      }
    }

    state = state.copyWith(selectedNodeIds: newSelection);
  }

  /// Get current tree data
  TreeData getCurrentTreeData() {
    return TreeData(
      nodes: state.nodes,
      rootId: state.rootId,
    );
  }

  /// Check if tree has nodes
  bool hasTreeNodes() => state.nodes.isNotEmpty;

  /// Get selected file IDs from current state
  Set<String> getSelectedFileIds() => state.selectedFileIds;

  /// Clear all nodes (used when scanner clears files)
  void clearTree() {
    state = const TreeState(
      nodes: {},
      rootId: TreeBuilder.rootId,
      selectedNodeIds: {},
      expansionState: {},
    );

    // Notify scanner of cleared selection
    onSelectionChangedCallback?.call({});
  }

  /// Directly adds a virtual file node to the tree.
  void addVirtualFileNode({
    required String parentNodeId,
    required ScannedFile file,
  }) {
    final parent = state.nodes[parentNodeId];
    if (parent == null || parent.type == NodeType.file) return;

    final virtualPath = path.join(parent.virtualPath, file.name);
    final nodeId = 'node_${file.id}';

    // Create the new tree node, correctly linked to the ScannedFile ID
    final newNode = TreeNode(
      id: nodeId,
      name: file.name,
      type: NodeType.file,
      parentId: parentNodeId,
      virtualPath: virtualPath,
      fileId: file.id,
      isVirtual: true,
      source: FileSource.created,
      isSelected: true, // Auto-select the new file
    );

    // Add the new node to the tree
    final newNodes = Map<String, TreeNode>.from(state.nodes);
    newNodes[newNode.id] = newNode;

    // Add the new node to its parent's children list
    final updatedParent = parent.copyWith(
      childIds: [...parent.childIds, newNode.id],
    );
    newNodes[parentNodeId] = updatedParent;

    // Update the selection state
    final newSelection = Set<String>.from(state.selectedNodeIds)
      ..add(newNode.id);

    state = state.copyWith(
      nodes: newNodes,
      selectedNodeIds: newSelection,
    );

    // Notify the FileListNotifier that the selection has changed
    onSelectionChangedCallback?.call(state.selectedFileIds);
  }
}

/// Provider for tree state
final treeStateProvider = StateNotifierProvider<TreeStateNotifier, TreeState>((
  ref,
) {
  return TreeStateNotifier();
});
