import '../models/scanned_file.dart';
import '../ui/file_display_helper.dart';

/// Service responsible for building markdown output from selected files
class MarkdownBuilder {
  /// Build markdown from selected files.
  ///
  /// - If a "Header" file is selected, its content is written verbatim at the top.
  /// - If a "Footer" file is selected, its content is written verbatim at the bottom.
  /// - "Header" and "Footer" are excluded from the main Context Collection block.
  String buildMarkdown(List<ScannedFile> selectedFiles) {
    final output = StringBuffer();

    final headerFile = selectedFiles
        .where((f) => f.isVirtual && f.name == 'Header')
        .firstOrNull;

    final footerFile = selectedFiles
        .where((f) => f.isVirtual && f.name == 'Footer')
        .firstOrNull;

    // --- Header (verbatim) ---
    if (headerFile != null) {
      final text = headerFile.effectiveContent;
      if (text.trim().isNotEmpty) {
        output.write(text);
        if (!text.endsWith('\n')) output.writeln();
        output.writeln();
      }
    }

    // --- Build Context Collection (excluding Header/Footer) ---
    final context = StringBuffer()
      ..writeln('# Context Collection')
      ..writeln();

    final contextFiles = List<ScannedFile>.from(selectedFiles)
      ..removeWhere(
        (f) =>
            f.isVirtual &&
            (f.id == headerFile?.id || f.id == footerFile?.id),
      )
      ..sort((a, b) => a.fullPath.compareTo(b.fullPath));

    for (final file in contextFiles) {
      context
        ..writeln('## ${file.name}')
        ..writeln(file.generateReference())
        ..writeln();

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

    // Normalize extra blank lines in the CONTEXT section only
    final contextNormalized =
        context.toString().replaceAll(RegExp(r'\n{3,}'), '\n\n');

    output.write(contextNormalized);

    // --- Footer (verbatim) ---
    if (footerFile != null) {
      final text = footerFile.effectiveContent;
      if (text.trim().isNotEmpty) {
        // Ensure separation from context block
        if (!output.toString().endsWith('\n\n')) output.writeln();
        output.write(text);
        if (!text.endsWith('\n')) output.writeln();
      }
    }

    return output.toString();
  }
}
