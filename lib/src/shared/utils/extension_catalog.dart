import 'package:flutter/material.dart';

/// Catalog of supported file extensions and their categories
class ExtensionCatalog {
  static const Map<String, FileCategory> _extensionCategories = {
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
    '.f90': FileCategory.programming,
    '.f95': FileCategory.programming,
    '.f03': FileCategory.programming,
    '.f08': FileCategory.programming,
    '.for': FileCategory.programming,
    '.ml': FileCategory.programming,
    '.mli': FileCategory.programming,
    '.erl': FileCategory.programming,
    '.hrl': FileCategory.programming,
    '.rkt': FileCategory.programming,
    '.scm': FileCategory.programming,
    '.ss': FileCategory.programming,
    '.lisp': FileCategory.programming,
    '.lsp': FileCategory.programming,
    '.cl': FileCategory.programming,
    '.cob': FileCategory.programming,
    '.cbl': FileCategory.programming,
    '.ada': FileCategory.programming,
    '.adb': FileCategory.programming,
    '.ads': FileCategory.programming,
    '.prolog': FileCategory.programming,
    '.pro': FileCategory.programming,
    '.tcl': FileCategory.programming,
    '.awk': FileCategory.programming,
    '.sed': FileCategory.programming,

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
    '.svg': FileCategory.web,
    '.webp': FileCategory.web,
    '.woff': FileCategory.web,
    '.woff2': FileCategory.web,
    '.ttf': FileCategory.web,
    '.eot': FileCategory.web,
    '.otf': FileCategory.web,

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
    '.env.local': FileCategory.data,
    '.env.development': FileCategory.data,
    '.env.production': FileCategory.data,
    '.csv': FileCategory.data,
    '.tsv': FileCategory.data,
    '.plist': FileCategory.data,
    '.xls': FileCategory.data,
    '.xlsx': FileCategory.data,
    '.ods': FileCategory.data,
    '.xlsm': FileCategory.data,
    '.xlsb': FileCategory.data,
    '.parquet': FileCategory.data,
    '.avro': FileCategory.data,
    '.orc': FileCategory.data,
    '.feather': FileCategory.data,
    '.arrow': FileCategory.data,
    '.ndjson': FileCategory.data,
    '.jsonl': FileCategory.data,
    '.geojson': FileCategory.data,
    '.gpx': FileCategory.data,
    '.kml': FileCategory.data,
    '.kmz': FileCategory.data,
    '.prisma': FileCategory.data,
    '.graphql': FileCategory.data,
    '.gql': FileCategory.data,
    '.proto': FileCategory.data,
    '.thrift': FileCategory.data,
    '.pkl': FileCategory.data,
    '.joblib': FileCategory.data,
    '.h5': FileCategory.data,
    '.safetensors': FileCategory.data,
    '.ckpt': FileCategory.data,
    '.pth': FileCategory.data,

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
    '.mdx': FileCategory.documentation,
    '.rst': FileCategory.documentation,
    '.adoc': FileCategory.documentation,
    '.asciidoc': FileCategory.documentation,
    '.tex': FileCategory.documentation,
    '.latex': FileCategory.documentation,
    '.txt': FileCategory.documentation,
    '.rtf': FileCategory.documentation,
    '.org': FileCategory.documentation,
    '.pod': FileCategory.documentation,
    '.man': FileCategory.documentation,
    '.info': FileCategory.documentation,
    '.texi': FileCategory.documentation,
    '.texinfo': FileCategory.documentation,
    '.ipynb': FileCategory.documentation,
    '.rmd': FileCategory.documentation,
    '.qmd': FileCategory.documentation,
    '.1': FileCategory.documentation,
    '.2': FileCategory.documentation,
    '.3': FileCategory.documentation,
    '.4': FileCategory.documentation,
    '.5': FileCategory.documentation,
    '.6': FileCategory.documentation,
    '.7': FileCategory.documentation,
    '.8': FileCategory.documentation,
    '.9': FileCategory.documentation,

    // Database
    '.sql': FileCategory.database,
    '.psql': FileCategory.database,
    '.mysql': FileCategory.database,
    '.sqlite': FileCategory.database,
    '.mongodb': FileCategory.database,
    '.cql': FileCategory.database,
    '.db': FileCategory.database,
    '.db3': FileCategory.database,
    '.sqlite3': FileCategory.database,
    '.mdb': FileCategory.database,
    '.accdb': FileCategory.database,

    // DevOps & Build
    '.dockerfile': FileCategory.devops,
    '.containerfile': FileCategory.devops,
    '.makefile': FileCategory.devops,
    '.mk': FileCategory.devops,
    '.gradle': FileCategory.devops,
    '.gradle.kts': FileCategory.devops,
    '.groovy': FileCategory.devops,
    '.jenkinsfile': FileCategory.devops,
    '.travis.yml': FileCategory.devops,
    '.gitlab-ci.yml': FileCategory.devops,
    '.github': FileCategory.devops,
    '.circleci': FileCategory.devops,
    '.drone.yml': FileCategory.devops,
    '.buildkite': FileCategory.devops,
    '.teamcity': FileCategory.devops,
    '.appveyor.yml': FileCategory.devops,
    '.azure-pipelines.yml': FileCategory.devops,
    '.bitbucket-pipelines.yml': FileCategory.devops,
    '.codeship-services.yml': FileCategory.devops,
    '.codeship-steps.yml': FileCategory.devops,
    '.wercker.yml': FileCategory.devops,
    '.semaphore.yml': FileCategory.devops,
    '.buildspec.yml': FileCategory.devops,
    '.cloudbuild.yaml': FileCategory.devops,
    '.terraform': FileCategory.devops,
    '.tf': FileCategory.devops,
    '.tfvars': FileCategory.devops,
    '.hcl': FileCategory.devops,
    '.nomad': FileCategory.devops,
    '.consul': FileCategory.devops,
    '.vault': FileCategory.devops,
    '.ansible': FileCategory.devops,
    '.playbook.yml': FileCategory.devops,
    '.inventory': FileCategory.devops,
    '.puppet': FileCategory.devops,
    '.pp': FileCategory.devops,
    '.chef': FileCategory.devops,
    '.cookbook': FileCategory.devops,
    '.recipe.rb': FileCategory.devops,
    '.salt': FileCategory.devops,
    '.sls': FileCategory.devops,
    '.vagrantfile': FileCategory.devops,
    '.packer.json': FileCategory.devops,
    '.pkr.hcl': FileCategory.devops,
    '.vite': FileCategory.devops,
    '.webpack': FileCategory.devops,
    '.rollup': FileCategory.devops,
    '.esbuild': FileCategory.devops,
    '.swc': FileCategory.devops,
    '.turbo': FileCategory.devops,
    '.nx': FileCategory.devops,
    '.jest': FileCategory.devops,
    '.vitest': FileCategory.devops,
    '.cypress': FileCategory.devops,
    '.playwright': FileCategory.devops,
    '.podfile': FileCategory.devops,
    '.podspec': FileCategory.devops,
    '.xcconfig': FileCategory.devops,

    // Other
    '.gitignore': FileCategory.other,
    '.gitattributes': FileCategory.other,
    '.gitkeep': FileCategory.other,
    '.editorconfig': FileCategory.other,
    '.prettierrc': FileCategory.other,
    '.prettierignore': FileCategory.other,
    '.eslintrc': FileCategory.other,
    '.eslintignore': FileCategory.other,
    '.stylelintrc': FileCategory.other,
    '.npmrc': FileCategory.other,
    '.npmignore': FileCategory.other,
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
    '.dockerignore': FileCategory.other,
    '.yarnrc': FileCategory.other,
    '.pnpm': FileCategory.other,
    'bun.lockb': FileCategory.other,
    '.mdc': FileCategory.other,
    '.cursorrules': FileCategory.other,
    '.claude': FileCategory.other,
    '.copilot': FileCategory.other,
    '.aider': FileCategory.other,
    '.promptfile': FileCategory.other,
    '.prompt': FileCategory.other,
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
    '.license': FileCategory.other,
    '.lic': FileCategory.other,
    '.authors': FileCategory.other,
    '.contributors': FileCategory.other,
    '.notice': FileCategory.other,
    '.patents': FileCategory.other,
    '.changelog': FileCategory.other,
    '.changes': FileCategory.other,
    '.history': FileCategory.other,
    '.news': FileCategory.other,
    '.releases': FileCategory.other,
    '.todo': FileCategory.other,
    '.tasks': FileCategory.other,
    '.fixme': FileCategory.other,
    '.bugs': FileCategory.other,
    '.issues': FileCategory.other,
    '.notes': FileCategory.other,
    '.memo': FileCategory.other,
    '.manifest': FileCategory.other,
    '.version': FileCategory.other,
    '.ver': FileCategory.other,
    '.rev': FileCategory.other,
    '.revision': FileCategory.other,
    '.build': FileCategory.other,
    '.dist': FileCategory.other,
    '.out': FileCategory.other,
    '.output': FileCategory.other,
    '.result': FileCategory.other,
    '.results': FileCategory.other,
    '.test': FileCategory.other,
    '.tests': FileCategory.other,
    '.spec': FileCategory.other,
    '.specs': FileCategory.other,
    '.example': FileCategory.other,
    '.examples': FileCategory.other,
    '.sample': FileCategory.other,
    '.samples': FileCategory.other,
    '.demo': FileCategory.other,
    '.demos': FileCategory.other,
    '.template': FileCategory.other,
    '.templates': FileCategory.other,
    '.stub': FileCategory.other,
    '.stubs': FileCategory.other,
    '.mock': FileCategory.other,
    '.mocks': FileCategory.other,
    '.fixture': FileCategory.other,
    '.fixtures': FileCategory.other,
    '.snapshot': FileCategory.other,
    '.snapshots': FileCategory.other,
    '.coverage': FileCategory.other,
    '.report': FileCategory.other,
    '.reports': FileCategory.other,
    '.analysis': FileCategory.other,
    '.analyses': FileCategory.other,
    '.metrics': FileCategory.other,
    '.measure': FileCategory.other,
    '.measures': FileCategory.other,
    '.stat': FileCategory.other,
    '.stats': FileCategory.other,
    '.perf': FileCategory.other,
    '.performance': FileCategory.other,
    '.benchmark': FileCategory.other,
    '.benchmarks': FileCategory.other,
    '.profile': FileCategory.other,
    '.profiles': FileCategory.other,
    '.trace': FileCategory.other,
    '.traces': FileCategory.other,
    '.dump': FileCategory.other,
    '.dumps': FileCategory.other,
    '.core': FileCategory.other,
    '.crash': FileCategory.other,
    '.err': FileCategory.other,
    '.error': FileCategory.other,
    '.errors': FileCategory.other,
    '.warn': FileCategory.other,
    '.warning': FileCategory.other,
    '.warnings': FileCategory.other,
    '.debug': FileCategory.other,
    '.verbose': FileCategory.other,
    '.stacktrace': FileCategory.other,
    '.backtrace': FileCategory.other,
    '.coredump': FileCategory.other,
    '.heapdump': FileCategory.other,
    '.threaddump': FileCategory.other,
    '.memdump': FileCategory.other,
  };

  /// Get all supported extensions from the catalog
  static Map<String, FileCategory> get extensionCategories =>
      Map.unmodifiable(_extensionCategories);

  /// Get all supported extensions
  static Set<String> get supportedExtensions =>
      _extensionCategories.keys.toSet();

  /// Check if a file extension is supported for text extraction
  static bool supportsText(String extension) {
    return _extensionCategories.containsKey(extension.toLowerCase());
  }

  /// Get the category for a file extension
  static FileCategory? getCategory(String extension) {
    return _extensionCategories[extension.toLowerCase()];
  }

  /// Get all extensions for a specific category
  static List<String> getExtensionsByCategory(FileCategory category) {
    return _extensionCategories.entries
        .where((entry) => entry.value == category)
        .map((entry) => entry.key)
        .toList()
      ..sort();
  }

  /// Get extensions grouped by category
  static Map<FileCategory, List<String>> getGroupedExtensions() {
    final grouped = <FileCategory, List<String>>{};

    for (final category in FileCategory.values) {
      final extensions = getExtensionsByCategory(category);
      if (extensions.isNotEmpty) {
        grouped[category] = extensions;
      }
    }

    return grouped;
  }
}

/// File category enumeration
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

/// Top-level function to check if an extension supports text extraction
/// This is the clean API mentioned in the roadmap
bool supportsTextHelper(
    String extension, Map<String, FileCategory>? customExtensions) {
  final ext = extension.toLowerCase();

  // Check custom extensions first (user preferences)
  if (customExtensions != null && customExtensions.containsKey(ext)) {
    return true;
  }

  // Fall back to catalog
  return ExtensionCatalog.supportsText(ext);
}

/// Get category for an extension, considering user preferences
FileCategory? getExtensionCategory(
    String extension, Map<String, FileCategory>? customExtensions) {
  final ext = extension.toLowerCase();

  // Check custom extensions first
  if (customExtensions != null && customExtensions.containsKey(ext)) {
    return customExtensions[ext];
  }

  // Fall back to catalog
  return ExtensionCatalog.getCategory(ext);
}
