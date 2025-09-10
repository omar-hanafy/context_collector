import 'dart:io';
import 'dart:math';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;

import '../models/scanned_file.dart';

/// Service for file operations like copying paths, saving files, etc.
/// Extracted from FileListNotifier to reduce its size and improve maintainability.
class FileOperationsService {
  FileOperationsService._();

  /// Saves content to a file using the system file picker
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

  /// Copies text to the system clipboard
  static Future<void> copyToClipboard(String text) async {
    if (text.isEmpty) {
      throw ArgumentError('No content to copy');
    }
    await Clipboard.setData(ClipboardData(text: text));
  }

  /// Copies the full paths of files to the clipboard
  static Future<void> copyFullPaths(List<ScannedFile> files) async {
    final realFiles = files.where((f) => !f.isVirtual).toList();
    if (realFiles.isEmpty) {
      throw ArgumentError('No real files selected to copy paths');
    }

    final paths = realFiles.map((f) => f.fullPath).toList()..sort();
    await copyToClipboard(paths.join('\n'));
  }

  /// Copies AI-formatted relative paths to the clipboard
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

  /// Finds the longest common directory path from a list of file paths
  static String findCommonBasePath(List<String> paths) {
    if (paths.isEmpty) return '';
    if (paths.length == 1) return p.dirname(paths.first);

    // Split all paths into components
    final componentsList = paths.map((path) => p.split(path)).toList();

    // Find the shortest path to limit our search
    final minLength = componentsList.map((c) => c.length).reduce(min);

    // Find common components
    final commonComponents = <String>[];
    for (int i = 0; i < minLength - 1; i++) {
      // -1 to exclude the filename
      final component = componentsList[0][i];
      if (componentsList.every((components) => components[i] == component)) {
        commonComponents.add(component);
      } else {
        break;
      }
    }

    return p.joinAll(commonComponents);
  }

  /// Validates paths and returns categorized results
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

  /// Builds a summary message for paste operations
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