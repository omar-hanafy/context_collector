import 'dart:io';

import 'package:cross_file/cross_file.dart';
import 'package:desktop_drop/desktop_drop.dart';
import 'package:path/path.dart' as path;

import '../models/scan_result.dart';
import '../models/scanned_file.dart';
import 'file_scanner.dart';

/// Handles file/directory drop operations with a fully non-blocking,
/// incremental pipeline.
class DropHandler {
  DropHandler({required this.fileScanner});

  final FileScanner fileScanner;

  /// Processes dropped items incrementally, reporting files as they are found
  /// without blocking the UI thread.
  Future<void> processDroppedItemsIncremental(
    List<XFile> items, {
    required Set<String> blacklist,
    required ScanSource source, // Pass source for context
    required void Function(ScannedFile file) onFileFound,
    required void Function(List<String> sourcePaths) onScanComplete,
  }) async {
    final processedPaths = <String>{};
    final sourcePaths = <String>{};

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
          final parentDir = path.dirname(itemPath);
          filesByDirectory.putIfAbsent(parentDir, () => []).add(itemPath);
        }
      }
    }

    // Process directories incrementally
    for (final dirPath in directories) {
      sourcePaths.add(dirPath);
      await fileScanner.scanDirectoryIncremental(
        dirPath,
        blacklist: blacklist,
        source: source,
        onFileFound: (file) {
          if (processedPaths.add(file.fullPath)) {
            onFileFound(file);
          }
        },
      );
    }

    // Process individual files incrementally and asynchronously
    for (final entry in filesByDirectory.entries) {
      sourcePaths.add(entry.key);
      for (final filePath in entry.value) {
        if (!processedPaths.add(filePath)) continue;

        final fileName = path.basename(filePath);
        final isBlacklisted = blacklist.any(
          (pattern) => fileName.toLowerCase().endsWith(pattern.toLowerCase()),
        );

        if (isBlacklisted) continue;

        try {
          // Use the SYNC factory for instant performance
          final file = ScannedFile.fromFile(
            File(filePath),
            relativePath: fileName,
            source: source,
          );
          onFileFound(file);
        } catch (_) {
          // Handle cases where file might be inaccessible
        }
      }
    }

    onScanComplete(sourcePaths.toList());
  }

  // Helper methods _isVSCodeDirectoryDrop and _extractVSCodeDirectory remain the same...
  /// Check if this is a VS Code directory drop
  Future<bool> _isVSCodeDirectoryDrop(String filePath) async {
    if (!filePath.contains('/tmp/Drops/')) return false;

    try {
      final content = await File(filePath).readAsString();
      return content.contains('<script>start("') && content.contains('addRow(');
    } catch (_) {
      return false;
    }
  }

  /// Extract directory path from VS Code drop
  Future<String?> _extractVSCodeDirectory(String filePath) async {
    try {
      final content = await File(filePath).readAsString();
      final match = RegExp(
        r'<script>start\("([^"]+)"\);</script>',
      ).firstMatch(content);
      final dirPath = match?.group(1);

      if (dirPath != null && Directory(dirPath).existsSync()) {
        return dirPath;
      }
    } catch (_) {}

    return null;
  }
}
