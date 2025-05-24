import '../domain/scanned_file.dart';

/// Service responsible for assembling content from multiple files into a combined format
/// This separates disk I/O concerns from UI state management
class ContentAssembler {
  /// Build a combined markdown-formatted string from selected files
  Future<String> buildMerged(List<ScannedFile> selectedFiles) async {
    final buffer = StringBuffer()
      ..writeln('# Context Collection')
      ..writeln('Generated on: ${DateTime.now().toIso8601String()}')
      ..writeln('Total selected files: ${selectedFiles.length}')
      ..writeln();

    for (final file in selectedFiles) {
      buffer
        ..writeln('=' * 80)
        ..writeln(file.generateReference())
        ..writeln('=' * 80);

      if (file.content != null) {
        buffer.writeln(file.content);
      } else if (file.error != null) {
        buffer.writeln('ERROR: ${file.error}');
      } else {
        buffer.writeln('PENDING: Content not loaded');
      }

      buffer
        ..writeln()
        ..writeln();
    }

    return buffer.toString();
  }

  /// Get content statistics
  ContentStats getStats(List<ScannedFile> files) {
    var totalSize = 0;
    var totalLines = 0;
    var totalCharacters = 0;
    var loadedFiles = 0;
    var errorFiles = 0;

    for (final file in files) {
      totalSize += file.size;

      if (file.content != null) {
        loadedFiles++;
        totalLines += file.content!.split('\n').length;
        totalCharacters += file.content!.length;
      } else if (file.error != null) {
        errorFiles++;
      }
    }

    return ContentStats(
      totalFiles: files.length,
      loadedFiles: loadedFiles,
      errorFiles: errorFiles,
      pendingFiles: files.length - loadedFiles - errorFiles,
      totalSize: totalSize,
      totalLines: totalLines,
      totalCharacters: totalCharacters,
    );
  }
}

/// Statistics about content collection
class ContentStats {
  const ContentStats({
    required this.totalFiles,
    required this.loadedFiles,
    required this.errorFiles,
    required this.pendingFiles,
    required this.totalSize,
    required this.totalLines,
    required this.totalCharacters,
  });

  final int totalFiles;
  final int loadedFiles;
  final int errorFiles;
  final int pendingFiles;
  final int totalSize;
  final int totalLines;
  final int totalCharacters;

  String get formattedSize {
    if (totalSize < 1024) return '${totalSize}B';
    if (totalSize < 1024 * 1024) {
      return '${(totalSize / 1024).toStringAsFixed(1)}KB';
    }
    if (totalSize < 1024 * 1024 * 1024) {
      return '${(totalSize / (1024 * 1024)).toStringAsFixed(1)}MB';
    }
    return '${(totalSize / (1024 * 1024 * 1024)).toStringAsFixed(1)}GB';
  }

  String get formattedCharacters {
    if (totalCharacters < 1000) return totalCharacters.toString();
    if (totalCharacters < 1000000) {
      return '${(totalCharacters / 1000).toStringAsFixed(1)}K';
    }
    return '${(totalCharacters / 1000000).toStringAsFixed(1)}M';
  }
}
