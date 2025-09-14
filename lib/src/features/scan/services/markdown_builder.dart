import '../models/scanned_file.dart';
import '../ui/file_display_helper.dart';

/// Service responsible for building markdown output from selected files
class MarkdownBuilder {
  /// Build markdown from selected files, with an optional special Prompt file.
  ///
  /// - If [prompt] is provided and has non-empty content, its content is written
  ///   verbatim at the very top (no headers, no code fences, no decorations).
  /// - The Prompt file is then excluded from the rest of the markdown.
  String buildMarkdown(
    List<ScannedFile> selectedFiles, {
    ScannedFile? prompt,
  }) {
    final output = StringBuffer();

    // --- Top-of-file prompt (verbatim, preserved exactly) ---
    if (prompt != null) {
      final text = prompt.effectiveContent;
      if (text.trim().isNotEmpty) {
        // Write exactly as-is
        output.write(text);
        // Ensure at least one blank line before the context block
        if (!text.endsWith('\n')) output.writeln();
        output.writeln();
      }
    }

    // --- Build Context Collection (excluding the prompt file) ---
    final context = StringBuffer()
      ..writeln('# Context Collection')
      ..writeln();

    // Sort by path for consistency and exclude prompt (if present)
    final sortedFiles = List<ScannedFile>.from(selectedFiles)
      ..removeWhere((f) => prompt != null && f.id == prompt.id)
      ..sort((a, b) => a.fullPath.compareTo(b.fullPath));

    for (final file in sortedFiles) {
      context
        ..writeln('## ${file.name}')
        ..writeln(file.generateReference())
        ..writeln();

      // Use effectiveContent to support edited and virtual content
      if (file.effectiveContent.isNotEmpty && file.error == null) {
        context
          ..writeln('```${FileDisplayHelper.getLanguageFromFile(file)}')
          ..writeln(file.effectiveContent)
          ..writeln('```')
          ..writeln('\n---\n');
      } else if (file.error != null) {
        context.writeln('```\nERROR: ${file.error}\n```');
      } else if (file.content == null && !file.isVirtual) {
        context.writeln('```\n// Content not loaded\n```');
      }

      context.writeln();
    }

    // Normalize extra blank lines in the CONTEXT section only (leave Prompt intact)
    final contextNormalized =
        context.toString().replaceAll(RegExp(r'\n{3,}'), '\n\n');

    // Compose final output: [Prompt verbatim] + [Context Collection]
    output.write(contextNormalized);

    return output.toString();
  }
}
