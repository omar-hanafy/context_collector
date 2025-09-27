// lib/src/controller/directory_tree_controller.dart
import 'dart:collection';
import 'package:directory_tree/directory_tree.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_directory_tree/src/controller/expansion_controller.dart';
import 'package:flutter_directory_tree/src/controller/selection_controller.dart';

/// Single source of truth for UI state: expansion, selection, filter, flattening.
class DirectoryTreeController extends ChangeNotifier {
  DirectoryTreeController({
    required TreeData data,
    ExpansionController? expansions,
    SelectionController? selection,
    FlattenStrategy? flattenStrategy,
    bool seedSelectionFromCore = true,
    this.autoExpandVisibleRoot = true,
  })  : _data = data,
        _ownsExpansions = expansions == null,
        _ownsSelection = selection == null,
        expansions = expansions ??
            ExpansionController(
              initiallyExpanded: _initialExpandedIds(
                data,
                includeVisibleRoot: autoExpandVisibleRoot,
              ),
            ),
        selection =
            selection ?? SelectionController(mode: SelectionMode.single),
        _flattenStrategy = flattenStrategy ?? const DefaultFlattenStrategy() {
    if (!_ownsExpansions) {
      final external = this.expansions;
      if (external.expandedIds.isEmpty) {
        final seeds = _initialExpandedIds(
          _data,
          includeVisibleRoot: autoExpandVisibleRoot,
        );
        if (seeds.isNotEmpty) {
          external.expandAll(seeds);
        }
      }
    }

    if (_ownsSelection && seedSelectionFromCore) {
      final seeds = _initialSelectedIds(_data);
      if (seeds.isNotEmpty) {
        this.selection.addAll(seeds);
      }
    }

    // Recompute when child controllers change.
    this.expansions.addListener(_bubble);
    this.selection.addListener(_relaySelection);
    _recomputeVisible();
    _rebuildVirtualIndex();
  }

  TreeData get data => _data;
  TreeData _data;

  final bool autoExpandVisibleRoot;

  final ExpansionController expansions;
  final SelectionController selection;
  final bool _ownsExpansions;
  final bool _ownsSelection;

  final FlattenStrategy _flattenStrategy;

  String _filterQuery = '';

  String get filterQuery => _filterQuery;

  set filterQuery(String value) {
    final next = value.trim();
    if (next == _filterQuery) return;
    _filterQuery = next;
    _recomputeVisible();
    notifyListeners();
  }

  List<VisibleNode> get visibleNodes => _visibleNodesView;
  late List<VisibleNode> _visibleNodes;
  late UnmodifiableListView<VisibleNode> _visibleNodesView;
  late Map<String, int> _indexById;
  late Map<String, String> _idByVirtualPath;
  late Map<String, String> _idByEntryId;
  bool _suppressBubble = false;
  void _relaySelection() {
    if (_suppressBubble) return;
    notifyListeners();
  }

  /// Swap in a new structural tree. Attempts to preserve expansion/selection.
  void rebuild(
    TreeData next, {
    bool tryPreserveState = true,
    bool reseedFromCore = false,
  }) {
    _data = next;

    final existingIds = next.nodes.keys.toSet();

    _suppressBubble = true;
    try {
      if (tryPreserveState) {
        expansions.retainWhere(existingIds.contains);
        selection.retainWhere(existingIds.contains);
      } else {
        expansions.collapseAll();
        selection.clear();
      }

      if (reseedFromCore) {
        final seeds = _initialExpandedIds(
          next,
          includeVisibleRoot: autoExpandVisibleRoot,
        );
        expansions
          ..collapseAll()
          ..expandAll(seeds);
        final selectionSeeds = _initialSelectedIds(next);
        selection.performBatch(() {
          selection.clear();
          if (selectionSeeds.isNotEmpty) {
            selection.addAll(selectionSeeds);
          }
        });
      } else if (autoExpandVisibleRoot &&
          !expansions.isExpanded(next.visibleRootId)) {
        expansions.setExpanded(next.visibleRootId, true);
      }
    } finally {
      _suppressBubble = false;
    }

    _recomputeVisible();
    _rebuildVirtualIndex();
    notifyListeners();
  }

  /// Expand all ancestors to reveal a node, then optionally select it.
  Future<void> reveal({
    String? nodeId,
    String? virtualPath,
    bool select = false,
  }) async {
    final id = nodeId ?? _findByVirtualPath(virtualPath ?? '');
    if (id == null) return;

    // Walk parents and expand.
    String? current = id;
    while (current != null && current.isNotEmpty) {
      final node = _data.nodes[current];
      if (node == null) break;
      if (node.type == NodeType.folder || node.type == NodeType.root) {
        expansions.setExpanded(node.id, true);
      }
      if (node.id == _data.visibleRootId) break;
      current = node.parentId;
    }

    if (select) {
      selection.selectOnly(id);
    }
  }

  /// Reveal a node and scroll it into view using a [ScrollController].
  Future<void> revealAndScroll({
    String? nodeId,
    String? virtualPath,
    bool select = false,
    required ScrollController scrollController,
    required double rowExtent,
    bool animate = true,
    Duration duration = const Duration(milliseconds: 220),
    Curve curve = Curves.easeOutCubic,
  }) async {
    assert(nodeId != null || (virtualPath != null && virtualPath.isNotEmpty),
        'Either nodeId or virtualPath must be provided.');

    final resolvedId = nodeId ?? _findByVirtualPath(virtualPath ?? '');
    if (resolvedId == null) {
      return;
    }

    await reveal(nodeId: resolvedId, select: select);

    if (!scrollController.hasClients) {
      return;
    }

    // Let any synchronous listeners run before computing offsets.
    await Future<void>.microtask(() {});

    final index = indexOfNode(resolvedId);
    if (index < 0) {
      return;
    }

    final target = index * rowExtent;
    final position = scrollController.position;
    final viewportExtent = position.viewportDimension;
    final contentExtent = _visibleNodes.length * rowExtent;
    final maxExtent =
        (contentExtent - viewportExtent).clamp(0.0, double.infinity);
    final clamped = target.clamp(position.minScrollExtent, maxExtent);

    if (animate) {
      await scrollController.animateTo(
        clamped,
        duration: duration,
        curve: curve,
      );
    } else {
      scrollController.jumpTo(clamped);
    }
  }

  void expand(String nodeId, {bool recursive = false}) {
    if (!_data.nodes.containsKey(nodeId) || !_isFolderLike(nodeId)) return;
    if (recursive) {
      expansions.performBatch(() {
        _expandDescendants(nodeId);
      });
    } else {
      expansions.setExpanded(nodeId, true);
    }
  }

  void collapse(String nodeId, {bool recursive = false}) {
    if (!_data.nodes.containsKey(nodeId) || !_isFolderLike(nodeId)) return;
    if (recursive) {
      expansions.performBatch(() {
        _collapseDescendants(nodeId);
      });
    } else {
      expansions.setExpanded(nodeId, false);
    }
  }

  void toggle(String nodeId) {
    if (!_data.nodes.containsKey(nodeId) || !_isFolderLike(nodeId)) return;
    expansions.toggle(nodeId);
  }

  void selectOnly(String nodeId) {
    selection.selectOnly(nodeId);
  }

  void toggleSelection(String nodeId) {
    selection.toggle(nodeId);
  }

  void selectRange({required String anchorId, required String toId}) {
    final a = _indexById[anchorId];
    final b = _indexById[toId];
    if (a == null || b == null) return;
    final start = a < b ? a : b;
    final end = a < b ? b : a;
    final ids = <String>[
      for (var i = start; i <= end; i++) _visibleNodes[i].id,
    ];
    selection.selectRange(ids, anchorId, toId);
  }

  void clearSelection() {
    selection.clear();
  }

  /// Add all file descendants of [nodeId] to the current selection.
  void selectSubtree(String nodeId) {
    final ids = _descendantFileIds(nodeId);
    if (ids.isEmpty) return;
    selection.performBatch(() {
      selection.addAll(ids);
    });
  }

  /// Remove all file descendants of [nodeId] from the current selection.
  void deselectSubtree(String nodeId) {
    final ids = _descendantFileIds(nodeId);
    if (ids.isEmpty) return;
    selection.performBatch(() {
      selection.removeAll(ids);
    });
  }

  /// Lookup a visible node id using a core entryId (file identifier).
  String? nodeIdForEntryId(String entryId) => _idByEntryId[entryId];

  /// Reveal and optionally select a node by its underlying entry id.
  Future<void> revealByEntryId(String entryId, {bool select = false}) async {
    final id = nodeIdForEntryId(entryId);
    if (id == null) return;
    await reveal(nodeId: id, select: select);
  }

  /// Return the visible index of a node, or -1 if not visible.
  int indexOfNode(String nodeId) => _indexById[nodeId] ?? -1;

  // ---- internals ------------------------------------------------------------

  bool _isFolderLike(String nodeId) {
    final type = _data.nodes[nodeId]?.type;
    return type == NodeType.folder || type == NodeType.root;
  }

  void _recomputeVisible() {
    _visibleNodes = _flattenStrategy.flatten(
      data: _data,
      expandedIds: expansions.expandedIds,
      filterQuery: _filterQuery.isEmpty ? null : _filterQuery,
    );
    _visibleNodesView = UnmodifiableListView(_visibleNodes);
    _indexById = {
      for (var i = 0; i < _visibleNodes.length; i++) _visibleNodes[i].id: i,
    };
  }

  void _rebuildVirtualIndex() {
    _idByVirtualPath = {
      for (final entry in _data.nodes.entries)
        if (entry.value.virtualPath.isNotEmpty)
          entry.value.virtualPath: entry.key,
    };
    _idByEntryId = {
      for (final entry in _data.nodes.entries)
        if (entry.value.entryId != null) entry.value.entryId!: entry.key,
    };
  }

  void _bubble() {
    if (_suppressBubble) return;
    _recomputeVisible();
    notifyListeners();
  }

  String? _findByVirtualPath(String virtualPath) {
    if (virtualPath.isEmpty) return null;
    return _idByVirtualPath[virtualPath];
  }

  void _expandDescendants(String nodeId) {
    final stack = <String>[nodeId];
    while (stack.isNotEmpty) {
      final id = stack.removeLast();
      final node = _data.nodes[id];
      if (node == null) continue;
      if (_isFolderLike(id)) {
        expansions.setExpanded(id, true);
      }
      if (node.childIds.isNotEmpty) {
        stack.addAll(node.childIds);
      }
    }
  }

  void _collapseDescendants(String nodeId) {
    final stack = <String>[nodeId];
    while (stack.isNotEmpty) {
      final id = stack.removeLast();
      final node = _data.nodes[id];
      if (node == null) continue;
      if (_isFolderLike(id)) {
        expansions.setExpanded(id, false);
      }
      stack.addAll(node.childIds);
    }
  }

  List<String> _descendantFileIds(String nodeId) {
    final root = _data.nodes[nodeId];
    if (root == null) return const <String>[];
    final fileIds = <String>[];
    final stack = <String>[nodeId];
    while (stack.isNotEmpty) {
      final id = stack.removeLast();
      final node = _data.nodes[id];
      if (node == null) continue;
      if (node.type == NodeType.file) {
        fileIds.add(id);
      } else if (node.childIds.isNotEmpty) {
        stack.addAll(node.childIds);
      }
    }
    return fileIds;
  }

  @override
  void dispose() {
    expansions.removeListener(_bubble);
    selection.removeListener(_relaySelection);
    if (_ownsExpansions) {
      expansions.dispose();
    }
    if (_ownsSelection) {
      selection.dispose();
    }
    super.dispose();
  }

  static Set<String> _initialExpandedIds(
    TreeData data, {
    bool includeVisibleRoot = true,
  }) {
    final seeds = <String>{};
    if (includeVisibleRoot) {
      seeds.add(data.visibleRootId);
    }
    for (final node in data.nodes.values) {
      if (node.isExpanded &&
          (includeVisibleRoot || node.id != data.visibleRootId)) {
        seeds.add(node.id);
      }
    }
    return seeds;
  }

  static Set<String> _initialSelectedIds(TreeData data) {
    final seeds = <String>{};
    for (final node in data.nodes.values) {
      if (node.isSelected) {
        seeds.add(node.id);
      }
    }
    return seeds;
  }
}
