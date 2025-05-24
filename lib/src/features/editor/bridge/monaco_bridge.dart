// ignore_for_file: use_setters_to_change_properties
import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../domain/editor_settings.dart';

/// Enhanced Bridge between Flutter and Monaco Editor WebView
/// Supports comprehensive editor configuration and advanced features
class MonacoBridge extends ChangeNotifier {
  WebViewController? _webViewController;

  String _content = '';
  String _language = 'plaintext';
  EditorSettings _settings = const EditorSettings();
  bool _isReady = false;

  // State tracking
  Map<String, dynamic>? _lastState;
  String? _lastTheme;

  // Available themes
  static const List<String> availableThemes = [
    'vs',
    'vs-dark',
    'hc-black',
    'one-dark-pro',
    'one-dark-pro-transparent',
  ];

  // Available languages from your languages.js file
  static const List<Map<String, String>> availableLanguages = [
    {'value': 'plaintext', 'text': 'Plain Text'},
    {'value': 'abap', 'text': 'ABAP'},
    {'value': 'apex', 'text': 'Apex'},
    {'value': 'azcli', 'text': 'Azure CLI'},
    {'value': 'bat', 'text': 'Batch'},
    {'value': 'bicep', 'text': 'Bicep'},
    {'value': 'cameligo', 'text': 'Cameligo'},
    {'value': 'clojure', 'text': 'Clojure'},
    {'value': 'coffeescript', 'text': 'CoffeeScript'},
    {'value': 'c', 'text': 'C'},
    {'value': 'cpp', 'text': 'C++'},
    {'value': 'csharp', 'text': 'C#'},
    {'value': 'csp', 'text': 'CSP'},
    {'value': 'css', 'text': 'CSS'},
    {'value': 'cypher', 'text': 'Cypher'},
    {'value': 'dart', 'text': 'Dart'},
    {'value': 'dockerfile', 'text': 'Dockerfile'},
    {'value': 'ecl', 'text': 'ECL'},
    {'value': 'elixir', 'text': 'Elixir'},
    {'value': 'flow9', 'text': 'Flow9'},
    {'value': 'fsharp', 'text': 'F#'},
    {'value': 'freemarker2', 'text': 'Freemarker2'},
    {'value': 'go', 'text': 'Go'},
    {'value': 'graphql', 'text': 'GraphQL'},
    {'value': 'handlebars', 'text': 'Handlebars'},
    {'value': 'hcl', 'text': 'HCL'},
    {'value': 'html', 'text': 'HTML'},
    {'value': 'ini', 'text': 'INI'},
    {'value': 'java', 'text': 'Java'},
    {'value': 'javascript', 'text': 'JavaScript'},
    {'value': 'julia', 'text': 'Julia'},
    {'value': 'kotlin', 'text': 'Kotlin'},
    {'value': 'less', 'text': 'Less'},
    {'value': 'lexon', 'text': 'Lexon'},
    {'value': 'lua', 'text': 'Lua'},
    {'value': 'liquid', 'text': 'Liquid'},
    {'value': 'm3', 'text': 'M3'},
    {'value': 'markdown', 'text': 'Markdown'},
    {'value': 'mdx', 'text': 'MDX'},
    {'value': 'mips', 'text': 'MIPS'},
    {'value': 'msdax', 'text': 'MSDAX'},
    {'value': 'mysql', 'text': 'MySQL'},
    {'value': 'objective-c', 'text': 'Objective-C'},
    {'value': 'pascal', 'text': 'Pascal'},
    {'value': 'pascaligo', 'text': 'Pascaligo'},
    {'value': 'perl', 'text': 'Perl'},
    {'value': 'pgsql', 'text': 'PostgreSQL'},
    {'value': 'php', 'text': 'PHP'},
    {'value': 'pla', 'text': 'PLA'},
    {'value': 'postiats', 'text': 'Postiats'},
    {'value': 'powerquery', 'text': 'Power Query'},
    {'value': 'powershell', 'text': 'PowerShell'},
    {'value': 'proto', 'text': 'Protocol Buffers'},
    {'value': 'pug', 'text': 'Pug'},
    {'value': 'python', 'text': 'Python'},
    {'value': 'qsharp', 'text': 'Q#'},
    {'value': 'r', 'text': 'R'},
    {'value': 'razor', 'text': 'Razor'},
    {'value': 'redis', 'text': 'Redis'},
    {'value': 'redshift', 'text': 'Redshift'},
    {'value': 'restructuredtext', 'text': 'reStructuredText'},
    {'value': 'ruby', 'text': 'Ruby'},
    {'value': 'rust', 'text': 'Rust'},
    {'value': 'sb', 'text': 'Small Basic'},
    {'value': 'scala', 'text': 'Scala'},
    {'value': 'scheme', 'text': 'Scheme'},
    {'value': 'scss', 'text': 'SCSS'},
    {'value': 'shell', 'text': 'Shell Script'},
    {'value': 'sol', 'text': 'Solidity'},
    {'value': 'aes', 'text': 'AES'},
    {'value': 'sparql', 'text': 'SPARQL'},
    {'value': 'sql', 'text': 'SQL'},
    {'value': 'st', 'text': 'Structured Text'},
    {'value': 'swift', 'text': 'Swift'},
    {'value': 'systemverilog', 'text': 'SystemVerilog'},
    {'value': 'verilog', 'text': 'Verilog'},
    {'value': 'tcl', 'text': 'Tcl'},
    {'value': 'twig', 'text': 'Twig'},
    {'value': 'typescript', 'text': 'TypeScript'},
    {'value': 'typespec', 'text': 'TypeSpec'},
    {'value': 'vb', 'text': 'Visual Basic'},
    {'value': 'wgsl', 'text': 'WGSL'},
    {'value': 'xml', 'text': 'XML'},
    {'value': 'yaml', 'text': 'YAML'},
    {'value': 'json', 'text': 'JSON'},
  ];

  // Getters
  String get content => _content;

  String get language => _language;

  EditorSettings get settings => _settings;

  bool get isReady => _isReady;

  // Theme and language getters
  String get theme => _settings.theme;

  double get fontSize => _settings.fontSize;

  bool get wordWrap => _settings.wordWrap != WordWrap.off;

  bool get showLineNumbers => _settings.showLineNumbers;

  bool get readOnly => _settings.readOnly;

  void attachWebView(WebViewController controller) {
    _webViewController = controller;
  }

  void detachWebView() {
    _webViewController = null;
    _isReady = false;
  }

  void markReady() {
    _isReady = true;
    if (_webViewController != null) {
      _pushContentToEditor();
      _pushSettingsToEditor();
    }
    notifyListeners();
  }

  /// Updates the editor content
  Future<void> setContent(String content, {bool preserveState = false}) async {
    if (_content == content) return;

    if (preserveState && _webViewController != null && _isReady) {
      await _saveEditorState();
    }

    _content = content;

    if (_webViewController != null && _isReady) {
      await _pushContentToEditor();

      if (preserveState && _lastState != null) {
        await _restoreEditorState();
      }
    }

    notifyListeners();
  }

  /// Gets the current editor content
  Future<String> getContent() async {
    if (_webViewController != null && _isReady) {
      try {
        final result = await _webViewController!.runJavaScriptReturningResult(
          'window.getEditorContent() || ""',
        );
        final content = result is String ? result : result.toString();
        // Remove quotes if present
        _content = content.replaceAll(RegExp(r'^"|"$'), '');
      } catch (e) {
        debugPrint('Error getting content: $e');
      }
    }
    return _content;
  }

  /// Sets the editor language
  Future<void> setLanguage(String language) async {
    if (_language == language) return;

    _language = language;

    if (_webViewController != null && _isReady) {
      await _webViewController!.runJavaScript(
        'window.setEditorLanguage("$language")',
      );
    }

    notifyListeners();
  }

  /// Updates editor settings - this is the main method for configuration
  Future<void> updateSettings(EditorSettings newSettings) async {
    final oldSettings = _settings;
    _settings = newSettings;

    if (_webViewController != null && _isReady) {
      await _pushSettingsToEditor();

      // If theme changed, notify specifically
      if (oldSettings.theme != newSettings.theme) {
        await _setTheme(newSettings.theme);
      }
    }

    notifyListeners();
  }

  /// Apply language-specific settings
  Future<void> applyLanguageSettings(String language) async {
    final languageSettings = _settings.getLanguageSettings(language);
    if (languageSettings != _settings) {
      await _pushLanguageSpecificSettings(languageSettings, language);
    }
  }

  /// Sets the editor theme
  Future<void> _setTheme(String theme) async {
    if (_lastTheme == theme) return;

    _lastTheme = theme;

    if (_webViewController != null && _isReady) {
      await _webViewController!.runJavaScript(
        'window.setEditorTheme("$theme")',
      );
    }
  }

  /// Formats the document
  Future<void> format() async {
    if (_webViewController != null && _isReady) {
      await _webViewController!.runJavaScript(
        'window.editor?.getAction("editor.action.formatDocument")?.run()',
      );
    }
  }

  /// Finds text in the editor
  Future<void> find() async {
    if (_webViewController != null && _isReady) {
      await _webViewController!.runJavaScript(
        'window.editor?.getAction("actions.find")?.run()',
      );
    }
  }

  /// Replace text in the editor
  Future<void> findAndReplace() async {
    if (_webViewController != null && _isReady) {
      await _webViewController!.runJavaScript(
        'window.editor?.getAction("editor.action.startFindReplaceAction")?.run()',
      );
    }
  }

  /// Goes to a specific line
  Future<void> goToLine([int? line]) async {
    if (_webViewController != null && _isReady) {
      if (line != null) {
        await _webViewController!.runJavaScript(
          'if (window.editor) { window.editor.revealLineInCenter($line); window.editor.setPosition({ lineNumber: $line, column: 1 }); }',
        );
      } else {
        await _webViewController!.runJavaScript(
          'window.editor?.getAction("editor.action.gotoLine")?.run()',
        );
      }
    }
  }

  /// Toggles line comments
  Future<void> toggleLineComment() async {
    if (_webViewController != null && _isReady) {
      await _webViewController!.runJavaScript(
        'window.editor?.getAction("editor.action.commentLine")?.run()',
      );
    }
  }

  /// Toggles block comments
  Future<void> toggleBlockComment() async {
    if (_webViewController != null && _isReady) {
      await _webViewController!.runJavaScript(
        'window.editor?.getAction("editor.action.blockComment")?.run()',
      );
    }
  }

  /// Triggers auto-completion
  Future<void> triggerSuggest() async {
    if (_webViewController != null && _isReady) {
      await _webViewController!.runJavaScript(
        'window.editor?.getAction("editor.action.triggerSuggest")?.run()',
      );
    }
  }

  /// Shows the command palette
  Future<void> showCommandPalette() async {
    if (_webViewController != null && _isReady) {
      await _webViewController!.runJavaScript(
        'window.editor?.getAction("editor.action.quickCommand")?.run()',
      );
    }
  }

  /// Scrolls to top
  Future<void> scrollToTop() async {
    if (_webViewController != null && _isReady) {
      await _webViewController!.runJavaScript(
        'window.editor?.setScrollPosition({ scrollTop: 0, scrollLeft: 0 })',
      );
    }
  }

  /// Scrolls to bottom
  Future<void> scrollToBottom() async {
    if (_webViewController != null && _isReady) {
      await _webViewController!.runJavaScript(
        '''
        if (window.editor) {
          const lineCount = window.editor.getModel()?.getLineCount() || 1;
          window.editor.revealLine(lineCount);
        }
        ''',
      );
    }
  }

  /// Fold all code blocks
  Future<void> foldAll() async {
    if (_webViewController != null && _isReady) {
      await _webViewController!.runJavaScript(
        'window.editor?.getAction("editor.foldAll")?.run()',
      );
    }
  }

  /// Unfold all code blocks
  Future<void> unfoldAll() async {
    if (_webViewController != null && _isReady) {
      await _webViewController!.runJavaScript(
        'window.editor?.getAction("editor.unfoldAll")?.run()',
      );
    }
  }

  /// Select all content
  Future<void> selectAll() async {
    if (_webViewController != null && _isReady) {
      await _webViewController!.runJavaScript(
        'window.editor?.getAction("editor.action.selectAll")?.run()',
      );
    }
  }

  /// Execute a custom Monaco action by ID
  Future<void> executeAction(String actionId) async {
    if (_webViewController != null && _isReady) {
      await _webViewController!.runJavaScript(
        'window.editor?.getAction("$actionId")?.run()',
      );
    }
  }

  /// Execute a custom keybinding
  Future<void> executeKeybinding(String keybinding) async {
    if (_webViewController != null && _isReady) {
      await _webViewController!.runJavaScript(
        'window.executeKeybinding("$keybinding")',
      );
    }
  }

  /// Get editor statistics
  Future<Map<String, dynamic>> getEditorStats() async {
    if (_webViewController != null && _isReady) {
      try {
        final result =
            await _webViewController!.runJavaScriptReturningResult(r'''
          JSON.stringify({
            lineCount: window.editor?.getModel()?.getLineCount() || 0,
            characterCount: window.editor?.getValue()?.length || 0,
            wordCount: (window.editor?.getValue()?.match(/\b\w+\b/g) || []).length,
            selectedText: window.editor?.getSelection()?.isEmpty() === false,
            language: window.editor?.getModel()?.getLanguageId() || 'unknown',
            cursorPosition: window.editor?.getPosition(),
            viewState: {
              scrollTop: window.editor?.getScrollTop() || 0,
              scrollLeft: window.editor?.getScrollLeft() || 0
            }
          })
        ''');

        if (result is String) {
          return json.decode(result) as Map<String, dynamic>;
        }
      } catch (e) {
        debugPrint('Error getting editor stats: $e');
      }
    }
    return {};
  }

  // Private methods
  Future<void> _pushContentToEditor() async {
    if (_webViewController == null || !_isReady) return;

    final String escapedContent = json.encode(_content);
    await _webViewController!.runJavaScript(
      'window.setEditorContent($escapedContent)',
    );
  }

  Future<void> _pushSettingsToEditor() async {
    if (_webViewController == null || !_isReady) return;

    final options = _settings.toMonacoOptions();
    final String optionsJson = json.encode(options);

    await _webViewController!.runJavaScript(
      'window.setEditorOptions($optionsJson)',
    );
  }

  Future<void> _pushLanguageSpecificSettings(
      EditorSettings languageSettings, String language) async {
    if (_webViewController == null || !_isReady) return;

    final options = languageSettings.toMonacoOptions();
    final String optionsJson = json.encode(options);

    await _webViewController!.runJavaScript(
      'window.setLanguageSpecificOptions("$language", $optionsJson)',
    );
  }

  Future<void> _saveEditorState() async {
    try {
      final stateJson = await _webViewController!.runJavaScriptReturningResult(
        '''
JSON.stringify({
          position: window.editor?.getPosition(),
          selection: window.editor?.getSelection(),
          scrollTop: window.editor?.getScrollTop(),
          scrollLeft: window.editor?.getScrollLeft(),
          viewState: window.editor?.saveViewState()
        })''',
      ) as String;
      _lastState = json.decode(stateJson) as Map<String, dynamic>?;
    } catch (e) {
      debugPrint('Error saving editor state: $e');
      _lastState = null;
    }
  }

  Future<void> _restoreEditorState() async {
    if (_lastState == null || _webViewController == null || !_isReady) return;

    try {
      await _webViewController!.runJavaScript('''
        if (window.editor) {
          const state = ${json.encode(_lastState)};
          if (state.viewState) {
            window.editor.restoreViewState(state.viewState);
          } else {
            if (state.position) {
              window.editor.setPosition(state.position);
            }
            if (state.selection) {
              window.editor.setSelection(state.selection);
            }
            if (state.scrollTop !== undefined) {
              window.editor.setScrollPosition({
                scrollTop: state.scrollTop,
                scrollLeft: state.scrollLeft || 0
              });
            }
          }
        }
      ''');
    } catch (e) {
      debugPrint('Error restoring editor state: $e');
    }
  }

  /// Register custom themes (if needed in the future)
  Future<void> registerCustomTheme(
      String themeName, Map<String, dynamic> themeData) async {
    if (_webViewController != null && _isReady) {
      final themeJson = json.encode(themeData);
      await _webViewController!.runJavaScript(
        'monaco.editor.defineTheme("$themeName", $themeJson)',
      );
    }
  }

  /// Register custom language (if needed in the future)
  Future<void> registerCustomLanguage(
      String languageId, Map<String, dynamic> languageDefinition) async {
    if (_webViewController != null && _isReady) {
      final langJson = json.encode(languageDefinition);
      await _webViewController!.runJavaScript(
        'monaco.languages.register($langJson)',
      );
    }
  }

  /// Set up custom keybindings
  Future<void> setupKeybindings(Map<String, String> keybindings) async {
    if (_webViewController != null && _isReady && keybindings.isNotEmpty) {
      final keybindingsJson = json.encode(keybindings);
      await _webViewController!.runJavaScript(
        'window.setupCustomKeybindings($keybindingsJson)',
      );
    }
  }

  /// Apply keybinding preset
  Future<void> applyKeybindingPreset(KeybindingPresetEnum preset) async {
    if (_webViewController != null && _isReady) {
      await _webViewController!.runJavaScript(
        'window.applyKeybindingPreset("${preset.name}")',
      );
    }
  }

  @override
  void dispose() {
    _webViewController = null;
    super.dispose();
  }
}
