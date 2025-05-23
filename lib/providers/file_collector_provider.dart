import 'dart:io';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../config/file_extensions.dart';
import '../models/file_item.dart';
import 'settings_provider.dart';

class FileCollectorProvider with ChangeNotifier {
  final List<FileItem> _files = [];
  bool _isProcessing = false;
  String? _error;
  String _combinedContent = '';
  SettingsProvider? _settingsProvider;

  List<FileItem> get files => List.unmodifiable(_files);
  bool get isProcessing => _isProcessing;
  String? get error => _error;
  String get combinedContent => _combinedContent;

  List<FileItem> get selectedFiles =>
      _files.where((f) => f.isSelected).toList();

  int get selectedFilesCount => selectedFiles.length;
  int get totalFilesCount => _files.length;

  bool get hasFiles => _files.isNotEmpty;
  bool get hasSelectedFiles => selectedFiles.isNotEmpty;

  set settingsProvider(SettingsProvider settingsProvider) {
    _settingsProvider = settingsProvider;
  }

  Map<String, FileCategory>? get _activeExtensions =>
      _settingsProvider?.activeExtensions;

  void addFiles(List<String> filePaths) {
    _error = null;
    bool newFilesAdded = false;

    for (final filePath in filePaths) {
      final file = File(filePath);
      if (file.existsSync()) {
        final fileItem = FileItem.fromFile(file);
        if (!_files.contains(fileItem)) {
          _files.add(fileItem); // By default, isSelected is true in FileItem
          newFilesAdded = true;
        }
      }
    }

    if (newFilesAdded) {
      notifyListeners();
      _updateCombinedContent(); // Update content for newly added files (references)
      loadFileContents(); // Automatically load content for new files
    } else {
      notifyListeners(); // Still notify if no new files but paths were processed
    }
  }

  Future<void> addDirectory(String directoryPath) async {
    _error = null;
    bool newFilesAdded = false;
    try {
      final directory = Directory(directoryPath);
      if (!directory.existsSync()) {
        _error = 'Directory not found: $directoryPath';
        notifyListeners();
        return;
      }

      final activeExtensions =
          _activeExtensions ?? FileExtensionConfig.extensionCategories;
      final foundFilePaths = <String>[];

      await for (final entity
          in directory.list(recursive: true, followLinks: false)) {
        if (entity is File) {
          final extension = entity.path.split('.').last.toLowerCase();
          if (activeExtensions.containsKey('.$extension')) {
            foundFilePaths.add(entity.path);
          }
        }
      }

      if (foundFilePaths.isNotEmpty) {
        // Temporarily collect files to check which are truly new
        final tempNewFiles = <FileItem>[];
        for (final filePath in foundFilePaths) {
          final file = File(filePath);
          if (file.existsSync()) {
            final fileItem = FileItem.fromFile(file);
            if (!_files.contains(fileItem)) {
              tempNewFiles.add(fileItem);
            }
          }
        }

        if (tempNewFiles.isNotEmpty) {
          _files.addAll(tempNewFiles);
          newFilesAdded = true;
        }
      }
    } catch (e) {
      _error = 'Error scanning directory: $e';
    }

    if (newFilesAdded) {
      notifyListeners();
      _updateCombinedContent();
      await loadFileContents(); // Automatically load content
    } else {
      notifyListeners(); // Notify for errors or if no new files were found
    }
  }

  void removeFile(FileItem fileItem) {
    _files.remove(fileItem);
    notifyListeners();
    _updateCombinedContent();
  }

  void clearFiles() {
    _files.clear();
    _combinedContent = '';
    _error = null;
    notifyListeners();
  }

  void toggleFileSelection(FileItem fileItem) {
    final index = _files.indexOf(fileItem);
    if (index != -1) {
      _files[index] = fileItem.copyWith(isSelected: !fileItem.isSelected);
      notifyListeners();
      _updateCombinedContent();
    }
  }

  void selectAll() {
    for (int i = 0; i < _files.length; i++) {
      _files[i] = _files[i].copyWith(isSelected: true);
    }
    notifyListeners();
    _updateCombinedContent();
  }

  void deselectAll() {
    for (int i = 0; i < _files.length; i++) {
      _files[i] = _files[i].copyWith(isSelected: false);
    }
    notifyListeners();
    _updateCombinedContent();
  }

  Future<void> loadFileContents() async {
    // Only process files that are selected, have no content, and are not already loading
    final filesToLoad = _files
        .where((f) => f.isSelected && f.content == null && !f.isLoading)
        .toList();

    if (filesToLoad.isEmpty) return;

    _isProcessing = true;
    _error = null;
    notifyListeners();

    try {
      bool contentChanged = false;
      for (final fileToLoad in filesToLoad) {
        final index = _files.indexOf(fileToLoad);
        if (index != -1) {
          // Should always be true here
          _files[index] = _files[index].copyWith(isLoading: true);
          // No need to notify here, will notify after each load or batch at end

          final updatedFile = await _files[index].loadContent(
            activeExtensions: _activeExtensions,
          );
          _files[index] = updatedFile;
          if (updatedFile.content != null || updatedFile.error != null) {
            contentChanged = true;
          }
          notifyListeners(); // Notify after each file is processed to update UI progressively
        }
      }

      if (contentChanged) {
        _updateCombinedContent(); // This will re-generate the combined text
      }
    } catch (e) {
      _error = 'Error loading files: $e';
    } finally {
      _isProcessing = false;
      notifyListeners(); // Final notification for isProcessing and any errors
    }
  }

  void _updateCombinedContent() {
    final buffer = StringBuffer()
      ..writeln('# Context Collection')
      ..writeln('Generated on: ${DateTime.now().toIso8601String()}')
      ..writeln('Total selected files: ${selectedFiles.length}')
      ..writeln();

    for (final file in selectedFiles) {
      buffer
        ..writeln('=' * 80)
        ..writeln(file.generateReference())
        ..writeln('=' * 80);

      if (file.isLoading) {
        buffer.writeln('LOADING CONTENT...');
      } else if (file.content != null) {
        buffer.writeln(file.content);
      } else if (file.error != null) {
        buffer.writeln('ERROR: ${file.error}');
      } else if (!file.isTextFileWithSettings(_activeExtensions)) {
        buffer.writeln('SKIPPED: Binary file');
      } else {
        buffer.writeln('PENDING: Content not loaded (or file is empty)');
      }

      buffer
        ..writeln()
        ..writeln();
    }

    _combinedContent = buffer.toString();
  }

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
          const XTypeGroup(
            label: 'All files',
          ),
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

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
