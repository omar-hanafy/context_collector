# Changelog

All notable changes to Context Collector will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.1.0] - 2025-01-14

### 🎉 Added
- **Full Windows support!** Context Collector now runs natively on Windows 10/11
  - Automatic WebView2 Runtime detection and installation prompt
  - Platform-specific WebView integration using flutter_inappwebview
  - Windows-optimized UI and file handling
- Layered architecture for improved performance
  - Editor UI always loaded in background for instant response
  - Smooth fade transitions between home and editor screens
- Enhanced drag-and-drop capabilities
  - Continuous file dropping support
  - Visual feedback during drag operations
  - Works on both home screen and editor screen

### 🔧 Changed
- Migrated from provider to flutter_riverpod for better state management
- Improved Monaco editor initialization with background asset preloading
- Settings sidebar now slides from left side (beside file list)
- Editor starts with empty content (no default welcome message)

### 🐛 Fixed
- Fixed duplicate key errors in AnimatedSwitcher
- Resolved editor visibility issues when clearing files
- Fixed file dropping limitations (now supports multiple drops)
- Corrected sidebar animation and positioning

### 🏗️ Technical Improvements
- Refactored editor service to use layered architecture
- Improved WebView lifecycle management
- Enhanced error handling for platform-specific features
- Better separation of concerns between UI layers

## [1.0.0-beta] - Initial Release

### Added
- macOS support
- Monaco Editor integration
- File and directory drag-and-drop
- 250+ file extension support
- Live statistics
- Multiple theme support
- Customizable keybindings
- Settings persistence

---

**Note:** Context Collector currently supports macOS and Windows. Linux support may be considered in the future.
