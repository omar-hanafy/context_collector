import 'dart:io';

import 'package:context_collector/context_collector.dart';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Enhanced UI state management for file selection and content operations
/// Optimized for the new streamlined UI/UX with better performance and state handling
class SelectionCubit with ChangeNotifier {
  SelectionCubit({
    FileScanner? fileScanner,
    ContentAssembler? contentAssembler,
  })  : _fileScanner = fileScanner ?? FileScanner(),
        _contentAssembler = contentAssembler ?? ContentAssembler();

  final FileScanner _fileScanner;
  final ContentAssembler _contentAssembler;

  // Core state
  final List<ScannedFile> _allFiles = [];
  final Set<String> _selectedFilePaths = {};
  bool _isProcessing = false;
  String? _error;
  String _combinedContent = '';
  Map<String, FileCategory>? _supportedExtensions;

  // Performance optimization: Cache expensive computations
  ContentStats? _cachedStats;
  String? _lastStatsComputedForContent;

  // === GETTERS ===
  
  List<ScannedFile> get allFiles => List.unmodifiable(_allFiles);

  List<ScannedFile> get selectedFiles => _allFiles
      .where((file) => _selectedFilePaths.contains(file.fullPath))
      .toList();

  List<ScannedFile> get loadedFiles => _allFiles
      .where((file) => file.content != null)
      .toList();

  List<ScannedFile> get errorFiles => _allFiles
      .where((file) => file.error != null)
      .toList();

  List<ScannedFile> get pendingFiles => _allFiles
      .where((file) => file.content == null && file.error == null)
      .toList();

  bool get isProcessing => _isProcessing;

  String? get error => _error;

  String get combinedContent => _combinedContent;

  int get selectedFilesCount => selectedFiles.length;

  int get totalFilesCount => _allFiles.length;

  bool get hasFiles => _allFiles.isNotEmpty;

  bool get hasSelectedFiles => selectedFiles.isNotEmpty;

  bool get hasLoadedContent => _combinedContent.isNotEmpty;

  /// Get comprehensive file statistics with caching for performance
  ContentStats getStats() {
    // Use cached stats if content hasn't changed
    if (_cachedStats != null && _lastStatsComputedForContent == _combinedContent) {
      return _cachedStats!;
    }

    // Compute fresh stats
    _cachedStats = _contentAssembler.getStats(selectedFiles);
    _lastStatsComputedForContent = _combinedContent;
    return _cachedStats!;
  }

  /// Get file breakdown by status
  Map<String, int> get fileStatusBreakdown => {
    'total': totalFilesCount,
    'selected': selectedFilesCount,
    'loaded': loadedFiles.length,
    'pending': pendingFiles.length,
    'errors': errorFiles.length,
  };

  /// Get files grouped by category
  Map<FileCategory, List<ScannedFile>> get filesByCategory {
    final Map<FileCategory, List<ScannedFile>> grouped = {};
    
    for (final file in _allFiles) {
      final category = file.getCategory(_supportedExtensions) ?? FileCategory.other;
      grouped.putIfAbsent(category, () => []).add(file);
    }
    
    return grouped;
  }

  /// Get selection rate (percentage of files selected)
  double get selectionRate => 
    totalFilesCount > 0 ? selectedFilesCount / totalFilesCount : 0.0;

  /// Get load completion rate (percentage of selected files loaded)
  double get loadCompletionRate {
    final selected = selectedFiles;
    if (selected.isEmpty) return 0.0;
    final loaded = selected.where((f) => f.content != null).length;
    return loaded / selected.length;
  }

  // === CORE OPERATIONS ===

  /// Set the supported extensions (from preferences)
  void setSupportedExtensions(Map<String, FileCategory> extensions) {
    _supportedExtensions = extensions;
    _invalidateCache();
    _updateCombinedContent();
  }

  /// Add files from file paths with improved error handling
  void addFiles(List<String> filePaths) {
    if (filePaths.isEmpty) return;
    
    _error = null;
    bool newFilesAdded = false;
    final errors = <String>[];

    for (final filePath in filePaths) {
      try {
        final file = File(filePath);
        if (file.existsSync()) {
          final scannedFile = ScannedFile.fromFile(file);
          if (!_allFiles.any((f) => f.fullPath == scannedFile.fullPath)) {
            _allFiles.add(scannedFile);
            _selectedFilePaths.add(scannedFile.fullPath); // Auto-select new files
            newFilesAdded = true;
          }
        } else {
          errors.add('File not found: $filePath');
        }
      } catch (e) {
        errors.add('Error processing $filePath: $e');
      }
    }

    if (errors.isNotEmpty) {
      _error = 'Some files could not be added:\n${errors.join('\n')}';
    }

    if (newFilesAdded) {
      _invalidateCache();
      notifyListeners();
      _updateCombinedContent();
      // Auto-load content for newly added files
      loadFileContents();
    } else {
      notifyListeners();
    }
  }

  /// Add a directory by scanning it with enhanced progress tracking
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
        _invalidateCache();
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
    _invalidateCache();
    notifyListeners();
    _updateCombinedContent();
  }

  /// Remove multiple files efficiently
  void removeFiles(List<ScannedFile> filesToRemove) {
    final pathsToRemove = filesToRemove.map((f) => f.fullPath).toSet();
    _allFiles.removeWhere((f) => pathsToRemove.contains(f.fullPath));
    _selectedFilePaths.removeAll(pathsToRemove);
    _invalidateCache();
    notifyListeners();
    _updateCombinedContent();
  }

  /// Clear all files with confirmation option
  void clearFiles({bool skipConfirmation = false}) {
    _allFiles.clear();
    _selectedFilePaths.clear();
    _combinedContent = '';
    _error = null;
    _invalidateCache();
    notifyListeners();
  }

  /// Toggle selection for a file
  void toggleFileSelection(ScannedFile file) {
    if (_selectedFilePaths.contains(file.fullPath)) {
      _selectedFilePaths.remove(file.fullPath);
    } else {
      _selectedFilePaths.add(file.fullPath);
    }
    _invalidateCache();
    notifyListeners();
    _updateCombinedContent();
  }

  /// Select all files
  void selectAll() {
    _selectedFilePaths
      ..clear()
      ..addAll(_allFiles.map((f) => f.fullPath));
    _invalidateCache();
    notifyListeners();
    _updateCombinedContent();
  }

  /// Deselect all files
  void deselectAll() {
    _selectedFilePaths.clear();
    _invalidateCache();
    notifyListeners();
    _updateCombinedContent();
  }

  /// Select files by category
  void selectByCategory(FileCategory category) {
    final categoryFiles = _allFiles
        .where((f) => f.getCategory(_supportedExtensions) == category)
        .map((f) => f.fullPath);
    _selectedFilePaths.addAll(categoryFiles);
    _invalidateCache();
    notifyListeners();
    _updateCombinedContent();
  }

  /// Select files by status (loaded, pending, error)
  void selectByStatus(String status) {
    List<ScannedFile> targetFiles;
    
    switch (status.toLowerCase()) {
      case 'loaded':
        targetFiles = loadedFiles;
      case 'pending':
        targetFiles = pendingFiles;
      case 'error':
        targetFiles = errorFiles;
      default:
        return;
    }

    final pathsToSelect = targetFiles.map((f) => f.fullPath);
    _selectedFilePaths.addAll(pathsToSelect);
    _invalidateCache();
    notifyListeners();
    _updateCombinedContent();
  }

  /// Load content for all selected files with progress tracking
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

      int loadedCount = 0;
      for (final file in filesToLoad) {
        final index = _allFiles.indexWhere((f) => f.fullPath == file.fullPath);
        if (index != -1) {
          final updatedFile =
              await _fileScanner.loadFileContent(file, supportedExtensions);
          _allFiles[index] = updatedFile;
          loadedCount++;
          
          // Notify progress periodically for large batches
          if (loadedCount % 10 == 0 || loadedCount == filesToLoad.length) {
            notifyListeners();
          }
        }
      }

      _invalidateCache();
      _updateCombinedContent();
    } catch (e) {
      _error = 'Error loading files: $e';
    } finally {
      _setProcessing(false);
    }
  }

  /// Load content for a specific file
  Future<void> loadFileContent(ScannedFile file) async {
    final index = _allFiles.indexWhere((f) => f.fullPath == file.fullPath);
    if (index == -1) return;

    _setProcessing(true);
    try {
      final supportedExtensions =
          _supportedExtensions ?? ExtensionCatalog.extensionCategories;
      final updatedFile = await _fileScanner.loadFileContent(file, supportedExtensions);
      _allFiles[index] = updatedFile;
      _invalidateCache();
      _updateCombinedContent();
      notifyListeners();
    } catch (e) {
      _error = 'Error loading file ${file.name}: $e';
      notifyListeners();
    } finally {
      _setProcessing(false);
    }
  }

  /// Reload content for files with errors
  Future<void> retryErrorFiles() async {
    final errorFiles = this.errorFiles;
    if (errorFiles.isEmpty) return;

    // Clear errors before retrying
    for (int i = 0; i < _allFiles.length; i++) {
      if (_allFiles[i].error != null) {
        _allFiles[i] = _allFiles[i].copyWith(error: null);
      }
    }

    _setProcessing(true);
    try {
      final supportedExtensions =
          _supportedExtensions ?? ExtensionCatalog.extensionCategories;

      for (final file in errorFiles) {
        final index = _allFiles.indexWhere((f) => f.fullPath == file.fullPath);
        if (index != -1) {
          final updatedFile = await _fileScanner.loadFileContent(file, supportedExtensions);
          _allFiles[index] = updatedFile;
        }
      }

      _invalidateCache();
      _updateCombinedContent();
    } catch (e) {
      _error = 'Error retrying failed files: $e';
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
              'txt', 'dart', 'py', 'js', 'ts', 'jsx', 'tsx', 'java', 'kt',
              'swift', 'cpp', 'c', 'h', 'hpp', 'cs', 'php', 'rb', 'go', 'rs',
              'html', 'css', 'scss', 'json', 'xml', 'yaml', 'yml', 'md', 'sql'
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

  /// Filter files by search term
  List<ScannedFile> searchFiles(String searchTerm) {
    if (searchTerm.isEmpty) return allFiles;
    
    final lowercaseSearch = searchTerm.toLowerCase();
    return _allFiles.where((file) {
      return file.name.toLowerCase().contains(lowercaseSearch) ||
             file.fullPath.toLowerCase().contains(lowercaseSearch) ||
             file.extension.toLowerCase().contains(lowercaseSearch);
    }).toList();
  }

  /// Get files sorted by various criteria
  List<ScannedFile> getSortedFiles({
    required String sortBy, // 'name', 'size', 'date', 'type', 'status'
    bool ascending = true,
  }) {
    final files = List<ScannedFile>.from(_allFiles);
    
    files.sort((a, b) {
      int comparison;
      
      switch (sortBy) {
        case 'name':
          comparison = a.name.compareTo(b.name);
        case 'size':
          comparison = a.size.compareTo(b.size);
        case 'date':
          comparison = a.lastModified.compareTo(b.lastModified);
        case 'type':
          comparison = a.extension.compareTo(b.extension);
        case 'status':
          comparison = _getStatusPriority(a).compareTo(_getStatusPriority(b));
        default:
          comparison = a.name.compareTo(b.name);
      }
      
      return ascending ? comparison : -comparison;
    });
    
    return files;
  }

  /// Export file list with metadata
  Future<void> exportFileList() async {
    try {
      final buffer = StringBuffer();
      buffer.writeln('Context Collector File List');
      buffer.writeln('Generated: ${DateTime.now().toIso8601String()}');
      buffer.writeln('Total Files: ${totalFilesCount}');
      buffer.writeln('Selected Files: ${selectedFilesCount}');
      buffer.writeln();

      for (final file in _allFiles) {
        buffer.writeln('File: ${file.name}');
        buffer.writeln('  Path: ${file.fullPath}');
        buffer.writeln('  Size: ${file.sizeFormatted}');
        buffer.writeln('  Extension: ${file.extension}');
        buffer.writeln('  Modified: ${file.lastModified.toIso8601String()}');
        buffer.writeln('  Selected: ${isFileSelected(file)}');
        buffer.writeln('  Status: ${_getFileStatus(file)}');
        buffer.writeln();
      }

      final filePath = await getSaveLocation(
        suggestedName: 'file_list_${DateTime.now().millisecondsSinceEpoch}.txt',
        acceptedTypeGroups: [
          const XTypeGroup(
            label: 'Text files',
            extensions: ['txt'],
          ),
        ],
      );

      if (filePath != null) {
        final file = File(filePath.path);
        await file.writeAsString(buffer.toString());
      }
    } catch (e) {
      _error = 'Error exporting file list: $e';
      notifyListeners();
    }
  }

  // === PRIVATE METHODS ===

  void _setProcessing(bool processing) {
    _isProcessing = processing;
    notifyListeners();
  }

  void _updateCombinedContent() {
    final selectedFilesList = selectedFiles;

    // Use the content assembler service to build the combined content
    _contentAssembler.buildMerged(selectedFilesList).then((content) {
      _combinedContent = content;
      _invalidateCache(); // Invalidate stats cache when content changes
      notifyListeners();
    });
  }

  void _invalidateCache() {
    _cachedStats = null;
    _lastStatsComputedForContent = null;
  }

  int _getStatusPriority(ScannedFile file) {
    if (file.error != null) return 3; // Errors last
    if (file.content != null) return 1; // Loaded first
    return 2; // Pending in middle
  }

  String _getFileStatus(ScannedFile file) {
    if (file.error != null) return 'Error: ${file.error}';
    if (file.content != null) return 'Loaded';
    if (!file.supportsText(_supportedExtensions)) return 'Unsupported';
    return 'Ready';
  }

  // === PERFORMANCE OPTIMIZATIONS ===

  /// Batch update multiple file selections efficiently
  void batchUpdateSelections(Map<String, bool> updates) {
    bool hasChanges = false;
    
    for (final entry in updates.entries) {
      final filePath = entry.key;
      final shouldSelect = entry.value;
      
      if (shouldSelect && !_selectedFilePaths.contains(filePath)) {
        _selectedFilePaths.add(filePath);
        hasChanges = true;
      } else if (!shouldSelect && _selectedFilePaths.contains(filePath)) {
        _selectedFilePaths.remove(filePath);
        hasChanges = true;
      }
    }
    
    if (hasChanges) {
      _invalidateCache();
      notifyListeners();
      _updateCombinedContent();
    }
  }

  /// Optimized method for checking if all files are selected
  bool get areAllFilesSelected => _selectedFilePaths.length == _allFiles.length;

  /// Optimized method for checking if no files are selected
  bool get areNoFilesSelected => _selectedFilePaths.isEmpty;

  /// Get memory usage estimation for debugging
  Map<String, dynamic> get memoryUsage => {
    'totalFiles': _allFiles.length,
    'selectedFiles': _selectedFilePaths.length,
    'combinedContentSize': _combinedContent.length,
    'estimatedMemoryMB': (_combinedContent.length / (1024 * 1024)).toStringAsFixed(2),
  };

  @override
  void dispose() {
    _invalidateCache();
    super.dispose();
  }
}