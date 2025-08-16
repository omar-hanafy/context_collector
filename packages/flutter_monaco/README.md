# Flutter Monaco

A Flutter plugin for integrating the Monaco Editor (VS Code's editor) into Flutter applications via WebView.

## Features

- 🎨 **Full Monaco Editor** - The same editor that powers VS Code
- 🌐 **100+ Language Support** - Syntax highlighting for all major languages
- 🎭 **Multiple Themes** - Dark, Light, and High Contrast themes
- 💾 **Versioned Asset Caching** - Efficient one-time asset installation
- 🖥️ **Cross-Platform** - Works on Windows, macOS, iOS, and Linux
- ⚡ **Multiple Editors** - Support for unlimited independent editor instances
- 📊 **Live Statistics** - Real-time line/character counts and selection info
- 🎯 **Type-safe API** - Comprehensive typed bindings for Monaco's JavaScript API
- 🔍 **Find & Replace** - Full programmatic find/replace with regex support
- 🎭 **Decorations & Markers** - Add highlights, errors, warnings to your code
- 📡 **Event Streams** - Listen to content changes, selection, focus events

## Installation

Add `flutter_monaco` to your `pubspec.yaml`:

```yaml
dependencies:
  flutter_monaco:
    path: packages/flutter_monaco  # Or from pub.dev when published
```

## Quick Start

```dart
import 'package:flutter/material.dart';
import 'package:flutter_monaco/flutter_monaco.dart';

// Create a controller
final controller = await MonacoController.create(
  options: const EditorOptions(
    language: 'dart',
    theme: 'vs-dark',
    fontSize: 14,
    wordWrap: true,
  ),
);

// Set content (queued automatically if editor not ready)
await controller.setValue('void main() {\n  print("Hello Monaco!");\n}');

// Display the editor widget
Scaffold(
  body: controller.webViewWidget,
)

// Don't forget to dispose when done
controller.dispose();
```

## Multiple Editors Example

Create a sophisticated multi-editor layout with different languages and themes:

```dart
class MultiEditorView extends StatefulWidget {
  @override
  State<MultiEditorView> createState() => _MultiEditorViewState();
}

class _MultiEditorViewState extends State<MultiEditorView> {
  MonacoController? _dartController;
  MonacoController? _jsController;
  MonacoController? _markdownController;

  @override
  void initState() {
    super.initState();
    _initializeEditors();
  }

  Future<void> _initializeEditors() async {
    // Create three independent editors with different configurations
    _dartController = await MonacoController.create(
      options: const EditorOptions(
        language: 'dart',
        theme: 'vs-dark',
        fontSize: 14,
        minimap: true,
      ),
    );
    
    _jsController = await MonacoController.create(
      options: const EditorOptions(
        language: 'javascript',
        theme: 'vs',  // Light theme
        fontSize: 14,
        minimap: true,
      ),
    );
    
    _markdownController = await MonacoController.create(
      options: const EditorOptions(
        language: 'markdown',
        theme: 'vs-dark',
        fontSize: 15,
        wordWrap: true,
        minimap: false,
        lineNumbers: false,
      ),
    );
    
    // Set initial content
    await _dartController!.setValue('// Dart code');
    await _jsController!.setValue('// JavaScript code');
    await _markdownController!.setValue('# Markdown content');
    
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    if (_dartController == null) {
      return const Center(child: CircularProgressIndicator());
    }
    
    return Column(
      children: [
        // Top row - Dart and JavaScript side by side
        Expanded(
          flex: 2,
          child: Row(
            children: [
              Expanded(child: _dartController!.webViewWidget),
              const VerticalDivider(width: 1),
              Expanded(child: _jsController!.webViewWidget),
            ],
          ),
        ),
        const Divider(height: 1),
        // Bottom - Markdown editor
        Expanded(
          child: _markdownController!.webViewWidget,
        ),
      ],
    );
  }

  @override
  void dispose() {
    _dartController?.dispose();
    _jsController?.dispose();
    _markdownController?.dispose();
    super.dispose();
  }
}
```

## API Reference

### MonacoController

Main controller for interacting with the editor:

```dart
// Content management
await controller.setValue('const x = 42;');
String content = await controller.getValue();

// Language and theme
await controller.setLanguage('javascript');
await controller.setTheme('vs-dark');

// Editor actions
await controller.format();           // Format document
await controller.find();             // Open find dialog
await controller.replace();          // Open replace dialog
await controller.selectAll();        // Select all text
await controller.undo();             // Undo last action
await controller.redo();             // Redo last undone action

// Clipboard
await controller.cut();
await controller.copy();
await controller.paste();

// Navigation
await controller.scrollToTop();
await controller.scrollToBottom();
await controller.revealLine(100);    // Jump to line 100
await controller.focus();            // Request focus

// Custom actions
await controller.executeAction('editor.action.commentLine');

// Live statistics
controller.liveStats.addListener(() {
  final stats = controller.liveStats.value;
  print('Lines: ${stats.lineCount.value}');
  print('Characters: ${stats.charCount.value}');
  print('Selected: ${stats.selectedCharacters.value}');
});

// Event streams
controller.onContentChanged.listen((isFlush) {
  print('Content changed (full replace: $isFlush)');
});

controller.onSelectionChanged.listen((range) {
  print('Selection: $range');
});

controller.onFocus.listen((_) => print('Editor focused'));
controller.onBlur.listen((_) => print('Editor blurred'));
```

### Advanced Features

```dart
// Find and replace
final matches = await controller.findMatches(
  'TODO',
  options: const FindOptions(
    isRegex: false,
    matchCase: true,
    wholeWord: true,
  ),
);
print('Found ${matches.length} TODOs');

// Add error markers
await controller.setErrorMarkers([
  MarkerData.error(
    range: Range.lines(10, 10),
    message: 'Undefined variable',
    code: 'E001',
  ),
]);

// Add decorations (highlights)
await controller.addLineDecorations(
  [5, 10, 15],  // Line numbers
  'highlight-line',  // CSS class
);

// Work with multiple models
final uri = await controller.createModel(
  'console.log("New file");',
  language: 'javascript',
);
await controller.setModel(uri);
```

### EditorOptions

Configure the editor appearance and behavior:

```dart
const EditorOptions(
  language: 'javascript',
  theme: 'vs-dark',              // 'vs', 'vs-dark', 'hc-black'
  fontSize: 14,
  fontFamily: 'Consolas, monospace',
  lineHeight: 1.4,
  wordWrap: true,                // or 'off', 'on', 'wordWrapColumn', 'bounded'
  minimap: false,
  lineNumbers: true,              // or 'off', 'on', 'relative', 'interval'
  rulers: [80, 120],
  tabSize: 2,
  insertSpaces: true,
  readOnly: false,
  automaticLayout: true,          // Auto-resize with container
  scrollBeyondLastLine: true,
  smoothScrolling: false,
  cursorBlinking: 'blink',        // 'blink', 'smooth', 'phase', 'expand', 'solid'
  cursorStyle: 'line',            // 'line', 'block', 'underline'
  renderWhitespace: 'selection',  // 'none', 'boundary', 'selection', 'trailing', 'all'
  bracketPairColorization: true,
  formatOnPaste: false,
  formatOnType: false,
  quickSuggestions: true,
  parameterHints: true,
  hover: true,
  contextMenu: true,
  mouseWheelZoom: false,
);
```

### MonacoAssets

Manage Monaco Editor assets:

```dart
// One-time initialization (called automatically)
await MonacoAssets.ensureReady();

// Get asset information
final info = await MonacoAssets.assetInfo();
print('Monaco cache: ${info['path']}');
print('Total size: ${info['totalSizeMB']} MB');
print('File count: ${info['fileCount']}');

// Clear cache (forces re-extraction on next use)
await MonacoAssets.clearCache();
```

## Architecture

### Asset Management

The plugin uses a versioned cache system:
- Monaco assets (~30MB) are bundled with the plugin in `assets/monaco/min/`
- Assets are extracted once to the app's support directory
- Assets are versioned (e.g., `monaco-0.45.0/`) for clean updates
- Multiple editors share the same asset installation
- Thread-safe initialization with re-entrant protection

### Platform Support

- **macOS**: Uses WKWebView via `webview_flutter` with blob worker shim
- **Windows**: Uses WebView2 via `webview_windows` (requires WebView2 Runtime)
- **iOS**: Uses WKWebView with automatic blob worker shim for file:// protocol
- **Linux**: Uses WebKitGTK via `webview_flutter`

### Performance

- **Memory**: Each editor instance uses ~30-100MB depending on content
- **Startup**: First launch extracts assets (one-time ~1-2 seconds)
- **Multiple Editors**: Tested with 4+ simultaneous editors on desktop
- **Workers**: Web Workers run in separate threads for syntax highlighting

## Requirements

### macOS
- macOS 10.13 or later
- Xcode (for development)

### Windows
- Windows 10 version 1809 or later
- Microsoft Edge WebView2 Runtime (auto-installed on most Windows 10/11 systems)

### iOS
- iOS 11.0 or later
- Info.plist must allow local file access

### Linux
- Any distribution with WebKitGTK installed

## Example App

The [example](example/) directory contains a full demonstration app with:
- Basic single editor setup
- Language and theme switching
- Multi-editor layout (3 editors simultaneously)
- Live statistics display
- Content extraction and manipulation
- Cross-editor content copying

Run the example:
```bash
cd example
flutter run -d macos  # or windows, linux
```

## Important Notes

### Asset Management
Monaco Editor assets are **automatically bundled** with this plugin. You do not need to add any assets to your application. The plugin handles:
- Asset extraction on first launch
- Versioned caching for fast subsequent loads
- Automatic cleanup when updating versions

### Content Queuing
The controller automatically queues content and language changes made before the editor is ready. Your content won't be lost even if you call `setValue()` immediately after creating the controller.

### Event Handling
For advanced users, you can listen to raw JavaScript events:
```dart
controller.onContentChanged.listen((isFlush) { });
controller.onSelectionChanged.listen((range) { });
controller.onFocus.listen((_) { });
controller.onBlur.listen((_) { });
```

### Marker Owners
When using markers (diagnostics), the `clearAllMarkers()` method only clears markers from known owners ('flutter', 'flutter-errors', 'flutter-warnings'). Custom owners must be tracked and cleared separately.

## Troubleshooting

### Windows: WebView2 not found
If you get a WebView2 error on Windows, install the WebView2 Runtime:
https://developer.microsoft.com/en-us/microsoft-edge/webview2/

### macOS/iOS: Workers not loading
The plugin automatically configures a blob worker shim. If you still have issues:
1. Check the console output for errors
2. Ensure file:// access is allowed in your WebView configuration

### Assets not loading
If Monaco assets fail to load:
1. Check the console for error messages
2. Try clearing the cache: `await MonacoAssets.clearCache()`
3. Ensure your app has file system permissions

### Editor not responding
If the editor becomes unresponsive:
1. Check that JavaScript is enabled in the WebView
2. Verify the HTML file was generated correctly
3. Look for JavaScript errors in the console output

### Multiple editors performance
If performance degrades with multiple editors:
1. Limit to 3-4 editors on mobile devices
2. Disable minimap for better performance
3. Consider lazy initialization of editors

## License

This plugin is licensed under the MIT License. See LICENSE file for details.

Monaco Editor is licensed under the MIT License by Microsoft.
