import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as path;

import '../ui/file_display_helper.dart';
import 'scan_result.dart';

/// Simplified ScannedFile model - same API, cleaner implementation
@immutable
class ScannedFile {
  const ScannedFile({
    required this.id,
    required this.name,
    required this.fullPath,
    required this.extension,
    required this.size,
    required this.lastModified,
    required this.source,
    required this.isVirtual,
    this.relativePath,
    this.content,
    this.virtualContent,
    this.editedContent,
    this.error,
    this.displayPath,
  });

  factory ScannedFile.fromFile(
    File file, {
    String? relativePath,
    ScanSource source = ScanSource.browse,
  }) {
    final filePath = file.path;
    final fileName = path.basename(filePath);
    final stat = file.statSync();

    // VS Code temp file handling - simplified
    final displayPath = filePath.contains('/tmp/Drops/') ? fileName : null;

    // Generate deterministic ID based on the normalized full path
    // This ensures the same file always gets the same ID
    final normalizedPath = path.normalize(filePath);
    final id =
        'file_${normalizedPath.hashCode.toUnsigned(32).toRadixString(16)}_${stat.size}';

    return ScannedFile(
      id: id,
      name: fileName,
      fullPath: filePath,
      extension: path.extension(filePath).toLowerCase(),
      size: stat.size,
      lastModified: stat.modified,
      source: source,
      isVirtual: false,
      relativePath: relativePath,
      displayPath: displayPath,
    );
  }

  final String id;
  final String name;
  final String fullPath;
  final String extension;
  final int size;
  final DateTime lastModified;
  final ScanSource source;
  final bool isVirtual;
  final String? relativePath;
  final String? content;
  final String? virtualContent;
  final String? editedContent;
  final String? error;
  final String? displayPath;

  /// Computed properties
  bool get isDirty => editedContent != null && editedContent != content;
  String get effectiveContent =>
      editedContent ?? virtualContent ?? content ?? '';

  /// Simplified text support check - just try to read it
  bool get supportsText => true; // We'll try to read any file as text

  /// Generate reference for markdown
  String generateReference() {
    final pathToShow = FileDisplayHelper.getPathForDisplay(this);
    return '> **Path:** $pathToShow';
  }

  ScannedFile copyWith({
    String? id,
    String? name,
    String? fullPath,
    String? extension,
    int? size,
    DateTime? lastModified,
    ScanSource? source,
    bool? isVirtual,
    String? relativePath,
    String? content,
    String? virtualContent,
    String? editedContent,
    String? error,
    String? displayPath,
  }) {
    return ScannedFile(
      id: id ?? this.id,
      name: name ?? this.name,
      fullPath: fullPath ?? this.fullPath,
      extension: extension ?? this.extension,
      size: size ?? this.size,
      lastModified: lastModified ?? this.lastModified,
      source: source ?? this.source,
      isVirtual: isVirtual ?? this.isVirtual,
      relativePath: relativePath ?? this.relativePath,
      content: content ?? this.content,
      virtualContent: virtualContent ?? this.virtualContent,
      editedContent: editedContent ?? this.editedContent,
      error: error ?? this.error,
      displayPath: displayPath ?? this.displayPath,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is ScannedFile && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
