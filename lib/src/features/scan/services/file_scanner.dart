import 'dart:io';
import 'package:path/path.dart' as path;
import '../models/scanned_file.dart';
import '../models/scan_result.dart';

/// Simplified file scanner - combines scanning and content assembly
class FileScanner {
  /// Scan directory for files (no extension filtering)
  /// Now returns ScanResult with metadata
  Future<ScanResult> scanDirectory(String directoryPath) async {
    final directory = Directory(directoryPath);
    if (!directory.existsSync()) {
      throw FileSystemException('Directory not found: $directoryPath');
    }

    final files = <ScannedFile>[];
    
    await for (final entity in directory.list(
      recursive: true,
      followLinks: false,
    )) {
      if (entity is File) {
        // Skip hidden files (like .DS_Store)
        final fileName = path.basename(entity.path);
        if (fileName.startsWith('.')) continue;
        
        try {
          // Calculate relative path from the scanned directory
          final relativePath = path.relative(entity.path, from: directoryPath);
          
          files.add(ScannedFile.fromFile(
            entity,
            relativePath: relativePath,
            source: ScanSource.browse,
          ));
        } catch (_) {
          // Skip files we can't access
        }
      }
    }
    
    return ScanResult(
      files: files,
      metadata: ScanMetadata(
        sourcePaths: [directoryPath],
        timestamp: DateTime.now(),
        source: ScanSource.browse,
      ),
    );
  }

  /// Create a virtual file (not from disk)
  ScannedFile createVirtualFile({
    required String name,
    required String content,
    String? virtualPath,
  }) {
    final fullPath = virtualPath ?? '/$name';
    
    // Generate deterministic ID for virtual files based on path
    // Prefix with 'virtual_' to avoid conflicts with real files
    final normalizedPath = path.normalize(fullPath);
    final id = 'virtual_${normalizedPath.hashCode.toUnsigned(32).toRadixString(16)}';
    
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

  /// Load content for a file
  Future<ScannedFile> loadFileContent(ScannedFile file) async {
    // Virtual files already have content
    if (file.isVirtual) {
      return file;
    }
    
    try {
      final fileEntity = File(file.fullPath);
      if (!fileEntity.existsSync()) {
        return file.copyWith(error: 'File not found');
      }

      // Try to read as text
      final content = await fileEntity.readAsString();
      return file.copyWith(content: content);
    } catch (e) {
      // If it fails, it's probably binary
      return file.copyWith(error: 'Cannot read file: binary or unsupported format');
    }
  }

  /// Build markdown from selected files
  Future<String> buildMarkdown(List<ScannedFile> selectedFiles) async {
    final buffer = StringBuffer()
      ..writeln('# Context Collection')
      ..writeln();

    // Sort by path for consistency
    final sortedFiles = List<ScannedFile>.from(selectedFiles)
      ..sort((a, b) => a.fullPath.compareTo(b.fullPath));

    for (final file in sortedFiles) {
      buffer
        ..writeln('## ${file.name}')
        ..writeln(file.generateReference())
        ..writeln();

      // Use effectiveContent to support edited and virtual content
      if (file.effectiveContent.isNotEmpty && file.error == null) {
        buffer
          ..writeln('```${file.language}')
          ..writeln(file.effectiveContent)
          ..writeln('```')
          ..writeln('\n---\n');
      } else if (file.error != null) {
        buffer.writeln('```\nERROR: ${file.error}\n```');
      } else if (file.content == null && !file.isVirtual) {
        buffer.writeln('```\n// Content not loaded\n```');
      }

      buffer.writeln();
    }

    return buffer.toString().replaceAll(RegExp(r'\n{3,}'), '\n\n');
  }
}
