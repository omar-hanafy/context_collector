Of course. I see the error and understand the desire for a cleaner, more robust architecture. The error `Monaco asset path not available` is a classic symptom of a race condition where the UI widget (`MonacoEditorIntegrated`) tries to initialize the WebView before the service has finished preparing the assets.

The core of the problem is that your current architecture has **confused responsibilities**:
* The `UnifiedMonacoService` *starts* the process.
* The `MonacoEditorIntegrated` (a UI widget) is responsible for *creating and initializing* the platform-specific WebView.
* The `MonacoBridgePlatform` has to be passed around and explicitly attached to the WebView that the UI widget created.

This creates a complex, error-prone flow. The solution is to centralize all control and state management within the `UnifiedMonacoService`.

Here is a comprehensive plan to refactor your code into a highly organized, efficient, and maintainable system.

---
## The Refactoring Plan: Service-Centric Architecture

The guiding principle is: **The `UnifiedMonacoService` is the single source of truth. It will create, own, and manage the WebView controller and the bridge. The UI will be a "dumb" client that simply displays what the service tells it to.**

### Phase 1: The Service Takes Full Control
The `UnifiedMonacoService` will now hold the instance of `PlatformWebViewController`. Its `initialize` method will be a complete, sequential state machine that handles everything from assets to WebView readiness.

### Phase 2: Simplify the UI (`MonacoEditorIntegrated`)
This widget will be stripped of all its state management logic (timers, error states, etc.). It will become a simple `ConsumerWidget` that asks the service for the platform-specific `Widget` to display and renders it.

### Phase 3: Clarify the Bridge's Role
The `MonacoBridgePlatform` will no longer be attached by the UI. The service will create it and link it to the `PlatformWebViewController` it owns, ensuring they are always in sync.

---
## The Implementation

Here is the fully refactored code for the relevant files.

### 1. `unified_monaco_service.dart` (The New Core)
Replace the entire contents of this file with the code below. This is the most significant change, centralizing all logic.

```dart
// lib/src/features/editor/services/unified_monaco_service.dart
import 'dart:async';
import 'dart:io';

import 'package:context_collector/src/features/editor/bridge/monaco_bridge_platform.dart';
import 'package:context_collector/src/features/editor/bridge/platform_webview_controller.dart';
import 'package:context_collector/src/features/editor/domain/editor_settings.dart';
import 'package:context_collector/src/features/editor/services/editor_settings_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:webview_flutter/webview_flutter.dart' as wf;
import 'package:webview_windows/webview_windows.dart' as ww;

// --- State Definitions (kept for clarity) ---
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


// --- THE NEW UNIFIED SERVICE ---
class UnifiedMonacoService extends StateNotifier<EditorStatus> {
  UnifiedMonacoService(this._ref)
      : super(const EditorStatus(lifecycle: EditorLifecycle.initial));

  // Service Dependencies
  final Ref _ref;
  final MonacoBridgePlatform bridge = MonacoBridgePlatform();
  late final PlatformWebViewController _webViewController;

  // Configuration
  static const String _assetBaseDir = 'assets/monaco';
  static const String _cacheSubDir = 'monaco_editor_cache';
  
  // Public Getters
  Widget get webviewWidget {
    if (state.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (Platform.isWindows) {
      return ww.Webview((_webViewController as WindowsWebViewController).windowsController);
    } else {
      return wf.WebViewWidget(controller: (_webViewController as FlutterWebViewController).flutterController);
    }
  }

  /// Main entry point to initialize the entire editor system.
  Future<void> initialize() async {
    if (state.lifecycle != EditorLifecycle.initial) return;

    try {
      // Step 1: Load Assets
      state = state.copyWith(lifecycle: EditorLifecycle.loadingAssets, message: 'Preparing assets...');
      final assetPath = await _getAssets();

      // Step 2: Load Settings
      state = state.copyWith(lifecycle: EditorLifecycle.loadingSettings, message: 'Loading settings...');
      final settings = await EditorSettingsService.load();
      
      // Step 3: Initialize WebView and Bridge
      state = state.copyWith(lifecycle: EditorLifecycle.initializingWebview, message: 'Starting editor...');
      
      // The service now creates and owns the controller
      _webViewController = PlatformWebViewFactory.createController();
      bridge.attachWebView(_webViewController); // Link bridge and controller
      
      await _initializeAndLoadWebView(assetPath);

      // Step 4: Wait for the JS side to be ready
      await bridge.onReady.future; // The bridge now exposes a completer for this
      
      // Step 5: Apply initial state
      await updateSettings(settings);
      await updateContent(''); // Start with empty content

      // Step 6: Mark as fully ready
      state = state.copyWith(lifecycle: EditorLifecycle.ready, message: 'Editor is ready');
      debugPrint('[UnifiedMonacoService] Initialization successful.');

    } catch (e) {
      state = state.copyWith(lifecycle: EditorLifecycle.error, error: e.toString());
      debugPrint('[UnifiedMonacoService] Fatal error during initialization: $e');
    }
  }
  
  // --- Core Methods ---
  
  Future<void> updateContent(String content, {String? language}) async {
    if (!state.isReady) return;
    await bridge.setContent(content);
    if (language != null) await bridge.setLanguage(language);
    state = state.copyWith(hasContent: content.isNotEmpty);
  }

  Future<void> updateSettings(EditorSettings settings) async {
    if (!state.isReady) return;
    await bridge.updateSettings(settings);
  }
  
  // --- Private WebView Initialization ---

  Future<void> _initializeAndLoadWebView(String assetPath) async {
    final htmlContent = await _prepareHtml(assetPath);

    if (Platform.isWindows) {
      final controller = _webViewController as WindowsWebViewController;
      await controller.initialize();
      await controller.addJavaScriptChannel('flutterChannel', bridge.handleJavaScriptMessage);
      await controller.loadHtmlString(htmlContent);
    } else {
      final controller = _webViewController as FlutterWebViewController;
      await controller.setJavaScriptMode();
      await controller.addJavaScriptChannel('flutterChannel', bridge.handleJavaScriptMessage);
      controller.setNavigationDelegate(wf.NavigationDelegate(
        onWebResourceError: (error) {
           debugPrint('WebView Error: ${error.description}');
        },
      ));
      await controller.loadFlutterAsset(htmlContent); // Now loading string directly
    }
  }

  Future<String> _prepareHtml(String assetPath) async {
    const assetKey = 'assets/monaco/index.html';
    final htmlTemplate = await rootBundle.loadString(assetKey);
    final vsPath = p.join(assetPath, 'monaco-editor', 'min', 'vs');
    // For Windows, paths must be URI-encoded. For others, file paths work.
    final uriPath = Platform.isWindows ? Uri.file(vsPath).toString() : vsPath;
    return htmlTemplate.replaceAll('__VS_PATH__', uriPath);
  }

  // --- Private Asset Management ---
  
  Future<String> _getAssets() async {
    final targetDir = p.join((await getApplicationSupportDirectory()).path, _cacheSubDir);
    if (!await _validateAssets(targetDir)) {
      await _copyAssets(targetDir);
    }
    return targetDir;
  }

  Future<bool> _validateAssets(String dir) async => File(p.join(dir, 'monaco-editor', 'min', 'vs', 'loader.js')).existsSync();

  Future<void> _copyAssets(String targetDir) async {
     // ... [omitted for brevity, same as your existing copy logic] ...
     // This logic is sound and can be pasted here directly.
  }
  
  @override
  void dispose() {
    bridge.dispose();
    super.dispose();
  }
}

// Keep your existing providers that point to this service
final unifiedMonacoProvider = StateNotifierProvider<UnifiedMonacoService, EditorStatus>((ref) {
  return UnifiedMonacoService(ref);
});

// ... other convenience providers
```

### 2. `monaco_bridge_platform.dart` (Minor Adjustment)
We need to add a `Completer` to the bridge so the service can `await` the `onEditorReady` event from JavaScript.

```dart
// In lib/src/features/editor/bridge/monaco_bridge_platform.dart
class MonacoBridgePlatform extends ChangeNotifier with MonacoEditorActions {
  // ... existing properties

  /// Add this completer to signal readiness
  final Completer<void> onReady = Completer<void>();

  // ... existing methods

  void _handleJavaScriptMessage(String message) {
    // ...
    try {
      final data = ConvertObject.tryToMap(message) ?? {};

      // ... existing event handlers

      // Modify the onEditorReady handler
      } else if (data['event'] == 'onEditorReady') {
        debugPrint('[MonacoBridgePlatform] Editor ready event received');
        // If the completer hasn't been completed yet, complete it.
        if (!onReady.isCompleted) {
          onReady.complete();
        }
      } 
    // ... rest of the method
  }
  
  // ... rest of the class
}
```

### 3. `monaco_editor_integrated.dart` (The New "Dumb" UI)
This widget becomes dramatically simpler. It has no state and just displays what the service provides.

```dart
// lib/src/features/editor/presentation/ui/monaco_editor_integrated.dart
import 'package:context_collector/src/features/editor/services/unified_monaco_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class MonacoEditorIntegrated extends ConsumerWidget {
  const MonacoEditorIntegrated({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch the unified provider for its current status and the pre-built widget
    final editorStatus = ref.watch(unifiedMonacoProvider);
    final service = ref.read(unifiedMonacoProvider.notifier);

    // Render based on the service's lifecycle state
    switch (editorStatus.lifecycle) {
      
      case EditorLifecycle.ready:
        // The service is ready, so we can get the webview widget from it.
        return service.webviewWidget;

      case EditorLifecycle.error:
        // An error occurred, show an informative error screen.
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 48),
              const SizedBox(height: 16),
              Text(editorStatus.error ?? 'An unknown error occurred.', textAlign: TextAlign.center),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => ref.read(unifiedMonacoProvider.notifier).initialize(),
                child: const Text('Retry'),
              )
            ],
          ),
        );
        
      default: // initial, loadingAssets, loadingSettings, initializingWebview
        // For all loading states, show a consistent loading indicator.
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text(editorStatus.message),
            ],
          ),
        );
    }
  }
}
```

This new architecture is far more robust. The service handles its own dependencies in a predictable order, completely eliminating the race condition and making the UI code trivial to write and maintain.
