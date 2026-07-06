import 'package:flutter/foundation.dart';

import 'scan_result.dart';

/// Represents a single file (real or virtual) in the context collection.
///
/// This immutable class holds all metadata and content for a file.
@immutable
class ScannedFile {
  const ScannedFile({
    required this.id,
    required this.name,
    required this.fullPath,
    required this.relativePath,
    required this.extension,
    required this.size,
    required this.lastModified,
    required this.source,
    this.isVirtual = false,
    this.content,
    this.editedContent,
    this.virtualContent,
    this.error,
    this.displayPath,
  });

  /// Unique identifier for the file (based on path and size)
  final String id;

  /// Basic file properties
  final String name;
  final String fullPath;
  final String relativePath;
  final String extension;
  final int size;
  final DateTime lastModified;
  final ScanSource source;

  /// Content properties
  final bool isVirtual;
  final String? content;
  final String? editedContent;
  final String? virtualContent;
  final String? error;
  final String? displayPath;

  /// True if the file has been edited in the app.
  bool get isDirty => editedContent != null && editedContent != content;

  /// Text that is safe to bind to an editable Monaco document.
  ///
  /// Real files return `null` until their content has actually loaded. This
  /// keeps the lazy-loading state distinct from a legitimately empty file.
  String? get editorContent {
    if (editedContent != null) return editedContent;
    if (isVirtual) return virtualContent ?? content ?? '';
    return content;
  }

  /// True once the file has text that can safely be shown in Monaco.
  bool get hasEditorContent => editorContent != null;

  /// The most up-to-date content for the file (edited, virtual, or from disk).
  String get effectiveContent => editorContent ?? '';

  /// Simplified text support check - we optimistically try to read any file.
  bool get supportsText => true;

  /// Generates the markdown reference line for the file's path.
  String generateReference() {
    return '> **Path:** $fullPath';
  }

  /// Returns a new instance of ScannedFile with updated properties.
  ScannedFile copyWith({
    String? id,
    String? name,
    String? fullPath,
    String? relativePath,
    String? extension,
    int? size,
    DateTime? lastModified,
    ScanSource? source,
    bool? isVirtual,
    String? content,
    String? editedContent,
    String? virtualContent,
    String? error,
    String? displayPath,
    bool clearContent = false,
    bool clearEditedContent = false,
    bool clearVirtualContent = false,
    bool clearError = false,
    bool clearDisplayPath = false,
  }) {
    return ScannedFile(
      id: id ?? this.id,
      name: name ?? this.name,
      fullPath: fullPath ?? this.fullPath,
      relativePath: relativePath ?? this.relativePath,
      extension: extension ?? this.extension,
      size: size ?? this.size,
      lastModified: lastModified ?? this.lastModified,
      source: source ?? this.source,
      isVirtual: isVirtual ?? this.isVirtual,
      content: clearContent ? null : content ?? this.content,
      editedContent: clearEditedContent
          ? null
          : editedContent ?? this.editedContent,
      virtualContent: clearVirtualContent
          ? null
          : virtualContent ?? this.virtualContent,
      error: clearError ? null : error ?? this.error,
      displayPath: clearDisplayPath ? null : displayPath ?? this.displayPath,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ScannedFile &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'ScannedFile(id: $id, name: $name, path: $fullPath)';
}
