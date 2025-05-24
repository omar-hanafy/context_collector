import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Required for rootBundle
import 'package:path/path.dart' as p; // Required for path joining
import 'package:webview_flutter/webview_flutter.dart';

import '../extensions/theme_extensions.dart';

class MonacoEditorEmbedded extends StatefulWidget {
  const MonacoEditorEmbedded({
    super.key,
    required this.content,
    this.onCopy,
    this.onScrollToTop,
    this.showLineNumbers = true,
    this.fontSize = 13,
    this.wordWrap = false,
    this.readOnly = false,
    this.showControls = true,
  });

  final String content;
  final VoidCallback? onCopy;
  final VoidCallback? onScrollToTop;
  final bool showLineNumbers;
  final double fontSize;
  final bool wordWrap;
  final bool readOnly;
  final bool showControls;

  @override
  State<MonacoEditorEmbedded> createState() => _MonacoEditorEmbeddedState();
}

class _MonacoEditorEmbeddedState extends State<MonacoEditorEmbedded> {
  late WebViewController _controller;
  bool _isReady = false;
  bool _isLoading = true;
  String? _error;
  bool _readOnly = false; // Track read-only state internally

  // Metrics
  int _totalLines = 0;
  int _totalCharacters = 0;

  // Editor settings
  String _currentTheme = 'vs-dark';
  String _currentLanguage = 'javascript';

  // Available languages and themes
  final List<Map<String, String>> _languages = [
    {'value': 'plaintext', 'text': 'Plain Text'},
    {'value': 'javascript', 'text': 'JavaScript'},
    {'value': 'typescript', 'text': 'TypeScript'},
    {'value': 'html', 'text': 'HTML'},
    {'value': 'css', 'text': 'CSS'},
    {'value': 'json', 'text': 'JSON'},
    {'value': 'markdown', 'text': 'Markdown'},
    {'value': 'dart', 'text': 'Dart'},
    {'value': 'python', 'text': 'Python'},
    {'value': 'java', 'text': 'Java'},
    {'value': 'csharp', 'text': 'C#'},
    {'value': 'cpp', 'text': 'C++'},
    {'value': 'go', 'text': 'Go'},
    {'value': 'ruby', 'text': 'Ruby'},
    {'value': 'swift', 'text': 'Swift'},
    {'value': 'php', 'text': 'PHP'},
    {'value': 'sql', 'text': 'SQL'},
    {'value': 'yaml', 'text': 'YAML'},
    {'value': 'shell', 'text': 'Shell'},
  ];

  final List<Map<String, String>> _themes = [
    {'value': 'vs', 'text': 'Visual Studio'},
    {'value': 'vs-dark', 'text': 'Visual Studio Dark'},
    {'value': 'hc-black', 'text': 'High Contrast Dark'},
  ];

  @override
  void initState() {
    super.initState();
    _readOnly = widget.readOnly;
    _updateMetrics();
    _initWebView();
  }

  @override
  void didUpdateWidget(MonacoEditorEmbedded oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.content != widget.content) {
      _updateContent();
      _updateMetrics();
    }

    if (oldWidget.readOnly != widget.readOnly) {
      _readOnly = widget.readOnly;
      _updateOptions();
    }

    if (oldWidget.fontSize != widget.fontSize ||
        oldWidget.showLineNumbers != widget.showLineNumbers ||
        oldWidget.wordWrap != widget.wordWrap) {
      _updateOptions();
    }
  }

  void _updateMetrics() {
    setState(() {
      _totalLines = widget.content.split('\n').length;
      _totalCharacters = widget.content.length;
    });
  }

  Future<void> _initWebView() async {
    try {
      print('Monaco: Initializing WebView');
      // Initialize WebViewController
      _controller = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted);

      // Don't set transparent background on macOS to avoid 'opaque is not implemented' error
      if (!Platform.isMacOS) {
        _controller.setBackgroundColor(Colors.transparent);
      }

      print('Monaco: Adding JavaScript channels');
      // Add JavaScript channels for communication
      _controller.addJavaScriptChannel(
        'flutterChannel',
        onMessageReceived: (JavaScriptMessage message) {
          print(
              'Monaco: Received message via flutterChannel: ${message.message}');
          try {
            if (message.message.startsWith('log:')) {
              print('Monaco JS Log: ${message.message.substring(4)}');
              return;
            }

            final data = jsonDecode(message.message);
            final event = data['event'] as String?;

            if (event == 'onEditorReady') {
              print('Monaco: onEditorReady event received via JS channel!');
              _onEditorReady();
            }
          } catch (e) {
            print('Monaco: Error parsing message: $e');
          }
        },
      );

      print('Monaco: Setting navigation delegate');
      // Set navigation delegate
      _controller.setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (url) {
            print('Monaco: Page started loading: $url');
          },
          onProgress: (int progress) {
            print('Monaco: Loading progress: $progress');
            if (progress == 100) {
              print('Monaco: Page loaded 100%');

              // Inject JS bridge code
              _controller.runJavaScript('''
                console.log("Monaco: Injecting console log interceptor");
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
                    console.originalLog("Monaco: Detected editor creation success, sending ready event");
                    if (window.flutterChannel) {
                      window.flutterChannel.postMessage(JSON.stringify({event: 'onEditorReady'}));
                    }
                  }
                };
                console.log("Monaco: Console log interceptor injected");
                
                // Force immediate execution to check for editor
                setTimeout(function() {
                  if (window.editor) {
                    console.log("Monaco: Editor already exists, sending ready event");
                    if (window.flutterChannel) {
                      window.flutterChannel.postMessage(JSON.stringify({event: 'onEditorReady'}));
                    }
                  } else {
                    console.log("Monaco: Editor not yet initialized");
                  }
                }, 1000);
              ''');
            }
          },
          onPageFinished: (String url) {
            print('Monaco: Page finished loading: $url');
            // Set loading to false after the page is fully loaded
            setState(() {
              _isLoading = false;
              print('Monaco: _isLoading set to false in onPageFinished');
            });
          },
          onWebResourceError: (WebResourceError error) {
            print(
                'Monaco: Web resource error: ${error.description} (${error.errorCode}) - URL: ${error.url}');
            setState(() {
              _error =
                  'Failed to load editor: ${error.description} (URL: ${error.url})';
              _isLoading = false;
              print(
                  'Monaco: Set _error and _isLoading=false due to web resource error');
            });
          },
          onNavigationRequest: (NavigationRequest request) {
            print('Monaco: Navigation request: ${request.url}');
            if (request.url.startsWith('flutter://log:')) {
              final log = Uri.decodeFull(request.url.substring(13));
              print('Monaco Log: $log');
              return NavigationDecision.prevent;
            } else if (request.url.startsWith('flutter://')) {
              final payload = Uri.decodeFull(request.url.substring(10));
              print('Monaco: Received flutter:// URL message: $payload');
              _handleUrlMessage(payload);
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
        ),
      );

      // Load the HTML content
      print('Monaco: Starting to load HTML content');
      await _loadHtml();
    } catch (e, stackTrace) {
      print('Monaco: Error initializing WebView: $e');
      print('Monaco: Stack trace: $stackTrace');
      setState(() {
        _error = 'Failed to initialize editor: $e';
        _isLoading = false;
        print(
            'Monaco: Set _error and _isLoading=false due to initialization error');
      });
    }
  }

  void _handleUrlMessage(String payload) {
    print('Monaco: _handleUrlMessage called with payload: $payload');
    if (payload.startsWith('onEditorReady')) {
      print('Monaco: onEditorReady message received via URL message');
      _onEditorReady();
    }
  }

  Future<void> _loadHtml() async {
    const asset = 'assets/monaco/index.html';

    try {
      print('Monaco: Starting to load HTML content');

      if (Platform.isAndroid || Platform.isIOS) {
        print('Monaco: Loading for mobile platform using loadFlutterAsset');
        await _controller.loadFlutterAsset(asset);
        return;
      }

      print('Monaco: Loading for desktop platform - creating temp directory');
      // For desktop: Copy to temp dir, replace VS_PATH, then load via loadFile
      final tempDir = await Directory.systemTemp.createTemp('monaco_editor');
      print('Monaco: Temp directory created at ${tempDir.path}');

      final vsPath = Uri.file(p.join(tempDir.path, 'vs')).toString();
      print('Monaco: VS_PATH will be set to $vsPath');

      // Copy the vs directory to the temp dir (needed for offline operation)
      print('Monaco: Starting asset copying to temp directory');
      await _copyAssetDirectory('assets/monaco/vs', p.join(tempDir.path, 'vs'));

      print('Monaco: Loading HTML content from assets');
      // Load and modify the HTML content to include the absolute vs path
      final htmlContent = await rootBundle.loadString(asset);
      print('Monaco: HTML content loaded, length: ${htmlContent.length}');

      final modifiedHtml = htmlContent.replaceAll('__VS_PATH__', vsPath);
      print('Monaco: HTML content modified with VS_PATH');

      // Write the modified HTML to a temp file
      final htmlFile = File(p.join(tempDir.path, 'index.html'));
      await htmlFile.writeAsString(modifiedHtml);
      print('Monaco: HTML written to ${htmlFile.path}');

      // Explicitly force loading to be false at end of function
      Future.delayed(const Duration(seconds: 5), () {
        if (mounted) {
          setState(() {
            _isLoading = false;
            print('Monaco: FORCE setting _isLoading to false after 5 seconds');
          });
        }
      });

      // Load the temp HTML file
      print('Monaco: Loading HTML file into WebView');
      await _controller.loadFile(htmlFile.path);
      print('Monaco: HTML file loaded into WebView');
    } catch (e, stackTrace) {
      print('Monaco: Error loading editor HTML: $e');
      print('Monaco: Stack trace: $stackTrace');
      setState(() {
        _error = 'Failed to load editor HTML: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _copyAssetDirectory(String assetDir, String targetDir) async {
    try {
      // Create target directory if it doesn't exist
      final targetDirFile = Directory(targetDir);
      if (!await targetDirFile.exists()) {
        await targetDirFile.create(recursive: true);
      }

      // Create editor directory
      final editorDir = Directory(p.join(targetDir, 'editor'));
      if (!await editorDir.exists()) {
        await editorDir.create(recursive: true);
      }

      // We know we have two possible paths:
      // 1. assets/monaco/vs/editor/editor.main.js
      // 2. assets/monaco/monaco-editor/min/vs/editor/editor.main.js

      final List<String> pathsToTry = [
        // First try the direct path
        'assets/monaco/vs/loader.js',
        'assets/monaco/vs/editor/editor.main.js',
        'assets/monaco/vs/editor/editor.main.css',

        // Then try the min path
        'assets/monaco/monaco-editor/min/vs/loader.js',
        'assets/monaco/monaco-editor/min/vs/editor/editor.main.js',
        'assets/monaco/monaco-editor/min/vs/editor/editor.main.css',
      ];

      // Try loading from various paths
      bool loaderJsFound = false;
      bool editorMainJsFound = false;
      bool editorMainCssFound = false;

      for (final path in pathsToTry) {
        try {
          if (path.endsWith('/loader.js') && !loaderJsFound) {
            final bytes = await rootBundle.load(path);
            await File(p.join(targetDir, 'loader.js'))
                .writeAsBytes(bytes.buffer.asUint8List());
            loaderJsFound = true;
            print('Successfully copied loader.js from $path');
          } else if (path.endsWith('/editor.main.js') && !editorMainJsFound) {
            final bytes = await rootBundle.load(path);
            await File(p.join(targetDir, 'editor', 'editor.main.js'))
                .writeAsBytes(bytes.buffer.asUint8List());
            editorMainJsFound = true;
            print('Successfully copied editor.main.js from $path');
          } else if (path.endsWith('/editor.main.css') && !editorMainCssFound) {
            final bytes = await rootBundle.load(path);
            await File(p.join(targetDir, 'editor', 'editor.main.css'))
                .writeAsBytes(bytes.buffer.asUint8List());
            editorMainCssFound = true;
            print('Successfully copied editor.main.css from $path');
          }
        } catch (e) {
          print('Failed to load from $path: $e');
        }
      }

      // Basic error reporting
      if (!loaderJsFound)
        print('CRITICAL ERROR: Failed to find loader.js in any location');
      if (!editorMainJsFound)
        print('CRITICAL ERROR: Failed to find editor.main.js in any location');
      if (!editorMainCssFound)
        print('CRITICAL ERROR: Failed to find editor.main.css in any location');
    } catch (e) {
      print('Error preparing Monaco assets directory: $e');
    }
  }

  void _onEditorReady() {
    print('Monaco: _onEditorReady called - editor is ready!');
    if (mounted) {
      print('Monaco: Component is mounted, updating state...');
      setState(() {
        _isReady = true;
        _isLoading = false;
        print(
            'Monaco: State updated - _isReady=$_isReady, _isLoading=$_isLoading');
      });
      _updateContent();
      _updateOptions();
      _detectLanguage();
      print('Monaco: Content and options updated');
    } else {
      print('Monaco: ERROR - Component not mounted in _onEditorReady');
    }
  }

  void _updateContent() {
    if (!_isReady) return;
    final escapedContent = jsonEncode(widget.content);
    _controller.runJavaScript('window.setEditorContent($escapedContent);');
  }

  void _updateOptions() {
    if (!_isReady) return;
    final options = {
      'fontSize': widget.fontSize,
      'lineNumbers': widget.showLineNumbers ? 'on' : 'off',
      'wordWrap': widget.wordWrap ? 'on' : 'off',
      'readOnly': _readOnly,
      'theme': _currentTheme,
    };
    final optionsJson = jsonEncode(options);
    print('Monaco: Updating options: $optionsJson');
    _controller.runJavaScript('window.setEditorOptions($optionsJson);');
  }

  void _updateLanguage(String language) {
    if (!_isReady) return;
    setState(() {
      _currentLanguage = language;
    });
    _controller.runJavaScript('window.setEditorLanguage("$language");');
  }

  void _updateTheme(String theme) {
    if (!_isReady) return;
    setState(() {
      _currentTheme = theme;
    });
    _controller.runJavaScript('window.setEditorTheme("$theme");');
  }

  void _detectLanguage() {
    if (!_isReady) return;

    // Try to detect language from content
    String detectedLanguage = 'plaintext';

    final content = widget.content.toLowerCase();

    if (content.contains('<!doctype html>') || content.contains('<html')) {
      detectedLanguage = 'html';
    } else if (content.contains("import 'package:flutter") ||
        content.contains('extends stateless') ||
        content.contains('extends state<')) {
      detectedLanguage = 'dart';
    } else if (content.contains('function') ||
        content.contains('const ') ||
        content.contains('let ')) {
      detectedLanguage = 'javascript';
    } else if (content.contains('import react') ||
        content.contains("from 'react'")) {
      detectedLanguage = 'javascript';
    } else if (content.contains('def ') ||
        content.contains('import ') && content.contains('from ')) {
      detectedLanguage = 'python';
    } else if (content.startsWith('{') && content.endsWith('}')) {
      try {
        jsonDecode(content);
        detectedLanguage = 'json';
      } catch (_) {}
    }

    setState(() {
      _currentLanguage = detectedLanguage;
    });

    _controller.runJavaScript('window.setEditorLanguage("$detectedLanguage");');
  }

  void _toggleReadOnly() {
    setState(() {
      _readOnly = !_readOnly;
    });
    _updateOptions();
  }

  @override
  Widget build(BuildContext context) {
    print(
        'Monaco: build called - _error=$_error, _isLoading=$_isLoading, _isReady=$_isReady');

    if (_error != null) {
      print('Monaco: Rendering error view: $_error');
      return _buildErrorView(context);
    }

    return Column(
      children: [
        // Main content area
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: context.isDark
                  ? Colors.black.addOpacity(0.3)
                  : Colors.grey.shade50,
              border: Border.all(
                color: context.onSurface.addOpacity(0.1),
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Stack(
                children: [
                  WebViewWidget(controller: _controller),
                  if (_isLoading)
                    ColoredBox(
                      color: context.surface,
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const CircularProgressIndicator(),
                            const SizedBox(height: 16),
                            Text(
                              'Loading Monaco Editor...',
                              style: context.bodyMedium,
                            ),
                          ],
                        ),
                      ),
                    ),
                  if (widget.showControls && _isReady)
                    Positioned(
                      bottom: 10,
                      right: 10,
                      child: Container(
                        padding: const EdgeInsetsDirectional.all(8),
                        decoration: BoxDecoration(
                          color: context.isDark
                              ? Colors.black.addOpacity(0.7)
                              : Colors.white.addOpacity(0.8),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: context.onSurface.addOpacity(0.1),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Read-only toggle
                            IconButton(
                              onPressed: _toggleReadOnly,
                              icon: Icon(
                                _readOnly
                                    ? Icons.lock_outline
                                    : Icons.edit_outlined,
                                size: 18,
                              ),
                              tooltip: _readOnly
                                  ? 'Enable editing'
                                  : 'Read-only mode',
                              style: IconButton.styleFrom(
                                backgroundColor: _readOnly
                                    ? Colors.red.withOpacity(0.2)
                                    : Colors.green.withOpacity(0.2),
                                padding: const EdgeInsetsDirectional.all(6),
                                minimumSize: const Size(36, 36),
                              ),
                            ),
                            const SizedBox(width: 8),
                            // Theme selector
                            DropdownButton<String>(
                              value: _currentTheme,
                              onChanged: (value) {
                                if (value != null) _updateTheme(value);
                              },
                              style: context.bodySmall,
                              dropdownColor: context.isDark
                                  ? Colors.black.addOpacity(0.9)
                                  : Colors.white,
                              items: _themes.map((theme) {
                                return DropdownMenuItem<String>(
                                  value: theme['value'],
                                  child: Text(theme['text']!),
                                );
                              }).toList(),
                              underline: const SizedBox.shrink(),
                              borderRadius: BorderRadius.circular(8),
                              icon: Icon(
                                Icons.palette_outlined,
                                size: 16,
                                color: context.onSurface.addOpacity(0.7),
                              ),
                            ),
                            const SizedBox(width: 8),
                            // Language selector
                            DropdownButton<String>(
                              value: _currentLanguage,
                              onChanged: (value) {
                                if (value != null) _updateLanguage(value);
                              },
                              style: context.bodySmall,
                              dropdownColor: context.isDark
                                  ? Colors.black.addOpacity(0.9)
                                  : Colors.white,
                              items: _languages.map((language) {
                                return DropdownMenuItem<String>(
                                  value: language['value'],
                                  child: Text(language['text']!),
                                );
                              }).toList(),
                              underline: const SizedBox.shrink(),
                              borderRadius: BorderRadius.circular(8),
                              icon: Icon(
                                Icons.code,
                                size: 16,
                                color: context.onSurface.addOpacity(0.7),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),

        // Info bar
        _buildInfoBar(context),
      ],
    );
  }

  Widget _buildErrorView(BuildContext context) {
    return Center(
      child: Container(
        padding: const EdgeInsetsDirectional.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: context.error,
            ),
            const SizedBox(height: 16),
            Text(
              'Failed to load editor',
              style: context.titleLarge?.copyWith(
                color: context.error,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _error!,
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

  Widget _buildInfoBar(BuildContext context) {
    return Container(
      margin: const EdgeInsetsDirectional.only(top: 8),
      padding: const EdgeInsetsDirectional.symmetric(
        horizontal: 16,
        vertical: 8,
      ),
      decoration: BoxDecoration(
        color: context.isDark
            ? Colors.black.addOpacity(0.3)
            : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: context.onSurface.addOpacity(0.1),
        ),
      ),
      child: Row(
        children: [
          _buildInfoItem(
            context,
            icon: Icons.format_list_numbered,
            label: 'Lines',
            value: _totalLines.toString(),
          ),
          const SizedBox(width: 24),
          _buildInfoItem(
            context,
            icon: Icons.text_fields,
            label: 'Characters',
            value: _formatNumber(_totalCharacters),
          ),
          const Spacer(),
          // Monaco indicator
          Container(
            padding: const EdgeInsetsDirectional.symmetric(
              horizontal: 12,
              vertical: 4,
            ),
            decoration: BoxDecoration(
              color: context.primary.addOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: context.primary.addOpacity(0.3),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.code,
                  size: 14,
                  color: context.primary,
                ),
                const SizedBox(width: 6),
                Text(
                  'Monaco Editor',
                  style: context.labelSmall?.copyWith(
                    color: context.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          // Action buttons
          if (widget.content.isNotEmpty) ...[
            _buildActionButton(
              context,
              icon: Icons.vertical_align_top,
              tooltip: 'Scroll to top',
              onPressed: () {
                _controller.runJavaScript(
                    'window.editor.setScrollPosition({scrollTop: 0, scrollLeft: 0});');
                widget.onScrollToTop?.call();
              },
            ),
            const SizedBox(width: 8),
            _buildActionButton(
              context,
              icon: Icons.copy,
              tooltip: 'Copy to clipboard',
              onPressed: widget.onCopy,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 14,
          color: context.onSurface.addOpacity(0.5),
        ),
        const SizedBox(width: 6),
        Text(
          '$label: ',
          style: context.labelSmall?.copyWith(
            color: context.onSurface.addOpacity(0.5),
          ),
        ),
        Text(
          value,
          style: context.labelSmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: context.onSurface.addOpacity(0.8),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton(
    BuildContext context, {
    required IconData icon,
    required String tooltip,
    VoidCallback? onPressed,
  }) {
    return IconButton(
      onPressed: onPressed,
      icon: Icon(icon),
      iconSize: 18,
      tooltip: tooltip,
      style: IconButton.styleFrom(
        backgroundColor: context.primary.addOpacity(0.1),
        foregroundColor: context.primary,
        padding: const EdgeInsetsDirectional.all(6),
        minimumSize: const Size(32, 32),
      ),
    );
  }

  String _formatNumber(int number) {
    if (number < 1000) return number.toString();
    if (number < 1000000) {
      return '${(number / 1000).toStringAsFixed(1)}K';
    }
    return '${(number / 1000000).toStringAsFixed(1)}M';
  }
}
