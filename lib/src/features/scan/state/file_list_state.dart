// import 'dart:io'; // Unused

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_directory_tree/flutter_directory_tree.dart' as tree;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as path;

import '../../settings/presentation/state/preferences_notifier.dart';
import '../../virtual_tree/directory_tree_adapter.dart';
import '../models/scan_result.dart';
import '../models/scanned_file.dart';
import '../services/markdown_builder.dart';
import '../services/path_parser_service.dart';
import '../services/unified_file_service.dart';

/// Selection state - enhanced with file map and scan history
@immutable
class SelectionState {
  const SelectionState({
    this.fileMap = const {},
    this.selectedFileIds = const {},
    this.scanHistory = const [],
    this.isProcessing = false,
    this.sessionStarted = false, // New: Tracks if an editor session is active
    this.error,
    this.combinedContent = '',
    this.activeFileId,
    this.viewingAll = false,
    this.pendingRenameFileId,
  });

  final Map<String, ScannedFile>
  fileMap; // Quick lookup by ID - single source of truth
  final Set<String> selectedFileIds; // Now using IDs instead of paths
  final List<ScanMetadata> scanHistory;
  final bool isProcessing;
  final bool sessionStarted;
  final String? error;
  final String combinedContent;
  final String? activeFileId;

  // When true, Monaco shows ephemeral combined content and should not
  // be flushed back into any single file.
  final bool viewingAll;

  // When set (e.g., from Dock/global text drop), UI should prompt to rename
  // the indicated file id.
  final String? pendingRenameFileId;

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
    bool? sessionStarted,
    String? error,
    bool clearError = false,
    String? combinedContent,
    String? activeFileId,
    bool? viewingAll,
    String? pendingRenameFileId,
  }) {
    return SelectionState(
      fileMap: fileMap ?? this.fileMap,
      selectedFileIds: selectedFileIds ?? this.selectedFileIds,
      scanHistory: scanHistory ?? this.scanHistory,
      isProcessing: isProcessing ?? this.isProcessing,
      sessionStarted: sessionStarted ?? this.sessionStarted,
      error: clearError ? null : error ?? this.error,
      combinedContent: combinedContent ?? this.combinedContent,
      activeFileId: activeFileId ?? this.activeFileId,
      viewingAll: viewingAll ?? this.viewingAll,
      pendingRenameFileId: pendingRenameFileId ?? this.pendingRenameFileId,
    );
  }

  // Convenience
  ScannedFile? get activeFile =>
      activeFileId == null ? null : fileMap[activeFileId];
}

/// Provider for path parser service
final pathParserServiceProvider = Provider<PathParserService>(
  (ref) => PathParserService(),
);

/// Provider - same API
final selectionProvider =
    StateNotifierProvider<FileListNotifier, SelectionState>((ref) {
      final markdownBuilder = MarkdownBuilder();
      return FileListNotifier(
        ref: ref,
        markdownBuilder: markdownBuilder,
      );
    });

/// Enhanced notifier with virtual tree integration.
class FileListNotifier extends StateNotifier<SelectionState> {
  FileListNotifier({
    required this.ref,
    required this.markdownBuilder,
  }) : super(const SelectionState());

  final Ref ref;
  final MarkdownBuilder markdownBuilder;

  DirectoryTreeAdapter? treeAdapter;

  void initializeDirectoryTree(DirectoryTreeAdapter adapter) {
    treeAdapter?.selectionRelay = null;
    treeAdapter = adapter;
    treeAdapter!.selectionRelay = onTreeSelectionChanged;
    _rebuildTreeFromState();
  }

  //============================================================================
  // MAIN PROCESSING METHOD
  //============================================================================

  /// The single master method for processing all new files/directories.
  Future<void> _processNewItems(
    List<XFile> items, {
    required ScanSource source,
  }) async {
    state = state.copyWith(
      isProcessing: true,
      clearError: true,
      sessionStarted: true,
    );

    try {
      final filterSettings = ref.read(preferencesProvider).settings;
      final blacklist = filterSettings.blacklistedExtensions;
      final sourcePaths = <String>{};

      await UnifiedFileService.processDroppedItems(
        items: items,
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
          // Ensure a Prompt virtual file exists in any active session
          _ensurePromptFilePresent();
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
      sessionStarted: true, // Adding any file starts the session
      // If no active file yet, open this file immediately
      activeFileId: state.activeFileId ?? file.id,
    );

    // INSTANT UI UPDATE - No debouncing!
    _rebuildTreeFromState();
  }

  /// Loads content for a single file and updates the state.
  Future<void> _loadFileContent(ScannedFile file) async {
    final loadedFile = await UnifiedFileService.loadFileContent(file);
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

  /// Set active file for viewing/editing in Monaco.
  void setActiveFile(String fileId) {
    if (!state.fileMap.containsKey(fileId)) return;
    if (state.activeFileId == fileId) return;
    state = state.copyWith(activeFileId: fileId);
  }

  /// Persist the editor's current text into the given file
  /// (call before switching away or before copy/save).
  void saveEditorTextFor(String fileId, String text) {
    // Safety guard: never persist when showing combined "View All" content.
    if (state.viewingAll) return;
    final file = state.fileMap[fileId];
    if (file == null) return;
    if (text == file.effectiveContent) return; // No change
    final newFileMap = Map<String, ScannedFile>.from(state.fileMap);
    newFileMap[fileId] = file.copyWith(editedContent: text);
    state = state.copyWith(fileMap: newFileMap);
    _rebuildCombinedContent();
  }

  /// New: Refreshes the content of all non-virtual files from disk.
  Future<void> refreshAllContents() async {
    state = state.copyWith(isProcessing: true);
    final filesToRefresh = state.fileMap.values.where((f) => !f.isVirtual);
    final newFileMap = Map<String, ScannedFile>.from(state.fileMap);

    for (final file in filesToRefresh) {
      try {
        // Reload content from disk
        final reloadedFile = await UnifiedFileService.loadFileContent(file);
        // Overwrite the file in the map, discarding any edits
        newFileMap[reloadedFile.id] = reloadedFile.copyWith(
          editedContent: null,
        );
      } catch (_) {
        // Ignore errors for single file reloads
      }
    }

    state = state.copyWith(fileMap: newFileMap, isProcessing: false);
    // Trigger UI rebuilds
    _rebuildCombinedContent();
    _rebuildTreeFromState();
  }

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

      final existingPaths = state.fileMap.values.map((f) => f.fullPath).toSet();
      final validationResult = await UnifiedFileService.validatePaths(
        parseResult.validPaths,
        existingPaths,
      );

      // Process the validated items
      if (validationResult.hasValidFiles) {
        await _processNewItems(
          validationResult.validFiles,
          source: ScanSource.paste,
        );
      }

      // Build summary notification
      if (context.mounted && !validationResult.isEmpty) {
        final summary = UnifiedFileService.buildPasteSummary(validationResult);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(summary),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      state = state.copyWith(error: 'Failed to process pasted paths: $e');
    } finally {
      state = state.copyWith(isProcessing: false);
    }
  }

  /// Reads plain-text paths from the clipboard and processes them directly.
  Future<void> pastePathsFromClipboard(BuildContext context) async {
    try {
      final data = await Clipboard.getData(Clipboard.kTextPlain);
      final text = data?.text?.trim() ?? '';
      if (text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Clipboard is empty.')),
        );
        return;
      }
      await processPastedPaths(text, context);
    } catch (e) {
      state = state.copyWith(error: 'Failed to read clipboard: $e');
    }
  }

  void setViewingAll(bool v) {
    state = state.copyWith(viewingAll: v);
  }

  void exitCombinedPreview() => setViewingAll(false);

  void clearPendingRename() {
    state = state.copyWith(pendingRenameFileId: null);
  }

  void renameFile(String fileId, String newName) {
    final file = state.fileMap[fileId];
    if (file == null) return;
    final updated = file.copyWith(
      name: newName,
      fullPath: '/$newName',
      relativePath: newName,
      extension: path.extension(newName).toLowerCase(),
    );
    final newMap = Map<String, ScannedFile>.from(state.fileMap)
      ..[fileId] = updated;
    state = state.copyWith(fileMap: newMap, pendingRenameFileId: null);
    _rebuildTreeFromState();
  }

  /// Creates a virtual file with an auto-generated unique name under the tree root.
  void createVirtualFileWithAutoName(
    String content, {
    String base = 'pasted',
    String ext = '.txt',
    bool promptForName = false,
  }) {
    // Collect existing file names to avoid collisions for the auto name.
    final names = state.fileMap.values.map((f) => f.name).toSet();

    String candidate = '$base$ext';
    int i = 2;
    while (names.contains(candidate)) {
      candidate = '$base-$i$ext';
      i++;
    }

    final file = UnifiedFileService.createVirtualFile(
      name: candidate,
      content: content,
      virtualPath: candidate,
    );
    _addFileToState(file);
    _ensurePromptFilePresent();
    state = state.copyWith(
      activeFileId: file.id,
      // If requested, trigger the rename prompt flow in the editor route.
      pendingRenameFileId: promptForName ? file.id : state.pendingRenameFileId,
    );
  }

  /// Process plain text received via drop (Dock/Finder text drop) or other channels.
  /// Paths-only: if it parses as paths, they are validated and added; otherwise ignored.
  Future<void> processDroppedText(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;

    final pathParser = ref.read(pathParserServiceProvider);
    final parsed = await pathParser.parse(trimmed);

    if (parsed.validPaths.isNotEmpty) {
      final existingPaths = state.fileMap.values.map((f) => f.fullPath).toSet();
      final validation = await UnifiedFileService.validatePaths(
        parsed.validPaths,
        existingPaths,
      );
      if (validation.validFiles.isNotEmpty) {
        await _processNewItems(validation.validFiles, source: ScanSource.paste);
      }
      return;
    }

    // Not paths → do nothing (no auto detection/content creation)
  }

  //============================================================================
  // UI REBUILD HELPERS - INSTANT, NO DEBOUNCING
  //============================================================================

  void _rebuildCombinedContent() {
    // Find the special Prompt virtual file (if any), regardless of selection.
    ScannedFile? promptFile;
    for (final f in state.fileMap.values) {
      if (f.isVirtual && f.name == 'Prompt') {
        promptFile = f;
        break;
      }
    }

    final content = markdownBuilder.buildMarkdown(
      state.selectedFiles,
      prompt: promptFile,
    );
    if (mounted) {
      state = state.copyWith(combinedContent: content);
    }
  }

  void _rebuildTreeFromState() {
    final adapter = treeAdapter;
    if (adapter != null && mounted) {
      adapter.rebuildFromScanner(
        files: state.fileMap.values,
        metadata: state.scanHistory,
        selectedFileIds: state.selectedFileIds,
      );
    }
  }

  //============================================================================
  // STANDARD STATE MANAGEMENT METHODS
  //============================================================================

  /// Saves the combined content of all selected files to a new text file.
  Future<void> saveToFile() async {
    try {
      await UnifiedFileService.saveToFile(state.combinedContent);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  /// Copies the combined markdown context to the system clipboard.
  Future<void> copyContextToClipboard() async {
    try {
      await UnifiedFileService.copyToClipboard(state.combinedContent);
      // NOTE: The calling UI should show a confirmation SnackBar.
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  /// Copies the full paths of selected files to the clipboard.
  Future<void> copyFullPathsToClipboard() async {
    try {
      await UnifiedFileService.copyFullPaths(state.selectedFiles);
      // NOTE: The calling UI should show a confirmation SnackBar.
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  /// Copies the AI-formatted relative paths of selected files to the clipboard.
  Future<void> copyAiPathsToClipboard() async {
    try {
      await UnifiedFileService.copyAiPaths(state.selectedFiles);
      // NOTE: The calling UI should show a confirmation SnackBar.
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  /// Clears the current error message from the state.
  void clearError() {
    state = state.copyWith(clearError: true);
  }

  void onTreeSelectionChanged(Set<String> fileIds) {
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
    treeAdapter?.setSelectedEntryIds(newSelection);
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
    treeAdapter?.clear();
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

  @override
  void dispose() {
    treeAdapter?.selectionRelay = null;
    super.dispose();
  }

  /// New: Called from UI to create a virtual file.
  /// This creates the data object and triggers a tree rebuild.
  void createVirtualFile(String fileName, String content) {
    // Virtual path is just the file name, as it will live at the top level
    final virtualFile = UnifiedFileService.createVirtualFile(
      name: fileName,
      content: content,
      virtualPath: fileName,
    );

    // Add to state and rebuild everything. This is simpler and more robust.
    _addFileToState(virtualFile);
    // Ensure Prompt exists in the session (does not steal focus if already set)
    _ensurePromptFilePresent();
    // Make it the active file for editing in Monaco
    state = state.copyWith(
      activeFileId: virtualFile.id,
    );
  }

  /// Opens the special Prompt file, creating it if not present.
  void openPrompt() {
    // If Prompt exists, just activate it.
    for (final f in state.fileMap.values) {
      if (f.isVirtual && f.name == 'Prompt') {
        setActiveFile(f.id);
        return;
      }
    }
    // Otherwise, create an empty Prompt and focus it.
    createVirtualFile('Prompt', '');
  }

  /// Ensures a virtual file named 'Prompt' exists in the current session.
  void _ensurePromptFilePresent() {
    // If no session yet, do nothing (keeps home screen clean).
    if (!state.hasFiles) return;
    final hasPrompt = state.fileMap.values.any(
      (f) => f.isVirtual && f.name == 'Prompt',
    );
    if (hasPrompt) return;

    final prompt = UnifiedFileService.createVirtualFile(
      name: 'Prompt',
      content: '',
      virtualPath: 'Prompt',
    );
    // Add without stealing focus if one is already set
    final active = state.activeFileId;
    _addFileToState(prompt);
    if (active != null) {
      state = state.copyWith(activeFileId: active);
    }
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
    final adapter = treeAdapter;
    if (adapter == null) return;

    final data = adapter.data;
    if (data.nodes.isEmpty) return;

    final rawFileIdsToRemove = adapter.collectEntryIds(topLevelNodeIds);
    final sourcePathsToRemove = adapter.collectSourcePaths(topLevelNodeIds);

    final removeVirtualDescendants = topLevelNodeIds.contains(
      tree.TreeBuilder.treeRootId,
    );
    final fileIdsToRemove = <String>{
      for (final fileId in rawFileIdsToRemove)
        if (_shouldRemoveFileId(
          fileId: fileId,
          removeVirtualDescendants: removeVirtualDescendants,
          topLevelNodeIds: topLevelNodeIds,
          adapter: adapter,
        ))
          fileId,
    };

    if (fileIdsToRemove.isEmpty && sourcePathsToRemove.isEmpty) return;

    final newFileMap = Map<String, ScannedFile>.from(state.fileMap)
      ..removeWhere((fileId, _) => fileIdsToRemove.contains(fileId));

    final newSelectedFileIds = Set<String>.from(state.selectedFileIds)
      ..removeAll(fileIdsToRemove);

    final newScanHistory = _removePathsFromScanHistory(sourcePathsToRemove);

    // --- Step 4: Update state and trigger a full tree rebuild ---
    final shouldResetSession =
        newFileMap.isEmpty && state.sessionStarted && !state.hasFiles;

    // Adjust active file if it was removed
    String? newActiveFileId = state.activeFileId;
    if (newActiveFileId != null && !newFileMap.containsKey(newActiveFileId)) {
      // Prefer any still-selected file, else any remaining file, else null
      final stillSelected = state.selectedFileIds
          .where(newFileMap.containsKey)
          .toList();
      if (stillSelected.isNotEmpty) {
        newActiveFileId = stillSelected.first;
      } else if (newFileMap.isNotEmpty) {
        newActiveFileId = newFileMap.keys.first;
      } else {
        newActiveFileId = null;
      }
    }

    state = state.copyWith(
      fileMap: newFileMap,
      selectedFileIds: newSelectedFileIds,
      scanHistory: newScanHistory,
      // If all files are removed, end the session to return to home screen
      sessionStarted: state.sessionStarted && !shouldResetSession,
      activeFileId: newActiveFileId,
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

  bool _shouldRemoveFileId({
    required String fileId,
    required bool removeVirtualDescendants,
    required Set<String> topLevelNodeIds,
    required DirectoryTreeAdapter adapter,
  }) {
    final file = state.fileMap[fileId];
    final isVirtual = file?.isVirtual ?? false;
    if (!isVirtual) {
      return true;
    }
    if (!removeVirtualDescendants) {
      return true;
    }

    final nodeId = adapter.controller.nodeIdForEntryId(fileId);
    if (nodeId != null && topLevelNodeIds.contains(nodeId)) {
      return true;
    }

    return false;
  }
}
