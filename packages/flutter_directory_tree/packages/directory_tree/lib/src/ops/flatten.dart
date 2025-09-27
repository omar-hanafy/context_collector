// lib/src/ops/flatten.dart
import 'package:directory_tree/src/models/tree_data.dart';
import 'package:directory_tree/src/models/tree_node.dart';
import 'package:directory_tree/src/ops/path_utils.dart';
import 'package:directory_tree/src/ops/search_filter.dart';
import 'package:directory_tree/src/ops/sort_delegate.dart';
import 'package:directory_tree/src/ops/visible_node.dart';

/// Strategy interface so downstream users can swap the algorithm later.
abstract class FlattenStrategy {
  const FlattenStrategy();

  List<VisibleNode> flatten({
    required TreeData data,
    required Set<String> expandedIds,
    String? filterQuery,
  });
}

/// Default DFS-based flatten:
/// - Always includes `visibleRootId` as depth 0
/// - Honors expansion state for folders (visible root is implicitly expanded)
/// - If filter is provided, shows matching nodes and the ancestors needed
class DefaultFlattenStrategy extends FlattenStrategy {
  const DefaultFlattenStrategy();

  @override
  List<VisibleNode> flatten({
    required TreeData data,
    required Set<String> expandedIds,
    String? filterQuery,
  }) {
    final nodes = data.nodes;
    final root = nodes[data.visibleRootId];
    if (root == null) return const <VisibleNode>[];

    final out = <VisibleNode>[];

    final pred = compileFilter(filterQuery);
    final hasFilter = filterQuery != null && filterQuery.trim().isNotEmpty;

    // Precompute "matches or has matching descendant" when filtering.
    final matchesCache = <String, bool>{};
    bool subtreeMatches(String id) {
      if (!hasFilter) return true;
      final cached = matchesCache[id];
      if (cached != null) return cached;
      final n = nodes[id]!;
      final self = pred(n.name, extensionLower(n.name));
      if (self) return matchesCache[id] = true;
      for (final cid in n.childIds) {
        if (subtreeMatches(cid)) {
          return matchesCache[id] = true;
        }
      }
      return matchesCache[id] = false;
    }

    void visit(String id, int depth, {required bool forceExpand}) {
      final n = nodes[id]!;
      // Skip nodes that don't match the filter (and have no matching children).
      if (!subtreeMatches(id)) return;

      final isFolder = n.type == NodeType.folder || n.type == NodeType.root;
      final hasChildren = n.childIds.isNotEmpty;

      out.add(
        VisibleNode(
          id: n.id,
          depth: depth,
          name: n.name,
          type: n.type,
          hasChildren: hasChildren,
          virtualPath: n.virtualPath,
          entryId: n.entryId,
          isVirtual: n.isVirtual,
          sourcePath: n.sourcePath,
          origin: n.origin,
        ),
      );

      // Decide whether to traverse children.
      final expanded = forceExpand || expandedIds.contains(n.id);
      if (isFolder && hasChildren && expanded) {
        for (final cid in n.childIds) {
          visit(cid, depth + 1, forceExpand: hasFilter && subtreeMatches(cid));
        }
      }
    }

    if (data.omitContainerRowAtRoot &&
        (root.type == NodeType.folder || root.type == NodeType.root)) {
      for (final cid in root.childIds) {
        visit(cid, 0, forceExpand: hasFilter && subtreeMatches(cid));
      }
    } else {
      visit(root.id, 0, forceExpand: hasFilter);
    }
    return out;
  }
}

/// Same as default flatten but uses a SortDelegate for child ordering.
class SortedFlattenStrategy extends DefaultFlattenStrategy {
  const SortedFlattenStrategy(this.delegate);
  final SortDelegate delegate;

  @override
  List<VisibleNode> flatten({
    required TreeData data,
    required Set<String> expandedIds,
    String? filterQuery,
  }) {
    final nodes = data.nodes;
    final root = nodes[data.visibleRootId];
    if (root == null) return const <VisibleNode>[];

    final out = <VisibleNode>[];
    final pred = compileFilter(filterQuery);
    final hasFilter = filterQuery != null && filterQuery.trim().isNotEmpty;

    final matchesCache = <String, bool>{};
    bool subtreeMatches(String id) {
      if (!hasFilter) return true;
      final cached = matchesCache[id];
      if (cached != null) return cached;
      final n = nodes[id]!;
      final self = pred(n.name, extensionLower(n.name));
      if (self) return matchesCache[id] = true;
      for (final cid in n.childIds) {
        if (subtreeMatches(cid)) return matchesCache[id] = true;
      }
      return matchesCache[id] = false;
    }

    void visit(String id, int depth, {required bool forceExpand}) {
      final n = nodes[id]!;
      if (!subtreeMatches(id)) return;

      final hasChildren = n.childIds.isNotEmpty;
      out.add(
        VisibleNode(
          id: n.id,
          depth: depth,
          name: n.name,
          type: n.type,
          hasChildren: hasChildren,
          virtualPath: n.virtualPath,
          entryId: n.entryId,
          isVirtual: n.isVirtual,
          sourcePath: n.sourcePath,
          origin: n.origin,
        ),
      );

      final expanded = forceExpand || expandedIds.contains(n.id);
      if ((n.type == NodeType.folder || n.type == NodeType.root) &&
          hasChildren &&
          expanded) {
        final ordered = delegate.sortChildIds(data, n.id);
        for (final cid in ordered) {
          visit(cid, depth + 1, forceExpand: hasFilter && subtreeMatches(cid));
        }
      }
    }

    if (data.omitContainerRowAtRoot &&
        (root.type == NodeType.folder || root.type == NodeType.root)) {
      final ordered = delegate.sortChildIds(data, root.id);
      for (final cid in ordered) {
        visit(cid, 0, forceExpand: hasFilter && subtreeMatches(cid));
      }
    } else {
      visit(root.id, 0, forceExpand: hasFilter);
    }
    return out;
  }
}
