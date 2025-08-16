import 'dart:io';
import 'dart:math';

import 'package:cross_file/cross_file.dart';
import 'package:desktop_drop/desktop_drop.dart';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;

import '../models/scan_result.dart';
import '../models/scanned_file.dart';

/// Unified service for all file operations - scanning, dropping, and file operations
/// Consolidates FileScanner, DropHandler, and FileOperationsService
class UnifiedFileService {
  UnifiedFileService._();

  //============================================================================
  // FILE SCANNING (from FileScanner)
  //============================================================================

  /// Scans a directory incrementally
  static Future<void> scanDirectory({
    required String directoryPath,
    required Set<String> blacklist,
    required void Function(ScannedFile file) onFileFound,
    required ScanSource source,
  }) async {
    final directory = Directory(directoryPath);
    if (!directory.existsSync()) {
      throw FileSystemException('Directory not found: $directoryPath');
    }

    await for (final entity in directory.list(
      recursive: true,
      followLinks: false,
    )) {
      if (entity is! File) continue;

      final fileName = p.basename(entity.path);
      
      // Skip hidden files
      if (fileName.startsWith('.')) continue;
      
      // Check blacklist
      if (blacklist.any((pattern) => 
        fileName.toLowerCase().endsWith(pattern.toLowerCase())
      )) continue;

      try {
        final relativePath = p.relative(entity.path, from: directoryPath);
        final scannedFile = ScannedFile.fromFile(
          entity,
          relativePath: relativePath,
          source: source,
        );
        onFileFound(scannedFile);
      } catch (_) {
        // Skip problematic files
      }
    }
  }

  /// Creates a virtual file
  static ScannedFile createVirtualFile({
    required String name,
    required String content,
    String? virtualPath,
  }) {
    final fullPath = virtualPath ?? '/$name';
    final normalizedPath = p.normalize(fullPath);
    final id = 'virtual_${normalizedPath.hashCode.toUnsigned(32).toRadixString(16)}';

    return ScannedFile(
      id: id,
      name: name,
      fullPath: fullPath,
      relativePath: virtualPath?.replaceFirst('/', '') ?? name,
      extension: p.extension(name).toLowerCase(),
      size: content.length,
      lastModified: DateTime.now(),
      source: ScanSource.manual,
      isVirtual: true,
      content: content,
      virtualContent: content,
    );
  }

  /// Loads file content
  static Future<ScannedFile> loadFileContent(ScannedFile file) async {
    if (file.isVirtual) return file;

    try {
      final fileEntity = File(file.fullPath);
      if (!fileEntity.existsSync()) {
        return file.copyWith(error: 'File not found on disk');
      }
      final content = await fileEntity.readAsString();
      return file.copyWith(content: content);
    } catch (e) {
      return file.copyWith(
        error: 'Cannot read file: Likely binary or unsupported format',
      );
    }
  }

  //============================================================================
  // DROP HANDLING (from DropHandler)
  //============================================================================

  /// Processes dropped items
  static Future<void> processDroppedItems({
    required List<XFile> items,
    required Set<String> blacklist,
    required ScanSource source,
    required void Function(ScannedFile file) onFileFound,
    required void Function(List<String> sourcePaths) onScanComplete,
  }) async {
    final processedPaths = <String>{};
    final sourcePaths = <String>{};
    
    // Remove duplicates
    final uniquePaths = <String>{};
    final uniqueItems = <XFile>[];
    for (final item in items) {
      if (!uniquePaths.contains(item.path)) {
        uniquePaths.add(item.path);
        uniqueItems.add(item);
      }
    }

    final filesByDirectory = <String, List<String>>{};
    final directories = <String>[];

    for (final item in uniqueItems) {
      final itemPath = item.path;

      // Check for VS Code directory drop
      if (await _isVSCodeDirectoryDrop(itemPath)) {
        final dirPath = await _extractVSCodeDirectory(itemPath);
        if (dirPath != null) directories.add(dirPath);
        continue;
      }

      if (item is DropItemDirectory) {
        directories.add(itemPath);
      } else {
        final entityType = FileSystemEntity.typeSync(itemPath);
        if (entityType == FileSystemEntityType.directory) {
          directories.add(itemPath);
        } else if (entityType == FileSystemEntityType.file) {
          final parentDir = p.dirname(itemPath);
          filesByDirectory.putIfAbsent(parentDir, () => []).add(itemPath);
        }
      }
    }

    // Process directories
    for (final dirPath in directories) {
      sourcePaths.add(dirPath);
      await scanDirectory(
        directoryPath: dirPath,
        blacklist: blacklist,
        source: source,
        onFileFound: (file) {
          if (processedPaths.add(file.fullPath)) {
            onFileFound(file);
          }
        },
      );
    }

    // Process individual files
    for (final entry in filesByDirectory.entries) {
      sourcePaths.add(entry.key);
      for (final filePath in entry.value) {
        if (!processedPaths.add(filePath)) continue;

        final fileName = p.basename(filePath);
        if (blacklist.any((pattern) => 
          fileName.toLowerCase().endsWith(pattern.toLowerCase())
        )) continue;

        try {
          final file = ScannedFile.fromFile(
            File(filePath),
            relativePath: fileName,
            source: source,
          );
          onFileFound(file);
        } catch (_) {}
      }
    }

    onScanComplete(sourcePaths.toList());
  }

  static Future<bool> _isVSCodeDirectoryDrop(String filePath) async {
    if (!filePath.contains('/tmp/Drops/')) return false;
    try {
      final content = await File(filePath).readAsString();
      return content.contains('<script>start("') && content.contains('addRow(');
    } catch (_) {
      return false;
    }
  }

  static Future<String?> _extractVSCodeDirectory(String filePath) async {
    try {
      final content = await File(filePath).readAsString();
      final match = RegExp(r'<script>start\("([^"]+)"\);</script>').firstMatch(content);
      final dirPath = match?.group(1);
      if (dirPath != null && Directory(dirPath).existsSync()) {
        return dirPath;
      }
    } catch (_) {}
    return null;
  }

  //============================================================================
  // FILE OPERATIONS (from FileOperationsService)
  //============================================================================

  /// Saves content to file
  static Future<void> saveToFile(String content) async {
    if (content.isEmpty) {
      throw ArgumentError('No content to save');
    }

    final fileName = 'context_collection_${DateTime.now().millisecondsSinceEpoch}.md';
    final filePath = await getSaveLocation(suggestedName: fileName);
    if (filePath != null) {
      await File(filePath.path).writeAsString(content);
    }
  }

  /// Copies text to clipboard
  static Future<void> copyToClipboard(String text) async {
    if (text.isEmpty) {
      throw ArgumentError('No content to copy');
    }
    await Clipboard.setData(ClipboardData(text: text));
  }

  /// Copies full paths to clipboard
  static Future<void> copyFullPaths(List<ScannedFile> files) async {
    final realFiles = files.where((f) => !f.isVirtual).toList();
    if (realFiles.isEmpty) {
      throw ArgumentError('No real files selected to copy paths');
    }

    final paths = realFiles.map((f) => f.fullPath).toList()..sort();
    await copyToClipboard(paths.join('\n'));
  }

  /// Copies AI-formatted paths to clipboard
  static Future<void> copyAiPaths(List<ScannedFile> files) async {
    final realFiles = files.where((f) => !f.isVirtual).toList();
    if (realFiles.isEmpty) {
      throw ArgumentError('No real files selected to copy AI paths');
    }

    final aiPaths = <String>[];
    final commonBasePath = findCommonBasePath(
      realFiles.map((f) => f.fullPath).toList(),
    );

    for (final file in realFiles) {
      final relative = p.relative(file.fullPath, from: commonBasePath);
      aiPaths.add('@${relative.replaceAll(r'\', '/')}');
    }

    aiPaths.sort();
    await copyToClipboard(aiPaths.join('\n'));
  }

  /// Finds common base path
  static String findCommonBasePath(List<String> paths) {
    if (paths.isEmpty) return '';
    if (paths.length == 1) return p.dirname(paths.first);

    final componentsList = paths.map((path) => p.split(path)).toList();
    final minLength = componentsList.map((c) => c.length).reduce(min);
    final commonComponents = <String>[];
    
    for (int i = 0; i < minLength - 1; i++) {
      final component = componentsList[0][i];
      if (componentsList.every((components) => components[i] == component)) {
        commonComponents.add(component);
      } else {
        break;
      }
    }

    return p.joinAll(commonComponents);
  }

  /// Validates paths
  static Future<PathValidationResult> validatePaths(
    List<String> paths,
    Set<String> existingPaths,
  ) async {
    final validFiles = <XFile>[];
    final errorPaths = <String>[];
    final duplicatePaths = <String>[];

    await Future.wait(
      paths.map((path) async {
        if (existingPaths.contains(path)) {
          duplicatePaths.add(path);
          return;
        }
        try {
          final type = FileSystemEntity.typeSync(path);
          if (type != FileSystemEntityType.notFound) {
            validFiles.add(XFile(path));
          } else {
            errorPaths.add(path);
          }
        } catch (_) {
          errorPaths.add(path);
        }
      }),
    );

    return PathValidationResult(
      validFiles: validFiles,
      errorPaths: errorPaths,
      duplicatePaths: duplicatePaths,
    );
  }

  /// Builds paste summary
  static String buildPasteSummary(PathValidationResult result) {
    final summary = <String>[];
    if (result.validFiles.isNotEmpty) {
      summary.add('${result.validFiles.length} new items added');
    }
    if (result.duplicatePaths.isNotEmpty) {
      summary.add('${result.duplicatePaths.length} already exist');
    }
    if (result.errorPaths.isNotEmpty) {
      summary.add('${result.errorPaths.length} not found');
    }
    return summary.join(' • ');
  }
}

/// Result of path validation
class PathValidationResult {
  const PathValidationResult({
    required this.validFiles,
    required this.errorPaths,
    required this.duplicatePaths,
  });

  final List<XFile> validFiles;
  final List<String> errorPaths;
  final List<String> duplicatePaths;

  bool get hasValidFiles => validFiles.isNotEmpty;
  bool get hasErrors => errorPaths.isNotEmpty;
  bool get hasDuplicates => duplicatePaths.isNotEmpty;
  bool get isEmpty => !hasValidFiles && !hasErrors && !hasDuplicates;
}