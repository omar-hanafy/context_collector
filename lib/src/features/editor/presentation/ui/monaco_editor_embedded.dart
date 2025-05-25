import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../../../shared/theme/extensions.dart';
import '../../bridge/monaco_bridge.dart';

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
  bool _bridgeIsMarkedReady = false;

  @override
  void initState() {
    super.initState();
    debugPrint('[_MonacoEditorEmbeddedState] initState: $hashCode');
    _initWebView();
  }

  @override
  void dispose() {
    debugPrint('[_MonacoEditorEmbeddedState] dispose: $hashCode');
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
              // Inject JS bridge code to forward console.log and signal editor readiness
              _webViewController.runJavaScript('''
                console.originalLog = console.log;
                console.log = function(...args) {
                  console.originalLog.apply(console, args);
                  if (window.flutterChannel) {
                    try {
                      // Forward logs
                      window.flutterChannel.postMessage('log:' + args.join(' '));
                    } catch(e) {
                      console.originalLog('Error sending log to Flutter:', e);
                    }
                  }
                  // Check for a specific message that indicates Monaco is fully up
                  if (args[0] === "Monaco editor instance created successfully" || 
                      (typeof args[0] === 'string' && args[0].includes("Monaco editor core services initialized"))) {
                    if (window.flutterChannel) {
                      // Ensure this event is unique and clearly identifiable
                      window.flutterChannel.postMessage(JSON.stringify({event: 'onEditorReady', detail: 'Editor core ready'}));
                    }
                  }
                };
                
                // Fallback check if the specific log message is missed
                setTimeout(function() {
                  if (window.editor && window.flutterChannel) {
                     // Check if already sent by log, to avoid duplicate onEditorReady.
                     // This part might be tricky; relying on a single, clear log message is often better.
                     // For now, let it send; the Dart side has a guard (_bridgeIsMarkedReady).
                    window.flutterChannel.postMessage(JSON.stringify({event: 'onEditorReady', detail: 'Editor available via window.editor after timeout'}));
                  }
                }, 2000); // Increased timeout for safety
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
    debugPrint(
        '[_MonacoEditorEmbeddedState._handleUrlMessage] Received URL message: $payload');
    // Implement actual handling if this communication path is used
  }

  void _handleMessage(JavaScriptMessage message) {
    final String msg = message.message;
    if (msg.startsWith('log:')) {
      // Optional: Handle JS console.log messages
      // debugPrint('[JS Log] ${msg.substring(4)}');
      return;
    }

    try {
      final decoded = json.decode(msg) as Map<String, dynamic>;
      if (decoded['event'] == 'onEditorReady') {
        if (!_bridgeIsMarkedReady) {
          debugPrint(
              '[_MonacoEditorEmbeddedState._handleMessage] Received onEditorReady (detail: ${decoded['detail']}), _bridgeIsMarkedReady: $_bridgeIsMarkedReady');
          widget.bridge.markReady();
          _bridgeIsMarkedReady = true;
          widget.onReady?.call();
          if (mounted) {
            setState(() {
              _isLoading = false;
              _error = null;
            });
          }
          _initTimer?.cancel();
        } else {
          debugPrint(
              '[_MonacoEditorEmbeddedState._handleMessage] Received onEditorReady, but bridge already marked ready. Detail: ${decoded['detail']}. Ignoring.');
        }
      }
      // Potentially handle other events from JS if defined
      // else if (decoded['event'] == 'someOtherEvent') { ... }

      // Always forward any JSON payload to the bridge so it can
      // handle 'stats' (and anything else you add later).
      widget.bridge.handleJavaScriptMessage(message);
    } catch (e) {
      debugPrint(
          '[_MonacoEditorEmbeddedState._handleMessage] Error decoding/handling message from JS: $e. Raw Message: "$msg"');
      // Still try to forward non-JSON messages to the bridge as they might be handled differently there
      try {
        widget.bridge.handleJavaScriptMessage(message);
      } catch (innerE) {
        // If bridge also fails to handle it, just log and ignore
        debugPrint(
            '[_MonacoEditorEmbeddedState._handleMessage] Bridge also failed to handle message: $innerE');
      }
    }
  }

  void _onPageLoaded() {
    debugPrint(
        '[_MonacoEditorEmbeddedState._onPageLoaded] Page finished loading HTML document.');
    // This method is for when the HTML page itself has loaded.
    // Monaco editor initialization within the page is a separate process,
    // signaled by the 'onEditorReady' event from the JavaScript.
    // Avoid calling widget.onReady or bridge.markReady() here.
  }

  void _onLoadError(WebResourceError error) {
    _initTimer?.cancel();
    if (mounted) {
      setState(() {
        _error = 'Failed to load Monaco Editor: ${error.description}';
        _isLoading = false;
      });
    }
    debugPrint('Monaco Editor WebResourceError: ${error.description}');
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
