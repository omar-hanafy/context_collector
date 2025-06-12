import 'package:flutter/material.dart';

/// Minimal FileCategory enum to support settings
/// In the simplified scan feature, we don't actually filter by extensions
enum FileCategory {
  programming('Programming Languages', Icons.code),
  web('Web Technologies', Icons.web),
  data('Data & Config', Icons.data_object),
  script('Scripts', Icons.terminal),
  documentation('Documentation', Icons.description),
  database('Database', Icons.storage),
  devops('DevOps & Build', Icons.build_circle),
  other('Other', Icons.insert_drive_file);

  const FileCategory(this.displayName, this.icon);

  final String displayName;
  final IconData icon;
}

/// Minimal ExtensionCatalog to support settings
/// The simplified scan feature accepts all files, so this is just for compatibility
class ExtensionCatalog {
  static const Map<String, FileCategory> extensionCategories = {
    '.dart': FileCategory.programming,
    '.py': FileCategory.programming,
    '.js': FileCategory.programming,
    '.ts': FileCategory.programming,
    '.java': FileCategory.programming,
    '.html': FileCategory.web,
    '.css': FileCategory.web,
    '.json': FileCategory.data,
    '.yaml': FileCategory.data,
    '.yml': FileCategory.data,
    '.xml': FileCategory.data,
    '.sh': FileCategory.script,
    '.md': FileCategory.documentation,
    '.txt': FileCategory.documentation,
    '.sql': FileCategory.database,
  };
  
  static Set<String> get supportedExtensions => extensionCategories.keys.toSet();
}
