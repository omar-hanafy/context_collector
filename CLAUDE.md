# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Common Development Commands

### Setup & Dependencies
```bash
flutter pub get                                    # Install dependencies
flutter config --enable-macos-desktop --enable-windows-desktop --enable-linux-desktop  # Enable desktop support
```

### Development
```bash
flutter run                                       # Run app in debug mode
flutter run -d macos                              # Run on macOS (currently stable)
flutter run -d windows                            # Run on Windows (currently stable)
flutter run -d linux                              # Run on Linux (planned)
```

### Testing
```bash
flutter test                                       # Run all tests
flutter test test/features/merge/three_way_merger_test.dart  # Run specific test
```

### Building
```bash
flutter build macos                               # Build macOS app
flutter build windows                             # Build Windows app
flutter build linux                               # Build Linux app
```

### Code Quality
```bash
flutter analyze                                   # Run static analysis (uses very_good_analysis)
dart format .                                     # Format code
dart fix --apply                                  # Apply automated fixes
```

## Architecture Overview

Context Collector is a Flutter desktop application that helps developers prepare code for AI assistants by combining multiple files into a formatted markdown bundle.

### Core Architecture Patterns

1. **Feature-Based Architecture**: The app is organized by features rather than layers. Each feature (`editor`, `scan`, `merge`, `settings`) is self-contained with its own domain, data, and presentation layers.

2. **State Management**: Uses Riverpod for dependency injection and state management. Key providers:
   - `selectionProvider`: Manages file selection state across the app
   - `preferencesProvider`: Handles user settings persistence
   - `monacoAssetManagerProvider`: Manages Monaco editor asset lifecycle

3. **Platform Abstraction**: The Monaco editor integration uses platform-specific implementations:
   - `MonacoBridgePlatform`: Abstract interface for WebView communication
   - Platform-specific controllers handle WebView differences (macOS uses `webview_flutter`, Windows uses `webview_windows`)

### Monaco Editor Integration

The Monaco editor (VS Code's editor) is embedded via WebView with a custom bridge system:

1. **Asset Management**: `MonacoAssetManager` copies Monaco files to platform-specific locations on first run
2. **Communication Bridge**: Bidirectional message passing between Flutter and JavaScript
3. **Platform Handling**: 
   - macOS: Uses `WKWebView` via `webview_flutter`
   - Windows: Uses WebView2 via `webview_windows` (currently being stabilized)
   - Fallback: Shows native Flutter text editor if WebView unavailable

### Key Workflows

1. **File Processing Pipeline**:
   - User drops files/folders → `FileScanner` recursively discovers files
   - Files filtered by extension preferences → `ContentAssembler` formats into markdown
   - Combined content displayed in Monaco editor with syntax highlighting

2. **Settings System**:
   - `ExtensionPrefs` manages which file types to include
   - Editor settings (themes, keybindings, font size) persist via `SharedPreferences`
   - Real-time preview of changes in Monaco editor

3. **Three-Way Merge** (Experimental):
   - Uses Google's `diff_match_patch` algorithm
   - Runs in isolates for performance on large files
   - Implements conflict-free merging strategy

### Platform Status

- **macOS**: Fully supported and stable
- **Windows**: Under active development - WebView2 integration in progress
- **Linux**: Planned but not yet implemented

### Important Considerations

1. **Monaco Assets**: First launch extracts ~30MB of Monaco files to user's app support directory
2. **WebView Lifecycle**: WebView initialization is async - handle loading states appropriately
3. **File Limits**: Large directories may cause UI lag - consider pagination or virtualization for file lists
4. **Platform Detection**: Always check platform before using platform-specific features

# RULES
## PACKAGE ACCESS:
1. **Always Check Local Source First**
   Before offering any implementation detail about a package, look in the user's local pub cache at:

   ```
   /Users/omarhanafy/.pub-cache/hosted/pub.dev/<package-name>-<version>/lib/
   ```

   For example:

   * `webview_windows versions 0.4.0` →
     `/Users/omarhanafy/.pub-cache/hosted/pub.dev/webview_windows-0.4.0`

2. **Fall Back to Official Repo if Needed**
   If the code isn't in the local cache (maybe the user hasn't pulled that version yet), fetch it from the package's GitHub or pub.dev repository before answering.

3. **Quote or Reference Exact API**
   When describing classes, methods, parameters, or behaviors, copy the signature and docs straight from the source so we're never paraphrasing from memory.

4. **Flag Unknowns Explicitly**
   If you still aren't 100% sure—say so. You can add:

   > “I couldn't find that symbol in the local cache or official repo; could you confirm the version or point me to the relevant file?”

5. **Keep Paths and Versions Up to Date**
   Always use the exact version folder that the user's pub-cache contains. If you spot a mismatch, mention it and suggest checking `pubspec.lock`.

6. **Residual Checks**
   Before finalizing, quickly scan for `export` statements in the package's `lib/` folder to see which APIs are publicly exposed.
 