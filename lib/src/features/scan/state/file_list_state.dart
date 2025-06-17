import 'dart:io';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../settings/presentation/state/preferences_notifier.dart';
import '../../virtual_tree/api/virtual_tree_api.dart';
import '../models/scan_result.dart';
import '../models/scanned_file.dart';
import '../services/drop_handler.dart';
import '../services/file_scanner.dart';
import '../services/markdown_builder.dart';

/// Selection state - enhanced with file map and scan history
@immutable
class SelectionState {
  const SelectionState({
    this.fileMap = const {},
    this.selectedFileIds = const {},
    this.scanHistory = const [],
    this.isProcessing = false,
    this.error,
    this.combinedContent = '',
    this.virtualTreeJson,
  });

  final Map<String, ScannedFile>
  fileMap; // Quick lookup by ID - single source of truth
  final Set<String> selectedFileIds; // Now using IDs instead of paths
  final List<ScanMetadata> scanHistory;
  final bool isProcessing;
  final String? error;
  final String combinedContent;
  final String? virtualTreeJson;

  // Backward compatible getters
  Set<String> get selectedFilePaths =>
      selectedFiles.map((f) => f.fullPath).toSet();

  // New getters using IDs
  List<ScannedFile> get selectedFiles => selectedFileIds
      .map((id) => fileMap[id])
      .whereType<ScannedFile>()
      .toList();

  int get selectedFilesCount => selectedFiles.length;

  int get totalFilesCount => fileMap.length;

  bool get hasFiles => fileMap.isNotEmpty;

  bool get hasSelectedFiles => selectedFileIds.isNotEmpty;

  // Helper methods
  ScannedFile? getFileById(String id) => fileMap[id];

  List<ScannedFile> getFilesByIds(List<String> ids) =>
      ids.map((id) => fileMap[id]).whereType<ScannedFile>().toList();

  SelectionState copyWith({
    Map<String, ScannedFile>? fileMap,
    Set<String>? selectedFileIds,
    List<ScanMetadata>? scanHistory,
    bool? isProcessing,
    String? error,
    bool clearError = false,
    String? combinedContent,
    String? virtualTreeJson,
  }) {
    return SelectionState(
      fileMap: fileMap ?? this.fileMap,
      selectedFileIds: selectedFileIds ?? this.selectedFileIds,
      scanHistory: scanHistory ?? this.scanHistory,
      isProcessing: isProcessing ?? this.isProcessing,
      error: clearError ? null : error ?? this.error,
      combinedContent: combinedContent ?? this.combinedContent,
      virtualTreeJson: virtualTreeJson ?? this.virtualTreeJson,
    );
  }
}

/// Provider - same API
final selectionProvider =
    StateNotifierProvider<FileListNotifier, SelectionState>((ref) {
      final fileScanner = FileScanner();
      final markdownBuilder = MarkdownBuilder();
      return FileListNotifier(
        ref: ref,
        fileScanner: fileScanner,
        dropHandler: DropHandler(fileScanner: fileScanner),
        markdownBuilder: markdownBuilder,
      );
    });

/// Enhanced notifier with virtual tree integration
class FileListNotifier extends StateNotifier<SelectionState> {
  FileListNotifier({
    required this.ref,
    required this.fileScanner,
    required this.dropHandler,
    required this.markdownBuilder,
  }) : super(const SelectionState());

  final Ref ref;
  final FileScanner fileScanner;
  final DropHandler dropHandler;
  final MarkdownBuilder markdownBuilder;

  // Optional virtual tree integration
  VirtualTreeAPI? virtualTree;

  /// Initialize virtual tree and wire up callbacks
  void initializeVirtualTree(VirtualTreeAPI tree) {
    virtualTree = tree;

    // Wire up callbacks from tree to this notifier
    tree
      ..onNodeCreated(onVirtualFileCreated)
      ..onNodeEdited(onFileContentChanged)
      ..onSelectionChanged(updateSelectionFromTree);
  }

  /// Process dropped items - main orchestrator method
  Future<void> processDroppedItems(
    List<XFile> items, {
    BuildContext? context,
  }) async {
    state = state.copyWith(isProcessing: true, clearError: true);

    try {
      // Read the blacklist from settings
      final filterSettings = ref.read(preferencesProvider).settings;
      final blacklist = filterSettings.blacklistedExtensions;

      // Step 1: Scan the dropped items
      final scanResult = await dropHandler.processDroppedItems(
        items,
        blacklist: blacklist,
      );

      if (scanResult.files.isEmpty) {
        state = state.copyWith(
          isProcessing: false,
          error: 'No new files to add',
        );
        return;
      }

      // Step 4: Apply changes to state
      await _applyScanResultToState(scanResult);
    } catch (e) {
      state = state.copyWith(error: 'Failed to process files: $e');
    } finally {
      state = state.copyWith(isProcessing: false);
    }
  }

  /// Apply scan result to state
  Future<void> _applyScanResultToState(ScanResult scanResult) async {
    // Build new file map
    final newFileMap = Map<String, ScannedFile>.from(state.fileMap);
    for (final file in scanResult.files) {
      newFileMap[file.id] = file;
    }

    // Update scan history
    final newScanHistory = [...state.scanHistory, scanResult.metadata];

    // Auto-select new files
    final updatedSelection = {
      ...state.selectedFileIds,
      ...scanResult.files.map((f) => f.id),
    };

    // Build virtual tree if available
    if (virtualTree != null) {
      final treeData = await virtualTree!.buildTree(
        files: newFileMap.values.toList(),
        scanMetadata: newScanHistory,
      );

      state = state.copyWith(
        fileMap: newFileMap,
        selectedFileIds: updatedSelection,
        scanHistory: newScanHistory,
        virtualTreeJson: treeData.toJson(),
      );
    } else {
      state = state.copyWith(
        fileMap: newFileMap,
        selectedFileIds: updatedSelection,
        scanHistory: newScanHistory,
      );
    }

    // Load content for new files
    await _loadFileContents(scanResult.files);
  }

  /// Load file contents - updated to use file map
  Future<void> _loadFileContents(List<ScannedFile> files) async {
    // Load all files first without updating state
    final loadedFiles = <ScannedFile>[];
    for (final file in files) {
      final loadedFile = await fileScanner.loadFileContent(file);
      loadedFiles.add(loadedFile);
    }

    // Update file map with loaded content
    final newFileMap = Map<String, ScannedFile>.from(state.fileMap);
    for (final loadedFile in loadedFiles) {
      newFileMap[loadedFile.id] = loadedFile;
    }

    // Build combined content before updating state
    final selectedFiles = state.selectedFileIds
        .map((id) => newFileMap[id])
        .whereType<ScannedFile>()
        .toList();
    final content = await markdownBuilder.buildMarkdown(selectedFiles);

    // Single state update with everything
    state = state.copyWith(
      fileMap: newFileMap,
      combinedContent: content,
    );
  }

  /// Update selection from tree - called when tree selection changes
  void updateSelectionFromTree(Set<String> fileIds) {
    // Update selection and rebuild content
    _updateSelectionAndContent(fileIds);
  }

  /// Toggle file selection - updated to use IDs
  void toggleFileSelection(ScannedFile file) {
    final currentSelection = Set<String>.from(state.selectedFileIds);
    if (currentSelection.contains(file.id)) {
      currentSelection.remove(file.id);
    } else {
      currentSelection.add(file.id);
    }

    _updateSelectionAndContent(currentSelection);
  }

  /// Update selection and rebuild content
  void _updateSelectionAndContent(Set<String> newSelection) {
    // Build content from selected files
    final selectedFiles = newSelection
        .map((id) => state.fileMap[id])
        .whereType<ScannedFile>()
        .toList();

    // Update state and build content
    markdownBuilder.buildMarkdown(selectedFiles).then((content) {
      if (mounted) {
        state = state.copyWith(
          selectedFileIds: newSelection,
          combinedContent: content,
        );

        // Notify virtual tree of selection change
        virtualTree?.setSelectedFileIds(newSelection);
      }
    });
  }

  /// Select all files
  void selectAll() {
    final allIds = state.fileMap.keys.toSet();
    _updateSelectionAndContent(allIds);
  }

  /// Deselect all files
  void deselectAll() {
    _updateSelectionAndContent({});
  }

  /// Remove a file
  void removeFile(ScannedFile file) {
    final newFileMap = Map<String, ScannedFile>.from(state.fileMap)
      ..remove(file.id);

    final updatedSelection = Set<String>.from(state.selectedFileIds)
      ..remove(file.id);

    // Update state and rebuild content
    state = state.copyWith(
      fileMap: newFileMap,
      selectedFileIds: updatedSelection,
    );

    // Rebuild content
    _rebuildCombinedContent();
  }

  /// Clear all files
  void clearFiles() {
    // Clear virtual tree first
    virtualTree?.clearTree();

    // Reset state
    state = const SelectionState();
  }

  /// Copy to clipboard
  Future<void> copyToClipboard() async {
    if (state.combinedContent.isEmpty) {
      state = state.copyWith(error: 'No content to copy');
      return;
    }
    await Clipboard.setData(ClipboardData(text: state.combinedContent));
  }

  /// Save to file
  Future<void> saveToFile() async {
    if (state.combinedContent.isEmpty) {
      state = state.copyWith(error: 'No content to save');
      return;
    }

    try {
      final fileName =
          'context_collection_${DateTime.now().millisecondsSinceEpoch}.txt';
      final filePath = await getSaveLocation(suggestedName: fileName);
      if (filePath != null) {
        await File(filePath.path).writeAsString(state.combinedContent);
      }
    } catch (e) {
      state = state.copyWith(error: 'Error saving file: $e');
    }
  }

  /// Pick files manually
  Future<void> pickFiles(BuildContext context) async {
    state = state.copyWith(isProcessing: true, clearError: true);
    try {
      final files = await openFiles();
      if (files.isNotEmpty) {
        await processDroppedItems(files, context: context);
      }
    } catch (e) {
      state = state.copyWith(error: 'Error picking files: $e');
    } finally {
      state = state.copyWith(isProcessing: false);
    }
  }

  /// Pick directory
  Future<void> pickDirectory(BuildContext context) async {
    state = state.copyWith(isProcessing: true, clearError: true);
    try {
      final directoryPath = await getDirectoryPath();
      if (directoryPath != null) {
        // Process as a dropped directory
        await processDroppedItems([XFile(directoryPath)], context: context);
      }
    } catch (e) {
      state = state.copyWith(error: 'Error picking directory: $e');
    } finally {
      state = state.copyWith(isProcessing: false);
    }
  }

  /// Clear error
  void clearError() {
    state = state.copyWith(clearError: true);
  }

  /// Rebuild combined content from current selection
  Future<void> _rebuildCombinedContent() async {
    final selectedFiles = state.selectedFileIds
        .map((id) => state.fileMap[id])
        .whereType<ScannedFile>()
        .toList();

    final content = await markdownBuilder.buildMarkdown(selectedFiles);

    if (mounted) {
      state = state.copyWith(combinedContent: content);
    }
  }

  // Virtual tree callback methods

  /// Called when file content is edited
  void onFileContentChanged(String fileId, String newContent) {
    final file = state.fileMap[fileId];
    if (file == null) return;

    final updatedFile = file.copyWith(editedContent: newContent);
    final newFileMap = Map<String, ScannedFile>.from(state.fileMap);
    newFileMap[fileId] = updatedFile;

    state = state.copyWith(
      fileMap: newFileMap,
    );

    _rebuildCombinedContent();
  }

  /// Called when a virtual file is created
  void onVirtualFileCreated(
    String parentNodeId,
    String fileName,
    String content,
  ) {
    // Get the parent node's virtual path from the tree
    final parentVirtualPath =
        virtualTree?.getNodeVirtualPath(parentNodeId) ?? '';

    // Build the correct virtual path for the new file
    final virtualPath = parentVirtualPath.isEmpty
        ? fileName
        : '$parentVirtualPath/$fileName';

    // Create the ScannedFile data object with the correct path
    final virtualFile = fileScanner.createVirtualFile(
      name: fileName,
      content: content,
      virtualPath: virtualPath,
    );

    // Add the new file to our central file map
    final newFileMap = Map<String, ScannedFile>.from(state.fileMap);
    newFileMap[virtualFile.id] = virtualFile;

    // Update the state with the new file
    state = state.copyWith(
      fileMap: newFileMap,
    );

    // NOW, command the virtual tree to add the UI node for this new file
    virtualTree?.addVirtualFileNode(
      parentNodeId: parentNodeId,
      file: virtualFile,
    );

    // No need to call _rebuildCombinedContent here, because the tree notifier
    // will call back with the updated selection, which triggers the rebuild.
  }

  /// Called when a virtual folder is created
  void onVirtualFolderCreated(
    String parentNodeId,
    String folderName,
  ) {
    if (virtualTree == null) return;

    // For virtual folders, we delegate directly to the tree state
    // since folders don't have associated file data
    virtualTree!.createVirtualFolder(
      parentNodeId: parentNodeId,
      folderName: folderName,
    );
  }

  /// Removes a set of nodes and all their descendants from the state.
  /// This is the ONLY way to remove items to ensure proper cleanup.
  ///
  /// CRITICAL: This method performs three essential operations:
  /// 1. Removes files from the master file map
  /// 2. Updates the selection state
  /// 3. CLEANS the scanHistory to prevent false duplicate detection
  ///
  /// The scanHistory cleanup (step 3) is CRITICAL. Without it, removing files
  /// and then re-adding the same directory will incorrectly trigger the duplicate
  /// detection dialog, even though the files are no longer in the tree.
  ///
  /// Implementation note: This method delegates the actual tree removal to a full
  /// rebuild from the cleaned state, ensuring the tree always reflects the truth.
  Future<void> removeNodes(Set<String> topLevelNodeIds) async {
    if (virtualTree == null) return;

    final allNodes = virtualTree!.getCurrentTree()?.nodes ?? {};
    if (allNodes.isEmpty) return;

    // --- Step 1: Collect all file IDs and source paths to be removed ---
    final fileIdsToRemove = <String>{};
    final nodesToRemove = <String>{};
    final sourcePathsToRemove = <String>{};

    void collectDescendants(String nodeId) {
      if (nodesToRemove.contains(nodeId)) return;
      nodesToRemove.add(nodeId);
      final node = allNodes[nodeId];
      if (node == null) return;
      if (node.fileId != null) {
        fileIdsToRemove.add(node.fileId!);
      }
      // If a folder node has an original source path, it's a candidate for history cleanup
      if (node.type == NodeType.folder && node.sourcePath != null) {
        sourcePathsToRemove.add(node.sourcePath!);
      }
      for (final childId in node.childIds) {
        collectDescendants(childId);
      }
    }

    for (final nodeId in topLevelNodeIds) {
      collectDescendants(nodeId);
    }

    // Nothing to do
    if (fileIdsToRemove.isEmpty && nodesToRemove.isEmpty) return;

    // --- Step 2: Remove files from the master file map ---
    final newFileMap = Map<String, ScannedFile>.from(state.fileMap)
      ..removeWhere((fileId, _) => fileIdsToRemove.contains(fileId));

    final newSelectedFileIds = Set<String>.from(state.selectedFileIds)
      ..removeAll(fileIdsToRemove);

    // --- Step 3: Clean the scanHistory (THE CRITICAL BUG FIX) ---
    final newScanHistory = _removePathsFromScanHistory(sourcePathsToRemove);

    // --- Step 4: Update state and trigger a full tree rebuild ---
    state = state.copyWith(
      fileMap: newFileMap,
      selectedFileIds: newSelectedFileIds,
      scanHistory: newScanHistory,
    );

    // This rebuilds the tree from the now-clean master state
    await _rebuildTreeFromState();
    await _rebuildCombinedContent();
  }

  /// Helper to rebuild the virtual tree from the current state
  Future<void> _rebuildTreeFromState() async {
    if (virtualTree != null) {
      final treeData = await virtualTree!.buildTree(
        files: state.fileMap.values.toList(),
        scanMetadata: state.scanHistory,
      );
      state = state.copyWith(virtualTreeJson: treeData.toJson());
    }
  }

  /// Removes a set of source paths from the scan history and returns the
  /// clean history. This is critical for preventing incorrect duplicate detection.
  ///
  /// Why this is needed:
  /// The scan history tracks all directories that have been scanned. When files
  /// are removed from the tree, their source paths must also be removed from
  /// the history. Otherwise, re-adding the same directory will be incorrectly
  /// identified as a duplicate, even though those files are no longer present.
  ///
  /// Example bug this prevents:
  /// 1. User adds /project/src/ (path recorded in scan history)
  /// 2. User removes all files from /project/src/
  /// 3. User adds /project/src/ again
  /// 4. WITHOUT this cleanup: "Duplicate detected" dialog appears (incorrect)
  /// 5. WITH this cleanup: Files are added normally (correct)
  List<ScanMetadata> _removePathsFromScanHistory(
    Iterable<String> pathsToRemove,
  ) {
    final pathsToRemoveSet = pathsToRemove.toSet();
    final newScanHistory = <ScanMetadata>[];

    for (final scanMetadata in state.scanHistory) {
      // Get the source paths from this metadata entry that are NOT being removed.
      final remainingSourcePaths = scanMetadata.sourcePaths
          .where((p) => !pathsToRemoveSet.contains(p))
          .toList();

      // If there are any paths left, create a new metadata object for them.
      if (remainingSourcePaths.isNotEmpty) {
        newScanHistory.add(
          ScanMetadata(
            sourcePaths: remainingSourcePaths,
            timestamp: scanMetadata.timestamp,
            source: scanMetadata.source,
          ),
        );
      }
    }
    return newScanHistory;
  }
}
