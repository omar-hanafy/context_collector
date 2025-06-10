import 'dart:async';
import 'dart:io';

import 'package:context_collector/src/features/editor/bridge/monaco_bridge_platform.dart';
import 'package:context_collector/src/features/editor/bridge/platform_webview_controller.dart';
import 'package:context_collector/src/features/editor/domain/editor_settings.dart';
import 'package:context_collector/src/features/editor/services/editor_settings_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
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

// --- THE UNIFIED SERVICE ---
class UnifiedMonacoService extends StateNotifier<EditorStatus> {
  UnifiedMonacoService()
      : super(const EditorStatus(lifecycle: EditorLifecycle.initial));

  final MonacoBridgePlatform bridge = MonacoBridgePlatform();
  late final PlatformWebViewController _webViewController;

  static const String _assetBaseDir = 'assets/monaco';
  static const String _cacheSubDir = 'monaco_editor_cache';

  String? _assetPath;
  bool _isDisposed = false;

  // --- FIX: Add a variable to queue content that arrives before the editor is ready ---
  String? _queuedContent;

  Widget get webviewWidget {
    if (state.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (Platform.isWindows) {
      return ww.Webview(
          (_webViewController as WindowsWebViewController).windowsController);
    } else {
      return wf.WebViewWidget(
          controller: (_webViewController as FlutterWebViewController)
              .flutterController);
    }
  }

  Future<void> initialize() async {
    if (state.lifecycle != EditorLifecycle.initial) return;
    debugPrint(
        '[UnifiedMonacoService] Full initialization sequence started...');

    try {
      state = state.copyWith(
          lifecycle: EditorLifecycle.loadingAssets,
          message: 'Preparing assets...');
      _assetPath = await _getAssets();
      if (_isDisposed) return;

      state = state.copyWith(
          lifecycle: EditorLifecycle.loadingSettings,
          message: 'Loading settings...');
      final settings = await EditorSettingsServiceHelper.load();
      if (_isDisposed) return;

      state = state.copyWith(
          lifecycle: EditorLifecycle.initializingWebview,
          message: 'Starting editor...');
      _webViewController = PlatformWebViewFactory.createController();
      bridge.attachWebView(_webViewController);

      await _initializeAndLoadWebView(_assetPath!);
      if (_isDisposed) return;

      await bridge.onReady.future.timeout(const Duration(seconds: 20),
          onTimeout: () => throw TimeoutException(
              'Monaco Editor did not report back as ready in 20 seconds.'));

      if (_isDisposed) return;

      // Apply initial settings FIRST
      await bridge.updateSettings(settings);

      // --- FIX: Check for and apply any queued content that arrived during initialization ---
      if (_queuedContent != null) {
        debugPrint('[UnifiedMonacoService] Applying queued content...');
        await bridge.setContent(_queuedContent!);
        state = state.copyWith(hasContent: _queuedContent!.isNotEmpty);
        _queuedContent = null; // Clear the queue
      } else {
        await bridge
            .setContent(''); // Start with empty content if nothing was queued
      }

      state = state.copyWith(
          lifecycle: EditorLifecycle.ready, message: 'Editor is ready');
      debugPrint('[UnifiedMonacoService] Initialization successful.');
    } catch (e) {
      if (_isDisposed) return;
      state =
          state.copyWith(lifecycle: EditorLifecycle.error, error: e.toString());
      debugPrint(
          '[UnifiedMonacoService] Fatal error during initialization: $e');
    }
  }

  // --- FIX: Modified updateContent to handle the queue ---
  Future<void> updateContent(String content, {String? language}) async {
    // If the editor isn't ready yet, queue the content and exit.
    if (!state.isReady) {
      debugPrint('[UnifiedMonacoService] Editor not ready. Queuing content.');
      _queuedContent = content;
      return;
    }

    // If we are ready, update the content directly.
    await bridge.setContent(content);
    if (language != null) await bridge.setLanguage(language);

    if (mounted) {
      state = state.copyWith(hasContent: content.isNotEmpty);
    }
  }

  Future<void> updateSettings(EditorSettings settings) async {
    // We don't need to queue settings, as they are loaded once on init.
    // This method is for live updates after the editor is ready.
    if (!state.isReady) return;
    await bridge.updateSettings(settings);
  }

  // --- Private WebView and Asset Logic (Unchanged but included for completeness) ---

  Future<void> _initializeAndLoadWebView(String assetPath) async {
    if (Platform.isWindows) {
      final controller = _webViewController as WindowsWebViewController;
      await controller.initialize();
      await controller.addJavaScriptChannel(
          'flutterChannel', bridge.handleJavaScriptMessage);
      final htmlContent = await _prepareHtml(assetPath, forWindows: true);
      await controller.loadHtmlString(htmlContent);
    } else {
      final controller = _webViewController as FlutterWebViewController;
      final htmlContent = await _prepareHtml(assetPath, forWindows: false);
      final tempFile = File(p.join(assetPath, 'index.html'));
      await tempFile.writeAsString(htmlContent);

      await controller.setJavaScriptMode();
      await controller.addJavaScriptChannel(
          'flutterChannel', bridge.handleJavaScriptMessage);
      controller.setNavigationDelegate(wf.NavigationDelegate(
        onWebResourceError: (error) =>
            debugPrint('WebView Error: ${error.description}'),
      ));
      await controller.loadFile(tempFile.path);
    }
  }

  Future<String> _prepareHtml(String assetPath,
      {required bool forWindows}) async {
    const assetKey = 'assets/monaco/index.html';
    final htmlTemplate = await rootBundle.loadString(assetKey);
    final vsPath = p.join(assetPath, 'monaco-editor', 'min', 'vs');
    final finalPath =
        forWindows ? Uri.file(vsPath).toString() : './monaco-editor/min/vs';
    return htmlTemplate.replaceAll('__VS_PATH__', finalPath);
  }

  Future<String> _getAssets() async {
    final targetDir =
        p.join((await getApplicationSupportDirectory()).path, _cacheSubDir);
    if (!File(p.join(targetDir, 'monaco-editor', 'min', 'vs', 'loader.js'))
        .existsSync()) {
      await _copyAssets(targetDir);
    }
    return targetDir;
  }

  Future<void> _copyAssets(String targetDir) async {
    final directory = Directory(targetDir);
    if (directory.existsSync()) {
      await directory.delete(recursive: true);
    }
    await directory.create(recursive: true);
    final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
    final assets =
        manifest.listAssets().where((key) => key.startsWith(_assetBaseDir));
    for (final key in assets) {
      final relativePath = key.substring('$_assetBaseDir/'.length);
      if (relativePath.isEmpty) continue;
      final targetFile = File(p.join(targetDir, relativePath));
      await targetFile.parent.create(recursive: true);
      final bytes = await rootBundle.load(key);
      await targetFile.writeAsBytes(bytes.buffer.asUint8List());
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    bridge.dispose();
    super.dispose();
  }
}
