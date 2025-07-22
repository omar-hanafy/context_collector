import 'package:path/path.dart' as path;

import '../../scan/models/scan_result.dart';
import '../../scan/models/scanned_file.dart';
import '../api/virtual_tree_api.dart';

/// Builds a virtual tree deterministically from a list of files and metadata.
/// This new implementation creates a simplified structure with a fixed 'tree' root.
class TreeBuilder {
  static const String rootId = 'root';
  static const String treeRootId = 'tree_root';

  TreeData buildTree({
    required List<ScannedFile> files,
    required List<ScanMetadata> scanMetadata,
  }) {
    // The top-level, non-visible root node
    final nodes = <String, TreeNode>{
      rootId: TreeNode(
        id: rootId,
        name: 'Root',
        type: NodeType.root,
        parentId: '',
        virtualPath: '/',
      ),
    };

    // The main 'tree/' folder that contains everything
    final treeRootNode = TreeNode(
      id: treeRootId,
      name: 'tree',
      type: NodeType.folder,
      parentId: rootId,
      virtualPath: '/tree',
      isExpanded: true,
    );
    nodes[treeRootId] = treeRootNode;
    nodes[rootId]!.childIds.add(treeRootId);

    if (files.isEmpty) {
      return TreeData(nodes: nodes, rootId: rootId);
    }

    // Process real files first
    final realFiles = files.where((f) => !f.isVirtual).toList();
    if (realFiles.isNotEmpty) {
      _buildFromRealFiles(nodes, realFiles, scanMetadata);
    }

    // Process virtual files, placing them at the top level
    final virtualFiles = files.where((f) => f.isVirtual).toList();
    for (final file in virtualFiles) {
      _addFileToParent(
        nodes: nodes,
        file: file,
        parentId: treeRootId,
      );
    }

    return TreeData(nodes: nodes, rootId: rootId);
  }

  /// Constructs tree nodes from real filesystem files.
  void _buildFromRealFiles(
    Map<String, TreeNode> nodes,
    List<ScannedFile> realFiles,
    List<ScanMetadata> scanMetadata,
  ) {
    final allSourcePaths = scanMetadata
        .expand((meta) => meta.sourcePaths)
        .toSet();
    final filesBySource = _groupFilesByMostSpecificSource(
      realFiles,
      allSourcePaths,
    );
    final sortedSourcePaths = filesBySource.keys.toList()
      ..sort((a, b) => a.compareTo(b));

    for (final sourcePath in sortedSourcePaths) {
      final filesInGroup = filesBySource[sourcePath]!;
      final parentNode = nodes[treeRootId]!;
      final sourceFolderName = path.basename(sourcePath);

      // Create a node for the source folder (e.g., 'src') as a direct child of 'tree'
      final sourceFolderNode = _findOrCreateFolder(
        nodes: nodes,
        name: sourceFolderName,
        parentId: parentNode.id,
        parentVirtualPath: parentNode.virtualPath,
        sourcePath: sourcePath,
      );

      // Add all files from this source group under the created source folder node
      for (final file in filesInGroup) {
        final relativePath = path.relative(file.fullPath, from: sourcePath);
        _addFileAndHierarchy(
          nodes: nodes,
          file: file,
          baseNodeId: sourceFolderNode.id,
          relativePath: relativePath,
        );
      }
    }
  }

  /// Adds a single file to a parent, creating folder hierarchy as needed.
  void _addFileAndHierarchy({
    required Map<String, TreeNode> nodes,
    required ScannedFile file,
    required String baseNodeId,
    required String relativePath,
  }) {
    final parts = path.split(relativePath).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return; // Happens if relativePath is '.'

    String currentParentId = baseNodeId;
    for (int i = 0; i < parts.length - 1; i++) {
      final folderName = parts[i];
      final parentNode = nodes[currentParentId]!;
      currentParentId = _findOrCreateFolder(
        nodes: nodes,
        name: folderName,
        parentId: currentParentId,
        parentVirtualPath: parentNode.virtualPath,
        isVirtual: file.isVirtual,
      ).id;
    }

    _addFileToParent(
      nodes: nodes,
      file: file,
      parentId: currentParentId,
      fileNameOverride: parts.last,
    );
  }

  /// Helper to add a ScannedFile as a direct child of a parent node.
  void _addFileToParent({
    required Map<String, TreeNode> nodes,
    required ScannedFile file,
    required String parentId,
    String? fileNameOverride,
  }) {
    final parentNode = nodes[parentId]!;
    final fileName = fileNameOverride ?? file.name;
    final fileNodeId = 'node_${file.id}';

    if (!nodes.containsKey(fileNodeId)) {
      nodes[fileNodeId] = TreeNode(
        id: fileNodeId,
        name: fileName,
        type: NodeType.file,
        parentId: parentId,
        virtualPath: path.join(parentNode.virtualPath, fileName),
        sourcePath: file.fullPath,
        fileId: file.id,
        isVirtual: file.isVirtual,
        source: file.isVirtual ? FileSource.created : FileSource.disk,
        isSelected: true,
      );
      parentNode.childIds.add(fileNodeId);
    }
  }

  Map<String, List<ScannedFile>> _groupFilesByMostSpecificSource(
    List<ScannedFile> files,
    Set<String> allSourcePaths,
  ) {
    final groups = <String, List<ScannedFile>>{};
    for (final file in files) {
      String? bestSourcePath;
      for (final sourcePath in allSourcePaths) {
        if (path.isWithin(sourcePath, file.fullPath) ||
            sourcePath == file.fullPath) {
          if (bestSourcePath == null ||
              sourcePath.length > bestSourcePath.length) {
            bestSourcePath = sourcePath;
          }
        }
      }
      final groupKey = bestSourcePath ?? path.dirname(file.fullPath);
      groups.putIfAbsent(groupKey, () => []).add(file);
    }
    return groups;
  }

  TreeNode _findOrCreateFolder({
    required Map<String, TreeNode> nodes,
    required String name,
    required String parentId,
    required String parentVirtualPath,
    String? sourcePath,
    bool isVirtual = false,
  }) {
    final parent = nodes[parentId]!;
    for (final childId in parent.childIds) {
      final child = nodes[childId];
      if (child != null &&
          child.name == name &&
          child.type == NodeType.folder) {
        // If this folder didn't have a source yet and we now know one,
        // update it with the new sourcePath.
        if (sourcePath != null && child.sourcePath == null) {
          nodes[childId] = child.copyWith(sourcePath: sourcePath);
        }
        return nodes[childId]!;
      }
    }
    final newFolder = TreeNode(
      name: name,
      type: NodeType.folder,
      parentId: parentId,
      virtualPath: path.join(parentVirtualPath, name),
      sourcePath: sourcePath,
      isVirtual: isVirtual,
      source: isVirtual ? FileSource.created : FileSource.disk,
      isExpanded: true,
    );
    nodes[newFolder.id] = newFolder;
    parent.childIds.add(newFolder.id);
    return newFolder;
  }
}
