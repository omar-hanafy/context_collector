import 'dart:async';
import 'dart:io';

import 'package:context_collector/context_collector.dart';
import 'package:context_collector/src/features/scan/services/drop_processor.dart';
import 'package:desktop_drop/desktop_drop.dart';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// State class
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
      processingProgress:
          clearProgress ? null : processingProgress ?? this.processingProgress,
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

// Provider
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
  })  : _fileScanner = fileScanner,
        _contentAssembler = contentAssembler,
        _dropProcessor = dropProcessor,
        _ref = ref,
        super(const SelectionState());
  final FileScanner _fileScanner;
  final ContentAssembler _contentAssembler;
  final DropProcessor _dropProcessor;
  // ignore: unused_field
  final Ref _ref;

  // Track active operations to prevent race conditions
  final _activeOperations = <String>{};
  StreamSubscription<DropProcessProgress>? _dropProcessSubscription;

  @override
  void dispose() {
    _dropProcessSubscription?.cancel();
    super.dispose();
  }

  void setSupportedExtensions(Map<String, FileCategory> extensions) {
    state = state.copyWith(supportedExtensions: extensions);
    _updateCombinedContent();
  }

  /// Process dropped items using the DropProcessor for robust handling
  Future<void> processDroppedItems(List<XFile> droppedItems) async {
    // Check if already processing
    if (_activeOperations.contains('drop_process')) {
      if (kDebugMode) {
        print('[SelectionNotifier] Already processing dropped items, skipping');
      }
      return;
    }

    _activeOperations.add('drop_process');
    state = state.copyWith(
      isProcessing: true,
      clearError: true,
      clearProgress: false,
    );

    try {
      final effectiveSupportedExtensions =
          state.supportedExtensions ?? ExtensionCatalog.extensionCategories;

      // Get existing file paths for duplicate detection
      final existingPaths = state.allFiles.map((f) => f.fullPath).toSet();

      // Process dropped items with progress tracking
      final result = await _dropProcessor.processDroppedItems(
        droppedItems: droppedItems,
        supportedExtensions: effectiveSupportedExtensions,
        existingFilePaths: existingPaths,
        onProgress: (progress) {
          if (mounted) {
            state = state.copyWith(processingProgress: progress);
          }
        },
      );

      // Processing complete, now load file contents
      if (result.files.isNotEmpty) {
        await _batchAddFiles(result.files);
      }

      // Report errors if any
      if (result.hasErrors) {
        final errorMessage = result.errors.entries
            .take(3) // Show first 3 errors
            .map((e) => '${e.key}: ${e.value}')
            .join('\n');
        final moreErrors = result.errors.length > 3
            ? '\n...and ${result.errors.length - 3} more errors'
            : '';

        state = state.copyWith(
          error: 'Some files could not be processed:\n$errorMessage$moreErrors',
        );
      }

      // Report skipped files if any and no other files were added
      if (result.skippedPaths.isNotEmpty && result.files.isEmpty) {
        state = state.copyWith(
          error: '${result.skippedPaths.length} files were already added',
        );
      }
    } catch (e) {
      if (kDebugMode) {
        print('[SelectionNotifier] Error in processDroppedItems: $e');
      }
      state = state.copyWith(
        error: 'Failed to process dropped items: $e',
      );
    } finally {
      _activeOperations.remove('drop_process');
      state = state.copyWith(
        isProcessing: false,
        clearProgress: true,
      );
    }
  }

  /// Batch add files with proper state management
  Future<void> _batchAddFiles(List<ScannedFile> newFiles) async {
    if (newFiles.isEmpty) return;

    // Add operation tracking
    _activeOperations.add('batch_add');

    try {
      final currentFiles = List<ScannedFile>.from(state.allFiles);
      final currentSelectedPaths = Set<String>.from(state.selectedFilePaths);

      // Add new files
      for (final file in newFiles) {
        if (!currentFiles.any((f) => f.fullPath == file.fullPath)) {
          currentFiles.add(file);
          currentSelectedPaths.add(file.fullPath);
        }
      }

      // Update state with all new files at once
      state = state.copyWith(
        allFiles: currentFiles,
        selectedFilePaths: currentSelectedPaths,
        pendingLoadCount: newFiles.length,
      );

      // Load file contents in batches
      await _batchLoadFileContents();
    } finally {
      _activeOperations.remove('batch_add');
    }
  }

  /// Load file contents in batches to avoid UI freezing
  Future<void> _batchLoadFileContents() async {
    final filesToLoad = state.selectedFiles
        .where((f) => f.content == null && f.error == null)
        .toList();

    if (filesToLoad.isEmpty) {
      state = state.copyWith(pendingLoadCount: 0);
      return;
    }

    // Add operation tracking
    _activeOperations.add('batch_load');

    try {
      final effectiveSupportedExtensions =
          state.supportedExtensions ?? ExtensionCatalog.extensionCategories;

      const batchSize = 10; // Process 10 files at a time
      final currentFiles = List<ScannedFile>.from(state.allFiles);

      for (var i = 0; i < filesToLoad.length; i += batchSize) {
        final batch = filesToLoad.skip(i).take(batchSize).toList();

        // Load batch in parallel
        final futures = batch.map((file) async {
          try {
            return await _fileScanner.loadFileContent(
                file, effectiveSupportedExtensions);
          } catch (e) {
            return file.copyWith(
              error: 'Failed to load: $e',
            );
          }
        });

        final loadedBatch = await Future.wait(futures);

        // Update files in state
        for (final loadedFile in loadedBatch) {
          final index =
              currentFiles.indexWhere((f) => f.fullPath == loadedFile.fullPath);
          if (index != -1) {
            currentFiles[index] = loadedFile;
          }
        }

        // Update state after each batch
        final remaining = filesToLoad.length - (i + batch.length);
        state = state.copyWith(
          allFiles: currentFiles,
          pendingLoadCount: remaining > 0 ? remaining : 0,
        );

        // Update combined content periodically
        if (i % (batchSize * 2) == 0 || remaining == 0) {
          await _updateCombinedContent();
        }

        // Small delay to prevent UI freezing
        if (remaining > 0) {
          await Future<void>.delayed(const Duration(milliseconds: 50));
        }
      }

      // Final update
      await _updateCombinedContent();
    } catch (e) {
      if (kDebugMode) {
        print('[SelectionNotifier] Batch load error: $e');
      }
      state = state.copyWith(
        error: 'Error loading file contents: $e',
        pendingLoadCount: 0,
      );
    } finally {
      _activeOperations.remove('batch_load');
    }
  }

  Future<void> addFiles(List<String> filePaths) async {
    var newFilesAdded = false;
    final currentFiles = List<ScannedFile>.from(state.allFiles);
    final currentSelectedPaths = Set<String>.from(state.selectedFilePaths);

    for (final filePath in filePaths) {
      final file = File(filePath);
      if (file.existsSync()) {
        final scannedFile = ScannedFile.fromFile(file);
        if (!currentFiles.any((f) => f.fullPath == scannedFile.fullPath)) {
          currentFiles.add(scannedFile);
          currentSelectedPaths.add(scannedFile.fullPath);
          newFilesAdded = true;
        }
      }
    }

    if (newFilesAdded) {
      // First update state with new files (showing loading state)
      state = state.copyWith(
        allFiles: currentFiles,
        selectedFilePaths: currentSelectedPaths,
        clearError: true,
        isProcessing: true, // Show processing state
      );

      // Load file contents (this will also update combined content and set isProcessing to false)
      await loadFileContents();
    } else {
      state = state.copyWith(clearError: true); // Still clear error if any
    }
  }

  Future<void> addDirectory(String directoryPath) async {
    state = state.copyWith(isProcessing: true, clearError: true);
    try {
      final effectiveSupportedExtensions =
          state.supportedExtensions ?? ExtensionCatalog.extensionCategories;
      final foundFiles = await _fileScanner.scanDirectory(
          directoryPath, effectiveSupportedExtensions);

      var newFilesAdded = false;
      final currentFiles = List<ScannedFile>.from(state.allFiles);
      final currentSelectedPaths = Set<String>.from(state.selectedFilePaths);

      for (final file in foundFiles) {
        if (!currentFiles.any((f) => f.fullPath == file.fullPath)) {
          currentFiles.add(file);
          currentSelectedPaths.add(file.fullPath);
          newFilesAdded = true;
        }
      }

      state = state.copyWith(
          allFiles: currentFiles, selectedFilePaths: currentSelectedPaths);
      if (newFilesAdded) {
        await _updateCombinedContent();
        await loadFileContents();
      }
    } catch (e) {
      state = state.copyWith(error: 'Error scanning directory: $e');
    } finally {
      state = state.copyWith(isProcessing: false);
    }
  }

  void removeFile(ScannedFile file) {
    final currentFiles = List<ScannedFile>.from(state.allFiles)
      ..removeWhere((f) => f.fullPath == file.fullPath);
    final currentSelectedPaths = Set<String>.from(state.selectedFilePaths)
      ..remove(file.fullPath);
    state = state.copyWith(
        allFiles: currentFiles, selectedFilePaths: currentSelectedPaths);
    _updateCombinedContent();
  }

  void clearFiles() {
    state = state.copyWith(
      allFiles: [],
      selectedFilePaths: {},
      combinedContent: '',
      clearError: true,
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

  Future<void> loadFileContents() async {
    final filesToLoad = state.selectedFiles
        .where((f) => f.content == null && f.error == null)
        .toList();

    if (filesToLoad.isEmpty) return;

    state = state.copyWith(isProcessing: true, clearError: true);
    try {
      final effectiveSupportedExtensions =
          state.supportedExtensions ?? ExtensionCatalog.extensionCategories;

      final currentFiles = List<ScannedFile>.from(state.allFiles);
      var changed = false;

      for (final file in filesToLoad) {
        final index =
            currentFiles.indexWhere((f) => f.fullPath == file.fullPath);
        if (index != -1) {
          final updatedFile = await _fileScanner.loadFileContent(
              file, effectiveSupportedExtensions);
          currentFiles[index] = updatedFile;
          changed = true;
        }
      }
      if (changed) {
        state = state.copyWith(
            allFiles: currentFiles); // Update state once after loop
      }
      await _updateCombinedContent(); // This will also update state with new combined content
    } catch (e) {
      state = state.copyWith(error: 'Error loading files: $e');
    } finally {
      state = state.copyWith(isProcessing: false);
    }
  }

  Future<void> copyToClipboard() async {
    var contentToCopy = state.combinedContent;
    if (contentToCopy.isEmpty && state.hasSelectedFiles) {
      state = state.copyWith(isProcessing: true);
      await loadFileContents(); // This will update state.combinedContent via _updateCombinedContent
      contentToCopy =
          state.combinedContent; // Re-fetch potentially updated content
      state = state.copyWith(isProcessing: false);
    }
    if (contentToCopy.isEmpty && !state.hasSelectedFiles) {
      state = state.copyWith(error: 'No files selected to copy.');
      return;
    }

    try {
      await Clipboard.setData(ClipboardData(text: contentToCopy));
    } catch (e) {
      state = state.copyWith(error: 'Error copying to clipboard: $e');
    }
  }

  Future<void> saveToFile() async {
    var contentToSave = state.combinedContent;
    if (contentToSave.isEmpty && state.hasSelectedFiles) {
      state = state.copyWith(isProcessing: true);
      await loadFileContents();
      contentToSave = state.combinedContent;
      state = state.copyWith(isProcessing: false);
    }
    if (contentToSave.isEmpty && !state.hasSelectedFiles) {
      state = state.copyWith(error: 'No files selected to save.');
      return;
    }

    try {
      final fileName =
          'context_collection_${DateTime.now().millisecondsSinceEpoch}.txt';
      final filePath = await getSaveLocation(
        suggestedName: fileName,
        acceptedTypeGroups: [
          const XTypeGroup(label: 'Text files', extensions: ['txt']),
        ],
      );

      if (filePath != null) {
        final file = File(filePath.path);
        await file.writeAsString(contentToSave);
      }
    } catch (e) {
      state = state.copyWith(error: 'Error saving file: $e');
    }
  }

  Future<void> pickFiles() async {
    state = state.copyWith(isProcessing: true, clearError: true);
    try {
      final files = await openFiles(
        acceptedTypeGroups: [
          const XTypeGroup(
            label: 'Text files',
            extensions: <String>[
              'txt',
              'dart',
              'py',
              'js',
              'ts',
              'jsx',
              'tsx',
              'java',
              'kt',
              'swift',
              'cpp',
              'c',
              'h',
              'hpp',
              'cs',
              'php',
              'rb',
              'go',
              'rs',
              'html',
              'css',
              'scss',
              'json',
              'xml',
              'yaml',
              'yml',
              'md',
              'sql'
            ],
          ),
          const XTypeGroup(label: 'All files'),
        ],
      );

      if (files.isNotEmpty) {
        final filePaths = files.map((file) => file.path).toList();
        // addFiles will set processing to false after it's done with its own loading.
        // So, no need to set isProcessing to false here explicitly.
        await addFiles(filePaths);
      } else {
        state = state.copyWith(isProcessing: false);
      }
    } catch (e) {
      state =
          state.copyWith(error: 'Error picking files: $e', isProcessing: false);
    }
  }

  Future<void> pickDirectory() async {
    state = state.copyWith(isProcessing: true, clearError: true);
    try {
      final directoryPath = await getDirectoryPath();
      if (directoryPath != null) {
        // addDirectory will set processing to false.
        await addDirectory(directoryPath);
      } else {
        state = state.copyWith(isProcessing: false);
      }
    } catch (e) {
      state = state.copyWith(
          error: 'Error picking directory: $e', isProcessing: false);
    }
  }

  void clearError() {
    state = state.copyWith(clearError: true);
  }

  // isFileSelected can be a getter on the state or a method here.
  // For consistency with UI, usually it's part of state or derived from it.
  // Let's assume UI will use state.selectedFilePaths.contains(file.fullPath)

  // Private method to update combined content
  // Note: This now updates the state directly.
  Future<void> _updateCombinedContent() async {
    final content = await _contentAssembler.buildMerged(state.selectedFiles);
    // Check if the notifier is still mounted before updating state
    if (!mounted) return;
    state = state.copyWith(combinedContent: content);
  }
}
