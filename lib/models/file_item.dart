import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:path/path.dart' as path;

import '../config/file_extensions.dart';

@immutable
class FileItem {
  const FileItem({
    required this.name,
    required this.fullPath,
    required this.extension,
    required this.size,
    required this.lastModified,
    this.content,
    this.isSelected = true,
    this.isLoading = false,
    this.error,
  });

  factory FileItem.fromFile(File file) {
    final stat = file.statSync();
    return FileItem(
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
  final bool isSelected;
  final bool isLoading;
  final String? error;

  String get sizeFormatted {
    if (size < 1024) return '${size}B';
    if (size < 1024 * 1024) return '${(size / 1024).toStringAsFixed(1)}KB';
    if (size < 1024 * 1024 * 1024) {
      return '${(size / (1024 * 1024)).toStringAsFixed(1)}MB';
    }
    return '${(size / (1024 * 1024 * 1024)).toStringAsFixed(1)}GB';
  }

  bool get isTextFile => FileExtensionConfig.isTextFile(extension);

  FileCategory? get category => FileExtensionConfig.getCategory(extension);

  Future<FileItem> loadContent() async {
    if (!isTextFile) {
      return copyWith(
        error: 'File type not supported for text extraction',
        isLoading: false,
      );
    }

    try {
      final file = File(fullPath);
      if (!file.existsSync()) {
        return copyWith(
          error: 'File not found',
          isLoading: false,
        );
      }

      final fileContent = await file.readAsString();
      return copyWith(
        content: fileContent,
        isLoading: false,
        error: null,
      );
    } catch (e) {
      return copyWith(
        error: 'Error reading file: $e',
        content: null,
        isLoading: false,
      );
    }
  }

  String generateReference() {
    return '// File: $fullPath\n// Size: $sizeFormatted\n// Modified: ${lastModified.toIso8601String()}\n';
  }

  FileItem copyWith({
    String? name,
    String? fullPath,
    String? extension,
    int? size,
    DateTime? lastModified,
    String? content,
    bool? isSelected,
    bool? isLoading,
    String? error,
  }) {
    return FileItem(
      name: name ?? this.name,
      fullPath: fullPath ?? this.fullPath,
      extension: extension ?? this.extension,
      size: size ?? this.size,
      lastModified: lastModified ?? this.lastModified,
      content: content ?? this.content,
      isSelected: isSelected ?? this.isSelected,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is FileItem && other.fullPath == fullPath;
  }

  @override
  int get hashCode => fullPath.hashCode;
}
