import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as path;

import '../../../shared/utils/extension_catalog.dart';

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
  });

  /// Create a ScannedFile from a File system object
  factory ScannedFile.fromFile(File file) {
    final stat = file.statSync();
    return ScannedFile(
      name: path.basename(file.path),
      fullPath: file.path,
      extension: path.extension(file.path).toLowerCase(),
      size: stat.size,
      lastModified: stat.modified,
    );
  }

  final String name;
  final String fullPath;
  final String extension;
  final int size;
  final DateTime lastModified;
  final String? content;
  final String? error;

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

  /// Generate metadata reference for the combined content
  String generateReference() {
    return '// File: $fullPath\n// Size: $sizeFormatted\n// Modified: ${lastModified.toIso8601String()}\n';
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
  }) {
    return ScannedFile(
      name: name ?? this.name,
      fullPath: fullPath ?? this.fullPath,
      extension: extension ?? this.extension,
      size: size ?? this.size,
      lastModified: lastModified ?? this.lastModified,
      content: content ?? this.content,
      error: error ?? this.error,
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
