import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  // Ensures Flutter gives keyboard focus to the platform view (WebView)
  final FocusNode _platformViewFocus = FocusNode(
    debugLabel: 'MonacoPlatformView',
  );
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
    // Ensure platform focus on pointer down, then DOM focus via controller.
    return Listener(
      // Important on macOS: don't claim the primary click; let WKWebView win it.
      behavior: HitTestBehavior.translucent,
      onPointerDown: (_) {
        if (!_platformViewFocus.hasFocus) {
          _platformViewFocus.requestFocus();
        }
        // Nudge Monaco input focus without blocking the event pipeline.
        unawaited(ensureEditorFocus(attempts: 1));
      },
      child: Focus(
        focusNode: _platformViewFocus,
        canRequestFocus: true,
        onKeyEvent: (node, event) {
          // Ensure macOS forwards keys to the platform view (WKWebView)
          if (event is KeyDownEvent) {
            return KeyEventResult.skipRemainingHandlers;
          }
          return KeyEventResult.ignored;
        },
        descendantsAreFocusable: true,
        child: _controller!.webViewWidget,
      ),
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
      // Nudge both platform and DOM focus now that we're ready.
      unawaited(ensureEditorFocus(attempts: 3));
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
    // Ensure the hidden textarea owns DOM focus after updates.
    unawaited(ensureEditorFocus(attempts: 3));
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

    // Re-layout and re-focus after option changes (theme/font/etc.).
    await layout();
    await ensureEditorFocus(attempts: 2);
  }

  @override
  void dispose() {
    _platformViewFocus.dispose();
    _controller?.dispose();
    super.dispose();
  }

  /// Ensures the native WebView grabs platform focus (first responder),
  /// then the JS Monaco instance can accept keyboard input.
  Future<void> ensureNativeFocus() async {
    if (_controller == null || !state.isReady) return;
    // Ask Flutter to focus the platform view's FocusNode.
    if (_platformViewFocus.canRequestFocus) {
      _platformViewFocus.requestFocus();
    }
    // Also nudge the native view to become first responder.
    try {
      await _controller!.focus();
    } catch (_) {}
    // Allow a full frame for focus to settle through both layers.
    await Future<void>.delayed(const Duration(milliseconds: 16));
  }

  /// Ensures the Monaco DOM input area gets focus reliably.
  /// Uses the controller's robust helper with layout + retries.
  Future<void> ensureEditorFocus({int attempts = 3}) async {
    if (_controller == null || !state.isReady) return;
    await ensureNativeFocus();
    try {
      await _controller!.ensureEditorFocus(attempts: attempts);
    } catch (_) {
      // Fallback for older builds: best-effort focus.
      try {
        await _controller!.focus();
      } catch (_) {}
    }
  }

  /// Explicitly triggers Monaco layout (useful after resizes or panel changes).
  Future<void> layout() async {
    if (_controller == null || !state.isReady) return;
    try {
      await _controller!.layout();
    } catch (_) {}
  }

  /// Stronger focus recovery used after dialogs with TextFields close.
  /// Releases Flutter's TextInput client, then reacquires platform + DOM focus.
  Future<void> recoverKeyboardFocus({int attempts = 6}) async {
    if (_controller == null || !state.isReady) return;
    try {
      FocusManager.instance.primaryFocus?.unfocus();
    } catch (_) {}
    try {
      await SystemChannels.textInput.invokeMethod<void>('TextInput.hide');
    } catch (_) {}
    // Let the dialog's focus scope tear down.
    await Future<void>.delayed(const Duration(milliseconds: 16));
    await ensureNativeFocus();
    try {
      await _controller!.ensureEditorFocus(attempts: attempts);
    } catch (_) {
      try {
        await _controller!.focus();
      } catch (_) {}
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
