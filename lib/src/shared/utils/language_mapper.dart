import 'dart:io';

import 'package:path/path.dart' as path;

/// Maps file extensions to language identifiers for syntax highlighting
/// Enhanced version based on the Python implementation
class LanguageMapper {
  /// Maps file extensions to language identifiers for code snippets
  /// Only includes mappings where extension != language identifier
  static const Map<String, String> _extensionToLanguage = {
    // Systems Programming - Headers and alternate extensions
    '.h': 'c',
    '.cc': 'cpp',
    '.cxx': 'cpp',
    '.c++': 'cpp',
    '.hpp': 'cpp',
    '.hxx': 'cpp',
    '.h++': 'cpp',
    '.hh': 'cpp',
    '.rlib': 'rust',
    '.rs.in': 'rust',

    // JVM Languages - Alternate extensions
    '.jar': 'java',
    '.class': 'java',
    '.jav': 'java',
    '.kts': 'kotlin', // Kotlin script
    '.ktm': 'kotlin',
    '.sc': 'scala',
    '.sbt': 'scala',
    '.gvy': 'groovy',
    '.gy': 'groovy',
    '.gradle': 'groovy',
    '.jenkinsfile': 'groovy',

    // Scripting Languages - Alternate extensions
    '.pyw': 'python', // Python Windows
    '.pyx': 'python', // Cython
    '.py': 'python', // python
    '.pxd': 'python', // Cython
    '.pyi': 'python', // Python stub
    '.py3': 'python',
    '.rpy': 'python', // Ren'Py
    '.sage': 'python',
    '.wsgi': 'python',
    '.mjs': 'javascript', // ES modules
    '.cjs': 'javascript', // CommonJS
    '.jsx': 'javascript', // React JSX (some prefer jsx highlighting)
    '.tsx': 'typescript', // TypeScript JSX
    '.d.ts': 'typescript', // TypeScript definitions
    '.rbw': 'ruby', // Ruby Windows
    '.erb': 'ruby', // Embedded Ruby
    '.gemspec': 'ruby',
    '.podspec': 'ruby',
    '.rake': 'ruby',
    '.ru': 'ruby', // Rack config
    '.thor': 'ruby',
    '.pm': 'perl', // Perl module
    '.pod': 'perl', // Perl documentation
    '.t': 'perl', // Perl test
    '.phtml': 'php',
    '.php3': 'php',
    '.php4': 'php',
    '.php5': 'php',
    '.php7': 'php',
    '.phps': 'php',
    '.phar': 'php',
    '.bash': 'shell',
    '.zsh': 'shell',
    '.fish': 'shell',
    '.ksh': 'shell',
    '.csh': 'shell',
    '.tcsh': 'shell',
    '.ash': 'shell',
    '.dash': 'shell',
    '.bashrc': 'shell',
    '.zshrc': 'shell',
    '.profile': 'shell',
    '.ps1': 'powershell',
    '.psm1': 'powershell',
    '.psd1': 'powershell',
    '.pssc': 'powershell',

    // Mobile Development
    '.m': 'objective-c',
    '.mm': 'objective-c',

    // Web Technologies - Alternate extensions and frameworks
    '.htm': 'html',
    '.xhtml': 'html',
    '.shtml': 'html',
    '.cshtml': 'html', // Razor
    '.vue': 'html', // Vue.js (or could be 'vue' if supported)
    '.svelte': 'html',
    '.hbs': 'handlebars',
    '.handlebars': 'handlebars',
    '.mustache': 'handlebars',
    '.ejs': 'html', // EJS templates
    '.pug': 'pug', // Pug templates
    '.slim': 'slim', // Slim templates
    '.scss': 'scss',
    '.sass': 'sass',
    '.less': 'less',
    '.styl': 'stylus',
    '.stylus': 'stylus',

    // Data & Config Formats - Alternate extensions
    '.jsonl': 'json', // JSON Lines
    '.json5': 'json', // JSON5
    '.jsonc': 'json', // JSON with comments
    '.yml': 'yaml',
    '.yaml-tmpl': 'yaml',
    '.yml.tmpl': 'yaml',
    '.toml': 'toml',
    '.tml': 'toml',
    '.xsl': 'xml',
    '.xslt': 'xml',
    '.plist': 'xml',
    '.rss': 'xml',
    '.atom': 'xml',
    '.svg': 'xml',
    '.cfg': 'ini',
    '.conf': 'ini',
    '.config': 'ini',
    '.properties': 'ini',
    '.env': 'ini', // Environment files
    '.dotenv': 'ini',
    '.gql': 'graphql',
    '.graphqls': 'graphql',
    '.proto': 'protobuf',
    '.proto3': 'protobuf',

    // Documentation - Alternate extensions
    '.markdown': 'markdown',
    '.mdown': 'markdown',
    '.md': 'markdown',
    '.mkd': 'markdown',
    '.mkdn': 'markdown',
    '.mdwn': 'markdown',
    '.mdx': 'markdown', // MDX (Markdown + JSX)
    '.rst': 'restructuredtext',
    '.rest': 'restructuredtext',
    '.restx': 'restructuredtext',
    '.rtxt': 'restructuredtext',
    '.adoc': 'asciidoc',
    '.asciidoc': 'asciidoc',
    '.asc': 'asciidoc',
    '.tex': 'latex',
    '.ltx': 'latex',
    '.latex': 'latex',
    '.sty': 'latex',
    '.cls': 'latex',

    // Database - Alternate extensions
    '.mysql': 'sql',
    '.pgsql': 'sql',
    '.sqlite': 'sql',
    '.psql': 'sql',
    '.plsql': 'sql',
    '.cypher': 'cypher',
    '.cql': 'cypher', // Cypher Query Language
    '.sparql': 'sparql',
    '.rq': 'sparql',

    // Build & Package - Alternate extensions
    '.cmake': 'cmake',
    '.make': 'makefile',
    '.mak': 'makefile',
    '.mk': 'makefile',
    '.gmk': 'makefile',
    '.dockerfile': 'dockerfile',
    '.docker': 'dockerfile',
    '.containerfile': 'dockerfile',

    // .NET and Windows
    '.csproj': 'xml',
    '.vbproj': 'xml',
    '.fsproj': 'xml',
    '.vcxproj': 'xml',
    '.targets': 'xml',
    '.props': 'xml',
    '.vb': 'vb',
    '.bas': 'vb',
    '.frm': 'vb',
    '.razor': 'razor',
    '.bat': 'bat',
    '.cmd': 'bat',

    // Other Languages - Alternate extensions
    '.rmd': 'markdown', // R Markdown
    '.rnw': 'latex', // R Sweave
    '.fs': 'fsharp',
    '.fsx': 'fsharp',
    '.fsi': 'fsharp',
    '.ex': 'elixir',
    '.exs': 'elixir',
    '.eex': 'elixir', // Embedded Elixir
    '.leex': 'elixir',
    '.erl': 'erlang',
    '.hrl': 'erlang',
    '.clj': 'clojure',
    '.cljs': 'clojure',
    '.cljc': 'clojure',
    '.edn': 'clojure',
    '.hs': 'haskell',
    '.lhs': 'haskell',
    '.cabal': 'haskell',
    '.tf': 'hcl', // Terraform
    '.tfvars': 'hcl',
    '.hcl': 'hcl',
    '.nomad': 'hcl',
    '.v': 'verilog',
    '.sv': 'systemverilog',
    '.svh': 'systemverilog',
    '.ml': 'ocaml',
    '.mli': 'ocaml',
    '.wat': 'wasm', // WebAssembly text
    '.wast': 'wasm',
    '.glsl': 'glsl',
    '.vert': 'glsl',
    '.frag': 'glsl',
    '.geom': 'glsl',
    '.comp': 'glsl',
    '.tesc': 'glsl',
    '.tese': 'glsl',
    '.hlsl': 'hlsl',
    '.fx': 'hlsl',
    '.fxh': 'hlsl',

    // Cloud & Infrastructure
    '.bicep': 'bicep',
    '.azcli': 'azcli',
    '.k8s': 'yaml', // Kubernetes manifests
    '.kube': 'yaml',

    // Dart specific (since you love Dart!)
    '.dart.js': 'javascript', // Compiled Dart to JS
    '.g.dart': 'dart', // Generated Dart files
    '.freezed.dart': 'dart',
    '.chopper.dart': 'dart',

    // Additional scripting (since you love scripting!)
    '.awk': 'awk',
    '.sed': 'sed',
    '.expect': 'expect',
    '.applescript': 'applescript',
    '.scpt': 'applescript',
    '.osascript': 'applescript',
    '.jq': 'jq', // jq query language
    '.nu': 'nu', // Nushell
    '.just': 'just', // Justfile
    '.justfile': 'just',
  };

  /// Special case for files without extensions but with specific names
  static const Map<String, String> _filenameToLanguage = {
    'dockerfile': 'dockerfile',
    'Dockerfile': 'dockerfile',
    'makefile': 'makefile',
    'Makefile': 'makefile',
    'gnumakefile': 'makefile',
    'GNUmakefile': 'makefile',
    'cmakelists.txt': 'cmake',
    'CMakeLists.txt': 'cmake',
    '.gitignore': 'gitignore',
    '.gitattributes': 'gitattributes',
    '.editorconfig': 'ini',
    'package.json': 'json',
    'package-lock.json': 'json',
    'tsconfig.json': 'json',
    'jsconfig.json': 'json',
    '.eslintrc': 'json',
    '.eslintrc.json': 'json',
    '.prettierrc': 'json',
    '.prettierrc.json': 'json',
    'pubspec.yaml': 'yaml',
    'pubspec.yml': 'yaml',
    'app.yaml': 'yaml',
    'app.yml': 'yaml',
    'docker-compose.yml': 'yaml',
    'docker-compose.yaml': 'yaml',
    '.travis.yml': 'yaml',
    '.github/workflows/main.yml': 'yaml',
    'requirements.txt': 'plaintext',
    'Pipfile': 'toml',
    'Cargo.toml': 'toml',
    'go.mod': 'go',
    'go.sum': 'go',
  };

  /// Get language identifier for a file based on its extension or name
  static String getLanguageForFile(String filePath) {
    final fileName = path.basename(filePath).toLowerCase();
    final extension = path.extension(filePath).toLowerCase();

    // First check if we have a specific mapping for this exact filename
    if (_filenameToLanguage.containsKey(fileName)) {
      return _filenameToLanguage[fileName]!;
    }

    // Then check extension mapping
    if (_extensionToLanguage.containsKey(extension)) {
      return _extensionToLanguage[extension]!;
    }

    // Some special cases for shebang files (when no extension)
    if (extension.isEmpty) {
      try {
        final file = File(filePath);
        if (file.existsSync()) {
          final firstLine = file.readAsLinesSync().firstOrNull ?? '';
          if (firstLine.startsWith('#!')) {
            if (firstLine.contains('python')) return 'python';
            if (firstLine.contains('node')) return 'javascript';
            if (firstLine.contains('bash') || firstLine.contains('/sh')) {
              return 'shell';
            }
            if (firstLine.contains('ruby')) return 'ruby';
            if (firstLine.contains('perl')) return 'perl';
            if (firstLine.contains('php')) return 'php';
            if (firstLine.contains('lua')) return 'lua';
          }
        }
      } catch (_) {
        // Ignore file read errors
      }
      return 'plaintext'; // No extension and no shebang
    }

    // Default: return extension without the dot (e.g., .java -> java, .cpp -> cpp)
    return extension.substring(1);
  }

  /// Get language identifier for a file extension
  static String getLanguageForExtension(String extension) {
    // Ensure extension starts with a dot
    final normalizedExt = extension.startsWith('.') ? extension : '.$extension';
    final extLower = normalizedExt.toLowerCase();

    // Return mapped language or extension without dot as fallback
    return _extensionToLanguage[extLower] ?? extLower.substring(1);
  }

  /// Check if a language is supported for syntax highlighting
  /// This includes both explicitly mapped languages and any valid extension
  static bool isLanguageSupported(String language) {
    final languageLower = language.toLowerCase();

    // Check if it's in our explicit mapping
    if (_extensionToLanguage.values.contains(languageLower)) {
      return true;
    }

    // Check if it's in filename mappings
    if (_filenameToLanguage.values.contains(languageLower)) {
      return true;
    }

    // Accept any non-empty language identifier (since we fallback to extensions)
    return languageLower.isNotEmpty && languageLower != 'plaintext';
  }

  /// Get all supported languages (including common extensions)
  static Set<String> getSupportedLanguages() {
    final languages = <String>{}
      // Add explicitly mapped languages
      ..addAll(_extensionToLanguage.values)
      ..addAll(_filenameToLanguage.values);

    // Add common programming language extensions that would be auto-detected
    final commonExtensions = {
      'java',
      'cpp',
      'dart',
      'swift',
      'go',
      'rust',
      'kotlin',
      'scala',
      'python',
      'ruby',
      'php',
      'perl',
      'lua',
      'javascript',
      'typescript',
      'html',
      'css',
      'xml',
      'json',
      'yaml',
      'sql',
      'markdown',
      'c',
    };
    languages.addAll(commonExtensions);

    return languages;
  }

  /// Get all supported file extensions (from the explicit mapping)
  static Set<String> getSupportedExtensions() {
    return _extensionToLanguage.keys.toSet();
  }

  /// Get the appropriate language display name (for UI)
  static String getLanguageDisplayName(String language) {
    final displayNames = {
      'c': 'C',
      'cpp': 'C++',
      'csharp': 'C#',
      'css': 'CSS',
      'dart': 'Dart',
      'dockerfile': 'Dockerfile',
      'fsharp': 'F#',
      'go': 'Go',
      'html': 'HTML',
      'java': 'Java',
      'javascript': 'JavaScript',
      'json': 'JSON',
      'kotlin': 'Kotlin',
      'markdown': 'Markdown',
      'objective-c': 'Objective-C',
      'php': 'PHP',
      'plaintext': 'Plain Text',
      'powershell': 'PowerShell',
      'python': 'Python',
      'ruby': 'Ruby',
      'rust': 'Rust',
      'scss': 'SCSS',
      'shell': 'Shell',
      'sql': 'SQL',
      'swift': 'Swift',
      'typescript': 'TypeScript',
      'vb': 'Visual Basic',
      'xml': 'XML',
      'yaml': 'YAML',
    };

    final languageLower = language.toLowerCase();
    return displayNames[languageLower] ??
        language.substring(0, 1).toUpperCase() +
            (language.length > 1 ? language.substring(1).toLowerCase() : '');
  }
}
