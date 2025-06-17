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

  /// File size limits
  static const int maxFileSize = 10 * 1024 * 1024; // 10 MB
  static const int warningFileSize = 1 * 1024 * 1024; // 1 MB

  /// Default settings
  static const String defaultTheme = 'vs-dark';
  static const String defaultLanguage = 'markdown';
  static const String defaultKeybindingPreset = 'vscode';

  static String indexHtmlContent(String vsPath) =>
      '''
<!DOCTYPE html>
<html>
  <head>
    <meta charset="utf-8" />
    <meta http-equiv="X-UA-Compatible" content="IE=edge" />
    <!-- FIXED: Relaxed CSP to allow file:// scripts and unsafe-eval (required by Monaco) -->
    <meta
      http-equiv="Content-Security-Policy"
      content="default-src 'self' file: 'unsafe-inline' 'unsafe-eval'; script-src 'self' file: 'unsafe-inline' 'unsafe-eval'; style-src 'self' 'unsafe-inline'; font-src 'self' file:; worker-src 'self' blob:;"
    />
    <style>
      html, body, #editor-container {
        width: 100%; height: 100%; margin: 0; padding: 0; overflow: hidden;
      }
    </style>
  </head>
  <body>
    <div id="editor-container"></div>

    <script>
      var require = { paths: { vs: '$vsPath' } };
      console.log('[Monaco HTML] Require config set. VS_PATH is: ' + '$vsPath');
    </script>

    <script src="$vsPath/loader.js"
            onload="console.log('[Monaco HTML] loader.js successfully loaded.')"
            onerror="console.error('[Monaco HTML] FATAL: loader.js FAILED TO LOAD.')"
    ></script>

    <script>
      console.log('[Monaco HTML] Attempting to require editor.main...');
      try {
        // This is the standard Monaco loader pattern, now with an error callback.
        require(
          ['vs/editor/editor.main'],
          function () { // SUCCESS CALLBACK
            console.log('[Monaco] SUCCESS: editor.main.js has loaded. Initializing editor...');

            function postMessageToFlutter(message) {
              if (typeof message !== 'string') {
                message = JSON.stringify(message);
              }
              if (window.flutterChannel && window.flutterChannel.postMessage) {
                window.flutterChannel.postMessage(message);
              } else {
                console.error('[Monaco] Flutter communication channel is not available.');
              }
            }

            monaco.editor.onDidCreateEditor(function (editor) {
              window.editor = editor;
              window.setEditorContent = (content) => editor.setValue(content || '');
              window.setEditorLanguage = (language) => monaco.editor.setModelLanguage(editor.getModel(), language);
              window.setEditorTheme = (theme) => monaco.editor.setTheme(theme);
              window.setEditorOptions = (options) => editor.updateOptions(options);

              const sendStats = () => {
                if (!editor.getModel() || !editor.getSelection()) return;
                const model = editor.getModel(), selection = editor.getSelection(), selections = editor.getSelections() || [];
                postMessageToFlutter({
                  event: 'stats',
                  lineCount: model.getLineCount(),
                  charCount: model.getValueLength(),
                  selLines: selection.endLineNumber - selection.startLineNumber + 1,
                  selChars: model.getValueInRange(selection).length,
                  caretCount: selections.length,
                });
              };
              editor.onDidChangeModelContent(sendStats);
              editor.onDidChangeCursorSelection(sendStats);
              sendStats();

              postMessageToFlutter({ event: 'onEditorReady' });
              console.log('[Monaco] Editor is ready and has sent the onEditorReady event.');
            });

            monaco.editor.create(document.getElementById('editor-container'), {
              value: '// Context Collector is ready.',
              language: 'markdown',
              theme: 'vs-dark',
              automaticLayout: true,
              wordWrap: 'on',
              padding: { top: 10 },
              minimap: { enabled: false }
            });
          },
          function (error) { // ERROR CALLBACK
            console.error('[Monaco] FATAL: require() failed to load editor.main.js. Error:', error);
          }
        );
      } catch (e) {
        console.error('[Monaco] FATAL: A critical error occurred trying to call require(). Error:', e);
      }
    </script>
  </body>
</html>
  ''';
}
