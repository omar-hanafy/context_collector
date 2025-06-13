import 'package:uuid/uuid.dart';

/// Node types in the virtual tree
enum NodeType { root, folder, file }

/// Source of the file/folder
enum FileSource { disk, created, pasted }

/// Represents a node in the virtual file tree
class TreeNode {
  final String id;
  final String name;
  final NodeType type;
  final String parentId;
  final List<String> childIds;

  // Source information
  final String? sourcePath; // Original disk path
  final String virtualPath; // Path in virtual tree
  final bool isVirtual; // Created in-app
  final FileSource source;

  // Content management
  final String? fileId; // Links to ScannedFile.id

  // UI state
  bool isExpanded;
  bool isSelected;

  TreeNode({
    String? id,
    required this.name,
    required this.type,
    required this.parentId,
    required this.virtualPath,
    this.sourcePath,
    this.fileId,
    this.isVirtual = false,
    this.source = FileSource.disk,
    this.isExpanded = false,
    this.isSelected = false,
    List<String>? childIds,
  }) : id = id ?? const Uuid().v4(),
       childIds = childIds ?? [];

  /// Create a copy with updated values
  TreeNode copyWith({
    String? name,
    bool? isExpanded,
    bool? isSelected,
    List<String>? childIds,
    String? sourcePath,
  }) {
    return TreeNode(
      id: id,
      name: name ?? this.name,
      type: type,
      parentId: parentId,
      virtualPath: virtualPath,
      sourcePath: sourcePath ?? this.sourcePath,
      fileId: fileId,
      isVirtual: isVirtual,
      source: source,
      isExpanded: isExpanded ?? this.isExpanded,
      isSelected: isSelected ?? this.isSelected,
      childIds: childIds ?? this.childIds,
    );
  }

  /// Convert to map for serialization
  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'type': type.index,
    'parentId': parentId,
    'virtualPath': virtualPath,
    'sourcePath': sourcePath,
    'fileId': fileId,
    'isVirtual': isVirtual,
    'source': source.index,
    'isExpanded': isExpanded,
    'isSelected': isSelected,
    'childIds': childIds,
  };

  /// Create from map
  factory TreeNode.fromMap(Map<String, dynamic> map) => TreeNode(
    id: map['id'] as String,
    name: map['name'] as String,
    type: NodeType.values[map['type'] as int],
    parentId: map['parentId'] as String,
    virtualPath: map['virtualPath'] as String,
    sourcePath: map['sourcePath'] as String?,
    fileId: map['fileId'] as String?,
    isVirtual: map['isVirtual'] as bool? ?? false,
    source: FileSource.values[map['source'] as int? ?? 0],
    isExpanded: map['isExpanded'] as bool? ?? false,
    isSelected: map['isSelected'] as bool? ?? false,
    childIds: (map['childIds'] as List<dynamic>?)?.cast<String>() ?? [],
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is TreeNode && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
