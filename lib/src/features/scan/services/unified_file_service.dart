import 'dart:convert';
import 'dart:math';

import 'package:docx_to_markdown/docx_to_markdown.dart';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;

import '../models/scan_result.dart';
import '../models/scanned_file.dart';
import '../ui/file_display_helper.dart';
import 'fs/platform_fs.dart';

/// Unified service for all file operations - scanning, dropping, and file
/// operations. Platform-specific filesystem access is delegated to
/// [PlatformFs] so this service compiles and runs on desktop and web alike.
class UnifiedFileService {
  UnifiedFileService._();

  static bool _isDocx(ScannedFile file) =>
      file.extension.toLowerCase() == '.docx';

  static Future<String> _decodeDocx(ScannedFile file, Uint8List bytes) async {
    try {
      return await DocxConverter(bytes).convert();
    } on DocxPackageException catch (e) {
      throw FormatException('Cannot read .docx file: ${e.message}');
    }
  }

  //============================================================================
  // FILE SCANNING
  //============================================================================

  /// Scans a directory incrementally and efficiently, skipping heavy folders.
  /// Desktop-only; on web folders arrive pre-expanded via drag-and-drop.
  static Future<void> scanDirectory({
    required String directoryPath,
    required Set<String> blacklist,
    required void Function(List<ScannedFile> files) onBatchFound,
    required ScanSource source,
  }) {
    return PlatformFs.scanDirectory(
      directoryPath: directoryPath,
      blacklist: blacklist,
      onBatchFound: onBatchFound,
      source: source,
    );
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
      final bytes = await PlatformFs.readFileBytes(file);
      if (bytes == null) {
        return file.copyWith(error: 'File not found on disk');
      }

      // Basic size check to prevent OOM on massive files
      // 10MB limit for loading into string
      if (bytes.length > 10 * 1024 * 1024) {
        return file.copyWith(
          error: 'File too large to read (>${bytes.length ~/ (1024 * 1024)}MB)',
        );
      }

      if (_isDocx(file)) {
        final content = await _decodeDocx(file, bytes);
        return file.copyWith(content: content, clearError: true);
      }

      final content = utf8.decode(bytes);
      return file.copyWith(content: content, clearError: true);
    } on FormatException catch (e) {
      final message = e.message.trim();
      return file.copyWith(
        error: message.startsWith('Cannot read .docx')
            ? message
            : 'Cannot read file: Likely binary or unsupported format',
      );
    } catch (_) {
      return file.copyWith(
        error: 'Cannot read file: Likely binary or unsupported format',
      );
    }
  }

  //============================================================================
  // DROP HANDLING
  //============================================================================

  /// Processes dropped items
  static Future<void> processDroppedItems({
    required List<XFile> items,
    required Set<String> blacklist,
    required ScanSource source,
    required void Function(List<ScannedFile> files) onBatchFound,
    required void Function(List<String> sourcePaths) onScanComplete,
  }) {
    return PlatformFs.expandDroppedItems(
      items: items,
      blacklist: blacklist,
      source: source,
      onBatchFound: onBatchFound,
      onScanComplete: onScanComplete,
    );
  }

  //============================================================================
  // FILE OPERATIONS
  //============================================================================

  /// Saves content to file (Legacy string based)
  static Future<void> saveToFile(String content) async {
    if (content.isEmpty) {
      throw ArgumentError('No content to save');
    }

    final fileName =
        'context_collection_${DateTime.now().millisecondsSinceEpoch}.md';
    await PlatformFs.saveTextFile(suggestedName: fileName, content: content);
  }

  /// Builds the combined markdown content for "View All" mode.
  /// Reads files from their backing store when content is not in memory.
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
        // Try reading from the backing store
        try {
          final len = await PlatformFs.fileSizeOf(file);
          if (len == null) {
            error = 'File not found on disk';
          } else if (len >= 5 * 1024 * 1024) {
            // 5MB limit per file for view all
            error =
                'File too large to preview (${(len / 1024 / 1024).toStringAsFixed(1)} MB)';
          } else {
            final bytes = await PlatformFs.readFileBytes(file);
            if (bytes == null) {
              error = 'File not found on disk';
            } else if (_isDocx(file)) {
              content = await _decodeDocx(file, bytes);
              isLoaded = true;
            } else {
              content = utf8.decode(bytes);
              isLoaded = true;
            }
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

  /// Exports the selected files.
  ///
  /// On desktop this streams content from disk to disk so huge projects never
  /// live in RAM; on web the content is assembled in memory (where the files
  /// already live) and downloaded as a single markdown file.
  static Future<void> streamSaveToFile(List<ScannedFile> files) async {
    if (PlatformFs.supportsStreamingExport) {
      await PlatformFs.exportCollectionStreaming(files);
      return;
    }

    final content = await buildCombinedContent(files);
    final fileName =
        'context_collection_${DateTime.now().millisecondsSinceEpoch}.md';
    await PlatformFs.saveTextFile(suggestedName: fileName, content: content);
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
          if (PlatformFs.pathExists(path)) {
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
