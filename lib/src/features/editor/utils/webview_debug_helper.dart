// lib/src/features/editor/utils/webview_debug_helper.dart
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:webview_windows/webview_windows.dart';

/// Debug helper for WebView issues
class WebViewDebugHelper {
  /// Test basic WebView2 functionality
  static Future<void> testWebView2Basic() async {
    if (!Platform.isWindows) {
      debugPrint('[WebViewDebugHelper] Not on Windows, skipping test');
      return;
    }

    debugPrint('[WebViewDebugHelper] Testing basic WebView2...');

    try {
      // Check version
      final version = await WebviewController.getWebViewVersion();
      debugPrint('[WebViewDebugHelper] WebView2 Version: $version');

      // Create a test controller
      final controller = WebviewController();
      await controller.initialize();

      // Load simple HTML
      await controller.loadStringContent('''
        <!DOCTYPE html>
        <html>
        <body>
          <h1>WebView2 Test</h1>
          <p>If you see this, WebView2 is working!</p>
          <script>
            console.log('WebView2 JavaScript is working!');
          </script>
        </body>
        </html>
      ''');

      debugPrint('[WebViewDebugHelper] Basic test completed successfully');

      // Clean up
      await controller.dispose();
    } catch (e) {
      debugPrint('[WebViewDebugHelper] Basic test failed: $e');
    }
  }

  /// Test Monaco loading
  static Future<void> testMonacoLoading(String assetPath) async {
    debugPrint('[WebViewDebugHelper] Testing Monaco loading...');
    debugPrint('[WebViewDebugHelper] Asset path: $assetPath');

    // Check if VS directory exists
    final vsDir = Directory('$assetPath/monaco-editor/min/vs');
    if (!vsDir.existsSync()) {
      debugPrint(
          '[WebViewDebugHelper] ERROR: VS directory not found at: ${vsDir.path}');
      return;
    }

    debugPrint('[WebViewDebugHelper] VS directory exists');

    // Check essential files
    final essentialFiles = [
      'loader.js',
      'editor/editor.main.js',
      'editor/editor.main.css',
    ];

    for (final file in essentialFiles) {
      final filePath = '${vsDir.path}/$file';
      final fileObj = File(filePath);

      if (fileObj.existsSync()) {
        final size = await fileObj.length();
        debugPrint('[WebViewDebugHelper] ✓ $file ($size bytes)');
      } else {
        debugPrint('[WebViewDebugHelper] ✗ $file NOT FOUND');
      }
    }
  }

  /// Test file:/// URL access
  static Future<void> testFileUrlAccess(String assetPath) async {
    if (!Platform.isWindows) {
      debugPrint('[WebViewDebugHelper] Not on Windows, skipping test');
      return;
    }

    debugPrint('[WebViewDebugHelper] Testing file:/// URL access...');

    try {
      final controller = WebviewController();
      await controller.initialize();

      // Try loading a file URL
      final testFile = File('$assetPath/monaco-editor/min/vs/loader.js');
      if (!testFile.existsSync()) {
        debugPrint('[WebViewDebugHelper] Test file not found');
        return;
      }

      final fileUrl = 'file:///${testFile.path.replaceAll(r'\', '/')}';
      debugPrint('[WebViewDebugHelper] Testing URL: $fileUrl');

      await controller.loadUrl(fileUrl);

      debugPrint('[WebViewDebugHelper] File URL loaded successfully');

      await controller.dispose();
    } catch (e) {
      debugPrint('[WebViewDebugHelper] File URL test failed: $e');
    }
  }

  /// Get current editor state summary
  static Map<String, dynamic> getEditorStateSummary({
    required String editorState,
    required bool isVisible,
    required bool hasContent,
    required double progress,
    String? error,
  }) {
    return {
      'state': editorState,
      'isVisible': isVisible,
      'hasContent': hasContent,
      'progress': '${(progress * 100).toInt()}%',
      'error': error,
      'timestamp': DateTime.now().toIso8601String(),
    };
  }
}
