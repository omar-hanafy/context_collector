import '../../scan/models/scanned_file.dart';
import '../../scan/models/scan_result.dart';
import '../api/virtual_tree_api.dart';
import '../state/tree_state.dart';

/// Implementation of VirtualTreeAPI for scanner integration
class VirtualTreeImpl implements VirtualTreeAPI {
  final TreeStateNotifier _notifier;

  VirtualTreeImpl(this._notifier);

  @override
  Future<TreeData> buildTree({
    required List<ScannedFile> files,
    required List<ScanMetadata> scanMetadata,
  }) async {
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
  void onNodeCreated(void Function(String, String, String) callback) {
    _notifier.onNodeCreatedCallback = callback;
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
    final fileIds = <String>{};
    for (final node in _notifier.state.nodes.values) {
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
  void addVirtualFileNode({
    required String parentNodeId,
    required ScannedFile file,
  }) {
    _notifier.addVirtualFileNode(parentNodeId: parentNodeId, file: file);
  }

  @override
  String? getNodeVirtualPath(String nodeId) {
    return _notifier.state.nodes[nodeId]?.virtualPath;
  }

  @override
  void createVirtualFolder({
    required String parentNodeId,
    required String folderName,
  }) {
    _notifier.createNode(
      parentId: parentNodeId,
      name: folderName,
      isFolder: true,
    );
  }

  /// Force content rebuild (useful for debugging)
  void forceContentRebuild() {
    final fileIds = _notifier.state.selectedFileIds;
    _notifier.onSelectionChangedCallback?.call(fileIds);
  }

  /// Debug: Check if callbacks are set
  bool hasCallbacks() {
    return _notifier.onSelectionChangedCallback != null;
  }
}
