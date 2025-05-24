import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:webview_flutter/webview_flutter.dart';

/// Controller for managing Monaco Editor state and operations
class MonacoController extends ChangeNotifier {
  WebViewController? _webViewController;

  String _content = '';
  String _language = 'plaintext';
  String _theme = 'vs-dark';
  double _fontSize = 13;
  bool _wordWrap = false;
  bool _showLineNumbers = true;
  bool _readOnly = true;
  bool _isReady = false;

  // State tracking
  Map<String, dynamic>? _lastState;

  // Getters
  String get content => _content;
  String get language => _language;
  String get theme => _theme;
  double get fontSize => _fontSize;
  bool get wordWrap => _wordWrap;
  bool get showLineNumbers => _showLineNumbers;
  bool get readOnly => _readOnly;
  bool get isReady => _isReady;

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
      _pushOptionsToEditor();
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

  /// Sets the editor theme
  Future<void> setTheme(String theme) async {
    if (_theme == theme) return;

    _theme = theme;

    if (_webViewController != null && _isReady) {
      await _webViewController!.runJavaScript(
        'window.setEditorTheme("$theme")',
      );
    }

    notifyListeners();
  }

  /// Updates editor options
  Future<void> updateOptions({
    double? fontSize,
    bool? wordWrap,
    bool? showLineNumbers,
    bool? readOnly,
  }) async {
    var changed = false;

    if (fontSize != null && fontSize != _fontSize) {
      _fontSize = fontSize;
      changed = true;
    }

    if (wordWrap != null && wordWrap != _wordWrap) {
      _wordWrap = wordWrap;
      changed = true;
    }

    if (showLineNumbers != null && showLineNumbers != _showLineNumbers) {
      _showLineNumbers = showLineNumbers;
      changed = true;
    }

    if (readOnly != null && readOnly != _readOnly) {
      _readOnly = readOnly;
      changed = true;
    }

    if (changed) {
      await _pushOptionsToEditor();
      notifyListeners();
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

  /// Goes to a specific line
  Future<void> goToLine(int line) async {
    if (_webViewController != null && _isReady) {
      await _webViewController!.runJavaScript(
        'if (window.editor) { window.editor.revealLineInCenter($line); window.editor.setPosition({ lineNumber: $line, column: 1 }); }',
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

  // Private methods
  Future<void> _pushContentToEditor() async {
    if (_webViewController == null || !_isReady) return;

    final String escapedContent = json.encode(_content);
    await _webViewController!.runJavaScript(
      'window.setEditorContent($escapedContent)',
    );
  }

  Future<void> _pushOptionsToEditor() async {
    if (_webViewController == null || !_isReady) return;

    final options = {
      'fontSize': _fontSize,
      'wordWrap': _wordWrap ? 'on' : 'off',
      'lineNumbers': _showLineNumbers ? 'on' : 'off',
      'readOnly': _readOnly,
    };

    final String optionsJson = json.encode(options);
    await _webViewController!.runJavaScript(
      'window.setEditorOptions($optionsJson)',
    );
  }

  Future<void> _saveEditorState() async {
    try {
      // Save current state manually since original HTML doesn't have saveState method
      final stateJson = await _webViewController!.runJavaScriptReturningResult(
        '''
JSON.stringify({
          position: window.editor?.getPosition(),
          selection: window.editor?.getSelection(),
          scrollTop: window.editor?.getScrollTop(),
          scrollLeft: window.editor?.getScrollLeft()
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
      // Restore state manually
      await _webViewController!.runJavaScript('''
        if (window.editor) {
          const state = ${json.encode(_lastState)};
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
      ''');
    } catch (e) {
      debugPrint('Error restoring editor state: $e');
    }
  }

  @override
  void dispose() {
    _webViewController = null;
    super.dispose();
  }
}
