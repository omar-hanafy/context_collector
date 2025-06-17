import 'dart:io';

import 'package:cross_file/cross_file.dart';
import 'package:desktop_drop/desktop_drop.dart';
import 'package:path/path.dart' as path;

import '../models/scan_result.dart';
import '../models/scanned_file.dart';
import 'file_scanner.dart';

/// Simplified drop handler - keeps VS Code & JetBrains edge cases
class DropHandler {
  DropHandler({required this.fileScanner});

  final FileScanner fileScanner;

  /// Process dropped items - now returns ScanResult with metadata
  Future<ScanResult> processDroppedItems(
    List<XFile> items, {
    required Set<String> blacklist,
  }) async {
    final allFiles = <ScannedFile>[];
    final processedPaths = <String>{};
    final sourcePaths = <String>{};

    // Deduplicate items first - sometimes the same file appears multiple times
    final uniquePaths = <String>{};
    final uniqueItems = <XFile>[];
    for (final item in items) {
      if (!uniquePaths.contains(item.path)) {
        uniquePaths.add(item.path);
        uniqueItems.add(item);
      }
    }

    // Group files by their parent directory first to avoid duplicate source paths
    final filesByDirectory = <String, List<String>>{};
    final directories = <String>[];

    // First pass: categorize items
    for (final item in uniqueItems) {
      final itemPath = item.path;

      // VS Code directory drop detection
      if (await _isVSCodeDirectoryDrop(itemPath)) {
        final dirPath = await _extractVSCodeDirectory(itemPath);
        if (dirPath != null) {
          directories.add(dirPath);
        }
        continue;
      }

      // Handle typed drops (desktop_drop 0.6.0+)
      if (item is DropItemDirectory) {
        directories.add(itemPath);
      } else {
        // Check if "file" is actually a directory (JetBrains workaround)
        final entityType = FileSystemEntity.typeSync(itemPath);

        if (entityType == FileSystemEntityType.directory) {
          directories.add(itemPath);
        } else if (entityType == FileSystemEntityType.file) {
          // Group individual files by their parent directory
          final parentDir = path.dirname(itemPath);
          filesByDirectory.putIfAbsent(parentDir, () => []).add(itemPath);
        }
      }
    }

    // Process directories
    for (final dirPath in directories) {
      final scanResult = await fileScanner.scanDirectory(
        dirPath,
        blacklist: blacklist,
      );
      sourcePaths.add(dirPath);
      for (final file in scanResult.files) {
        if (!processedPaths.contains(file.fullPath)) {
          allFiles.add(file);
          processedPaths.add(file.fullPath);
        }
      }
    }

    // Process grouped files
    for (final entry in filesByDirectory.entries) {
      final parentDir = entry.key;
      final filePaths = entry.value;

      // Only add parent directory to source paths once per group
      sourcePaths.add(parentDir);

      for (final filePath in filePaths) {
        // Skip if we've already processed this exact file path
        if (processedPaths.contains(filePath)) {
          continue;
        }

        final fileName = path.basename(filePath);

        // Check if filename matches any blacklist pattern
        bool isBlacklisted = false;
        for (final pattern in blacklist) {
          if (fileName.toLowerCase().endsWith(pattern.toLowerCase())) {
            isBlacklisted = true;
            break;
          }
        }

        if (isBlacklisted) {
          continue;
        }

        final file = ScannedFile.fromFile(
          File(filePath),
          relativePath: fileName,
          source: ScanSource.drop,
        );

        allFiles.add(file);
        processedPaths.add(filePath);
      }
    }

    return ScanResult(
      files: allFiles,
      metadata: ScanMetadata(
        sourcePaths: sourcePaths.toList(),
        timestamp: DateTime.now(),
        source: ScanSource.drop,
      ),
    );
  }

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
