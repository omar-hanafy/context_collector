// ignore_for_file: use_setters_to_change_properties

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:context_collector/src/features/editor/bridge/platform_webview_controller.dart';
import 'package:context_collector/src/features/editor/domain/editor_settings.dart';
import 'package:context_collector/src/features/editor/domain/monaco_scripts.dart';
import 'package:context_collector/src/features/editor/utils/monaco_settings_converter.dart';
import 'package:dart_helper_utils/dart_helper_utils.dart';
import 'package:flutter/foundation.dart';

/// Enhanced Cross-Platform Monaco Bridge
/// Works seamlessly with both webview_flutter and webview_windows
class MonacoBridgePlatform extends ChangeNotifier {
  PlatformWebViewController? _webViewController;

  String _content = '';
  String _language = 'markdown';
  EditorSettings _settings = const EditorSettings();
  bool _isReady = false;
  bool _forceSetLanguageNext = false;

  // ValueNotifier for live editor stats
  final ValueNotifier<Map<String, int>> liveStats =
      ValueNotifier(<String, int>{});

  // State tracking
  Map<String, dynamic>? _lastState;
  String? _lastTheme;

  static const String _statsChannelName = 'flutterChannel';

  // Getters
  String get content => _content;

  String get language => _language;

  EditorSettings get settings => _settings;

  bool get isReady => _isReady;

  String get theme => _settings.theme;

  double get fontSize => _settings.fontSize;

  bool get wordWrap => _settings.wordWrap != WordWrap.off;

  bool get showLineNumbers => _settings.showLineNumbers;

  bool get readOnly => _settings.readOnly;

  /// Handle JavaScript messages from the WebView
  /// Handle JavaScript messages from the WebView
  void _handleJavaScriptMessage(String message) {
    debugPrint(
        '[MonacoBridgePlatform._handleJavaScriptMessage] Received: $message');

    // Handle log messages
    if (message.startsWith('log:')) {
      debugPrint('[Monaco JS] ${message.substring(4)}');
      return;
    }

    try {
      final data = ConvertObject.tryToMap(message) ?? {};

      if (data['event'] == 'stats') {
        liveStats.value = {
          'lines': ConvertObject.toInt(data['lineCount'], defaultValue: 0),
          'chars': ConvertObject.toInt(data['charCount'], defaultValue: 0),
          'selLn': ConvertObject.toInt(data['selLines'], defaultValue: 0),
          'selCh': ConvertObject.toInt(data['selChars'], defaultValue: 0),
          'carets': ConvertObject.toInt(data['caretCount'], defaultValue: 1),
        };
      } else if (data['event'] == 'onEditorReady') {
        debugPrint('[MonacoBridgePlatform] Editor ready event received');
      } else if (data['event'] == 'error') {
        debugPrint('[MonacoBridgePlatform] Editor error: ${data['message']}');
      } else {
        debugPrint('[MonacoBridgePlatform] Unhandled message: $message');
      }
    } catch (e) {
      debugPrint('[MonacoBridgePlatform] Error parsing message: $e');
      // For Windows, sometimes messages come as raw strings
      if (Platform.isWindows && message.isNotEmpty) {
        _handleWindowsMessage(message);
      }
    }
  }

  /// Handle Windows-specific message formats (ADD THIS NEW METHOD)
  void _handleWindowsMessage(String message) {
    try {
      // Windows WebView might send messages in different formats
      if (message.contains('stats') || message.contains('lineCount')) {
        // Try to extract stats from the message
        final regex = RegExp(r'"event"\s*:\s*"stats"');
        if (regex.hasMatch(message)) {
          final data = ConvertObject.tryToMap(message) ?? {};
          if (data['event'] == 'stats') {
            liveStats.value = {
              'lines': ConvertObject.toInt(data['lineCount'], defaultValue: 0),
              'chars': ConvertObject.toInt(data['charCount'], defaultValue: 0),
              'selLn': ConvertObject.toInt(data['selLines'], defaultValue: 0),
              'selCh': ConvertObject.toInt(data['selChars'], defaultValue: 0),
              'carets':
                  ConvertObject.toInt(data['caretCount'], defaultValue: 1),
            };
          }
        }
      }
    } catch (e) {
      debugPrint('[MonacoBridgePlatform] Windows message handling error: $e');
    }
  }

  /// Public method for external components to forward JavaScript messages
  /// Supports both JavaScriptMessage objects (from webview_flutter) and Strings
  void handleJavaScriptMessage(dynamic message) {
    String messageContent;

    // Handle both JavaScriptMessage objects and Strings for compatibility
    if (message is String) {
      messageContent = message;
    } else if (message.runtimeType.toString().contains('JavaScriptMessage')) {
      // ignore: avoid_dynamic_calls
      messageContent = message.message as String;
    } else {
      messageContent = message.toString();
    }

    _handleJavaScriptMessage(messageContent);
  }

  /// Attach the platform-specific WebView controller
  void attachWebView(PlatformWebViewController controller) {
    _webViewController = controller;
    debugPrint('[MonacoBridgePlatform] WebView controller attached');
  }

  /// Detach the WebView controller
  void detachWebView() {
    _webViewController
        ?.removeJavaScriptChannel(_statsChannelName)
        .catchError((dynamic e) {
      debugPrint('[MonacoBridgePlatform] Error removing JS channel: $e');
      return null;
    });
    _webViewController = null;
    _isReady = false;
    debugPrint('[MonacoBridgePlatform] WebView controller detached');
  }

  /// Mark the editor as ready and initialize
  void markReady() {
    debugPrint('[MonacoBridgePlatform] markReady called. Language: $_language');
    _isReady = true;

    if (_webViewController != null) {
      // Add debugging to check Monaco initialization
      _webViewController!.runJavaScript(MonacoScripts.editorReadyCheck).catchError(
        (dynamic e) {
          debugPrint(
              '[MonacoBridgePlatform] Error checking Monaco readiness: $e');
          return null;
        },
      );

      _pushContentToEditor();
      _pushSettingsToEditor();
      _forceSetLanguageNext = true;
      setLanguage(_language);
      _injectLiveStatsJavaScript();
    }

    notifyListeners();
    debugPrint('[MonacoBridgePlatform] Editor marked as ready');
  }

  /// Inject JavaScript for live statistics monitoring
  Future<void> _injectLiveStatsJavaScript() async {
    if (_webViewController == null || !_isReady) {
      debugPrint('[MonacoBridgePlatform] Skipping stats injection: not ready');
      return;
    }

    const script = MonacoScripts.liveStatsMonitoring;

    try {
      await _webViewController!.runJavaScript(script);
      debugPrint('[MonacoBridgePlatform] Live stats JavaScript injected');
    } catch (e) {
      debugPrint('[MonacoBridgePlatform] Error injecting stats JS: $e');
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
        _content = content.replaceAll(RegExp(r'^"|"$'), '');
      } catch (e) {
        debugPrint('[MonacoBridgePlatform] Error getting content: $e');
      }
    }
    return _content;
  }

  /// Sets the editor language
  Future<void> setLanguage(String language) async {
    debugPrint(
        '[MonacoBridgePlatform] setLanguage: $language (ready: $_isReady)');

    if (!_isReady) {
      _language = language;
      notifyListeners();
      return;
    }

    if (_language == language && !_forceSetLanguageNext) {
      debugPrint('[MonacoBridgePlatform] Language already set to: $language');
      return;
    }

    _language = language;
    _forceSetLanguageNext = false;

    if (_webViewController != null) {
      try {
        // First, check if Monaco is properly initialized
        await _webViewController!.runJavaScript(
          MonacoScripts.languageCheckScript(language),
        );

        await _webViewController!.runJavaScript(
          'window.setEditorLanguage && window.setEditorLanguage("$language")',
        );
        debugPrint('[MonacoBridgePlatform] Language set to: $language');

        // Verify the language was set
        await _webViewController!.runJavaScript(MonacoScripts.verifyLanguageScript);
      } catch (e) {
        debugPrint('[MonacoBridgePlatform] Error setting language: $e');
      }
    }
    notifyListeners();
  }

  /// Updates editor settings - the main method for configuration
  Future<void> updateSettings(EditorSettings newSettings) async {
    debugPrint('[MonacoBridgePlatform] updateSettings called');
    final oldSettings = _settings;
    _settings = newSettings;

    if (_webViewController != null && _isReady) {
      await _pushSettingsToEditor();

      if (oldSettings.theme != newSettings.theme) {
        await _setTheme(newSettings.theme);
      }
    }

    notifyListeners();
  }

  /// Apply keybinding preset
  Future<void> applyKeybindingPreset(KeybindingPresetEnum preset) async {
    debugPrint('[MonacoBridgePlatform] applyKeybindingPreset: $preset');

    if (_webViewController != null && _isReady) {
      try {
        // Use the enum name directly like the old version
        await _webViewController!.runJavaScript(
          'window.applyKeybindingPreset && window.applyKeybindingPreset("${preset.monacoPreset}")',
        );
        debugPrint(
            '[MonacoBridgePlatform] Applied keybinding preset: ${preset.monacoPreset}');
      } catch (e) {
        debugPrint(
            '[MonacoBridgePlatform] Error applying keybinding preset: $e');
      }
    }
  }

  /// Set up custom keybindings
  Future<void> setupKeybindings(Map<String, String> keybindings) async {
    debugPrint(
        '[MonacoBridgePlatform] setupKeybindings: ${keybindings.length} bindings');

    if (_webViewController != null && _isReady && keybindings.isNotEmpty) {
      try {
        final keybindingsJson = json.encode(keybindings);
        await _webViewController!.runJavaScript(
          'window.setupCustomKeybindings && window.setupCustomKeybindings($keybindingsJson)',
        );
        debugPrint('[MonacoBridgePlatform] Custom keybindings applied');
      } catch (e) {
        debugPrint('[MonacoBridgePlatform] Error setting up keybindings: $e');
      }
    }
  }

  /// Apply language-specific settings
  Future<void> applyLanguageSettings(String language) async {
    final languageSettings = _settings.getLanguageSettings(language);
    if (languageSettings != _settings) {
      await _pushLanguageSpecificSettings(languageSettings, language);
    }
  }

  /// Set markers for error highlighting, etc.
  Future<void> setMarkers(List<Map<String, dynamic>> markers) async {
    if (_webViewController != null && _isReady) {
      try {
        final markersJson = json.encode(markers);
        await _webViewController!.runJavaScript(
          'window.setEditorMarkers && window.setEditorMarkers($markersJson)',
        );
        debugPrint('[MonacoBridgePlatform] Markers set: ${markers.length}');
      } catch (e) {
        debugPrint('[MonacoBridgePlatform] Error setting markers: $e');
      }
    }
  }

  /// Sets the editor theme
  Future<void> _setTheme(String theme) async {
    if (_lastTheme == theme) return;
    _lastTheme = theme;

    if (_webViewController != null && _isReady) {
      try {
        await _webViewController!.runJavaScript(
          'window.setEditorTheme("$theme")',
        );
        debugPrint('[MonacoBridgePlatform] Theme set to: $theme');
      } catch (e) {
        debugPrint('[MonacoBridgePlatform] Error setting theme: $e');
      }
    }
  }

  // ========================================
  // EDITOR ACTIONS
  // ========================================

  /// Helper method to execute Monaco editor actions
  Future<void> _executeEditorAction(String actionId) async {
    if (_webViewController != null && _isReady) {
      await _webViewController!.runJavaScript(
        MonacoScripts.executeActionScript(actionId),
      );
    }
  }

  /// Formats the document
  Future<void> format() async => _executeEditorAction('editor.action.formatDocument');

  /// Finds text in the editor
  Future<void> find() async => _executeEditorAction('actions.find');

  /// Replace text in the editor
  Future<void> findAndReplace() async => 
      _executeEditorAction('editor.action.startFindReplaceAction');

  /// Goes to a specific line
  Future<void> goToLine([int? line]) async {
    if (_webViewController != null && _isReady) {
      if (line != null) {
        await _webViewController!.runJavaScript(MonacoScripts.goToLineScript(line));
      } else {
        await _executeEditorAction('editor.action.gotoLine');
      }
    }
  }

  /// Toggles line comments
  Future<void> toggleLineComment() async => 
      _executeEditorAction('editor.action.commentLine');

  /// Toggles block comments
  Future<void> toggleBlockComment() async => 
      _executeEditorAction('editor.action.blockComment');

  /// Triggers auto-completion
  Future<void> triggerSuggest() async => 
      _executeEditorAction('editor.action.triggerSuggest');

  /// Shows the command palette
  Future<void> showCommandPalette() async => 
      _executeEditorAction('editor.action.quickCommand');

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
      await _webViewController!.runJavaScript(MonacoScripts.scrollToBottomScript);
    }
  }

  /// Fold all code blocks
  Future<void> foldAll() async => _executeEditorAction('editor.foldAll');

  /// Unfold all code blocks
  Future<void> unfoldAll() async => _executeEditorAction('editor.unfoldAll');

  /// Select all content
  Future<void> selectAll() async => _executeEditorAction('editor.action.selectAll');

  /// Execute a custom Monaco action by ID
  Future<void> executeAction(String actionId) async => _executeEditorAction(actionId);

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
        final result = await _webViewController!
            .runJavaScriptReturningResult(MonacoScripts.getEditorStatsScript);

        if (result is String) {
          return json.decode(result) as Map<String, dynamic>;
        }
      } catch (e) {
        debugPrint('[MonacoBridgePlatform] Error getting editor stats: $e');
      }
    }
    return {};
  }

  /// Debug method to check Monaco initialization and language support
  Future<Map<String, dynamic>> getDebugInfo() async {
    if (_webViewController != null && _isReady) {
      try {
        final result = await _webViewController!
            .runJavaScriptReturningResult(MonacoScripts.getDebugInfoScript);

        if (result is String) {
          final debugInfo = json.decode(result) as Map<String, dynamic>;
          debugPrint('[MonacoBridgePlatform] Debug info: $debugInfo');
          return debugInfo;
        }
      } catch (e) {
        debugPrint('[MonacoBridgePlatform] Error getting debug info: $e');
      }
    }
    return {'error': 'WebView not ready or not available'};
  }

  // ========================================
  // PRIVATE METHODS
  // ========================================

  /// Push content to the editor
  Future<void> _pushContentToEditor() async {
    if (_webViewController == null || !_isReady) return;

    try {
      final escapedContent = json.encode(_content);
      await _webViewController!.runJavaScript(
        'window.setEditorContent($escapedContent)',
      );
    } catch (e) {
      debugPrint('[MonacoBridgePlatform] Error pushing content: $e');
    }
  }

  /// Push settings to the editor
  Future<void> _pushSettingsToEditor() async {
    if (_webViewController == null || !_isReady) return;

    try {
      final options = MonacoSettingsConverter.toMonacoOptions(_settings);
      final optionsJson = json.encode(options);

      await _webViewController!.runJavaScript(
        'window.setEditorOptions($optionsJson)',
      );
      debugPrint('[MonacoBridgePlatform] Settings pushed to editor');
    } catch (e) {
      debugPrint('[MonacoBridgePlatform] Error pushing settings: $e');
    }
  }

  /// Push language-specific settings
  Future<void> _pushLanguageSpecificSettings(
      EditorSettings languageSettings, String language) async {
    if (_webViewController == null || !_isReady) return;

    try {
      final options = MonacoSettingsConverter.toMonacoOptions(languageSettings);
      final optionsJson = json.encode(options);

      await _webViewController!.runJavaScript(
        'window.setLanguageSpecificOptions && window.setLanguageSpecificOptions("$language", $optionsJson)',
      );
    } catch (e) {
      debugPrint(
          '[MonacoBridgePlatform] Error pushing language-specific settings: $e');
    }
  }

  /// Save current editor state
  Future<void> _saveEditorState() async {
    try {
      final stateJson = (await _webViewController!
              .runJavaScriptReturningResult(MonacoScripts.saveEditorStateScript))!
          as String;
      _lastState = json.decode(stateJson) as Map<String, dynamic>?;
    } catch (e) {
      debugPrint('[MonacoBridgePlatform] Error saving editor state: $e');
      _lastState = null;
    }
  }

  /// Restore editor state
  Future<void> _restoreEditorState() async {
    if (_lastState == null || _webViewController == null || !_isReady) return;

    try {
      await _webViewController!.runJavaScript(
        MonacoScripts.restoreEditorStateScript(json.encode(_lastState)),
      );
    } catch (e) {
      debugPrint('[MonacoBridgePlatform] Error restoring editor state: $e');
    }
  }

  /// Register custom themes (for future use)
  Future<void> registerCustomTheme(
      String themeName, Map<String, dynamic> themeData) async {
    if (_webViewController != null && _isReady) {
      try {
        final themeJson = json.encode(themeData);
        await _webViewController!.runJavaScript(
          'monaco.editor.defineTheme("$themeName", $themeJson)',
        );
      } catch (e) {
        debugPrint('[MonacoBridgePlatform] Error registering custom theme: $e');
      }
    }
  }

  /// Register custom language (for future use)
  Future<void> registerCustomLanguage(
      String languageId, Map<String, dynamic> languageDefinition) async {
    if (_webViewController != null && _isReady) {
      try {
        final langJson = json.encode(languageDefinition);
        await _webViewController!.runJavaScript(
          'monaco.languages.register($langJson)',
        );
      } catch (e) {
        debugPrint(
            '[MonacoBridgePlatform] Error registering custom language: $e');
      }
    }
  }

  @override
  void dispose() {
    debugPrint('[MonacoBridgePlatform] Disposing bridge');
    liveStats.dispose();
    _webViewController?.dispose();
    _webViewController = null;
    super.dispose();
  }
}
