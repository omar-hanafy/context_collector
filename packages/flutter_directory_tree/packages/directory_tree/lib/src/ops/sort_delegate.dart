// lib/src/ops/sort_delegate.dart
import 'package:directory_tree/src/models/tree_data.dart';
import 'package:directory_tree/src/models/tree_node.dart';

/// Lets apps override child ordering under a parent node.
/// Use with `SortedFlattenStrategy` (see ops/flatten.dart).
abstract class SortDelegate {
  const SortDelegate();

  /// Return an ordered list of child ids for `parentId`.
  List<String> sortChildIds(TreeData data, String parentId);
}

/// Default: Folders first, then files; both case-insensitive by name, then id.
class AlphaSortDelegate extends SortDelegate {
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
