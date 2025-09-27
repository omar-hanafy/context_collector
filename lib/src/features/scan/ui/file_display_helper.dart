import 'package:flutter/material.dart';
import 'package:flutter_helper_utils/flutter_helper_utils.dart';

import '../models/file_category.dart';
import '../models/scanned_file.dart';

/// Shared utility for displaying file information consistently across the app
class FileDisplayHelper {
  FileDisplayHelper._();

  /// Get icon for file based on extension
  static IconData getIconForExtension(String extension) {
    final ext = extension.toLowerCase();
    if (ext.isEmpty) return Icons.insert_drive_file_outlined;

    // Use the single source of truth: extensionCatalog
    final category = getCategoryForExtension(ext);
    return category.icon;
  }

  /// Get color for file icon based on extension
  static Color getIconColor(String extension, BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final ext = extension.toLowerCase();

    // Calm, role-based palette by category (no rainbow per extension)
    final category = getCategoryForExtension(ext);
    return switch (category) {
      FileCategory.programming ||
      FileCategory.web => cs.primary.setOpacity(0.90),
      FileCategory.data ||
      FileCategory.database => cs.secondary.setOpacity(0.90),
      FileCategory.script => cs.tertiary.setOpacity(0.90),
      FileCategory.documentation => cs.onSurfaceVariant,
      _ => cs.onSurfaceVariant,
    };
  }

  /// Build status indicator for file
  static Widget? buildStatusIndicator(BuildContext context, ScannedFile file) {
    if (file.isVirtual) {
      return null;
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

    return null;
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

  /// Get language for syntax highlighting from a file
  static String getLanguageFromFile(ScannedFile file) {
    return file.extension.isEmpty ? 'plaintext' : getLanguageId(file.extension);
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
}
