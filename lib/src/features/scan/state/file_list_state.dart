import 'dart:io';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as path;

import '../../virtual_tree/api/virtual_tree_api.dart';
import '../models/scan_result.dart';
import '../models/scanned_file.dart';
import '../services/drop_handler.dart';
import '../services/file_scanner.dart';
import '../ui/duplicate_handling_dialog.dart';
import '../ui/file_conflict_dialog.dart';

/// Selection state - enhanced with file map and scan history
@immutable
class SelectionState {
  const SelectionState({
    this.allFiles = const [],
    this.fileMap = const {},
    this.selectedFileIds = const {},
    this.scanHistory = const [],
    this.isProcessing = false,
    this.error,
    this.combinedContent = '',
    this.virtualTreeJson,
  });

  final List<ScannedFile> allFiles; // Keep for backward compatibility
  final Map<String, ScannedFile> fileMap; // Quick lookup by ID
  final Set<String> selectedFileIds; // Now using IDs instead of paths
  final List<ScanMetadata> scanHistory;
  final bool isProcessing;
  final String? error;
  final String combinedContent;
  final String? virtualTreeJson;

  // Backward compatible getters
  Set<String> get selectedFilePaths => selectedFiles.map((f) => f.fullPath).toSet();
  
  // New getters using IDs
  List<ScannedFile> get selectedFiles => 
      selectedFileIds.map((id) => fileMap[id]).whereType<ScannedFile>().toList();
  int get selectedFilesCount => selectedFiles.length;
  int get totalFilesCount => fileMap.length;
  bool get hasFiles => fileMap.isNotEmpty;
  bool get hasSelectedFiles => selectedFileIds.isNotEmpty;
  
  // Helper methods
  ScannedFile? getFileById(String id) => fileMap[id];
  List<ScannedFile> getFilesByIds(List<String> ids) => 
      ids.map((id) => fileMap[id]).whereType<ScannedFile>().toList();

  SelectionState copyWith({
    List<ScannedFile>? allFiles,
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
      allFiles: allFiles ?? this.allFiles,
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
final selectionProvider = StateNotifierProvider<FileListNotifier, SelectionState>((ref) {
  final fileScanner = FileScanner();
  return FileListNotifier(
    fileScanner: fileScanner,
    dropHandler: DropHandler(fileScanner: fileScanner),
  );
});

/// Enhanced notifier with virtual tree integration
class FileListNotifier extends StateNotifier<SelectionState> {
  FileListNotifier({
    required this.fileScanner,
    required this.dropHandler,
  }) : super(const SelectionState());

  final FileScanner fileScanner;
  final DropHandler dropHandler;
  
  // Optional virtual tree integration
  VirtualTreeAPI? virtualTree;
  
  /// Initialize virtual tree and wire up callbacks
  void initializeVirtualTree(VirtualTreeAPI tree) {
    virtualTree = tree;
    
    // Wire up callbacks from tree to this notifier
    tree
      ..onNodeCreated(onVirtualFileCreated)
      ..onNodeEdited(onFileContentChanged)
      ..onNodeRemoved(onFileRemoved)
      ..onSelectionChanged(updateSelectionFromTree);
  }

  /// Process dropped items - main orchestrator method
  Future<void> processDroppedItems(List<XFile> items, {BuildContext? context}) async {
    state = state.copyWith(isProcessing: true, clearError: true);

    try {
      // Step 1: Scan the dropped items
      var scanResult = await dropHandler.processDroppedItems(items);

      // Step 2: Handle directory-level duplicates
      final duplicateResult = await _handleDirectoryDuplicates(scanResult, context);
      if (duplicateResult == null) return; // User cancelled
      scanResult = duplicateResult;

      // Step 3: Handle file-level conflicts
      final conflictResult = await _resolveFileConflicts(scanResult, context);
      if (conflictResult == null) return; // User cancelled
      scanResult = conflictResult;

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

  /// Detect and handle directory-level duplicates
  Future<ScanResult?> _handleDirectoryDuplicates(
    ScanResult scanResult,
    BuildContext? context,
  ) async {
    // Detect duplicate paths
    final duplicatePaths = _detectDuplicatePaths(scanResult.metadata.sourcePaths);
    final duplicatePathsList = duplicatePaths.toList();

    // No duplicates - default to merge smart
    if (duplicatePathsList.isEmpty) {
      return _applyDuplicateAction(scanResult, DuplicateAction.mergeSmart, []);
    }

    // Show dialog for duplicate handling
    if (context == null || !context.mounted) {
      return scanResult; // Can't show dialog without context
    }

    var action = await showDuplicateHandlingDialog(context, duplicatePathsList);
    if (action == null) {
      state = state.copyWith(isProcessing: false);
      return null; // User cancelled
    }

    // Check if merge would add any files
    if (action == DuplicateAction.mergeSmart) {
      final wouldAddFiles = _checkIfMergeWouldAddFiles(scanResult);
      if (!wouldAddFiles && context.mounted) {
        // Show dialog again since all files already exist
        action = await showDuplicateHandlingDialog(context, duplicatePathsList);
        if (action == null) {
          state = state.copyWith(isProcessing: false);
          return null;
        }
      }
    }

    return _applyDuplicateAction(scanResult, action, duplicatePathsList);
  }

  /// Detect duplicate paths in existing files
  Set<String> _detectDuplicatePaths(List<String> sourcePaths) {
    final duplicatePaths = <String>{};

    for (final sourcePath in sourcePaths) {
      for (final existingFile in state.fileMap.values) {
        if (existingFile.fullPath.startsWith(sourcePath)) {
          duplicatePaths.add(sourcePath);
          break;
        }
      }
    }

    return duplicatePaths;
  }

  /// Check if merge would add any new files
  bool _checkIfMergeWouldAddFiles(ScanResult scanResult) {
    final existingPaths = state.fileMap.values
        .map((f) => path.normalize(f.fullPath))
        .toSet();

    return scanResult.files.any(
      (file) => !existingPaths.contains(path.normalize(file.fullPath)),
    );
  }

  /// Apply duplicate action to scan result
  ScanResult _applyDuplicateAction(
    ScanResult scanResult,
    DuplicateAction action,
    List<String> duplicatePaths,
  ) {
    switch (action) {
      case DuplicateAction.replaceAll:
        return _applyReplaceAllAction(scanResult, duplicatePaths);

      case DuplicateAction.addAsDuplicate:
        return _applyAddAsDuplicateAction(scanResult);

      case DuplicateAction.mergeSmart:
        return _applyMergeSmartAction(scanResult);
    }
  }

  /// Apply "Replace All" duplicate action
  ScanResult _applyReplaceAllAction(
    ScanResult scanResult,
    List<String> duplicatePaths,
  ) {
    final newFileMap = Map<String, ScannedFile>.from(state.fileMap);
    final filesToRemove = <String>[];

    // Find all files to remove
    for (final file in state.fileMap.values) {
      for (final dupPath in duplicatePaths) {
        if (path.isWithin(dupPath, file.fullPath)) {
          filesToRemove.add(file.id);
          break;
        }
      }
    }

    // Remove files
    for (final id in filesToRemove) {
      newFileMap.remove(id);
    }

    state = state.copyWith(
      fileMap: newFileMap,
      selectedFileIds: state.selectedFileIds.difference(filesToRemove.toSet()),
    );

    // Clear tree to rebuild
    virtualTree?.clearTree();

    return scanResult;
  }

  /// Apply "Add as Duplicate" action
  ScanResult _applyAddAsDuplicateAction(ScanResult scanResult) {
    final updatedFiles = <ScannedFile>[];

    for (final sourcePath in scanResult.metadata.sourcePaths) {
      final newFolderName = _generateUniqueFolderName(sourcePath);

      // Update files to be under the new folder
      for (final file in scanResult.files) {
        if (_isFileFromSource(file, sourcePath)) {
          final relativeInSource = _getRelativePathInSource(file, sourcePath);
          final newRelativePath = path.join(newFolderName, relativeInSource);

          updatedFiles.add(file.copyWith(relativePath: newRelativePath));
        } else {
          updatedFiles.add(file);
        }
      }
    }

    return ScanResult(
      files: updatedFiles,
      metadata: scanResult.metadata,
    );
  }

  /// Apply "Merge Smart" action
  ScanResult _applyMergeSmartAction(ScanResult scanResult) {
    final existingPaths = state.fileMap.values
        .map((f) => path.normalize(f.fullPath))
        .toSet();

    final filesToAdd = <ScannedFile>[];

    for (final file in scanResult.files) {
      final normalizedPath = path.normalize(file.fullPath);
      if (!existingPaths.contains(normalizedPath)) {
        filesToAdd.add(file);
      }
    }

    return ScanResult(
      files: filesToAdd,
      metadata: scanResult.metadata,
    );
  }

  /// Generate unique folder name for duplicates
  String _generateUniqueFolderName(String sourcePath) {
    final baseName = path.basename(sourcePath);
    var copyNumber = 2;
    var newFolderName = '$baseName (copy)';

    final existingFolders = _getExistingTopLevelFolders();

    while (existingFolders.contains(newFolderName)) {
      newFolderName = '$baseName (copy $copyNumber)';
      copyNumber++;
    }

    return newFolderName;
  }

  /// Get existing top-level folder names
  Set<String> _getExistingTopLevelFolders() {
    final folders = <String>{};

    // From tree nodes
    if (virtualTree != null) {
      final treeData = virtualTree!.getCurrentTree();
      if (treeData != null) {
        final rootNode = treeData.nodes[treeData.rootId];
        if (rootNode != null) {
          for (final childId in rootNode.childIds) {
            final child = treeData.nodes[childId];
            if (child != null && child.type == NodeType.folder) {
              folders.add(child.name);
            }
          }
        }
      }
    }

    // From existing files
    for (final file in state.fileMap.values) {
      if (file.relativePath != null) {
        final topFolder = file.relativePath!.split(path.separator).first;
        if (topFolder.isNotEmpty) {
          folders.add(topFolder);
        }
      }
    }

    return folders;
  }

  /// Check if file is from a specific source
  bool _isFileFromSource(ScannedFile file, String sourcePath) {
    return path.isWithin(sourcePath, file.fullPath) ||
        (file.relativePath != null &&
            path.join(sourcePath, file.relativePath!) == file.fullPath);
  }

  /// Get relative path within source
  String _getRelativePathInSource(ScannedFile file, String sourcePath) {
    if (file.relativePath != null && file.relativePath!.isNotEmpty) {
      return file.relativePath!;
    }
    return path.relative(file.fullPath, from: sourcePath);
  }

  /// Resolve file-level conflicts
  Future<ScanResult?> _resolveFileConflicts(
    ScanResult scanResult,
    BuildContext? context,
  ) async {
    // Don't check conflicts if we already replaced all
    if (scanResult.files.isEmpty) return scanResult;

    final conflicts = _findFileConflicts(scanResult.files);
    if (conflicts.isEmpty) return scanResult;

    if (context == null || !context.mounted) return scanResult;

    final conflictResult = await _handleFileConflicts(
      context,
      conflicts,
      scanResult.files,
    );

    if (conflictResult == null) {
      state = state.copyWith(isProcessing: false);
      return null; // User cancelled
    }

    return ScanResult(
      files: conflictResult,
      metadata: scanResult.metadata,
    );
  }

  /// Find files that conflict with existing ones
  List<ScannedFile> _findFileConflicts(List<ScannedFile> files) {
    final existingPaths = state.fileMap.values
        .map((f) => path.normalize(f.fullPath))
        .toSet();

    return files
        .where((file) => existingPaths.contains(path.normalize(file.fullPath)))
        .toList();
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
        allFiles: newFileMap.values.toList(),
        selectedFileIds: updatedSelection,
        scanHistory: newScanHistory,
        virtualTreeJson: treeData.toJson(),
      );
    } else {
      state = state.copyWith(
        fileMap: newFileMap,
        allFiles: newFileMap.values.toList(),
        selectedFileIds: updatedSelection,
        scanHistory: newScanHistory,
      );
    }

    // Load content for new files
    await _loadFileContents(scanResult.files);
  }

  /// Handle individual file conflicts
  Future<List<ScannedFile>?> _handleFileConflicts(
    BuildContext context, 
    List<ScannedFile> conflicts,
    List<ScannedFile> allIncomingFiles,
  ) async {
    final conflictFileNames = conflicts.map((f) => f.name).toList();
    final action = await showFileConflictDialog(context, conflictFileNames);

    if (action == null) {
      return null; // User cancelled
    }

    // Use the provided incoming files
    final conflictPaths = conflicts.map((c) => path.normalize(c.fullPath)).toSet();
    
    final existingPathMap = <String, ScannedFile>{};
    for (final file in state.fileMap.values) {
      existingPathMap[path.normalize(file.fullPath)] = file;
    }

    final resultFiles = <ScannedFile>[];

    switch (action) {
      case FileConflictAction.skip:
        // Return only non-conflicting files from incoming
        for (final file in allIncomingFiles) {
          final normalizedPath = path.normalize(file.fullPath);
          if (!conflictPaths.contains(normalizedPath)) {
            resultFiles.add(file);
          }
        }
        break;

      case FileConflictAction.replace:
        // Remove existing files that conflict from state
        final newFileMap = Map<String, ScannedFile>.from(state.fileMap);
        
        // Remove existing files that conflict
        newFileMap.removeWhere((id, file) => 
          conflictPaths.contains(path.normalize(file.fullPath))
        );
        
        state = state.copyWith(fileMap: newFileMap);
        
        // Return all incoming files (conflicts will replace existing)
        resultFiles.addAll(allIncomingFiles);
        break;

      case FileConflictAction.copy:
        // Add all files, renaming conflicts
        for (final file in allIncomingFiles) {
          final normalizedPath = path.normalize(file.fullPath);
          
          if (conflictPaths.contains(normalizedPath)) {
            // This is a conflict - rename it
            var newName = file.name;
            var newFullPath = file.fullPath;
            var counter = 2;
            
            // Find unique name
            while (existingPathMap.containsKey(path.normalize(newFullPath))) {
              final extension = path.extension(file.name);
              final baseName = path.basenameWithoutExtension(file.name);
              
              newName = '$baseName (copy${counter > 2 ? ' $counter' : ''})$extension';
              newFullPath = path.join(path.dirname(file.fullPath), newName);
              counter++;
            }
            
            resultFiles.add(file.copyWith(
              name: newName,
              fullPath: newFullPath,
              relativePath: file.relativePath != null 
                ? path.join(path.dirname(file.relativePath!), newName)
                : newName,
            ));
          } else {
            // Not a conflict - add as-is
            resultFiles.add(file);
          }
        }
        break;
    }

    return resultFiles;
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
    final content = await fileScanner.buildMarkdown(selectedFiles);
    
    // Single state update with everything
    state = state.copyWith(
      fileMap: newFileMap,
      allFiles: newFileMap.values.toList(),
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
    fileScanner.buildMarkdown(selectedFiles).then((content) {
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
    final newFileMap = Map<String, ScannedFile>.from(state.fileMap);
    newFileMap.remove(file.id);
    
    final updatedSelection = Set<String>.from(state.selectedFileIds);
    updatedSelection.remove(file.id);
    
    // Update state and rebuild content
    state = state.copyWith(
      fileMap: newFileMap,
      allFiles: newFileMap.values.toList(),
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
      final fileName = 'context_collection_${DateTime.now().millisecondsSinceEpoch}.txt';
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
    
    final content = await fileScanner.buildMarkdown(selectedFiles);
    
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
      allFiles: newFileMap.values.toList(),
    );
    
    _rebuildCombinedContent();
  }
  
  /// Called when a virtual file is created
  void onVirtualFileCreated(String parentPath, String fileName, String content) {
    final virtualFile = fileScanner.createVirtualFile(
      name: fileName,
      content: content,
      virtualPath: parentPath.isEmpty ? fileName : '$parentPath/$fileName',
    );
    
    final newFileMap = Map<String, ScannedFile>.from(state.fileMap);
    newFileMap[virtualFile.id] = virtualFile;
    
    // Auto-select the new file
    final newSelection = Set<String>.from(state.selectedFileIds);
    newSelection.add(virtualFile.id);
    
    state = state.copyWith(
      fileMap: newFileMap,
      allFiles: newFileMap.values.toList(),
      selectedFileIds: newSelection,
    );
    
    _rebuildCombinedContent();
  }
  
  /// Called when a file is removed from tree
  void onFileRemoved(String fileId) {
    final newFileMap = Map<String, ScannedFile>.from(state.fileMap);
    newFileMap.remove(fileId);
    
    final newSelection = Set<String>.from(state.selectedFileIds);
    newSelection.remove(fileId);
    
    state = state.copyWith(
      fileMap: newFileMap,
      allFiles: newFileMap.values.toList(),
      selectedFileIds: newSelection,
    );
    
    _rebuildCombinedContent();
  }
}
