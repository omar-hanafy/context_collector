import '../../scan/models/scan_result.dart';
import '../../scan/models/scanned_file.dart';
import '../api/virtual_tree_api.dart';
import '../state/tree_state.dart';

/// Implementation of VirtualTreeAPI for scanner integration
class VirtualTreeImpl implements VirtualTreeAPI {
  VirtualTreeImpl(this._notifier);
  final TreeStateNotifier _notifier;

  @override
  TreeData buildTree({
    required List<ScannedFile> files,
    required List<ScanMetadata> scanMetadata,
  }) {
    _notifier.buildFromFiles(files, scanMetadata);

    return _notifier.getCurrentTreeData();
  }

  @override
  TreeData? getCurrentTree() {
    if (!_notifier.hasTreeNodes()) return null;

    return _notifier.getCurrentTreeData();
  }

  @override
  Set<String> getSelectedFileIds() => _notifier.getSelectedFileIds();

  @override
  void setSelectedFileIds(Set<String> ids) {
    _notifier.updateSelectionFromFileIds(ids);
  }

  @override
  Future<String> buildCombinedContent(Set<String> selectedIds) async {
    // This is handled by scanner's buildMarkdown
    // Virtual tree just provides the selection
    return '';
  }

  @override
  void onNodeEdited(void Function(String, String) callback) {
    _notifier.onNodeEditedCallback = callback;
  }

  @override
  void onSelectionChanged(void Function(Set<String>) callback) {
    _notifier.onSelectionChangedCallback = callback;
  }

  /// Get existing file IDs in the tree
  Set<String> getExistingFileIds() {
    final treeData = _notifier.getCurrentTreeData();
    final fileIds = <String>{};
    for (final node in treeData.nodes.values) {
      if (node.fileId != null) {
        fileIds.add(node.fileId!);
      }
    }
    return fileIds;
  }

  @override
  void clearTree() {
    _notifier.clearTree();
  }

  @override
  String? getNodeVirtualPath(String nodeId) {
    final treeData = _notifier.getCurrentTreeData();
    return treeData.nodes[nodeId]?.virtualPath;
  }


  /// Force content rebuild (useful for debugging)
  void forceContentRebuild() {
    final fileIds = _notifier.getSelectedFileIds();
    _notifier.onSelectionChangedCallback?.call(fileIds);
  }

  /// Debug: Check if callbacks are set
  bool hasCallbacks() {
    return _notifier.onSelectionChangedCallback != null;
  }
}
