import 'dart:io';

import 'package:context_collector/context_collector.dart';
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
  });
  final List<ScannedFile> allFiles;
  final Set<String> selectedFilePaths;
  final bool isProcessing;
  final String? error;
  final String combinedContent;
  final Map<String, FileCategory>? supportedExtensions;

  SelectionState copyWith({
    List<ScannedFile>? allFiles,
    Set<String>? selectedFilePaths,
    bool? isProcessing,
    String? error,
    bool clearError = false, // Special flag to clear error
    String? combinedContent,
    Map<String, FileCategory>? supportedExtensions,
  }) {
    return SelectionState(
      allFiles: allFiles ?? this.allFiles,
      selectedFilePaths: selectedFilePaths ?? this.selectedFilePaths,
      isProcessing: isProcessing ?? this.isProcessing,
      error: clearError ? null : error ?? this.error,
      combinedContent: combinedContent ?? this.combinedContent,
      supportedExtensions: supportedExtensions ?? this.supportedExtensions,
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
  // If FileScanner and ContentAssembler were also Riverpod providers,
  // we would use ref.watch or ref.read here.
  // For now, we instantiate them directly as in the original Cubit.
  return SelectionNotifier(
    fileScanner: FileScanner(),
    contentAssembler: ContentAssembler(),
    ref:
        ref, // Pass ref for potential future use (e.g., reading other providers)
  );
});

// Notifier
class SelectionNotifier extends StateNotifier<SelectionState> {
  // Keep ref for potential future use

  SelectionNotifier({
    required FileScanner fileScanner,
    required ContentAssembler contentAssembler,
    required Ref ref,
  })  : _fileScanner = fileScanner,
        _contentAssembler = contentAssembler,
        _ref = ref,
        super(const SelectionState());
  final FileScanner _fileScanner;
  final ContentAssembler _contentAssembler;
  // ignore: unused_field
  final Ref _ref;

  void setSupportedExtensions(Map<String, FileCategory> extensions) {
    state = state.copyWith(supportedExtensions: extensions);
    _updateCombinedContent();
  }

  Future<void> addFiles(List<String> filePaths) async {
    bool newFilesAdded = false;
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
        error: null,
        clearError: true,
        isProcessing: true,  // Show processing state
      );
      
      // Load file contents (this will also update combined content and set isProcessing to false)
      await loadFileContents();
    } else {
      state = state.copyWith(
          error: null, clearError: true); // Still clear error if any
    }
  }

  Future<void> addDirectory(String directoryPath) async {
    state = state.copyWith(isProcessing: true, error: null, clearError: true);
    try {
      final effectiveSupportedExtensions =
          state.supportedExtensions ?? ExtensionCatalog.extensionCategories;
      final foundFiles = await _fileScanner.scanDirectory(
          directoryPath, effectiveSupportedExtensions);

      bool newFilesAdded = false;
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
        _updateCombinedContent();
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
      error: null,
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

    state = state.copyWith(isProcessing: true, error: null, clearError: true);
    try {
      final effectiveSupportedExtensions =
          state.supportedExtensions ?? ExtensionCatalog.extensionCategories;

      final currentFiles = List<ScannedFile>.from(state.allFiles);
      bool changed = false;

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
      _updateCombinedContent(); // This will also update state with new combined content
    } catch (e) {
      state = state.copyWith(error: 'Error loading files: $e');
    } finally {
      state = state.copyWith(isProcessing: false);
    }
  }

  Future<void> copyToClipboard() async {
    String contentToCopy = state.combinedContent;
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
    String contentToSave = state.combinedContent;
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
    state = state.copyWith(isProcessing: true, error: null, clearError: true);
    try {
      final List<XFile> files = await openFiles(
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
    state = state.copyWith(isProcessing: true, error: null, clearError: true);
    try {
      final String? directoryPath = await getDirectoryPath();
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
    state = state.copyWith(error: null, clearError: true);
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
