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
  void Function(String)? onNodeRemovedCallback;
  void Function(Set<String>)? onSelectionChangedCallback;

  /// Build tree from files and metadata (merges with existing tree)
  void buildFromFiles(List<ScannedFile> files, List<ScanMetadata> metadata) {
    // Get existing file IDs to avoid duplicates
    final existingFileIds = <String>{};
    for (final node in state.nodes.values) {
      if (node.fileId != null) {
        existingFileIds.add(node.fileId!);
      }
    }

    // Build tree with existing nodes
    final treeData = _treeBuilder.buildTree(
      files: files,
      scanMetadata: metadata,
      existingNodes: state.nodes.isNotEmpty ? state.nodes : null,
      existingFileIds: existingFileIds,
    );

    // Preserve expansion state for existing nodes
    final newExpansionState = <String, bool>{};
    for (final entry in treeData.nodes.entries) {
      final nodeId = entry.key;
      final node = entry.value;

      // Keep previous expansion state or use node default
      newExpansionState[nodeId] =
          state.expansionState[nodeId] ?? node.isExpanded;
    }

    // Collect all new file nodes that were added (they're auto-selected)
    final newSelectedIds = Set<String>.from(state.selectedNodeIds);
    for (final node in treeData.nodes.values) {
      if (node.type == NodeType.file &&
          node.isSelected &&
          !state.nodes.containsKey(node.id)) {
        newSelectedIds.add(node.id);
      }
    }

    state = TreeState(
      nodes: treeData.nodes,
      rootId: treeData.rootId,
      expansionState: newExpansionState,
      selectedNodeIds: newSelectedIds,
    );

    // Notify scanner of the new selection
    final fileIds = state.selectedFileIds;
    onSelectionChangedCallback?.call(fileIds);
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

    // Check for name conflicts and auto-increment if necessary
    var finalName = name;
    if (!isFolder) {
      final existingNames = <String>{};
      for (final childId in parent.childIds) {
        final child = state.nodes[childId];
        if (child != null && child.type == NodeType.file) {
          existingNames.add(child.name);
        }
      }
      
      // If name already exists, find the next available number
      if (existingNames.contains(finalName)) {
        final extension = path.extension(finalName);
        final baseName = path.basenameWithoutExtension(finalName);
        
        // Extract existing number if present (e.g., "file (2)" -> 2)
        final numberMatch = RegExp(r' \((\d+)\)$').firstMatch(baseName);
        var counter = 2;
        
        if (numberMatch != null) {
          // Start from the next number after the existing one
          counter = int.parse(numberMatch.group(1)!) + 1;
        }
        
        // Find the next available name
        do {
          finalName = '$baseName ($counter)$extension';
          counter++;
        } while (existingNames.contains(finalName));
      }
    }

    final virtualPath = path.join(parent.virtualPath, finalName);

    if (!isFolder && content != null) {
      // Notify scanner to create virtual file with the final name
      onNodeCreatedCallback?.call(parent.virtualPath, finalName, content);
    }

    // Create tree node with the final name
    final newNode = TreeNode(
      name: finalName,
      type: isFolder ? NodeType.folder : NodeType.file,
      parentId: parentId,
      virtualPath: virtualPath,
      isVirtual: true,
      source: FileSource.created,
    );

    final newNodes = Map<String, TreeNode>.from(state.nodes);
    newNodes[newNode.id] = newNode;

    // Update parent's children
    final updatedParent = parent.copyWith(
      childIds: [...parent.childIds, newNode.id],
    );
    newNodes[parentId] = updatedParent;

    // Expand parent folder
    final newExpansionState = Map<String, bool>.from(state.expansionState);
    newExpansionState[parentId] = true;

    state = state.copyWith(
      nodes: newNodes,
      expansionState: newExpansionState,
    );
  }

  /// Edit node content (for files)
  void editNodeContent(String nodeId, String content) {
    final node = state.nodes[nodeId];
    if (node?.fileId == null || node!.type != NodeType.file) return;

    // Notify scanner of content change
    onNodeEditedCallback?.call(node.fileId!, content);
  }

  /// Remove a node and all its children
  void removeNode(String nodeId) {
    final node = state.nodes[nodeId];
    if (node == null || node.type == NodeType.root) return;

    // Collect all file IDs that will be removed
    final removedFileIds = <String>{};
    _collectFileIds(nodeId, removedFileIds);

    // Remove from tree
    final newNodes = Map<String, TreeNode>.from(state.nodes);
    final newSelection = Set<String>.from(state.selectedNodeIds);
    final newExpansionState = Map<String, bool>.from(state.expansionState);

    _removeNodeRecursive(nodeId, newNodes, newSelection, newExpansionState);

    state = state.copyWith(
      nodes: newNodes,
      selectedNodeIds: newSelection,
      expansionState: newExpansionState,
    );

    // Notify scanner of all removed files
    for (final fileId in removedFileIds) {
      onNodeRemovedCallback?.call(fileId);
    }

    // Update selection in scanner
    final fileIds = state.selectedFileIds;
    onSelectionChangedCallback?.call(fileIds);
  }

  /// Collect all file IDs under a node
  void _collectFileIds(String nodeId, Set<String> fileIds) {
    final node = state.nodes[nodeId];
    if (node == null) return;

    if (node.type == NodeType.file && node.fileId != null) {
      fileIds.add(node.fileId!);
    }

    for (final childId in node.childIds) {
      _collectFileIds(childId, fileIds);
    }
  }

  /// Recursively remove a node and all its children
  void _removeNodeRecursive(
    String nodeId,
    Map<String, TreeNode> nodes,
    Set<String> selection,
    Map<String, bool> expansionState,
  ) {
    final node = nodes[nodeId];
    if (node == null) return;

    // Remove children first
    for (final childId in List<String>.from(node.childIds)) {
      _removeNodeRecursive(childId, nodes, selection, expansionState);
    }

    // Remove from parent's children
    if (node.parentId.isNotEmpty) {
      final parent = nodes[node.parentId];
      if (parent != null) {
        final updatedParent = parent.copyWith(
          childIds: parent.childIds.where((id) => id != nodeId).toList(),
        );
        nodes[node.parentId] = updatedParent;
      }
    }

    // Remove the node itself
    nodes.remove(nodeId);
    selection.remove(nodeId);
    expansionState.remove(nodeId);
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
    state = TreeState(
      nodes: const {},
      rootId: TreeBuilder.rootId,
      selectedNodeIds: const {},
      expansionState: const {},
    );
    
    // Notify scanner of cleared selection
    onSelectionChangedCallback?.call({});
  }
}

/// Provider for tree state
final treeStateProvider = StateNotifierProvider<TreeStateNotifier, TreeState>((
  ref,
) {
  return TreeStateNotifier();
});
