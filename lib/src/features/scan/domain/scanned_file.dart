import 'dart:io';

import 'package:context_collector/src/shared/utils/extension_catalog.dart';
import 'package:context_collector/src/shared/utils/language_mapper.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as path;

/// Represents a file that has been scanned from the filesystem
/// This is an immutable value object that only holds data
@immutable
class ScannedFile {
  const ScannedFile({
    required this.name,
    required this.fullPath,
    required this.extension,
    required this.size,
    required this.lastModified,
    this.content,
    this.error,
    this.displayPath,
  });

  /// Create a ScannedFile from a File system object
  factory ScannedFile.fromFile(File file) {
    final stat = file.statSync();
    final filePath = file.path;
    final fileName = path.basename(filePath);

    // For VS Code temp files, use just the filename as display path
    String? displayPath;
    if (filePath.contains('/tmp/Drops/')) {
      displayPath = fileName;
    }

    return ScannedFile(
      name: fileName,
      fullPath: filePath,
      extension: path.extension(filePath).toLowerCase(),
      size: stat.size,
      lastModified: stat.modified,
      displayPath: displayPath,
    );
  }

  final String name;
  final String fullPath;
  final String extension;
  final int size;
  final DateTime lastModified;
  final String? content;
  final String? error;

  /// Optional display path (for VS Code drops where the temp path isn't meaningful)
  final String? displayPath;

  /// Check if this file was dropped from VS Code (temporary file)
  bool get isVSCodeDrop => fullPath.contains('/tmp/Drops/');

  /// Human-readable file size
  String get sizeFormatted {
    if (size < 1024) return '${size}B';
    if (size < 1024 * 1024) return '${(size / 1024).toStringAsFixed(1)}KB';
    if (size < 1024 * 1024 * 1024) {
      return '${(size / (1024 * 1024)).toStringAsFixed(1)}MB';
    }
    return '${(size / (1024 * 1024 * 1024)).toStringAsFixed(1)}GB';
  }

  /// Check if this file supports text extraction
  bool supportsText([Map<String, FileCategory>? customExtensions]) {
    return supportsTextHelper(extension, customExtensions);
  }

  /// Get the category for this file
  FileCategory? getCategory([Map<String, FileCategory>? customExtensions]) {
    return getExtensionCategory(extension, customExtensions);
  }

  /// Get the language identifier for syntax highlighting
  String get language {
    return LanguageMapper.getLanguageForFile(fullPath);
  }

  /// Get the line count of the file content
  int get lineCount {
    if (content == null) return 0;
    return content!.split('\n').length;
  }

  /// Generate metadata reference for the combined content
  String generateReference() {
    // Use display path if available (for VS Code drops)
    final pathToShow = displayPath ?? fullPath;
    return '> **Path:** $pathToShow  \n';
  }

  /// Create a copy with updated fields
  ScannedFile copyWith({
    String? name,
    String? fullPath,
    String? extension,
    int? size,
    DateTime? lastModified,
    String? content,
    String? error,
    String? displayPath,
  }) {
    return ScannedFile(
      name: name ?? this.name,
      fullPath: fullPath ?? this.fullPath,
      extension: extension ?? this.extension,
      size: size ?? this.size,
      lastModified: lastModified ?? this.lastModified,
      content: content ?? this.content,
      error: error ?? this.error,
      displayPath: displayPath ?? this.displayPath,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ScannedFile && other.fullPath == fullPath;
  }

  @override
  int get hashCode => fullPath.hashCode;

  @override
  String toString() => 'ScannedFile(path: $fullPath, size: $sizeFormatted)';
}
