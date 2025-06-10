import 'dart:async';
import 'dart:io';

import 'package:context_collector/context_collector.dart';
import 'package:context_collector/src/features/scan/services/drop_processor.dart';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// State class (no changes needed here)
@immutable
class SelectionState {
  const SelectionState({
    this.allFiles = const [],
    this.selectedFilePaths = const {},
    this.isProcessing = false,
    this.error,
    this.combinedContent = '',
    this.supportedExtensions,
    this.processingProgress,
    this.pendingLoadCount = 0,
  });
  final List<ScannedFile> allFiles;
  final Set<String> selectedFilePaths;
  final bool isProcessing;
  final String? error;
  final String combinedContent;
  final Map<String, FileCategory>? supportedExtensions;
  final DropProcessProgress? processingProgress;
  final int pendingLoadCount;

  SelectionState copyWith({
    List<ScannedFile>? allFiles,
    Set<String>? selectedFilePaths,
    bool? isProcessing,
    String? error,
    bool clearError = false, // Special flag to clear error
    String? combinedContent,
    Map<String, FileCategory>? supportedExtensions,
    DropProcessProgress? processingProgress,
    bool clearProgress = false,
    int? pendingLoadCount,
  }) {
    return SelectionState(
      allFiles: allFiles ?? this.allFiles,
      selectedFilePaths: selectedFilePaths ?? this.selectedFilePaths,
      isProcessing: isProcessing ?? this.isProcessing,
      error: clearError ? null : error ?? this.error,
      combinedContent: combinedContent ?? this.combinedContent,
      supportedExtensions: supportedExtensions ?? this.supportedExtensions,
      processingProgress: clearProgress
          ? null
          : processingProgress ?? this.processingProgress,
      pendingLoadCount: pendingLoadCount ?? this.pendingLoadCount,
    );
  }

  // Getters (derived state)
  List<ScannedFile> get selectedFiles => allFiles
      .where((file) => selectedFilePaths.contains(file.fullPath))
      .toList();
  int get selectedFilesCount => selectedFiles.length;
  int get totalFilesCount => allFiles.length;
  bool get hasFiles => allFiles.isNotEmpty;
  bool get hasSelectedFiles => selectedFiles.isNotEmpty;
}

// Provider (no changes needed here)
final selectionProvider =
    StateNotifierProvider<SelectionNotifier, SelectionState>((ref) {
      final fileScanner = FileScanner();
      return SelectionNotifier(
        fileScanner: fileScanner,
        contentAssembler: ContentAssembler(),
        dropProcessor: DropProcessor(fileScanner: fileScanner),
        ref: ref,
      );
    });

// Notifier
class SelectionNotifier extends StateNotifier<SelectionState> {
  SelectionNotifier({
    required FileScanner fileScanner,
    required ContentAssembler contentAssembler,
    required DropProcessor dropProcessor,
    required Ref ref,
  }) : _fileScanner = fileScanner,
       _contentAssembler = contentAssembler,
       _dropProcessor = dropProcessor,
       _ref = ref,
       super(const SelectionState());

  final FileScanner _fileScanner;
  final ContentAssembler _contentAssembler;
  final DropProcessor _dropProcessor;
  // ignore: unused_field
  final Ref _ref;

  /// --- RACE CONDITION FIX ---
  /// Each time a new file loading operation starts (or is cleared), we increment this ID.
  /// Async operations check if their original ID is still the current one before updating the state.
  /// This prevents a slow, old operation from overwriting a newer state.
  int _loadOperationId = 0;

  @override
  void dispose() {
    // Incrementing the ID on dispose ensures any lingering async operations are cancelled.
    _loadOperationId++;
    super.dispose();
  }

  void setSupportedExtensions(Map<String, FileCategory> extensions) {
    state = state.copyWith(supportedExtensions: extensions);
    _updateCombinedContent();
  }

  /// Process dropped items using the DropProcessor for robust handling
  Future<void> processDroppedItems(List<XFile> droppedItems) async {
    /// --- RACE CONDITION FIX ---
    /// This is a new operation, so we get a new ID, invalidating any previous operations.
    final operationId = ++_loadOperationId;

    state = state.copyWith(
      isProcessing: true,
      clearError: true,
      clearProgress: false,
    );

    try {
      final effectiveSupportedExtensions =
          state.supportedExtensions ?? ExtensionCatalog.extensionCategories;
      final existingPaths = state.allFiles.map((f) => f.fullPath).toSet();

      final result = await _dropProcessor.processDroppedItems(
        droppedItems: droppedItems,
        supportedExtensions: effectiveSupportedExtensions,
        existingFilePaths: existingPaths,
        onProgress: (progress) {
          if (mounted && operationId == _loadOperationId) {
            state = state.copyWith(processingProgress: progress);
          }
        },
      );

      // Check if the operation has been cancelled by a newer one.
      if (!mounted || operationId != _loadOperationId) return;

      // Processing complete, now add files and load their contents
      if (result.files.isNotEmpty) {
        await _batchAddAndLoadFiles(operationId, result.files);
      }

      // --- Error and message reporting (simplified for clarity) ---
      if (result.hasErrors) {
        state = state.copyWith(error: 'Some files could not be processed.');
      } else if (result.skippedPaths.isNotEmpty && result.files.isEmpty) {
        state = state.copyWith(
          error:
              'No new files added. Skipped ${result.skippedPaths.length} duplicates.',
        );
      }
    } catch (e) {
      if (mounted && operationId == _loadOperationId) {
        state = state.copyWith(error: 'Failed to process dropped items: $e');
      }
    } finally {
      if (mounted && operationId == _loadOperationId) {
        state = state.copyWith(isProcessing: false, clearProgress: true);
      }
    }
  }

  /// --- REFACTORED ---
  /// Combines batch adding and loading into a single, cancellable flow.
  Future<void> _batchAddAndLoadFiles(
    int operationId,
    List<ScannedFile> newFiles,
  ) async {
    if (newFiles.isEmpty) return;

    // 1. Add new files to the state immediately so they appear in the UI.
    final currentFiles = List<ScannedFile>.from(state.allFiles);
    final currentSelectedPaths = Set<String>.from(state.selectedFilePaths);
    final filesToAdd = <ScannedFile>[];

    for (final file in newFiles) {
      if (!currentFiles.any((f) => f.fullPath == file.fullPath)) {
        filesToAdd.add(file);
        currentFiles.add(file);
        currentSelectedPaths.add(file.fullPath);
      }
    }

    if (!mounted || operationId != _loadOperationId) return;

    state = state.copyWith(
      allFiles: currentFiles,
      selectedFilePaths: currentSelectedPaths,
      pendingLoadCount: state.pendingLoadCount + filesToAdd.length,
    );
    await _updateCombinedContent();

    // 2. Load the content for the newly added files in cancellable batches.
    await _batchLoadFileContents(operationId, filesToAdd);
  }

  /// --- REFACTORED ---
  /// Loads file contents in batches and is aware of the operationId to allow cancellation.
  Future<void> _batchLoadFileContents(
    int operationId,
    List<ScannedFile> filesToLoad,
  ) async {
    if (filesToLoad.isEmpty) return;

    try {
      final effectiveSupportedExtensions =
          state.supportedExtensions ?? ExtensionCatalog.extensionCategories;
      const batchSize = 10;

      for (var i = 0; i < filesToLoad.length; i += batchSize) {
        // *** CANCELLATION CHECK ***
        if (!mounted || operationId != _loadOperationId) return;

        final batch = filesToLoad.skip(i).take(batchSize).toList();
        final futures = batch.map(
          (file) =>
              _fileScanner.loadFileContent(file, effectiveSupportedExtensions),
        );
        final loadedBatch = await Future.wait(futures);

        // *** CANCELLATION CHECK ***
        if (!mounted || operationId != _loadOperationId) return;

        // *** SAFE STATE UPDATE ***
        // Apply updates to the *current* state's file list.
        // This prevents re-introducing files that were cleared.
        final currentFiles = List<ScannedFile>.from(state.allFiles);
        var changed = false;
        for (final loadedFile in loadedBatch) {
          final index = currentFiles.indexWhere(
            (f) => f.fullPath == loadedFile.fullPath,
          );
          if (index != -1) {
            currentFiles[index] = loadedFile;
            changed = true;
          }
        }

        if (changed) {
          state = state.copyWith(
            allFiles: currentFiles,
            pendingLoadCount: state.pendingLoadCount - batch.length,
          );
          await _updateCombinedContent();
        } else {
          // Files were likely cleared while loading, just update the count.
          state = state.copyWith(
            pendingLoadCount: state.pendingLoadCount - batch.length,
          );
        }

        // Small delay to keep the UI responsive.
        await Future.delayed(const Duration(milliseconds: 50));
      }
    } catch (e) {
      if (mounted && operationId == _loadOperationId) {
        state = state.copyWith(error: 'Error loading file contents: $e');
      }
    } finally {
      if (mounted && operationId == _loadOperationId) {
        // This was the last active operation, so we can clear the pending count.
        if (state.pendingLoadCount <= 0) {
          state = state.copyWith(pendingLoadCount: 0);
        }
      }
    }
  }

  void removeFile(ScannedFile file) {
    final currentFiles = List<ScannedFile>.from(state.allFiles)
      ..removeWhere((f) => f.fullPath == file.fullPath);
    final currentSelectedPaths = Set<String>.from(state.selectedFilePaths)
      ..remove(file.fullPath);

    // If the removed file was pending, decrease the count.
    final wasPending = file.content == null && file.error == null;
    final newPendingCount = wasPending
        ? state.pendingLoadCount - 1
        : state.pendingLoadCount;

    state = state.copyWith(
      allFiles: currentFiles,
      selectedFilePaths: currentSelectedPaths,
      pendingLoadCount: newPendingCount > 0 ? newPendingCount : 0,
    );
    _updateCombinedContent();
  }

  /// --- REFACTORED ---
  void clearFiles() {
    // Invalidate any ongoing loading operations by incrementing the ID.
    _loadOperationId++;

    state = state.copyWith(
      allFiles: [],
      selectedFilePaths: {},
      combinedContent: '',
      clearError: true,
      pendingLoadCount: 0,
      clearProgress: true,
      isProcessing: false,
    );
  }

  void toggleFileSelection(ScannedFile file) {
    final currentSelectedPaths = Set<String>.from(state.selectedFilePaths);
    if (currentSelectedPaths.contains(file.fullPath)) {
      currentSelectedPaths.remove(file.fullPath);
    } else {
      currentSelectedPaths.add(file.fullPath);
    }
    state = state.copyWith(selectedFilePaths: currentSelectedPaths);
    _updateCombinedContent();
  }

  void selectAll() {
    final allPaths = state.allFiles.map((f) => f.fullPath).toSet();
    state = state.copyWith(selectedFilePaths: allPaths);
    _updateCombinedContent();
  }

  void deselectAll() {
    state = state.copyWith(selectedFilePaths: {});
    _updateCombinedContent();
  }

  Future<void> copyToClipboard() async {
    await _ensureContentIsLoaded();
    if (state.combinedContent.isEmpty) {
      state = state.copyWith(error: 'No content to copy.');
      return;
    }
    await Clipboard.setData(ClipboardData(text: state.combinedContent));
  }

  Future<void> saveToFile() async {
    await _ensureContentIsLoaded();
    final contentToSave = state.combinedContent;

    if (contentToSave.isEmpty) {
      state = state.copyWith(error: 'No content to save.');
      return;
    }

    try {
      final fileName =
          'context_collection_${DateTime.now().millisecondsSinceEpoch}.txt';
      final filePath = await getSaveLocation(suggestedName: fileName);
      if (filePath != null) {
        await File(filePath.path).writeAsString(contentToSave);
      }
    } catch (e) {
      state = state.copyWith(error: 'Error saving file: $e');
    }
  }

  /// Helper to ensure all selected files are loaded before an action.
  Future<void> _ensureContentIsLoaded() async {
    final filesToLoad = state.selectedFiles
        .where((f) => f.content == null && f.error == null)
        .toList();
    if (filesToLoad.isEmpty) {
      await _updateCombinedContent();
      return;
    }

    final operationId = ++_loadOperationId;
    state = state.copyWith(isProcessing: true);
    await _batchLoadFileContents(operationId, filesToLoad);
    if (mounted && operationId == _loadOperationId) {
      state = state.copyWith(isProcessing: false);
    }
  }

  Future<void> pickFiles() async {
    final operationId = ++_loadOperationId;
    state = state.copyWith(isProcessing: true, clearError: true);
    try {
      final files = await openFiles();
      if (!mounted || operationId != _loadOperationId) return;

      if (files.isNotEmpty) {
        final scannedFiles = files
            .map((f) => ScannedFile.fromFile(File(f.path)))
            .toList();
        await _batchAddAndLoadFiles(operationId, scannedFiles);
      }
    } catch (e) {
      if (mounted && operationId == _loadOperationId) {
        state = state.copyWith(error: 'Error picking files: $e');
      }
    } finally {
      if (mounted && operationId == _loadOperationId) {
        state = state.copyWith(isProcessing: false);
      }
    }
  }

  Future<void> pickDirectory() async {
    final operationId = ++_loadOperationId;
    state = state.copyWith(isProcessing: true, clearError: true);
    try {
      final directoryPath = await getDirectoryPath();
      if (!mounted || operationId != _loadOperationId) return;

      if (directoryPath != null) {
        final foundFiles = await _fileScanner.scanDirectory(
          directoryPath,
          state.supportedExtensions ?? ExtensionCatalog.extensionCategories,
        );
        if (mounted && operationId == _loadOperationId) {
          await _batchAddAndLoadFiles(operationId, foundFiles);
        }
      }
    } catch (e) {
      if (mounted && operationId == _loadOperationId) {
        state = state.copyWith(error: 'Error picking directory: $e');
      }
    } finally {
      if (mounted && operationId == _loadOperationId) {
        state = state.copyWith(isProcessing: false);
      }
    }
  }

  void clearError() {
    state = state.copyWith(clearError: true);
  }

  Future<void> _updateCombinedContent() async {
    if (!mounted) return;
    final content = await _contentAssembler.buildMerged(state.selectedFiles);
    if (mounted) {
      state = state.copyWith(combinedContent: content);
    }
  }
}
