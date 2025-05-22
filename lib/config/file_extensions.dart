import 'package:flutter/material.dart';

class FileExtensionConfig {
  static const Map<String, FileCategory> extensionCategories = {
    // Programming Languages
    '.dart': FileCategory.programming,
    '.py': FileCategory.programming,
    '.js': FileCategory.programming,
    '.ts': FileCategory.programming,
    '.jsx': FileCategory.programming,
    '.tsx': FileCategory.programming,
    '.java': FileCategory.programming,
    '.kt': FileCategory.programming,
    '.swift': FileCategory.programming,
    '.cpp': FileCategory.programming,
    '.c': FileCategory.programming,
    '.h': FileCategory.programming,
    '.hpp': FileCategory.programming,
    '.cs': FileCategory.programming,
    '.php': FileCategory.programming,
    '.rb': FileCategory.programming,
    '.go': FileCategory.programming,
    '.rs': FileCategory.programming,
    '.scala': FileCategory.programming,
    '.r': FileCategory.programming,
    '.m': FileCategory.programming,
    '.mm': FileCategory.programming,
    '.lua': FileCategory.programming,
    '.pl': FileCategory.programming,
    '.ex': FileCategory.programming,
    '.exs': FileCategory.programming,
    '.elm': FileCategory.programming,
    '.clj': FileCategory.programming,
    '.coffee': FileCategory.programming,
    '.vb': FileCategory.programming,
    '.fs': FileCategory.programming,
    '.hs': FileCategory.programming,
    '.nim': FileCategory.programming,
    '.cr': FileCategory.programming,
    '.jl': FileCategory.programming,
    '.pas': FileCategory.programming,
    '.d': FileCategory.programming,
    '.zig': FileCategory.programming,
    '.v': FileCategory.programming,
    '.sol': FileCategory.programming,

    // Web Technologies
    '.html': FileCategory.web,
    '.htm': FileCategory.web,
    '.css': FileCategory.web,
    '.scss': FileCategory.web,
    '.sass': FileCategory.web,
    '.less': FileCategory.web,
    '.vue': FileCategory.web,
    '.svelte': FileCategory.web,
    '.astro': FileCategory.web,

    // Data & Config
    '.json': FileCategory.data,
    '.xml': FileCategory.data,
    '.yaml': FileCategory.data,
    '.yml': FileCategory.data,
    '.toml': FileCategory.data,
    '.ini': FileCategory.data,
    '.conf': FileCategory.data,
    '.cfg': FileCategory.data,
    '.properties': FileCategory.data,
    '.env': FileCategory.data,
    '.csv': FileCategory.data,
    '.tsv': FileCategory.data,
    '.plist': FileCategory.data,

    // Scripts
    '.sh': FileCategory.script,
    '.bash': FileCategory.script,
    '.zsh': FileCategory.script,
    '.fish': FileCategory.script,
    '.ps1': FileCategory.script,
    '.psm1': FileCategory.script,
    '.psd1': FileCategory.script,
    '.bat': FileCategory.script,
    '.cmd': FileCategory.script,
    '.vbs': FileCategory.script,
    '.ahk': FileCategory.script,

    // Documentation
    '.md': FileCategory.documentation,
    '.markdown': FileCategory.documentation,
    '.rst': FileCategory.documentation,
    '.adoc': FileCategory.documentation,
    '.asciidoc': FileCategory.documentation,
    '.tex': FileCategory.documentation,
    '.latex': FileCategory.documentation,
    '.txt': FileCategory.documentation,
    '.rtf': FileCategory.documentation,
    '.org': FileCategory.documentation,

    // Database
    '.sql': FileCategory.database,
    '.psql': FileCategory.database,
    '.mysql': FileCategory.database,
    '.sqlite': FileCategory.database,
    '.mongodb': FileCategory.database,
    '.cql': FileCategory.database,

    // DevOps & Build
    '.dockerfile': FileCategory.devops,
    '.containerfile': FileCategory.devops,
    '.makefile': FileCategory.devops,
    '.mk': FileCategory.devops,
    '.gradle': FileCategory.devops,
    '.groovy': FileCategory.devops,
    '.jenkinsfile': FileCategory.devops,
    '.travis.yml': FileCategory.devops,
    '.gitlab-ci.yml': FileCategory.devops,
    '.github': FileCategory.devops,
    '.circleci': FileCategory.devops,
    '.drone.yml': FileCategory.devops,

    // Other
    '.gitignore': FileCategory.other,
    '.gitattributes': FileCategory.other,
    '.editorconfig': FileCategory.other,
    '.prettierrc': FileCategory.other,
    '.eslintrc': FileCategory.other,
    '.stylelintrc': FileCategory.other,
    '.npmrc': FileCategory.other,
    '.nvmrc': FileCategory.other,
    '.rvmrc': FileCategory.other,
    '.ruby-version': FileCategory.other,
    '.python-version': FileCategory.other,
    '.node-version': FileCategory.other,
    '.tool-versions': FileCategory.other,
    '.babelrc': FileCategory.other,
    '.browserslistrc': FileCategory.other,
    '.huskyrc': FileCategory.other,
    '.lintstagedrc': FileCategory.other,
    '.commitlintrc': FileCategory.other,
    '.renovaterc': FileCategory.other,
    '.dependabot': FileCategory.other,
    '.log': FileCategory.other,
    '.lock': FileCategory.other,
    '.pid': FileCategory.other,
    '.cache': FileCategory.other,
    '.tmp': FileCategory.other,
    '.temp': FileCategory.other,
    '.bak': FileCategory.other,
    '.backup': FileCategory.other,
    '.old': FileCategory.other,
    '.orig': FileCategory.other,
    '.rej': FileCategory.other,
    '.diff': FileCategory.other,
    '.patch': FileCategory.other,
    '.pub': FileCategory.other,
    '.pem': FileCategory.other,
    '.key': FileCategory.other,
    '.crt': FileCategory.other,
    '.cer': FileCategory.other,
    '.p12': FileCategory.other,
    '.pfx': FileCategory.other,
    '.jks': FileCategory.other,
  };

  static Set<String> get supportedExtensions =>
      extensionCategories.keys.toSet();

  static bool isTextFile(String extension) {
    return extensionCategories.containsKey(extension.toLowerCase());
  }

  static FileCategory? getCategory(String extension) {
    return extensionCategories[extension.toLowerCase()];
  }

  static List<String> getExtensionsByCategory(FileCategory category) {
    return extensionCategories.entries
        .where((entry) => entry.value == category)
        .map((entry) => entry.key)
        .toList()
      ..sort();
  }

  static Map<FileCategory, List<String>> getGroupedExtensions() {
    final Map<FileCategory, List<String>> grouped = {};

    for (final category in FileCategory.values) {
      final extensions = getExtensionsByCategory(category);
      if (extensions.isNotEmpty) {
        grouped[category] = extensions;
      }
    }

    return grouped;
  }
}

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
