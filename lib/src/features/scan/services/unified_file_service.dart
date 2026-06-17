import 'dart:io';
import 'dart:math';

import 'package:desktop_drop/desktop_drop.dart';
import 'package:docx_to_markdown/docx_to_markdown.dart';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;

import '../models/scan_result.dart';
import '../models/scanned_file.dart';
import '../ui/file_display_helper.dart';

/// Unified service for all file operations - scanning, dropping, and file operations
/// Consolidates FileScanner, DropHandler, and FileOperationsService
class UnifiedFileService {
  UnifiedFileService._();

  static bool _isDocx(ScannedFile file) =>
      file.extension.toLowerCase() == '.docx';

  static Future<String> _readDocxAsMarkdown(File file) async {
    try {
      final bytes = await file.readAsBytes();
      return await DocxConverter(bytes).convert();
    } on DocxPackageException catch (e) {
      throw FileSystemException(
        'Cannot read .docx file: ${e.message}',
        file.path,
      );
    }
  }

  //============================================================================
  // FILE SCANNING (from FileScanner)
  //============================================================================

  /// Scans a directory incrementally and efficiently, skipping heavy folders.
  static Future<void> scanDirectory({
    required String directoryPath,
    required Set<String> blacklist,
    required void Function(List<ScannedFile> files) onBatchFound,
    required ScanSource source,
  }) async {
    final rootDir = Directory(directoryPath);
    if (!rootDir.existsSync()) {
      return;
    }

    // Folders to completely ignore during traversal
    const ignoredDirs = {
      'build',
      '.dart_tool',
      '.git',
      '.idea',
      'ios',
      'android',
      'node_modules',
      'linux',
      'macos',
      'windows',
      'web',
      'coverage',
      '.gradle',
      '.vscode',
      'Pods',
      '.symlinks',
      'DerivedData',
      'dist',
      'out',
    };

    final List<Directory> stack = [rootDir];
    final List<ScannedFile> batch = [];

    while (stack.isNotEmpty) {
      final current = stack.removeLast();

      try {
        // List non-recursively
        final entities = current.list(recursive: false, followLinks: false);

        await for (final entity in entities) {
          final name = p.basename(entity.path);

          if (entity is Directory) {
            // Skip ignored dirs
            if (!name.startsWith('.') && !ignoredDirs.contains(name)) {
              stack.add(entity);
            }
          } else if (entity is File) {
            // Skip hidden files
            if (name.startsWith('.')) continue;

            // Check blacklist
            if (blacklist.any(
              (ext) => name.toLowerCase().endsWith(ext.toLowerCase()),
            )) {
              continue;
            }

            try {
              final relativePath = p.relative(entity.path, from: directoryPath);
              batch.add(
                ScannedFile.fromFile(
                  entity,
                  relativePath: relativePath,
                  source: source,
                ),
              );

              // Emit batch every 200 items
              if (batch.length >= 200) {
                onBatchFound(List.from(batch));
                batch.clear();
              }
            } catch (_) {
              // Skip problematic files
            }
          }
        }
      } catch (_) {
        // Access denied or other fs errors
      }
    }

    if (batch.isNotEmpty) {
      onBatchFound(batch);
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
    final id =
        'virtual_${normalizedPath.hashCode.toUnsigned(32).toRadixString(16)}';

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

      // Basic size check to prevent OOM on massive files
      // 10MB limit for loading into string
      final stat = fileEntity.statSync();
      if (stat.size > 10 * 1024 * 1024) {
        return file.copyWith(
          error: 'File too large to read (>${stat.size ~/ (1024 * 1024)}MB)',
        );
      }

      if (_isDocx(file)) {
        final content = await _readDocxAsMarkdown(fileEntity);
        return file.copyWith(content: content);
      }

      final content = await fileEntity.readAsString();
      return file.copyWith(content: content);
    } on FileSystemException catch (e) {
      return file.copyWith(error: e.message);
    } catch (_) {
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
    required void Function(List<ScannedFile> files) onBatchFound,
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
        onBatchFound: (batch) {
          final newFiles = <ScannedFile>[];
          for (final file in batch) {
            if (processedPaths.add(file.fullPath)) {
              newFiles.add(file);
            }
          }
          if (newFiles.isNotEmpty) {
            onBatchFound(newFiles);
          }
        },
      );
    }

    // Process individual files
    // We treat these as a batch per directory
    for (final entry in filesByDirectory.entries) {
      sourcePaths.add(entry.key);
      final batch = <ScannedFile>[];

      for (final filePath in entry.value) {
        if (!processedPaths.add(filePath)) {
          continue;
        }

        final fileName = p.basename(filePath);
        if (blacklist.any(
          (pattern) => fileName.toLowerCase().endsWith(pattern.toLowerCase()),
        )) {
          continue;
        }

        try {
          final file = ScannedFile.fromFile(
            File(filePath),
            relativePath: fileName,
            source: source,
          );
          batch.add(file);
        } catch (_) {}
      }

      if (batch.isNotEmpty) {
        onBatchFound(batch);
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
      final match = RegExp(
        r'<script>start\("([^\"]+)"\);</script>',
      ).firstMatch(content);
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

  /// Saves content to file (Legacy string based)
  static Future<void> saveToFile(String content) async {
    if (content.isEmpty) {
      throw ArgumentError('No content to save');
    }

    final fileName =
        'context_collection_${DateTime.now().millisecondsSinceEpoch}.md';
    final filePath = await getSaveLocation(suggestedName: fileName);
    if (filePath != null) {
      await File(filePath.path).writeAsString(content);
    }
  }

  /// Builds the combined markdown content for "View All" mode.
  /// Reads files from disk if their content is not currently loaded in memory.
  static Future<String> buildCombinedContent(
    List<ScannedFile> selectedFiles,
  ) async {
    final output = StringBuffer();

    final headerFile = selectedFiles
        .where((f) => f.isVirtual && f.name == 'Header')
        .firstOrNull;

    final footerFile = selectedFiles
        .where((f) => f.isVirtual && f.name == 'Footer')
        .firstOrNull;

    // --- Header (verbatim) ---
    if (headerFile != null) {
      final text = headerFile.effectiveContent;
      if (text.trim().isNotEmpty) {
        output.write(text);
        if (!text.endsWith('\n')) output.writeln();
        output.writeln();
      }
    }

    // --- Build Context Collection ---
    final context = StringBuffer()
      ..writeln('# Context Collection')
      ..writeln();

    final contextFiles = List<ScannedFile>.from(selectedFiles)
      ..removeWhere(
        (f) =>
            f.isVirtual && (f.id == headerFile?.id || f.id == footerFile?.id),
      )
      ..sort((a, b) => a.fullPath.compareTo(b.fullPath));

    for (final file in contextFiles) {
      context
        ..writeln('## ${file.name}')
        ..writeln(file.generateReference())
        ..writeln();

      String content = '';
      bool isLoaded = false;
      String? error = file.error;

      // Determine content source
      if (file.isVirtual ||
          file.editedContent != null ||
          file.content != null) {
        content = file.effectiveContent;
        isLoaded = true;
      } else {
        // Try reading from disk
        try {
          final f = File(file.fullPath);
          if (f.existsSync()) {
            final len = await f.length();
            if (len < 5 * 1024 * 1024) {
              // 5MB limit per file for view all
              if (_isDocx(file)) {
                content = await _readDocxAsMarkdown(f);
                isLoaded = true;
              } else {
                content = await f.readAsString();
                isLoaded = true;
              }
            } else {
              error =
                  'File too large to preview (${(len / 1024 / 1024).toStringAsFixed(1)} MB)';
            }
          } else {
            error = 'File not found on disk';
          }
        } catch (e) {
          error = 'Error reading file: $e';
        }
      }

      if (isLoaded && error == null) {
        context
          ..writeln('```${FileDisplayHelper.getLanguageFromFile(file)}')
          ..writeln(content)
          ..writeln('```')
          ..writeln('\n---\n');
      } else if (error != null) {
        context.writeln('```\nERROR: $error\n```');
      } else {
        context.writeln('```\n// Content not loaded (Unknown error)\n```');
      }

      context.writeln();
    }

    // Normalize extra blank lines
    final contextNormalized = context.toString().replaceAll(
      RegExp(r'\n{3,}'),
      '\n\n',
    );

    output.write(contextNormalized);

    // --- Footer (verbatim) ---
    if (footerFile != null) {
      final text = footerFile.effectiveContent;
      if (text.trim().isNotEmpty) {
        if (!output.toString().endsWith('\n\n')) output.writeln();
        output.write(text);
        if (!text.endsWith('\n')) output.writeln();
      }
    }

    return output.toString();
  }

  /// Safe export that streams content from disk to disk.
  /// Handles large projects without using RAM for the whole content.
  static Future<void> streamSaveToFile(List<ScannedFile> files) async {
    final fileName =
        'context_collection_${DateTime.now().millisecondsSinceEpoch}.md';
    final savePath = await getSaveLocation(suggestedName: fileName);
    if (savePath == null) return;

    // Open a write stream directly to the file
    final sink = File(savePath.path).openWrite();

    try {
      // --- Header ---
      final headerFile = files
          .where((f) => f.isVirtual && f.name == 'Header')
          .firstOrNull;
      if (headerFile != null) {
        sink
          ..writeln(headerFile.effectiveContent)
          ..writeln();
      }

      sink.writeln('# Context Collection\n');

      final contextFiles =
          files
              .where(
                (f) =>
                    !(f.isVirtual &&
                        (f.name == 'Header' || f.name == 'Footer')),
              )
              .toList()
            ..sort((a, b) => a.fullPath.compareTo(b.fullPath));

      for (final file in contextFiles) {
        sink
          ..writeln('## ${file.name}')
          ..writeln('> **Path:** ${file.fullPath}\n');

        final fenceLanguage = _isDocx(file)
            ? 'markdown'
            : file.extension.replaceAll('.', '');
        sink.writeln('```$fenceLanguage');

        if (file.isVirtual) {
          sink.write(file.effectiveContent);
        } else {
          // REAL FILES: Stream directly from disk!
          final f = File(file.fullPath);
          if (f.existsSync()) {
            if (_isDocx(file)) {
              try {
                sink.write(await _readDocxAsMarkdown(f));
              } catch (e) {
                sink.writeln('// Error converting .docx to text: $e');
              }
            } else {
              await sink.addStream(f.openRead());
            }
          } else {
            sink.writeln('// Error: File not found');
          }
        }

        sink
          ..writeln('\n```\n')
          ..writeln('---\n');
      }

      // --- Footer ---
      final footerFile = files
          .where((f) => f.isVirtual && f.name == 'Footer')
          .firstOrNull;
      if (footerFile != null) {
        sink
          ..writeln()
          ..writeln(footerFile.effectiveContent);
      }
    } finally {
      await sink.flush();
      await sink.close();
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

    final componentsList = paths.map(p.split).toList();
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
