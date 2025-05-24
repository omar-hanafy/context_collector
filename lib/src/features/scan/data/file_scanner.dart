import 'dart:io';

import 'package:path/path.dart' as path;

import '../domain/scanned_file.dart';
import '../../../shared/utils/extension_catalog.dart';

/// Service responsible for scanning directories and finding supported files
class FileScanner {
  /// Scan a directory for supported files
  Future<List<ScannedFile>> scanDirectory(
    String directoryPath,
    Map<String, FileCategory> supportedExtensions,
  ) async {
    final directory = Directory(directoryPath);
    if (!directory.existsSync()) {
      throw FileSystemException('Directory not found: $directoryPath');
    }

    final foundFiles = <ScannedFile>[];

    await for (final entity
        in directory.list(recursive: true, followLinks: false)) {
      if (entity is File) {
        final extension = path.extension(entity.path).toLowerCase();
        if (supportedExtensions.containsKey(extension)) {
          try {
            final scannedFile = ScannedFile.fromFile(entity);
            foundFiles.add(scannedFile);
          } catch (e) {
            // Skip files that can't be accessed
            continue;
          }
        }
      }
    }

    return foundFiles;
  }

  /// Load content for a single file
  Future<ScannedFile> loadFileContent(
    ScannedFile file,
    Map<String, FileCategory> supportedExtensions,
  ) async {
    if (!file.supportsText(supportedExtensions)) {
      return file.copyWith(
        error: 'File type not supported for text extraction',
      );
    }

    try {
      final fileEntity = File(file.fullPath);
      if (!fileEntity.existsSync()) {
        return file.copyWith(error: 'File not found');
      }

      final content = await fileEntity.readAsString();
      return file.copyWith(content: content, error: null);
    } catch (e) {
      return file.copyWith(
        error: 'Error reading file: $e',
        content: null,
      );
    }
  }

  /// Load content for multiple files
  Future<List<ScannedFile>> loadMultipleFileContents(
    List<ScannedFile> files,
    Map<String, FileCategory> supportedExtensions,
  ) async {
    final results = <ScannedFile>[];

    for (final file in files) {
      final result = await loadFileContent(file, supportedExtensions);
      results.add(result);
    }

    return results;
  }
}
