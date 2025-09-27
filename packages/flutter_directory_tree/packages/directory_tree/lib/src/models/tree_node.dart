import 'package:equatable/equatable.dart';
import 'package:uuid/uuid.dart';

enum NodeType { root, folder, file }

/// Marks whether a directory is directly selected by the user (TRD) or
/// materialized as an inferred intermediate.
enum SelectionOrigin { none, inferred, direct }

class TreeNode extends Equatable {
  TreeNode({
    required this.name,
    required this.type,
    required this.parentId,
    required this.virtualPath,
    String? id,
    this.sourcePath,
    this.entryId,
    this.isVirtual = false,
    this.isExpanded = false,
    this.isSelected = false,
    List<String>? childIds,
    this.origin = SelectionOrigin.none,
  })  : id = id ?? const Uuid().v4(),
        childIds = childIds ?? const [];

  final String id;
  final String name;
  final NodeType type;
  final String parentId;
  final List<String> childIds;

  final String? sourcePath; // original path if any
  final String virtualPath; // path inside the virtual tree
  final String? entryId; // links to TreeEntry.id (for file nodes)
  final bool isVirtual;

  final bool isExpanded; // default visual state on first build
  final bool isSelected; // default selection state on first build
  final SelectionOrigin origin; // differentiates direct vs inferred folders

  TreeNode copyWith({
    String? name,
    bool? isExpanded,
    bool? isSelected,
    List<String>? childIds,
    String? sourcePath,
    SelectionOrigin? origin,
  }) {
    return TreeNode(
      id: id,
      name: name ?? this.name,
      type: type,
      parentId: parentId,
      virtualPath: virtualPath,
      sourcePath: sourcePath ?? this.sourcePath,
      entryId: entryId,
      isVirtual: isVirtual,
      isExpanded: isExpanded ?? this.isExpanded,
      isSelected: isSelected ?? this.isSelected,
      childIds: childIds ?? this.childIds,
      origin: origin ?? this.origin,
    );
  }

  @override
  List<Object?> get props => [id];
}
