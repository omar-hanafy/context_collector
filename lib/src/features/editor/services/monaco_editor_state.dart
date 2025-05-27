// lib/src/features/editor/services/monaco_editor_state.dart
import 'package:flutter/foundation.dart';

/// States for the global Monaco editor instance
enum MonacoEditorServiceState {
  /// Initial state, editor not yet initialized
  idle,
  
  /// Waiting for assets to be ready
  waitingForAssets,
  
  /// Creating and initializing the editor instance
  initializing,
  
  /// Loading Monaco and setting up the environment
  loading,
  
  /// Editor is fully ready and can be shown instantly
  ready,
  
  /// Error occurred during initialization
  error,
  
  /// Retrying after an error
  retrying,
}

/// Detailed status of the Monaco editor service
@immutable
class MonacoEditorStatus {
  const MonacoEditorStatus({
    required this.state,
    this.progress = 0.0,
    this.message,
    this.error,
    this.retryCount = 0,
    this.lastUpdate,
    this.isVisible = false,
    this.hasContent = false,
    this.queuedContent,
  });

  final MonacoEditorServiceState state;
  final double progress;
  final String? message;
  final String? error;
  final int retryCount;
  final DateTime? lastUpdate;
  final bool isVisible;
  final bool hasContent;
  final String? queuedContent;

  MonacoEditorStatus copyWith({
    MonacoEditorServiceState? state,
    double? progress,
    String? message,
    String? error,
    int? retryCount,
    DateTime? lastUpdate,
    bool? isVisible,
    bool? hasContent,
    String? queuedContent,
  }) {
    return MonacoEditorStatus(
      state: state ?? this.state,
      progress: progress ?? this.progress,
      message: message ?? this.message,
      error: error ?? this.error,
      retryCount: retryCount ?? this.retryCount,
      lastUpdate: lastUpdate ?? this.lastUpdate,
      isVisible: isVisible ?? this.isVisible,
      hasContent: hasContent ?? this.hasContent,
      queuedContent: queuedContent ?? this.queuedContent,
    );
  }

  bool get isReady => state == MonacoEditorServiceState.ready;
  
  bool get isLoading => [
    MonacoEditorServiceState.waitingForAssets,
    MonacoEditorServiceState.initializing,
    MonacoEditorServiceState.loading,
    MonacoEditorServiceState.retrying,
  ].contains(state);
  
  bool get hasError => state == MonacoEditorServiceState.error;
  
  bool get canShow => isReady && hasContent;

  @override
  String toString() => 'MonacoEditorStatus('
      'state: $state, '
      'progress: ${(progress * 100).toInt()}%, '
      'visible: $isVisible, '
      'hasContent: $hasContent'
      ')';
}

/// Configuration for the editor initialization
@immutable
class MonacoEditorConfig {
  const MonacoEditorConfig({
    this.initContent = _defaultInitContent,
    this.initLanguage = 'markdown',
    this.showInitContent = true,
    this.maxRetries = 3,
    this.retryDelay = const Duration(seconds: 2),
  });

  final String initContent;
  final String initLanguage;
  final bool showInitContent;
  final int maxRetries;
  final Duration retryDelay;

  static const String _defaultInitContent = '''
# Welcome to Context Collector! 🎯

Your **Monaco Editor** is ready and waiting for files.

## Quick Start
- 📁 **Drag and drop** files or folders into the app
- ⌨️ **Edit** with full Monaco Editor features
- 🎨 **Customize** using the settings panel
- 📋 **Copy** combined content with one click

## Features
- Syntax highlighting for 50+ languages
- IntelliSense and auto-completion
- Multiple cursor support
- Find and replace
- Code folding
- And much more!

---
*Drop your files to begin editing...*
''';
}
