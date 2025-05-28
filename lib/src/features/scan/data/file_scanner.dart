import 'dart:io';

import 'package:path/path.dart' as path;

import '../../../shared/utils/drop_file_resolver.dart';
import '../../../shared/utils/extension_catalog.dart';
import '../domain/scanned_file.dart';

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
        var extension = path.extension(entity.path).toLowerCase();
        
        // For temporary drop files without extensions, try to resolve the actual extension
        if (extension.isEmpty && DropFileResolver.isTemporaryDropFile(entity.path)) {
          final fileInfo = DropFileResolver.resolveFileInfo(entity.path);
          extension = fileInfo['extension'] ?? '';
        }
        
        // Include files with supported extensions OR files without extensions
        // (which might be text files from desktop_drop temporary directory)
        if (supportedExtensions.containsKey(extension) || extension.isEmpty) {
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
    // Special handling for files without extensions (e.g., from desktop_drop temporary files)
    if (file.extension.isEmpty) {
      try {
        final fileEntity = File(file.fullPath);
        if (!fileEntity.existsSync()) {
          return file.copyWith(error: 'File not found');
        }

        // For temporary drop files, try to resolve the actual extension
        String? resolvedExtension;
        if (DropFileResolver.isTemporaryDropFile(file.fullPath)) {
          final fileInfo = DropFileResolver.resolveFileInfo(file.fullPath);
          resolvedExtension = fileInfo['extension'];
          
          // If we resolved an extension, check if it's supported
          if (resolvedExtension != null && resolvedExtension.isNotEmpty) {
            if (!supportedExtensions.containsKey(resolvedExtension)) {
              return file.copyWith(
                error: 'Resolved file type $resolvedExtension is not supported',
              );
            }
          }
        }

        // Try to read as text - if it's a text file, it should work
        final content = await fileEntity.readAsString();
        // If we successfully read it as text, return with content
        return file.copyWith(content: content, error: null);
      } catch (e) {
        return file.copyWith(
          error: 'Cannot read file: possibly binary or unsupported format',
          content: null,
        );
      }
    }
    
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
