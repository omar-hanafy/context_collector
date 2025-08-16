import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_monaco/flutter_monaco.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'settings_service.dart';

/// Simplified Monaco service using the flutter_monaco package
class MonacoService extends StateNotifier<EditorStatus> {
  MonacoService()
    : super(const EditorStatus(lifecycle: EditorLifecycle.initial));

  MonacoController? _controller;
  String? _queuedContent;
  String? _queuedLanguage;

  MonacoController? get controller => _controller;

  Widget get webviewWidget {
    if (_controller == null || !state.isReady) {
      return const Center(child: CircularProgressIndicator());
    }
    return _controller!.webViewWidget;
  }

  Future<void> initialize() async {
    if (state.lifecycle != EditorLifecycle.initial &&
        state.lifecycle != EditorLifecycle.error) {
      return;
    }

    debugPrint('[MonacoService] Initializing with flutter_monaco package...');

    try {
      // Load saved settings
      final options = await EditorSettingsService.load();

      // Create controller with settings
      _controller = await MonacoController.create(
        options: options,
      );

      // Apply queued content if any
      if (_queuedContent != null) {
        await _controller!.setValue(_queuedContent!);
        if (_queuedLanguage != null) {
          await _controller!.setLanguage(MonacoLanguage.fromId(_queuedLanguage!));
        }
        _queuedContent = null;
        _queuedLanguage = null;
      }

      state = state.copyWith(
        lifecycle: EditorLifecycle.ready,
        message: 'Editor is ready',
      );

      debugPrint('[MonacoService] Initialization successful');
    } catch (e, st) {
      state = state.copyWith(
        lifecycle: EditorLifecycle.error,
        error: e.toString(),
      );
      debugPrint('[MonacoService] Error: $e\n$st');
    }
  }

  Future<void> updateContent(String content, {String? language}) async {
    if (_controller == null || !state.isReady) {
      _queuedContent = content;
      _queuedLanguage = language;
      return;
    }

    await _controller!.setValue(content);
    if (language != null) {
      await _controller!.setLanguage(MonacoLanguage.fromId(language));
    }

    if (mounted) {
      state = state.copyWith(hasContent: content.isNotEmpty);
    }
  }

  Future<void> updateOptions(EditorOptions options) async {
    if (_controller == null || !state.isReady) return;

    await _controller!.updateOptions(options);
    await _controller!.setTheme(options.theme);
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }
}

enum EditorLifecycle {
  initial,
  ready,
  error,
}

@immutable
class EditorStatus {
  const EditorStatus({
    this.lifecycle = EditorLifecycle.initial,
    this.message = 'Initializing...',
    this.error,
    this.hasContent = false,
  });

  final EditorLifecycle lifecycle;
  final String message;
  final String? error;
  final bool hasContent;

  EditorStatus copyWith({
    EditorLifecycle? lifecycle,
    String? message,
    String? error,
    bool? hasContent,
  }) {
    return EditorStatus(
      lifecycle: lifecycle ?? this.lifecycle,
      message: message ?? this.message,
      error: error ?? this.error,
      hasContent: hasContent ?? this.hasContent,
    );
  }

  bool get isReady => lifecycle == EditorLifecycle.ready;
  bool get isLoading => !isReady && lifecycle != EditorLifecycle.error;
  bool get hasError => lifecycle == EditorLifecycle.error;
}
