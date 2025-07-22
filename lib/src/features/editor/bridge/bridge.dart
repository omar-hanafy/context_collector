import 'dart:async';
import 'dart:convert';

import 'package:context_collector/context_collector.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_helper_utils/flutter_helper_utils.dart';

/// A communication bridge between the Flutter application and the Monaco Editor
/// instance running in a WebView.
///
/// the editor (like readiness and stats updates) and sending commands to it (like
/// setting content, changing language, or executing actions). It uses the
/// [MonacoEditorActions] mixin to provide a clean API for common editor operations.
class MonacoBridgePlatform extends ChangeNotifier with MonacoEditorActions {
  PlatformWebViewController? _webViewController;

  // --- State Management ---
  /// A completer that signals when the Monaco Editor's JavaScript `onEditorReady`
  /// event has been received, indicating that the editor is fully initialized.
  final Completer<void> onReady = Completer<void>();

  /// A [ValueNotifier] that provides real-time statistics from the editor,
  /// such as line count, character count, and selection details.
  final ValueNotifier<LiveStats> liveStats =
      const LiveStats.defaults().notifier;

  String _content = '';
  String _language = 'markdown';

  /// Gets the current content of the editor.
  String get content => _content;

  /// Gets the current language syntax of the editor.
  String get language => _language;

  // --- Lifecycle and WebView Integration ---

  /// Attaches the platform-specific [PlatformWebViewController] to the bridge.
  ///
  /// This method is called by the managing service once the WebView is created,
  /// establishing the connection needed to execute JavaScript.
  void attachWebView(PlatformWebViewController controller) {
    _webViewController = controller;
    debugPrint('[MonacoBridgePlatform] WebView controller attached.');
  }

  /// The primary entry point for all messages sent from the WebView's JavaScript.
  ///
  /// This method normalizes the incoming message and passes it to the internal
  /// [_handleJavaScriptMessage] for parsing and dispatching.
  void handleJavaScriptMessage(dynamic message) {
    // Normalize message content, as platform implementations can vary.
    final String messageContent = message is String
        ? message
        : (message.runtimeType.toString() == 'JavaScriptMessage'
              // ignore: avoid_dynamic_calls
              ? message.message as String
              : message.toString());

    _handleJavaScriptMessage(messageContent);
  }

  // --- Public API for Editor Operations ---

  /// Updates the editor's entire content.
  ///
  /// The new content is JSON-encoded to ensure safe transmission to JavaScript.
  Future<void> setContent(String newContent) async {
    if (_webViewController == null) return;
    _content = newContent;
    final escapedContent = json.encode(newContent);
    await _webViewController!.runJavaScript(
      'window.setEditorContent($escapedContent)',
    );
    notifyListeners();
  }

  /// Updates the editor's language for syntax highlighting and other features.
  Future<void> setLanguage(String newLanguage) async {
    if (_webViewController == null) return;
    _language = newLanguage;
    await _webViewController!.runJavaScript(
      'window.setEditorLanguage && window.setEditorLanguage("$newLanguage")',
    );
    notifyListeners();
  }

  /// Pushes a new set of editor options to Monaco.
  ///
  /// This updates the editor's appearance and behavior based on an [EditorSettings]
  /// object, including theme and other Monaco-specific options.
  Future<void> updateSettings(EditorSettings settings) async {
    if (_webViewController == null) return;
    debugPrint('[MonacoBridgePlatform] Pushing settings to editor...');
    final optionsJson = json.encode(settings.toMonacoOptions());
    await _webViewController!.runJavaScript(
      'window.setEditorOptions($optionsJson)',
    );
    await _webViewController!.runJavaScript(
      'window.setEditorTheme("${settings.theme}")',
    );
    notifyListeners();
  }

  /// Scrolls the editor to the first line.
  Future<void> scrollToTop() async {
    if (_webViewController == null) return;
    await _webViewController!.runJavaScript(MonacoScripts.scrollToTopScript);
  }

  /// Scrolls the editor to the last line.
  Future<void> scrollToBottom() async {
    if (_webViewController == null) return;
    await _webViewController!.runJavaScript(MonacoScripts.scrollToBottomScript);
  }

  /// Gets the current content directly from the Monaco editor instance.
  ///
  /// This is the most reliable way to get the latest content, including any
  /// user edits that haven't been pushed back to the Flutter state.
  Future<String> getCurrentContent() async {
    if (_webViewController == null) return '';
    try {
      // Use 'window.editor?.getValue()' for safety. It won't throw an error
      // if the editor isn't ready, and '?? ""' handles the null case.
      final result = await _webViewController!
          .runJavaScriptReturningResult('window.editor?.getValue() ?? ""');
      return result?.toString() ?? '';
    } catch (e) {
      debugPrint('[MonacoBridgePlatform] Failed to get editor content: $e');
      return ''; // Return empty string on error
    }
  }

  /// Programmatically sets focus on the Monaco editor instance in the WebView.
  ///
  /// This is crucial for restoring keyboard input on macOS after a Flutter
  /// dialog or modal has been shown and dismissed.
  Future<void> requestFocus() async {
    if (_webViewController == null) return;
    // The editor.focus() call is the official Monaco API to grab focus.
    await _webViewController!.runJavaScript('window.editor?.focus()');
    debugPrint('[MonacoBridgePlatform] Focus requested.');
  }

  // --- Overridden Methods ---

  @override
  Future<void> executeEditorAction(String actionId, [dynamic args]) async {
    if (_webViewController == null) return;

    // json.encode will correctly handle null `args` by converting it to the string 'null'.
    final argsJson = json.encode(args);

    // This is the safer script.
    // 1. It uses `window.editor`, which is the specific instance of the editor we are controlling.
    // 2. It uses the optional chaining operator `?.` which prevents an error if `window.editor` hasn't been initialized yet.
    // 3. It uses `trigger()`, which is the high-level API for running commands. It fails gracefully if the actionId doesn't exist.
    final script =
        'window.editor?.trigger("flutter-bridge", "$actionId", $argsJson)';

    await _webViewController!.runJavaScript(script);
  }

  @override
  void dispose() {
    debugPrint('[MonacoBridgePlatform] Disposing bridge.');
    if (!onReady.isCompleted) {
      onReady.completeError(
        Exception('Bridge disposed before the editor became ready.'),
      );
    }
    liveStats.dispose();
    _webViewController?.dispose(); // Ensure the controller is also disposed.
    super.dispose();
  }

  // --- Private Helpers ---

  /// Injects the JavaScript responsible for monitoring and reporting editor stats.
  Future<void> _injectLiveStatsJavaScript() async {
    if (_webViewController == null) return;
    await _webViewController!.runJavaScript(MonacoScripts.liveStatsMonitoring);
  }

  /// Parses and dispatches all incoming messages from the editor's JavaScript.
  void _handleJavaScriptMessage(String message) {
    // Handle simple log messages from JS without JSON parsing. This is efficient.
    if (message.startsWith('log:')) {
      debugPrint('[Monaco JS] ${message.substring(4)}');
      return;
    }

    // The try-catch block MUST wrap the JSON conversion to handle parsing errors.
    try {
      // The conversion is now safely inside the try block.
      final Map<String, dynamic> json = ConvertObject.toMap<String, dynamic>(
        message,
      );

      switch (json) {
        case {'event': 'onEditorReady'} when !onReady.isCompleted:
          debugPrint('[MonacoBridge] ✅ "onEditorReady" event received.');
          onReady.complete();
          _injectLiveStatsJavaScript();
        // It's good practice to add breaks in switch statements.

        case {'event': 'onEditorReady'}:
          debugPrint(
            '[MonacoBridge] "onEditorReady" already completed, ignoring.',
          );

        // --- OPTION 1: For Dart 3.4+ (Recommended if available) ---
        case final Map<String, dynamic> data when data['event'] == 'stats':
          liveStats.value = LiveStats.fromJson(data);

        case {'event': 'error', 'message': final String message}:
          debugPrint('❌ [Monaco JS Error] $message');

        case {'event': final String event}:
          debugPrint('[MonacoBridge] Unhandled JS event type: "$event"');

        default:
          debugPrint('[MonacoBridge] Unhandled or malformed JS message.');
      }
    } catch (e) {
      // This will now correctly catch errors from both parsing and switching logic.
      debugPrint(
        '[MonacoBridge] Could not process JS message. Raw: "$message". Error: $e',
      );
    }
  }
}

@immutable
class LiveStats extends Equatable {
  // --- CONSTRUCTORS ---
  const LiveStats({
    required this.lineCount,
    required this.charCount,
    required this.selectedLines,
    required this.selectedCharacters,
    required this.caretCount,
  });

  /// A factory for creating an initial/empty state with default labels.
  const LiveStats.defaults({
    this.lineCount = (value: 0, label: 'Ln'),
    this.charCount = (value: 0, label: 'Ch'),
    this.selectedLines = (value: 0, label: 'Sel Ln'),
    this.selectedCharacters = (value: 0, label: 'Sel Ch'),
    this.caretCount = (value: 0, label: 'Cursors'),
  });

  /// The fromJson factory now constructs the records, pairing the
  /// integer from the JSON with its corresponding hardcoded label.
  /// JSON: {event: stats, lineCount: 2, charCount: 75, selLines: 0, selChars: 0, caretCount: 1}
  factory LiveStats.fromJson(Map<String, dynamic> json) {
    return LiveStats(
      lineCount: (
        value: json.getInt('lineCount', defaultValue: 0),
        label: 'Ln',
      ),
      charCount: (
        value: json.getInt('charCount', defaultValue: 0),
        label: 'Ch',
      ),
      selectedLines: (
        value: json.getInt('selLines', defaultValue: 0),
        label: 'Sel Ln',
      ),
      selectedCharacters: (
        value: json.getInt('selChars', defaultValue: 0),
        label: 'Sel Ch',
      ),
      caretCount: (
        value: json.getInt('caretCount', defaultValue: 0),
        label: 'Cursors',
      ),
    );
  }

  // --- PROPERTIES ---
  // The properties are now records containing both the value and its label.
  final ({int value, String label}) lineCount;
  final ({int value, String label}) charCount;
  final ({int value, String label}) selectedLines;
  final ({int value, String label}) selectedCharacters;
  final ({int value, String label}) caretCount;

  // --- GETTERS & PROPS ---

  /// The getter now accesses the `.value` of the record.
  bool get hasSelection => selectedCharacters.value > 0;

  @override
  List<Object?> get props => [
    lineCount,
    charCount,
    selectedLines,
    selectedCharacters,
    caretCount,
  ];
}
