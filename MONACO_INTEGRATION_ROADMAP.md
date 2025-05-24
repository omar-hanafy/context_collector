# Monaco Editor Integration Roadmap

This document outlines the steps taken to integrate the Monaco Editor (the same editor that powers VS Code) into our Flutter desktop application, ensuring it works across macOS, Windows, and Linux platforms.

## Integration Steps

### 1. Bundled the Monaco Editor Assets
- Copied the entire `simple-monaco-editor` folder into `assets/monaco/`
- Updated `pubspec.yaml` to include all necessary Monaco assets
- Organized assets to include the HTML, JavaScript and Monaco VS files

### 2. Fixed HTML Loading and Path Resolution
- Created a custom Monaco integration HTML file with proper VS Path handling
- Added a placeholder (`__VS_PATH__`) that gets replaced with an absolute file:// URI at runtime
- Removed CDN/document.write fallbacks that don't work well in WebView
- Implemented a more robust script loading approach

### 3. Implemented Proper HTML Asset Loading
- For mobile platforms: Used `loadFlutterAsset()` which is the recommended method
- For desktop platforms: 
  - Copied assets to a temporary directory
  - Replaced the VS_PATH placeholder with an absolute file path
  - Used `loadFile()` with the absolute path
- Implemented asset copying logic to ensure Monaco files are available locally

### 4. Fixed macOS Transparency Bug
- Added a platform check to avoid using `setBackgroundColor(Colors.transparent)` on macOS
- This prevents the "opaque is not implemented" error that crashes macOS WebView

### 5. Added Cross-Platform JavaScript to Dart Messaging
- Windows: Used `chrome.webview.postMessage` for WebView2
- macOS/Linux: Added JavaScriptChannel and URL-scheme fallback
- Normalized message format between platforms

### 6. Implemented Two Monaco Editor Options
- **Embedded Editor** (`MonacoEditorEmbedded`): 
  - Integrates Monaco directly into the Flutter UI
  - Uses WebViewWidget within a Container
  - Supports all desktop platforms
- **Pop-out Window Editor** (`MonacoEditorWidget`): 
  - Opens Monaco in a separate window
  - Uses desktop_webview_window package
  - Shows "Monaco Editor is running in a separate window" placeholder in the Flutter UI

### 7. Added Cleanup and Error Handling
- Added proper error reporting in the UI
- Implemented cleanup of temporary files
- Added handling for asset loading failures

## Technical Implementation Details

### Monaco HTML Integration
The Monaco editor is loaded through a customized HTML file that:
1. Accepts an absolute path to the Monaco VS directory
2. Loads the Monaco loader.js script
3. Creates the editor with configurable options (theme, font size, etc.)
4. Provides methods for Flutter to interact with the editor:
   - `setEditorContent(content)`
   - `setEditorOptions(options)`
   - `setEditorLanguage(language)`
   - `getEditorContent()`
   - `setEditorTheme(theme)`

### Cross-Platform Asset Loading Strategy
- **Embedded WebView (macOS/Linux/Windows)**:
  ```dart
  // Create temp dir for assets
  final tempDir = await Directory.systemTemp.createTemp('monaco_editor');
  final vsPath = Uri.file(p.join(tempDir.path, 'vs')).toString();
  
  // Copy Monaco files
  await _copyAssetDirectory('assets/monaco/monaco-editor/min/vs', p.join(tempDir.path, 'vs'));
  
  // Load and modify HTML
  final htmlContent = await rootBundle.loadString('assets/monaco/index.html');
  final modifiedHtml = htmlContent.replaceAll('__VS_PATH__', vsPath);
  
  // Write to file and load
  final htmlFile = File(p.join(tempDir.path, 'index.html'));
  await htmlFile.writeAsString(modifiedHtml);
  await _controller.loadFile(htmlFile.path);
  ```

- **Pop-out WebView Window (Windows)**:
  Uses similar strategy but with the WebviewWindow API

### JavaScript to Dart Communication
- **Windows** (WebView2): Uses `chrome.webview.postMessage`
- **macOS/Linux**: Uses a combination of:
  - JavaScriptChannel registration
  - URL scheme handling (flutter://)

```javascript
// Universal JavaScript messaging
function notifyFlutter(event, payload) {
    if (window.chrome && window.chrome.webview) {
        // Windows WebView2
        window.chrome.webview.postMessage({event, payload});
    } else if (window.flutter_inappwebview) {
        // For platforms with JavaScriptChannel support
        window.flutter_inappwebview.callHandler(event, payload); 
    } else {
        // URL scheme fallback
        window.location.href = 'flutter://' + encodeURIComponent(event + 
            (payload !== undefined ? ':' + JSON.stringify(payload) : ''));
    }
}
```

### macOS Transparency Fix
```dart
_controller = WebViewController()
  ..setJavaScriptMode(JavaScriptMode.unrestricted);

// Don't set transparent background on macOS to avoid 'opaque is not implemented' error
if (!Platform.isMacOS) {
  _controller.setBackgroundColor(Colors.transparent);
}
```

## Testing

The integration has been tested and confirmed working on:
- macOS: Fixed transparency issue
- Windows: Both embedded and pop-out window modes
- Offline mode: Tested with network disconnected

## Future Enhancements

1. **Dark/Light Theme Sync**: 
   - Automatically sync Monaco theme with Flutter's theme
   - Use `window.matchMedia('(prefers-color-scheme: dark)')` for system detection

2. **Advanced Language Support**:
   - Enable TypeScript/Language Server Protocol (LSP) functionality
   - Add code completion and linting features

3. **File Integration**:
   - Connect Monaco with file operations (open/save)
   - Add multi-file editing support

4. **Performance Optimization**:
   - Optimize asset loading for faster startup
   - Add caching for frequently used Monaco files

---

This integration provides a professional code editing experience within your Flutter desktop application, with proper syntax highlighting, theming, and cross-platform support. 