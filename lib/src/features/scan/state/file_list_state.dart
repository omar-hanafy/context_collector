// lib/src/features/scan/state/file_list_state.dart

import 'dart:async';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_directory_tree/flutter_directory_tree.dart' as tree;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as path;

import '../../../shared/platform/platform_caps.dart';
import '../../settings/presentation/state/preferences_notifier.dart';
import '../../virtual_tree/directory_tree_adapter.dart';
import '../models/scan_result.dart';
import '../models/scanned_file.dart';
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
    this.sessionStarted = false,
    this.error,
    this.combinedContent = '',
    this.activeFileId,
    this.viewingAll = false,
    this.pendingRenameFileId,
    this.editorBoundFileId,
  });

  final Map<String, ScannedFile> fileMap;
  final Set<String> selectedFileIds;
  final List<ScanMetadata> scanHistory;
  final bool isProcessing;
  final bool sessionStarted;
  final String? error;
  final String combinedContent;
  final String? activeFileId;
  final bool viewingAll;
  final String? pendingRenameFileId;
  final String? editorBoundFileId;

  // Backward compatible getters
  Set<String> get selectedFilePaths =>
      selectedFiles.map((f) => f.fullPath).toSet();

  List<ScannedFile> get selectedFiles => selectedFileIds
      .map((id) => fileMap[id])
      .whereType<ScannedFile>()
      .toList();

  int get selectedFilesCount => selectedFiles.length;
  int get totalFilesCount => fileMap.length;
  bool get hasFiles => fileMap.isNotEmpty;
  bool get hasSelectedFiles => selectedFileIds.isNotEmpty;

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
    bool clearActiveFileId = false,
    bool? viewingAll,
    String? pendingRenameFileId,
    bool clearPendingRenameFileId = false,
    String? editorBoundFileId,
    bool clearEditorBoundFileId = false,
  }) {
    return SelectionState(
      fileMap: fileMap ?? this.fileMap,
      selectedFileIds: selectedFileIds ?? this.selectedFileIds,
      scanHistory: scanHistory ?? this.scanHistory,
      isProcessing: isProcessing ?? this.isProcessing,
      sessionStarted: sessionStarted ?? this.sessionStarted,
      error: clearError ? null : error ?? this.error,
      combinedContent: combinedContent ?? this.combinedContent,
      activeFileId: clearActiveFileId
          ? null
          : activeFileId ?? this.activeFileId,
      viewingAll: viewingAll ?? this.viewingAll,
      pendingRenameFileId: clearPendingRenameFileId
          ? null
          : pendingRenameFileId ?? this.pendingRenameFileId,
      editorBoundFileId: clearEditorBoundFileId
          ? null
          : editorBoundFileId ?? this.editorBoundFileId,
    );
  }

  ScannedFile? get activeFile =>
      activeFileId == null ? null : fileMap[activeFileId];

  bool get editorIsBoundToActiveFile =>
      activeFileId != null && editorBoundFileId == activeFileId;
}

final pathParserServiceProvider = Provider<PathParserService>(
  (ref) => PathParserService(),
);

final selectionProvider =
    StateNotifierProvider<FileListNotifier, SelectionState>((ref) {
      return FileListNotifier(
        ref: ref,
      );
    });

class FileListNotifier extends StateNotifier<SelectionState> {
  FileListNotifier({
    required this.ref,
  }) : super(const SelectionState());

  final Ref ref;

  DirectoryTreeAdapter? treeAdapter;
  Timer? _treeRebuildTimer;

  void initializeDirectoryTree(DirectoryTreeAdapter adapter) {
    treeAdapter?.selectionRelay = null;
    treeAdapter = adapter;
    treeAdapter!.selectionRelay = onTreeSelectionChanged;
    _rebuildTreeFromState(force: true);
  }

  //============================================================================
  // MAIN PROCESSING METHOD
  //============================================================================

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
        onBatchFound: _addBatchToState,
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
          _ensureSpecialFilesPresent();
          _rebuildTreeFromState(force: true);
          // Only rebuild combined content if absolutely necessary (viewing all)
          if (state.viewingAll) {
            unawaited(_rebuildCombinedContent());
          }
        },
      );
    } catch (e) {
      state = state.copyWith(error: 'Failed to process new items: $e');
    } finally {
      state = state.copyWith(isProcessing: false);
    }
  }

  /// Efficiently adds a batch of files to the state
  void _addBatchToState(List<ScannedFile> files) {
    if (files.isEmpty) return;

    final newFileMap = Map<String, ScannedFile>.from(state.fileMap);
    final updatedSelection = Set<String>.from(state.selectedFileIds);

    for (final file in files) {
      newFileMap[file.id] = file;
      updatedSelection.add(file.id);
    }

    final nextActiveFile = state.activeFileId == null ? files.first : null;
    state = state.copyWith(
      fileMap: newFileMap,
      selectedFileIds: updatedSelection,
      sessionStarted: true,
      // Only set active file if none exists
      activeFileId: state.activeFileId ?? files.first.id,
      clearEditorBoundFileId: nextActiveFile != null,
    );

    if (nextActiveFile != null) {
      unawaited(_loadSingleFileContentIfNeeded(nextActiveFile));
    }

    // Update tree incrementally so user sees progress
    _rebuildTreeFromState();
  }

  /// Add a single file (helper for virtual files)
  void _addFileToState(ScannedFile file) {
    _addBatchToState([file]);
  }

  //============================================================================
  // PUBLIC API
  //============================================================================

  /// Set active file for viewing/editing in Monaco.
  /// Implements LAZY LOADING of content.
  void setActiveFile(String fileId) {
    if (!state.fileMap.containsKey(fileId)) return;

    // Update active ID immediately
    if (state.activeFileId != fileId) {
      state = state.copyWith(activeFileId: fileId);
    }

    // Lazy Load: Check if content is missing and needs loading
    final file = state.fileMap[fileId]!;
    unawaited(_loadSingleFileContentIfNeeded(file));
  }

  Future<void> _loadSingleFileContentIfNeeded(ScannedFile file) async {
    if (file.isVirtual || file.content != null || file.error != null) {
      return;
    }
    await _loadSingleFileContent(file);
  }

  /// Loads content for a single file safely
  Future<void> _loadSingleFileContent(ScannedFile file) async {
    try {
      final loadedFile = await UnifiedFileService.loadFileContent(file);

      if (mounted && state.fileMap.containsKey(loadedFile.id)) {
        final currentFile = state.fileMap[loadedFile.id]!;
        final newFileMap = Map<String, ScannedFile>.from(state.fileMap);
        newFileMap[loadedFile.id] = currentFile.copyWith(
          content: loadedFile.content,
          error: loadedFile.error,
          clearError: loadedFile.error == null,
        );
        state = state.copyWith(fileMap: newFileMap);

        // If we are viewing all, we might need to update the combined view
        if (state.viewingAll) {
          unawaited(_rebuildCombinedContent());
        }
      }
    } catch (e) {
      // Handle read errors gracefully, maybe update file with error state
    }
  }

  bool saveEditorTextFor(String fileId, String text) {
    if (state.viewingAll) return false;
    if (state.editorBoundFileId != fileId) return false;
    final file = state.fileMap[fileId];
    if (file == null || !file.hasEditorContent) return false;
    if (text == file.editorContent) return true;

    final newFileMap = Map<String, ScannedFile>.from(state.fileMap);
    final baseContent = file.isVirtual
        ? file.virtualContent ?? file.content ?? ''
        : file.content;
    newFileMap[fileId] = baseContent != null && text == baseContent
        ? file.copyWith(clearEditedContent: true)
        : file.copyWith(editedContent: text);
    state = state.copyWith(fileMap: newFileMap);

    if (state.viewingAll) {
      unawaited(_rebuildCombinedContent());
    }
    return true;
  }

  void markEditorContentBoundToFile(String fileId) {
    final file = state.fileMap[fileId];
    if (state.viewingAll ||
        state.activeFileId != fileId ||
        file == null ||
        !file.hasEditorContent) {
      return;
    }
    if (state.editorBoundFileId == fileId) return;
    state = state.copyWith(editorBoundFileId: fileId);
  }

  void clearEditorContentBinding() {
    if (state.editorBoundFileId == null) return;
    state = state.copyWith(clearEditorBoundFileId: true);
  }

  Future<void> refreshAllContents() async {
    state = state.copyWith(isProcessing: true);
    final filesToRefresh = state.fileMap.values.where((f) => !f.isVirtual);
    final newFileMap = Map<String, ScannedFile>.from(state.fileMap);

    for (final file in filesToRefresh) {
      try {
        final reloadedFile = await UnifiedFileService.loadFileContent(file);
        newFileMap[reloadedFile.id] = reloadedFile.copyWith(
          clearEditedContent: true,
        );
      } catch (_) {}
    }

    state = state.copyWith(fileMap: newFileMap, isProcessing: false);
    if (state.viewingAll) {
      unawaited(_rebuildCombinedContent());
    }
    _rebuildTreeFromState(force: true);
  }

  Future<void> pickFiles(BuildContext context) async {
    final files = await openFiles();
    if (files.isNotEmpty) {
      await _processNewItems(files, source: ScanSource.browse);
    }
  }

  Future<void> pickDirectory(BuildContext context) async {
    // Browsers cannot open a directory picker with readable paths; folder
    // input on web happens through drag-and-drop (UI entry points are hidden).
    if (!PlatformCaps.supportsDirectoryPicker) return;
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
    // Pasted filesystem paths are unreadable in a browser (UI entry points
    // are hidden on web).
    if (!PlatformCaps.supportsPastePaths) return;
    state = state.copyWith(isProcessing: true, clearError: true);
    try {
      final pathParser = ref.read(pathParserServiceProvider);
      final parseResult = await pathParser.parse(pastedText);

      final existingPaths = state.fileMap.values.map((f) => f.fullPath).toSet();
      final validationResult = await UnifiedFileService.validatePaths(
        parseResult.validPaths,
        existingPaths,
      );

      if (validationResult.hasValidFiles) {
        await _processNewItems(
          validationResult.validFiles,
          source: ScanSource.paste,
        );
      }

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

  Future<void> pastePathsFromClipboard(BuildContext context) async {
    if (!PlatformCaps.supportsPastePaths) return;
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
    state = state.copyWith(viewingAll: v, clearEditorBoundFileId: v);
    if (v) {
      unawaited(_rebuildCombinedContent());
    }
  }

  void exitCombinedPreview() => setViewingAll(false);

  void clearPendingRename() {
    state = state.copyWith(clearPendingRenameFileId: true);
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
    state = state.copyWith(
      fileMap: newMap,
      clearPendingRenameFileId: true,
    );
    _rebuildTreeFromState(force: true);
  }

  void createVirtualFileWithAutoName(
    String content, {
    String base = 'pasted',
    String ext = '.txt',
    bool promptForName = false,
  }) {
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
    _ensureSpecialFilesPresent();
    // Setting active file will trigger lazy load check (which does nothing for virtual)
    setActiveFile(file.id);
  }

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
  }

  //============================================================================
  // UI REBUILD HELPERS
  //============================================================================

  Future<void> _rebuildCombinedContent() async {
    if (!state.viewingAll) return; // Lazy rebuild
    final content = await UnifiedFileService.buildCombinedContent(
      state.selectedFiles,
    );
    if (mounted) {
      state = state.copyWith(combinedContent: content);
    }
  }

  void _rebuildTreeFromState({bool force = false}) {
    final adapter = treeAdapter;
    if (adapter == null || !mounted) return;

    if (!force && (_treeRebuildTimer?.isActive ?? false)) return;
    _treeRebuildTimer?.cancel();

    if (force) {
      _performTreeRebuild();
    } else {
      _treeRebuildTimer = Timer(
        const Duration(milliseconds: 200),
        _performTreeRebuild,
      );
    }
  }

  void _performTreeRebuild() {
    final adapter = treeAdapter;
    if (adapter == null || !mounted) return;
    adapter.rebuildFromScanner(
      files: state.fileMap.values,
      metadata: state.scanHistory,
      selectedFileIds: state.selectedFileIds,
    );
  }

  //============================================================================
  // STANDARD STATE MANAGEMENT METHODS
  //============================================================================

  Future<void> saveToFile() async {
    try {
      state = state.copyWith(isProcessing: true);
      // Use streaming save to handle large projects
      await UnifiedFileService.streamSaveToFile(state.selectedFiles);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    } finally {
      state = state.copyWith(isProcessing: false);
    }
  }

  Future<String> buildSelectedContextContent() async {
    final selectedFiles = state.selectedFiles;
    if (selectedFiles.isEmpty) return '';
    return UnifiedFileService.buildCombinedContent(selectedFiles);
  }

  Future<bool> copyContextToClipboard() async {
    try {
      final content = await buildSelectedContextContent();
      if (content.trim().isEmpty) return false;
      await UnifiedFileService.copyToClipboard(content);
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      rethrow;
    }
  }

  Future<void> copyFullPathsToClipboard() async {
    try {
      await UnifiedFileService.copyFullPaths(state.selectedFiles);
    } catch (e) {
      state = state.copyWith(error: e.toString());
      rethrow;
    }
  }

  Future<void> copyAiPathsToClipboard() async {
    try {
      await UnifiedFileService.copyAiPaths(state.selectedFiles);
    } catch (e) {
      state = state.copyWith(error: e.toString());
      rethrow;
    }
  }

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

    // Only rebuild combined content if we are viewing it
    if (state.viewingAll) {
      unawaited(_rebuildCombinedContent());
    }

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
      clearEditorBoundFileId:
          state.editorBoundFileId != null &&
          !newFileMap.containsKey(state.editorBoundFileId),
    );
    _rebuildTreeFromState(force: true);
    if (state.viewingAll) {
      unawaited(_rebuildCombinedContent());
    }
  }

  void clearFiles() {
    treeAdapter?.clear();
    state = const SelectionState();
  }

  void onFileContentChanged(String fileId, String newContent) {
    final file = state.fileMap[fileId];
    if (file == null) return;
    final newFileMap = Map<String, ScannedFile>.from(state.fileMap);
    final baseContent = file.isVirtual
        ? file.virtualContent ?? file.content ?? ''
        : file.content;
    newFileMap[fileId] = baseContent != null && newContent == baseContent
        ? file.copyWith(clearEditedContent: true)
        : file.copyWith(editedContent: newContent);
    state = state.copyWith(fileMap: newFileMap);

    if (state.viewingAll) {
      unawaited(_rebuildCombinedContent());
    }
  }

  @override
  void dispose() {
    _treeRebuildTimer?.cancel();
    treeAdapter?.selectionRelay = null;
    super.dispose();
  }

  void createVirtualFile(
    String fileName,
    String content, {
    String? virtualPath,
  }) {
    final effectivePath = (virtualPath == null || virtualPath.isEmpty)
        ? fileName
        : virtualPath;
    final virtualFile = UnifiedFileService.createVirtualFile(
      name: fileName,
      content: content,
      virtualPath: effectivePath,
    );

    _addFileToState(virtualFile);
    _ensureSpecialFilesPresent();
    // Setting active file will trigger lazy load check (which does nothing for virtual)
    setActiveFile(virtualFile.id);
  }

  void openHeader() {
    for (final f in state.fileMap.values) {
      if (f.isVirtual && f.name == 'Header') {
        setActiveFile(f.id);
        return;
      }
    }
    createVirtualFile('Header', '');
  }

  void _ensureSpecialFilesPresent() {
    if (!state.hasFiles) return;

    final hasHeader = state.fileMap.values.any(
      (f) => f.isVirtual && f.name == 'Header',
    );
    final hasFooter = state.fileMap.values.any(
      (f) => f.isVirtual && f.name == 'Footer',
    );

    if (hasHeader && hasFooter) return;

    if (!hasHeader) {
      final header = UnifiedFileService.createVirtualFile(
        name: 'Header',
        content: '',
        virtualPath: 'Header',
      );
      _addFileToState(header);
    }

    if (!hasFooter) {
      final footer = UnifiedFileService.createVirtualFile(
        name: 'Footer',
        content: '',
        virtualPath: 'Footer',
      );
      _addFileToState(footer);
    }
  }

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

    final filePathsToRemove = <String>{
      for (final fileId in fileIdsToRemove)
        if (state.fileMap[fileId] case final file? when !file.isVirtual)
          file.fullPath,
    };

    if (fileIdsToRemove.isEmpty && sourcePathsToRemove.isEmpty) return;

    final newFileMap = Map<String, ScannedFile>.from(state.fileMap)
      ..removeWhere((fileId, _) => fileIdsToRemove.contains(fileId));

    final newSelectedFileIds = Set<String>.from(state.selectedFileIds)
      ..removeAll(fileIdsToRemove);

    final newScanHistory = _removePathsFromScanHistory(
      {...sourcePathsToRemove, ...filePathsToRemove},
      remainingFiles: newFileMap.values,
    );

    final shouldResetSession =
        newFileMap.isEmpty && state.sessionStarted && !state.hasFiles;

    String? newActiveFileId = state.activeFileId;
    if (newActiveFileId != null && !newFileMap.containsKey(newActiveFileId)) {
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
      sessionStarted: state.sessionStarted && !shouldResetSession,
      activeFileId: newActiveFileId,
      clearActiveFileId: newActiveFileId == null,
      clearEditorBoundFileId:
          state.editorBoundFileId != null &&
          (state.editorBoundFileId != newActiveFileId ||
              !newFileMap.containsKey(state.editorBoundFileId)),
    );

    _rebuildTreeFromState(force: true);
    if (state.viewingAll) {
      unawaited(_rebuildCombinedContent());
    }
  }

  List<ScanMetadata> _removePathsFromScanHistory(
    Iterable<String> pathsToRemove, {
    required Iterable<ScannedFile> remainingFiles,
  }) {
    final pathsToRemoveSet = pathsToRemove
        .map(_normalizeScanPath)
        .where((p) => p.isNotEmpty)
        .toSet();
    final remainingRealFilePaths = remainingFiles
        .where((file) => !file.isVirtual)
        .map((file) => _normalizeScanPath(file.fullPath))
        .where((p) => p.isNotEmpty)
        .toList();
    final newScanHistory = <ScanMetadata>[];

    for (final scanMetadata in state.scanHistory) {
      final remainingSourcePaths = <String>[];
      for (final sourcePath in scanMetadata.sourcePaths) {
        final normalizedSourcePath = _normalizeScanPath(sourcePath);
        final affectedByRemoval = pathsToRemoveSet.any(
          (removedPath) =>
              _sameOrNestedPath(normalizedSourcePath, removedPath) ||
              _sameOrNestedPath(removedPath, normalizedSourcePath),
        );
        final hasRemainingFiles = remainingRealFilePaths.any(
          (filePath) => _sameOrNestedPath(normalizedSourcePath, filePath),
        );

        if (!affectedByRemoval || hasRemainingFiles) {
          remainingSourcePaths.add(sourcePath);
        }
      }

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

  String _normalizeScanPath(String value) {
    if (value.trim().isEmpty) return '';
    return path.normalize(value);
  }

  bool _sameOrNestedPath(String parentPath, String childPath) {
    if (parentPath.isEmpty || childPath.isEmpty) return false;
    return parentPath == childPath || path.isWithin(parentPath, childPath);
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
