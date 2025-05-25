import '../../../shared/utils/language_mapper.dart';
import '../domain/scanned_file.dart';

/// Service responsible for assembling content from multiple files into a combined format
/// This separates disk I/O concerns from UI state management
class ContentAssembler {
  /// Build a combined markdown-formatted string from selected files
  Future<String> buildMerged(List<ScannedFile> selectedFiles) async {
    final buffer = StringBuffer()
      ..writeln('# Context Collection')
      ..writeln();

    // Sort files by path for better organization
    final sortedFiles = List<ScannedFile>.from(selectedFiles)
      ..sort((a, b) => a.fullPath.compareTo(b.fullPath));

    for (final file in sortedFiles) {
      // Get the language identifier for syntax highlighting
      final language = LanguageMapper.getLanguageForFile(file.fullPath);

      buffer
        ..writeln('## ${file.name}')
        ..writeln(file.generateReference())
        ..writeln();

      if (file.content != null) {
        // Add code block with language identifier for syntax highlighting
        buffer
          ..writeln('```$language')
          ..writeln(file.content)
          ..writeln('```')
          ..writeln('\n---\n');
      } else if (file.error != null) {
        buffer.writeln('```\nERROR: ${file.error}\n```');
      } else {
        buffer.writeln('```\nPENDING: Content not loaded\n```');
      }

      buffer
        ..writeln()
        ..writeln();
    }

    // Clean up excessive whitespace before returning
    return _cleanupWhitespace(buffer.toString());
  }

  /// Remove multiple consecutive empty lines and replace with single empty line
  String _cleanupWhitespace(String content) {
    // Replace 3 or more consecutive newlines with just 2 newlines (1 empty line)
    return content
        // First, normalize different line endings to \n
        .replaceAll('\r\n', '\n')
        .replaceAll('\r', '\n')
        // Remove multiple consecutive empty lines (3+ newlines become 2)
        .replaceAll(RegExp(r'\n{3,}'), '\n\n')
        // Clean up any trailing whitespace at the end of lines
        .replaceAll(RegExp(r'[ \t]+$', multiLine: true), '')
        // Remove excessive whitespace at the very end of the document
        .replaceAll(RegExp(r'\n+$'), '\n');
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