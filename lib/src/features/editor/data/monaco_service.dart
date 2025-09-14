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
  final FocusNode _webViewFocusNode = FocusNode(debugLabel: 'MonacoWebView');
  Completer<void>? _initCompleter;
  // Ensures only the latest updateContent() call wins.
  int _setEpoch = 0;

  MonacoLanguage? _safeLangFromId(String? id) {
    if (id == null) return null;
    try {
      return MonacoLanguage.fromId(id);
    } catch (_) {
      return null;
    }
  }

  /// Re-verify and re-apply value across frames; abort if a newer write arrived.
  Future<void> _stickValue(String content, int epoch, {int retries = 3}) async {
    for (var i = 0; i < retries; i++) {
      // Let any late init/model swap finish.
      await Future<void>.delayed(const Duration(milliseconds: 16));
      if (epoch != _setEpoch || _controller == null || !state.isReady) return;
      try {
        final got = await _controller!.getValue();
        if (got == content) return; // content held
      } catch (_) {}
      try {
        await _controller!.setValue(content);
      } catch (_) {}
    }
  }

  MonacoController? get controller => _controller;

  Widget get webviewWidget {
    if (_controller == null || !state.isReady) {
      return const Center(child: CircularProgressIndicator());
    }
    // Ensure the native platform view can become first responder
    return Focus(
      focusNode: _webViewFocusNode,
      canRequestFocus: true,
      child: _controller!.webViewWidget,
    );
  }

  Future<void> initialize() async {
    // Make initialization idempotent and guard against concurrent callers.
    if (_initCompleter != null) {
      return _initCompleter!.future;
    }
    if (state.lifecycle != EditorLifecycle.initial &&
        state.lifecycle != EditorLifecycle.error) {
      return;
    }
    _initCompleter = Completer<void>();

    debugPrint('[MonacoService] Initializing with flutter_monaco package...');

    try {
      // Load saved settings
      final options = await EditorSettingsService.load();

      // Create controller with settings
      _controller = await MonacoController.create(
        options: options,
      );

      // Apply queued content if any (language first; then sticky commit)
      if (_queuedContent != null) {
        final epoch = ++_setEpoch;
        final lang = _safeLangFromId(_queuedLanguage);
        if (lang != null) {
          try {
            await _controller!.setLanguage(lang);
          } catch (_) {}
          await Future<void>.delayed(const Duration(milliseconds: 16));
        }
        try {
          await _controller!.setValue(_queuedContent!);
        } catch (_) {}
        unawaited(_stickValue(_queuedContent!, epoch, retries: 8));
        _queuedContent = null;
        _queuedLanguage = null;
      }

      state = state.copyWith(
        lifecycle: EditorLifecycle.ready,
        message: 'Editor is ready',
      );

      debugPrint('[MonacoService] Initialization successful');
      _initCompleter?.complete();
    } catch (e, st) {
      state = state.copyWith(
        lifecycle: EditorLifecycle.error,
        error: e.toString(),
      );
      debugPrint('[MonacoService] Error: $e\n$st');
      _initCompleter?.completeError(e, st);
    } finally {
      // Allow re-init only after a full dispose or explicit error handling
      // Keep the completer for awaiting callers but don't reset lifecycle here.
    }
  }

  Future<void> updateContent(String content, {String? language}) async {
    if (_controller == null || !state.isReady) {
      _queuedContent = content;
      _queuedLanguage = language;
      return;
    }

    final epoch = ++_setEpoch;
    // Language first (if valid), but never fail the write on language errors
    final lang = _safeLangFromId(language);
    if (lang != null) {
      try {
        await _controller!.setLanguage(lang);
      } catch (_) {}
      await Future<void>.delayed(const Duration(milliseconds: 16));
    }
    try {
      await _controller!.setValue(content);
    } catch (_) {}

    await ensureNativeFocus();
    unawaited(_stickValue(content, epoch, retries: 8));

    if (mounted) {
      state = state.copyWith(hasContent: content.isNotEmpty);
    }
  }

  Future<void> updateOptions(EditorOptions options) async {
    if (_controller == null || !state.isReady) return;

    String? before;
    try {
      before = await _controller!.getValue();
    } catch (_) {}

    await _controller!.updateOptions(options);
    await _controller!.setTheme(options.theme);

    if (before != null) {
      try {
        await _controller!.setValue(before);
      } catch (_) {}
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    _webViewFocusNode.dispose();
    super.dispose();
  }

  /// Ensures the native WebView grabs platform focus (first responder),
  /// then the JS Monaco instance can accept keyboard input.
  Future<void> ensureNativeFocus() async {
    if (_webViewFocusNode.canRequestFocus) {
      _webViewFocusNode.requestFocus();
      // Give the engine a beat to propagate focus to the platform view
      await Future<void>.delayed(const Duration(milliseconds: 1));
    }
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
