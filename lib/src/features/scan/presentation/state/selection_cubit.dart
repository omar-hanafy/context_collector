import 'dart:io';

import 'package:context_collector/context_collector.dart';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// UI state management for file selection and content operations
/// This cubit handles only UI-related state and delegates disk operations to services
class SelectionCubit with ChangeNotifier {
  SelectionCubit({
    FileScanner? fileScanner,
    ContentAssembler? contentAssembler,
  })  : _fileScanner = fileScanner ?? FileScanner(),
        _contentAssembler = contentAssembler ?? ContentAssembler();

  final FileScanner _fileScanner;
  final ContentAssembler _contentAssembler;

  // State
  final List<ScannedFile> _allFiles = [];
  final Set<String> _selectedFilePaths = {};
  bool _isProcessing = false;
  String? _error;
  String _combinedContent = '';
  Map<String, FileCategory>? _supportedExtensions;

  // Getters
  List<ScannedFile> get allFiles => List.unmodifiable(_allFiles);

  List<ScannedFile> get selectedFiles => _allFiles
      .where((file) => _selectedFilePaths.contains(file.fullPath))
      .toList();

  bool get isProcessing => _isProcessing;

  String? get error => _error;

  String get combinedContent => _combinedContent;

  int get selectedFilesCount => selectedFiles.length;

  int get totalFilesCount => _allFiles.length;

  bool get hasFiles => _allFiles.isNotEmpty;

  bool get hasSelectedFiles => selectedFiles.isNotEmpty;

  /// Set the supported extensions (from preferences)
  void setSupportedExtensions(Map<String, FileCategory> extensions) {
    _supportedExtensions = extensions;
    _updateCombinedContent();
  }

  /// Add files from file paths
  void addFiles(List<String> filePaths) {
    _error = null;
    bool newFilesAdded = false;

    for (final filePath in filePaths) {
      final file = File(filePath);
      if (file.existsSync()) {
        final scannedFile = ScannedFile.fromFile(file);
        if (!_allFiles.any((f) => f.fullPath == scannedFile.fullPath)) {
          _allFiles.add(scannedFile);
          _selectedFilePaths.add(scannedFile.fullPath); // Auto-select new files
          newFilesAdded = true;
        }
      }
    }

    if (newFilesAdded) {
      notifyListeners();
      _updateCombinedContent();
      // Auto-load content for newly added files
      loadFileContents();
    } else {
      notifyListeners();
    }
  }

  /// Add a directory by scanning it
  Future<void> addDirectory(String directoryPath) async {
    _error = null;
    _setProcessing(true);

    try {
      final supportedExtensions =
          _supportedExtensions ?? ExtensionCatalog.extensionCategories;
      final foundFiles =
          await _fileScanner.scanDirectory(directoryPath, supportedExtensions);

      bool newFilesAdded = false;
      for (final file in foundFiles) {
        if (!_allFiles.any((f) => f.fullPath == file.fullPath)) {
          _allFiles.add(file);
          _selectedFilePaths.add(file.fullPath); // Auto-select new files
          newFilesAdded = true;
        }
      }

      if (newFilesAdded) {
        _updateCombinedContent();
        // Auto-load content for newly added files
        await loadFileContents();
      }
    } catch (e) {
      _error = 'Error scanning directory: $e';
    } finally {
      _setProcessing(false);
    }
  }

  /// Remove a file from the collection
  void removeFile(ScannedFile file) {
    _allFiles.removeWhere((f) => f.fullPath == file.fullPath);
    _selectedFilePaths.remove(file.fullPath);
    notifyListeners();
    _updateCombinedContent();
  }

  /// Clear all files
  void clearFiles() {
    _allFiles.clear();
    _selectedFilePaths.clear();
    _combinedContent = '';
    _error = null;
    notifyListeners();
  }

  /// Toggle selection for a file
  void toggleFileSelection(ScannedFile file) {
    if (_selectedFilePaths.contains(file.fullPath)) {
      _selectedFilePaths.remove(file.fullPath);
    } else {
      _selectedFilePaths.add(file.fullPath);
    }
    notifyListeners();
    _updateCombinedContent();
  }

  /// Select all files
  void selectAll() {
    _selectedFilePaths
      ..clear()
      ..addAll(_allFiles.map((f) => f.fullPath));
    notifyListeners();
    _updateCombinedContent();
  }

  /// Deselect all files
  void deselectAll() {
    _selectedFilePaths.clear();
    notifyListeners();
    _updateCombinedContent();
  }

  /// Load content for all selected files
  Future<void> loadFileContents() async {
    final filesToLoad = selectedFiles
        .where((f) => f.content == null && f.error == null)
        .toList();

    if (filesToLoad.isEmpty) return;

    _setProcessing(true);
    _error = null;

    try {
      final supportedExtensions =
          _supportedExtensions ?? ExtensionCatalog.extensionCategories;

      for (final file in filesToLoad) {
        final index = _allFiles.indexWhere((f) => f.fullPath == file.fullPath);
        if (index != -1) {
          final updatedFile =
              await _fileScanner.loadFileContent(file, supportedExtensions);
          _allFiles[index] = updatedFile;
          notifyListeners(); // Update UI after each file loads
        }
      }

      _updateCombinedContent();
    } catch (e) {
      _error = 'Error loading files: $e';
    } finally {
      _setProcessing(false);
    }
  }

  /// Copy combined content to clipboard
  Future<void> copyToClipboard() async {
    if (_combinedContent.isEmpty) {
      await loadFileContents();
    }

    try {
      await Clipboard.setData(ClipboardData(text: _combinedContent));
    } catch (e) {
      _error = 'Error copying to clipboard: $e';
      notifyListeners();
    }
  }

  /// Save combined content to file
  Future<void> saveToFile() async {
    if (_combinedContent.isEmpty) {
      await loadFileContents();
    }

    try {
      final fileName =
          'context_collection_${DateTime.now().millisecondsSinceEpoch}.txt';

      final filePath = await getSaveLocation(
        suggestedName: fileName,
        acceptedTypeGroups: [
          const XTypeGroup(
            label: 'Text files',
            extensions: ['txt'],
          ),
        ],
      );

      if (filePath != null) {
        final file = File(filePath.path);
        await file.writeAsString(_combinedContent);
      }
    } catch (e) {
      _error = 'Error saving file: $e';
      notifyListeners();
    }
  }

  /// Pick files using file picker
  Future<void> pickFiles() async {
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
        addFiles(filePaths);
      }
    } catch (e) {
      _error = 'Error picking files: $e';
      notifyListeners();
    }
  }

  /// Pick directory using directory picker
  Future<void> pickDirectory() async {
    try {
      final String? directoryPath = await getDirectoryPath();
      if (directoryPath != null) {
        await addDirectory(directoryPath);
      }
    } catch (e) {
      _error = 'Error picking directory: $e';
      notifyListeners();
    }
  }

  /// Clear error state
  void clearError() {
    _error = null;
    notifyListeners();
  }

  /// Check if a file is selected
  bool isFileSelected(ScannedFile file) {
    return _selectedFilePaths.contains(file.fullPath);
  }

  // Private methods
  void _setProcessing(bool processing) {
    _isProcessing = processing;
    notifyListeners();
  }

  void _updateCombinedContent() {
    final selectedFilesList = selectedFiles;

    // Use the content assembler service to build the combined content
    _contentAssembler.buildMerged(selectedFilesList).then((content) {
      _combinedContent = content;
      notifyListeners();
    });
  }
}
