import 'package:flutter/material.dart';
import '../models/scanned_file.dart';

/// Shared utility for displaying file information consistently across the app
class FileDisplayHelper {
  FileDisplayHelper._();

  /// Get icon for file based on extension
  static IconData getIconForExtension(String extension) {
    const codeExtensions = {
      '.dart', '.py', '.js', '.ts', '.java', '.cpp', '.c', '.rs', '.go',
      '.rb', '.php', '.swift', '.kt', '.scala', '.r', '.m', '.h',
    };
    const webExtensions = {
      '.html', '.css', '.scss', '.sass', '.less', '.jsx', '.tsx', '.vue',
      '.svelte', '.astro',
    };
    const configExtensions = {
      '.json', '.yaml', '.yml', '.xml', '.toml', '.ini', '.conf', '.config',
      '.env', '.properties',
    };
    const docExtensions = {
      '.md', '.txt', '.rst', '.adoc', '.tex', '.doc', '.docx', '.pdf',
    };
    const scriptExtensions = {
      '.sh', '.bash', '.zsh', '.fish', '.ps1', '.bat', '.cmd',
    };
    const dataExtensions = {
      '.csv', '.tsv', '.xls', '.xlsx', '.sql', '.db', '.sqlite',
    };

    final ext = extension.toLowerCase();

    if (ext.isEmpty) return Icons.insert_drive_file_outlined;
    if (codeExtensions.contains(ext)) return Icons.code;
    if (webExtensions.contains(ext)) return Icons.web;
    if (configExtensions.contains(ext)) return Icons.settings_outlined;
    if (docExtensions.contains(ext)) return Icons.description_outlined;
    if (scriptExtensions.contains(ext)) return Icons.terminal;
    if (dataExtensions.contains(ext)) return Icons.table_chart_outlined;

    return Icons.insert_drive_file_outlined;
  }

  /// Get color for file icon based on extension
  static Color getIconColor(String extension, BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final ext = extension.toLowerCase();

    // Special colors for certain file types
    if (ext == '.dart') return Colors.blue.shade600;
    if (ext == '.py') return Colors.green.shade600;
    if (ext == '.js' || ext == '.ts') return Colors.amber.shade700;
    if (ext == '.html' || ext == '.css') return Colors.orange.shade600;
    if (ext == '.json' || ext == '.yaml') return Colors.purple.shade600;
    if (ext == '.md') return Colors.blueGrey.shade600;

    return colorScheme.onSurface.withOpacity(0.7);
  }

  /// Build status indicator for file
  static Widget? buildStatusIndicator(BuildContext context, ScannedFile file) {
    if (file.isDirty) {
      return Tooltip(
        message: 'Modified',
        child: Icon(
          Icons.edit,
          size: 14,
          color: Colors.orange.shade700,
        ),
      );
    }

    if (file.error != null) {
      return Tooltip(
        message: file.error,
        child: Icon(
          Icons.error_outline,
          size: 14,
          color: Theme.of(context).colorScheme.error,
        ),
      );
    }

    if (file.isVirtual) {
      return Tooltip(
        message: 'Virtual file',
        child: Icon(
          Icons.add_circle_outline,
          size: 14,
          color: Colors.green.shade600,
        ),
      );
    }

    return null;
  }

  /// Get status text for file
  static String getStatusText(ScannedFile file) {
    if (file.error != null) return 'Error';
    if (file.isVirtual) return 'Virtual';
    if (file.isDirty) return 'Modified';
    if (file.content != null) return 'Loaded';
    return 'Pending';
  }

  /// Get status color for file
  static Color getStatusColor(BuildContext context, ScannedFile file) {
    final colorScheme = Theme.of(context).colorScheme;

    if (file.error != null) return colorScheme.error;
    if (file.isVirtual) return Colors.green;
    if (file.isDirty) return Colors.orange;
    if (file.content != null) return colorScheme.primary;
    return colorScheme.onSurface.withOpacity(0.5);
  }

  /// Format file size for display
  static String formatFileSize(int bytes) {
    if (bytes < 1024) return '${bytes}B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)}KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)}MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)}GB';
  }

  /// Get language identifier for syntax highlighting
  static String getLanguageId(String extension) {
    final languageMap = {
      '.dart': 'dart',
      '.py': 'python',
      '.js': 'javascript',
      '.ts': 'typescript',
      '.java': 'java',
      '.cpp': 'cpp',
      '.c': 'c',
      '.cs': 'csharp',
      '.go': 'go',
      '.rs': 'rust',
      '.rb': 'ruby',
      '.php': 'php',
      '.swift': 'swift',
      '.kt': 'kotlin',
      '.html': 'html',
      '.css': 'css',
      '.scss': 'scss',
      '.json': 'json',
      '.yaml': 'yaml',
      '.yml': 'yaml',
      '.xml': 'xml',
      '.md': 'markdown',
      '.sql': 'sql',
      '.sh': 'shell',
      '.bash': 'shell',
      '.ps1': 'powershell',
      '.bat': 'batch',
    };

    return languageMap[extension.toLowerCase()] ?? 'plaintext';
  }
}
