import 'dart:io';

import 'package:path/path.dart' as path;

import '../models/scan_result.dart';
import '../models/scanned_file.dart';

/// Scans the filesystem for files and loads their content.
///
/// This class has been refactored to use a fully asynchronous and incremental
/// approach, ensuring the UI remains responsive during large directory scans.
class FileScanner {
  /// Scans a directory for files incrementally, reporting each file as it's found.
  /// This is the primary method for directory processing.
  ///
  /// Performance characteristics:
  /// - Files are reported immediately as they're discovered
  /// - No blocking operations in the main scan loop
  /// - UI remains responsive even with thousands of files
  Future<void> scanDirectoryIncremental(
    String directoryPath, {
    required Set<String> blacklist,
    required void Function(ScannedFile file) onFileFound,
    required ScanSource source,
  }) async {
    final directory = Directory(directoryPath);
    if (!directory.existsSync()) {
      throw FileSystemException('Directory not found: $directoryPath');
    }

    // The stream from directory.list() is inherently asynchronous and non-blocking
    await for (final entity in directory.list(
      recursive: true,
      followLinks: false,
    )) {
      if (entity is! File) continue;

      final fileName = path.basename(entity.path);

      // Skip hidden files (e.g., .DS_Store, .git)
      if (fileName.startsWith('.')) {
        continue;
      }

      // Check if the file is blacklisted by extension or name
      final isBlacklisted = blacklist.any(
        (pattern) => fileName.toLowerCase().endsWith(pattern.toLowerCase()),
      );

      if (isBlacklisted) {
        continue;
      }

      try {
        // Calculate the relative path from the originally scanned directory
        final relativePath = path.relative(entity.path, from: directoryPath);

        // Use the SYNC factory for instant performance
        final scannedFile = ScannedFile.fromFile(
          entity,
          relativePath: relativePath,
          source: source,
        );

        // Report the file immediately to enable instant UI feedback
        onFileFound(scannedFile);
      } catch (_) {
        // Skip files that might have permission errors or other issues
        // during async stat/creation. This ensures one bad file doesn't
        // break the entire scan.
      }
    }
  }

  /// Creates a virtual file object that doesn't exist on disk.
  /// Virtual files are used for user-created content within the app.
  ScannedFile createVirtualFile({
    required String name,
    required String content,
    String? virtualPath,
  }) {
    final fullPath = virtualPath ?? '/$name';
    final normalizedPath = path.normalize(fullPath);

    // Generate deterministic ID for virtual files based on path
    // Prefix with 'virtual_' to avoid conflicts with real files
    final id =
        'virtual_${normalizedPath.hashCode.toUnsigned(32).toRadixString(16)}';

    return ScannedFile(
      id: id,
      name: name,
      fullPath: fullPath,
      relativePath: virtualPath?.replaceFirst('/', '') ?? name,
      extension: path.extension(name).toLowerCase(),
      size: content.length,
      lastModified: DateTime.now(),
      source: ScanSource.manual,
      isVirtual: true,
      content: content,
      virtualContent: content,
    );
  }

  /// Asynchronously loads the text content for a given ScannedFile.
  ///
  /// This method is called separately from the initial scan to avoid
  /// blocking the UI while reading potentially large files.
  Future<ScannedFile> loadFileContent(ScannedFile file) async {
    // Virtual files already have their content in memory
    if (file.isVirtual) {
      return file;
    }

    try {
      final fileEntity = File(file.fullPath);
      if (!fileEntity.existsSync()) {
        return file.copyWith(error: 'File not found on disk');
      }

      // Asynchronously read the file content as a string
      final content = await fileEntity.readAsString();
      return file.copyWith(content: content);
    } catch (e) {
      // If reading as a string fails, it's likely a binary file or
      // there's a permission/encoding issue
      return file.copyWith(
        error: 'Cannot read file: Likely binary or unsupported format',
      );
    }
  }
}
