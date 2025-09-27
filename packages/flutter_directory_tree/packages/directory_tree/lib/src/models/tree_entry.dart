import 'package:path/path.dart' as p;

/// A single logical item for the virtual tree.
/// Typically represents a file, but can be any leaf entity you want to show.
class TreeEntry {
  const TreeEntry({
    required this.id,
    required this.name,
    required this.fullPath,
    this.isVirtual = false,
    this.metadata,
  });

  /// Stable id (e.g., your ScannedFile.id)
  final String id;

  /// Display name (basename)
  final String name;

  /// Absolute or canonical source path
  final String fullPath;

  /// Created in-app, not a physical file
  final bool isVirtual;

  /// arbitrary extras (ext, error, etc.)
  final Map<String, Object?>? metadata;

  String get extension => p.extension(name).toLowerCase();
}
