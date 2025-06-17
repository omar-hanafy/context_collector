# Project Documentation: Context Collector

This document provides a comprehensive overview of the **Context Collector** Flutter application, detailing its final working architecture, core concepts, and key features.

## 1. Project Overview

Context Collector is a desktop utility for Windows and macOS, designed to streamline the process of gathering and consolidating file contents into a single, cohesive block of text. Its primary use case is to prepare a comprehensive context for Large Language Models (LLMs) by combining multiple source code files, complete with file path references.

The application is built around a powerful, embedded **Monaco Editor**, providing a familiar and feature-rich environment for viewing and interacting with the collected context.

### Core Features:
- **File & Folder Ingestion**: Add files through drag-and-drop or native file pickers.
- **Dynamic Virtual File Tree**: An interactive tree view organizes scanned files, preserving their hierarchy. It also supports the creation of "virtual" files and folders that don't exist on disk.
- **Robust Monaco Editor Integration**: A high-fidelity code editor for viewing the combined context, with full support for syntax highlighting, settings, and platform-specific features.
- **State-Driven Architecture**: Built with Riverpod for robust and predictable state management, decoupling UI from business logic.
- **Rich Customization**: Persistent settings for the editor, including themes, fonts, keybindings, and language-specific rules.

---

## 2. Final Architecture & Key Concepts

The final architecture solves the complex challenges of embedding a local WebView on sandboxed desktop platforms. The key to its success lies in three core concepts:

### 2.1. Dynamic HTML Generation

Instead of relying on a static `index.html` file in the assets, the application now generates it dynamically.

-   **HTML as a Dart Function:** The entire HTML structure is defined as a `static String indexHtmlFile(String vsPath)` function within `EditorConstants`. This makes the HTML template a part of the compiled Dart code, eliminating any risk of it being missing at runtime.
-   **Runtime Generation by `MonacoAssetManager`:** The `MonacoAssetManager` has been promoted from a simple file-copier to a true manager. Its `_ensureHtmlFile` method is called on every launch. It takes the HTML template from `EditorConstants` and writes a physical `index.html` file into the app's cache directory, injecting the correct relative path to the Monaco assets.
-   **Benefits:** This approach ensures the `index.html` file is always perfectly configured for the environment it's running in, with the correct paths and security policies, making the setup significantly more robust.

### 2.2. Platform-Specific WebView Loading

The `MonacoService` now intelligently uses the best loading strategy for each platform to overcome OS-specific security constraints.

-   **On macOS (Sandboxed):** The app uses `controller.loadFile(htmlFilePath)`. This works because `MonacoAssetManager` has already created a perfectly-formed `index.html` in the cache directory. This file contains **relative paths** to the other assets (`loader.js`, etc.), which the sandboxed WebView can resolve correctly because they are relative to the loaded file itself.
-   **On Windows:** The app uses `controller.loadHtmlString(htmlContent)`. The HTML template is populated with an **absolute `file://` URI** for the Monaco assets. This is the most reliable method for the `webview_windows` package.

This dual-strategy approach is the key to achieving consistent behavior across different platforms with different security models.

### 2.3. The Correct Content Security Policy (CSP)

The final piece of the puzzle was creating a CSP that is permissive enough for Monaco's advanced features to work when loaded from a `file://` source, especially within a sandbox. The working policy is:

```html
<meta http-equiv="Content-Security-Policy" 
      content="default-src 'self' file: 'unsafe-inline' 'unsafe-eval'; 
               script-src 'self' file: 'unsafe-inline' 'unsafe-eval'; 
               style-src 'self' 'unsafe-inline'; 
               font-src 'self' file:; 
               worker-src 'self' blob:;"/>
```
-   `font-src 'self' file:`: **Fixes the icon issue.** It explicitly allows the WebView to load font files (like `codicon.ttf`) from local `file://` paths.
-   `script-src ... 'unsafe-eval'`: Required by Monaco for some of its internal workings.
-   `worker-src 'self' blob:`: Crucial for allowing Monaco's language service web workers to run. Without this, features like syntax validation and auto-completion would fail.

---

## 3. Key File Descriptions (Final Architecture)

| File                            | Path                              | Description                                                                                                                                                                                                                                       |
|:--------------------------------|:----------------------------------|:--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| **`editor_constants.dart`**     | `src/features/editor/core/model/` | Now contains the master `index.html` content as a Dart function, `indexHtmlFile()`. This centralizes the WebView's bootstrap logic within the compiled application.                                                                               |
| **`monaco_asset_manager.dart`** | `src/features/editor/data/`       | A critical service that manages the lifecycle of all Monaco assets. It copies the Monaco library to a cache directory and dynamically generates the `index.html` file with the correct configuration for the current run.                         |
| **`monaco_service.dart`**       | `src/features/editor/data/`       | The core service that orchestrates the editor's lifecycle. It now uses the `MonacoAssetManager` to get asset paths and employs platform-specific loading strategies (`loadFile` for macOS, `loadHtmlString` for Windows) to ensure compatibility. |
| **`webview_controller.dart`**   | `src/features/editor/bridge/`     | Provides a unified interface for the platform-specific WebView controllers. Includes the essential `setOnConsoleMessage` method for debugging the `webview_flutter` implementation on macOS.                                                      |
| **`main.dart`**                 | `lib/`                            | The app's entry point. Initializes all top-level services and providers and registers the global `RouteObserver` for robust focus management.                                                                                                     |
