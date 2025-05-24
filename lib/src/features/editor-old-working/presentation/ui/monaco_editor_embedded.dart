import 'dart:async';
import 'dart:io';

import 'package:dart_helper_utils/dart_helper_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../bridge/monaco_bridge.dart';
import '../../../../shared/theme/extensions.dart';

/// Optimized Monaco Editor widget using single WebView implementation
class MonacoEditorEmbedded extends StatefulWidget {
  const MonacoEditorEmbedded({
    super.key,
    required this.bridge,
    this.onReady,
    this.height,
  });

  final MonacoBridge bridge;
  final VoidCallback? onReady;
  final double? height;

  @override
  State<MonacoEditorEmbedded> createState() => _MonacoEditorEmbeddedState();
}

class _MonacoEditorEmbeddedState extends State<MonacoEditorEmbedded> {
  late WebViewController _webViewController;
  bool _isLoading = true;
  String? _error;
  Timer? _initTimer;

  @override
  void initState() {
    super.initState();
    _initWebView();
  }

  @override
  void dispose() {
    _initTimer?.cancel();
    widget.bridge.detachWebView();
    super.dispose();
  }

  Future<void> _initWebView() async {
    try {
      // Setup timeout
      _initTimer = Timer(const Duration(seconds: 10), () {
        if (!widget.bridge.isReady && mounted) {
          setState(() {
            _error = 'Monaco Editor initialization timed out';
            _isLoading = false;
          });
        }
      });

      // Initialize WebViewController
      _webViewController = WebViewController();
      await _webViewController.setJavaScriptMode(JavaScriptMode.unrestricted);

      // Platform-specific setup
      if (!Platform.isMacOS) {
        await _webViewController.setBackgroundColor(Colors.transparent);
      }

      // Add communication channel
      await _webViewController.addJavaScriptChannel(
        'flutterChannel',
        onMessageReceived: _handleMessage,
      );

      // Set navigation delegate
      await _webViewController.setNavigationDelegate(
        NavigationDelegate(
          onProgress: (int progress) {
            if (progress == 100) {
              // Inject JS bridge code
              _webViewController.runJavaScript('''
                console.originalLog = console.log;
                console.log = function(...args) {
                  console.originalLog.apply(console, args);
                  if (window.flutterChannel) {
                    try {
                      window.flutterChannel.postMessage('log:' + args.join(' '));
                    } catch(e) {
                      console.originalLog('Error sending log to Flutter:', e);
                    }
                  }
                  if (args[0] === "Monaco editor instance created successfully") {
                    if (window.flutterChannel) {
                      window.flutterChannel.postMessage(JSON.stringify({event: 'onEditorReady'}));
                    }
                  }
                };
                
                // Force immediate execution to check for editor
                setTimeout(function() {
                  if (window.editor) {
                    if (window.flutterChannel) {
                      window.flutterChannel.postMessage(JSON.stringify({event: 'onEditorReady'}));
                    }
                  }
                }, 1000);
              ''');
            }
          },
          onPageFinished: (_) => _onPageLoaded(),
          onWebResourceError: _onLoadError,
          onNavigationRequest: (NavigationRequest request) {
            if (request.url.startsWith('flutter://')) {
              final payload = Uri.decodeFull(request.url.substring(10));
              _handleUrlMessage(payload);
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
        ),
      );

      // Load HTML
      await _loadMonacoHtml();

      // Attach to bridge
      widget.bridge.attachWebView(_webViewController);
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to initialize Monaco: $e';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadMonacoHtml() async {
    const asset = 'assets/monaco/index.html';

    try {
      if (Platform.isAndroid || Platform.isIOS) {
        // Mobile: Use loadFlutterAsset directly
        await _webViewController.loadFlutterAsset(asset);
        return;
      }

      // Desktop: We need to copy assets and inject the VS path
      final tempDir = await Directory.systemTemp.createTemp('monaco_editor');

      // Copy only essential Monaco files
      final vsPath = await _copyMonacoAssets(tempDir.path);

      // Load and modify the HTML content
      final htmlContent = await rootBundle.loadString(asset);
      final modifiedHtml = htmlContent.replaceAll('__VS_PATH__', vsPath);

      // Write the modified HTML to a temp file
      final htmlFile = File('${tempDir.path}/index.html');
      await htmlFile.writeAsString(modifiedHtml);

      // Load the temp HTML file
      await _webViewController.loadFile(htmlFile.path);

      // Schedule cleanup
      Future.delayed(const Duration(minutes: 5), () {
        try {
          tempDir.deleteSync(recursive: true);
        } catch (_) {
          // Ignore cleanup errors
        }
      });
    } catch (e) {
      throw Exception('Failed to load editor HTML: $e');
    }
  }

  Future<String> _copyMonacoAssets(String targetDir) async {
    final vsDir = Directory('$targetDir/vs');
    await vsDir.create(recursive: true);

    // Essential files only
    const essentialFiles = [
      'loader.js',
      'editor/editor.main.js',
      'editor/editor.main.css',
      'base/worker/workerMain.js',
    ];

    // Essential language files
    const languages = [
      'basic-languages/dart/dart.js',
      'basic-languages/javascript/javascript.js',
      'basic-languages/typescript/typescript.js',
      'basic-languages/python/python.js',
      'basic-languages/json/json.js',
      'basic-languages/html/html.js',
      'basic-languages/css/css.js',
      'basic-languages/yaml/yaml.js',
      'basic-languages/markdown/markdown.js',
      'basic-languages/xml/xml.js',
      'basic-languages/sql/sql.js',
      'basic-languages/shell/shell.js',
      // Advanced language support
      'language/typescript/tsMode.js',
      'language/typescript/tsWorker.js',
      'language/css/cssMode.js',
      'language/css/cssWorker.js',
      'language/json/jsonMode.js',
      'language/json/jsonWorker.js',
      'language/html/htmlMode.js',
      'language/html/htmlWorker.js',
    ];

    // Copy core files
    for (final file in essentialFiles) {
      await _copyAssetFile(
        'assets/monaco/monaco-editor/min/vs/$file',
        '$targetDir/vs/$file',
      );
    }

    // Copy language files
    for (final langFile in languages) {
      try {
        await _copyAssetFile(
          'assets/monaco/monaco-editor/min/vs/$langFile',
          '$targetDir/vs/$langFile',
        );
      } catch (_) {
        // Some language files might not exist, ignore
      }
    }

    // Copy required font file
    await _copyAssetFile(
      'assets/monaco/monaco-editor/min/vs/base/browser/ui/codicons/codicon/codicon.ttf',
      '$targetDir/vs/base/browser/ui/codicons/codicon/codicon.ttf',
    );

    return Uri.file(vsDir.path).toString();
  }

  Future<void> _copyAssetFile(String assetPath, String targetPath) async {
    final targetFile = File(targetPath);
    await targetFile.parent.create(recursive: true);

    final bytes = await rootBundle.load(assetPath);
    await targetFile.writeAsBytes(bytes.buffer.asUint8List());
  }

  void _handleUrlMessage(String payload) {
    if (payload.startsWith('onEditorReady')) {
      _onEditorReady();
    }
  }

  void _handleMessage(JavaScriptMessage message) {
    try {
      // Handle both direct messages and log messages
      if (message.message.startsWith('log:')) {
        // Console log message, ignore
        return;
      }

      final data = tryToMap(message.message) ?? {};
      final event = data.tryGetString('event');

      if (event == 'onEditorReady') {
        _onEditorReady();
      } else if (event == 'contentChanged') {
        // Handle content changes if needed
      }
    } catch (e) {
      // Try to handle as a simple string message
      if (message.message == 'EDITOR_READY_EVENT_FIRED') {
        _onEditorReady();
      } else {
        debugPrint('Error handling Monaco message: $e');
      }
    }
  }

  void _onPageLoaded() {
    // Page loaded, waiting for editor ready
    if (mounted) {
      setState(() {
        _isLoading = true;
      });
    }
  }

  void _onLoadError(WebResourceError error) {
    if (mounted) {
      setState(() {
        _error = 'Failed to load Monaco: ${error.description}';
        _isLoading = false;
      });
    }
  }

  Future<void> _onEditorReady() async {
    _initTimer?.cancel();

    widget.bridge.markReady();

    // Apply initial content if any
    if (widget.bridge.content.isNotEmpty) {
      await widget.bridge.setContent(widget.bridge.content);
    }

    // Apply initial options
    await widget.bridge.updateOptions();

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }

    widget.onReady?.call();
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return _buildErrorView();
    }

    return SizedBox(
      height: widget.height ?? double.infinity,
      child: Stack(
        children: [
          WebViewWidget(controller: _webViewController),
          if (_isLoading)
            ColoredBox(
              color: context.isDark ? const Color(0xFF1E1E1E) : Colors.white,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(),
                    const SizedBox(height: 16),
                    Text(
                      'Loading Monaco Editor...',
                      style: context.bodyMedium?.copyWith(
                        color: context.onSurface.addOpacity(0.6),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildErrorView() {
    return Container(
      padding: const EdgeInsets.all(32),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: context.error,
            ),
            const SizedBox(height: 16),
            Text(
              'Failed to load Monaco Editor',
              style: context.titleLarge?.copyWith(
                color: context.error,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _error ?? 'Unknown error',
              textAlign: TextAlign.center,
              style: context.bodyMedium?.copyWith(
                color: context.onSurface.addOpacity(0.6),
              ),
            ),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: () {
                setState(() {
                  _error = null;
                  _isLoading = true;
                });
                _initWebView();
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
