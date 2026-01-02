// lib/src/ops/sort_delegate.dart
import 'package:directory_tree/src/models/tree_data.dart';
import 'package:directory_tree/src/models/tree_node.dart';

/// Controls how children of a folder are ordered.
///
/// Implement this interface to define custom sorting logic (e.g., sort by date,
/// size, or file type priority). Pass it to [SortedFlattenStrategy].
abstract class SortDelegate {
  /// Abstract constant constructor.
  const SortDelegate();

  /// Return an ordered list of child ids for `parentId`.
  List<String> sortChildIds(TreeData data, String parentId);
}

/// A standard sorter: Folders first, then files, sorted alphabetically.
///
/// Comparison is case-insensitive. Ties are broken by node ID.
class AlphaSortDelegate extends SortDelegate {
  /// Creates a standard alphabetical sort delegate.
  const AlphaSortDelegate();

  @override
  List<String> sortChildIds(TreeData data, String parentId) {
    final parent = data.nodes[parentId];
    if (parent == null) return const <String>[];

    final byName = List<String>.from(parent.childIds);
    int cmp(String aId, String bId) {
      final a = data.nodes[aId]!;
      final b = data.nodes[bId]!;
      if (a.type != b.type) return a.type == NodeType.folder ? -1 : 1;
      final n = a.name.toLowerCase().compareTo(b.name.toLowerCase());
      if (n != 0) return n;
      return a.id.compareTo(b.id);
    }

    byName.sort(cmp);
    return byName;
  }
}
