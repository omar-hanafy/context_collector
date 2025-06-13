import 'package:path/path.dart' as path;

import '../../scan/models/scan_result.dart';
import '../../scan/models/scanned_file.dart';
import '../api/virtual_tree_api.dart';

/// Builds a virtual tree deterministically from a list of files and metadata.
class TreeBuilder {
  static const String rootId = 'root';

  TreeData buildTree({
    required List<ScannedFile> files,
    required List<ScanMetadata> scanMetadata,
  }) {
    final nodes = <String, TreeNode>{
      rootId: TreeNode(
        id: rootId,
        name: 'Context Collection',
        type: NodeType.root,
        parentId: '',
        virtualPath: '/',
        isExpanded: true,
      ),
    };

    if (files.isEmpty) {
      return TreeData(nodes: nodes, rootId: rootId);
    }

    final realFiles = files.where((f) => !f.isVirtual).toList();
    final virtualFiles = files.where((f) => f.isVirtual).toList();

    _buildFromRealFiles(nodes, realFiles, scanMetadata);
    _mergeVirtualFiles(nodes, virtualFiles);

    return TreeData(nodes: nodes, rootId: rootId);
  }

  /// PASS 1: Constructs the base tree from filesystem files.
  void _buildFromRealFiles(
    Map<String, TreeNode> nodes,
    List<ScannedFile> realFiles,
    List<ScanMetadata> scanMetadata,
  ) {
    if (realFiles.isEmpty) return;

    final allSourcePaths = scanMetadata
        .expand((meta) => meta.sourcePaths)
        .toSet();
    final filesBySource = _groupFilesByMostSpecificSource(
      realFiles,
      allSourcePaths,
    );
    final sortedSourcePaths = filesBySource.keys.toList()
      ..sort((a, b) => a.length.compareTo(b.length));

    for (final sourcePath in sortedSourcePaths) {
      final filesInGroup = filesBySource[sourcePath]!;
      final parentId = _findBestParentForSource(sourcePath, nodes);
      final parentNode = nodes[parentId]!;
      final sourceFolderName = path.basename(sourcePath);
      final sourceFolderNode = _findOrCreateFolder(
        nodes: nodes,
        name: sourceFolderName,
        parentId: parentId,
        parentVirtualPath: parentNode.virtualPath,
        sourcePath: sourcePath,
      );

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

  /// PASS 2: Merges virtual files by finding the best home in the real tree.
  void _mergeVirtualFiles(
    Map<String, TreeNode> nodes,
    List<ScannedFile> virtualFiles,
  ) {
    virtualFiles.sort(
      (a, b) =>
          (a.relativePath?.length ?? 0).compareTo(b.relativePath?.length ?? 0),
    );

    for (final file in virtualFiles) {
      final relativePath = file.relativePath ?? file.name;
      final parts = path
          .split(relativePath)
          .where((p) => p.isNotEmpty)
          .toList();
      if (parts.isEmpty) continue;

      final folderParts = parts.take(parts.length - 1).toList();
      final fileName = parts.last;

      // Try to find the best existing entry point for this virtual file
      String parentId = _findBestEntryPoint(nodes, folderParts);

      // Calculate remaining path parts to create
      final entryNode = nodes[parentId]!;
      final entryParts = entryNode.virtualPath == '/'
          ? <String>[]
          : path
                .split(entryNode.virtualPath)
                .where((p) => p.isNotEmpty)
                .toList();

      final remainingParts = _getRemainingPath(folderParts, entryParts);

      // Create any remaining folders
      for (final part in remainingParts) {
        final parentNode = nodes[parentId]!;
        parentId = _findOrCreateFolder(
          nodes: nodes,
          name: part,
          parentId: parentId,
          parentVirtualPath: parentNode.virtualPath,
          isVirtual: true,
        ).id;
      }

      // Add the file
      final parentNode = nodes[parentId]!;
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
          isVirtual: true,
          source: FileSource.created,
          isSelected: true,
        );
        parentNode.childIds.add(fileNodeId);
      }
    }
  }

  /// Adds a single file to the tree, creating its folder hierarchy as needed.
  void _addFileAndHierarchy({
    required Map<String, TreeNode> nodes,
    required ScannedFile file,
    required String baseNodeId,
    required String relativePath,
  }) {
    final parts = path.split(relativePath).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return;

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

    final fileName = parts.last;
    final parentNode = nodes[currentParentId]!;
    final fileNodeId = 'node_${file.id}';

    if (!nodes.containsKey(fileNodeId)) {
      nodes[fileNodeId] = TreeNode(
        id: fileNodeId,
        name: fileName,
        type: NodeType.file,
        parentId: currentParentId,
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
        if (path.isWithin(sourcePath, file.fullPath)) {
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

  String _findBestParentForSource(
    String sourcePath,
    Map<String, TreeNode> nodes,
  ) {
    String bestParentId = rootId;
    int maxMatchDepth = -1;
    for (final node in nodes.values) {
      if (node.type != NodeType.folder ||
          node.isVirtual ||
          node.sourcePath == null) {
        continue;
      }
      if (path.isWithin(node.sourcePath!, sourcePath)) {
        final depth = path.split(node.sourcePath!).length;
        if (depth > maxMatchDepth) {
          maxMatchDepth = depth;
          bestParentId = node.id;
        }
      }
    }
    return bestParentId;
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
        // clone it with the new sourcePath and put it back.
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

  /// Finds the best existing entry point in the tree for a virtual file path.
  /// Prefers deeper matches and suffix matches to handle cases where virtual
  /// files were created before real directories were added.
  String _findBestEntryPoint(
    Map<String, TreeNode> nodes,
    List<String> folderParts,
  ) {
    String bestId = rootId;
    int bestScore = -1;

    for (final node in nodes.values) {
      if (node.type == NodeType.file) continue;

      final nodeParts = node.virtualPath == '/'
          ? <String>[]
          : path.split(node.virtualPath).where((p) => p.isNotEmpty).toList();

      if (nodeParts.isEmpty) continue; // Skip root, already handled

      // Check for prefix match (folderParts starts with nodeParts)
      final isPrefix =
          nodeParts.length <= folderParts.length &&
          _listStartsWith(folderParts, nodeParts);

      // Check for suffix match (nodeParts ends with folderParts)
      final isSuffix =
          folderParts.length <= nodeParts.length &&
          _listEndsWith(nodeParts, folderParts);

      if (!isPrefix && !isSuffix) continue;

      // Calculate score: suffix matches get higher score to prefer deeper paths
      int score;
      if (isSuffix) {
        // Suffix match: prefer deeper nodes
        score = folderParts.length * 2000 + nodeParts.length;
      } else {
        // Prefix match: standard scoring
        score = nodeParts.length * 1000 + nodeParts.length;
      }

      if (score > bestScore) {
        bestScore = score;
        bestId = node.id;
      }
    }

    return bestId;
  }

  /// Gets the remaining path parts after the entry point.
  List<String> _getRemainingPath(
    List<String> fullPath,
    List<String> entryParts,
  ) {
    // If entry is root or fullPath is shorter, return the full path
    if (entryParts.isEmpty || fullPath.length < entryParts.length) {
      return fullPath;
    }

    // Check if fullPath starts with entryParts (prefix match)
    if (_listStartsWith(fullPath, entryParts)) {
      return fullPath.sublist(entryParts.length);
    }

    // Check if entryParts ends with fullPath (suffix match)
    if (_listEndsWith(entryParts, fullPath)) {
      return [];
    }

    // No match, return full path
    return fullPath;
  }

  /// Checks if list starts with prefix.
  bool _listStartsWith(List<String> list, List<String> prefix) {
    if (prefix.length > list.length) return false;
    for (int i = 0; i < prefix.length; i++) {
      if (list[i] != prefix[i]) return false;
    }
    return true;
  }

  /// Checks if list ends with suffix.
  bool _listEndsWith(List<String> list, List<String> suffix) {
    if (suffix.length > list.length) return false;
    final offset = list.length - suffix.length;
    for (int i = 0; i < suffix.length; i++) {
      if (list[offset + i] != suffix[i]) return false;
    }
    return true;
  }
}
