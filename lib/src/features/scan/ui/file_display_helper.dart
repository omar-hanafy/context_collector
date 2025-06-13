import 'package:flutter/material.dart';
import 'package:flutter_helper_utils/flutter_helper_utils.dart';

import '../models/file_category.dart';
import '../models/scanned_file.dart';

/// Shared utility for displaying file information consistently across the app
class FileDisplayHelper {
  FileDisplayHelper._();

  /// Get icon for file based on extension
  static IconData getIconForExtension(String extension) {
    const codeExtensions = {
      '.dart',
      '.py',
      '.js',
      '.ts',
      '.java',
      '.cpp',
      '.c',
      '.rs',
      '.go',
      '.rb',
      '.php',
      '.swift',
      '.kt',
      '.scala',
      '.r',
      '.m',
      '.h',
    };
    const webExtensions = {
      '.html',
      '.css',
      '.scss',
      '.sass',
      '.less',
      '.jsx',
      '.tsx',
      '.vue',
      '.svelte',
      '.astro',
    };
    const configExtensions = {
      '.json',
      '.yaml',
      '.yml',
      '.xml',
      '.toml',
      '.ini',
      '.conf',
      '.config',
      '.env',
      '.properties',
    };
    const docExtensions = {
      '.md',
      '.txt',
      '.rst',
      '.adoc',
      '.tex',
      '.doc',
      '.docx',
      '.pdf',
    };
    const scriptExtensions = {
      '.sh',
      '.bash',
      '.zsh',
      '.fish',
      '.ps1',
      '.bat',
      '.cmd',
    };
    const dataExtensions = {
      '.csv',
      '.tsv',
      '.xls',
      '.xlsx',
      '.sql',
      '.db',
      '.sqlite',
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

    return colorScheme.onSurface.addOpacity(0.7);
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
    return colorScheme.onSurface.addOpacity(0.5);
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

  /// Get display name for a file (handles virtual files and VS Code temp files)
  static String getDisplayName(ScannedFile file) {
    return file.isVirtual ? file.name : (file.displayPath ?? file.name);
  }

  /// Get language for syntax highlighting from a file
  static String getLanguageFromFile(ScannedFile file) {
    return file.extension.isEmpty ? 'plaintext' : getLanguageId(file.extension);
  }

  /// Get the best path to display for a file
  /// Priority: displayPath > relativePath > fullPath
  static String getPathForDisplay(ScannedFile file) {
    return file.displayPath ?? file.relativePath ?? file.fullPath;
  }

  /// Comprehensive extension catalog - single source of truth
  static const Map<String, FileCategory> extensionCatalog = {
    // Programming Languages
    '.dart': FileCategory.programming,
    '.py': FileCategory.programming,
    '.js': FileCategory.programming,
    '.ts': FileCategory.programming,
    '.java': FileCategory.programming,
    '.cpp': FileCategory.programming,
    '.c': FileCategory.programming,
    '.cs': FileCategory.programming,
    '.go': FileCategory.programming,
    '.rs': FileCategory.programming,
    '.rb': FileCategory.programming,
    '.php': FileCategory.programming,
    '.swift': FileCategory.programming,
    '.kt': FileCategory.programming,
    '.scala': FileCategory.programming,
    '.r': FileCategory.programming,
    '.m': FileCategory.programming,
    '.h': FileCategory.programming,

    // Web Technologies
    '.html': FileCategory.web,
    '.css': FileCategory.web,
    '.scss': FileCategory.web,
    '.sass': FileCategory.web,
    '.less': FileCategory.web,
    '.jsx': FileCategory.web,
    '.tsx': FileCategory.web,
    '.vue': FileCategory.web,
    '.svelte': FileCategory.web,
    '.astro': FileCategory.web,

    // Data & Config
    '.json': FileCategory.data,
    '.yaml': FileCategory.data,
    '.yml': FileCategory.data,
    '.xml': FileCategory.data,
    '.toml': FileCategory.data,
    '.ini': FileCategory.data,
    '.conf': FileCategory.data,
    '.config': FileCategory.data,
    '.env': FileCategory.data,
    '.properties': FileCategory.data,

    // Scripts
    '.sh': FileCategory.script,
    '.bash': FileCategory.script,
    '.zsh': FileCategory.script,
    '.fish': FileCategory.script,
    '.ps1': FileCategory.script,
    '.bat': FileCategory.script,
    '.cmd': FileCategory.script,

    // Documentation
    '.md': FileCategory.documentation,
    '.txt': FileCategory.documentation,
    '.rst': FileCategory.documentation,
    '.adoc': FileCategory.documentation,
    '.tex': FileCategory.documentation,
    '.doc': FileCategory.documentation,
    '.docx': FileCategory.documentation,
    '.pdf': FileCategory.documentation,

    // Database
    '.sql': FileCategory.database,
    '.db': FileCategory.database,
    '.sqlite': FileCategory.database,

    // Data files
    '.csv': FileCategory.data,
    '.tsv': FileCategory.data,
    '.xls': FileCategory.data,
    '.xlsx': FileCategory.data,
  };

  /// Get file category for an extension
  static FileCategory getCategoryForExtension(String extension) {
    return extensionCatalog[extension.toLowerCase()] ?? FileCategory.other;
  }

  /// Get all supported extensions
  static Set<String> get supportedExtensions => extensionCatalog.keys.toSet();

  /// Get extensions for a specific category
  static Set<String> getExtensionsForCategory(FileCategory category) {
    return extensionCatalog.entries
        .where((entry) => entry.value == category)
        .map((entry) => entry.key)
        .toSet();
  }
}
