import '../models/scanned_file.dart';
import '../ui/file_display_helper.dart';

/// Service responsible for building markdown output from selected files
class MarkdownBuilder {
  /// Build markdown from selected files
  String buildMarkdown(List<ScannedFile> selectedFiles) {
    final buffer = StringBuffer()
      ..writeln('# Context Collection')
      ..writeln();

    // Sort by path for consistency
    final sortedFiles = List<ScannedFile>.from(selectedFiles)
      ..sort((a, b) => a.fullPath.compareTo(b.fullPath));

    for (final file in sortedFiles) {
      buffer
        ..writeln('## ${file.name}')
        ..writeln(file.generateReference())
        ..writeln();

      // Use effectiveContent to support edited and virtual content
      if (file.effectiveContent.isNotEmpty && file.error == null) {
        buffer
          ..writeln('```${FileDisplayHelper.getLanguageFromFile(file)}')
          ..writeln(file.effectiveContent)
          ..writeln('```')
          ..writeln('\n---\n');
      } else if (file.error != null) {
        buffer.writeln('```\nERROR: ${file.error}\n```');
      } else if (file.content == null && !file.isVirtual) {
        buffer.writeln('```\n// Content not loaded\n```');
      }

      buffer.writeln();
    }

    return buffer.toString().replaceAll(RegExp(r'\n{3,}'), '\n\n');
  }
}
