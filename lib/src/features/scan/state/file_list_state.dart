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
import '../services/path_parser_service.dart';

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

/// Provider for path parser service
final pathParserServiceProvider = Provider<PathParserService>(
  (ref) => PathParserService(),
);

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

/// Enhanced notifier with virtual tree integration.
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

  VirtualTreeAPI? virtualTree;

  void initializeVirtualTree(VirtualTreeAPI tree) {
    virtualTree = tree;
    tree
      ..onNodeCreated(onVirtualFileCreated)
      ..onNodeEdited(onFileContentChanged)
      ..onSelectionChanged(updateSelectionFromTree);
  }

  //============================================================================
  // MAIN PROCESSING METHOD
  //============================================================================

  /// The single master method for processing all new files/directories.
  Future<void> _processNewItems(
    List<XFile> items, {
    required ScanSource source,
  }) async {
    state = state.copyWith(isProcessing: true, clearError: true);

    try {
      final filterSettings = ref.read(preferencesProvider).settings;
      final blacklist = filterSettings.blacklistedExtensions;
      final sourcePaths = <String>{};

      await dropHandler.processDroppedItemsIncremental(
        items,
        blacklist: blacklist,
        source: source,
        onFileFound: (file) {
          _addFileToState(file);
          // Fire-and-forget content load
          _loadFileContent(file);
        },
        onScanComplete: (paths) {
          sourcePaths.addAll(paths);
          final scanMetadata = ScanMetadata(
            sourcePaths: sourcePaths.toList(),
            timestamp: DateTime.now(),
            source: source,
          );
          state = state.copyWith(
            scanHistory: [...state.scanHistory, scanMetadata],
          );
          // Final rebuild to ensure everything is in sync
          _rebuildTreeFromState();
          _rebuildCombinedContent();
        },
      );
    } catch (e) {
      state = state.copyWith(error: 'Failed to process new items: $e');
    } finally {
      state = state.copyWith(isProcessing: false);
    }
  }

  /// Add a single file to the state and update UI immediately
  void _addFileToState(ScannedFile file) {
    final newFileMap = Map<String, ScannedFile>.from(state.fileMap);
    newFileMap[file.id] = file;

    final updatedSelection = Set<String>.from(state.selectedFileIds)
      ..add(file.id);

    state = state.copyWith(
      fileMap: newFileMap,
      selectedFileIds: updatedSelection,
    );

    // INSTANT UI UPDATE - No debouncing!
    _rebuildTreeFromState();
  }

  /// Loads content for a single file and updates the state.
  Future<void> _loadFileContent(ScannedFile file) async {
    final loadedFile = await fileScanner.loadFileContent(file);
    if (mounted && state.fileMap.containsKey(loadedFile.id)) {
      final newFileMap = Map<String, ScannedFile>.from(state.fileMap);
      newFileMap[loadedFile.id] = loadedFile;
      state = state.copyWith(fileMap: newFileMap);
      // Update combined content when file content is loaded
      _rebuildCombinedContent();
    }
  }

  //============================================================================
  // PUBLIC API
  //============================================================================

  Future<void> pickFiles(BuildContext context) async {
    final files = await openFiles();
    if (files.isNotEmpty) {
      await _processNewItems(files, source: ScanSource.browse);
    }
  }

  Future<void> pickDirectory(BuildContext context) async {
    final directoryPath = await getDirectoryPath();
    if (directoryPath != null) {
      await _processNewItems(
        [XFile(directoryPath)],
        source: ScanSource.browse,
      );
    }
  }

  Future<void> processDroppedItems(List<XFile> items) async {
    await _processNewItems(items, source: ScanSource.drop);
  }

  Future<void> processPastedPaths(
    String pastedText,
    BuildContext context,
  ) async {
    state = state.copyWith(isProcessing: true, clearError: true);
    try {
      final pathParser = ref.read(pathParserServiceProvider);
      final parseResult = await pathParser.parse(pastedText);

      final filesToProcess = <XFile>[];
      final errorPaths = <String>[];
      final existingPaths = <String>[];

      await Future.wait(
        parseResult.validPaths.map((path) async {
          if (state.fileMap.values.any((f) => f.fullPath == path)) {
            existingPaths.add(path);
            return;
          }
          try {
            final type = FileSystemEntity.typeSync(path);
            if (type != FileSystemEntityType.notFound) {
              filesToProcess.add(XFile(path));
            } else {
              errorPaths.add(path);
            }
          } catch (_) {
            errorPaths.add(path);
          }
        }),
      );

      // Process the validated items
      if (filesToProcess.isNotEmpty) {
        await _processNewItems(filesToProcess, source: ScanSource.paste);
      }

      // Build summary notification
      if (context.mounted) {
        final summary = <String>[];
        if (filesToProcess.isNotEmpty) {
          summary.add('${filesToProcess.length} new items added');
        }
        if (existingPaths.isNotEmpty) {
          summary.add('${existingPaths.length} already exist');
        }
        if (errorPaths.isNotEmpty) {
          summary.add('${errorPaths.length} not found');
        }

        if (summary.isNotEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(summary.join(' • ')),
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e) {
      state = state.copyWith(error: 'Failed to process pasted paths: $e');
    } finally {
      state = state.copyWith(isProcessing: false);
    }
  }

  //============================================================================
  // UI REBUILD HELPERS - INSTANT, NO DEBOUNCING
  //============================================================================

  void _rebuildCombinedContent() {
    final content = markdownBuilder.buildMarkdown(state.selectedFiles);
    if (mounted) {
      state = state.copyWith(combinedContent: content);
    }
  }

  void _rebuildTreeFromState() {
    if (virtualTree != null && mounted) {
      final treeData = virtualTree!.buildTree(
        files: state.fileMap.values.toList(),
        scanMetadata: state.scanHistory,
      );
      if (mounted) {
        state = state.copyWith(virtualTreeJson: treeData.toJson());
      }
    }
  }

  //============================================================================
  // STANDARD STATE MANAGEMENT METHODS
  //============================================================================

  /// Saves the combined content of all selected files to a new text file.
  Future<void> saveToFile() async {
    if (state.combinedContent.isEmpty) {
      state = state.copyWith(error: 'No content to save');
      return;
    }

    try {
      final fileName =
          'context_collection_${DateTime.now().millisecondsSinceEpoch}.md';
      final filePath = await getSaveLocation(suggestedName: fileName);
      if (filePath != null) {
        await File(filePath.path).writeAsString(state.combinedContent);
      }
    } catch (e) {
      state = state.copyWith(error: 'Error saving file: $e');
    }
  }

  /// Copies the combined content to the system clipboard.
  Future<void> copyToClipboard() async {
    if (state.combinedContent.isEmpty) {
      state = state.copyWith(error: 'No content to copy');
      return;
    }
    await Clipboard.setData(ClipboardData(text: state.combinedContent));
  }

  /// Clears the current error message from the state.
  void clearError() {
    state = state.copyWith(clearError: true);
  }

  void updateSelectionFromTree(Set<String> fileIds) {
    _updateSelectionAndContent(fileIds);
  }

  void toggleFileSelection(ScannedFile file) {
    final currentSelection = Set<String>.from(state.selectedFileIds);
    if (currentSelection.contains(file.id)) {
      currentSelection.remove(file.id);
    } else {
      currentSelection.add(file.id);
    }
    _updateSelectionAndContent(currentSelection);
  }

  void selectAll() {
    _updateSelectionAndContent(state.fileMap.keys.toSet());
  }

  void deselectAll() {
    _updateSelectionAndContent({});
  }

  void _updateSelectionAndContent(Set<String> newSelection) {
    if (!mounted) return;
    state = state.copyWith(selectedFileIds: newSelection);
    // Instant update - no debouncing
    _rebuildCombinedContent();
    virtualTree?.setSelectedFileIds(newSelection);
  }

  void removeFile(ScannedFile file) {
    final newFileMap = Map<String, ScannedFile>.from(state.fileMap)
      ..remove(file.id);
    final newSelectedIds = Set<String>.from(state.selectedFileIds)
      ..remove(file.id);
    state = state.copyWith(
      fileMap: newFileMap,
      selectedFileIds: newSelectedIds,
    );
    _rebuildTreeFromState();
    _rebuildCombinedContent();
  }

  void clearFiles() {
    virtualTree?.clearTree();
    state = const SelectionState();
  }

  void onFileContentChanged(String fileId, String newContent) {
    final file = state.fileMap[fileId];
    if (file == null) return;
    final newFileMap = Map<String, ScannedFile>.from(state.fileMap);
    newFileMap[fileId] = file.copyWith(editedContent: newContent);
    state = state.copyWith(fileMap: newFileMap);
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
  void removeNodes(Set<String> topLevelNodeIds) {
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
    _rebuildTreeFromState();
    _rebuildCombinedContent();
  }

  /// Removes a set of source paths from the scan history and returns the
  /// clean history. This is critical for preventing incorrect duplicate detection.
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
