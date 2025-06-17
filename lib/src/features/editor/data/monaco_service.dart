import 'dart:async';
import 'dart:io';

import 'package:context_collector/context_collector.dart';
import 'package:context_collector/src/features/editor/data/monaco_asset_manager.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:webview_flutter/webview_flutter.dart' as wf;
import 'package:webview_windows/webview_windows.dart' as ww;

// --- State Definitions ---
enum EditorLifecycle {
  initial,
  loadingAssets,
  loadingSettings,
  initializingWebview,
  ready,
  error,
}

@immutable
class EditorStatus {
  const EditorStatus({
    this.lifecycle = EditorLifecycle.initial,
    this.message = 'Initializing...',
    this.error,
    this.hasContent = false,
  });

  final EditorLifecycle lifecycle;
  final String message;
  final String? error;
  final bool hasContent;

  EditorStatus copyWith({
    EditorLifecycle? lifecycle,
    String? message,
    String? error,
    bool? hasContent,
  }) {
    return EditorStatus(
      lifecycle: lifecycle ?? this.lifecycle,
      message: message ?? this.message,
      error: error ?? this.error,
      hasContent: hasContent ?? this.hasContent,
    );
  }

  bool get isReady => lifecycle == EditorLifecycle.ready;
  bool get isLoading => !isReady && lifecycle != EditorLifecycle.error;
  bool get hasError => lifecycle == EditorLifecycle.error;
}

// --- THE MONACO SERVICE ---
class MonacoService extends StateNotifier<EditorStatus> {
  MonacoService()
    : super(const EditorStatus(lifecycle: EditorLifecycle.initial));

  final MonacoBridgePlatform bridge = MonacoBridgePlatform();
  PlatformWebViewController? _webViewController;

  String? _assetPath;
  bool _isDisposed = false;
  String? _queuedContent;

  /// Returns the platform-specific WebView widget
  Widget get webviewWidget {
    if (state.isLoading || _webViewController == null) {
      return const Center(child: CircularProgressIndicator());
    }

    if (Platform.isWindows) {
      return ww.Webview(
        (_webViewController! as WindowsWebViewController).windowsController,
      );
    } else {
      return wf.WebViewWidget(
        controller:
            (_webViewController! as FlutterWebViewController).flutterController,
      );
    }
  }

  /// Initialize the Monaco editor
  Future<void> initialize() async {
    // Prevent re-initialization unless in initial or error state
    if (state.lifecycle != EditorLifecycle.initial &&
        state.lifecycle != EditorLifecycle.error) {
      return;
    }

    debugPrint('[MonacoService] Full initialization sequence started...');

    try {
      // Step 1: Load Monaco assets
      await _loadAssets();
      if (_isDisposed) return;

      // Step 2: Load editor settings
      await _loadSettings();
      if (_isDisposed) return;

      // Step 3: Initialize WebView
      await _initializeWebView();
      if (_isDisposed) return;

      // Step 4: Wait for editor ready signal
      await _waitForEditorReady();
      if (_isDisposed) return;

      // Step 5: Apply initial configuration
      await _applyInitialConfiguration();

      state = state.copyWith(
        lifecycle: EditorLifecycle.ready,
        message: 'Editor is ready',
      );
      debugPrint('[MonacoService] Initialization successful.');
    } catch (e, st) {
      if (_isDisposed) return;
      _handleError(e, st);
    }
  }

  /// Update editor content
  Future<void> updateContent(String content, {String? language}) async {
    if (!state.isReady) {
      debugPrint('[MonacoService] Editor not ready. Queuing content.');
      _queuedContent = content;
      return;
    }

    await bridge.setContent(content);
    if (language != null) {
      await bridge.setLanguage(language);
    }

    if (mounted) {
      state = state.copyWith(hasContent: content.isNotEmpty);
    }
  }

  /// Update editor settings
  Future<void> updateSettings(EditorSettings settings) async {
    if (!state.isReady) return;
    await bridge.updateSettings(settings);
  }

  // --- Private Methods ---

  Future<void> _loadAssets() async {
    state = state.copyWith(
      lifecycle: EditorLifecycle.loadingAssets,
      message: 'Preparing assets...',
      error: null,
    );

    // MonacoAssetManager now handles everything: copying assets AND creating HTML
    _assetPath = await MonacoAssetManager.getAssetsDirectory();
    debugPrint('[MonacoService] Assets ready at: $_assetPath');
  }

  Future<void> _loadSettings() async {
    state = state.copyWith(
      lifecycle: EditorLifecycle.loadingSettings,
      message: 'Loading settings...',
    );

    // Settings are loaded but applied after editor is ready
    final settings = await EditorSettingsServiceHelper.load();
    debugPrint('[MonacoService] Settings loaded.');
  }

  Future<void> _initializeWebView() async {
    state = state.copyWith(
      lifecycle: EditorLifecycle.initializingWebview,
      message: 'Starting editor...',
    );

    // Create platform-specific controller
    _webViewController ??= PlatformWebViewFactory.createController();
    bridge.attachWebView(_webViewController!);

    // Platform-specific initialization
    if (Platform.isWindows) {
      await _initializeWindowsWebView();
    } else {
      await _initializeMacOSWebView();
    }

    debugPrint('[MonacoService] WebView initialized and content loading.');
  }

  Future<void> _initializeWindowsWebView() async {
    final controller = _webViewController! as WindowsWebViewController;

    // Initialize WebView2
    await controller.initialize();

    // Set up JavaScript channel
    await controller.addJavaScriptChannel(
      'flutterChannel',
      bridge.handleJavaScriptMessage,
    );

    // Prepare HTML with absolute paths and Windows-specific scripts
    final vsPath = p.join(_assetPath!, 'monaco-editor', 'min', 'vs');
    final absoluteVsPath = Uri.file(vsPath).toString();
    var htmlContent = EditorConstants.indexHtmlFile(absoluteVsPath);

    // Add Windows flutter channel script
    htmlContent = _addWindowsChannelScript(htmlContent);

    // Load HTML directly
    await controller.loadHtmlString(htmlContent);
  }

  Future<void> _initializeMacOSWebView() async {
    final controller = _webViewController! as FlutterWebViewController;

    // Configure WebView
    await controller.setJavaScriptMode();
    await controller.addJavaScriptChannel(
      'flutterChannel',
      bridge.handleJavaScriptMessage,
    );

    // Set up console logging for debugging
    await controller.setOnConsoleMessage((message) {
      debugPrint(
        '[Monaco Console] ${message.level.name}: ${message.message}',
      );
    });

    // Set navigation delegates
    controller.setNavigationDelegate(
      wf.NavigationDelegate(
        onPageFinished: (url) {
          debugPrint('[MonacoService] WebView Page Finished: $url');
        },
        onWebResourceError: (error) {
          debugPrint(
            '[MonacoService] WebView Error: ${error.description} on ${error.url}',
          );
        },
      ),
    );

    // Get HTML file path from MonacoAssetManager (single source of truth)
    final htmlFilePath = await MonacoAssetManager.getHtmlFilePath();

    debugPrint('[MonacoService] Loading HTML from: $htmlFilePath');
    await controller.flutterController.loadFile(htmlFilePath);
  }

  Future<void> _waitForEditorReady() async {
    debugPrint('[MonacoService] Waiting for onReady event from JS...');

    await bridge.onReady.future.timeout(
      const Duration(seconds: 20),
      onTimeout: () => throw TimeoutException(
        'Monaco Editor did not report back as ready in 20 seconds.',
      ),
    );

    debugPrint('[MonacoService] onReady event received!');
  }

  Future<void> _applyInitialConfiguration() async {
    // Apply settings
    final settings = await EditorSettingsServiceHelper.load();
    await bridge.updateSettings(settings);
    debugPrint('[MonacoService] Initial settings applied.');

    // Apply queued content if any
    if (_queuedContent != null) {
      debugPrint('[MonacoService] Applying queued content...');
      await bridge.setContent(_queuedContent!);
      state = state.copyWith(hasContent: _queuedContent!.isNotEmpty);
      _queuedContent = null;
    } else {
      await bridge.setContent('');
    }
  }

  String _addWindowsChannelScript(String html) {
    const channelScript =
        '''
<script>
${MonacoScripts.windowsFlutterChannelScript}
</script>
''';
    return html.replaceFirst('<head>', '<head>\n$channelScript');
  }

  void _handleError(dynamic error, StackTrace stackTrace) {
    state = state.copyWith(
      lifecycle: EditorLifecycle.error,
      error: error.toString(),
    );
    debugPrint(
      '[MonacoService] Fatal error during initialization: $error\n$stackTrace',
    );
  }

  @override
  void dispose() {
    _isDisposed = true;
    bridge.dispose();
    _webViewController?.dispose();
    super.dispose();
  }
}
