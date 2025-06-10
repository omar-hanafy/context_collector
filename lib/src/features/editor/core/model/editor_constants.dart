/// Unified constants for the Monaco editor
class EditorConstants {
  // Prevent instantiation
  EditorConstants._();

  /// Theme display names
  static const Map<String, String> themeNames = {
    'vs': 'Light',
    'vs-dark': 'Dark',
    'hc-black': 'High Contrast Dark',
    'hc-light': 'High Contrast Light',
  };

  /// Available languages with display names
  static const Map<String, String> languages = {
    'plaintext': 'Plain Text',
    'abap': 'ABAP',
    'apex': 'Apex',
    'azcli': 'Azure CLI',
    'bat': 'Batch',
    'bicep': 'Bicep',
    'cameligo': 'Cameligo',
    'clojure': 'Clojure',
    'coffeescript': 'CoffeeScript',
    'c': 'C',
    'cpp': 'C++',
    'csharp': 'C#',
    'csp': 'CSP',
    'css': 'CSS',
    'cypher': 'Cypher',
    'dart': 'Dart',
    'dockerfile': 'Dockerfile',
    'ecl': 'ECL',
    'elixir': 'Elixir',
    'flow9': 'Flow9',
    'fsharp': 'F#',
    'freemarker2': 'Freemarker2',
    'go': 'Go',
    'graphql': 'GraphQL',
    'handlebars': 'Handlebars',
    'hcl': 'HCL',
    'html': 'HTML',
    'ini': 'INI',
    'java': 'Java',
    'javascript': 'JavaScript',
    'julia': 'Julia',
    'kotlin': 'Kotlin',
    'less': 'Less',
    'lexon': 'Lexon',
    'lua': 'Lua',
    'liquid': 'Liquid',
    'm3': 'M3',
    'markdown': 'Markdown',
    'mdx': 'MDX',
    'mips': 'MIPS',
    'msdax': 'MSDAX',
    'mysql': 'MySQL',
    'objective-c': 'Objective-C',
    'pascal': 'Pascal',
    'pascaligo': 'Pascaligo',
    'perl': 'Perl',
    'pgsql': 'PostgreSQL',
    'php': 'PHP',
    'pla': 'PLA',
    'postiats': 'Postiats',
    'powerquery': 'Power Query',
    'powershell': 'PowerShell',
    'proto': 'Protocol Buffers',
    'pug': 'Pug',
    'python': 'Python',
    'qsharp': 'Q#',
    'r': 'R',
    'razor': 'Razor',
    'redis': 'Redis',
    'redshift': 'Redshift',
    'restructuredtext': 'reStructuredText',
    'ruby': 'Ruby',
    'rust': 'Rust',
    'sb': 'Small Basic',
    'scala': 'Scala',
    'scheme': 'Scheme',
    'scss': 'SCSS',
    'shell': 'Shell Script',
    'sol': 'Solidity',
    'aes': 'AES',
    'sparql': 'SPARQL',
    'sql': 'SQL',
    'st': 'Structured Text',
    'swift': 'Swift',
    'systemverilog': 'SystemVerilog',
    'verilog': 'Verilog',
    'tcl': 'Tcl',
    'twig': 'Twig',
    'typescript': 'TypeScript',
    'typespec': 'TypeSpec',
    'vb': 'Visual Basic',
    'wgsl': 'WGSL',
    'xml': 'XML',
    'yaml': 'YAML',
    'json': 'JSON',
  };

  /// Common font families
  static const List<String> fontFamilies = [
    'Cascadia Code, Fira Code, Consolas, monospace',
    'Fira Code, Consolas, monospace',
    'SF Mono, Monaco, monospace',
    'JetBrains Mono, monospace',
    'Source Code Pro, monospace',
    'Consolas, monospace',
    'Monaco, monospace',
    'Menlo, monospace',
    'Courier New, monospace',
    'monospace',
  ];

  /// Font size range
  static const double minFontSize = 8;
  static const double maxFontSize = 48;
  static const double defaultFontSize = 14;

  /// Tab size range
  static const int minTabSize = 1;
  static const int maxTabSize = 8;
  static const int defaultTabSize = 2;

  /// Keybinding presets
  static const Map<String, String> keybindingPresets = {
    'vscode': 'VS Code',
    'intellij': 'IntelliJ',
    'vim': 'Vim',
    'emacs': 'Emacs',
    'custom': 'Custom',
  };

  /// Common ruler positions
  static const List<List<int>> commonRulers = [
    [],
    [80],
    [100],
    [120],
    [80, 120],
    [80, 100, 120],
  ];

  /// Monaco asset files
  static const String monacoVersion = '0.45.0';
  static const String monacoAssetPath = 'assets/monaco';
  static const String monacoIndexFile = 'index.html';

  /// File size limits
  static const int maxFileSize = 10 * 1024 * 1024; // 10 MB
  static const int warningFileSize = 1 * 1024 * 1024; // 1 MB

  /// Default settings
  static const String defaultTheme = 'vs-dark';
  static const String defaultLanguage = 'markdown';
  static const String defaultKeybindingPreset = 'vscode';
}
