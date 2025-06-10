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
      final content = lines.join('\n');

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

      // Language-specific patterns
      if (_isDartCode(content)) return '.dart';
      if (_isJavaScriptCode(content)) return '.js';
      if (_isPythonCode(content)) return '.py';
      if (_isJavaCode(content)) return '.java';
      if (_isCppCode(content)) return '.cpp';
      if (_isHtmlCode(content)) return '.html';
      if (_isCssCode(content)) return '.css';
      if (_isJsonCode(content)) return '.json';
      if (_isXmlCode(content)) return '.xml';
      if (_isMarkdownCode(content)) return '.md';
      if (_isYamlCode(content)) return '.yaml';
      if (_isShellScript(content)) return '.sh';

      // Default to .txt if it's readable text
      return '.txt';
    } catch (e) {
      // If we can't read the file as text, it might be binary
      return null;
    }
  }

  static bool _isDartCode(String content) {
    return content.contains("import 'dart:") ||
        content.contains("import 'package:") ||
        content.contains('class ') && content.contains(' extends ') ||
        content.contains('void main()') ||
        content.contains('Widget build(');
  }

  static bool _isJavaScriptCode(String content) {
    return content.contains('function ') ||
        content.contains('const ') ||
        content.contains('let ') ||
        content.contains('var ') ||
        content.contains('=>') ||
        content.contains('require(') ||
        content.contains('import ') && content.contains(' from ');
  }

  static bool _isPythonCode(String content) {
    return content.contains('def ') ||
        content.contains('class ') && content.contains(':') ||
        content.contains('import ') ||
        content.contains('from ') && content.contains(' import ') ||
        content.contains('if __name__');
  }

  static bool _isJavaCode(String content) {
    return content.contains('public class ') ||
        content.contains('private ') ||
        content.contains('protected ') ||
        content.contains('package ') ||
        content.contains('import java.');
  }

  static bool _isCppCode(String content) {
    return content.contains('#include ') ||
        content.contains('using namespace ') ||
        content.contains('int main(') ||
        content.contains('std::');
  }

  static bool _isHtmlCode(String content) {
    return content.contains('<!DOCTYPE') ||
        content.contains('<html') ||
        content.contains('<head>') ||
        content.contains('<body>') ||
        (content.contains('<div') && content.contains('</div>'));
  }

  static bool _isCssCode(String content) {
    return (content.contains('{') &&
            content.contains('}') &&
            content.contains(':') &&
            content.contains(';')) &&
        (content.contains('color:') ||
            content.contains('background:') ||
            content.contains('margin:') ||
            content.contains('padding:') ||
            content.contains('font-'));
  }

  static bool _isJsonCode(String content) {
    final trimmed = content.trim();
    return (trimmed.startsWith('{') && trimmed.contains('}')) ||
        (trimmed.startsWith('[') && trimmed.contains(']'));
  }

  static bool _isXmlCode(String content) {
    return content.contains('<?xml') ||
        (content.contains('<') &&
            content.contains('>') &&
            content.contains('</'));
  }

  static bool _isMarkdownCode(String content) {
    return content.contains('# ') ||
        content.contains('## ') ||
        content.contains('```') ||
        content.contains('- ') ||
        content.contains('* ') ||
        content.contains('[') && content.contains('](');
  }

  static bool _isYamlCode(String content) {
    return content.contains(':') &&
        (content.contains('  ') || content.contains('\t')) &&
        !content.contains('{') &&
        !content.contains('}');
  }

  static bool _isShellScript(String content) {
    return content.contains('#!/bin/') ||
        content.contains('echo ') ||
        content.contains('export ') ||
        content.contains('if [') ||
        content.contains('then') ||
        content.contains('fi') ||
        content.contains('for ') && content.contains('do');
  }
}
