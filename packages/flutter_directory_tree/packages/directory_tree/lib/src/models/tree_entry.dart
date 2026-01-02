import 'package:path/path.dart' as p;

/// Represents a raw input item to be organized into the tree.
///
/// A [TreeEntry] is typically a file, but it can represent any leaf entity
/// (e.g., a database row, a virtual document) that has a path-like structure.
///
/// This is the *input* primitive for [TreeBuilder.build]. It differs from
/// [TreeNode], which is the *output* graph node containing hierarchy
/// relationships.
///
/// ### Key Properties
/// *   [fullPath]: The absolute source path used to calculate the entry's
///     position in the tree hierarchy.
/// *   [id]: A stable identifier (e.g., database ID) used to persist selection
///     state across tree rebuilds.
class TreeEntry {
  /// Creates a new [TreeEntry].
  const TreeEntry({
    required this.id,
    required this.name,
    required this.fullPath,
    this.isVirtual = false,
    this.metadata,
  });

  /// Stable id (e.g., your ScannedFile.id).
  final String id;

  /// Display name (basename).
  final String name;

  /// Absolute or canonical source path.
  final String fullPath;

  /// Created in-app, not a physical file.
  final bool isVirtual;

  /// Arbitrary extras (ext, error, etc.).
  final Map<String, Object?>? metadata;

  /// Returns the file extension in lowercase.
  String get extension => p.extension(name).toLowerCase();
}
