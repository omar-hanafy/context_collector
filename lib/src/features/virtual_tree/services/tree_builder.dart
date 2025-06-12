import 'package:path/path.dart' as path;
import '../../scan/models/scanned_file.dart';
import '../../scan/models/scan_result.dart';
import '../api/virtual_tree_api.dart';
import '../models/tree_node.dart';

/// Builds virtual tree structures from file lists
class TreeBuilder {
  static const String rootId = 'root';
  
  /// Build a complete tree from files and scan metadata
  TreeData buildTree({
    required List<ScannedFile> files,
    required List<ScanMetadata> scanMetadata,
    Map<String, TreeNode>? existingNodes,
    Set<String>? existingFileIds,
  }) {
    final nodes = existingNodes != null 
        ? Map<String, TreeNode>.from(existingNodes)
        : <String, TreeNode>{};
    
    // Create or get root node
    if (!nodes.containsKey(rootId)) {
      final root = TreeNode(
        id: rootId,
        name: 'Context Collection',
        type: NodeType.root,
        parentId: '',
        virtualPath: '/',
        isExpanded: true,
      );
      nodes[rootId] = root;
    }
    
    if (files.isEmpty) {
      return TreeData(nodes: nodes, rootId: rootId);
    }
    
    // Filter out files that already exist
    final newFiles = existingFileIds != null
        ? files.where((file) => !existingFileIds.contains(file.id)).toList()
        : files;
    
    // Debug: Check for duplicates in the input files
    final uniqueFileIds = <String>{};
    final deduplicatedFiles = <ScannedFile>[];
    for (final file in newFiles) {
      if (!uniqueFileIds.contains(file.id)) {
        uniqueFileIds.add(file.id);
        deduplicatedFiles.add(file);
      }
    }
    
    if (deduplicatedFiles.isEmpty) {
      return TreeData(nodes: nodes, rootId: rootId);
    }
    
    // Group files by their scan source
    final filesBySource = _groupFilesBySource(deduplicatedFiles, scanMetadata);
    
    // Build optimal tree structure
    for (final entry in filesBySource.entries) {
      _buildSubtree(
        nodes: nodes,
        sourcePath: entry.key,
        files: entry.value,
        parentId: rootId,
      );
    }
    
    return TreeData(nodes: nodes, rootId: rootId);
  }
  
  /// Group files by their source paths for intelligent tree building
  Map<String, List<ScannedFile>> _groupFilesBySource(
    List<ScannedFile> files,
    List<ScanMetadata> metadata,
  ) {
    final groups = <String, List<ScannedFile>>{};
    
    // First, check if all files share a common duplicate folder prefix
    // This happens when files are dropped with "Add as Duplicate" option
    String? commonDuplicatePrefix;
    bool allHaveDuplicatePrefix = true;
    
    for (final file in files) {
      if (file.relativePath == null || !file.relativePath!.contains('(copy')) {
        allHaveDuplicatePrefix = false;
        break;
      }
      
      final parts = file.relativePath!.split(path.separator);
      if (parts.isNotEmpty && parts.first.contains('(copy')) {
        if (commonDuplicatePrefix == null) {
          commonDuplicatePrefix = parts.first;
        } else if (commonDuplicatePrefix != parts.first) {
          allHaveDuplicatePrefix = false;
          break;
        }
      } else {
        allHaveDuplicatePrefix = false;
        break;
      }
    }
    
    // If all files share a duplicate prefix, group them together
    if (allHaveDuplicatePrefix && commonDuplicatePrefix != null) {
      groups[''] = files; // Empty key means no additional source folder needed
      return groups;
    }
    
    // Otherwise, use metadata to group files by their actual source paths
    if (metadata.isNotEmpty) {
      // Create a map to track which files have been assigned to groups
      final assignedFiles = <String>{};
      
      // Process each file and assign it to exactly one group
      for (final file in files) {
        // Skip if already assigned
        if (assignedFiles.contains(file.id)) {
          continue;
        }
        
        // Determine the grouping key based on the file's path
        String groupKey = '';
        
        // Try to find which source path this file belongs to
        for (final scan in metadata) {
          for (final sourcePath in scan.sourcePaths) {
            if (file.fullPath.startsWith(sourcePath)) {
              groupKey = sourcePath;
              break;
            }
          }
          if (groupKey.isNotEmpty) break;
        }
        
        // If no source path matched, use the file's parent directory
        if (groupKey.isEmpty && file.fullPath.isNotEmpty) {
          groupKey = path.dirname(file.fullPath);
        }
        
        // Add file to its group and mark as assigned
        groups.putIfAbsent(groupKey, () => []).add(file);
        assignedFiles.add(file.id);
      }
    } else {
      // Fallback: group by common ancestors
      groups[''] = files;
    }
    
    return groups;
  }
  
  /// Build a subtree for a group of files from the same source
  void _buildSubtree({
    required Map<String, TreeNode> nodes,
    required String sourcePath,
    required List<ScannedFile> files,
    required String parentId,
  }) {
    if (files.isEmpty) return;
    
    // Check if all files already have a common folder prefix in their relative paths
    // This happens when we're adding duplicates with renamed folders
    String? commonTopFolder;
    bool allHaveCommonFolder = true;
    
    for (final file in files) {
      if (file.relativePath == null || file.relativePath!.isEmpty) {
        allHaveCommonFolder = false;
        break;
      }
      
      final parts = file.relativePath!.split(path.separator);
      if (parts.length > 1) {
        // File has folder structure in relative path
        final topFolder = parts.first;
        if (commonTopFolder == null) {
          commonTopFolder = topFolder;
        } else if (commonTopFolder != topFolder) {
          allHaveCommonFolder = false;
          break;
        }
      } else {
        // File is at root level of relative path
        allHaveCommonFolder = false;
        break;
      }
    }
    
    // Decide whether to create a source folder
    String currentParentId = parentId;
    
    if (allHaveCommonFolder && commonTopFolder != null && 
        (commonTopFolder.contains('(copy') || commonTopFolder.contains('(2)'))) {
      // Files already have the duplicate folder in their relative paths
      // Don't create an additional source folder
      currentParentId = parentId;
    } else if (sourcePath.isNotEmpty) {
      // Create a source folder to group these files
      final folderName = _getSourceFolderName(sourcePath);
      
      // Check if a folder with this name already exists at this level
      TreeNode? existingFolder;
      final parent = nodes[parentId]!;
      for (final childId in parent.childIds) {
        final child = nodes[childId];
        if (child != null && child.type == NodeType.folder && child.name == folderName) {
          existingFolder = child;
          break;
        }
      }
      
      if (existingFolder != null) {
        // Use existing folder
        currentParentId = existingFolder.id;
      } else {
        // Create new folder
        final sourceFolder = _createFolderNode(
          name: folderName,
          parentId: parentId,
          virtualPath: folderName,
          sourcePath: sourcePath,
        );
        
        nodes[sourceFolder.id] = sourceFolder;
        nodes[parentId]!.childIds.add(sourceFolder.id);
        currentParentId = sourceFolder.id;
      }
    }
    
    // Process each file
    for (final file in files) {
      _addFileToTree(
        nodes: nodes,
        file: file,
        sourceParentId: currentParentId,
        sourcePath: sourcePath,
      );
    }
  }
  
  /// Add a single file to the tree, creating folders as needed
  void _addFileToTree({
    required Map<String, TreeNode> nodes,
    required ScannedFile file,
    required String sourceParentId,
    required String sourcePath,
  }) {
    // Use relative path if available, otherwise compute it
    String relativePath = file.relativePath ?? '';
    
    if (relativePath.isEmpty && sourcePath.isNotEmpty) {
      // Try to compute relative path
      if (file.fullPath.startsWith(sourcePath)) {
        relativePath = path.relative(file.fullPath, from: sourcePath);
      }
    }
    
    // If still no relative path, just use the file name
    if (relativePath.isEmpty) {
      relativePath = file.name;
    }
    
    // Split path into parts
    final parts = relativePath.split(path.separator)
        .where((p) => p.isNotEmpty)
        .toList();
    
    if (parts.isEmpty) return;
    
    // Create folder hierarchy
    String currentParentId = sourceParentId;
    String currentVirtualPath = nodes[sourceParentId]!.virtualPath;
    
    // Process all parts except the last (which is the file)
    for (int i = 0; i < parts.length - 1; i++) {
      final folderName = parts[i];
      final folderVirtualPath = path.join(currentVirtualPath, folderName);
      
      // Check if folder already exists
      final existingFolder = _findChildByName(
        nodes: nodes,
        parentId: currentParentId,
        name: folderName,
        type: NodeType.folder,
      );
      
      if (existingFolder != null) {
        currentParentId = existingFolder.id;
        currentVirtualPath = existingFolder.virtualPath;
      } else {
        // Create new folder
        final folder = _createFolderNode(
          name: folderName,
          parentId: currentParentId,
          virtualPath: folderVirtualPath,
        );
        
        nodes[folder.id] = folder;
        nodes[currentParentId]!.childIds.add(folder.id);
        
        currentParentId = folder.id;
        currentVirtualPath = folderVirtualPath;
      }
    }
    
    // Create file node
    final fileName = parts.last;
    final fileVirtualPath = path.join(currentVirtualPath, fileName);
    final nodeId = 'node_${file.id}';
    
    // Check if this node already exists (prevent duplicates)
    if (nodes.containsKey(nodeId)) {
      return;
    }
    
    final fileNode = TreeNode(
      id: nodeId,
      name: fileName,
      type: NodeType.file,
      parentId: currentParentId,
      virtualPath: fileVirtualPath,
      sourcePath: file.fullPath,
      fileId: file.id,
      isVirtual: file.isVirtual,
      source: file.isVirtual ? FileSource.created : FileSource.disk,
      isSelected: true,  // Auto-select new files
    );
    
    nodes[fileNode.id] = fileNode;
    nodes[currentParentId]!.childIds.add(fileNode.id);
  }
  
  /// Create a folder node
  TreeNode _createFolderNode({
    required String name,
    required String parentId,
    required String virtualPath,
    String? sourcePath,
  }) {
    return TreeNode(
      name: name,
      type: NodeType.folder,
      parentId: parentId,
      virtualPath: virtualPath,
      sourcePath: sourcePath,
      isExpanded: true, // Expand folders by default
    );
  }
  
  /// Find a child node by name and type
  TreeNode? _findChildByName({
    required Map<String, TreeNode> nodes,
    required String parentId,
    required String name,
    required NodeType type,
  }) {
    final parent = nodes[parentId];
    if (parent == null) return null;
    
    for (final childId in parent.childIds) {
      final child = nodes[childId];
      if (child != null && child.name == name && child.type == type) {
        return child;
      }
    }
    
    return null;
  }
  
  /// Get a user-friendly name for a source folder
  String _getSourceFolderName(String sourcePath) {
    // Get the last two parts of the path for context
    final parts = sourcePath.split(path.separator)
        .where((p) => p.isNotEmpty)
        .toList();
    
    if (parts.isEmpty) return 'Source';
    
    // If it's a common project name, use just that
    final lastPart = parts.last;
    if (_isProjectName(lastPart)) {
      return lastPart;
    }
    
    // Otherwise, use last two parts for context
    if (parts.length >= 2) {
      return '${parts[parts.length - 2]}/${parts.last}';
    }
    
    return lastPart;
  }
  
  /// Check if a folder name looks like a project name
  bool _isProjectName(String name) {
    return name.contains(RegExp(r'[_\-.]')) || 
           name.length > 15 || 
           !name.contains(RegExp(r'[A-Z]'));
  }
}
