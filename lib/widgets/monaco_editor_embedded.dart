import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Required for rootBundle
import 'package:path/path.dart' as p; // Required for path joining
import 'package:webview_flutter/webview_flutter.dart';

import '../extensions/theme_extensions.dart';

// Helper class to track copy operations
class _CopyResult {
  _CopyResult(this.success, this.failures);
  final int success;
  final int failures;
}

class MonacoEditorEmbedded extends StatefulWidget {
  const MonacoEditorEmbedded({
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
  State<MonacoEditorEmbedded> createState() => _MonacoEditorEmbeddedState();
}

class _MonacoEditorEmbeddedState extends State<MonacoEditorEmbedded> {
  late WebViewController _controller;
  bool _isReady = false;
  bool _isLoading = true;
  String? _error;

  // Metrics
  int _totalLines = 0;
  int _totalCharacters = 0;

  // Add language options
  final List<String> _supportedLanguages = [
    'plaintext',
    'dart',
    'html',
    'css',
    'javascript',
    'typescript',
    'json',
    'yaml',
    'markdown',
    'python',
    'shell',
    'xml',
    'sql',
  ];

  String _currentLanguage = 'plaintext';
  String _currentTheme = 'vs-dark';
  bool _isEditMode = false;

  @override
  void initState() {
    super.initState();
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
      // Initialize WebViewController
      _controller = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted);

      // Don't set transparent background on macOS to avoid 'opaque is not implemented' error
      if (!Platform.isMacOS) {
        _controller.setBackgroundColor(Colors.transparent);
      }

      // Add JavaScript channels for communication
      _controller.addJavaScriptChannel(
        'flutterChannel',
        onMessageReceived: (JavaScriptMessage message) {
          try {
            if (message.message.startsWith('log:')) {
              return;
            }

            final data = jsonDecode(message.message);
            final event = data['event'] as String?;

            if (event == 'onEditorReady') {
              _onEditorReady();
            }
          } catch (e) {
            // Ignore parsing errors
          }
        },
      );

      // Set navigation delegate
      _controller.setNavigationDelegate(
        NavigationDelegate(
          onProgress: (int progress) {
            if (progress == 100) {
              // Inject JS bridge code
              _controller.runJavaScript('''
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
          onPageFinished: (String url) {
            setState(() {
              _isLoading = false;
            });
          },
          onWebResourceError: (WebResourceError error) {
            setState(() {
              _error =
                  'Failed to load editor: ${error.description} (URL: ${error.url})';
              _isLoading = false;
            });
          },
          onNavigationRequest: (NavigationRequest request) {
            if (request.url.startsWith('flutter://log:')) {
              return NavigationDecision.prevent;
            } else if (request.url.startsWith('flutter://')) {
              final payload = Uri.decodeFull(request.url.substring(10));
              _handleUrlMessage(payload);
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
        ),
      );

      // Load the HTML content
      await _loadHtml();
    } catch (e, stackTrace) {
      setState(() {
        _error = 'Failed to initialize editor: $e';
        _isLoading = false;
      });
    }
  }

  void _handleUrlMessage(String payload) {
    if (payload.startsWith('onEditorReady')) {
      _onEditorReady();
    }
  }

  Future<void> _loadHtml() async {
    const asset = 'assets/monaco/index.html';

    try {
      if (Platform.isAndroid || Platform.isIOS) {
        await _controller.loadFlutterAsset(asset);
        return;
      }

      // For desktop: Copy to temp dir, replace VS_PATH, then load via loadFile
      final tempDir = await Directory.systemTemp.createTemp('monaco_editor');

      // Use monaco-editor/min/vs path
      final vsPath = Uri.file(p.join(tempDir.path, 'vs')).toString();

      // Copy the vs directory to the temp dir (needed for offline operation)
      await _copyAssetDirectory(
          'assets/monaco/monaco-editor/min/vs', p.join(tempDir.path, 'vs'));

      // Load and modify the HTML content to include the absolute vs path
      final htmlContent = await rootBundle.loadString(asset);
      final modifiedHtml = htmlContent.replaceAll('__VS_PATH__', vsPath);

      // Write the modified HTML to a temp file
      final htmlFile = File(p.join(tempDir.path, 'index.html'));
      await htmlFile.writeAsString(modifiedHtml);

      // Force loading to be false after a timeout
      Future.delayed(const Duration(seconds: 5), () {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      });

      // Load the temp HTML file
      await _controller.loadFile(htmlFile.path);
    } catch (e) {
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

      // Create subdirectories
      final editorDir = Directory(p.join(targetDir, 'editor'));
      if (!await editorDir.exists()) {
        await editorDir.create(recursive: true);
      }

      final basicLangDir = Directory(p.join(targetDir, 'basic-languages'));
      if (!await basicLangDir.exists()) {
        await basicLangDir.create(recursive: true);
      }

      final languageDir = Directory(p.join(targetDir, 'language'));
      if (!await languageDir.exists()) {
        await languageDir.create(recursive: true);
      }

      // Copy the core files
      await _copyAssetFile('assets/monaco/monaco-editor/min/vs/loader.js',
          p.join(targetDir, 'loader.js'));
      await _copyAssetFile(
          'assets/monaco/monaco-editor/min/vs/editor/editor.main.js',
          p.join(targetDir, 'editor', 'editor.main.js'));
      await _copyAssetFile(
          'assets/monaco/monaco-editor/min/vs/editor/editor.main.css',
          p.join(targetDir, 'editor', 'editor.main.css'));

      // Copy language files
      final copyResults = await _copyLanguageFiles(
          'assets/monaco/monaco-editor/min/vs', targetDir);

      if (copyResults.success == 0) {
        // Silent failure - fallback happens in the HTML
      }
    } catch (e) {
      // Silent failure - fallback happens in the HTML
    }
  }

  Future<_CopyResult> _copyLanguageFiles(
      String sourcePath, String targetPath) async {
    int success = 0;
    int failures = 0;

    // List of important language directories to copy
    final languageDirs = [
      'basic-languages/dart',
      'basic-languages/typescript',
      'basic-languages/javascript',
      'basic-languages/html',
      'basic-languages/css',
      'basic-languages/json',
      'basic-languages/python',
      'basic-languages/yaml',
      'basic-languages/xml',
      'basic-languages/markdown',
      'basic-languages/shell',
      'language/typescript',
      'language/json',
      'language/html',
      'language/css',
    ];

    for (final langDir in languageDirs) {
      try {
        final sourceDir = p.join(sourcePath, langDir);
        final targetLangDir = p.join(targetPath, langDir);

        // Create the target language directory
        final targetLangDirFile = Directory(targetLangDir);
        if (!await targetLangDirFile.exists()) {
          await targetLangDirFile.create(recursive: true);
        }

        // Get list of files from asset bundle
        final manifest = await rootBundle.loadString('AssetManifest.json');
        final Map<String, dynamic> manifestMap =
            json.decode(manifest) as Map<String, dynamic>;

        // Find all files in this language directory
        final langFiles = manifestMap.keys
            .where((String key) =>
                key.startsWith('$sourceDir/') && key.endsWith('.js'))
            .toList();

        for (final file in langFiles) {
          try {
            final fileName = p.basename(file);
            final targetFile = p.join(targetLangDir, fileName);

            await _copyAssetFile(file, targetFile);
            success++;
          } catch (e) {
            failures++;
          }
        }
      } catch (e) {
        failures++;
      }
    }

    return _CopyResult(success, failures);
  }

  Future<void> _copyAssetFile(String assetPath, String targetPath) async {
    try {
      final bytes = await rootBundle.load(assetPath);
      await File(targetPath).writeAsBytes(bytes.buffer.asUint8List());
    } catch (e) {
      rethrow;
    }
  }

  void _onEditorReady() {
    if (mounted) {
      setState(() {
        _isReady = true;
        _isLoading = false;
      });
      _updateContent();
      _updateOptions();
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
      'readOnly': !_isEditMode && widget.readOnly,
      'theme': _currentTheme,
      // Disable linter
      'diagnostics': false,
      'formatOnType': false,
      'formatOnPaste': false,
      'lightbulb': {'enabled': false},
    };
    final optionsJson = jsonEncode(options);
    _controller.runJavaScript('window.setEditorOptions($optionsJson);');
  }

  void _setLanguage(String language) {
    setState(() {
      _currentLanguage = language;
    });
    if (_isReady) {
      _controller.runJavaScript('window.setEditorLanguage("$language");');
    }
  }

  void _setTheme(String theme) {
    setState(() {
      _currentTheme = theme;
    });
    if (_isReady) {
      _controller.runJavaScript('window.setEditorTheme("$theme");');
    }
  }

  void _toggleEditMode() {
    setState(() {
      _isEditMode = !_isEditMode;
    });
    if (_isReady) {
      _updateOptions();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
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
      child: Column(
        children: [
          Row(
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
          const SizedBox(height: 8),
          Row(
            children: [
              // Language selector
              _buildDropdownSelector(
                context,
                icon: Icons.code,
                label: 'Language',
                value: _currentLanguage,
                items: _supportedLanguages
                    .map((lang) => DropdownMenuItem(
                          value: lang,
                          child: Text(lang.capitalize()),
                        ))
                    .toList(),
                onChanged: (value) {
                  if (value != null) {
                    _setLanguage(value);
                  }
                },
              ),
              const SizedBox(width: 16),
              // Theme selector
              _buildDropdownSelector(
                context,
                icon: Icons.palette,
                label: 'Theme',
                value: _currentTheme,
                items: const [
                  DropdownMenuItem(
                    value: 'vs',
                    child: Text('Light'),
                  ),
                  DropdownMenuItem(
                    value: 'vs-dark',
                    child: Text('Dark'),
                  ),
                  DropdownMenuItem(
                    value: 'hc-black',
                    child: Text('High Contrast'),
                  ),
                ],
                onChanged: (value) {
                  if (value != null) {
                    _setTheme(value);
                  }
                },
              ),
              const Spacer(),
              // Edit mode toggle
              _buildSwitchToggle(
                context,
                icon: Icons.edit,
                label: 'Edit Mode',
                value: _isEditMode,
                onChanged: (_) => _toggleEditMode(),
              ),
            ],
          ),
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

  Widget _buildDropdownSelector<T>(
    BuildContext context, {
    required IconData icon,
    required String label,
    required T value,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?> onChanged,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: context.isDark
            ? Colors.black.addOpacity(0.2)
            : Colors.white.addOpacity(0.9),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: context.onSurface.addOpacity(0.1),
        ),
      ),
      padding: const EdgeInsetsDirectional.symmetric(
        horizontal: 12,
        vertical: 4,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 16,
            color: context.onSurface.addOpacity(0.7),
          ),
          const SizedBox(width: 8),
          Text(
            '$label:',
            style: context.labelSmall?.copyWith(
              color: context.onSurface.addOpacity(0.7),
            ),
          ),
          const SizedBox(width: 8),
          DropdownButton<T>(
            value: value,
            items: items,
            onChanged: onChanged,
            underline: const SizedBox(),
            borderRadius: BorderRadius.circular(8),
            isDense: true,
            style: context.bodySmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSwitchToggle(
    BuildContext context, {
    required IconData icon,
    required String label,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: context.isDark
            ? Colors.black.addOpacity(0.2)
            : Colors.white.addOpacity(0.9),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: context.onSurface.addOpacity(0.1),
        ),
      ),
      padding: const EdgeInsetsDirectional.symmetric(
        horizontal: 12,
        vertical: 4,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 16,
            color: context.onSurface.addOpacity(0.7),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: context.labelSmall?.copyWith(
              color: context.onSurface.addOpacity(0.7),
            ),
          ),
          const SizedBox(width: 8),
          Switch.adaptive(
            value: value,
            onChanged: onChanged,
            activeColor: context.primary,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ],
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

// String extension to capitalize first letter
extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${substring(1)}";
  }
}
