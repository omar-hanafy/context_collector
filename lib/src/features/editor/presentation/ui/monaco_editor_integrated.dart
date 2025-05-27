// lib/src/features/editor/presentation/ui/monaco_editor_integrated.dart
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:context_collector/src/features/editor/assets_manager/notifier.dart';
import 'package:context_collector/src/features/editor/assets_manager/widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// Platform-specific imports
import 'package:webview_flutter/webview_flutter.dart' as wf;
import 'package:webview_windows/webview_windows.dart' as ww;

import '../../../../shared/theme/extensions.dart';
import '../../bridge/monaco_bridge_platform.dart';
import '../../bridge/platform_webview_controller.dart';
import '../../utils/webview_debug_helper.dart';

/// Monaco Editor that integrates with the asset management system
class MonacoEditorIntegrated extends ConsumerStatefulWidget {
  const MonacoEditorIntegrated({
    super.key,
    required this.bridge,
    this.onReady,
    this.height,
    this.showAssetStatus = false,
  });

  final MonacoBridgePlatform bridge;
  final VoidCallback? onReady;
  final double? height;
  final bool showAssetStatus;

  @override
  ConsumerState<MonacoEditorIntegrated> createState() =>
      _MonacoEditorIntegratedState();
}

class _MonacoEditorIntegratedState
    extends ConsumerState<MonacoEditorIntegrated> {
  late PlatformWebViewController _webViewController;
  bool _isWebViewLoading = true;
  String? _webViewError;
  Timer? _initTimer;
  Timer? _readinessCheckTimer;
  bool _bridgeIsMarkedReady = false;
  String _webViewStatus = 'Starting WebView...';
  int _readinessCheckCount = 0;

  @override
  void initState() {
    super.initState();
    debugPrint('[MonacoEditorIntegrated] initState');
    _checkAssetsAndInitialize();
  }

  @override
  void dispose() {
    debugPrint('[MonacoEditorIntegrated] dispose');
    _initTimer?.cancel();
    _readinessCheckTimer?.cancel();
    widget.bridge.detachWebView();
    _webViewController.dispose();
    super.dispose();
  }

  /// Check if assets are ready and initialize WebView accordingly
  Future<void> _checkAssetsAndInitialize() async {
    final assetStatus = ref.read(monacoAssetStatusProvider);

    if (assetStatus.isReady) {
      // Assets are ready, initialize WebView immediately
      await _initWebView();
    } else if (assetStatus.hasError) {
      // Assets failed to load, show error
      setState(() {
        _webViewError = 'Monaco assets failed to load: ${assetStatus.error}';
        _isWebViewLoading = false;
      });
    } else {
      // Assets are still loading, wait for them
      _updateWebViewStatus('Waiting for Monaco assets...');
    }
  }

  /// Initialize WebView with ready assets
  Future<void> _initWebView() async {
    try {
      _updateWebViewStatus('Initializing WebView...');

      // Get the asset path from the asset manager
      final assetPath = ref.read(monacoAssetPathProvider);
      if (assetPath == null) {
        throw Exception('Monaco asset path not available');
      }

      // Setup timeout - give plenty of time for Windows
      _initTimer = Timer(const Duration(seconds: 90), () {
        if (!widget.bridge.isReady && mounted) {
          setState(() {
            _webViewError =
                'Monaco Editor initialization timed out after 90 seconds.\n'
                'Please check the debug console for errors.';
            _isWebViewLoading = false;
          });
        }
      });

      // Create platform-specific controller
      _webViewController = PlatformWebViewFactory.createController();

      if (Platform.isWindows) {
        await _initWindowsWebView(assetPath);
      } else {
        await _initFlutterWebView(assetPath);
      }

      // Attach to bridge
      _updateWebViewStatus('Connecting to Monaco bridge...');
      widget.bridge.attachWebView(_webViewController);

      debugPrint('[MonacoEditorIntegrated] WebView initialization completed');
    } catch (e) {
      debugPrint('[MonacoEditorIntegrated] WebView initialization error: $e');
      if (mounted) {
        setState(() {
          _webViewError = 'Failed to initialize Monaco WebView: $e';
          _isWebViewLoading = false;
        });
      }
    }
  }

  Future<void> _initWindowsWebView(String assetPath) async {
    final controller = _webViewController as WindowsWebViewController;

    _updateWebViewStatus('Setting up Windows WebView2...');
    await controller.initialize();

    // Add a script that will be executed on every page load
    _updateWebViewStatus('Injecting communication scripts...');
    await controller.windowsController.addScriptToExecuteOnDocumentCreated('''
      // Create flutterChannel immediately when document is created
      console.log('[Windows Init] Creating flutterChannel on document creation');
      window.flutterChannel = {
        postMessage: function(msg) {
          console.log('[flutterChannel] Posting message:', msg);
          if (window.chrome && window.chrome.webview) {
            window.chrome.webview.postMessage(msg);
          } else {
            console.error('[flutterChannel] WebView2 API not available!');
          }
        }
      };
      console.log('[Windows Init] flutterChannel created successfully');
    ''');

    _updateWebViewStatus('Setting up communication channel...');
    await controller.addJavaScriptChannel('flutterChannel', _handleMessage);

    _updateWebViewStatus('Loading Monaco Editor...');
    await _loadMonacoForWindows(controller, assetPath);
  }

  Future<void> _initFlutterWebView(String assetPath) async {
    final controller = _webViewController as FlutterWebViewController;

    _updateWebViewStatus('Configuring WebView...');
    await controller.setJavaScriptMode();

    if (!Platform.isMacOS) {
      await controller.setBackgroundColor(Colors.transparent);
    }

    _updateWebViewStatus('Setting up communication...');
    await controller.addJavaScriptChannel('flutterChannel', _handleMessage);

    _updateWebViewStatus('Setting up navigation...');
    controller.setNavigationDelegate(
      wf.NavigationDelegate(
        onProgress: _onLoadProgress,
        onPageFinished: (_) => _onPageLoaded(),
        onWebResourceError: _onLoadError,
        onNavigationRequest: (wf.NavigationRequest request) {
          if (request.url.startsWith('flutter://')) {
            final payload = Uri.decodeFull(request.url.substring(10));
            _handleUrlMessage(payload);
            return wf.NavigationDecision.prevent;
          }
          return wf.NavigationDecision.navigate;
        },
      ),
    );

    _updateWebViewStatus('Loading Monaco Editor...');
    await _loadMonacoForFlutter(controller, assetPath);
  }

  void _onLoadProgress(int progress) {
    _updateWebViewStatus('Loading Monaco... ($progress%)');

    if (progress == 100 && !Platform.isWindows) {
      _injectReadinessDetection();
    }
  }

  // Test method for Windows debugging
  Future<void> _loadTestHtmlForWindows(
      WindowsWebViewController controller) async {
    debugPrint('[MonacoEditorIntegrated] Loading test HTML for Windows...');

    const testHtml = '''
<!DOCTYPE html>
<html>
<head>
    <title>Windows Test</title>
    <style>
        body { background: #1e1e1e; color: white; padding: 20px; font-family: sans-serif; }
    </style>
</head>
<body>
    <h1>WebView2 Test</h1>
    <div id="status">Checking communication...</div>
    
    <script>
        const status = document.getElementById('status');
        
        // Test flutterChannel
        if (window.flutterChannel) {
            status.innerHTML += '<br>✓ flutterChannel exists';
            
            // Send test message
            window.flutterChannel.postMessage(JSON.stringify({
                event: 'test',
                message: 'Hello from test page'
            }));
            
            // Send ready event after delay
            setTimeout(() => {
                window.flutterChannel.postMessage(JSON.stringify({
                    event: 'onEditorReady',
                    detail: 'Test page ready'
                }));
                status.innerHTML += '<br>✓ Ready event sent';
            }, 1000);
        } else {
            status.innerHTML += '<br>✗ flutterChannel NOT found';
        }
        
        // Test WebView2 API
        if (window.chrome && window.chrome.webview) {
            status.innerHTML += '<br>✓ WebView2 API available';
        } else {
            status.innerHTML += '<br>✗ WebView2 API NOT found';
        }
    </script>
</body>
</html>
''';

    await controller.loadHtmlString(testHtml);
  }

  Future<void> _loadMonacoForWindows(
      WindowsWebViewController controller, String assetPath) async {
    // Uncomment to test with simple HTML first
    // await _loadTestHtmlForWindows(controller);
    // return;

    try {
      debugPrint('[MonacoEditorIntegrated] Loading Monaco for Windows...');
      debugPrint('  Asset path: $assetPath');

      // Verify the VS directory exists
      final vsDir = Directory('$assetPath/monaco-editor/min/vs');
      if (!vsDir.existsSync()) {
        throw Exception('VS directory not found at: ${vsDir.path}');
      }

      // Load the index.html template from assets
      const asset = 'assets/monaco/index.html';
      String htmlContent = await rootBundle.loadString(asset);

      // For Windows, we need to handle paths carefully
      // Use absolute file paths without file:/// to avoid CORS issues
      final normalizedPath = assetPath.replaceAll(r'\', '/');

      // Replace the VS_PATH placeholder with the actual path
      // For Windows, we'll use a different approach in the HTML
      htmlContent = htmlContent.replaceAll(
          '__VS_PATH__', '$normalizedPath/monaco-editor/min/vs');

      // Load the modified HTML
      await controller.loadHtmlString(htmlContent);

      // Start checking for readiness after the page loads
      _readinessCheckTimer = Timer.periodic(const Duration(seconds: 1), (_) {
        _checkWindowsEditorReadiness();
      });
    } catch (e) {
      debugPrint('[MonacoEditorIntegrated] Windows loading error: $e');
      throw Exception('Failed to load Monaco HTML for Windows: $e');
    }
  }

  Future<void> _checkWindowsEditorReadiness() async {
    if (!mounted || _bridgeIsMarkedReady) {
      _readinessCheckTimer?.cancel();
      return;
    }

    _readinessCheckCount++;
    debugPrint(
        '[MonacoEditorIntegrated] Checking Windows readiness (attempt $_readinessCheckCount)...');

    try {
      // First check if the page is loaded and flutterChannel exists
      await _webViewController.runJavaScript('''
        (function() {
          console.log('[Ready Check] Checking environment...');
          const status = {
            hasRequire: typeof require !== 'undefined',
            hasMonaco: typeof monaco !== 'undefined',
            hasEditor: typeof window.editor !== 'undefined',
            hasFlutterChannel: typeof window.flutterChannel !== 'undefined',
            documentReady: document.readyState === 'complete',
            monacoStatus: window.monacoStatus || {}
          };
          console.log('[Ready Check] Status:', JSON.stringify(status, null, 2));
          
          // If editor exists but we haven't sent ready event, force it
          if (status.hasEditor && status.hasFlutterChannel && window.editor) {
            console.log('[Ready Check] Editor found! Forcing ready event...');
            
            // Make sure all API functions are available
            if (!window.setEditorContent) {
              window.setEditorContent = function(content) {
                if (window.editor) window.editor.setValue(content || '');
              };
            }
            if (!window.getEditorContent) {
              window.getEditorContent = function() {
                return window.editor ? window.editor.getValue() : '';
              };
            }
            if (!window.setEditorLanguage) {
              window.setEditorLanguage = function(language) {
                if (window.editor && window.editor.getModel()) {
                  monaco.editor.setModelLanguage(window.editor.getModel(), language);
                }
              };
            }
            if (!window.setEditorTheme) {
              window.setEditorTheme = function(theme) {
                if (monaco) monaco.editor.setTheme(theme);
              };
            }
            if (!window.setEditorOptions) {
              window.setEditorOptions = function(options) {
                if (window.editor) window.editor.updateOptions(options);
              };
            }
            
            // Send ready event
            window.flutterChannel.postMessage(JSON.stringify({
              event: 'onEditorReady',
              payload: {
                detail: 'Windows editor ready (forced)',
                checkCount: $_readinessCheckCount
              }
            }));
            
            // Stop checking after sending ready
            return true;
          } else if (!status.hasRequire && status.documentReady) {
            console.error('[Ready Check] CRITICAL: require is not defined after document ready!');
            window.flutterChannel.postMessage(JSON.stringify({
              event: 'error',
              message: 'require is not defined - Monaco loader failed'
            }));
            return true; // Stop checking
          }
          
          return false; // Continue checking
        })();
      ''').then((Object? result) {
        if (result.asBool) {
          _readinessCheckTimer?.cancel();
        }
      });
    } catch (e) {
      debugPrint('[MonacoEditorIntegrated] Ready check error: $e');
    }

    // Stop checking after 30 attempts (30 seconds) - reduced from 60
    if (_readinessCheckCount >= 30) {
      _readinessCheckTimer?.cancel();
      if (!_bridgeIsMarkedReady && mounted) {
        setState(() {
          _webViewError =
              'Monaco Editor failed to initialize after 30 seconds.\n'
              'The editor may not have loaded properly.';
          _isWebViewLoading = false;
        });
      }
    }
  }

  Future<void> _loadMonacoForFlutter(
      FlutterWebViewController controller, String assetPath) async {
    try {
      // Load the HTML template
      const asset = 'assets/monaco/index.html';
      final htmlContent = await rootBundle.loadString(asset);

      // Replace the VS path with our prepared asset path
      final vsPath = '$assetPath/monaco-editor/min/vs';
      final modifiedHtml = htmlContent.replaceAll('__VS_PATH__', vsPath);

      // Write to a temporary file and load it
      final tempFile = File('$assetPath/index.html');
      await tempFile.writeAsString(modifiedHtml);

      await controller.loadFile(tempFile.path);
    } catch (e) {
      throw Exception('Failed to load Monaco HTML: $e');
    }
  }

  Future<void> _injectReadinessDetection() async {
    // For non-Windows platforms
    await _webViewController.runJavaScript('''
      // Listen for console logs that indicate editor is ready
      const originalLog = console.log;
      console.log = function(...args) {
        originalLog.apply(console, args);
        const message = args.join(' ');
        
        // Check for various ready indicators
        if (message.includes('Monaco editor instance created') ||
            message.includes('ENHANCED_EDITOR_READY_EVENT_FIRED') ||
            message.includes('onEditorReady')) {
          if (window.flutterChannel) {
            window.flutterChannel.postMessage(JSON.stringify({
              event: 'onEditorReady',
              detail: 'Editor ready detected from console'
            }));
          }
        }
      };

      // Also check periodically
      setTimeout(function checkReady() {
        if (window.editor && window.flutterChannel) {
          window.flutterChannel.postMessage(JSON.stringify({
            event: 'onEditorReady',
            detail: 'Editor ready via periodic check'
          }));
        } else {
          setTimeout(checkReady, 1000);
        }
      }, 1000);
    ''');
  }

  void _handleMessage(String message) {
    debugPrint(
        '[MonacoEditorIntegrated] Received message: ${message.substring(0, message.length.clamp(0, 200))}...');

    if (message.startsWith('log:')) {
      return; // Skip log messages
    }

    try {
      final decoded = json.decode(message) as Map<String, dynamic>;

      if (decoded['event'] == 'onEditorReady') {
        if (!_bridgeIsMarkedReady) {
          _readinessCheckTimer?.cancel();

          // Extract detail from various possible locations
          final detail = decoded['detail'] ??
              decoded['payload']?['detail'] ??
              'Editor ready';

          debugPrint('[MonacoEditorIntegrated] ✅ Editor ready: $detail');

          widget.bridge.markReady();
          _bridgeIsMarkedReady = true;
          widget.onReady?.call();

          if (mounted) {
            setState(() {
              _isWebViewLoading = false;
              _webViewError = null;
            });
          }
          _initTimer?.cancel();
        }
      } else if (decoded['event'] == 'error') {
        final errorMessage = decoded['message'] ??
            decoded['payload']?['message'] ??
            'Unknown error';
        debugPrint('[MonacoEditorIntegrated] ❌ Editor error: $errorMessage');

        if (mounted && !_bridgeIsMarkedReady) {
          setState(() {
            _webViewError = 'Monaco Error: $errorMessage';
            _isWebViewLoading = false;
          });
        }
        _initTimer?.cancel();
      } else if (decoded['event'] == 'channelTest') {
        debugPrint(
            '[MonacoEditorIntegrated] Channel test received: ${decoded['message']}');
      } else if (decoded['event'] == 'stats') {
        // Forward stats to bridge
        widget.bridge.handleJavaScriptMessage(message);
      }

      // Forward all messages to bridge
      widget.bridge.handleJavaScriptMessage(message);
    } catch (e) {
      debugPrint('[MonacoEditorIntegrated] Error parsing message: $e');
      // Still forward to bridge even if we can't parse it
      widget.bridge.handleJavaScriptMessage(message);
    }
  }

  void _handleUrlMessage(String payload) {
    debugPrint('[MonacoEditorIntegrated] URL message: $payload');

    // Handle flutter:// URL scheme messages
    try {
      if (payload == 'onEditorReady') {
        _handleMessage(json.encode(
            {'event': 'onEditorReady', 'detail': 'Ready via URL scheme'}));
      }
    } catch (e) {
      debugPrint('[MonacoEditorIntegrated] Error handling URL message: $e');
    }
  }

  void _onPageLoaded() {
    debugPrint('[MonacoEditorIntegrated] Page loaded');
    _updateWebViewStatus('Monaco page loaded, waiting for initialization...');
  }

  void _onLoadError(wf.WebResourceError error) {
    debugPrint(
        '[MonacoEditorIntegrated] WebResourceError: ${error.description}');
    _initTimer?.cancel();
    _readinessCheckTimer?.cancel();

    if (mounted) {
      setState(() {
        _webViewError = 'Failed to load Monaco: ${error.description}';
        _isWebViewLoading = false;
      });
    }
  }

  void _updateWebViewStatus(String status) {
    if (mounted) {
      setState(() {
        _webViewStatus = status;
      });
    }
    debugPrint('[MonacoEditorIntegrated] Status: $status');
  }

  @override
  Widget build(BuildContext context) {
    final assetStatus = ref.watch(monacoAssetStatusProvider);

    // Listen for asset status changes
    ref.listen<MonacoAssetStatus>(monacoAssetStatusProvider, (previous, next) {
      if (previous?.state != next.state) {
        if (next.isReady && _isWebViewLoading && _webViewError == null) {
          // Assets just became ready, initialize WebView
          _initWebView();
        } else if (next.hasError) {
          // Assets failed
          setState(() {
            _webViewError = 'Monaco assets error: ${next.error}';
            _isWebViewLoading = false;
          });
        }
      }
    });

    return SizedBox(
      height: widget.height ?? double.infinity,
      child: Column(
        children: [
          // Asset status indicator (optional)
          if (widget.showAssetStatus) ...[
            Container(
              padding: const EdgeInsetsDirectional.symmetric(
                  horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  const MonacoAssetLoadingIndicator(size: 16),
                  const SizedBox(width: 8),
                  Text(
                    assetStatus.isReady
                        ? 'Assets Ready'
                        : 'Preparing Assets...',
                    style: context.bodySmall?.copyWith(
                      color: context.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
          ],

          // Main editor area
          Expanded(
            child: _buildEditorContent(assetStatus),
          ),
        ],
      ),
    );
  }

  Widget _buildEditorContent(MonacoAssetStatus assetStatus) {
    // Show asset loading if assets aren't ready yet
    if (!assetStatus.isReady && !assetStatus.hasError) {
      return const Center(
        child: MonacoAssetLoadingWidget(compact: true),
      );
    }

    // Show error if there's a WebView error
    if (_webViewError != null) {
      return _buildErrorView();
    }

    // Show the WebView with loading overlay if needed
    return Stack(
      children: [
        _buildWebView(),
        if (_isWebViewLoading) _buildWebViewLoadingOverlay(),
      ],
    );
  }

  Widget _buildWebView() {
    if (Platform.isWindows) {
      final controller = _webViewController as WindowsWebViewController;
      return ww.Webview(controller.windowsController);
    } else {
      final controller = _webViewController as FlutterWebViewController;
      return wf.WebViewWidget(controller: controller.flutterController);
    }
  }

  Widget _buildWebViewLoadingOverlay() {
    return ColoredBox(
      color: context.isDark ? const Color(0xFF1E1E1E) : Colors.white,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(
              'Starting Monaco Editor...',
              style: context.bodyMedium?.copyWith(
                color: context.onSurface.addOpacity(0.8),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _webViewStatus,
              style: context.bodySmall?.copyWith(
                color: context.onSurface.addOpacity(0.6),
              ),
            ),
            if (Platform.isWindows && _readinessCheckCount > 5) ...[
              const SizedBox(height: 8),
              Text(
                'Check attempt: $_readinessCheckCount',
                style: context.bodySmall?.copyWith(
                  color: context.onSurface.addOpacity(0.4),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildErrorView() {
    return Container(
      padding: const EdgeInsetsDirectional.all(32),
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
              'Monaco Editor Error',
              style: context.titleLarge?.copyWith(
                color: context.error,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsetsDirectional.all(16),
              decoration: BoxDecoration(
                color: context.errorContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _webViewError ?? 'Unknown error',
                textAlign: TextAlign.center,
                style: context.bodyMedium?.copyWith(
                  color: context.onErrorContainer,
                ),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                OutlinedButton.icon(
                  onPressed: () {
                    setState(() {
                      _webViewError = null;
                      _isWebViewLoading = true;
                      _bridgeIsMarkedReady = false;
                      _webViewStatus = 'Retrying...';
                      _readinessCheckCount = 0;
                    });
                    _checkAssetsAndInitialize();
                  },
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry'),
                ),
                const SizedBox(width: 16),
                Consumer(
                  builder: (context, ref, child) {
                    return TextButton.icon(
                      onPressed: () => ref
                          .read(monacoAssetManagerProvider)
                          .retryInitialization(),
                      icon: const Icon(Icons.refresh),
                      label: const Text('Reload Assets'),
                    );
                  },
                ),
                if (Platform.isWindows) ...[
                  const SizedBox(width: 16),
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.bug_report),
                    tooltip: 'Debug Options',
                    onSelected: (value) async {
                      switch (value) {
                        case 'test_basic':
                          await WebViewDebugHelper.testWebView2Basic();
                        case 'test_monaco':
                          final assetPath = ref.read(monacoAssetPathProvider);
                          if (assetPath != null) {
                            await WebViewDebugHelper.testMonacoLoading(
                                assetPath);
                          }
                        case 'test_file':
                          final assetPath = ref.read(monacoAssetPathProvider);
                          if (assetPath != null) {
                            await WebViewDebugHelper.testFileUrlAccess(
                                assetPath);
                          }
                        case 'open_devtools':
                          try {
                            if (_webViewController
                                is WindowsWebViewController) {
                              final winController = _webViewController
                                  as WindowsWebViewController;
                              await winController.windowsController
                                  .openDevTools();
                            }
                          } catch (e) {
                            debugPrint('Error opening DevTools: $e');
                          }
                        case 'reload_test':
                          if (_webViewController is WindowsWebViewController) {
                            setState(() {
                              _isWebViewLoading = true;
                              _webViewError = null;
                            });
                            await _loadTestHtmlForWindows(
                                _webViewController as WindowsWebViewController);
                          }
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'test_basic',
                        child: Text('Test Basic WebView2'),
                      ),
                      const PopupMenuItem(
                        value: 'test_monaco',
                        child: Text('Test Monaco Loading'),
                      ),
                      const PopupMenuItem(
                        value: 'test_file',
                        child: Text('Test File URL Access'),
                      ),
                      const PopupMenuDivider(),
                      const PopupMenuItem(
                        value: 'open_devtools',
                        child: Text('Open DevTools'),
                      ),
                      const PopupMenuDivider(),
                      const PopupMenuItem(
                        value: 'reload_test',
                        child: Text('Load Test HTML'),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
