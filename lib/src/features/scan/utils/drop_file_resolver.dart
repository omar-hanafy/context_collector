import 'dart:io';

import 'package:path/path.dart' as path;

/// Utility class to handle desktop_drop temporary files
///
/// When files are dragged from certain applications (like VSCode),
/// desktop_drop creates temporary files in the app's sandboxed container
/// that may lose their original extensions.
class DropFileResolver {
  /// Check if a file path is a desktop_drop temporary file
  static bool isTemporaryDropFile(String filePath) {
    return filePath.contains('/tmp/Drops/') ||
        filePath.contains(r'\tmp\Drops\') ||
        filePath.contains(
          '/Containers/com.omarhanafy.context.collector/Data/tmp/Drops/',
        );
  }

  /// Try to resolve the original file information from a temporary drop file
  /// Returns a map with 'extension' and 'originalName' if inference is successful
  static Map<String, String?> resolveFileInfo(String filePath) {
    final fileName = path.basename(filePath);
    final result = <String, String?>{
      'extension': null,
      'originalName': null,
    };

    // If the file already has an extension, use it
    final currentExtension = path.extension(filePath);
    if (currentExtension.isNotEmpty) {
      result['extension'] = currentExtension;
      return result;
    }

    // Common patterns for temporary files from VSCode drops
    // e.g., "lib-1" might be "lib.dart", "index-2" might be "index.js"
    final patterns = [
      // Pattern: name-number (e.g., lib-1, index-2)
      RegExp(r'^(.+)-(\d+)$'),
    ];

    for (final pattern in patterns) {
      final match = pattern.firstMatch(fileName);
      if (match != null) {
        final baseName = match.group(1);
        if (baseName != null) {
          // Try to infer extension based on common file names
          final extension = _inferExtensionFromName(baseName);
          if (extension != null) {
            result['extension'] = extension;
            result['originalName'] = '$baseName$extension';
            return result;
          }
        }
      }
    }

    // Try to infer from file content if name-based inference fails
    final contentExtension = _inferExtensionFromContent(filePath);
    if (contentExtension != null) {
      result['extension'] = contentExtension;
    }

    return result;
  }

  /// Infer file extension based on common file names
  static String? _inferExtensionFromName(String baseName) {
    final commonExtensions = {
      // Common config files
      'package': '.json',
      'tsconfig': '.json',
      'eslintrc': '.json',
      'prettierrc': '.json',
      'babel.config': '.js',
      'webpack.config': '.js',
      'vite.config': '.js',
      'jest.config': '.js',
      'rollup.config': '.js',

      // Common source files
      'index': '.js', // Could also be .ts, .tsx, .jsx, .html
      'main': '.dart', // In Flutter context
      'app': '.dart',
      'test': '.dart',
      'spec': '.js',

      // Build files
      'makefile': '',
      'dockerfile': '',
      'readme': '.md',
      'changelog': '.md',
      'license': '',

      // Shell scripts
      'build': '.sh',
      'deploy': '.sh',
      'setup': '.sh',
      'install': '.sh',
    };

    final lowerName = baseName.toLowerCase();
    return commonExtensions[lowerName];
  }

  /// Try to infer file extension from content
  static String? _inferExtensionFromContent(String filePath) {
    try {
      final file = File(filePath);
      if (!file.existsSync()) return null;

      // Read first few lines to detect file type
      final lines = file.readAsLinesSync().take(10).toList();
      if (lines.isEmpty) return null;

      final firstLine = lines.first.trim();

      // Shebang detection
      if (firstLine.startsWith('#!')) {
        if (firstLine.contains('python')) return '.py';
        if (firstLine.contains('node')) return '.js';
        if (firstLine.contains('bash') || firstLine.contains('sh')) {
          return '.sh';
        }
        if (firstLine.contains('ruby')) return '.rb';
        if (firstLine.contains('perl')) return '.pl';
        if (firstLine.contains('php')) return '.php';
      }

      // Default to .txt if it's readable text
      return '.txt';
    } catch (e) {
      // If we can't read the file as text, it might be binary
      return null;
    }
  }
}
