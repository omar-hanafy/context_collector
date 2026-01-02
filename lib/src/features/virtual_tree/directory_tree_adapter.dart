import 'package:flutter/foundation.dart';
import 'package:flutter_directory_tree/flutter_directory_tree.dart' as tree;

import '../scan/models/scan_result.dart';
import '../scan/models/scanned_file.dart';

/// Bridge between the scanner's single source of truth and the packaged tree.
class DirectoryTreeAdapter extends ChangeNotifier {
  DirectoryTreeAdapter({
    this.rowHeight = 32.0,
    tree.SortDelegate? sortDelegate,
    this.keepTreeFolderVisible = true,
  }) : _sortDelegate = sortDelegate ?? const CollectorSortDelegate() {
    _controller = tree.DirectoryTreeController(
      data: const tree.TreeData(
        nodes: {},
        rootId: tree.TreeBuilder.rootId,
        visibleRootId: tree.TreeBuilder.treeRootId,
      ),
      // Align tree behavior with checkbox UI by allowing multi-selection.
      selection: tree.SelectionController(mode: tree.SelectionMode.multi),
      flattenStrategy: _CollectorFlattenStrategy(
        () => _hiddenNodeIds,
        _sortDelegate,
      ),
      seedSelectionFromCore: true,
      autoExpandVisibleRoot: false,
    );

    _controller.selection.addListener(_relaySelection);
    _controller.addListener(_bubbleChanges);
  }

  final double rowHeight;
  final tree.SortDelegate _sortDelegate;
  final bool keepTreeFolderVisible;

  late final tree.DirectoryTreeController _controller;
  ValueChanged<Set<String>>? _selectionRelay;
  bool _suppressSelectionRelay = false;
  bool _suppressBubble = false;
  tree.TreeNode? _headerNode;
  tree.TreeNode? _footerNode;
  final Set<String> _hiddenNodeIds = <String>{};
  bool _isDisposed = false;

  tree.DirectoryTreeController get controller => _controller;

  tree.TreeNode? get headerNode => _headerNode;
  tree.TreeNode? get footerNode => _footerNode;

  String? get headerEntryId => _headerNode?.entryId;
  String? get footerEntryId => _footerNode?.entryId;

  /// Hook the scanner selection callback after the adapter is constructed.
  set selectionRelay(ValueChanged<Set<String>>? callback) {
    _selectionRelay = callback;
  }

  /// Rebuild the packaged tree from the latest scanner state.
  void rebuildFromScanner({
    required Iterable<ScannedFile> files,
    required Iterable<ScanMetadata> metadata,
    required Set<String> selectedFileIds,
  }) {
    final hadTree = _controller.data.nodes.isNotEmpty;
    final wasRootExpanded =
        hadTree &&
        _controller.expansions.isExpanded(tree.TreeBuilder.treeRootId);

    final entries = <tree.TreeEntry>[
      for (final file in files)
        tree.TreeEntry(
          id: file.id,
          name: file.name,
          fullPath: file.fullPath,
          isVirtual: file.isVirtual,
          metadata: file.displayPath == null
              ? null
              : {'displayPath': file.displayPath},
        ),
    ];

    final roots = metadata.expand((m) => m.sourcePaths).toSet().toList()
      ..sort();

    final builder = tree.TreeBuilder();
    final data = builder.build(
      entries: entries,
      sourceRoots: roots,
      rootFolderLabel: 'tree',
      expandFoldersByDefault: true,
      selectNewFilesByDefault: true,
      preferDeepestRoot: true,
      sortChildrenByName: true,
      stripPrefixes: roots,
      autoPickVisibleRoot: !keepTreeFolderVisible,
      visibleRootMaxHoistLevels: 2,
      visibleRootIgnoreVirtualFiles: true,
      mergeVirtualIntoRealFolders: true,
    );

    _headerNode = null;
    _footerNode = null;
    _hiddenNodeIds.clear();

    for (final node in data.nodes.values) {
      if (node.entryId != null &&
          node.isVirtual &&
          node.parentId == tree.TreeBuilder.treeRootId) {
        if (node.name == 'Header') {
          _headerNode = node;
          _hiddenNodeIds.add(node.id);
        } else if (node.name == 'Footer') {
          _footerNode = node;
          _hiddenNodeIds.add(node.id);
        }
      }
    }

    _suppressBubble = true;
    try {
      _controller.rebuild(
        data,
        tryPreserveState: true,
        // Seed once on first build; subsequent rebuilds keep user-driven expansion state.
        reseedFromCore: !hadTree,
      );
      if (hadTree) {
        _controller.expansions.setExpanded(
          tree.TreeBuilder.treeRootId,
          wasRootExpanded,
        );
      }
      setSelectedEntryIds(selectedFileIds);
    } finally {
      _suppressBubble = false;
    }

    notifyListeners();
  }

  /// Update the tree selection from the scanner without triggering a feedback loop.
  void setSelectedEntryIds(Set<String> entryIds) {
    _suppressSelectionRelay = true;
    try {
      final nodeIds = entryIds
          .map(_controller.nodeIdForEntryId)
          .whereType<String>()
          .toSet();
      _controller.selection.performBatch(() {
        _controller.selection.selectOnlyMany(nodeIds);
      });
    } finally {
      _suppressSelectionRelay = false;
    }
  }

  /// Reveal a node by the underlying scanner file id.
  Future<void> revealByEntryId(String fileId, {bool select = false}) {
    return _controller.revealByEntryId(fileId, select: select);
  }

  /// Clear all tree data (e.g. when the session resets).
  void clear() {
    _hiddenNodeIds.clear();
    _headerNode = null;
    _footerNode = null;
    _controller.rebuild(
      const tree.TreeData(
        nodes: {},
        rootId: tree.TreeBuilder.rootId,
        visibleRootId: tree.TreeBuilder.treeRootId,
      ),
      tryPreserveState: false,
      reseedFromCore: false,
    );
    notifyListeners();
  }

  /// Collect all file entry ids contained within the given visible node ids.
  Set<String> collectEntryIds(Iterable<String> nodeIds) {
    final out = <String>{};
    final data = _controller.data;
    void walk(String nodeId) {
      final node = data.nodes[nodeId];
      if (node == null) return;
      if (node.entryId != null) {
        out.add(node.entryId!);
      }
      for (final child in node.childIds) {
        walk(child);
      }
    }

    for (final id in nodeIds) {
      walk(id);
    }
    return out;
  }

  /// Collect source paths from folder nodes, used for scan-history cleanup.
  Set<String> collectSourcePaths(Iterable<String> nodeIds) {
    final out = <String>{};
    final data = _controller.data;
    void walk(String nodeId) {
      final node = data.nodes[nodeId];
      if (node == null) return;
      if (node.type == tree.NodeType.folder && node.sourcePath != null) {
        out.add(node.sourcePath!);
      }
      for (final child in node.childIds) {
        walk(child);
      }
    }

    for (final id in nodeIds) {
      walk(id);
    }
    return out;
  }

  tree.TreeData get data => _controller.data;

  void _relaySelection() {
    if (_suppressSelectionRelay) return;
    final relay = _selectionRelay;
    if (relay == null) return;
    final ids = <String>{};
    for (final nodeId in _controller.selection.selectedIds) {
      final node = _controller.data.nodes[nodeId];
      final entryId = node?.entryId;
      if (entryId != null) {
        ids.add(entryId);
      }
    }
    relay(ids);
  }

  void _bubbleChanges() {
    if (_suppressBubble) return;
    notifyListeners();
  }

  @override
  void dispose() {
    if (_isDisposed) {
      return;
    }
    _isDisposed = true;
    final controller = _controller;
    controller.selection.removeListener(_relaySelection);
    controller
      ..removeListener(_bubbleChanges)
      ..dispose();
    super.dispose();
  }
}

extension _SelectionControllerBatch on tree.SelectionController {
  /// Replace the selection with [ids] without emitting intermediate changes.
  void selectOnlyMany(Iterable<String> ids) {
    performBatch(() {
      clear();
      addAll(ids);
    });
  }
}

class _CollectorFlattenStrategy extends tree.SortedFlattenStrategy {
  _CollectorFlattenStrategy(
    this._hiddenNodeProvider,
    tree.SortDelegate delegate,
  ) : super(delegate);

  final Set<String> Function() _hiddenNodeProvider;

  @override
  List<tree.VisibleNode> flatten({
    required tree.TreeData data,
    required Set<String> expandedIds,
    String? filterQuery,
  }) {
    final nodes = super.flatten(
      data: data,
      expandedIds: expandedIds,
      filterQuery: filterQuery,
    );
    final hidden = _hiddenNodeProvider();
    if (hidden.isEmpty) {
      return nodes;
    }
    return [
      for (final node in nodes)
        if (!hidden.contains(node.id)) node,
    ];
  }
}

class CollectorSortDelegate extends tree.SortDelegate {
  const CollectorSortDelegate([this._alpha = const tree.AlphaSortDelegate()]);

  final tree.SortDelegate _alpha;

  @override
  List<String> sortChildIds(tree.TreeData data, String parentId) {
    final ordered = _alpha.sortChildIds(data, parentId);
    if (parentId == tree.TreeBuilder.treeRootId) {
      // Float Header to top
      final headerIdx = ordered.indexWhere((id) {
        final node = data.nodes[id];
        return node != null && node.isVirtual && node.name == 'Header';
      });
      if (headerIdx > 0) {
        final id = ordered.removeAt(headerIdx);
        ordered.insert(0, id);
      }

      // Float Footer to top (under header) or bottom?
      // Since they are hidden, this only matters if hiding fails.
      // Let's keep them stable.
    }
    return ordered;
  }
}
