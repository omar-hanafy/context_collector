import 'dart:developer';
import 'dart:io';

import 'package:desktop_webview_window/desktop_webview_window.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;

import '../extensions/theme_extensions.dart';

class MonacoEditorWidget extends StatefulWidget {
  const MonacoEditorWidget({
    super.key,
    required this.content,
    this.onCopy,
    this.onScrollToTop,
    this.showLineNumbers = true,
    this.fontSize = 13,
    this.wordWrap = false,
    this.readOnly = true,
  });

  final String content;
  final VoidCallback? onCopy;
  final VoidCallback? onScrollToTop;
  final bool showLineNumbers;
  final double fontSize;
  final bool wordWrap;
  final bool readOnly;

  @override
  State<MonacoEditorWidget> createState() => _MonacoEditorWidgetState();
}

class _MonacoEditorWidgetState extends State<MonacoEditorWidget> {
  Webview? _webview;
  bool _isReady = false;
  bool _isLoading = true;
  String? _error;

  // Metrics
  int _totalLines = 0;
  int _totalCharacters = 0;

  // Store temp directory for cleanup
  Directory? _tempDir;

  @override
  void initState() {
    super.initState();
    _initWebview();
    _updateMetrics();
  }

  @override
  void didUpdateWidget(MonacoEditorWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.content != widget.content) {
      _updateContent();
      _updateMetrics();
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

  Future<void> _initWebview() async {
    try {
      // Check if WebView is available
      if (!await WebviewWindow.isWebviewAvailable()) {
        setState(() {
          _error =
              'WebView is not available. Please install Edge WebView2 Runtime.';
          _isLoading = false;
        });
        return;
      }

      // Create WebView window
      _webview = await WebviewWindow.create(
        configuration: CreateConfiguration(
          userDataFolderWindows: await _getWebViewDataPath(),
          windowHeight: 800,
          windowWidth: 1000,
          title: 'Monaco Editor',
        ),
      );

      // Set up JavaScript handlers
      _webview!.addScriptToExecuteOnDocumentCreated('''
        window.flutter_inappwebview = {
          callHandler: function(handlerName, ...args) {
            window.chrome.webview.postMessage({
              event: handlerName,
              payload: args.length > 0 ? args[0] : undefined
            });
          }
        };
      ''');

      // Listen for messages from JavaScript
      _webview!.addOnWebMessageReceivedCallback((message) {
        try {
          final data = ConvertObject.toMap(message, defaultValue: {});
          final event = data['event']?.toString() ?? '';

          switch (event) {
            case 'onEditorReady':
              _onEditorReady();
            case 'onContentChanged':
              // Since we're in read-only mode, this shouldn't happen
              break;
          }
        } catch (e, s) {
          log('Error processing message from WebView: $e',
              error: e, stackTrace: s);
        }
      });

      // Load the editor HTML
      final htmlPath = await _prepareEditorHtml();
      _webview!.launch(htmlPath);
    } catch (e) {
      setState(() {
        _error = 'Failed to initialize editor: $e';
        _isLoading = false;
      });
    }
  }

  Future<String> _getWebViewDataPath() async {
    final appDir = Directory.current.path;
    final dataPath = p.join(appDir, 'webview_data');
    await Directory(dataPath).create(recursive: true);
    return dataPath;
  }

  Future<String> _prepareEditorHtml() async {
    // Create a temporary directory to hold Monaco files
    _tempDir = await Directory.systemTemp.createTemp('monaco_editor_window');

    // Get VS path which will be an absolute file:// URL
    final vsPath = Uri.file(p.join(_tempDir!.path, 'vs')).toString();

    // Copy required Monaco files to temp directory
    await _copyAssetDirectory(
        'assets/monaco/monaco-editor/min/vs', p.join(_tempDir!.path, 'vs'));

    // Load and modify the HTML content
    final htmlContent = await rootBundle.loadString('assets/monaco/index.html');
    final modifiedHtml = htmlContent.replaceAll('__VS_PATH__', vsPath);

    // Write the modified HTML to temp file
    final htmlFile = File(p.join(_tempDir!.path, 'index.html'));
    await htmlFile.writeAsString(modifiedHtml);

    // Return the full file URL
    return 'file://${htmlFile.path}';
  }

  Future<void> _copyAssetDirectory(String assetDir, String targetDir) async {
    try {
      // Create the target directory if it doesn't exist
      final targetDirFile = Directory(targetDir);
      if (!targetDirFile.existsSync()) {
        await targetDirFile.create(recursive: true);
      }

      // Create editor directory
      final editorDir = Directory(p.join(targetDir, 'editor'));
      if (!editorDir.existsSync()) {
        await editorDir.create(recursive: true);
      }

      // Use the monaco-editor/min/vs path
      const corePath = 'assets/monaco/monaco-editor/min/vs';

      try {
        // Copy core files
        final loaderBytes = await rootBundle.load('$corePath/loader.js');
        await File(p.join(targetDir, 'loader.js'))
            .writeAsBytes(loaderBytes.buffer.asUint8List());

        final editorJsBytes =
            await rootBundle.load('$corePath/editor/editor.main.js');
        await File(p.join(targetDir, 'editor', 'editor.main.js'))
            .writeAsBytes(editorJsBytes.buffer.asUint8List());

        final editorCssBytes =
            await rootBundle.load('$corePath/editor/editor.main.css');
        await File(p.join(targetDir, 'editor', 'editor.main.css'))
            .writeAsBytes(editorCssBytes.buffer.asUint8List());
      } catch (e, s) {
        log('Error copying core Monaco files: $e', error: e, stackTrace: s);
      }
    } catch (e, s) {
      log('Error copying Monaco asset directory: $e', error: e, stackTrace: s);
    }
  }

  void _onEditorReady() {
    if (mounted) {
      setState(() {
        _isReady = true;
        _isLoading = false;
      });

      // Initialize the editor content and options
      _updateContent();
      _updateOptions();
    }
  }

  void _updateContent() {
    if (!_isReady || _webview == null) return;

    final escapedContent = widget.encode();
    _webview!.evaluateJavaScript('window.setEditorContent($escapedContent);');
  }

  void _updateOptions() {
    if (!_isReady || _webview == null) return;

    final options = {
      'fontSize': widget.fontSize,
      'lineNumbers': widget.showLineNumbers ? 'on' : 'off',
      'wordWrap': widget.wordWrap ? 'on' : 'off',
      'readOnly': widget.readOnly,
      'theme': context.isDark ? 'vs-dark' : 'vs',
      // Disable linter
      'diagnostics': false,
      'formatOnType': false,
      'formatOnPaste': false,
      'lightbulb': {'enabled': false},
    };

    final optionsJson = options.encode();
    _webview!.evaluateJavaScript('window.setEditorOptions($optionsJson);');
  }

  @override
  void dispose() {
    // Close the WebView window
    _webview?.close();

    _tempDir?.delete(recursive: true).catchError((dynamic e) {
      log('Error deleting temp directory: $e');
      return _tempDir ?? Directory.systemTemp;
    });

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return _buildErrorView(context);
    }

    if (_isLoading) {
      return _buildLoadingView(context);
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
              child: const Center(
                child: Text(
                  'Monaco Editor is running in a separate window',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            ),
          ),
        ),

        // Info bar
        _buildInfoBar(context),
      ],
    );
  }

  Widget _buildLoadingView(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
          Text(
            'Loading Monaco Editor...',
            style: context.bodyLarge?.copyWith(
              color: context.onSurface.addOpacity(0.6),
            ),
          ),
        ],
      ),
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
                _initWebview();
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
          // Action buttons
          if (widget.content.isNotEmpty) ...[
            _buildActionButton(
              context,
              icon: Icons.vertical_align_top,
              tooltip: 'Scroll to top',
              onPressed: () {
                _webview?.evaluateJavaScript(
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
