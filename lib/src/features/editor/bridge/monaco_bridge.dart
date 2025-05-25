// ignore_for_file: use_setters_to_change_properties
import 'dart:async';
import 'dart:convert';

import 'package:dart_helper_utils/dart_helper_utils.dart';
import 'package:flutter/foundation.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../domain/editor_settings.dart';

/// Enhanced Bridge between Flutter and Monaco Editor WebView
/// Supports comprehensive editor configuration and advanced features
class MonacoBridge extends ChangeNotifier {
  WebViewController? _webViewController;

  String _content = '';
  String _language = 'markdown';
  EditorSettings _settings = const EditorSettings();
  bool _isReady = false;
  bool _forceSetLanguageNext = false;

  // ValueNotifier for live editor stats as per FOLLOWUP.md
  final ValueNotifier<Map<String, int>> liveStats =
      ValueNotifier(<String, int>{});

  // State tracking
  Map<String, dynamic>? _lastState;
  String? _lastTheme;

  static const String _statsChannelName = 'flutterChannel';

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

  void _handleJavaScriptMessage(JavaScriptMessage message) {
    debugPrint(
        '[MonacoBridge._handleJavaScriptMessage] Received raw message: ${message.message}');
    final data = ConvertObject.tryToMap(message.message) ?? {};
    if (data['event'] == 'stats') {
      // The JS sends stats directly, not nested in 'payload' as per one version of the guide.
      // Adapting to the simpler structure: data directly contains stat fields.
      liveStats.value = {
        'lines': ConvertObject.toInt(data['lineCount'], defaultValue: 0),
        'chars': ConvertObject.toInt(data['charCount'], defaultValue: 0),
        'selLn': ConvertObject.toInt(data['selLines'], defaultValue: 0),
        'selCh': ConvertObject.toInt(data['selChars'], defaultValue: 0),
        'carets': ConvertObject.toInt(data['caretCount'], defaultValue: 1),
      };
    } else {
      // Handle other potential messages if any
      debugPrint(
          '[MonacoBridge] Received unhandled JS message: ${message.message}');
    }
  }

  /// Public method for external components to forward JavaScript messages to the bridge
  void handleJavaScriptMessage(JavaScriptMessage message) {
    _handleJavaScriptMessage(message);
  }

  void attachWebView(WebViewController controller) {
    _webViewController = controller;
    // The channel 'flutterChannel' is added by MonacoEditorEmbedded to this controller.
    // MonacoBridge just uses this controller.
    // No need to add it again here. The bridge needs to know about it for _injectLiveStatsJavaScript.
  }

  void detachWebView() {
    // Try to remove the channel from the controller this bridge was using.
    // This assumes _statsChannelName is the correct name used by MonacoEditorEmbedded.
    _webViewController
        ?.removeJavaScriptChannel(_statsChannelName)
        .catchError((e) {
      debugPrint(
          '[MonacoBridge] Error removing JS channel $_statsChannelName: $e. May already be gone.');
    });
    _webViewController = null;
    _isReady = false;
  }

  void markReady() {
    debugPrint(
        '[MonacoBridge] markReady CALLED. Current _language: $_language. _isReady was: $_isReady');
    _isReady = true;
    if (_webViewController != null) {
      _pushContentToEditor();
      _pushSettingsToEditor();
      debugPrint('[MonacoBridge] markReady: Forcing next setLanguage call.');
      _forceSetLanguageNext = true;
      setLanguage(_language);
      _injectLiveStatsJavaScript();
    }
    notifyListeners();
    debugPrint('[MonacoBridge] markReady FINISHED.');
  }

  Future<void> _injectLiveStatsJavaScript() async {
    if (_webViewController == null || !_isReady) {
      debugPrint(
          '[MonacoBridge] Skipping JS stats injection: WebView not ready or null.');
      return;
    }
    debugPrint('[MonacoBridge] Attempting to inject live stats JavaScript.');
    const script = '''
      console.log('[Stats Script] Injected and running.');
      if (window.__liveStatsHooked) {
        console.log('[Stats Script] Listeners already hooked. Skipping.');
      } else {
        window.__liveStatsHooked = true;
        console.log('[Stats Script] First time hooking listeners.');
        if (window.editor) {
            console.log('[Stats Script] window.editor found. Attaching listeners.');
            const sendStats = () => {
                console.log('[Stats Script] sendStats called.');
                const model = window.editor.getModel();
                const selection = window.editor.getSelection();
                const selections = window.editor.getSelections() || []; 
                if (!model) { console.log('[Stats Script] sendStats: model is null!'); return; }
                if (!selection) { console.log('[Stats Script] sendStats: selection is null!'); return; }
                
                console.log('[Stats Script] sendStats: Model and selection OK. Selection empty: ' + selection.isEmpty());

                const stats = {
                    event: 'stats', 
                    lineCount: model.getLineCount(),
                    charCount: model.getValueLength(),
                    selLines: selection.isEmpty() ? 0 : selection.endLineNumber - selection.startLineNumber + 1,
                    selChars: selection.isEmpty() ? 0 : model.getValueInRange(selection).length,
                    caretCount: selections.length 
                };
                
                if (window.flutterChannel && window.flutterChannel.postMessage) {
                     console.log('[Stats Script] Attempting to post stats: ' + JSON.stringify(stats));
                     window.flutterChannel.postMessage(JSON.stringify(stats));
                     console.log('[Stats Script] Stats posted.');
                } else {
                    console.log('[Stats Script] ERROR: window.flutterChannel or postMessage not available.');
                }
            };

            window.editor.onDidChangeModelContent(() => { 
                console.log('[Stats Script] onDidChangeModelContent triggered.'); 
                sendStats(); 
            });
            window.editor.onDidChangeCursorSelection(() => { 
                console.log('[Stats Script] onDidChangeCursorSelection triggered.'); 
                sendStats(); 
            });
            
            console.log('[Stats Script] Event listeners attached. Performing initial sendStats.');
            sendStats(); // Initial push
        } else {
            console.log('[Stats Script] ERROR: window.editor not found when trying to attach listeners.');
        }
      }
    ''';
    try {
      await _webViewController!.runJavaScript(script);
      debugPrint('[MonacoBridge] Successfully injected live stats JavaScript.');
    } catch (e) {
      debugPrint('[MonacoBridge] ERROR injecting live stats JavaScript: $e');
    }
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
    debugPrint(
        '[MonacoBridge] setLanguage ATTEMPTING for: "$language". Current _language: "$_language". Is ready: $_isReady. Force flag: $_forceSetLanguageNext');

    if (!_isReady) {
      debugPrint(
          '[MonacoBridge] setLanguage: Editor not ready, just updating _language field to "$language".');
      _language = language;
      notifyListeners();
      return;
    }

    if (_language == language && !_forceSetLanguageNext) {
      debugPrint(
          '[MonacoBridge] setLanguage: Language "$language" is already current and no force flag. Skipping JS call.');
      return;
    }

    _language = language;
    _forceSetLanguageNext = false;

    if (_webViewController != null) {
      debugPrint(
          '[MonacoBridge] setLanguage: Calling JS window.setEditorLanguage("$language")');
      try {
        await _webViewController!.runJavaScript(
          'window.setEditorLanguage("$language")',
        );
        debugPrint(
            '[MonacoBridge] setLanguage: JS call for "$language" completed.');
      } catch (e) {
        debugPrint(
            '[MonacoBridge] setLanguage: ERROR calling JS for "$language": $e');
      }
    } else {
      debugPrint(
          '[MonacoBridge] setLanguage: WebViewController is null, cannot call JS for "$language".');
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
            await _webViewController!.runJavaScriptReturningResult(r"""
          JSON.stringify({
            lineCount: window.editor?.getModel()?.getLineCount() || 0,
            characterCount: window.editor?.getValue()?.length || 0,
            wordCount: (window.editor?.getValue()?.match(/\\b\\w+\\b/g) || []).length,
            selectedText: window.editor?.getSelection()?.isEmpty() === false,
            language: window.editor?.getModel()?.getLanguageId() || 'unknown',
            cursorPosition: window.editor?.getPosition(),
            viewState: {
              scrollTop: window.editor?.getScrollTop() || 0,
              scrollLeft: window.editor?.getScrollLeft() || 0
            },
            // New stats
            selectedLineCount: window.editor?.getSelection()?.isEmpty() 
              ? 0 
              : (window.editor?.getSelection()?.endLineNumber || 0) - (window.editor?.getSelection()?.startLineNumber || 0) + 1,
            selectedCharCount: window.editor?.getModel()?.getValueInRange(window.editor?.getSelection())?.length || 0
          })
        """);

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
    debugPrint(
        '[MonacoBridge._pushSettingsToEditor] Sending options: $optionsJson');

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

  Future<void> setMarkers(List<Map<String, dynamic>> markers) async {
    // Implementation of setMarkers method
  }

  @override
  void dispose() {
    liveStats.dispose();
    _webViewController = null;
    super.dispose();
  }
}
